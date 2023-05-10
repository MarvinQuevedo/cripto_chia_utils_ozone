// ignore_for_file: lines_longer_than_80_chars

import 'dart:convert';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:meta/meta.dart';

@immutable
class Payment {
  Payment(this.amount, this.puzzlehash, {List<dynamic>? memos})
      : memos = memos == null
            ? null
            : memos is List<String>
                ? memos.map((memo) => Memo(utf8.encode(memo))).toList()
                : memos is List<int>
                    ? memos.map((memo) => Memo(utf8.encode(memo.toString()))).toList()
                    : memos is List<Bytes>
                        ? memos.map((e) => Memo(e.byteList)).toList()
                        : throw ArgumentError(
                            'Unsupported type for memos. Must be Bytes, String, or int',
                          );

  Payment.fromProgram(Program program)
      : amount = program.toList()[1].toInt(),
        puzzlehash = Puzzlehash(program.toList()[0].atom),
        memos = program.toList().length > 2
            ? program.toList()[2].toList().map((p) => Memo(p.atom)).toList()
            : <Memo>[];
  final int amount;
  final Puzzlehash puzzlehash;
  final List<Memo>? memos;

  CreateCoinCondition toCreateCoinCondition() {
    return CreateCoinCondition(puzzlehash, amount, memos: memos);
  }

  List<String> get memoStrings {
    if (memos == null) {
      return [];
    }

    final memoStrings = <String>[];
    for (final memo in memos!) {
      final decodedString = memo.decodedString;
      if (decodedString != null) {
        memoStrings.add(decodedString);
      }
    }

    return memoStrings;
  }

  Program toProgram() {
    return Program.list([
      Program.fromBytes(puzzlehash),
      Program.fromInt(amount),
      Program.list(
        memos?.map(Program.fromBytes).toList() ?? [],
      ),
    ]);
  }

  @override
  String toString() => 'Payment(amount: $amount, puzzlehash: $puzzlehash, memos: $memos)';

  @override
  bool operator ==(Object other) =>
      other is Payment && puzzlehash == other.puzzlehash && amount == other.amount;

  @override
  int get hashCode => puzzlehash.hashCode ^ amount.hashCode;
}

extension PaymentIterable on Iterable<Payment> {
  int get totalValue {
    return fold(0, (int previousValue, payment) => previousValue + payment.amount);
  }

  List<Memo> get memos =>
      fold(<Memo>[], (previousValue, element) => previousValue + (element.memos ?? []));

  List<String> get memoStrings =>
      fold(<String>[], (previousValue, element) => previousValue + (element.memoStrings));
}

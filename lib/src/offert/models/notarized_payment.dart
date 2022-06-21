import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import '../../core/models/outer_puzzle.dart' as outerPuzzle;

import '../../core/models/conditions/announcement.dart';
import '../puzzles/settlement_payments/settlement_payments.clvm.hex.dart';
import 'puzzle_info.dart';

final ZERO_32 = Bytes(List.generate(32, (_) => 0));

class NotarizedPayment extends Payment {
  late final Bytes nonce;
  NotarizedPayment(
    int amount,
    Puzzlehash puzzlehash, {
    List<Bytes>? memos,
    Bytes? nonce,
  }) : super(
          amount,
          puzzlehash,
          memos: memos,
        ) {
    this.nonce = nonce ?? ZERO_32;
  }

  factory NotarizedPayment.fromConditionAndNonce(
      {required Program condition, required Bytes nonce}) {
    final withOpcode = Program.list([Program.fromInt(51), condition]);
    final p = Payment.fromProgram(withOpcode);
    //final args = p.toProgram();
    return NotarizedPayment(p.amount, p.puzzlehash, memos: p.memos, nonce: nonce);
  }

  NotarizedPayment copyWith({
    int? amount,
    Puzzlehash? puzzlehash,
    Bytes? nonce,
    List<Bytes>? memos,
  }) {
    return NotarizedPayment(
      amount ?? this.amount,
      puzzlehash ?? this.puzzlehash,
      nonce: nonce ?? this.nonce,
      memos: memos ?? this.memos,
    );
  }
}

class Offert {
  /// The key is the asset id of the asset being requested, if is null then request XCH
  final Map<Bytes?, List<NotarizedPayment>> requestedPayments;
  final SpendBundle spendBundle;

  ///  asset_id -> asset driver
  final Map<Bytes, PuzzleInfo> driverDict;

  Offert({
    required this.requestedPayments,
    required this.spendBundle,
    required this.driverDict,
  });

  Bytes get ph => offertProgram.hash();

  /// calc the coins hash [nonce]
  Map<Bytes?, List<NotarizedPayment>> notarizePayments({
    required Map<Bytes?, List<NotarizedPayment>>
        requestedPayments, //`Null` means you are requesting XCH
    required List<Coin> coins,
  }) {
    // This sort should be reproducible in CLVM with `>s`

    final sortedCoins = coins.toList()..sort((a, b) => a.id.compareTo(b.id));
    final sortedCoinList = sortedCoins.toList().map((e) => e.toProgram()).toList();
    final nonce = Program.list(sortedCoinList).hash();

    final result = Map<Bytes?, List<NotarizedPayment>>();
    requestedPayments.forEach((assetId, payments) {
      result[assetId] = [];
      payments.forEach((payment) {
        result[assetId]!.add(
          payment.copyWith(
            nonce: nonce,
          ),
        );
      });
    });
    return result;
  }

  List<Announcement> calculateAnnouncements({
    required Map<Bytes?, List<NotarizedPayment>> notarizedPayment,
    required Map<Bytes, PuzzleInfo> driverDict,
  }) {
    final result = <Announcement>[];
    notarizedPayment.forEach((assetId, payments) {
      Bytes? settlementPh;
      if (assetId != null) {
        if (!driverDict.containsKey(assetId)) {
          throw Exception(
              "Cannot calculate announcements without driver of requested item $assetId");
        }
        settlementPh = outerPuzzle
            .constructPuzzle(
              constructor: driverDict[assetId]!,
              innerPuzzle: offertProgram,
            )
            .hash();
      } else {
        settlementPh = offertProgram.hash();
      }

      Bytes msg = Program.list([
        Program.fromBytes(payments[0].nonce),
        Program.list(payments.map((e) => e.toProgram()).toList()),
      ]).hash();

      result.add(Announcement(settlementPh, msg));
    });
    return result;
  }
}

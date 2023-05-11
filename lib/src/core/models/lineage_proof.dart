import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:meta/meta.dart';

@immutable
class LineageProof with ToBytesMixin, ToProgramMixin {
  const LineageProof({
    required this.parentCoinInfo,
    required this.amount,
    this.innerPuzzlehash,
  });

  factory LineageProof.fromBytes(Bytes bytes) {
    final iterator = bytes.iterator;

    final parentCoinInfo = Puzzlehash.maybeFromStream(iterator);
    final innerPuzzlehash = Puzzlehash.maybeFromStream(iterator);

    final amount = maybeIntFrom64BitsStream(iterator);

    return LineageProof(
      parentCoinInfo: parentCoinInfo,
      innerPuzzlehash: innerPuzzlehash,
      amount: amount,
    );
  }
  static LineageProof fromMap(Map<String, dynamic> map) {
    return LineageProof(
      parentCoinInfo:
          map['parent_name'] == null ? null : Puzzlehash.fromHex(map['parent_name'] as String),
      innerPuzzlehash: map['inner_puzzle_hash'] == null
          ? null
          : Puzzlehash.fromHex(map['inner_puzzle_hash'] as String),
      amount: map['amount'] as int?,
    );
  }

  final Bytes? parentCoinInfo;
  final Puzzlehash? innerPuzzlehash;
  final int? amount;

  @override
  Program toProgram() => Program.list([
        if (parentCoinInfo != null) Program.fromBytes(parentCoinInfo!),
        if (innerPuzzlehash != null) Program.fromBytes(innerPuzzlehash!),
        if (amount != null) Program.fromInt(amount!),
      ]);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! LineageProof) {
      return false;
    }
    return toProgram() == other.toProgram();
  }

  @override
  int get hashCode => toProgram().hashCode;

  @override
  Bytes toBytes() {
    return Bytes([
      ...parentCoinInfo.optionallySerialize(),
      ...innerPuzzlehash.optionallySerialize(),
      ...optionallySerializeInt(amount),
    ]);
  }
}

import '../../../chia_crypto_utils.dart';

class LineageProof {
  final Puzzlehash? parentName;

  final Puzzlehash? innerPuzzleHash;

  final int? amount;

  LineageProof({
    required this.parentName,
    this.innerPuzzleHash,
    required this.amount,
  });

  Program toProgram() {
    List<Program> list = <Program>[];
    if (parentName != null) {
      list.add(Program.fromBytes(
        parentName!,
      ));
    }
    if (innerPuzzleHash != null) {
      list.add(Program.fromBytes(
        innerPuzzleHash!,
      ));
    }
    if (amount != null) {
      list.add(Program.fromInt(amount!));
    }
    return Program.list(list);
  }

  static LineageProof fromMap(Map<String, dynamic> map) {
    return LineageProof(
      parentName:
          map['parent_name'] == null ? null : Puzzlehash.fromHex(map['parent_name'] as String),
      innerPuzzleHash: map['inner_puzzle_hash'] == null
          ? null
          : Puzzlehash.fromHex(map['inner_puzzle_hash'] as String),
      amount: map['amount'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'parent_name': parentName?.toHex(),
      'inner_puzzle_hash': innerPuzzleHash?.toHex(),
      'amount': amount,
    };
  }

  bool isNone() => parentName == null && innerPuzzleHash == null && amount == null;
}

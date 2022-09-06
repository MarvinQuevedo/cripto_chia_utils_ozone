import '../../../chia_crypto_utils.dart';

class LineageProof {
  final Bytes? parentName;

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

  bool isNone() => parentName == null && innerPuzzleHash == null && amount == null;
}

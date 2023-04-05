import '../../../chia_crypto_utils.dart';
import '../../core/models/outer_puzzle.dart' as outerPuzzle;
import '../models/deconstructed_transfer_program_puzzle.dart';

DeconstructedTransferProgramPuzzle? mathTransferProgramPuzzle(Program puzzle) {
  final uncurried = puzzle.uncurry();
  if (uncurried.program.hash() == OWNERSHIP_LAYER_MOD_HASH) {
    final nftArgs = uncurried.arguments;

    final singletonStruct = nftArgs[0];
    final royaltyAddressP = nftArgs[1];
    final royaltyPercentage = nftArgs[2];

    return DeconstructedTransferProgramPuzzle(
      singletonStruct: singletonStruct,
      royaltyPercentage: royaltyPercentage.toInt(),
      royaltyAddressP: royaltyAddressP,
    );
  }
  return null;
}

Program puzzleForTransferProgram(
    {required Bytes launcherId, required Puzzlehash royaltyAddress, required int percentage}) {
  final sinletonStruct = Program.cons(
    Program.fromBytes(SINGLETON_TOP_LAYER_MOD_V1_1_HASH),
    Program.cons(
      Program.fromBytes(launcherId),
      Program.fromBytes(SINGLETON_LAUNCHER_HASH),
    ),
  );
  return TRANSFER_PROGRAM_MOD
      .curry([sinletonStruct, Program.fromBytes(royaltyAddress), Program.fromInt(percentage)]);
}

Program solutionForTransferProgram(
    {required Program conditions,
    required Puzzlehash? currentowner,
    required Puzzlehash newDid,
    required Puzzlehash newDidInnerHash,
    required Program tradePricesList}) {
  Program currentOwnerP = Program.nil;
  if (currentowner != null) {
    currentOwnerP = Program.fromBytes(currentowner);
  }

  return Program.list([
    conditions,
    currentOwnerP,
    Program.list([
      Program.fromBytes(newDid),
      tradePricesList,
      Program.fromBytes(
        newDidInnerHash,
      ),
    ])
  ]);
}

class TransferProgramOuterPuzzle extends outerPuzzle.OuterPuzzle {
  @override
  Program constructPuzzle({required PuzzleInfo constructor, required Program innerPuzzle}) {
    return puzzleForTransferProgram(
      launcherId: Puzzlehash.fromHex(constructor["launcher_id"]),
      royaltyAddress: Puzzlehash.fromHex(constructor["royalty_address"]),
      percentage: constructor["royalty_percentage"] as int,
    );
  }

  @override
  Puzzlehash? createAssetId({required PuzzleInfo constructor}) {
    return null;
  }

  @override
  PuzzleInfo? matchPuzzle(Program puzzle) {
    final matched = mathTransferProgramPuzzle(puzzle);
    if (matched != null) {
      final Map<String, dynamic> constructorDict = {
        "type": AssetType.ROYALTY_TRANSFER_PROGRAM,
        "launcher_id": matched.singletonStruct.rest().first().atom.toHexWithPrefix(),
        "royalty_address": matched.royaltyAddressP.atom.toHexWithPrefix(),
        "royalty_percentage": matched.royaltyPercentage
      };

      return PuzzleInfo(constructorDict);
    }
    return null;
  }

  @override
  Program solvePuzzle(
      {required PuzzleInfo constructor,
      required Solver solver,
      required Program innerPuzzle,
      required Program innerSolution}) {
    if (constructor.also != null) {
      innerSolution = outerPuzzle.solvePuzzle(
          constructor: constructor.also!,
          solver: solver,
          innerPuzzle: innerPuzzle,
          innerSolution: innerSolution);
    }

    return Program.nil;
  }

  @override
  Program? getInnerPuzzle({required PuzzleInfo constructor, required Program puzzleReveal}) {
    return null;
  }

  @override
  Program? getInnerSolution({required PuzzleInfo constructor, required Program solution}) {
    return null;
  }
}

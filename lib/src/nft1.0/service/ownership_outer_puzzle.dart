import '../../../chia_crypto_utils.dart';
import '../../core/models/outer_puzzle.dart' as outerPuzzle;
import '../models/deconstructed_ownership_outer_puzzle.dart';

DeconstructedOwnershipOuterPuzzle? mathOwnershipLayerPuzzle(Program puzzle) {
  final uncurried = puzzle.uncurry();
  if (uncurried.program.hash() == NFT_OWNERSHIP_LAYER_HASH) {
    final nftArgs = uncurried.arguments;

    final currentOwner = nftArgs[1];
    final transferProgram = nftArgs[2];
    final innerPuzzle = nftArgs[3];

    return DeconstructedOwnershipOuterPuzzle(
      currentOwner: currentOwner.atom,
      transferProgram: transferProgram,
      innerPuzzle: innerPuzzle,
    );
  }
  return null;
}

/// [currentOwner] Can be Program, Bytes, Hex String or CLVM program String
Program puzzleForOwnershipLayer(
    {required currentOwner, required Program transferProgram, required Program innerPuzzle}) {
  Program _currentOwner;
  if (currentOwner is Program) {
    _currentOwner = currentOwner;
  } else if (currentOwner is Bytes) {
    _currentOwner = Program.fromBytes(currentOwner);
  } else if (currentOwner == null) {
    _currentOwner = Program.nil;
  } else {
    if ((currentOwner as String).contains("0x")) {
      _currentOwner = Program.fromHex(currentOwner);
    } else {
      _currentOwner = Program.parse(currentOwner);
    }
  }
  return NFT_OWNERSHIP_LAYER.curry(
    [
      Program.fromBytes(NFT_OWNERSHIP_LAYER_HASH),
      _currentOwner,
      transferProgram,
      innerPuzzle,
    ],
  );
}

Program solutionForOwnershipLayer({required Program innerSolution}) {
  return Program.list([innerSolution]);
}

class OwnershipOuterPuzzle extends outerPuzzle.OuterPuzzle {
  @override
  Program constructPuzzle({required PuzzleInfo constructor, required Program innerPuzzle}) {
    if (constructor.also != null) {
      innerPuzzle =
          outerPuzzle.constructPuzzle(constructor: constructor.also!, innerPuzzle: innerPuzzle);
    }
    final transfer_program_info = constructor["transfer_program"];
    Program transfer_program;
    if (transfer_program_info is Program) {
      transfer_program = transfer_program_info;
    } else {
      transfer_program = outerPuzzle.constructPuzzle(
        constructor: transfer_program_info,
        innerPuzzle: innerPuzzle,
      );
    }

    return puzzleForOwnershipLayer(
      currentOwner: constructor["owner"],
      transferProgram: transfer_program,
      innerPuzzle: innerPuzzle,
    );
  }

  @override
  Puzzlehash? createAssetId({required PuzzleInfo constructor}) {
    return null;
  }

  @override
  PuzzleInfo? matchPuzzle(Program puzzle) {
    final matched = mathOwnershipLayerPuzzle(puzzle);
    if (matched != null) {
      final tpMatch = outerPuzzle.matchPuzzle(matched.transferProgram);
      final Map<String, dynamic> constructorDict = {
        "type": AssetType.OWNERSHIP,
        "owner": matched.currentOwner.isEmpty ? "()" : matched.currentOwner.toHexWithPrefix(),
        "transfer_program": tpMatch == null ? matched.transferProgram.toSource() : tpMatch.info,
      };
      final next = matchPuzzle(matched.innerPuzzle);
      if (next != null) {
        constructorDict["also"] = next.info;
      }
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

    return solutionForOwnershipLayer(innerSolution: innerSolution);
  }

  @override
  Program? getInnerPuzzle({required PuzzleInfo constructor, required Program puzzleReveal}) {
    final matched = mathOwnershipLayerPuzzle(puzzleReveal);
    if (matched != null) {
      final innerPuzzle = matched.innerPuzzle;
      if (constructor.also != null) {
        final deopInnerPuzzle = outerPuzzle.getInnerPuzzle(
          constructor: constructor.also!,
          puzzleReveal: puzzleReveal,
        );
        return deopInnerPuzzle;
      }
      return innerPuzzle;
    } else {
      throw Exception("This driver is not for the specified puzzle reveal");
    }
  }

  @override
  Program? getInnerSolution({required PuzzleInfo constructor, required Program solution}) {
    final myInnerSolution = solution.first();
    if (constructor.also != null) {
      final deepInnerSolution =
          outerPuzzle.getInnerSolution(constructor: constructor.also!, solution: myInnerSolution);
      return deepInnerSolution;
    }
    return myInnerSolution;
  }
}

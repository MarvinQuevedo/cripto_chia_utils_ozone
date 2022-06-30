import 'package:chia_crypto_utils/chia_crypto_utils.dart';

import '../../cat/service/cat_outer_puzzle.dart';
import '../../offer/models/puzzle_info.dart';
import '../../offer/models/solver.dart';

class AssetType {
  static String get CAT => 'CAT';
}

final Map<String, OuterPuzzle> _driverLookup = {
  AssetType.CAT: CATOuterPuzzle(),
};

Program constructPuzzle({
  required PuzzleInfo constructor,
  required Program innerPuzzle,
}) {
  final driver = _driverLookup[constructor.info['type']];
  if (driver == null) throw Exception('Unknown asset type: ${constructor.info["type"]}');

  return driver.constructPuzzle(
    constructor: constructor,
    innerPuzzle: innerPuzzle,
  );
}

Bytes createAssetId(PuzzleInfo constructor) {
  final driver = _driverLookup[constructor.info['type']];
  if (driver == null) throw Exception('Unknown asset type: ${constructor.info["type"]}');
  return driver.createAssetId(constructor: constructor);
}

PuzzleInfo? matchPuzzle(Program puzzle) {
  for (var driver in _driverLookup.values) {
    final matched = driver.matchPuzzle(puzzle);
    if (matched != null) {
      return matched;
    }
  }
  return null;
}

Program solvePuzzle({
  required PuzzleInfo constructor,
  required Solver solver,
  required Program innerPuzzle,
  required Program innerSolution,
}) {
  final driver = _driverLookup[constructor.info['type']];
  if (driver == null) throw Exception('Unknown asset type: ${constructor.info["type"]}');

  return driver.solvePuzzle(
    constructor: constructor,
    solver: solver,
    innerPuzzle: innerPuzzle,
    innerSolution: innerSolution,
  );
}

Program getInnerPuzzle({
  required PuzzleInfo constructor,
  required Program puzzleReveal,
}) {
  final driver = _driverLookup[constructor.info['type']];
  if (driver == null) throw Exception('Unknown asset type: ${constructor.info["type"]}');
  return driver.getInnerPuzzle(constructor: constructor, puzzleReveal: puzzleReveal);
}

Program getInnerSolution({
  required PuzzleInfo constructor,
  required Program solution,
}) {
  final driver = _driverLookup[constructor.info['type']];
  if (driver == null) throw Exception('Unknown asset type: ${constructor.info["type"]}');
  return driver.getInnerSolution(constructor: constructor, solution: solution);
}

abstract class OuterPuzzle {
  Program constructPuzzle({
    required PuzzleInfo constructor,
    required Program innerPuzzle,
  });
  Puzzlehash createAssetId({
    required PuzzleInfo constructor,
  });
  PuzzleInfo? matchPuzzle(Program puzzle);
  Program solvePuzzle({
    required PuzzleInfo constructor,
    required Solver solver,
    required Program innerPuzzle,
    required Program innerSolution,
  });
  Program getInnerPuzzle({
    required PuzzleInfo constructor,
    required Program puzzleReveal,
  });
  Program getInnerSolution({
    required PuzzleInfo constructor,
    required Program solution,
  });
}

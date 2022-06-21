import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/offert/models/puzzle_info.dart';
import 'package:chia_crypto_utils/src/offert/models/solver.dart';

import '../../cat/service/cat_outer_puzzle.dart';

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

abstract class OuterPuzzle {
  Program constructPuzzle({
    required PuzzleInfo constructor,
    required Program innerPuzzle,
  });
  Bytes createAssetId({
    required PuzzleInfo constructor,
  });
  PuzzleInfo? matchPuzzle(Program puzzle);
  Program solvePuzzle({
    required PuzzleInfo constructor,
    required Solver solver,
    required Program innerPuzzle,
    required Program innerSolution,
  });
}

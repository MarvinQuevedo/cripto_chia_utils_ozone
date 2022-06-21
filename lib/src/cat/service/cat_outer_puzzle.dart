import '../../core/models/outer_puzzle.dart';
import '../../offert/models/solver.dart';
import '../../offert/models/puzzle_info.dart';
import '../../../chia_crypto_utils.dart';
import '../../core/models/outer_puzzle.dart' as outerPuzzle;

class CATOuterPuzzle extends outerPuzzle.OuterPuzzle {
  @override
  Program constructPuzzle({required PuzzleInfo constructor, required Program innerPuzzle}) {
    return CatWalletService.makeCatPuzzle(constructor.info["tail"]!, innerPuzzle);
  }

  @override
  Bytes createAssetId({required PuzzleInfo constructor}) {
    return constructor.info["tail"]!;
  }

  @override
  PuzzleInfo? matchPuzzle(Program puzzle) {
    final matched = CatWalletService.matchCatPuzzle(puzzle);
    if (matched != null) {
      final Map<String, dynamic> constructorDict = {
        "type": AssetType.CAT,
        "tail": matched.assetId.toHexWithPrefix(),
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
    final Bytes coinBytes = solver.info["coin"];

    final CoinPrototype coin = CoinPrototype.fromStream(coinBytes.iterator);
    final CoinSpend parentSpend = CoinSpend.fromStream(solver.info["parent_spend"]);

    if (constructor.also != null) {
      innerPuzzle = outerPuzzle.constructPuzzle(
        constructor: constructor.also!,
        innerPuzzle: innerPuzzle,
      );
      innerSolution = outerPuzzle.solvePuzzle(
        constructor: constructor.also!,
        solver: solver,
        innerPuzzle: innerPuzzle,
        innerSolution: innerSolution,
      );
    }
    final matched = CatWalletService.matchCatPuzzle(parentSpend.puzzleReveal);
    if (matched == null) {
      throw Exception("Could not match puzzle");
    }

    final catCoin = CatCoin(
      parentCoinSpend: parentSpend,
      coin: coin,
    );

    final spendableCat = SpendableCat(
      coin: catCoin,
      innerPuzzle: innerPuzzle,
      innerSolution: innerSolution,
    );

    return CatWalletService.makeUnsignedSpendBundleForSpendableCats([
      spendableCat,
    ]).coinSpends.first.solution;
  }
}

import 'package:quiver/iterables.dart';

import '../../core/models/outer_puzzle.dart';
import '../../../chia_crypto_utils.dart';
import '../../core/models/outer_puzzle.dart' as outerPuzzle;
import '../../offer/models/puzzle_info.dart';
import '../../offer/models/solver.dart';

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
    final Bytes tailHash = solver.info["tail"];
    final spendableCatsList = <SpendableCat>[];

    CoinPrototype? targetCoin;
    final siblingsIter = (solver["siblings"] as Program).toList();
    final siblingSpends = (solver.info["sibling_spends"] as Program).toList();
    final siblingPuzzles = (solver.info["sibling_puzzles"] as Program).toList();
    final siblingSolutions = (solver.info["sibling_solutions"] as Program).toList();
    final zipped = zip([
      siblingsIter,
      siblingSpends,
      siblingPuzzles,
      siblingSolutions,
    ]);
    final base = [
      (solver["coin"]) as Program,
      (solver["parent_spend"]) as Program,
      innerPuzzle,
      innerSolution,
    ];
    final workIterable = zipped.toList()..add(base);
    for (var item in workIterable) {
      final coinProg = item[0];
      final spendProg = item[1];
      Program puzzle = item[2];
      Program solution = item[3];

      final coinBytes = coinProg.atom;

      final coin = CoinPrototype.fromBytes(coinBytes);
      if (coinBytes == solver["coin"]) {
        targetCoin = coin;
      }
      final parentSpend = CoinSpend.fromBytes(spendProg.atom);
      // final parentCoin = parentSpend.coin;
      if (constructor.also != null) {
        puzzle = outerPuzzle.constructPuzzle(constructor: constructor.also!, innerPuzzle: puzzle);
        solution = outerPuzzle.solvePuzzle(
            constructor: constructor.also!,
            solver: solver,
            innerPuzzle: innerPuzzle,
            innerSolution: innerSolution);
      }
      final matched = CatWalletService.matchCatPuzzle(parentSpend.puzzleReveal);
      assert(matched != null, "Cat puzzle can be match");
      //final parentInnerPuzzle = matched!.innerPuzzle;
      final catCoin = CatCoin(parentCoinSpend: parentSpend, coin: coin);

      // the [lineage_proof] is calc in the constructor of the [SpendableCat]
      final spendableCat = SpendableCat(
        coin: catCoin,
        innerPuzzle: puzzle,
        innerSolution: solution,
      );
      spendableCatsList.add(spendableCat);
    }

    return CatWalletService.makeUnsignedSpendBundleForSpendableCats(spendableCatsList)
        .coinSpends
        .where((element) => element.coin == targetCoin)
        .first
        .solution;
  }
}

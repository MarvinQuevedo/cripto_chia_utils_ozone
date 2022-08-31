import '../../../chia_crypto_utils.dart';
import '../../core/models/outer_puzzle.dart' as outerPuzzle;
import '../models/deconstructed_singleton_puzzle.dart';

DeconstructedSingletonPuzzle? mathSingletonPuzzle(Program puzzle) {
  final uncurried = puzzle.uncurry();
  if (uncurried.program == SINGLETON_MOD) {
    final nftArgs = uncurried.arguments;

    final singletonStruct = nftArgs[0];
    final sinletonModHash = singletonStruct.first();
    final singletonLauncherId = singletonStruct.rest().first();
    final launcherPuzzhash = singletonStruct.rest().rest();

    return DeconstructedSingletonPuzzle(
        innerPuzzle: nftArgs[1],
        launcherPuzzhash: Puzzlehash(launcherPuzzhash.atom),
        singletonLauncherId: Puzzlehash(singletonLauncherId.atom),
        sinletonModHash: Puzzlehash(sinletonModHash.atom));
  }
  return null;
}

Program solutionForSingleton({
  required LineageProof lineageProof,
  required int amount,
  required Program innerSolution,
}) {
  Program parentInfo;

  if (lineageProof.innerPuzzleHash == null) {
    parentInfo = Program.list([
      Program.fromBytes(
        lineageProof.parentName!,
      ),
      Program.fromInt(lineageProof.amount!)
    ]);
  } else {
    parentInfo = Program.list([
      Program.fromBytes(
        lineageProof.parentName!,
      ),
      Program.fromBytes(
        lineageProof.innerPuzzleHash!,
      ),
      Program.fromInt(lineageProof.amount!)
    ]);
  }

  return Program.list([
    parentInfo,
    Program.fromInt(amount),
    innerSolution,
  ]);
}

class SingletonOuterPuzzle extends outerPuzzle.OuterPuzzle {
  @override
  Program constructPuzzle({required PuzzleInfo constructor, required Program innerPuzzle}) {
    if (constructor.also != null) {
      innerPuzzle =
          outerPuzzle.constructPuzzle(constructor: constructor.also!, innerPuzzle: innerPuzzle);
    }

    Bytes launcherHash = SINGLETON_LAUNCHER_HASH;
    final Bytes launcherId = Bytes.fromHex(constructor["launcher_id"]);
    if (constructor["launcher_ph"] != null) {
      launcherHash = Bytes.fromHex(constructor["launcher_ph"]);
    }
    return SingletonService.puzzleForSingleton(
      launcherId,
      innerPuzzle,
      launcherHash: launcherHash,
    );
  }

  @override
  Puzzlehash? createAssetId({required PuzzleInfo constructor}) {
    return Puzzlehash.fromHex(constructor["launcher_id"]);
  }

  @override
  PuzzleInfo? matchPuzzle(Program puzzle) {
    final matched = mathSingletonPuzzle(puzzle);
    if (matched != null) {
      final Map<String, dynamic> constructorDict = {
        "type": "singleton",
        "launcher_id": matched.launcherPuzzhash.toHexWithPrefix(),
        "launcher_ph": matched.launcherPuzzhash.toHexWithPrefix(),
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
    Bytes coinBytes;

    if (solver["coin"] is Bytes) {
      coinBytes = solver["coin"];
    } else {
      coinBytes = Bytes.fromHex(solver["coin"] as String);
    }

    final coin = CoinPrototype.fromBytes(coinBytes);
    final parentSpend = CoinSpend.fromBytes(Bytes.fromHex(solver["parent_spend"]));
    final parentCoin = parentSpend.coin;
    if (constructor.also != null) {
      innerSolution = outerPuzzle.solvePuzzle(
          constructor: constructor.also!,
          solver: solver,
          innerPuzzle: innerPuzzle,
          innerSolution: innerSolution);
    }
    final mathced = mathSingletonPuzzle(parentSpend.puzzleReveal);
    if (mathced == null) {
      throw Exception("Math fail SingletonPuzzle");
    }

    return solutionForSingleton(
      lineageProof: LineageProof(
          parentName: parentCoin.parentCoinInfo,
          innerPuzzleHash: mathced.innerPuzzle.hash(),
          amount: parentCoin.amount),
      amount: coin.amount,
      innerSolution: innerSolution,
    );
  }

  @override
  Program? getInnerPuzzle({required PuzzleInfo constructor, required Program puzzleReveal}) {
    final matched = mathSingletonPuzzle(puzzleReveal);
    if (matched != null) {
      final innerPuzzle = matched.innerPuzzle;
      if (constructor.also != null) {
        final deepInnerPuzzle = outerPuzzle.getInnerPuzzle(
          constructor: constructor.also!,
          puzzleReveal: puzzleReveal,
        );
        return deepInnerPuzzle;
      }
      return innerPuzzle;
    } else {
      throw Exception("This driver is not for the specified puzzle reveal");
    }
  }

  @override
  Program? getInnerSolution({required PuzzleInfo constructor, required Program solution}) {
    final myInnerSolution = solution.filterAt("rrf");
    if (constructor.also != null) {
      final deepInnerSolution = outerPuzzle.getInnerSolution(
        constructor: constructor.also!,
        solution: myInnerSolution,
      );
      return deepInnerSolution;
    }
    return myInnerSolution;
  }
}

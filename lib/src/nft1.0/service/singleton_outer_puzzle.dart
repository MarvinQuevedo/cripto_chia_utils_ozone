import '../../../chia_crypto_utils.dart';
import '../models/deconstructed_singleton_puzzle.dart';

DeconstructedSingletonPuzzle? mathSingletonPuzzle(Program puzzle) {
  final uncurried = puzzle.uncurry();
  if (uncurried.program.hash() == SINGLETON_TOP_LAYER_MOD_V1_1_HASH) {
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

class SingletonOuterPuzzle extends OuterPuzzle {
  @override
  Program constructPuzzle({required PuzzleInfo constructor, required Program innerPuzzle}) {
    if (constructor.also != null) {
      innerPuzzle = OuterPuzzleDriver.constructPuzzle(
          constructor: constructor.also!, innerPuzzle: innerPuzzle);
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
        "type": AssetType.SINGLETON,
        "launcher_id": matched.singletonLauncherId.toHexWithPrefix(),
        "launcher_ph": matched.launcherPuzzhash.toHexWithPrefix(),
      };
      final next = OuterPuzzleDriver.matchPuzzle(matched.innerPuzzle);
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
    CoinSpend parentSpend;
    if (solver["parent_spend"] is String) {
      parentSpend = CoinSpend.fromBytes(
        Bytes.fromHex(solver["parent_spend"]),
      );
    } else if (solver["parent_spend"] is Bytes) {
      parentSpend = CoinSpend.fromBytes(Bytes.fromHex(solver["parent_spend"]));
    } else {
      parentSpend = solver["parent_spend"] as CoinSpend;
    }

    final parentCoin = parentSpend.coin;

    if (constructor.also != null) {
      innerSolution = OuterPuzzleDriver.solvePuzzle(
          constructor: constructor.also!,
          solver: solver,
          innerPuzzle: innerPuzzle,
          innerSolution: innerSolution);
    }
    final matched = mathSingletonPuzzle(parentSpend.puzzleReveal);
    if (matched == null) {
      throw Exception("Math fail SingletonPuzzle");
    }
    final parentInnerPuzzle = matched.innerPuzzle;

    return solutionForSingleton(
      lineageProof: LineageProof(
          parentName: Puzzlehash(parentCoin.parentCoinInfo),
          innerPuzzleHash: parentInnerPuzzle.hash(),
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
        final deepInnerPuzzle = OuterPuzzleDriver.getInnerPuzzle(
          constructor: constructor.also!,
          puzzleReveal: innerPuzzle,
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
      final deepInnerSolution = OuterPuzzleDriver.getInnerSolution(
        constructor: constructor.also!,
        solution: myInnerSolution,
      );
      return deepInnerSolution;
    }
    return myInnerSolution;
  }
}

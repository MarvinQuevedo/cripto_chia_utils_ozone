// ignore_for_file: lines_longer_than_80_chars

import 'dart:typed_data';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class SingletonService extends BaseWalletService {
  /// Return the puzzle reveal of a singleton with specific ID and innerpuz
  static Program puzzleForSingleton(
    Bytes launcherId,
    Program innerPuzzle, {
    Bytes? launcherHash,
  }) {
    return SINGLETON_MOD_V1.curry([
      Program.cons(
        Program.fromBytes(SINGLETON_MOD_V1.hash()),
        Program.cons(
          Program.fromBytes(launcherId),
          Program.fromBytes(
            launcherHash ?? SINGLETON_MOD_V1.hash(),
          ),
        ),
      ),
      innerPuzzle
    ]);
  }

  static Program makeSingletonStructureProgram(Bytes coinId) => Program.cons(
        Program.fromBytes(singletonTopLayerV1Program.hash()),
        Program.cons(
          Program.fromBytes(coinId),
          Program.fromBytes(singletonLauncherProgram.hash()),
        ),
      );

  static Program makeSingletonLauncherSolution(
    int amount,
    Puzzlehash puzzlehash,
  ) =>
      Program.list([
        Program.fromBytes(puzzlehash),
        Program.fromInt(amount),
        Program.fromBytes(List.filled(128, 0)),
      ]);

  static Program createP2SingletonPuzzle({
    required Bytes singletonModHash,
    required Bytes launcherId,
    required int secondsDelay,
    required Puzzlehash delayedPuzzlehash,
  }) {
    return p2SingletonOrDelayedPuzhashProgram.curry([
      Program.fromBytes(singletonModHash),
      Program.fromBytes(launcherId),
      Program.fromBytes(singletonLauncherProgram.hash()),
      Program.fromBytes(intToBytesStandard(secondsDelay, Endian.big)),
      Program.fromBytes(delayedPuzzlehash),
    ]);
  }

  static Future<Program> createP2SingletonPuzzleAsync({
    required Bytes singletonModHash,
    required Bytes launcherId,
    required int secondsDelay,
    required Puzzlehash delayedPuzzlehash,
  }) {
    return p2SingletonOrDelayedPuzhashProgram.curryAsync([
      Program.fromBytes(singletonModHash),
      Program.fromBytes(launcherId),
      Program.fromBytes(singletonLauncherProgram.hash()),
      Program.fromBytes(intToBytesStandard(secondsDelay, Endian.big)),
      Program.fromBytes(delayedPuzzlehash),
    ]);
  }

  static CoinPrototype getMostRecentSingletonCoinFromCoinSpend(CoinSpend coinSpend) {
    final additions = coinSpend.additions;
    // cribbed from https://github.com/Chia-Network/chia-blockchain/blob/4230af1a59768f6a4f9578408f810d7d2114c343/chia/pools/pool_puzzles.py#L284
    return additions.singleWhere((coin) => coin.amount.isOdd);
  }
}

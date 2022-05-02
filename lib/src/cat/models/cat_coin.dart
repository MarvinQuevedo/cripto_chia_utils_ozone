// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:chia_utils/src/cat/exceptions/invalid_cat_exception.dart';
import 'package:chia_utils/src/cat/puzzles/cat/cat.clvm.hex.dart';
import 'package:meta/meta.dart';

@immutable
class CatCoin extends CoinPrototype {
  final CoinSpend parentCoinSpend;
  final Puzzlehash assetId;
  final Program lineageProof;

  CatCoin({
    required this.parentCoinSpend,
    required CoinPrototype coin,
  })  : assetId = parentCoinSpend.puzzleReveal.uncurry().arguments.length > 1
            ? Puzzlehash(
                parentCoinSpend.puzzleReveal.uncurry().arguments[1].atom,
              )
            : throw InvalidCatException(),
        lineageProof = parentCoinSpend.puzzleReveal.uncurry().arguments.length >
                2
            ? Program.list([
                Program.fromBytes(
                  parentCoinSpend.coin.parentCoinInfo,
                ),
                // third argument to the cat puzzle is the inner puzzle
                Program.fromBytes(
                  parentCoinSpend.puzzleReveal.uncurry().arguments[2].hash(),
                ),
                Program.fromInt(parentCoinSpend.coin.amount)
              ])
            : throw InvalidCatException(),
        super(
          parentCoinInfo: coin.parentCoinInfo,
          puzzlehash: coin.puzzlehash,
          amount: coin.amount,
        ) {
    final uncurriedParentPuzzleReveal = parentCoinSpend.puzzleReveal.uncurry();
    if (uncurriedParentPuzzleReveal.program.toSource() !=
        catProgram.toSource()) {
      throw InvalidCatException();
    }
  }

  CatCoin.eve({
    required this.parentCoinSpend,
    required CoinPrototype coin,
    required this.assetId,
  })  : lineageProof = Program.nil,
        super(
          parentCoinInfo: coin.parentCoinInfo,
          puzzlehash: coin.puzzlehash,
          amount: coin.amount,
        );

  @override
  String toString() => 'CatCoin(id: $id, parentCoinInfo: $parentCoinInfo, puzzlehash: $puzzlehash, amount: $amount, assetId: $assetId)';
}

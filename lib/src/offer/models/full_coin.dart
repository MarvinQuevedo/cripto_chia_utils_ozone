import 'package:chia_crypto_utils/chia_crypto_utils.dart';

Puzzlehash? _getTailHash(CoinSpend? parentCoinSpend) {
  try {
    final arguments = parentCoinSpend!.puzzleReveal.uncurry().arguments;
    if (arguments.length > 1) {
      return Puzzlehash(parentCoinSpend.puzzleReveal.uncurry().arguments[1].atom);
    }
    return null;
  } catch (e) {
    return null;
  }
}

class FullCoin extends CoinPrototype {
  final CoinSpend? parentCoinSpend;
  late final Puzzlehash? assetId;
  late final Program lineageProof;
  late final Coin coin;
  bool get isCatCoin {
    final uncurriedParentPuzzleReveal = parentCoinSpend?.puzzleReveal.uncurry();
    if (uncurriedParentPuzzleReveal == null) {
      return false;
    } else {
      return true;
    }
  }

  FullCoin({
    this.parentCoinSpend,
    required this.coin,
  })  : assetId = _getTailHash(parentCoinSpend),
        lineageProof = (parentCoinSpend?.puzzleReveal.uncurry().arguments.length ?? 0) > 2
            ? Program.list([
                Program.fromBytes(
                  parentCoinSpend!.coin.parentCoinInfo,
                ),
                // third argument to the cat puzzle is the inner puzzle
                Program.fromBytes(
                  parentCoinSpend.puzzleReveal.uncurry().arguments[2].hash(),
                ),
                Program.fromInt(parentCoinSpend.coin.amount)
              ])
            : Program.nil,
        super(
          parentCoinInfo: coin.parentCoinInfo,
          puzzlehash: coin.puzzlehash,
          amount: coin.amount,
        );

  CatCoin toCatCoin() {
    return CatCoin(parentCoinSpend: parentCoinSpend!, coin: coin);
  }

  @override
  String toString() =>
      'CatCoin(id: $id, parentCoinSpend: $parentCoinSpend, assetId: $assetId, lineageProof: $lineageProof)';

  factory FullCoin.fromCoin(Coin coin, CoinSpend parentCoinSpend) {
    return FullCoin(parentCoinSpend: parentCoinSpend, coin: coin);
  }
  /*  factory FullCoin.fromCatCoin(CatCoin catCoin) {
    return FullCoin(
      parentCoinSpend: catCoin.parentCoinSpend,
      coin: catCoin.toCoinPrototype(),
    );
  } */
}

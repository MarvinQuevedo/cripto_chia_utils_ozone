import 'package:chia_crypto_utils/src/nft1.0/index.dart';

import '../../clvm.dart';
import '../../singleton/index.dart';

Program createNftLayerPuzzleWithCurryParams({
  required Program metadata,
  required Bytes metadataUpdaterHash,
  required Program innerPuzzle,
}) {
  return puzzleForMetadataLayer(
    metadata: metadata,
    metadataUpdaterHash: metadataUpdaterHash,
    innerPuzzle: innerPuzzle,
  );
}

Program createFullPuzzleWithNftPuzzle({
  required Bytes singletonId,
  required Program innerPuzzle,
}) {
  return SingletonService.puzzleForSingleton(
    singletonId,
    innerPuzzle,
    launcherHash: LAUNCHER_PUZZLE_HASH,
  );
}

Program createFullPuzzle(
    {required Bytes singletonId,
    required Program metadata,
    required Bytes metadataUpdaterHash,
    required Program innerPuzzle}) {
  final singletonStruct = Program.cons(
    Program.fromBytes(SINGLETON_MOD_HASH),
    Program.cons(
      Program.fromBytes(singletonId),
      Program.fromBytes(
        LAUNCHER_PUZZLE_HASH,
      ),
    ),
  );

  final sinletonInnerPuzzle = createNftLayerPuzzleWithCurryParams(
    metadata: metadata,
    metadataUpdaterHash: metadataUpdaterHash,
    innerPuzzle: innerPuzzle,
  );

  return SINGLETON_TOP_LAYER_MOD.curry([singletonStruct, sinletonInnerPuzzle]);
}

NFTInfo getNftInfoFromPuzzle(NFTCoinInfo nftCoinInfo) {
  final uncurriedNft = UncurriedNFT.uncurry(nftCoinInfo.fullPuzzle);
  return NFTInfo.fromUncurried(
    uncurriedNFT: uncurriedNft,
    currentCoin: nftCoinInfo.coin,
    mintHeight: nftCoinInfo.mintHeight,
  );
}

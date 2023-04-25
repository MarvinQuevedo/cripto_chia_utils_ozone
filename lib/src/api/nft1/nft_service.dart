import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class NftService {
  final ChiaFullNodeInterface fullNode;
  final WalletKeychain keychain;
  NftService({
    required this.fullNode,
    required this.keychain,
  });

  StandardWalletService get walletService => StandardWalletService();

  /// convert FullCoin to use to transfer or for request offer
  Future<FullNFTCoinInfo> convertFullCoin(FullCoin coin) async {
    final nftInfo = await NftWallet().getNFTFullCoinInfo(coin, buildKeychain: (phs) async {
      final founded = phs.where((element) =>
          keychain.getWalletVector(
            element,
          ) !=
          null);
      if (founded.length == phs.length) {
        return keychain;
      }
      return null;
    });
    return nftInfo.item1;
  }

  /// Get the coins of the keychain(balance)
  Future<List<FullCoin>> getNFTCoins({
    int? startHeight,
    int? endHeight,
    bool includeSpentCoins = false,
  }) async {
    return fullNode.getNftCoinsByInnerPuzzleHashes(
      keychain.puzzlehashes,
      endHeight: endHeight,
      includeSpentCoins: includeSpentCoins,
      startHeight: startHeight,
    );
  }

  /// Allow prepare nft coin for transfer of requested in Offer
  Future<FullNFTCoinInfo?> getNFTFullCoinByLauncherId(
    Puzzlehash launcherId,
  ) async {
    final mainChildrens = await fullNode.getCoinsByParentIds(
      [launcherId],
      includeSpentCoins: true,
    );
    final mainHidratedCoins = await fullNode.hydrateFullCoins(mainChildrens);
    FullCoin? nftCoin;
    final nftCoins = mainHidratedCoins.where((e) => e.type == SpendType.nft).toList();
    if (nftCoins.length == 1) {
      nftCoin = nftCoins.first;
    } else {
      for (final coin in nftCoins) {
        final uncurriedNft = UncurriedNFT.tryUncurry(coin.parentCoinSpend!.puzzleReveal);
        if (uncurriedNft != null) {
          if (uncurriedNft.singletonLauncherId.toBytes().toHex() == launcherId.toHex()) {
            nftCoin = coin;
            break;
          }
        }
      }
    }

    if (nftCoin == null) {
      throw Exception("Can't be found the NFT coin with launcher ${launcherId}");
    }
    final lastCoin = await fullNode.getLasUnespentSingletonCoin(nftCoin);
    return convertFullCoin(lastCoin);
  }

  /// Allow transfer a NFT to other wallet
  Future<ChiaBaseResponse> transferNFt(
      {required Puzzlehash targePuzzlehash,
      required FullNFTCoinInfo nftCoinInfo,
      int fee = 0,
      required List<CoinPrototype> standardCoinsForFee,
      required Puzzlehash changePuzzlehash}) async {
    final spendBundle = await NftWallet().createTransferSpendBundle(
      nftCoin: nftCoinInfo.toNftCoinInfo(),
      keychain: keychain,
      targetPuzzleHash: targePuzzlehash,
      standardCoinsForFee: standardCoinsForFee,
      fee: fee,
      changePuzzlehash: changePuzzlehash,
    );
    final response = await fullNode.pushTransaction(spendBundle);
    return response;
  }
}

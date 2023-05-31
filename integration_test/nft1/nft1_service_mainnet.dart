import 'dart:io';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/api/full_node/full_node_utils.dart';
import 'package:chia_crypto_utils/src/api/nft1/nft_service.dart';
import 'package:test/test.dart';

Future<void> main() async {
  final fullNodeUtils = FullNodeUtils(Network.mainnet, url: "https://chia.green-app.io/full-node");
  try {
    await fullNodeUtils.checkIsRunning();
  } catch (e) {
    print(e);
    return;
  }

  final mnemonic =
      'blast song refuse excess filter unhappy tag extra bless grain broom vanish'.split(' ');

  final keychainSecret = KeychainCoreSecret.fromMnemonic(mnemonic);
  final walletsSetList = <WalletSet>[];
  for (var i = 0; i < 5; i++) {
    final set1 = WalletSet.fromPrivateKey(keychainSecret.masterPrivateKey, i);
    walletsSetList.add(set1);
  }

  final keychain = WalletKeychain.fromWalletSets(walletsSetList);

  ChiaNetworkContextWrapper().registerNetworkContext(Network.mainnet);
  final fullNodeRpc = FullNodeHttpRpc(
    fullNodeUtils.url,
    certBytes: fullNodeUtils.certBytes,
    keyBytes: fullNodeUtils.keyBytes,
  );

  final fullNode = ChiaFullNodeInterface(fullNodeRpc);
  final nftService = NftNodeWalletService(fullNode: fullNode, keychain: keychain);

  List<FullCoin>? nftCoins;

  FullNFTCoinInfo? nftFullCoin;
  test('Get NFT Coins', () async {
    nftCoins = await nftService.getNFTCoins(includeSpentCoins: false, startHeight: 3663980);
    print(nftCoins!);
    expect(nftCoins!, isNotEmpty);
  }, timeout: Timeout(Duration(minutes: 1)));

  test('Get full coins for test', () async {
    for (final nftCoin in nftCoins!) {
      final nftFullCoin_ = await nftService.convertFullCoin(nftCoin);
      final nftInfo = nftFullCoin_.toNftCoinInfo();

      final uncurriedNft = UncurriedNFT.uncurry(nftInfo.fullPuzzle);
      if (uncurriedNft.supportDid) {
        expect(nftInfo.minterDid, isNotNull);
      }

      final launcherId = uncurriedNft.singletonLauncherId.atom;
      final _ = NftAddress.fromPuzzlehash(Puzzlehash(launcherId)).address;
      final walletVector = keychain.getWalletVector(uncurriedNft.p2PuzzleHash);
      expect(walletVector, isNotNull);
    }
  });

  test('Get full coin for transfer', () async {
    final nftCoin = nftCoins!.first;
    nftFullCoin = await nftService.convertFullCoin(nftCoin);
    final nftInfo = nftFullCoin!.toNftCoinInfo();

    final uncurriedNft = UncurriedNFT.uncurry(nftInfo.fullPuzzle);
    if (uncurriedNft.supportDid) {
      expect(nftInfo.minterDid, isNotNull);
    }
    final walletVector = keychain.getWalletVector(uncurriedNft.p2PuzzleHash);
    expect(walletVector, isNotNull);
  });

  test('Get  third full coin with launcher ID', () async {
    final nftId = NftAddress("nft1q85vya07qtwvv9gdf66vd8sghgl9l3qa98hvt5gmade9rk4ddczsynl2ec");
    final thirdFullCoin = await nftService.getNFTFullCoinByLauncherId(nftId.toPuzzlehash());

    expect(thirdFullCoin, isNotNull);
  });

  test('Transfer NFT', () async {
    List<CoinPrototype> xchCoins = await fullNode.getCoinsByPuzzleHashes(keychain.puzzlehashes);
    final targePuzzlehash = keychain.puzzlehashes[3];
    final changePuzzlehash = keychain.puzzlehashes[2];
    final response = await nftService.transferNFt(
      targePuzzlehash: targePuzzlehash,
      nftCoinInfo: nftFullCoin!,
      standardCoinsForFee: xchCoins,
      changePuzzlehash: changePuzzlehash,
    );
    expect(response.success, true);
  });
}

class FullNodeUtilsWindows {
  static const String defaultUrl = 'https://localhost:8555';

  final String url;
  final Network network;

  FullNodeUtilsWindows(this.network, {this.url = defaultUrl});

  Bytes get certBytes {
    return _getAuthFileBytes('$sslPath\\private_full_node.crt');
  }

  String get checkNetworkMessage => 'Check if your full node is runing on $network';

  Bytes get keyBytes {
    return _getAuthFileBytes('$sslPath\\private_full_node.key');
  }

  String get sslPath =>
      '${Platform.environment['HOMEPATH']}\\.chia\\mainnet\\config\\ssl\\full_node';

  Future<void> checkIsRunning() async {
    final fullNodeRpc = FullNodeHttpRpc(
      url,
      certBytes: certBytes,
      keyBytes: keyBytes,
    );

    final fullNode = ChiaFullNodeInterface(fullNodeRpc);
    await fullNode.getBlockchainState();
  }

  static Bytes _getAuthFileBytes(String pathToFile) {
    LoggingContext()
      ..info(null, highLog: 'auth file loaded: $pathToFile')
      ..info(null, highLog: 'file contents:')
      ..info(null, highLog: File(pathToFile).readAsStringSync());
    return Bytes(File(pathToFile).readAsBytesSync());
  }
}

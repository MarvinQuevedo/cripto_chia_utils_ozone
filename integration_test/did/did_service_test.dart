import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/api/did/did_service.dart';
import 'package:test/test.dart';

import '../nft1/nft1_service_test.dart';

Future<void> main() async {
  final fullNodeUtils = FullNodeUtilsWindows(Network.testnet10);
  try {
    await fullNodeUtils.checkIsRunning();
  } catch (e) {
    print(e);
    return;
  }

  final mnemonic =
      'kitten seat dial receive water peasant obvious tuition rifle ethics often improve mutual invest gospel unaware cushion trigger credit scare critic edge digital valid'
          .split(' ');

  final keychainSecret = KeychainCoreSecret.fromMnemonic(mnemonic);
  final walletsSetList = <WalletSet>[];
  for (var i = 0; i < 5; i++) {
    final set1 = WalletSet.fromPrivateKey(keychainSecret.masterPrivateKey, i);
    walletsSetList.add(set1);
  }

  final keychain = WalletKeychain.fromWalletSets(walletsSetList);

  ChiaNetworkContextWrapper().registerNetworkContext(Network.testnet10);
  final fullNodeRpc = FullNodeHttpRpc(
    fullNodeUtils.url,
    certBytes: fullNodeUtils.certBytes,
    keyBytes: fullNodeUtils.keyBytes,
  );

  final fullNode = ChiaFullNodeInterface(fullNodeRpc);
  final didService = DidService(fullNode: fullNode, keychain: keychain);

  List<FullCoin>? didCoins;

  DidInfo? didInfo;
  test('Get NFT Coins', () async {
    didCoins = await didService.getDIDCoins();
    print(didCoins!);
    expect(didCoins!, isNotEmpty);
  });

  test('Get Did info', () async {
    if (didCoins!.isNotEmpty) {
      final didCoin = didCoins![2];
      didInfo = await didService.getDidInfo(didCoin);

      expect(didInfo, isNotNull);
    }
  });

  test('Created DID', () async {
    List<CoinPrototype> xchCoins = await fullNode.getCoinsByPuzzleHashes(keychain.puzzlehashes);
    final targePuzzlehash = keychain.puzzlehashes[3];
    final changePuzzlehash = keychain.puzzlehashes[2];
    final response = await didService.createDid(
      targePuzzlehash: targePuzzlehash,
      coins: xchCoins,
      fee: 1000000,
      changePuzzlehash: changePuzzlehash,
    );
    expect(response.success, true);
  });
}

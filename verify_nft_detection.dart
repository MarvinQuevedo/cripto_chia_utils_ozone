import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/api/full_node/full_node_utils.dart';
import 'package:chia_crypto_utils/src/api/nft1/nft_service.dart';

Future<void> verifyNftDetection() async {
  print("🔍 Verificando detección de NFTs...");

  // Configurar full node
  final fullNodeUtils = FullNodeUtils(Network.mainnet, url: "https://chia.green-app.io/full-node");

  try {
    await fullNodeUtils.checkIsRunning();
    print("✅ Full node conectado");
  } catch (e) {
    print("❌ Error conectando al full node: $e");
    return;
  }

  // Crear keychain de prueba
  final mnemonic =
      'blast song refuse excess filter unhappy tag extra bless grain broom vanish'.split(' ');
  final keychainSecret = KeychainCoreSecret.fromMnemonic(mnemonic);
  final walletsSetList = <WalletSet>[];

  for (var i = 0; i < 5; i++) {
    final set1 = WalletSet.fromPrivateKey(keychainSecret.masterPrivateKey, i);
    walletsSetList.add(set1);
  }

  final keychain = WalletKeychain.fromWalletSets(walletsSetList);

  // Configurar full node
  ChiaNetworkContextWrapper().registerNetworkContext(Network.mainnet);
  final fullNodeRpc = FullNodeHttpRpc(
    fullNodeUtils.url,
    certBytes: fullNodeUtils.certBytes,
    keyBytes: fullNodeUtils.keyBytes,
  );

  final fullNode = ChiaFullNodeInterface(fullNodeRpc);
  final nftService = NftNodeWalletService(fullNode: fullNode, keychain: keychain);

  // Verificar constantes NFT
  print("\n🔧 Verificando constantes NFT...");
  print("   SINGLETON_TOP_LAYER_MOD_V1_1_HASH: ${SINGLETON_TOP_LAYER_MOD_V1_1_HASH.toHex()}");
  print("   NFT_STATE_LAYER_MOD_HASH: ${NFT_STATE_LAYER_MOD_HASH.toHex()}");

  // Verificar monedas por memo
  print("\n🔍 Verificando monedas por memo...");
  for (var i = 0; i < 3 && i < keychain.puzzlehashes.length; i++) {
    final puzzlehash = keychain.puzzlehashes[i];
    print("   Verificando puzzlehash ${i + 1}: ${puzzlehash.toHex()}");

    try {
      final coinsByMemo = await fullNode.getCoinsByMemo(puzzlehash, includeSpentCoins: true);
      print("     ✅ Encontradas ${coinsByMemo.length} monedas por memo");

      if (coinsByMemo.isNotEmpty) {
        // Verificar si alguna es singleton
        final singletonCoins = coinsByMemo
            .where((coin) => coin.puzzlehash == singletonLauncherProgram.hash())
            .toList();

        print("     📊 ${singletonCoins.length} monedas singleton encontradas");

        if (singletonCoins.isNotEmpty) {
          for (var j = 0; j < singletonCoins.length && j < 2; j++) {
            final singletonCoin = singletonCoins[j];
            print("       Singleton ${j + 1}: ${singletonCoin.id.toHex()}");

            try {
              final coinSpend = await fullNode.getCoinSpend(singletonCoin);
              if (coinSpend != null) {
                print("         Tipo detectado: ${coinSpend.type}");

                if (coinSpend.type == SpendType.nft) {
                  print("         🎉 ¡NFT válido detectado!");

                  // Intentar uncurry el NFT
                  try {
                    final uncurriedNft = UncurriedNFT.tryUncurry(coinSpend.puzzleReveal);
                    if (uncurriedNft != null) {
                      print("         ✅ NFT uncurry exitoso");
                      print(
                          "         Launcher ID: ${uncurriedNft.singletonLauncherId.atom.toHex()}");
                      print("         P2 Puzzle Hash: ${uncurriedNft.p2PuzzleHash.toHex()}");
                    } else {
                      print("         ❌ NFT uncurry falló");
                    }
                  } catch (e) {
                    print("         ❌ Error en uncurry: $e");
                  }
                } else {
                  print("         ⚠️ No es un NFT (tipo: ${coinSpend.type})");
                }
              } else {
                print("         ❌ No se pudo obtener coin spend");
              }
            } catch (e) {
              print("         ❌ Error analizando coin spend: $e");
            }
          }
        }
      }
    } catch (e) {
      print("     ❌ Error obteniendo monedas por memo: $e");
    }
  }

  // Verificar NFTs usando el servicio
  print("\n🖼️ Verificando NFTs usando NftNodeWalletService...");
  try {
    final nftCoins = await nftService.getNFTCoins(
      includeSpentCoins: false,
      startHeight: null,
      endHeight: null,
    );

    if (nftCoins.isEmpty) {
      print("   ⚠️ No se encontraron NFTs con el servicio");

      // Intentar con includeSpentCoins = true
      print("   🔍 Intentando con monedas gastadas incluidas...");
      final nftCoinsWithSpent = await nftService.getNFTCoins(
        includeSpentCoins: true,
        startHeight: null,
        endHeight: null,
      );

      if (nftCoinsWithSpent.isEmpty) {
        print("   ⚠️ Tampoco se encontraron NFTs con monedas gastadas");
      } else {
        print("   ✅ Encontrados ${nftCoinsWithSpent.length} NFTs (incluyendo gastados)");
      }
    } else {
      print("   ✅ Encontrados ${nftCoins.length} NFTs");
    }
  } catch (e) {
    print("   ❌ Error obteniendo NFTs: $e");
  }
}

void main() async {
  await verifyNftDetection();
}

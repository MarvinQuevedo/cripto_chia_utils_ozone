import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/api/full_node/full_node_utils.dart';
import 'package:chia_crypto_utils/src/api/nft1/nft_service.dart';

Future<void> checkNftByLauncher() async {
  print("🔍 Verificando NFT por Launcher ID...");

  // IMPORTANTE: Reemplaza con el Launcher ID real de tu NFT
  // final launcherIdHex = "tu_launcher_id_aqui";

  // Ejemplo de Launcher ID (reemplaza con uno real)
  final launcherIdHex = "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef";

  try {
    final launcherId = Puzzlehash.fromHex(launcherIdHex);
    print("🔍 Verificando Launcher ID: ${launcherId.toHex()}");

    // Configurar full node
    final fullNodeUtils =
        FullNodeUtils(Network.mainnet, url: "https://chia.green-app.io/full-node");

    try {
      await fullNodeUtils.checkIsRunning();
      print("✅ Full node conectado");
    } catch (e) {
      print("❌ Error conectando al full node: $e");
      return;
    }

    ChiaNetworkContextWrapper().registerNetworkContext(Network.mainnet);
    final fullNodeRpc = FullNodeHttpRpc(
      fullNodeUtils.url,
      certBytes: fullNodeUtils.certBytes,
      keyBytes: fullNodeUtils.keyBytes,
    );

    final fullNode = ChiaFullNodeInterface(fullNodeRpc);

    // Buscar monedas por parent ID (Launcher ID)
    print("\n🔍 Buscando monedas por Launcher ID...");
    try {
      final coinsByParent =
          await fullNode.getCoinsByParentIds([launcherId], includeSpentCoins: true);
      print("✅ Encontradas ${coinsByParent.length} monedas por Launcher ID");

      if (coinsByParent.isNotEmpty) {
        for (var i = 0; i < coinsByParent.length; i++) {
          final coin = coinsByParent[i];
          print("   Moneda ${i + 1}: ${coin.id.toHex()}");
          print("     Puzzlehash: ${coin.puzzlehash.toHex()}");
          print("     Es singleton: ${coin.puzzlehash == singletonLauncherProgram.hash()}");

          // Verificar si es un NFT
          try {
            final coinSpend = await fullNode.getCoinSpend(coin);
            if (coinSpend != null) {
              print("     Tipo: ${coinSpend.type}");

              if (coinSpend.type == SpendType.nft) {
                print("     🎉 ¡Es un NFT válido!");

                // Intentar obtener información del NFT
                try {
                  final uncurriedNft = UncurriedNFT.tryUncurry(coinSpend.puzzleReveal);
                  if (uncurriedNft != null) {
                    print("     ✅ NFT uncurry exitoso");
                    print("     Launcher ID: ${uncurriedNft.singletonLauncherId.atom.toHex()}");
                    print("     P2 Puzzle Hash: ${uncurriedNft.p2PuzzleHash.toHex()}");

                    // Verificar si el P2 puzzle hash está en nuestro keychain
                    final mnemonic =
                        'blast song refuse excess filter unhappy tag extra bless grain broom vanish'
                            .split(' ');
                    final keychainSecret = KeychainCoreSecret.fromMnemonic(mnemonic);
                    final walletsSetList = <WalletSet>[];

                    for (var j = 0; j < 20; j++) {
                      final set1 = WalletSet.fromPrivateKey(keychainSecret.masterPrivateKey, j);
                      walletsSetList.add(set1);
                    }

                    final keychain = WalletKeychain.fromWalletSets(walletsSetList);
                    final p2PuzzleHash = uncurriedNft.p2PuzzleHash;

                    if (keychain.puzzlehashes.contains(p2PuzzleHash)) {
                      print("     ✅ P2 Puzzle Hash está en nuestro keychain");
                    } else {
                      print("     ❌ P2 Puzzle Hash NO está en nuestro keychain");
                      print("     P2 Puzzle Hash: ${p2PuzzleHash.toHex()}");
                      print("     Direcciones en keychain:");
                      for (var k = 0; k < 5 && k < keychain.puzzlehashes.length; k++) {
                        print("       ${k + 1}: ${keychain.puzzlehashes[k].toHex()}");
                      }
                    }
                  } else {
                    print("     ❌ NFT uncurry falló");
                  }
                } catch (e) {
                  print("     ❌ Error en uncurry: $e");
                }
              } else {
                print("     ⚠️ No es un NFT (tipo: ${coinSpend.type})");
              }
            } else {
              print("     ❌ No se pudo obtener coin spend");
            }
          } catch (e) {
            print("     ❌ Error analizando coin spend: $e");
          }
        }
      } else {
        print("⚠️ No se encontraron monedas para este Launcher ID");
        print("💡 Posibles razones:");
        print("   1. El Launcher ID no existe");
        print("   2. El Launcher ID es incorrecto");
        print("   3. El NFT fue transferido o gastado");
      }
    } catch (e) {
      print("❌ Error buscando monedas por Launcher ID: $e");
    }
  } catch (e) {
    print("❌ Error con Launcher ID: $e");
    print("💡 Asegúrate de que el Launcher ID sea válido (64 caracteres hex)");
  }
}

void main() async {
  await checkNftByLauncher();
}

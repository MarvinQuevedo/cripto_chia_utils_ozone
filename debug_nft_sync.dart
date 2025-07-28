import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/api/full_node/full_node_utils.dart';
import 'package:chia_crypto_utils/src/api/nft1/nft_service.dart';

Future<void> debugNftSync() async {
  // Configurar el full node
  final fullNodeUtils = FullNodeUtils(Network.mainnet, url: "https://chia.green-app.io/full-node");

  try {
    await fullNodeUtils.checkIsRunning();
    print("✅ Full node está funcionando");
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

  print("🔑 Keychain creado con ${keychain.puzzlehashes.length} direcciones");
  print("📝 Primeras 3 direcciones:");
  for (var i = 0; i < 3 && i < keychain.puzzlehashes.length; i++) {
    print("   ${i + 1}: ${keychain.puzzlehashes[i].toHex()}");
  }

  // Configurar full node
  ChiaNetworkContextWrapper().registerNetworkContext(Network.mainnet);
  final fullNodeRpc = FullNodeHttpRpc(
    fullNodeUtils.url,
    certBytes: fullNodeUtils.certBytes,
    keyBytes: fullNodeUtils.keyBytes,
  );

  final fullNode = ChiaFullNodeInterface(fullNodeRpc);
  final nftService = NftNodeWalletService(fullNode: fullNode, keychain: keychain);

  // Verificar monedas estándar primero
  print("\n🔍 Verificando monedas estándar...");
  try {
    final standardCoins = await fullNode.getCoinsByPuzzleHashes(keychain.puzzlehashes);
    print("✅ Encontradas ${standardCoins.length} monedas estándar");
  } catch (e) {
    print("❌ Error obteniendo monedas estándar: $e");
  }

  // Verificar NFTs
  print("\n🖼️ Verificando NFTs...");
  try {
    final nftCoins = await nftService.getNFTCoins(
      includeSpentCoins: false,
      startHeight: null, // Sin filtro de altura
      endHeight: null,
    );

    if (nftCoins.isEmpty) {
      print("⚠️ No se encontraron NFTs");

      // Verificar si hay monedas singleton
      print("\n🔍 Verificando monedas singleton...");
      try {
        final allCoins =
            await fullNode.getCoinsByPuzzleHashes(keychain.puzzlehashes, includeSpentCoins: true);
        final singletonCoins =
            allCoins.where((coin) => coin.puzzlehash == singletonLauncherProgram.hash()).toList();

        print("📊 Encontradas ${singletonCoins.length} monedas singleton");

        if (singletonCoins.isNotEmpty) {
          print("🔍 Analizando primera moneda singleton...");
          final firstSingleton = singletonCoins.first;
          print("   ID: ${firstSingleton.id.toHex()}");
          print("   Puzzlehash: ${firstSingleton.puzzlehash.toHex()}");

          // Intentar obtener el coin spend
          try {
            final coinSpend = await fullNode.getCoinSpend(firstSingleton);
            if (coinSpend != null) {
              print("   ✅ Coin spend encontrado");
              print("   Tipo detectado: ${coinSpend.type}");

              if (coinSpend.type == SpendType.nft) {
                print("   🎉 ¡Es un NFT válido!");
              } else {
                print("   ⚠️ No se detectó como NFT (tipo: ${coinSpend.type})");
              }
            } else {
              print("   ❌ No se pudo obtener coin spend");
            }
          } catch (e) {
            print("   ❌ Error analizando coin spend: $e");
          }
        }
      } catch (e) {
        print("❌ Error verificando monedas singleton: $e");
      }
    } else {
      print("✅ Encontrados ${nftCoins.length} NFTs");

      // Mostrar detalles del primer NFT
      if (nftCoins.isNotEmpty) {
        final firstNft = nftCoins.first;
        print("\n📋 Detalles del primer NFT:");
        print("   Launcher ID: ${firstNft.coin.id.toHex()}");
        print("   Puzzlehash: ${firstNft.coin.puzzlehash.toHex()}");
        print("   Tipo: ${firstNft.type}");
      }
    }
  } catch (e) {
    print("❌ Error obteniendo NFTs: $e");
  }
}

void main() async {
  await debugNftSync();
}

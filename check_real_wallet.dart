import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/api/full_node/full_node_utils.dart';
import 'package:chia_crypto_utils/src/api/nft1/nft_service.dart';

Future<void> checkRealWallet() async {
  print("🔍 Verificando wallet real...");

  // IMPORTANTE: Reemplaza con tu mnemonic real
  // final mnemonic = 'tu mnemonic real aquí'.split(' ');

  // Por ahora usamos el mnemonic de prueba
  final mnemonic =
      'blast song refuse excess filter unhappy tag extra bless grain broom vanish'.split(' ');

  final keychainSecret = KeychainCoreSecret.fromMnemonic(mnemonic);
  final walletsSetList = <WalletSet>[];

  // Aumentar el número de direcciones para buscar más
  for (var i = 0; i < 20; i++) {
    final set1 = WalletSet.fromPrivateKey(keychainSecret.masterPrivateKey, i);
    walletsSetList.add(set1);
  }

  final keychain = WalletKeychain.fromWalletSets(walletsSetList);

  print("🔑 Keychain creado con ${keychain.puzzlehashes.length} direcciones");

  // Configurar full node
  final fullNodeUtils = FullNodeUtils(Network.mainnet, url: "https://chia.green-app.io/full-node");

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
  final nftService = NftNodeWalletService(fullNode: fullNode, keychain: keychain);

  // Buscar NFTs en todas las direcciones
  print("\n🖼️ Buscando NFTs en todas las direcciones...");

  int totalCoins = 0;
  int totalSingletonCoins = 0;
  int totalNfts = 0;

  for (var i = 0; i < keychain.puzzlehashes.length; i++) {
    final puzzlehash = keychain.puzzlehashes[i];

    try {
      final coinsByMemo = await fullNode.getCoinsByMemo(puzzlehash, includeSpentCoins: true);
      totalCoins += coinsByMemo.length;

      if (coinsByMemo.isNotEmpty) {
        final singletonCoins = coinsByMemo
            .where((coin) => coin.puzzlehash == singletonLauncherProgram.hash())
            .toList();

        totalSingletonCoins += singletonCoins.length;

        if (singletonCoins.isNotEmpty) {
          print("   📍 Dirección ${i + 1}: ${puzzlehash.toHex()}");
          print(
              "     Encontradas ${coinsByMemo.length} monedas, ${singletonCoins.length} singleton");

          for (final singletonCoin in singletonCoins) {
            try {
              final coinSpend = await fullNode.getCoinSpend(singletonCoin);
              if (coinSpend != null && coinSpend.type == SpendType.nft) {
                totalNfts++;
                print("     🎉 NFT encontrado: ${singletonCoin.id.toHex()}");
              }
            } catch (e) {
              // Ignorar errores individuales
            }
          }
        }
      }
    } catch (e) {
      // Ignorar errores de direcciones individuales
    }
  }

  print("\n📊 Resumen:");
  print("   Total de monedas encontradas: $totalCoins");
  print("   Total de monedas singleton: $totalSingletonCoins");
  print("   Total de NFTs válidos: $totalNfts");

  if (totalNfts == 0) {
    print("\n⚠️ No se encontraron NFTs en este wallet.");
    print("💡 Posibles razones:");
    print("   1. Este wallet no tiene NFTs");
    print("   2. Los NFTs están en direcciones no incluidas en el keychain");
    print("   3. Los NFTs están en un wallet diferente");
    print("   4. Los NFTs fueron transferidos o gastados");
  } else {
    print("\n✅ Se encontraron $totalNfts NFTs en este wallet.");
  }
}

void main() async {
  await checkRealWallet();
}

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:tuple/tuple.dart';

class DidService {
  final ChiaFullNodeInterface fullNode;
  final WalletKeychain keychain;
  DidService({
    required this.fullNode,
    required this.keychain,
  });

  StandardWalletService get walletService => StandardWalletService();

  /// Get the coins of the keychain(balance)
  Future<List<FullCoin>> getDIDCoins({
    int? startHeight,
    int? endHeight,
    bool includeSpentCoins = false,
  }) async {
    return fullNode.getDidCoinsByInnerPuzzleHashes(
      keychain.puzzlehashes,
      endHeight: endHeight,
      includeSpentCoins: includeSpentCoins,
      startHeight: startHeight,
    );
  }

  Future<DidInfo> getDidInfo(FullCoin didCoin) async {
    if (didCoin.parentCoinSpend!.type != SpendType.did) {
      throw Exception('Coin is not DID');
    }
    final parendSpend = didCoin.parentCoinSpend!;

    DidInfo? uncurriedInfo = DidInfo.uncurry(
      fullpuzzleReveal: parendSpend.puzzleReveal,
      solution: parendSpend.solution,
    );
    if (uncurriedInfo == null) {
      throw Exception('Coin is not DID');
    }
    final originCoins = await fullNode.getCoinsByParentIds([didCoin.coin.parentCoinInfo]);
    if (originCoins.isEmpty) {
      throw Exception("Can't find origin coin");
    }

    final singletonInnerPuzzleHash = uncurriedInfo.currentInner!.hash();

    uncurriedInfo = uncurriedInfo.copyWith(originCoin: originCoins.first);
    var actualCoinId = uncurriedInfo.originCoin!.id;
    while (true) {
      final children = await fullNode.getCoinsByParentIds([actualCoinId]);
      if (children.isEmpty) {
        break;
      }
      for (final coin in children) {
        final future_parent = LineageProof(
          parentName: Puzzlehash(coin.parentCoinInfo),
          innerPuzzleHash: singletonInnerPuzzleHash,
          amount: coin.amount,
        );

        uncurriedInfo.copyWith(
            parentInfo: uncurriedInfo.parentInfo
              ..add(
                Tuple2(
                  Puzzlehash(coin.id),
                  future_parent,
                ),
              ));
        actualCoinId = coin.id;
      }
    }

    return uncurriedInfo;
  }

  Future<ChiaBaseResponse> createDid(
      {required List<CoinPrototype> coins,
      required Puzzlehash changePuzzlehash,
      int fee = 0,
      int amount = 1,
      int? numOfBackupIdsNeeded,
      List<Puzzlehash>? backupsIds,
      Map<String, String> metadata = const {},
      required Puzzlehash tarjetPuzzlehash}) async {
    final didWallet = DidWallet();

    final result = await didWallet.createNewDid(
      coins: coins,
      keychain: keychain,
      fee: fee,
      amount: amount,
      backupsIds: backupsIds ?? [],
      changePuzzlehash: changePuzzlehash,
      p2Puzlehash: tarjetPuzzlehash,
      metadata: metadata,
      numOfBackupIdsNeeded: numOfBackupIdsNeeded,
    );
    if (result == null) {
      throw Exception('Error creating DID');
    }
    final spendBundle = result.item1;
    final response = await fullNode.pushTransaction(spendBundle);
    return response;
  }
}
import 'dart:convert';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/core/service/base_wallet.dart';

class DidWallet extends BaseWalletService {
  Future<SpendBundle> _generateNewDecentralisedId(
      {required int amount,
      int fee = 0,
      required List<CoinPrototype> coins,
      required WalletKeychain keychain,
      required Puzzlehash changePuzzlehash,
      required DidInfo didInfo}) async {
    final originCoin = coins.toList().last;
    final genesisLauncherPuz = singletonLauncherProgram;
    final launchercoin = CoinPrototype(
      parentCoinInfo: originCoin.id,
      puzzlehash: genesisLauncherPuz.hash(),
      amount: amount,
    );
    final p2Puzzle = getPuzzleFromPk(keychain.hardenedMap.values.first.childPublicKey);

    final didInner = getNewDidInnerPuz(
      coinName: launchercoin.id,
      didInfo: didInfo,
      p2Puzzle: p2Puzzle,
    );
    final didInnerHash = didInner.hash();
    final didFullPuz = createDidFullpuz(didInner, launchercoin.id);
    throw Exception("no implemented");
  }

  Future<SpendBundle> createNewDid({
    required int amount,
    List<Bytes> backupsIds = const [],
    int? numOfBackupIdsNeeded,
    Map<String, String> metadata = const {},
    String? name,
    int fee = 0,
    required List<CoinPrototype> coins,
    required WalletKeychain keychain,
    required Puzzlehash changePuzzlehash,
  }) async {
    if (numOfBackupIdsNeeded == null) {
      numOfBackupIdsNeeded = backupsIds.length;
    }
    if (numOfBackupIdsNeeded > backupsIds.length) {
      throw Exception("Cannot require more IDs than are known.");
    }
    final didInfo = DidInfo(
      originCoin: null,
      backupsIds: backupsIds,
      numOfBackupIdsNeeded: numOfBackupIdsNeeded,
      parentInfo: [],
      sentRecoveryTransaction: false,
      metadata: json.encode(metadata),
    );

    return _generateNewDecentralisedId(
      amount: amount,
      coins: coins,
      keychain: keychain,
      changePuzzlehash: changePuzzlehash,
      didInfo: didInfo,
      fee: fee,
    );
  }

  Program getNewDidInnerPuz({
    required DidInfo didInfo,
    Bytes? coinName,
    required Program p2Puzzle,
  }) {
    late Program innerpuz;
    if (didInfo.originCoin != null) {
      innerpuz = createDidInnerpuz(
        p2Puzzle: p2Puzzle,
        recoveryList: didInfo.backupsIds,
        numOfBackupIdsNeeded: didInfo.numOfBackupIdsNeeded,
        launcherId: didInfo.originCoin!.id,
        metadata: metadataToProgram(json.decode(didInfo.metadata)),
      );
    } else if (coinName != null) {
      innerpuz = createDidInnerpuz(
        p2Puzzle: p2Puzzle,
        recoveryList: didInfo.backupsIds,
        numOfBackupIdsNeeded: didInfo.numOfBackupIdsNeeded,
        launcherId: coinName,
        metadata: metadataToProgram(json.decode(didInfo.metadata)),
      );
    } else {
      throw Exception("must have origin coin");
    }
    return innerpuz;
  }
}
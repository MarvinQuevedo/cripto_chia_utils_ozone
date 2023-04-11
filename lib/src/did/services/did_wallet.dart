import 'dart:convert';

import '../../bls.dart';
import '../../clvm.dart';
import '../../core/index.dart';
import '../../core/service/conditions_utils.dart';
import '../../nft1.0/index.dart';
import '../../singleton/index.dart';
import '../../utils/key_derivation.dart';
import '../models/did_info.dart';
import '../puzzles/did_puzzles.dart' as didPuzzles;

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
      keychain: keychain,
    );
    final didInnerHash = didInner.hash();
    final didFullPuz = didPuzzles.createDidFullpuz(didInner, launchercoin.id);
    throw Exception("no implemented");
  }

  Future<SpendBundle> createNewDid({
    required int amount,
    List<Puzzlehash> backupsIds = const [],
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
    required WalletKeychain keychain,
  }) {
    late Program innerpuz;
    if (didInfo.originCoin != null) {
      innerpuz = didPuzzles.createDidInnerpuz(
        p2Puzzle: p2Puzzle,
        recoveryList: didInfo.backupsIds,
        numOfBackupIdsNeeded: didInfo.numOfBackupIdsNeeded,
        launcherId: didInfo.originCoin!.id,
        metadata: didPuzzles.metadataToProgram(json.decode(didInfo.metadata)),
      );
    } else if (coinName != null) {
      innerpuz = didPuzzles.createDidInnerpuz(
        p2Puzzle: p2Puzzle,
        recoveryList: didInfo.backupsIds,
        numOfBackupIdsNeeded: didInfo.numOfBackupIdsNeeded,
        launcherId: coinName,
        metadata: didPuzzles.metadataToProgram(json.decode(didInfo.metadata)),
      );
    } else {
      throw Exception("must have origin coin");
    }
    return innerpuz;
  }

  Future<SpendBundle> createMessageSpend(
    DidInfo didInfo, {
    Set<Bytes>? coinAnnouncements,
    Set<Bytes>? puzzleAnnouncements,
    Program? newInnerPuzzle,
    required List<CoinPrototype> coins,
    required WalletKeychain keychain,
  }) async {
    if (didInfo.currentInner == null || didInfo.originCoin == null) {
      throw Exception("didInfo.currentInner == null || didInfo.originCoin == null");
    }

    final coin = coins.first;
    final innerpuz = didInfo.currentInner!;
    if (newInnerPuzzle == null) {
      newInnerPuzzle = innerpuz;
    }
    final uncurried = didPuzzles.uncurryInnerpuz(newInnerPuzzle);
    assert(uncurried != null);
    final p2Puzzle = uncurried!.item1;

    final p2Solution = BaseWalletService.makeSolution(
      primaries: [
        Payment(coin.amount, newInnerPuzzle.hash(), memos: <Puzzlehash>[p2Puzzle.hash()]),
      ],
      coinAnnouncements: coinAnnouncements ?? {},
      puzzleAnnouncements: puzzleAnnouncements ?? {},
    );
    final innersol = Program.list([Program.fromInt(1), p2Solution]);
    final fullPuzzle = NftWalletService.createFullpuzzle(
      innerpuz,
      didInfo.originCoin!.id,
    );
    final parentInfo = didInfo.parentInfo.first.item2!;

    final fullsol = Program.list(
      [
        Program.list([
          Program.fromBytes(parentInfo.parentName!),
          Program.fromBytes(parentInfo.innerPuzzleHash!),
          Program.fromInt(parentInfo.amount!),
        ]),
        Program.fromInt(coin.amount),
        innersol,
      ],
    );
    final listOfCoinspends = <CoinSpend>[
      CoinSpend(coin: coin, puzzleReveal: fullPuzzle, solution: fullsol)
    ];
    final unsignedSpendBundle = SpendBundle(
      coinSpends: listOfCoinspends,
    );
    return sign(
      didInfo: didInfo,
      keychain: keychain,
      unsignedSpendBundle: unsignedSpendBundle,
    );
  }

  SpendBundle sign(
      {required SpendBundle unsignedSpendBundle,
      required WalletKeychain keychain,
      required DidInfo didInfo}) {
    final signatures = <JacobianPoint>[];
    for (final coinSpend in unsignedSpendBundle.coinSpends) {
      final uncurryPuzzleReveal = coinSpend.puzzleReveal.uncurry();

      final puzzleArgs = didPuzzles.matchDidPuzzle(
        mod: uncurryPuzzleReveal.program,
        curriedArgs: Program.list(uncurryPuzzleReveal.arguments),
      );
      if (puzzleArgs != null) {
        final p2Puzzle = puzzleArgs.first;
        final puzzleHash = p2Puzzle.hash();
        final targetWalletVector = keychain.getWalletVector(puzzleHash);
        final privateKey = targetWalletVector!.childPrivateKey;
        final synthSecretKey = calculateSyntheticPrivateKey(privateKey);

        final keys = <Bytes, PrivateKey>{
          targetWalletVector.childPublicKey.toBytes(): synthSecretKey,
        };
        final conditionsResult = conditionsDictForSolution(
            puzzleReveal: coinSpend.puzzleReveal, solution: coinSpend.solution);
        if (conditionsResult.item2 != null) {
          final pairs = pkmPairsForConditionsDict(
            conditionsDict: conditionsResult.item2!,
            additionalData: Bytes.fromHex(
              this.blockchainNetwork.aggSigMeExtraData,
            ),
            coinName: coinSpend.coin.id,
          );

          for (final pair in pairs) {
            final pk = pair.item1;
            final msg = pair.item2;
            try {
              final sk = keys[pk];
              if (sk != null) {
                final signature = AugSchemeMPL.sign(sk, msg);
                signatures.add(signature);
              } else {
                throw Exception("Cant foun sk for ${pk.toHex().substring(0, 5)}...}");
              }
            } catch (e) {
              throw Exception("This spend bundle cannot be signed by the NFT wallet");
            }
          }
        } else {
          throw Exception(conditionsResult.item1);
        }
      }
    }
    final aggregatedSignature = AugSchemeMPL.aggregate(signatures);
    return unsignedSpendBundle.addSignature(aggregatedSignature);
  }
}

import 'dart:convert';
import '../../bls.dart';
import '../../clvm.dart';
import '../../core/index.dart';
import '../../core/service/conditions_utils.dart';
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

  SpendBundle createMessageSpend(
    DidInfo didInfo, {
    Set<Bytes>? coinAnnouncements,
    Set<Bytes>? puzzleannouncements,
    Program? newInnerPuzzle,
    required List<CoinPrototype> coins,
    required WalletKeychain keychain,
  }) {
    final coin = coins.first;
    final innerpuz = didInfo.currentInner!;
    if (newInnerPuzzle == null) {
      newInnerPuzzle = innerpuz;
    }
    final uncurried = didPuzzles.uncurryInnerpuz(newInnerPuzzle);
    if (uncurried == null) {
      throw Exception("Puzzle is not DID puzzle");
    }

    final p2Puzzle = uncurried.item1;
    final p2Solution = BaseWalletService.makeSolution(
      primaries: [
        Payment(coin.amount, newInnerPuzzle.hash(), memos: [p2Puzzle.hash()]),
      ],
      coinAnnouncements: coinAnnouncements ?? {},
      puzzleAnnouncements: puzzleannouncements ?? {},
    );
    final innerSol = Program.list([Program.fromInt(1), p2Solution]);
    final fullPuzzle = SingletonService.puzzleForSingleton(
      didInfo.originCoin!.id,
      innerpuz,
    );
    final parentInfo = didInfo.parentInfo.first.item2!;
    final fullSolution = Program.list([
      Program.list([
        Program.fromBytes(parentInfo.parentName!),
        Program.fromBytes(parentInfo.innerPuzzleHash!),
        Program.fromInt(parentInfo.amount!),
      ]),
      Program.fromInt(parentInfo.amount!),
      innerSol
    ]);
    final listOfCoinsSpends = [
      CoinSpend(coin: coin, puzzleReveal: fullPuzzle, solution: fullSolution),
    ];
    final unsignedSpendBundle = SpendBundle(coinSpends: listOfCoinsSpends);
    return sign(
      unsignedSpendBundle: unsignedSpendBundle,
      keychain: keychain,
      didInfo: didInfo,
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
        curriedArgs: uncurryPuzzleReveal.arguments[1],
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
                //TODO: remove private key print
                print("sign message ${msg.toHex()} with ${sk.toBytes().toHex()}");
                final signature = AugSchemeMPL.sign(sk, msg);
                signatures.add(signature);
              } else {
                //TODO: remove private key print
                print("Cant foun sk for ${pk}");
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

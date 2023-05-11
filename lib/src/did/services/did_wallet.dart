// ignore_for_file: library_prefixes

import 'dart:convert';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/core/service/conditions_utils.dart';
import 'package:chia_crypto_utils/src/did/puzzles/did_puzzles.dart' as didPuzzles;
import 'package:tuple/tuple.dart';

class DidWallet extends BaseWalletService {
  final StandardWalletService standardWalletService = StandardWalletService();

  Future<Tuple2<SpendBundle, DidInfo>?> _generateNewDecentralisedId({
    required List<CoinPrototype> coins,
    required WalletKeychain keychain,
    required Puzzlehash changePuzzlehash,
    required DidInfo didInfoParam,
    int amount = 1,
    int fee = 0,
  }) async {
    // divide coins into origin and standard coins for fee
    final origin = coins.first;
    var didInfo = didInfoParam;

    final genesisLauncherPuz = LAUNCHER_PUZZLE;

    final launcherCoin = CoinPrototype(
      parentCoinInfo: origin.id,
      puzzlehash: genesisLauncherPuz.hash(),
      amount: amount,
    );
    final walletVector = keychain.getWalletVector(didInfo.p2PuzzleHash!);
    final p2Puzzle = getPuzzleFromPk(walletVector!.childPublicKey);

    final didInner = getNewDidInnerPuz(
      coinName: launcherCoin.id,
      didInfo: didInfo,
      keychain: keychain,
      p2Puzzle: p2Puzzle,
    );
    final didInnerHash = didInner.hash();

    final didFullPuz = NftWalletService.createFullpuzzle(
      didInner,
      launcherCoin.id,
    );

    final didPuzzleHash = didFullPuz.hash();

    final announcementSet = <AssertCoinAnnouncementCondition>{};
    final announcementMessage = Program.list([
      Program.fromBytes(didPuzzleHash),
      Program.fromInt(amount),
      Program.list([]),
    ]).hash();
    final assertCoinAnnouncement = AssertCoinAnnouncementCondition(
      launcherCoin.id,
      announcementMessage,
    );
    announcementSet.add(assertCoinAnnouncement);

    final txRecord = standardWalletService.createSpendBundle(
      payments: [
        Payment(
          launcherCoin.amount,
          genesisLauncherPuz.hash() //launcherCoin.puzzlehash
          ,
        ),
      ],
      coinsInput: coins, //[origin, ...standardCoinsForFee],
      keychain: keychain,
      changePuzzlehash: changePuzzlehash,
      originId: origin.id,
      fee: fee,
      coinAnnouncementsToAssert: announcementSet.toList(),
    );

    final genesisLauncherSolution = Program.list([
      Program.fromBytes(didPuzzleHash),
      Program.fromInt(amount),
      Program.list([]),
    ]);

    final launcherCs = CoinSpend(
      coin: launcherCoin,
      puzzleReveal: genesisLauncherPuz,
      solution: genesisLauncherSolution,
    );
    final launcherSb = SpendBundle(coinSpends: [launcherCs]);
    final eveCoin = CoinPrototype(
      parentCoinInfo: launcherCoin.id,
      puzzlehash: didPuzzleHash,
      amount: amount,
    );
    final futureParent = LineageProof(
      parentCoinInfo: Puzzlehash(eveCoin.parentCoinInfo),
      innerPuzzlehash: didInnerHash,
      amount: eveCoin.amount,
    );
    final eveParent = LineageProof(
      parentCoinInfo: Puzzlehash(launcherCoin.parentCoinInfo),
      innerPuzzlehash: launcherCoin.puzzlehash,
      amount: launcherCoin.amount,
    );
    didInfo = addParent(eveCoin.parentCoinInfo, eveParent, didInfo: didInfo);
    didInfo = addParent(eveCoin.id, futureParent, didInfo: didInfo);

    didInfo = DidInfo(
      originCoin: launcherCoin,
      backupsIds: didInfo.backupsIds,
      numOfBackupIdsNeeded: didInfo.numOfBackupIdsNeeded,
      parentInfo: didInfo.parentInfo,
      currentInner: didInner,
      sentRecoveryTransaction: false,
      metadata: didInfo.metadata,
    );

    final eveSpend = await generateEveSpend(
      coin: eveCoin,
      fullPuzzle: didFullPuz,
      innerPuz: didInner,
      didInfo: didInfo,
      keychain: keychain,
    );

    final fullSpend = SpendBundle.aggregate([
      txRecord,
      eveSpend,
      launcherSb,
    ]);
    if (didInfo.originCoin == null) {
      print('origin coin is null');
    }
    if (didInfo.currentInner == null) {
      print('current inner is null');
    }

    return Tuple2(fullSpend, didInfo);
  }

  DidInfo addParent(Bytes name, LineageProof? parent, {required DidInfo didInfo}) {
    print('Adding parent $name: $parent');

    return didInfo.copyWith(
      parentInfo: didInfo.parentInfo
        ..add(
          Tuple2(
            Puzzlehash(name),
            parent,
          ),
        ),
    );
  }

  Future<Tuple2<SpendBundle, DidInfo>?> createNewDid({
    required List<CoinPrototype> coins,
    required WalletKeychain keychain,
    required Puzzlehash changePuzzlehash,
    required Puzzlehash p2Puzlehash,
    int amount = 1,
    List<Puzzlehash> backupsIds = const [],
    int? numOfBackupIdsNeeded,
    Map<String, String> metadata = const {},
    int fee = 0,
  }) async {
    numOfBackupIdsNeeded ??= backupsIds.length;
    if (numOfBackupIdsNeeded > backupsIds.length) {
      throw Exception('Cannot require more IDs than are known.');
    }
    final empytParentInfo = <Tuple2<Puzzlehash, LineageProof?>>[];
    final didInfo = DidInfo(
      originCoin: null,
      backupsIds: backupsIds,
      numOfBackupIdsNeeded: numOfBackupIdsNeeded,
      parentInfo: empytParentInfo,
      sentRecoveryTransaction: false,
      metadata: json.encode(metadata),
      tempPuzzlehash: p2Puzlehash,
    );

    return _generateNewDecentralisedId(
      amount: amount,
      coins: coins,
      keychain: keychain,
      changePuzzlehash: changePuzzlehash,
      didInfoParam: didInfo,
      fee: fee,
    );
  }

  Map<Bytes, dynamic> parseMetadata(Map<String, dynamic> metadata) {
    final metadataMap = <Bytes, dynamic>{};
    metadata.forEach((key, value) {
      metadataMap[Bytes.fromHex(key)] = value;
    });
    return metadataMap;
  }

  Program getNewDidInnerPuz({
    required DidInfo didInfo,
    required Program p2Puzzle,
    required WalletKeychain keychain,
    Bytes? coinName,
  }) {
    Program innerpuz;
    if (didInfo.originCoin != null) {
      innerpuz = didPuzzles.createDidInnerpuz(
        p2Puzzle: p2Puzzle,
        recoveryList: didInfo.backupsIds,
        numOfBackupIdsNeeded: didInfo.numOfBackupIdsNeeded,
        launcherId: didInfo.originCoin!.id,
        metadata: didPuzzles.metadataToProgram(
          parseMetadata(
            Map<String, dynamic>.from(json.decode(didInfo.metadata) as Map<dynamic, dynamic>),
          ),
        ),
      );
    } else if (coinName != null) {
      innerpuz = didPuzzles.createDidInnerpuz(
        p2Puzzle: p2Puzzle,
        recoveryList: didInfo.backupsIds,
        numOfBackupIdsNeeded: didInfo.numOfBackupIdsNeeded,
        launcherId: coinName,
        metadata: didPuzzles.metadataToProgram(
          parseMetadata(
            Map<String, dynamic>.from(json.decode(didInfo.metadata) as Map<dynamic, dynamic>),
          ),
        ),
      );
    } else {
      throw Exception('must have origin coin');
    }
    return innerpuz;
  }

  Future<SpendBundle> createMessageSpend(
    DidInfo didInfo, {
    required WalletKeychain keychain,
    Set<Bytes>? coinAnnouncements,
    Set<Bytes>? puzzleAnnouncements,
    Program? newInnerPuzzle,
  }) async {
    if (didInfo.currentInner == null || didInfo.originCoin == null) {
      throw Exception('didInfo.currentInner == null || didInfo.originCoin == null');
    }

    final coin = didInfo.tempCoin!;
    final innerpuz = didInfo.currentInner!;
    newInnerPuzzle ??= innerpuz;
    final uncurried = didPuzzles.uncurryInnerpuz(newInnerPuzzle);
    if (uncurried == null) {
      throw Exception('uncurried == null');
    }
    final p2Puzzle = uncurried.item1;

    final p2Solution = BaseWalletService.makeSolution(
      primaries: [
        Payment(
          coin.amount,
          newInnerPuzzle.hash(),
          memos: <Puzzlehash>[p2Puzzle.hash()],
        ),
      ],
      puzzleAnnouncements: puzzleAnnouncements ?? {},
      coinAnnouncements: coinAnnouncements ?? {},
    );
    final innersol = Program.list([Program.fromInt(1), p2Solution]);
    final fullPuzzle = NftWalletService.createFullpuzzle(
      innerpuz,
      didInfo.didId!,
    );

    final parentInfo = getParentForCoin(coin, didInfo: didInfo);
    if (parentInfo == null) {
      throw Exception('parentInfo == null');
    }

    final fullsol = Program.list(
      [
        parentInfo.toProgram(),
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

  LineageProof? getParentForCoin(Coin coin, {required DidInfo didInfo}) {
    LineageProof? parentInfo;
    for (final item in didInfo.parentInfo) {
      final name = item.item1;
      final ccParent = item.item2;
      if (name == coin.parentCoinInfo) {
        parentInfo = ccParent;
      }
    }

    return parentInfo;
  }

  SpendBundle sign(
      {required SpendBundle unsignedSpendBundle,
      required WalletKeychain keychain,
      required DidInfo didInfo,}) {
    final signatures = <JacobianPoint>[];
    for (final coinSpend in unsignedSpendBundle.coinSpends) {
      try {
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

          final conditionsResult = conditionsDictForSolution(
            puzzleReveal: coinSpend.puzzleReveal,
            solution: coinSpend.solution,
          );
          if (conditionsResult.item2 != null) {
            final syntheticPk = synthSecretKey.getG1().toBytes();
            final pairs = pkmPairsForConditionsDict(
              conditionsDict: conditionsResult.item2!,
              additionalData: Bytes.fromHex(
                blockchainNetwork.aggSigMeExtraData,
              ),
              coinName: coinSpend.coin.id,
            );

            for (final pair in pairs) {
              final pk = pair.item1;
              final msg = pair.item2;
              try {
                if (syntheticPk == pk) {
                  final signature = AugSchemeMPL.sign(synthSecretKey, msg);
                  signatures.add(signature);
                } else {
                  final publickKey = PrivateKey.fromBytes(pk).getG1();
                  print('publickKey: ${publickKey.toHex()}');
                  throw Exception(
                    'This spend bundle cannot be signed by the DID wallet ${pk.toHex()}}',
                  );
                }
              } on Exception catch (e, stackTrace) {
                print(stackTrace);
                print(e);
                rethrow;
              }
            }
          } else {
            throw Exception(conditionsResult.item1);
          }
        }
      } catch (e, stackTrace) {
        print(stackTrace);
        print(e);
        rethrow;
      }
    }
    final aggregatedSignature = AugSchemeMPL.aggregate(signatures);
    return unsignedSpendBundle.addSignature(aggregatedSignature);
  }

  Future<SpendBundle> generateEveSpend({
    required CoinPrototype coin,
    required Program fullPuzzle,
    required Program innerPuz,
    required DidInfo didInfo,
    required WalletKeychain keychain,
  }) async {
    if (didInfo.originCoin == null) {
      throw Exception('didInfo.originCoin == null');
    }
    final uncurried = didPuzzles.uncurryInnerpuz(innerPuz);
    if (uncurried == null) {
      throw Exception('uncurried == null');
    }
    final p2Puzzle = uncurried.item1;
    // innerPuz solution is (mode p2Solution)
    final p2Solution = BaseWalletService.makeSolution(
      primaries: [
        Payment(
          coin.amount,
          innerPuz.hash(),
          memos: <Puzzlehash>[p2Puzzle.hash()],
        )
      ],
    );
    final innerSol = Program.list([Program.fromInt(1), p2Solution]);
    // full solution is (lineageProof myAmount innerSolution)
    final fullSol = Program.list([
      Program.list([
        Program.fromBytes(didInfo.originCoin!.parentCoinInfo),
        Program.fromInt(didInfo.originCoin!.amount),
      ]),
      Program.fromInt(coin.amount),
      innerSol,
    ]);
    final listOfCoinSpends = [
      CoinSpend(coin: coin, puzzleReveal: fullPuzzle, solution: fullSol),
    ];
    final unsignedSpendBundle = SpendBundle(
      coinSpends: listOfCoinSpends,
    );

    return sign(
      unsignedSpendBundle: unsignedSpendBundle,
      keychain: keychain,
      didInfo: didInfo,
    );
  }
}

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/core/models/conditions/announcement.dart';
import 'package:chia_crypto_utils/src/core/service/base_wallet.dart';
import 'package:tuple/tuple.dart';

import '../../core/exceptions/change_puzzlehash_needed_exception.dart';
import '../../core/service/conditions_utils.dart';

class NftWallet extends BaseWalletService {
  final StandardWalletService standardWalletService = StandardWalletService();

  SpendBundle createTransferSpendBundle({
    required NFTCoinInfo nftCoin,
    required WalletKeychain keychain,
    required Puzzlehash targetPuzzleHash,
    Puzzlehash? changePuzzlehash,
    int fee = 0,
    List<CoinPrototype>? standardCoinsForFee,
  }) {
    return generateSignedSpendBundle(
        payments: [
          Payment(
            nftCoin.coin.amount,
            targetPuzzleHash,
          )
        ],
        coins: [
          nftCoin.coin
        ],
        fee: fee,
        changePuzzlehash: changePuzzlehash,
        keychain: keychain,
        nftCoin: nftCoin,
        standardCoinsForFee: standardCoinsForFee,
        newOwner: null,
        newDidInnerhash: null);
  }

  SpendBundle generateSignedSpendBundle({
    required List<Payment> payments,
    required List<CoinPrototype> coins,
    List<CoinPrototype>? standardCoinsForFee,
    required WalletKeychain keychain,
    Puzzlehash? changePuzzlehash,
    List<AssertCoinAnnouncementCondition> coinAnnouncementsToAssert = const [],
    List<AssertPuzzleCondition> puzzleAnnouncementsToAssert = const [],
    int fee = 0,
    Bytes? newOwner,
    Bytes? newDidInnerhash,
    Program? tradePricesList,
    Map<String, String>? metadataUpdate,
    required NFTCoinInfo nftCoin,
    List<SpendBundle>? additionalBundles,
  }) {
    final generateSpendsTuple = generateUnsignedSpendbundle(
        payments: payments,
        coinsInput: coins,
        keychain: keychain,
        standardCoinsForFee: standardCoinsForFee,
        changePuzzlehash: changePuzzlehash,
        originId: nftCoin.nftId,
        nftCoin: nftCoin,
        fee: fee,
        coinAnnouncementsToAssert: coinAnnouncementsToAssert,
        puzzleAnnouncementsToAssert: puzzleAnnouncementsToAssert);

    final unsignedSpendBundle = generateSpendsTuple.item1;
    final chiaSpendBundle = generateSpendsTuple.item2;

    SpendBundle spendBundle = _sign(
      unsignedSpendBundle: unsignedSpendBundle,
      keychain: keychain,
    );

    standardWalletService.validateSpendBundle(spendBundle);
    standardWalletService.validateSpendBundleSignature(spendBundle);

    if (chiaSpendBundle != null) {
      spendBundle = spendBundle + chiaSpendBundle;
    }
    final spendBundleList = [spendBundle];

    spendBundleList.addAll(additionalBundles ?? []);

    return spendBundleList.fold<SpendBundle>(
      SpendBundle(coinSpends: []),
      (previousValue, element) => previousValue + element,
    );
  }

  SpendBundle _makeStandardSpendBundleForFee({
    required int fee,
    required List<CoinPrototype> standardCoins,
    required WalletKeychain keychain,
    required Puzzlehash? changePuzzlehash,
    List<AssertCoinAnnouncementCondition> coinAnnouncementsToAsset = const [],
  }) {
    assert(
      standardCoins.isNotEmpty,
      'If passing in a fee, you must also pass in standard coins to use for that fee.',
    );

    final totalStandardCoinsValue = standardCoins.fold(
      0,
      (int previousValue, standardCoin) => previousValue + standardCoin.amount,
    );
    assert(
      totalStandardCoinsValue >= fee,
      'Total value of passed in standad coins is not enough to cover fee.',
    );

    return standardWalletService.createSpendBundle(
      payments: [],
      coinsInput: standardCoins,
      changePuzzlehash: changePuzzlehash,
      keychain: keychain,
      fee: fee,
      coinAnnouncementsToAssert: coinAnnouncementsToAsset,
    );
  }

  Tuple2<SpendBundle, SpendBundle?> generateUnsignedSpendbundle({
    required List<Payment> payments,
    required List<CoinPrototype> coinsInput,
    required WalletKeychain keychain,
    Puzzlehash? changePuzzlehash,
    int fee = 0,
    Bytes? originId,
    List<AssertCoinAnnouncementCondition> coinAnnouncementsToAssert = const [],
    List<AssertPuzzleCondition> puzzleAnnouncementsToAssert = const [],
    required NFTCoinInfo nftCoin,
    List<CoinPrototype>? standardCoinsForFee,
    Map<String, String>? metadataUpdate,
  }) {
    // copy coins input since coins list is modified in this function
    final coins = List<CoinPrototype>.from(coinsInput);
    final totalCoinValue = coins.fold(0, (int previousValue, coin) => previousValue + coin.amount);

    final totalPaymentAmount = payments.fold(
      0,
      (int previousValue, payment) => previousValue + payment.amount,
    );
    final change = totalCoinValue - totalPaymentAmount - fee;

    if (changePuzzlehash == null && change > 0) {
      throw ChangePuzzlehashNeededException();
    }

    Set<Bytes> announcementsToMake = {};
    SpendBundle? feeSpendBundle;
    if (fee > 0) {
      announcementsToMake = {nftCoin.coin.id};
      feeSpendBundle = _makeStandardSpendBundleForFee(
          fee: fee,
          standardCoins: standardCoinsForFee!,
          keychain: keychain,
          changePuzzlehash: changePuzzlehash);

      // validateSpendBundleSignature(feeSpendBundle);
    }

    Program innerSol = BaseWalletService.makeSolution(
      primaries: payments,
      coinAnnouncements: announcementsToMake,
      coinAnnouncementsToAssert: coinAnnouncementsToAssert,
      puzzleAnnouncementsToAssert: puzzleAnnouncementsToAssert,
    );

    final unft = UncurriedNFT.uncurry(nftCoin.fullPuzzle);
    Program? magicCondition;

    if (unft.supportDid) {
      // TODO support for did
      /**
       * 
       *   if new_owner is None:
                # If no new owner was specified and we're sending this to ourselves, let's not reset the DID
                derivation_record: Optional[
                    DerivationRecord
                ] = await self.wallet_state_manager.puzzle_store.get_derivation_record_for_puzzle_hash(
                    payments[0].puzzle_hash
                )
                if derivation_record is not None:
                    new_owner = unft.owner_did
            magic_condition = Program.to([-10, new_owner, trade_prices_list, new_did_inner_hash])
      */
    }
    if (metadataUpdate != null) {
      final metadataUpdateListP = <Program>[];
      metadataUpdate.forEach((key, value) {
        metadataUpdateListP.add(Program.cons(
            Program.fromBytes(Bytes.fromHex(key)), Program.fromBytes(Bytes.fromHex(value))));
      });
      magicCondition = Program.list([
        Program.fromInt(-24),
        NFT_METADATA_UPDATER,
        Program.list(metadataUpdateListP),
      ]);
    }

    if (magicCondition != null) {
      innerSol = Program.list([
        Program.list([]),
        Program.cons(
          Program.fromInt(1),
          Program.cons(
            magicCondition.first(),
            innerSol.filterAt("rfr"),
          ),
        ),
        Program.list([]),
      ]);
    }
    if (unft.supportDid) {
      innerSol = Program.list([innerSol]);
    }

    final nftLayerSolution = Program.list([innerSol]);
    final lineageProof = nftCoin.lineageProof;
    if (lineageProof == null) {
      throw Exception("nftCoin.lineageProo can't be null");
    }

    final singletonSolution = Program.list([
      lineageProof.toProgram(),
      Program.fromInt(nftCoin.coin.amount),
      nftLayerSolution,
    ]);

    final coinSpend = CoinSpend(
      coin: nftCoin.coin,
      puzzleReveal: nftCoin.fullPuzzle,
      solution: singletonSolution,
    );
    SpendBundle nftSpendBundle = SpendBundle(
      coinSpends: [
        coinSpend,
      ],
    );

    return Tuple2(nftSpendBundle, feeSpendBundle);
  }

  SpendBundle _sign(
      {required SpendBundle unsignedSpendBundle,
      required WalletKeychain keychain,
      List<Puzzlehash>? puzzleHash}) {
    final signatures = <JacobianPoint>[];

    final puzzleHashList = puzzleHash ?? [];
    final keys = <Bytes, PrivateKey>{};

    for (final coinSpend in unsignedSpendBundle.coinSpends) {
      if (puzzleHashList.isEmpty) {
        final uncurried_nft = UncurriedNFT.tryUncurry(coinSpend.puzzleReveal);
        if (uncurried_nft != null) {
          print("Found a NFT state layer to sign");
          puzzleHashList.add(uncurried_nft.p2Puzzle.hash());
        }
      }
      for (final ph in puzzleHashList) {
        final coinWalletVector = keychain.getWalletVector(ph);

        final coinPrivateKey = coinWalletVector!.childPrivateKey;
        keys[coinPrivateKey.getG1().toBytes()] = coinPrivateKey;

        final synthSecretKey = calculateSyntheticPrivateKey(coinPrivateKey);
        keys[synthSecretKey.getG1().toBytes()] = synthSecretKey;
      }

      /*    final coinWalletVector = keychain.getWalletVector(puzzleHashList.first);
      final coinPrivateKey = coinWalletVector!.childPrivateKey;
      final signature = makeSignature(coinPrivateKey, coinSpend);
      signatures.add(signature); */

      final conditionsResult = conditionsDictForSolution(
          puzzleReveal: coinSpend.puzzleReveal, solution: coinSpend.solution);
      if (conditionsResult.item2 != null) {
        final pairs = pkmPairsForConditionsDict(
          conditionsDict: conditionsResult.item2!,
          additionalData: Bytes.fromHex(this.blockchainNetwork.aggSigMeExtraData),
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
              print("Cant foun sk for ${pk}");
            }
          } catch (e) {
            throw Exception("This spend bundle cannot be signed by the NFT wallet");
          }
        }
      }
    }

    final aggregatedSignature = AugSchemeMPL.aggregate(signatures);

    return unsignedSpendBundle.addSignature(aggregatedSignature);
  }

// generate_new_nft

  SpendBundle generateNewNft(
      {required List<CoinPrototype> coins,
      required WalletKeychain keychain,
      Puzzlehash? changePuzzlehash,
      required Program metadata,
      required Puzzlehash targetPuzzleHash,
      Puzzlehash? royaltyPuzzleHash,
      int percentage = 0,
      Puzzlehash? didId,
      int fee = 0}) {
    final amount = 1;
    final origin = coins.toList().first;
    // final genesisLauncherPuzz = LAUNCHER_PUZZLE;

    final launcherCoin = CoinPrototype(
      parentCoinInfo: origin.id,
      puzzlehash: LAUNCHER_PUZZLE_HASH,
      amount: amount,
    );

    print("Generating NFT with launcher coin %s and metadata:  ${launcherCoin}, ${metadata}");

    late Program innerPuzzle;

    final targetWalletVector = keychain.getWalletVector(targetPuzzleHash);
    final p2InnerPuzzle = getPuzzleFromPk(targetWalletVector!.childPublicKey);
    print("Attempt to generate a new NFT to ${targetPuzzleHash.toHex()}");
    if (didId != null) {
      innerPuzzle = NftService.createOwnwershipLayerPuzzle(
        nftId: origin.id,
        didId: didId,
        p2Puzzle: p2InnerPuzzle,
        percentage: percentage,
        royaltyPuzzleHash: royaltyPuzzleHash,
      );
    } else {
      innerPuzzle = p2InnerPuzzle;
    }

    final eveFullPuz = NftService.createFullPuzzle(
      singletonId: origin.id,
      metadata: metadata,
      metadataUpdaterHash: NFT_METADATA_UPDATER_HAHS,
      innerPuzzle: innerPuzzle,
    );

    final announcementMessage = Program.list([
      Program.fromBytes(eveFullPuz.hash()),
      Program.fromInt(amount),
      Program.list([]),
    ]).hash();
    final assertCoinAnnouncement =
        AssertCoinAnnouncementCondition(launcherCoin.id, announcementMessage);

    final createLauncherSpendBundle = standardWalletService.createSpendBundle(
      payments: [Payment(launcherCoin.amount, launcherCoin.puzzlehash)],
      coinsInput: coins,
      keychain: keychain,
      changePuzzlehash: changePuzzlehash,
      originId: origin.id,
      fee: fee,
      coinAnnouncementsToAssert: [assertCoinAnnouncement],
    );

    final genesisLauncherSolution = Program.list([
      Program.fromBytes(eveFullPuz.hash()),
      Program.fromInt(launcherCoin.amount),
      Program.list([]),
    ]);
    final launcherCoinSpend = CoinSpend(
      coin: launcherCoin,
      puzzleReveal: LAUNCHER_PUZZLE,
      solution: genesisLauncherSolution,
    );

    final launcherSpendBundle = SpendBundle(coinSpends: [launcherCoinSpend]);
    final eveCoin = CoinPrototype(
      amount: amount,
      parentCoinInfo: launcherCoin.id,
      puzzlehash: eveFullPuz.hash(),
    );

    final bundlesToAgg = createLauncherSpendBundle + launcherSpendBundle;

    Bytes? didInnerHash;

    if (didId != null && didId.isNotEmpty) {
      // did_inner_hash, did_bundle = await self.get_did_approval_info(launcher_coin.name())
      //bundles_to_agg.append(did_bundle)
      // TODO: implement DID
    }

    final nftCoin = NFTCoinInfo(
      nftId: launcherCoin.id,
      coin: eveCoin,
      fullPuzzle: eveFullPuz,
      mintHeight: 0,
      latestHeight: 0,
      lineageProof: LineageProof(parentName: launcherCoin.id, amount: launcherCoin.amount),
      pendingTransaction: true,
    );

    final signedSpendBundle = generateSignedSpendBundle(
      payments: [
        Payment(eveCoin.amount, targetPuzzleHash, memos: [targetPuzzleHash])
      ],
      coins: coins,
      keychain: keychain,
      nftCoin: nftCoin,
      newOwner: didId,
      additionalBundles: [bundlesToAgg],
      newDidInnerhash: didInnerHash,
    );
    return signedSpendBundle;
  }
}

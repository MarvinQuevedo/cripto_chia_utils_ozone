// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:chia_utils/src/cat/exceptions/mixed_asset_ids_exception.dart';
import 'package:chia_utils/src/cat/models/cat_coin.dart';
import 'package:chia_utils/src/cat/models/spendable_cat.dart';
import 'package:chia_utils/src/cat/puzzles/cat/cat.clvm.hex.dart';
import 'package:chia_utils/src/core/models/conditions/assert_coin_announcement_condition.dart';
import 'package:chia_utils/src/core/models/conditions/condition.dart';
import 'package:chia_utils/src/core/models/conditions/create_coin_announcement_condition.dart';
import 'package:chia_utils/src/core/models/conditions/create_coin_condition.dart';
import 'package:chia_utils/src/core/models/payment.dart';
import 'package:chia_utils/src/core/service/base_wallet.dart';
import 'package:chia_utils/src/standard/exceptions/spend_bundle_validation/incorrect_announcement_id_exception.dart';
import 'package:chia_utils/src/standard/exceptions/spend_bundle_validation/multiple_origin_coin_exception.dart';

class CatWalletService extends BaseWalletService {
  late StandardWalletService standardWalletService;
  
  CatWalletService(Context context) : super(context) {
    standardWalletService = StandardWalletService(context);
  }

  SpendBundle createSpendBundle(
    List<Payment> payments, 
    List<CatCoin> catCoinsInput, 
    Puzzlehash changePuzzlehash, 
    WalletKeychain keychain, 
    {
      List<Coin> standardCoinsForFee = const [], 
      int fee = 0, 
    }
    ) {
    final distinctAssetIds = catCoinsInput.map((c) => c.assetId).toSet();
    if(distinctAssetIds.length != 1) {
      throw MixedAssetIdsException(distinctAssetIds);
    }

    final totalPaymentAmount = payments.fold(0, (int previousValue, payment) => previousValue + payment.amount);

    final catCoins = List<CatCoin>.from(catCoinsInput);
    
    final totalCatCoinValue = catCoins.fold(0, (int previousValue, coin) => previousValue + coin.amount);

    assert(totalPaymentAmount <= totalCatCoinValue, 'Insufficient total cat coin value');
    final change = totalCatCoinValue - totalPaymentAmount;

    AssertCoinAnnouncementCondition? primaryAssertCoinAnnouncement;

    final spendBundlesToAggregate = <SpendBundle>[];

    final spendableCats = <SpendableCat>[];
    var first = true;
    for (final catCoin in catCoins) {
      final coinWalletVector = keychain.getWalletVector(catCoin.puzzlehash);
      final coinPublicKey = coinWalletVector!.childPublicKey;

      Program? innerSolution;
      // if first coin, make inner solution with output
      if (first) {
        first = false;
        // see https://github.com/Chia-Network/chia-blockchain/blob/4bd5c53f48cb049eff36c87c00d21b1f2dd26b27/chia/wallet/cat_wallet/cat_wallet.py#L646
        //   announcement = Announcement(coin.name(), std_hash(b"".join([c.name() for c in cat_coins])), b"\xca")
        final message = catCoins.fold(
          Bytes.empty, 
          (Bytes previousValue, coin) => previousValue + coin.id,
        ).sha256Hash();

        primaryAssertCoinAnnouncement = AssertCoinAnnouncementCondition(
          catCoin.id,
          message,
          // https://chialisp.com/docs/puzzles/cats under "Design Choices"
          morphBytes: Bytes.fromHex('ca'),
        );


        final conditions = <Condition>[];
        final createdCoins = <CoinPrototype>[];

        conditions.add(CreateCoinAnnouncementCondition(primaryAssertCoinAnnouncement.message));

        for (final payment in payments) {
          final sendCreateCoinCondition = payment.toCreateCoinCondition();
          conditions.add(sendCreateCoinCondition);
          createdCoins.add(
            CoinPrototype(
              parentCoinInfo: catCoin.id,
              puzzlehash: payment.puzzlehash,
              amount: payment.amount,
            ),
          );
        } 

        if (change > 0) {
          conditions.add(CreateCoinCondition(changePuzzlehash, change));
          createdCoins.add(
            CoinPrototype(
              parentCoinInfo: catCoin.id,
              puzzlehash: changePuzzlehash,
              amount: change,
            ),
          );
        }
        if (fee > 0) {
          spendBundlesToAggregate.add(
            _makeStandardSpendBundleForFee(
              fee: fee,
              standardCoins: standardCoinsForFee,
              keychain: keychain,
              changePuzzlehash: changePuzzlehash,
            ),
          );
        }

        innerSolution = BaseWalletService.makeSolutionFromConditions(conditions);
      } else {
        innerSolution = BaseWalletService.makeSolutionFromConditions([primaryAssertCoinAnnouncement!]);
      }

      final innerPuzzle = getPuzzleFromPk(coinPublicKey);

      spendableCats.add(
        SpendableCat(
          coin: catCoin, 
          innerPuzzle: innerPuzzle, 
          innerSolution: innerSolution,
        ),
      );
    }

    final immutableSpendableCats = List<SpendableCat>.unmodifiable(spendableCats);

    final catSpendBundle = _makeCatSpendBundleFromSpendableCats(immutableSpendableCats, keychain);

    spendBundlesToAggregate.add(catSpendBundle);

    return SpendBundle.aggregate(spendBundlesToAggregate);
  }

  SpendBundle _makeCatSpendBundleFromSpendableCats(List<SpendableCat> spendableCats, WalletKeychain keychain) {
    SpendableCat.calculateAndAttachSubtotals(spendableCats);

    final spends = <CoinSpend>[];
    final signatures = <JacobianPoint>[];
    
    final n = spendableCats.length;
    for (var index = 0; index < n; index++) {
      final previousIndex = (index - 1) % n;
      final nextIndex = (index + 1) % n;

      final previousSpendableCat = spendableCats[previousIndex];
      final currentSpendableCat = spendableCats[index];
      final nextSpendableCat = spendableCats[nextIndex];

      final puzzleReveal = makeCatPuzzle(currentSpendableCat);

      final solution = makeCatSolution(
        previousSpendableCat: previousSpendableCat, 
        currentSpendableCat: currentSpendableCat, 
        nextSpendableCat: nextSpendableCat,
      );

      final coinWalletVector = keychain.getWalletVector(currentSpendableCat.coin.puzzlehash);
      final coinPrivateKey = coinWalletVector!.childPrivateKey;

      final solAndSig = createCoinsSpendAndSignature(solution, puzzleReveal, coinPrivateKey, currentSpendableCat.coin);

      spends.add(solAndSig.coinSpend);
      signatures.add(solAndSig.signature);
    }

    final catAggregateSignature = AugSchemeMPL.aggregate(signatures);

    return SpendBundle(coinSpends: spends, aggregatedSignature: catAggregateSignature);
  }

  SpendBundle _makeStandardSpendBundleForFee({
    required int fee,
    required List<Coin> standardCoins,
    required WalletKeychain keychain,
    required Puzzlehash changePuzzlehash,
    List<AssertCoinAnnouncementCondition> coinAnnouncementsToAsset = const [],
  }) {
    assert(standardCoins.isNotEmpty, 'If passing in a fee, you must also pass in standard coins to use for that fee.');
    final totalStandardCoinsValue = standardCoins.fold(0, (int previousValue, standardCoin) => previousValue + standardCoin.amount);
    assert(totalStandardCoinsValue >= fee, 'Total value of passed in standad coins is not enough to cover fee.');

    return standardWalletService.createSpendBundle(
      standardCoins, 
      0, 
      changePuzzlehash, 
      changePuzzlehash, 
      keychain, 
      fee: fee,
      coinAnnouncementsToAssert: coinAnnouncementsToAsset,
    );
  }

  static Program makeCatSolution({
    required SpendableCat previousSpendableCat, 
    required SpendableCat currentSpendableCat, 
    required SpendableCat nextSpendableCat,

    }) {
    assert(currentSpendableCat.subtotal != null, 'subtotal has not been attached to currentSpendableCat');
    // see https://github.com/Chia-Network/chia-blockchain/blob/4bd5c53f48cb049eff36c87c00d21b1f2dd26b27/chia/wallet/cat_wallet/cat_utils.py#L123
    return Program.list([
      currentSpendableCat.innerSolution, 
      currentSpendableCat.coin.lineageProof,
      Program.fromBytes(previousSpendableCat.coin.id.toUint8List()),
      currentSpendableCat.coin.toProgram(),
      nextSpendableCat.makeStandardCoinProgram(),
      Program.fromInt(currentSpendableCat.subtotal!),
      Program.fromInt(0), // limitations_program_reveal: unused since we're not handling any cat discrepancy
    ]);
  }

  static Program makeCatPuzzle(SpendableCat spendableCat) {
    return catProgram.curry([
      Program.fromBytes(catProgram.hash()),
      Program.fromBytes(spendableCat.coin.assetId.toUint8List()),
      spendableCat.innerPuzzle
    ]);
  }

  void validateSpendBundle(SpendBundle spendBundle) {
    validateSpendBundleSignature(spendBundle);

    // validate assert_coin_announcement if it is created (if there are multiple coins spent)
    List<Bytes>? actualAssertCoinAnnouncementIds;
    final coinsToCreate = <CoinPrototype>[];
    final coinsBeingSpent = <CoinPrototype>[];
    Bytes? originId;
    final catSpends = spendBundle.coinSpends.where((spend) => spend.type == SpendType.cat);
    for (final catSpend in catSpends) {
      final outputConditions = catSpend.puzzleReveal.run(catSpend.solution).program.toList();

      // find create_coin conditions
      final coinCreationConditions = outputConditions.where(CreateCoinCondition.isThisCondition)
        .map((program) => CreateCoinCondition.fromProgram(program)).toList();
      
      for (final coinCreationCondition in coinCreationConditions) {
        coinsToCreate.add(CoinPrototype(parentCoinInfo: catSpend.coin.id, puzzlehash: coinCreationCondition.destinationHash, amount: coinCreationCondition.amount));
      }
      coinsBeingSpent.add(catSpend.coin);

      if (coinCreationConditions.isNotEmpty) {
        // if originId is already set, multiple coins are creating output which is invalid
        if (originId != null) {
          throw MultipleOriginCoinsException();
        }
        originId = catSpend.coin.id;
      }

      // origin id doesn't contain its own assert coin announcement
      if (catSpend.coin.id != originId) {
        final assertCoinAnnouncementPrograms =  outputConditions.where(AssertCoinAnnouncementCondition.isThisCondition).toList();

        // set actualAssertCoinAnnouncementIds only if it is null
        actualAssertCoinAnnouncementIds ??= assertCoinAnnouncementPrograms.map(AssertCoinAnnouncementCondition.getAnnouncementIdFromProgram).toList();
      }
      // look for assert coin announcement condition
      
    }
    // check for duplicate coins
    BaseWalletService.checkForDuplicateCoins(coinsToCreate);
    BaseWalletService.checkForDuplicateCoins(coinsBeingSpent);

    if (catSpends.length > 1) {
      assert(actualAssertCoinAnnouncementIds != null, 'No assert_coin_announcement condition when multiple spends');
      assert(originId != null, 'No create_coin conditions');
      
      // construct assert_coin_announcement id from spendbundle, verify against output
      final existingCoinsMessage = coinsBeingSpent.fold(Bytes.empty, (Bytes previousValue, coin) => previousValue + coin.id);

      final message = existingCoinsMessage.sha256Hash();

      final constructedAnnouncement = AssertCoinAnnouncementCondition(originId!, message, morphBytes: Bytes.fromHex('ca'));
      if (!actualAssertCoinAnnouncementIds!.contains(constructedAnnouncement.announcementId)) {
        throw IncorrectAnnouncementIdException();
      }
    }
  }  
}

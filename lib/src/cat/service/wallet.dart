// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/cat/exceptions/mixed_asset_ids_exception.dart';
import 'package:chia_crypto_utils/src/cat/models/conditions/run_tail_condition.dart';
import 'package:chia_crypto_utils/src/core/exceptions/change_puzzlehash_needed_exception.dart';
import 'package:chia_crypto_utils/src/core/exceptions/insufficient_coins_exception.dart';
import 'package:chia_crypto_utils/src/standard/exceptions/spend_bundle_validation/incorrect_announcement_id_exception.dart';
import 'package:chia_crypto_utils/src/standard/exceptions/spend_bundle_validation/multiple_origin_coin_exception.dart';
import 'package:tuple/tuple.dart';

class CatWalletService extends BaseWalletService {
  final _standardWalletService = StandardWalletService();
  StandardWalletService get standardWalletService => _standardWalletService;

  Tuple2<SpendBundle, SignatureHashes?> createSpendBundle({
    required List<Payment> payments,
    required List<CatCoin> catCoinsInput,
    required WalletKeychain keychain,
    List<Payment> xchPayments = const [],
    Puzzlehash? changePuzzlehash,
    List<Coin> standardCoinsForFee = const [],
    List<AssertCoinAnnouncementCondition> coinAnnouncementsToAssert = const [],
    List<AssertPuzzleCondition> puzzleAnnouncementsToAssert = const [],
    int fee = 0,
    bool unsigned = false,
  }) {
    final SignatureHashes signatureHashes = SignatureHashes();
    final distinctAssetIds = catCoinsInput.map((c) => c.assetId).toSet();
    if (distinctAssetIds.length != 1) {
      throw MixedAssetIdsException(distinctAssetIds);
    }

    final totalPaymentAmount = payments.fold(
      0,
      (int previousValue, payment) => previousValue + payment.amount,
    );

    final catCoins = List<CatCoin>.from(catCoinsInput);

    final totalCatCoinValue = catCoins.fold(
      0,
      (int previousValue, coin) => previousValue + coin.amount,
    );

    if (totalCatCoinValue < totalPaymentAmount) {
      throw InsufficientCoinsException(
        attemptedSpendAmount: totalPaymentAmount,
        coinTotalValue: totalCatCoinValue,
      );
    }

    final change = totalCatCoinValue - totalPaymentAmount;
    if (changePuzzlehash == null && change != 0) {
      throw ChangePuzzlehashNeededException();
    }
    AssertCoinAnnouncementCondition? primaryAssertCoinAnnouncement;

    SpendBundle? feeStandardSpendBundle;

    final spendableCats = <SpendableCat>[];
    var first = true;
    for (final catCoin in catCoins) {
      final coinWalletVector = keychain.getWalletVector(catCoin.puzzlehash);
      final coinPublicKey = coinWalletVector!.childPublicKey;

      Program? innerSolution;
      // if first coin, make inner solution with output
      if (first) {
        first = false;
        // see https://github.com/Chia-Network/chia-blockchain/blob/main/chia/wallet/cat_wallet/cat_wallet.py#L625
        //   announcement = Announcement(coin.name(), std_hash(b"".join([c.name() for c in cat_coins])), b"\xca")
        final message = catCoins
            .fold(
              Bytes.empty,
              (Bytes previousValue, coin) => previousValue + coin.id,
            )
            .sha256Hash();

        primaryAssertCoinAnnouncement = AssertCoinAnnouncementCondition(
          catCoin.id,
          message,
          // https://chialisp.com/docs/puzzles/cats under "Design Choices"
          // morphBytes: Bytes.fromHex('ca'),
        );

        final conditions = <Condition>[];
        final createdCoins = <CoinPrototype>[];

        conditions
          ..add(
            CreateCoinAnnouncementCondition(
              primaryAssertCoinAnnouncement.message,
            ),
          )
          ..addAll(coinAnnouncementsToAssert)
          ..addAll(puzzleAnnouncementsToAssert);

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
          conditions.add(CreateCoinCondition(
            changePuzzlehash!,
            change,
            memos: <Bytes>[
              changePuzzlehash.toBytes(),
            ],
          ));
          createdCoins.add(
            CoinPrototype(
              parentCoinInfo: catCoin.id,
              puzzlehash: changePuzzlehash,
              amount: change,
            ),
          );
        }

        if (fee > 0) {
          final standartResult = _makeStandardSpendBundleForFee(
            fee: fee,
            standardCoins: standardCoinsForFee,
            keychain: keychain,
            changePuzzlehash: changePuzzlehash,
            unsigned: unsigned,
            xchPayments: xchPayments,
          );
          feeStandardSpendBundle = standartResult.item1;
          signatureHashes.aggregate(standartResult.item2);
        }

        innerSolution = keychain.isTangem
            ? BaseWalletService.makeSolutionFromConditionsP2Delegate(conditions)
            : BaseWalletService.makeSolutionFromConditions(conditions);
      } else {
        innerSolution = keychain.isTangem
            ? BaseWalletService.makeSolutionFromConditionsP2Delegate(
                [primaryAssertCoinAnnouncement!],
              )
            : BaseWalletService.makeSolutionFromConditions(
                [primaryAssertCoinAnnouncement!],
              );
      }

      final innerPuzzle = standardWalletService.getPuzzleFromPublicKey(coinPublicKey);

      spendableCats.add(
        SpendableCat(
          coin: catCoin,
          innerPuzzle: innerPuzzle,
          innerSolution: innerSolution,
        ),
      );
    }

    final immutableSpendableCats = List<SpendableCat>.unmodifiable(spendableCats);

    final catSpendBundleResult =
        makeCatSpendBundleFromSpendableCats(immutableSpendableCats, keychain, unsigned: unsigned);
    final catSpendBundle = catSpendBundleResult.item1;
    signatureHashes.aggregate(catSpendBundleResult.item2);

    if (feeStandardSpendBundle != null) {
      if (unsigned) {
        return Tuple2(catSpendBundle + feeStandardSpendBundle, signatureHashes);
      } else {
        return Tuple2(catSpendBundle + feeStandardSpendBundle, null);
      }
    }
    if (unsigned) {
      return Tuple2(catSpendBundle, signatureHashes);
    } else {
      return Tuple2(catSpendBundle, null);
    }
  }

  SpendBundle makeMultiIssuanceCatSpendBundle({
    required Bytes genesisCoinId,
    required List<CoinPrototype> standardCoins,
    required PrivateKey privateKey,
    required Puzzlehash destinationPuzzlehash,
    required Puzzlehash changePuzzlehash,
    required int amount,
    required WalletKeychain keychain,
    int fee = 0,
  }) {
    final publicKey = privateKey.getG1();
    final curriedTail = delegatedTailProgram.curry([Program.fromBytes(publicKey.toBytes())]);

    final curriedGenesisByCoinId = genesisByCoinIdProgram.curry([Program.fromBytes(genesisCoinId)]);
    final tailSolution = Program.list([curriedGenesisByCoinId, Program.nil]);

    final signature = AugSchemeMPL.sign(privateKey, curriedGenesisByCoinId.hash());

    return makeIssuanceSpendbundle(
      tail: curriedTail,
      solution: tailSolution,
      standardCoins: standardCoins,
      destinationPuzzlehash: destinationPuzzlehash,
      changePuzzlehash: changePuzzlehash,
      amount: amount,
      signature: signature,
      keychain: keychain,
      originId: genesisCoinId,
      fee: fee,
    );
  }

  SpendBundle makeMeltingSpendBundle({
    required CatCoin catCoinToMelt,
    required List<CoinPrototype> standardCoinsForXchClaimingSpendBundle,
    required Puzzlehash puzzlehashToClaimXchTo,
    required Program tail,
    required Program tailSolution,
    required WalletKeychain keychain,
    required JacobianPoint issuanceSignature,
    int fee = 0,
    Puzzlehash? changePuzzlehash,
    int? inputAmountToMelt,
  }) {
    final amountToMelt = inputAmountToMelt ?? catCoinToMelt.amount;
    final change = catCoinToMelt.amount - amountToMelt;

    if (changePuzzlehash == null && change > 0) {
      throw ChangePuzzlehashNeededException();
    }

    final walletVector = keychain.getWalletVector(catCoinToMelt.puzzlehash);

    final innerPuzzle = getPuzzleFromPk(walletVector!.childPublicKey);

    final conditions = <Condition>[RunTailCondition(tail, tailSolution)];

    if (change > 0) {
      conditions.add(CreateCoinCondition(changePuzzlehash!, change));
    }

    final innerSolution = BaseWalletService.makeSolutionFromConditions(conditions);

    final spendableCat = SpendableCat(
      coin: catCoinToMelt,
      innerPuzzle: innerPuzzle,
      innerSolution: innerSolution,
      extraDelta: -amountToMelt,
    );

    final meltSpendBundle = makeCatSpendBundleFromSpendableCats([spendableCat], keychain);

    final totalStandardCoinValue = standardCoinsForXchClaimingSpendBundle.totalValue;

    final xchClaimingSpendbundle = standardWalletService.createSpendBundle(
      payments: [
        Payment(
          totalStandardCoinValue - fee + amountToMelt,
          puzzlehashToClaimXchTo,
        )
      ],
      coinsInput: standardCoinsForXchClaimingSpendBundle,
      keychain: keychain,
      fee: fee,
    );

    final finalSpendbundle =
        (meltSpendBundle.item1 + xchClaimingSpendbundle.item1).addSignature(issuanceSignature);

    return finalSpendbundle;
  }

  SpendBundle makeIssuanceSpendbundle({
    required Program tail,
    required Program solution,
    required List<CoinPrototype> standardCoins,
    required Puzzlehash destinationPuzzlehash,
    required Puzzlehash changePuzzlehash,
    required int amount,
    required JacobianPoint signature,
    required WalletKeychain keychain,
    Bytes? originId,
    int fee = 0,
  }) {
    final payToPuzzle = Program.cons(
      Program.fromInt(1),
      Program.list([
        Program.list(
          [Program.fromInt(51), Program.fromInt(0), Program.fromInt(-113), tail, solution],
        ),
        Program.list([
          Program.fromInt(51),
          Program.fromBytes(destinationPuzzlehash),
          Program.fromInt(amount),
          Program.list([
            Program.fromBytes(destinationPuzzlehash),
          ])
        ]),
      ]),
    );

    final catPuzzle = CAT_MOD.curry([
      Program.fromBytes(CAT_MOD.hash()),
      Program.fromBytes(tail.hash()),
      payToPuzzle,
    ]);

    final catPuzzleHash = Puzzlehash(catPuzzle.hash());

    final standardCoinOriginId = originId ?? standardCoins[0].id;
    final standartResult = standardWalletService.createSpendBundle(
      payments: [Payment(amount, Puzzlehash(catPuzzle.hash()))],
      coinsInput: standardCoins,
      changePuzzlehash: changePuzzlehash,
      keychain: keychain,
      originId: standardCoinOriginId,
      fee: fee,
    );
    final standardSpendBundle = standartResult.item1;

    final eveParentSpend = standardSpendBundle.coinSpends
        .singleWhere((spend) => spend.coin.id == standardCoinOriginId);

    final eveCoin = CoinPrototype(
      parentCoinInfo: standardCoinOriginId,
      puzzlehash: catPuzzleHash,
      amount: amount,
    );

    final eveCatCoin = CatCoin.eve(
      parentCoinSpend: eveParentSpend,
      coin: eveCoin,
      assetId: Puzzlehash(tail.hash()),
    );

    final spendableEve = SpendableCat(
      coin: eveCatCoin,
      innerPuzzle: payToPuzzle,
      innerSolution: Program.nil,
    );

    final eveUnsignedSpendbundle = makeUnsignedSpendBundleForSpendableCats([spendableEve]);

    final finalSpendBundle = (standardSpendBundle + eveUnsignedSpendbundle).addSignature(signature);

    return finalSpendBundle;
  }

  Tuple2<SpendBundle, SignatureHashes?> makeCatSpendBundleFromSpendableCats(
    List<SpendableCat> spendableCats,
    WalletKeychain keychain, {
    bool unsigned = false,
  }) {
    SignatureHashes signatureHashes = SignatureHashes();
    final unsignedSpendBundle = makeUnsignedSpendBundleForSpendableCats(spendableCats);

    final signatures = <JacobianPoint>[];

    for (final coinSpend in unsignedSpendBundle.coinSpends) {
      final coinWalletVector = keychain.getWalletVector(coinSpend.coin.puzzlehash);

      if (unsigned) {
        final message = getSignatureMessages(
          coinWalletVector!.childPublicKey,
          coinSpend,
          puzzleHash: coinSpend.coin.puzzlehash,
        );
        signatureHashes.addSignatureHashTuple(message);
      } else {
        final coinPrivateKey = coinWalletVector!.childPrivateKey;
        final signature = makeSignature(coinPrivateKey, coinSpend);
        signatures.add(signature);
      }
    }
    if (unsigned) {
      return Tuple2(unsignedSpendBundle, signatureHashes);
    }

    final aggregatedSignature = AugSchemeMPL.aggregate(signatures);

    final spendBundle = unsignedSpendBundle.addSignature(aggregatedSignature);
    return Tuple2(spendBundle, null);
  }

  static SpendBundle makeUnsignedSpendBundleForSpendableCats(
    List<SpendableCat> spendableCats,
  ) {
    SpendableCat.calculateAndAttachSubtotals(spendableCats);

    final spends = <CoinSpend>[];

    final n = spendableCats.length;
    for (var index = 0; index < n; index++) {
      final previousIndex = (index - 1) % n;
      final nextIndex = (index + 1) % n;

      final previousSpendableCat = spendableCats[previousIndex];
      final currentSpendableCat = spendableCats[index];
      final nextSpendableCat = spendableCats[nextIndex];

      final puzzleReveal = makeCatPuzzleFromSpendableCat(currentSpendableCat);

      final solution = makeCatSolution(
        previousSpendableCat: previousSpendableCat,
        currentSpendableCat: currentSpendableCat,
        nextSpendableCat: nextSpendableCat,
      );
      final coinSpend = CoinSpend(
        coin: currentSpendableCat.coin,
        puzzleReveal: puzzleReveal,
        solution: solution,
      );
      spends.add(coinSpend);
    }
    return SpendBundle(coinSpends: spends);
  }

  Tuple2<SpendBundle, SignatureHashes?> _makeStandardSpendBundleForFee({
    required int fee,
    required List<Coin> standardCoins,
    required List<Payment> xchPayments,
    required WalletKeychain keychain,
    required Puzzlehash? changePuzzlehash,
    List<AssertCoinAnnouncementCondition> coinAnnouncementsToAsset = const [],
    bool unsigned = false,
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
      payments: xchPayments,
      coinsInput: standardCoins,
      changePuzzlehash: changePuzzlehash,
      keychain: keychain,
      fee: fee,
      coinAnnouncementsToAssert: coinAnnouncementsToAsset,
      unsigned: unsigned,
    );
  }

  static Program makeCatSolution({
    required SpendableCat previousSpendableCat,
    required SpendableCat currentSpendableCat,
    required SpendableCat nextSpendableCat,
  }) {
    assert(
      currentSpendableCat.subtotal != null,
      'subtotal has not been attached to currentSpendableCat',
    );
    // see https://github.com/Chia-Network/chia-blockchain/blob/4bd5c53f48cb049eff36c87c00d21b1f2dd26b27/chia/wallet/cat_wallet/cat_utils.py#L123
    return Program.list([
      currentSpendableCat.innerSolution,
      currentSpendableCat.coin.lineageProof,
      Program.fromBytes(previousSpendableCat.coin.id),
      currentSpendableCat.coin.toProgram(),
      nextSpendableCat.makeStandardCoinProgram(),
      Program.fromInt(currentSpendableCat.subtotal!),
      Program.fromInt(
        currentSpendableCat.extraDelta,
      ), // limitations_program_reveal: unused since we're not handling any cat discrepancy
    ]);
  }

  static Program makeCatPuzzleFromSpendableCat(SpendableCat spendableCat) {
    return makeCatPuzzle(spendableCat.coin.assetId, spendableCat.innerPuzzle);
  }

  static Program makeCatPuzzle(Puzzlehash assetId, Program innerPuzzle) {
    return CAT_MOD
        .curry([Program.fromBytes(CAT_MOD.hash()), Program.fromBytes(assetId), innerPuzzle]);
  }

  void validateSpendBundle(SpendBundle spendBundle) {
    validateSpendBundleSignature(spendBundle);

    // validate assert_coin_announcement if it is created (if there are multiple coins spent)
    List<Bytes>? actualAssertCoinAnnouncementIds;
    final coinsToCreate = <CoinPrototype>[];
    final coinsBeingSpent = <CoinPrototype>[];
    Bytes? originId;
    final catSpends = spendBundle.coinSpends.where((spend) => spend.type == SpendType.cat2);
    for (final catSpend in catSpends) {
      final outputConditions = catSpend.puzzleReveal.run(catSpend.solution).program.toList();

      // find create_coin conditions
      final coinCreationConditions = outputConditions
          .where(CreateCoinCondition.isThisCondition)
          .map(CreateCoinCondition.fromProgram)
          .toList();

      for (final coinCreationCondition in coinCreationConditions) {
        coinsToCreate.add(
          CoinPrototype(
            parentCoinInfo: catSpend.coin.id,
            puzzlehash: coinCreationCondition.destinationPuzzlehash,
            amount: coinCreationCondition.amount,
          ),
        );
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
        final assertCoinAnnouncementPrograms =
            outputConditions.where(AssertCoinAnnouncementCondition.isThisCondition).toList();

        // set actualAssertCoinAnnouncementIds only if it is null
        actualAssertCoinAnnouncementIds ??= assertCoinAnnouncementPrograms
            .map(AssertCoinAnnouncementCondition.getAnnouncementIdFromProgram)
            .toList();
      }
      // look for assert coin announcement condition
    }

    // check for duplicate coins
    BaseWalletService.checkForDuplicateCoins(coinsToCreate);
    BaseWalletService.checkForDuplicateCoins(coinsBeingSpent);

    if (catSpends.length > 1) {
      assert(
        actualAssertCoinAnnouncementIds != null,
        'No assert_coin_announcement condition when multiple spends',
      );
      assert(originId != null, 'No create_coin conditions');

      // construct assert_coin_announcement id from spendbundle, verify against output
      final existingCoinsMessage = coinsBeingSpent.fold(
        Bytes.empty,
        (Bytes previousValue, coin) => previousValue + coin.id,
      );

      final message = existingCoinsMessage.sha256Hash();

      final constructedAnnouncement = AssertCoinAnnouncementCondition(
        originId!,
        message,
        //morphBytes: Bytes.fromHex('ca'),
      );

      if (!actualAssertCoinAnnouncementIds!.contains(constructedAnnouncement.announcementId)) {
        throw IncorrectAnnouncementIdException();
      }
    }
  }

  static DeconstructedCatPuzzle? matchCatPuzzle(Program catPuzzle) {
    final uncurried = catPuzzle.uncurry();

    final uncurriedPuzzle = uncurried.program;
    if (uncurriedPuzzle.hash() != CAT_MOD_HASH) {
      return null;
    }

    return DeconstructedCatPuzzle(
      uncurriedPuzzle: uncurriedPuzzle,
      assetId: Puzzlehash(uncurried.arguments[1].atom),
      innerPuzzle: uncurried.arguments[2],
    );
  }

  Future<PuzzleInfo> getPuzzleInfo(Bytes assetId) async {
    Map<String, dynamic> puzzleInfo = {
      'type': AssetType.CAT,
      'tail': assetId.toHexWithPrefix(),
    };
    return PuzzleInfo(puzzleInfo);
  }
}

class DeconstructedCatPuzzle {
  final Program uncurriedPuzzle;
  final Puzzlehash assetId;
  final Program innerPuzzle;

  DeconstructedCatPuzzle({
    required Program uncurriedPuzzle,
    required this.assetId,
    required this.innerPuzzle,
  }) : uncurriedPuzzle = (uncurriedPuzzle == CAT_MOD)
            ? uncurriedPuzzle
            : throw ArgumentError('Supplied puzzle is not cat puzzle');
}

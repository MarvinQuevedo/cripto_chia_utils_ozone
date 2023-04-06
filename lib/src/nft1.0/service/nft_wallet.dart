import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:tuple/tuple.dart';

import '../../core/models/outer_puzzle.dart' as outerPuzzle;

import '../../core/exceptions/change_puzzlehash_needed_exception.dart';
import '../../core/service/conditions_utils.dart';

class NftWallet extends BaseWalletService {
  final StandardWalletService standardWalletService = StandardWalletService();

  Offer makeNftOffer(
      {required WalletKeychain keychain,
      required Map<Bytes?, int> offerDict,
      required Map<Bytes, PuzzleInfo> driverDict,
      required Puzzlehash targetPuzzleHash,
      required List<FullCoin> selectedCoins,
      int fee = 0,
      int? mintCoinAmount,
      Puzzlehash? changePuzzlehash,
      List<CoinPrototype>? standardCoinsForFee,
      NFTCoinInfo? nftCoin,
      required bool old}) {
    final amounts = offerDict.values.toList();
    if (offerDict.length != 2 || ((amounts[0] > 0) == (amounts[1] > 0))) {
      throw Exception(
          "Royalty enabled NFTs only support offering/requesting one NFT for one currency");
    }
    bool offerringNft = false;
    Bytes? offeredAssetId;
    Bytes? requestedAssetId;

    offerDict.forEach((Bytes? assetId, int amount) {
      if (amount < 0) {
        offeredAssetId = assetId;
        if (assetId != null) {
          // check if asset is an NFT
          offerringNft = driverDict[assetId]!.checkType(types: [
            AssetType.SINGLETON,
            AssetType.METADATA,
            AssetType.OWNERSHIP,
          ]);
        }
      } else {
        requestedAssetId = assetId;
      }
    });

    if (offerringNft) {
      return _makeOfferingNftOffer(
        keychain: keychain,
        offerDict: offerDict,
        driverDict: driverDict,
        fee: fee,
        standardCoinsForFee: standardCoinsForFee,
        minCoinAmount: mintCoinAmount,
        requestedAssetId: requestedAssetId,
        offeredAssetId: offeredAssetId,
        selectedCoins: selectedCoins,
        nftCoin: nftCoin,
        changePuzzlehash: changePuzzlehash,
        targetPuzzleHash: targetPuzzleHash,
        old: old,
      );
    } else if (requestedAssetId != null) {
      return _makeRequestingNftOffer(
        keychain: keychain,
        offerDict: offerDict,
        driverDict: driverDict,
        fee: fee,
        nftCoin: nftCoin,
        standardCoinsForFee: standardCoinsForFee,
        minCoinAmount: mintCoinAmount,
        requestedAssetId: requestedAssetId!,
        selectedCoins: selectedCoins,
        changePuzzlehash: changePuzzlehash,
        targetPuzzleHash: targetPuzzleHash,
        offeredAssetId: offeredAssetId,
        old: old,
      );
    } else {
      Exception("No NFT in offer!");
    }

    throw Exception("");
  }

  SpendBundle createTransferSpendBundle({
    required NFTCoinInfo nftCoin,
    required WalletKeychain keychain,
    required Puzzlehash targetPuzzleHash,
    Puzzlehash? changePuzzlehash,
    int fee = 0,
    List<CoinPrototype>? standardCoinsForFee,
  }) {
    print(
      "p2puzzleNew = ${UncurriedNFT.uncurry(nftCoin.fullPuzzle).p2PuzzleHash.toHex()} ",
    );
    return generateSignedSpendBundle(
        payments: [
          Payment(
            nftCoin.coin.amount,
            targetPuzzleHash,
            memos: <Bytes>[
              targetPuzzleHash,
            ],
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
    print(
      "p2puzzleNew = ${UncurriedNFT.uncurry(nftCoin.fullPuzzle).p2PuzzleHash.toHex()} ",
    );
    final generateSpendsTuple = generateUnsignedSpendbundle(
      payments: payments,
      coinsInput: coins,
      keychain: keychain,
      standardCoinsForFee: standardCoinsForFee,
      changePuzzlehash: changePuzzlehash,
      originId: nftCoin.nftId,
      nftCoin: nftCoin,
      fee: fee,
      newOwner: newOwner,
      newDidInnerhash: newDidInnerhash,
      tradePricesList: tradePricesList,
      metadataUpdate: metadataUpdate,
      coinAnnouncementsToAssert: coinAnnouncementsToAssert,
      puzzleAnnouncementsToAssert: puzzleAnnouncementsToAssert,
    );

    var unsignedSpendBundle = generateSpendsTuple.item1;
    final chiaSpendBundle = generateSpendsTuple.item2;
    print(
      "p2puzzleNew = ${UncurriedNFT.uncurry(unsignedSpendBundle.coinSpends.first.puzzleReveal).p2PuzzleHash.toHex()} ",
    );
    SpendBundle spendBundle = _sign(
      unsignedSpendBundle: unsignedSpendBundle,
      keychain: keychain,
    );

    standardWalletService.validateSpendBundle(spendBundle);

    standardWalletService.validateSpendBundleSignature(spendBundle);

    print(
      "p2puzzleNew = ${UncurriedNFT.uncurry(generateSpendsTuple.item1.coinSpends.first.puzzleReveal).p2PuzzleHash.toHex()} ",
    );

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
    Bytes? newOwner,
    Bytes? newDidInnerhash,
    Program? tradePricesList,
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
      if (newOwner == null) {
        final walletVector = keychain.getWalletVector(payments.first.puzzlehash);
        if (walletVector != null) {
          newOwner = unft.ownerDid;
        }
      }

      magicCondition = Program.list([
        Program.fromInt(-10),
        newOwner != null ? Program.fromBytes(newOwner) : Program.list([]),
        tradePricesList != null ? tradePricesList : Program.list([]),
        newDidInnerhash != null ? Program.fromBytes(newDidInnerhash) : Program.list([]),
      ]);
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
            magicCondition,
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
        final uncurriedNft = UncurriedNFT.tryUncurry(coinSpend.puzzleReveal);
        if (uncurriedNft != null) {
          print("Found a NFT state layer to sign");
          puzzleHashList.add(uncurriedNft.p2PuzzleHash);

          print(
            "p2puzzleNew = ${uncurriedNft.p2PuzzleHash.toHex()} ",
          );
          print(Address.fromPuzzlehash(uncurriedNft.p2PuzzleHash, "txch").address);
        }
      }
      for (final ph in puzzleHashList) {
        final coinWalletVector = keychain.getWalletVector(ph);

        final coinPrivateKey = coinWalletVector!.childPrivateKey;
        keys[coinPrivateKey.getG1().toBytes()] = coinPrivateKey;

        final synthSecretKey = calculateSyntheticPrivateKey(coinPrivateKey);
        keys[synthSecretKey.getG1().toBytes()] = synthSecretKey;
      }

      final conditionsResult = conditionsDictForSolution(
        puzzleReveal: coinSpend.puzzleReveal,
        solution: coinSpend.solution,
      );

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
              print("sign message ${msg.toHex()} }");
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

    final aggregatedSignature = AugSchemeMPL.aggregate(signatures);
    print(aggregatedSignature.toHex());

    return unsignedSpendBundle.addSignature(aggregatedSignature);
  }

// generate_new_nft
  SpendBundle generateNewNft(
      {required List<CoinPrototype> coins,
      required WalletKeychain keychain,
      Puzzlehash? changePuzzlehash,
      required NftMetadata metadata,
      required Puzzlehash targetPuzzleHash,
      Puzzlehash? royaltyPuzzleHash,
      int percentage = 0,
      DidInfo? didInfo,
      int fee = 0}) {
    final amount = 1;
    final launcherParentCoin = coins.toList().first;
    // final genesisLauncherPuzz = LAUNCHER_PUZZLE;

    final launcherCoin = CoinPrototype(
      parentCoinInfo: launcherParentCoin.id,
      puzzlehash: LAUNCHER_PUZZLE_HASH,
      amount: amount,
    );

    print("Generating NFT with launcher coin %s and metadata:  ${launcherCoin}, ${metadata}");

    late Program innerPuzzle;

    final targetWalletVector = keychain.getWalletVector(targetPuzzleHash);
    final p2InnerPuzzle = getPuzzleFromPk(targetWalletVector!.childPublicKey);
    print("Attempt to generate a new NFT to ${targetPuzzleHash.toHex()}");
    print("address = ${Address.fromPuzzlehash(targetPuzzleHash, "txch").address}");
    if (didInfo != null) {
      // eve coin DID can be set to whatever so we keep it empty
      // WARNING: wallets should always ignore DID value for eve coins as they can be set
      //          to any DID without approval
      innerPuzzle = NftService.createOwnwershipLayerPuzzle(
        nftId: launcherParentCoin.id,
        didId: null,
        p2Puzzle: p2InnerPuzzle,
        percentage: percentage,
        royaltyPuzzleHash: royaltyPuzzleHash,
      );
    } else {
      innerPuzzle = p2InnerPuzzle;
    }

    final eveFullPuz = NftService.createFullPuzzle(
      singletonId: launcherParentCoin.id,
      metadata: metadata.toProgram(),
      metadataUpdaterHash: NFT_METADATA_UPDATER_HASH,
      innerPuzzle: innerPuzzle,
    );
    final eveFullPuzzleHash = eveFullPuz.hash();
    print(eveFullPuz.hash().toHex());

    final announcementMessage = Program.list([
      Program.fromBytes(eveFullPuzzleHash),
      Program.fromInt(launcherCoin.amount),
      Program.list([]),
    ]).hash();
    final assertCoinAnnouncement = AssertCoinAnnouncementCondition(
      launcherCoin.id,
      announcementMessage,
    );

    final createLauncherSpendBundle = standardWalletService.createSpendBundle(
      payments: [
        Payment(
          launcherCoin.amount,
          launcherCoin.puzzlehash,
        ),
      ],
      coinsInput: coins,
      keychain: keychain,
      changePuzzlehash: changePuzzlehash,
      originId: launcherParentCoin.id,
      fee: fee,
      coinAnnouncementsToAssert: [assertCoinAnnouncement],
    );

    final genesisLauncherSolution = Program.list([
      Program.fromBytes(eveFullPuz.hash()),
      Program.fromInt(launcherCoin.amount),
      Program.list([]),
    ]);

    final launcherCS = CoinSpend(
      coin: launcherCoin,
      puzzleReveal: LAUNCHER_PUZZLE,
      solution: genesisLauncherSolution,
    );

    final launcherSB = SpendBundle(coinSpends: [launcherCS]);
    final eveCoin = CoinPrototype(
      amount: amount,
      parentCoinInfo: launcherCoin.id,
      puzzlehash: eveFullPuz.hash(),
    );

    final bundlesToAgg = [createLauncherSpendBundle, launcherSB];

    Bytes? didInnerHash;

    if (didInfo != null && didInfo.didId.isNotEmpty) {
      final apporvalInfo = getDidApprovalInfo(
        nftsIds: [launcherCoin.id],
        didInfo: didInfo,
        keychain: keychain,
        coins: coins,
      );
      bundlesToAgg.add(apporvalInfo.item2);
    }

    final nftCoin = NFTCoinInfo(
      nftId: launcherCoin.id,
      coin: eveCoin,
      fullPuzzle: eveFullPuz,
      mintHeight: 0,
      latestHeight: 0,
      lineageProof: LineageProof(
        parentName: Puzzlehash(launcherCoin.parentCoinInfo),
        amount: launcherCoin.amount,
      ),
      pendingTransaction: true,
      minterDid: didInfo?.didId,
    );

    final signedSpendBundle = generateSignedSpendBundle(
      payments: [
        Payment(eveCoin.amount, targetPuzzleHash, memos: <Bytes>[
          targetPuzzleHash.toBytes(),
        ])
      ],
      coins: coins,
      keychain: keychain,
      nftCoin: nftCoin,
      newOwner: didInfo?.didId,
      additionalBundles: bundlesToAgg,
      newDidInnerhash: didInnerHash,
      changePuzzlehash: changePuzzlehash,
    );
    return signedSpendBundle;
  }

  Offer _makeOfferingNftOffer({
    required WalletKeychain keychain,
    required Map<Bytes?, int> offerDict,
    required Map<Bytes, PuzzleInfo> driverDict,
    required int fee,
    required Puzzlehash? changePuzzlehash,
    int? minCoinAmount,
    Bytes? requestedAssetId,
    Bytes? offeredAssetId,
    required Puzzlehash targetPuzzleHash,
    NFTCoinInfo? nftCoin,
    required List<FullCoin> selectedCoins,
    List<CoinPrototype>? standardCoinsForFee,
    required bool old,
  }) {
    if (offeredAssetId == null) {
      throw Exception("offered Asset Id not can be null");
    }
    driverDict[offeredAssetId]!.info["also"]["also"]['owner'] = '()';
    final Puzzlehash p2Ph = targetPuzzleHash;
    final int offerredAmount = offerDict[offeredAssetId]!.abs();
    final NFTCoinInfo offeredCoinInfo = nftCoin!;
    final int requestedAmount = offerDict[requestedAssetId]!;

    late final Program tradePrices;
    // If we are jus asking for xch
    if (requestedAssetId == null) {
      tradePrices =
          Program.list([Program.fromInt(requestedAmount), Program.fromBytes(OFFER_MOD_HASH)]);
    } else {
      tradePrices = Program.list([
        Program.list([
          Program.fromInt(requestedAmount),
          Program.fromBytes(
            outerPuzzle
                .constructPuzzle(
                  constructor: driverDict[requestedAssetId]!,
                  innerPuzzle: OFFER_MOD,
                )
                .hash(),
          )
        ]),
      ]);
    }

    final notarizedPayments = Offer.notarizePayments(requestedPayments: {
      requestedAssetId: <Payment>[
        Payment(requestedAmount, p2Ph, memos: [
          p2Ph,
        ])
      ]
    }, coins: [
      offeredCoinInfo.coin,
    ]);

    final announcements = Offer.calculateAnnouncements(
      notarizedPayment: notarizedPayments,
      driverDict: driverDict,
      old: old,
    );
    List<SpendBundle> spendBundles = [];

    final nftSpBundle = generateSignedSpendBundle(
      payments: [Payment(offerredAmount, Offer.ph(old))],
      coins: [offeredCoinInfo.coin],
      keychain: keychain,
      nftCoin: nftCoin,
      fee: fee,
      puzzleAnnouncementsToAssert: announcements,
      tradePricesList: tradePrices,
      standardCoinsForFee: standardCoinsForFee,
      changePuzzlehash: changePuzzlehash,
    );

    spendBundles.add(nftSpBundle);

    final totalSpendBundle = SpendBundle.aggregate(spendBundles);

    return Offer(
      requestedPayments: notarizedPayments,
      bundle: totalSpendBundle,
      driverDict: driverDict,
      old: old,
    );
  }

  Offer _makeRequestingNftOffer({
    required WalletKeychain keychain,
    required Map<Bytes?, int> offerDict,
    required Map<Bytes, PuzzleInfo> driverDict,
    required int fee,
    required Puzzlehash? changePuzzlehash,
    int? minCoinAmount,
    required Bytes requestedAssetId,
    Bytes? offeredAssetId,
    required Puzzlehash targetPuzzleHash,
    NFTCoinInfo? nftCoin,
    required List<FullCoin> selectedCoins,
    List<CoinPrototype>? standardCoinsForFee,
    required bool old,
  }) {
    driverDict[offeredAssetId]!.info["also"]["also"]['owner'] = '()';
    final requestedInfo = driverDict[requestedAssetId];
    final transfertInfo = requestedInfo?.also?.also;
    if (transfertInfo == null) {
      throw Exception("Transfer info cand be null");
    }
    final royaltyPercentage = transfertInfo["transfer_program"]["royalty_percentage"] as int;
    final royaltyAddress = Puzzlehash.fromHex(
      transfertInfo["transfer_program"]["royalty_address"] as String,
    );

    final p2Ph = targetPuzzleHash;

    final requestedPayments = <Bytes?, List<Payment>>{
      requestedAssetId: [
        Payment(
          offerDict[requestedAssetId]!,
          p2Ph,
        ),
      ]
    };

    final offeredAmount = offerDict[offeredAssetId]!.abs();
    final royaltyAmount = (offeredAmount * (royaltyPercentage / 10000)).floor();

    if (offeredAmount == royaltyAmount) {
      throw Exception("Amount offered and amount paid in royalties are equal");
    }

    //int coinAmountNeeded = 0;
    late final wallet;

    // Check is XCH offer
    if (offeredAssetId == null) {
      wallet = StandardWalletService();
      //coinAmountNeeded = offeredAmount + royaltyAmount + fee;
    } else {
      wallet = CatWalletService();
      //coinAmountNeeded = offeredAmount + royaltyAmount;
    }

    final catCoins =
        selectedCoins.where((element) => element.isCatCoin).map((e) => e.toCatCoin()).toList();

    final standardsCoins =
        selectedCoins.where((element) => !element.isCatCoin).map((e) => e.coin).toList();

    final pmtCoins = wallet is StandardWalletService ? standardsCoins : catCoins;

    final notarizedPayments = Offer.notarizePayments(
      requestedPayments: requestedPayments,
      coins: pmtCoins,
    );

    final announcementsToAssert = Offer.calculateAnnouncements(
      notarizedPayment: notarizedPayments,
      driverDict: driverDict,
      old: old,
    );

    announcementsToAssert.addAll(
      Offer.calculateAnnouncements(
        notarizedPayment: {
          offeredAssetId: [
            NotarizedPayment(
              royaltyAmount,
              royaltyAddress,
              memos: [royaltyAddress],
              nonce: requestedAssetId,
            ),
          ]
        },
        driverDict: driverDict,
        old: old,
      ),
    );

    late final SpendBundle spendBundle;

    if (wallet is StandardWalletService) {
      final standarBundle = StandardWalletService().createSpendBundle(
        payments: [
          Payment(offeredAmount, Offer.ph(old)),
        ],
        coinsInput: selectedCoins,
        keychain: keychain,
        fee: fee,
        puzzleAnnouncementsToAssert: announcementsToAssert,
        changePuzzlehash: changePuzzlehash,
      );

      spendBundle = standarBundle;
    } else {
      final catPayments = [
        Payment(offeredAmount, Offer.ph(old)),
        Payment(royaltyAmount, Offer.ph(old)),
      ];

      final catBundle = CatWalletService().createSpendBundle(
        payments: catPayments,
        catCoinsInput: catCoins,
        keychain: keychain,
        fee: fee,
        standardCoinsForFee: standardsCoins,
        puzzleAnnouncementsToAssert: announcementsToAssert,
        changePuzzlehash: changePuzzlehash,
      );

      spendBundle = catBundle;
    }

    /*
      
      Create a spend bundle for the royalty payout from OFFER MOD
      make the royalty payment solution
      ((nft_launcher_id . ((ROYALTY_ADDRESS, royalty_amount, (ROYALTY_ADDRESS)))))
      we are basically just recreating the royalty announcement above.

     */
    late final Program offerPuzzle;
    late final Program royaltySol;
    CoinPrototype? royaltyCoin = null;
    late final CoinSpend parentSpend;
    late final Puzzlehash royaltyPh;

    final innerRoyaltySol = Program.list(
      [
        Program.list([
          Program.fromBytes(requestedAssetId),
          Program.list([
            Program.fromBytes(royaltyAddress),
            Program.fromInt(royaltyAmount),
          ])
        ]),
      ],
    );
    if (offeredAssetId == null) {
      offerPuzzle = OFFER_MOD;
      royaltySol = innerRoyaltySol;
    } else {
      offerPuzzle = outerPuzzle.constructPuzzle(
        constructor: driverDict[offeredAssetId]!,
        innerPuzzle: OFFER_MOD,
      );
    }

    royaltyPh = offerPuzzle.hash();
    for (final coin in spendBundle.additions) {
      if (coin.amount == royaltyAmount && coin.puzzlehash == royaltyPh) {
        royaltyCoin = coin;
        parentSpend = spendBundle.coinSpends.first;
      }
    }

    if (royaltyCoin == null) {
      throw Exception("Royalty Coin is not found in the spend bundles");
    }

    if (offeredAssetId != null) {
      final royaltyCoinHex = royaltyCoin.toBytes().toHexWithPrefix();
      final parendSpendHex = parentSpend.toHexWithPrefix();
      final solver = Solver({
        "coin": royaltyCoinHex,
        "parent_spend": parendSpendHex,
        "siblings": "(" + royaltyCoinHex + ")",
        "sibling_spends": "(" + parendSpendHex + ")",
        "sibling_puzzles": "()",
        "sibling_solutions": "()",
      });
      royaltySol = outerPuzzle.solvePuzzle(
        constructor: driverDict[offeredAssetId]!,
        solver: solver,
        innerPuzzle: OFFER_MOD,
        innerSolution: innerRoyaltySol,
      );
    }

    final royaltySpend = SpendBundle(
      coinSpends: [
        CoinSpend(
          coin: royaltyCoin,
          puzzleReveal: offerPuzzle,
          solution: royaltySol,
        ),
      ],
    );
    final totalSpendBundle = SpendBundle.aggregate(
      [
        spendBundle,
        royaltySpend,
      ],
    );
    final offer = Offer(
        requestedPayments: notarizedPayments,
        bundle: totalSpendBundle,
        driverDict: driverDict,
        old: old);
    return offer;
  }

  /// Get DID spend with announcement created we need to transfer NFT with did with current inner hash of DID

  /// We also store `did_id` and then iterate to find the did wallet as we'd otherwise have to subscribe to
  /// any changes to DID wallet and storing wallet_id is not guaranteed to be consistent on wallet crash/reset.

  Tuple2<Bytes, SpendBundle> getDidApprovalInfo({
    required List<Bytes> nftsIds,
    required DidInfo didInfo,
    required List<CoinPrototype> coins,
    required WalletKeychain keychain,
  }) {
    final didBundle = DidWallet().createMessageSpend(
      didInfo,
      coins: coins,
      keychain: keychain,
    );
    final didInnerhash = didInfo.currentInner!.hash();
    return Tuple2(didInnerhash, didBundle);
  }
}

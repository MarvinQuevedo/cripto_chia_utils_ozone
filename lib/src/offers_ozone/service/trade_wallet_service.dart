import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class TradeWalletService extends BaseWalletService {
  final StandardWalletService standardWalletService = StandardWalletService();
  final catWallet = CatWalletService();

  /// `generate_secure_bundle` simulates a wallet's `generate_signed_transaction`
  /// but doesn't bother with non-offer announcements
  Offer createOfferBundle(
      {required List<FullCoin> selectedCoins,
      required List<AssertPuzzleCondition> announcements,
      required Map<Bytes?, int> offeredAmounts,
      required WalletKeychain keychain,
      required int fee,
      required Puzzlehash changePuzzlehash,
      required Map<Bytes?, PuzzleInfo> driverDict,
      required Map<Bytes?, List<NotarizedPayment>> notarizedPayments,
      required bool old}) {
    final transactions = <SpendBundle>[];

    final feeLeftToPay = fee;

    offeredAmounts.forEach((assetId, amount) {
      if (assetId == null) {
        final standarBundle = StandardWalletService().createSpendBundle(
          payments: [
            Payment(offeredAmounts[assetId]!.abs(), Offer.ph(old)),
          ],
          coinsInput: selectedCoins,
          keychain: keychain,
          fee: feeLeftToPay,
          puzzleAnnouncementsToAssert: announcements,
          changePuzzlehash: changePuzzlehash,
        );
        transactions.add(standarBundle);
      } else {
        bool isCat = driverDict[assetId]!.type == "cat";

        if (isCat) {
          final catPayments = [
            Payment(offeredAmounts[assetId]!.abs(), Offer.ph(old), memos: <Bytes>[
              Offer.ph(old).toBytes(),
            ]),
          ];
          final catCoins = selectedCoins
              .where((element) => element.isCatCoin)
              .map((e) => e.toCatCoin())
              .toList();
          final standardsCoins =
              selectedCoins.where((element) => !element.isCatCoin).map((e) => e.coin).toList();
          final catBundle = CatWalletService().createSpendBundle(
            payments: catPayments,
            catCoinsInput: catCoins,
            keychain: keychain,
            fee: feeLeftToPay,
            standardCoinsForFee: standardsCoins,
            puzzleAnnouncementsToAssert: announcements,
            changePuzzlehash: changePuzzlehash,
          );
          final catBytes = catBundle.toBytes();
          final _ = SpendBundle.fromBytes(catBytes);
          transactions.add(catBundle);
        } else {
          throw Exception("Not implemented for ${driverDict[assetId]?.type}}");
        }
      }
    });

    final totalSpendBundle = transactions.fold<SpendBundle>(
      SpendBundle(coinSpends: []),
      (previousValue, spendBundle) => previousValue + spendBundle,
    );

    return Offer(
        requestedPayments: notarizedPayments,
        bundle: totalSpendBundle,
        driverDict: driverDict,
        old: old);
  }

  Offer createOfferForIds(
      {required List<FullCoin> coins,
      required Map<Bytes?, PuzzleInfo> driverDict,
      required Map<Bytes?, List<Payment>> requiredPayments,
      required Map<Bytes?, int> offeredAmounts,
      int fee = 0,
      validateOnly = false,
      required Puzzlehash changePuzzlehash,
      required WalletKeychain keychain,
      required bool old}) {
    final chiaRequestedPayments = requiredPayments;

    final chiaNotariedPayments = Offer.notarizePayments(
      requestedPayments: chiaRequestedPayments,
      coins: coins,
    );
    final chiaAnnouncements = Offer.calculateAnnouncements(
      notarizedPayment: chiaNotariedPayments,
      driverDict: driverDict,
      old: old,
    );

    final chiaOffer = createOfferBundle(
        announcements: chiaAnnouncements,
        offeredAmounts: offeredAmounts,
        selectedCoins: coins,
        fee: fee,
        changePuzzlehash: changePuzzlehash,
        keychain: keychain,
        notarizedPayments: chiaNotariedPayments,
        driverDict: driverDict,
        old: old);

    return chiaOffer;
  }

  ///  Group coins by asset id and type
  Map<OfferAssetData, List<CoinPrototype>> agroupCoins(List<FullCoin> coins) {
    final groupedCoins = <OfferAssetData, List<CoinPrototype>>{};
    for (final coin in coins) {
      final assetData = OfferAssetData.fromFullCoin(coin);
      if (groupedCoins.containsKey(assetData)) {
        groupedCoins[assetData]!.add(coin.coin);
      } else {
        groupedCoins[assetData] = [coin.coin];
      }
    }
    return groupedCoins;
  }

  Future<Offer> responseOffer({
    required List<FullCoin> coins,
    required WalletKeychain keychain,
    required int fee,
    required Puzzlehash targetPuzzleHash,
    required Puzzlehash changePuzzlehash,
    required Offer offer,
  }) async {
    final isOld = offer.old;
    final groupedCoins = agroupCoins(coins);
    final driverDict = <Bytes?, PuzzleInfo>{};
    final takeOfferDict = <Bytes?, int>{};
    Map<OfferAssetData?, int> offerredAmounts = {};

    final arbitrage = offer.arbitrage();
    final offerDriverDict = offer.driverDict;

    arbitrage.forEach((assetId, amount) {
      if (assetId != null) {
        final assetType = offerDriverDict[assetId]!.type;
        if (assetType == OfferType.cat.value) {
          driverDict[assetId] = PuzzleInfo({
            "type": OfferType.cat.value,
            "tail": assetId.toHex(),
          });
        } else {
          driverDict[assetId] = PuzzleInfo({
            "type": OfferType.singleton.value,
            "launcher_id": assetId.toHexWithPrefix(),
            "launcher_ph": assetId.toHexWithPrefix(),
          });
        }
      }
    });

    final offerRequestedAmounts = offer.getRequestedAmounts();
    offerRequestedAmounts.forEach((assetId, amount) {
      takeOfferDict[assetId] = amount;

      if (assetId == null) {
        final totalChia = amount + fee;
        offerredAmounts[OfferAssetData.standart()] = totalChia.abs();
      } else {
        final assetType = offerDriverDict[assetId]!.type;
        if (assetType == OfferType.cat.value) {
          offerredAmounts[OfferAssetData.cat(tailHash: assetId)] = amount.abs();
        } else if (assetType == OfferType.singleton.value) {
          offerredAmounts[OfferAssetData.singletonNft(launcherPuzhash: assetId)] = amount.abs();
        }
      }
    });

    final offerOfferedAmounts = offer.getOfferedAmounts();
    Map<OfferAssetData?, List<int>> requestedAmounts = {};
    final payments = <Bytes?, List<Payment>>{};
    offerOfferedAmounts.forEach((assetId, amount) {
      if (payments[assetId] == null) {
        payments[assetId] = [];
      }
      payments[assetId]!.add(
        Payment(amount.abs(), targetPuzzleHash),
      );
      if (assetId == null) {
        requestedAmounts[OfferAssetData.standart()] = [amount.abs()];
      } else {
        final assetType = offerDriverDict[assetId]!.type;
        if (assetType == OfferType.cat.value) {
          requestedAmounts[OfferAssetData.cat(tailHash: assetId)] = [amount.abs()];
        } else if (assetType == OfferType.singleton.value) {
          requestedAmounts[OfferAssetData.singletonNft(launcherPuzhash: assetId)] = [amount.abs()];
        }
      }
    });

    final preparedData = await _prepareOfferData(
      coins: groupedCoins,
      requestedAmounts: requestedAmounts,
      offerredAmounts: offerredAmounts,
      fee: fee,
      targetPuzzleHash: targetPuzzleHash,
    );

    final offerWallet = TradeWalletService();
    final responseOffer = await offerWallet.createOfferForIds(
      coins: coins,
      driverDict: preparedData.driverDict,
      requiredPayments: preparedData.payments,
      offeredAmounts: preparedData.offerredAmounts,
      changePuzzlehash: changePuzzlehash,
      keychain: keychain,
      old: isOld,
      fee: fee,
    );

    final completedOffer = Offer.aggreate([offer, responseOffer]);
    return completedOffer;
  }

  // create doc comments
  ///   Create offer
  ///  [coins] - list of full  coins to use in offer
  /// [requesteAmounts] - map of asset id and amount to request,
  /// [offerredAmounts] - map of asset id and amount to offer
  /// [keychain] - keychain to use for offer
  /// [fee] - fee to use for offer
  /// [targetPuzzleHash] - puzzlehash to use for offer
  /// [isOld] - is old offer
  /// [changePuzzlehash] - puzzlehash to use for change
  Future<Offer> createOffer({
    required List<FullCoin> coins,
    required Map<OfferAssetData?, List<int>> requesteAmounts,
    required Map<OfferAssetData?, int> offerredAmounts,
    required WalletKeychain keychain,
    required int fee,
    required Puzzlehash targetPuzzleHash,
    required bool isOld,
    required Puzzlehash changePuzzlehash,
  }) async {
    Map<OfferAssetData, List<CoinPrototype>> coinPrototypes = agroupCoins(coins);

    final preparedData = await _prepareOfferData(
      coins: coinPrototypes,
      requestedAmounts: requesteAmounts,
      offerredAmounts: offerredAmounts,
      fee: fee,
      targetPuzzleHash: targetPuzzleHash,
    );

    final offerWallet = TradeWalletService();
    final offer = offerWallet.createOfferForIds(
      coins: coins,
      driverDict: preparedData.driverDict,
      requiredPayments: preparedData.payments,
      offeredAmounts: preparedData.offerredAmounts,
      changePuzzlehash: changePuzzlehash,
      keychain: keychain,
      old: isOld,
      fee: fee,
    );
    return offer;
  }

  Map<Bytes?, PuzzleInfo> _createDict({
    required Map<OfferAssetData?, List<int>> requestedAmounts,
    required Map<OfferAssetData?, int> offerredAmounts,
  }) {
    Map<Bytes?, PuzzleInfo> driverDict = {};
    final uniqueAssetsData =
        (requestedAmounts.keys.toList() + offerredAmounts.keys.toList()).toSet();

    for (final assetData in uniqueAssetsData) {
      if (assetData != null) {
        if (assetData.type == OfferType.cat.value) {
          final tailHash = assetData.assetId;
          driverDict[tailHash] = PuzzleInfo({
            "type": OfferType.cat.value,
            "tail": tailHash!.toHexWithPrefix(),
          });
        } else if (assetData.type == SpendType.nft) {
          driverDict[null] = PuzzleInfo({
            "type": OfferType.singleton.value,
            "launcher_id": assetData.assetId!.toHexWithPrefix(),
            "launcher_ph": assetData.assetId!.toHexWithPrefix(),
          });
        }
      }
    }
    return driverDict;
  }

  Future<PreparedTradeData> _prepareOfferData(
      {required Map<OfferAssetData?, List<int>> requestedAmounts,
      required Map<OfferAssetData?, int> offerredAmounts,
      required int fee,
      required Map<OfferAssetData?, List<CoinPrototype>> coins,
      required Puzzlehash targetPuzzleHash}) async {
    Map<Bytes?, PuzzleInfo> driverDict = _createDict(
      requestedAmounts: requestedAmounts,
      offerredAmounts: offerredAmounts,
    );

    // check offerredAmountsCoins
    offerredAmounts.forEach((assetData, amount) {
      int assetAmount = amount;
      final assetCoins = coins[assetData];

      if (assetData == null) {
        // is standard, add fee for check coins amount
        assetAmount = (offerredAmounts[null] ?? 0) + fee;
      }
      if (assetCoins == null) {
        throw Exception(
            "Not enough coins for offerredAmounts in the asset: ${assetData ?? 'standard'}");
      }
      final coinsAmount = assetCoins.map((e) => e.amount).reduce((a, b) => a + b);
      if (coinsAmount < assetAmount) {
        throw Exception(
            "Not enough coins for offerredAmounts (${assetAmount} <  ${coinsAmount}) in the asset: ${assetData ?? 'standard'}");
      }
    });

    final payments = <Bytes?, List<Payment>>{};

    requestedAmounts.forEach((assetData, amounts) {
      final assetId = assetData?.assetId;
      if (payments[assetId] == null) {
        payments[assetId] = [];
      }
      for (var amount in amounts) {
        List<Bytes> memos = [];
        if (assetId != null) {
          memos = [targetPuzzleHash.toBytes()];
        }
        payments[assetId]!.add(Payment(
          amount,
          targetPuzzleHash,
          memos: memos,
        ));
      }
    });
    final offeredAmountsSimple = <Bytes?, int>{};
    offerredAmounts.forEach((assetData, amount) {
      final assetId = assetData?.assetId;
      offeredAmountsSimple[assetId] = amount;
    });

    return PreparedTradeData(
      payments: payments,
      driverDict: driverDict,
      offerredAmounts: offeredAmountsSimple,
    );
  }
}

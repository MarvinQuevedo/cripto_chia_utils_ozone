import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/core/service/base_wallet.dart';

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
        final catPayments = [
          Payment(offeredAmounts[assetId]!.abs(), Offer.ph(old), memos: <Bytes>[
            Offer.ph(old).toBytes(),
          ]),
        ];
        final catCoins =
            selectedCoins.where((element) => element.isCatCoin).map((e) => e.toCatCoin()).toList();
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
      required Map<Bytes?, List<Payment>> payments,
      required Map<Bytes?, int> offeredAmounts,
      int fee = 0,
      validateOnly = false,
      required Puzzlehash changePuzzlehash,
      required WalletKeychain keychain,
      required bool old}) {
    final chiaRequestedPayments = payments;

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
/* 
  Offer responseOffer({
    required Offer offer,
    int fee = 0,
    required WalletKeychain keychain,
    required List<FullCoin> coins,
    required Puzzlehash changePuzzlehash,
    required Puzzlehash receivePuzzlehash,
  }) {
    final takeOfferDict = <Bytes?, int>{};
    final driverDict = <Bytes?, PuzzleInfo>{};
    final arbitrage = offer.arbitrage();

    arbitrage.forEach((assetId, amount) {
      takeOfferDict[assetId] = amount;
      if (assetId != null) {
        driverDict[assetId] = PuzzleInfo({
          "type": "CAT",
          "tail": assetId,
        });
      }
    });
    final payments = <Bytes?, List<Payment>>{};
    offer.getOfferedAmounts().forEach((assetId, amount) {
      if (payments[assetId] == null) {
        payments[assetId] = [];
      }
      payments[assetId]!.add(Payment(amount, receivePuzzlehash));
    });

    return createOfferForIds(
        changePuzzlehash: changePuzzlehash,
        coins: coins,
        driverDict: driverDict,
        keychain: keychain,
        offeredAmounts: takeOfferDict,
        fee: fee,
        payments: payments);
  } */
}

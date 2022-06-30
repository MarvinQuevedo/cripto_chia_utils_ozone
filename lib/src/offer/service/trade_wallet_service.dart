import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/core/service/base_wallet.dart';

import '../../core/models/conditions/announcement.dart';
import '../models/full_coin.dart';
import '../models/notarized_payment.dart';
import 'package:chia_crypto_utils/src/offer/models/offer.dart';
import 'package:chia_crypto_utils/src/offer/models/puzzle_info.dart';

class TradeWalletService extends BaseWalletService {
  final StandardWalletService standardWalletService = StandardWalletService();
  final catWallet = CatWalletService();

  /// `generate_secure_bundle` simulates a wallet's `generate_signed_transaction`
  /// but doesn't bother with non-offer announcements
  Offer createOfferBundle(
      {required List<FullCoin> selectedCoins,
      required List<Announcement> announcements,
      required Map<Bytes?, int> offeredAmounts,
      required WalletKeychain keychain,
      required int fee,
      required Puzzlehash changePuzzlehash,
      required Map<Bytes?, PuzzleInfo> driverDict,
      required Map<Bytes?, List<NotarizedPayment>> notarizedPayments}) {
    final transactions = <SpendBundle>[];

    final feeLeftToPay = fee;

    for (var coin in selectedCoins) {
      if (coin.assetId == null) {
        final standarBundle = StandardWalletService().createSpendBundle(
            payments: [Payment(offeredAmounts[coin.assetId]!, Offer.ph)],
            coinsInput: selectedCoins,
            keychain: keychain,
            fee: feeLeftToPay,
            coinAnnouncementsToAssert: announcements,
            changePuzzlehash: changePuzzlehash);
        transactions.add(standarBundle);
      } else if (coin.assetId != null) {
        final catBundle = CatWalletService().createSpendBundle(
          payments: [Payment(offeredAmounts[coin.assetId]!, Offer.ph)],
          catCoinsInput: selectedCoins
              .where((element) => element.isCatCoin)
              .map((e) => e.toCatCoin())
              .toList(),
          keychain: keychain,
          fee: feeLeftToPay,
          coinAnnouncementsToAssert: announcements,
        );
        transactions.add(catBundle);
      }
    }
    final totalSpendBundle = transactions.fold<SpendBundle>(
        SpendBundle.empty, (previousValue, spendBundle) => previousValue + spendBundle);

    return Offer(
      requestedPayments: notarizedPayments,
      bundle: totalSpendBundle,
      driverDict: driverDict,
    );
  }

  Offer createOfferForIds({
    required List<FullCoin> coins,
    required Map<Bytes?, PuzzleInfo> driverDict,
    required Map<Bytes?, List<Payment>> payments,
    int fee = 0,
    validateOnly = false,
    required Puzzlehash changePuzzlehash,
    required WalletKeychain keychain,
  }) {
    final chiaRequestedPayments = payments;
    final chiaOfferedAmount = 100;

    final chiaNotariedPayments = Offer.notarizePayments(
      requestedPayments: chiaRequestedPayments,
      coins: coins,
    );
    final chiaAnnouncements = Offer.calculateAnnouncements(
        notarizedPayment: chiaNotariedPayments, driverDict: driverDict);

    final chiaOffer = createOfferBundle(
      announcements: chiaAnnouncements,
      offeredAmounts: {null: chiaOfferedAmount},
      selectedCoins: coins,
      fee: 0,
      changePuzzlehash: changePuzzlehash,
      keychain: keychain,
      notarizedPayments: chiaNotariedPayments,
      driverDict: driverDict,
    );

    return chiaOffer;
  }
}

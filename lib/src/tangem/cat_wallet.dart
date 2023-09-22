import 'standart_wallet.dart';
import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:tuple/tuple.dart';

class TangemCatWallet extends CatWalletService {
  final _standardWalletService = TangemStandardWalletService();
  StandardWalletService get standardWalletService => _standardWalletService;

  @override
  Tuple2<SpendBundle, SignatureHashes?> createSpendBundle({
    required List<Payment> payments,
    required List<CatCoin> catCoinsInput,
    required WalletKeychain keychain,
    Puzzlehash? changePuzzlehash,
    List<Coin> standardCoinsForFee = const [],
    List<AssertCoinAnnouncementCondition> coinAnnouncementsToAssert = const [],
    List<AssertPuzzleCondition> puzzleAnnouncementsToAssert = const [],
    int fee = 0,
    bool unsigned = true,
  }) {
    return super.createSpendBundle(
      payments: payments,
      catCoinsInput: catCoinsInput,
      keychain: keychain,
      changePuzzlehash: changePuzzlehash,
      standardCoinsForFee: standardCoinsForFee,
      coinAnnouncementsToAssert: coinAnnouncementsToAssert,
      puzzleAnnouncementsToAssert: puzzleAnnouncementsToAssert,
      fee: fee,
      unsigned: unsigned,
    );
  }
}

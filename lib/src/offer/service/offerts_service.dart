import 'package:chia_crypto_utils/src/cat/index.dart';
import 'package:chia_crypto_utils/src/core/service/base_wallet.dart';

import '../../../chia_crypto_utils.dart';

class OffertsService extends BaseWalletService {
  final catWallet = CatWalletService();
  final standardWalletService = StandardWalletService();
}

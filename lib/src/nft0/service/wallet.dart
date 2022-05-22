import '../../context/index.dart';
import '../../core/service/base_wallet.dart';
import '../../standard/index.dart';

class Nft0WalletService extends BaseWalletService {
  late StandardWalletService standardWalletService;

  Nft0WalletService(Context context) : super(context) {
    standardWalletService = StandardWalletService(context);
  }
}

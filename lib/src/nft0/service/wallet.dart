import '../../../chia_crypto_utils.dart';
import '../../core/service/base_wallet.dart';
import '../../singleton/index.dart';

class Nft0WalletService extends BaseWalletService {
  Program createFullpuzzle(Program innerpuz, Bytes genesisId) {
    final modHash = singletonTopLayerProgram.hash();
    final singletonStruct = Program.list(
      [
        Program.fromBytes(modHash),
        Program.fromBytes(genesisId),
        Program.fromBytes(singletonLauncherProgram.hash())
      ],
    );
    return singletonTopLayerProgram.curry([
      singletonStruct,
      innerpuz,
    ]);
  }
}

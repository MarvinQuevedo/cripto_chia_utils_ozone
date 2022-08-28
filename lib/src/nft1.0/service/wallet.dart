import '../../../chia_crypto_utils.dart';
import '../../core/service/base_wallet.dart';
export '../models/index.dart';

class Nft0WalletService extends BaseWalletService {
  final standardWalletService = StandardWalletService();

  Program createFullpuzzle(Program innerpuz, Bytes genesisId) {
    final modHash = singletonTopLayerV1_1Program.hash();
    final singletonStruct = Program.list(
      [
        Program.fromBytes(modHash),
        Program.fromBytes(genesisId),
        Program.fromBytes(singletonLauncherProgram.hash())
      ],
    );
    return singletonTopLayerV1_1Program.curry([
      singletonStruct,
      innerpuz,
    ]);
  }
}

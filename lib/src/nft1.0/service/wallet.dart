import '../../../chia_crypto_utils.dart';
export '../models/index.dart';

class NftWalletService extends BaseWalletService {
  final standardWalletService = StandardWalletService();

  static Program createFullpuzzle(Program innerpuz, Bytes genesisId) {
    final modHash = SINGLETON_TOP_LAYER_MOD_v1_1.hash();
    final singletonStruct = Program.list(
      [
        Program.fromBytes(modHash),
        Program.fromBytes(genesisId),
        Program.fromBytes(singletonLauncherProgram.hash())
      ],
    );
    return SINGLETON_TOP_LAYER_MOD_v1_1.curry([
      singletonStruct,
      innerpuz,
    ]);
  }
}

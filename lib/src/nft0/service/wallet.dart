import 'package:chia_utils/src/nft0/puzzles/singleton_launcher/singleton_launcher.clvm.hex.dart';
import 'package:chia_utils/src/nft0/puzzles/singleton_top_layer_v1_1/singleton_top_layer_v1_1.clvm.hex.dart';

import '../../../chia_crypto_utils.dart';
import '../../core/service/base_wallet.dart';

class Nft0WalletService extends BaseWalletService {
  late StandardWalletService standardWalletService;

  Nft0WalletService(Context context) : super(context) {
    standardWalletService = StandardWalletService(context);
  }

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

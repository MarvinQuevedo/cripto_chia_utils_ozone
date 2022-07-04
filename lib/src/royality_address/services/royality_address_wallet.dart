import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/core/service/base_wallet.dart';

import '../puzzles/skynft.clsp.hex.dart';
export '../puzzles/skynft.clsp.hex.dart';

class RoyalityAddressWallet extends BaseWalletService {
  final StandardWalletService standardWallet = StandardWalletService();

  Program makeUserRoyaltyAddressBaseOnSkyNft({
    required Address customerAddress,
    required int royalityPercentage,
    Puzzlehash? platformPuzzlehash,
  }) {
    final firstPuzzleHash = customerAddress.toPuzzlehash();
    final platformPH = platformPuzzlehash ??
        Puzzlehash.fromHex("32660603960cc5b5b16fe4a5e7300ca858c4e625e08ac1d3dd476fb811dd670b");

    final royalityPuzzle = skyNftProgram.curry([
      Program.fromBytes(firstPuzzleHash),
      Program.fromBytes(platformPH),
      Program.fromInt(royalityPercentage),
    ]);
    return royalityPuzzle;
  }
}

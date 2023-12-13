// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:tuple/tuple.dart';

class TangemStandardWalletService extends StandardWalletService {
  @override
  Tuple2<SpendBundle, SignatureHashes?> createSpendBundle({
    required List<Payment> payments,
    required List<CoinPrototype> coinsInput,
    required WalletKeychain keychain,
    Puzzlehash? changePuzzlehash,
    int fee = 0,
    Bytes? originId,
    List<AssertCoinAnnouncementCondition> coinAnnouncementsToAssert = const [],
    List<AssertPuzzleCondition> puzzleAnnouncementsToAssert = const [],
    bool unsigned = true,
    MakePuzzleRevealFromPuzzleHash? makePuzzleRevealFromPuzzlehash,
  }) {
    return super.createSpendBundle(
      payments: payments,
      coinsInput: coinsInput,
      keychain: keychain,
      changePuzzlehash: changePuzzlehash,
      coinAnnouncementsToAssert: coinAnnouncementsToAssert,
      fee: fee,
      originId: originId,
      puzzleAnnouncementsToAssert: puzzleAnnouncementsToAssert,
      unsigned: true,
      makePuzzleRevealFromPuzzlehash: (puzzleHash) {
        final walletVector = keychain.getWalletVector(puzzleHash);
        final publicKey = walletVector!.childPublicKey;
        return puzzleForPk(publicKey);
      },
    );
  }

  @override
  Program getPuzzleFromPublicKey(JacobianPoint publicKey) {
    return puzzleForPk(publicKey);
  }
}

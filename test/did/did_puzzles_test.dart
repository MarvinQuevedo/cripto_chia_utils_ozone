import 'dart:typed_data';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/test.dart';

const spectedhash = "4b947248305a330e68357e73d84881400c26bd8ff2310173ec428a92f5ac3d45";
Future<void> main() async {
  final masterSk =
      PrivateKey.fromHex("0befcabff4a664461cc8f190cdd51c05621eb2837c71a1362df5b465a674ecfb");
  test('Parse Offer', () async {
    final pubKey = masterSkToWalletSk(masterSk, 0).getG1();
    final puzzle = getPuzzleFromPk(pubKey);

    final coinNumber = 2252255444;
    final coinBytes = intToBytes(coinNumber, 32, Endian.big);

    final didPuzzle = createDidInnerpuz(
      launcherId: coinBytes,
      p2Puzzle: puzzle,
      numOfBackupIdsNeeded: 0,
      recoveryList: [],
    );
    print("did puzzle");
    print(didPuzzle.hash().toHex());
    expect(didPuzzle.hash().toHex(), spectedhash);
  });
}

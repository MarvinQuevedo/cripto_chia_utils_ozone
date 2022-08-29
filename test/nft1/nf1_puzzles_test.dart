import 'dart:typed_data';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/nft1.0/service/metadata_outer_puzzle.dart';
import 'package:test/test.dart';

const spectedMetadataPuzzleHash =
    "7cbad8199fc4f5cb6f44c88de7ca20c07be7a28c09b11ff9da4bb9988c09a945";
const spectedFullhash = "c8109361adf2cd32c07587312052ddbc8bf61eb4644fd6351e1cf1f814f272fb";
const solutionProgramHash = "0a8c55bdb3469e3cefbc32f44e0eb94bb9cc79b0b233f9446226d550c463cb01";
Future<void> main() async {
  final masterSk =
      PrivateKey.fromHex("0befcabff4a664461cc8f190cdd51c05621eb2837c71a1362df5b465a674ecfb");

  final pubKey = masterSkToWalletSk(masterSk, 0).getG1();

  final puzzle = getPuzzleFromPk(pubKey);

  test('Metadata Layer puzzle', () async {
    final metadata = Program.list([]);
    final updaterHash = metadata.hash();

    final puzzleMetadataLayer = puzzleForMetadataLayer(
      innerPuzzle: puzzle,
      metadata: metadata,
      updaterHash: updaterHash,
    );
    print("puzzleMetadataLayer");
    expect(puzzleMetadataLayer.hash().toHex(), spectedMetadataPuzzleHash);

    final solutionProgram = solutionForMetadataLayer(amount: 125, innerSolution: Program.list([]));
    print("soutionForMetadataLayerProgram");
    expect(solutionProgram.hash().toHex(), solutionProgramHash);
  });
}

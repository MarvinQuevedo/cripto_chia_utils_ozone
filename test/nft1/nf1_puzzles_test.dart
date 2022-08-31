import 'dart:typed_data';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/clvm/parser.dart';
import 'package:chia_crypto_utils/src/nft1.0/service/metadata_outer_puzzle.dart';
import 'package:chia_crypto_utils/src/nft1.0/service/ownership_outer_puzzle.dart';
import 'package:test/test.dart';

const spectedMetadataPuzzleHash =
    "7cbad8199fc4f5cb6f44c88de7ca20c07be7a28c09b11ff9da4bb9988c09a945";
const spectedPuzzleForOwnershipLayerHash =
    "f5fb52927eaef26e4b5977dcb8574b5fed24d99ce2af8b7dccf679125cfc8b6a";
const spectedFullhash = "c8109361adf2cd32c07587312052ddbc8bf61eb4644fd6351e1cf1f814f272fb";
const solutionProgramHash = "0a8c55bdb3469e3cefbc32f44e0eb94bb9cc79b0b233f9446226d550c463cb01";
const solutionOwterProgramHash = "8238fa19e27bb63cf6663356aeb04847bf7b79158b799b8c329493f46ce6c5a6";
Future<void> main() async {
  final masterSk =
      PrivateKey.fromHex("0befcabff4a664461cc8f190cdd51c05621eb2837c71a1362df5b465a674ecfb");

  final pubKey = masterSkToWalletSk(masterSk, 0).getG1();

  final puzzle = getPuzzleFromPk(pubKey);
  final puzzleHash = puzzle.hash();

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

  test('Ownership Layer puzzle', () async {
    final _puzzleForOwnershipLayer = puzzleForOwnershipLayer(
      innerPuzzle: puzzle,
      currentOwner: puzzleHash,
      transferProgram: Program.list([]),
    );
    print("_puzzleForOwnershipLayer");
    expect(_puzzleForOwnershipLayer.hash().toHex(), spectedPuzzleForOwnershipLayerHash);

    final solutionProgram = solutionForOwnershipLayer(innerSolution: puzzle);
    print("ownerSolution");
    expect(solutionProgram.hash().toHex(), solutionOwterProgramHash);
  });

  test('Program At rrf', () async {
    final p1 = Program.list([
      Program.fromInt(10),
      Program.fromInt(20),
      Program.fromInt(30),
      Program.list([Program.fromInt(15), Program.fromInt(17)]),
      Program.fromInt(40),
      Program.fromInt(50)
    ]);
    final p2 = Program.list([
      Program.fromInt(20),
      Program.fromInt(30),
      Program.list([Program.fromInt(15), Program.fromInt(17)]),
      Program.fromInt(40),
      Program.fromInt(50)
    ]);
    final p22 = Program.deserialize(p1.serialize());
    print("Original");
    print(p1);

    print("Expected");
    print(p2);

    print("Result");

    print(p22.filterAt("r"));
    expect(p2, p22.filterAt("r"));
    expect(
        Program.fromInt(17),
        Program.list([
          Program.fromInt(10),
          Program.fromInt(20),
          Program.fromInt(30),
          Program.list([Program.fromInt(15), Program.fromInt(17)]),
          Program.fromInt(40),
          Program.fromInt(50)
        ]).filterAt("rrrfrf"));
  });
}

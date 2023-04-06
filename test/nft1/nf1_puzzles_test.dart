import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/nft1.0/index.dart';

import 'package:test/test.dart';

const spectedMetadataPuzzleHash =
    "7cbad8199fc4f5cb6f44c88de7ca20c07be7a28c09b11ff9da4bb9988c09a945";
const spectedPuzzleForOwnershipLayerHash =
    "f5fb52927eaef26e4b5977dcb8574b5fed24d99ce2af8b7dccf679125cfc8b6a";
const spectedPuzzleForTransferHash =
    "e9e755532f80627d5aeed8bc49fa4335bc8f4d409d16bf29dc4e68859a398684";
const spectedFullhash = "c8109361adf2cd32c07587312052ddbc8bf61eb4644fd6351e1cf1f814f272fb";
const solutionProgramHash = "0a8c55bdb3469e3cefbc32f44e0eb94bb9cc79b0b233f9446226d550c463cb01";
const solutionSingletonHash = "6f3366dde8f47e162b79cf95444158f44cdb5342e678f6df8277815c80c854d4";
const solutionSingletonHash2 = "0926ea4d51965585194d8eee5693c65e384ae3820a88e6e644526f1ed0087c6c";
const solutionOwterProgramHash = "8238fa19e27bb63cf6663356aeb04847bf7b79158b799b8c329493f46ce6c5a6";
const ownershipLayerTransferSolutionHash =
    "b8e85e13914851c8969030ced4dd64d4f2967dd2b6e70804523ae0d8d1f0e093";

Future<void> main() async {
  final masterSk =
      PrivateKey.fromHex("0befcabff4a664461cc8f190cdd51c05621eb2837c71a1362df5b465a674ecfb");

  final pubKey = masterSkToWalletSk(masterSk, 0).getG1();

  final puzzle = getPuzzleFromPk(pubKey);
  final puzzleHash = puzzle.hash();
  final parentName =
      Bytes.fromHex("7cbad8199fc4f5cb6f44c88de7ca20c07be7a28c09b11ff9da4bb9988c09a945");

  test('Metadata Layer puzzle', () async {
    final metadata = Program.list([]);
    final updaterHash = metadata.hash();

    final puzzleMetadataLayer = puzzleForMetadataLayer(
      innerPuzzle: puzzle,
      metadata: metadata,
      metadataUpdaterHash: updaterHash,
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

  test('Singleton Layer puzzle', () async {
    final solutionProgram1 = solutionForSingleton(
      innerSolution: Program.list([]),
      amount: 500,
      lineageProof: LineageProof(
        parentName: Puzzlehash(parentName),
        innerPuzzleHash: puzzleHash,
        amount: 502,
      ),
    );
    print("singletonSolution1");
    expect(solutionProgram1.hash().toHex(), solutionSingletonHash);

    final solutionProgram2 = solutionForSingleton(
      innerSolution: Program.list([]),
      amount: 500,
      lineageProof:
          LineageProof(parentName: Puzzlehash(parentName), amount: 502, innerPuzzleHash: null),
    );
    print("singletonSolution2");
    expect(solutionProgram2.hash().toHex(), solutionSingletonHash2);
  });

  test('Transfer Layer puzzle', () async {
    final _puzzleForTransferProgram =
        puzzleForTransferProgram(launcherId: puzzleHash, percentage: 5, royaltyAddress: puzzleHash);
    print("puzzleForTransferProgram");
    expect(_puzzleForTransferProgram.hash().toHex(), spectedPuzzleForTransferHash);

    final negativeProgram = Program.fromInt(-10);
    print("negativeProgram");
    print(negativeProgram);
  });
  test('OwnershipLayerTransferSolution', () async {
    final solution = NftService.createOwnershipLayerTransferSolution(
        newDid: puzzleHash,
        newDidInnerHash: puzzleHash,
        newPuzzleHash: puzzleHash,
        tradePricesList: [
          [105, 165]
        ]);
    print("puzzleForTransferProgram");
    expect(solution.hash().toHex(), ownershipLayerTransferSolutionHash);
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
    expect(Program.fromInt(0), Program.list([]));
  });
  final launcherId =
      Bytes.fromHex('c8109361adf2cd32c07587312052ddbc8bf61eb4644fd6351e1cf1f814f272fb');
  final eveFullPuz = NftService.createFullPuzzle(
    singletonId: launcherId,
    metadata: Program.list([]),
    metadataUpdaterHash: NFT_METADATA_UPDATER_HASH,
    innerPuzzle: Program.fromInt(1),
  );
  final announcementMessage = Program.list([
    Program.fromBytes(eveFullPuz.hash()),
    Program.fromInt(1),
    Program.list([]),
  ]).hash();
  final assertCoinAnnouncement = AssertCoinAnnouncementCondition(
    launcherId,
    announcementMessage,
  );
  print(assertCoinAnnouncement);

  final genesisLauncherSolution = Program.list([
    Program.fromBytes(eveFullPuz.hash()),
    Program.fromInt(1),
    Program.list([]),
  ]);
  print("genesisLauncherSolution");
  print(genesisLauncherSolution.hash());
  print("finish");
}

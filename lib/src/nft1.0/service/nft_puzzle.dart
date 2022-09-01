import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/core/service/base_wallet.dart';
import 'package:chia_crypto_utils/src/nft1.0/index.dart';
import 'package:chia_crypto_utils/src/standard/puzzles/p2_delegated_puzzle_or_hidden_puzzle/p2_delegated_puzzle_or_hidden_puzzle.clvm.hex.dart';

import '../../clvm.dart';
import '../../singleton/index.dart';

Program _parseValue(dynamic value) {
  Program? valueP;
  if (value is int) {
    valueP = Program.fromInt(value);
  } else if (value is String) {
    valueP = Program.fromString(value);
  } else if (value is Bytes) {
    valueP = Program.fromBytes(value);
  } else if (value is List) {
    final listValues = <Program>[];
    for (final item in value) {
      listValues.add(_parseValue(item));
    }
    valueP = Program.list(listValues);
  }
  if (valueP == null) {
    throw Exception("Can convert to metadata ${value}");
  }
  return valueP;
}

class NftService {
  static Program createNftLayerPuzzleWithCurryParams({
    required Program metadata,
    required Bytes metadataUpdaterHash,
    required Program innerPuzzle,
  }) {
    return puzzleForMetadataLayer(
      metadata: metadata,
      metadataUpdaterHash: metadataUpdaterHash,
      innerPuzzle: innerPuzzle,
    );
  }

  static Program createFullPuzzleWithNftPuzzle({
    required Bytes singletonId,
    required Program innerPuzzle,
  }) {
    return SingletonService.puzzleForSingleton(
      singletonId,
      innerPuzzle,
      launcherHash: LAUNCHER_PUZZLE_HASH,
    );
  }

  static Program createFullPuzzle(
      {required Bytes singletonId,
      required Program metadata,
      required Bytes metadataUpdaterHash,
      required Program innerPuzzle}) {
    final singletonStruct = Program.cons(
      Program.fromBytes(SINGLETON_MOD_HASH),
      Program.cons(
        Program.fromBytes(singletonId),
        Program.fromBytes(
          LAUNCHER_PUZZLE_HASH,
        ),
      ),
    );

    final sinletonInnerPuzzle = createNftLayerPuzzleWithCurryParams(
      metadata: metadata,
      metadataUpdaterHash: metadataUpdaterHash,
      innerPuzzle: innerPuzzle,
    );

    return SINGLETON_TOP_LAYER_MOD.curry([singletonStruct, sinletonInnerPuzzle]);
  }

  static NFTInfo getNftInfoFromPuzzle(NFTCoinInfo nftCoinInfo) {
    final uncurriedNft = UncurriedNFT.uncurry(nftCoinInfo.fullPuzzle);
    return NFTInfo.fromUncurried(
      uncurriedNFT: uncurriedNft,
      currentCoin: nftCoinInfo.coin,
      mintHeight: nftCoinInfo.mintHeight,
    );
  }

  ///  Convert the metadata dict to a Chialisp program
  static Program metadataToProgram(Map<Bytes, dynamic> metadata) {
    final programList = <Program>[];
    metadata.forEach((key, value) {
      Program? valueP = _parseValue(value);

      programList.add(Program.cons(
        Program.fromBytes(key),
        valueP,
      ));
    });
    return Program.list(programList);
  }

  /// Convert a program to a metadata dict, [program] Chialisp
  /// program contains the metadata return: Metadata dict
  static Map<Bytes, dynamic> programToMetadata(Program program) {
    final metadata = <Bytes, dynamic>{};
    for (var con in program.toList()) {
      metadata[con.first().atom] = con.rest().atom;
    }
    return metadata;
  }

  /// Prepend a value to a list in the metadata
  static void prependValue(
      {required Map<Bytes, dynamic> metadata, required Program value, required Bytes key}) {
    if (value == Program.list([])) return;

    if ((metadata[key] as List?)?.isEmpty ?? true) {
      metadata[key] = [value.atom];
    } else {
      (metadata[key] as List).insert(0, value.atom);
    }
  }

  /// Apply conditions of metadata updater to the previous metadata
  static Program updateMetadata({required Program metadata, required Program updateCondition}) {
    final newMetadata = programToMetadata(metadata);
    final uri = updateCondition.rest().rest().first();
    prependValue(metadata: newMetadata, value: uri.first(), key: uri.rest().atom);
    return metadataToProgram(newMetadata);
  }

  static Program constructOwnershipLayer(
          {required currentOwner,
          required Program transferProgram,
          required Program innerPuzzle}) =>
      puzzleForOwnershipLayer(
        currentOwner: currentOwner,
        transferProgram: transferProgram,
        innerPuzzle: innerPuzzle,
      );

  static Program createOwnwershipLayerPuzzle({
    required Bytes nftId,
    required Bytes? didId,
    required Program p2Puzzle,
    required int percentage,
    Puzzlehash? royaltyPuzzleHash,
  }) {
    final singletonStruct = Program.cons(
      Program.fromBytes(SINGLETON_MOD_HASH),
      Program.cons(
        Program.fromBytes(nftId),
        Program.fromBytes(
          LAUNCHER_PUZZLE_HASH,
        ),
      ),
    );
    if (royaltyPuzzleHash == null) {
      royaltyPuzzleHash = p2Puzzle.hash();
    }

    final transferProgram = NFT_STATE_LAYER_MOD.curry([
      singletonStruct,
      Program.fromBytes(royaltyPuzzleHash),
      Program.fromInt(percentage),
    ]);

    final nftInnerPuzzle = p2Puzzle;
    final nftOwnershipLayerPuzzle = constructOwnershipLayer(
      currentOwner: didId,
      transferProgram: transferProgram,
      innerPuzzle: nftInnerPuzzle,
    );
    return nftOwnershipLayerPuzzle;
  }

  static Program createOwnershipLayerTransferSolution({
    required Bytes newDid,
    required Puzzlehash newDidInnerHash,
    required List<int> tradePricesList,
    required Puzzlehash newPuzzleHash,
  }) {
    final tradePricesListP = Program.list(
      tradePricesList.map((e) => Program.fromInt(e)).toList(),
    );
    final conditionList = Program.list([
      Program.list(
        [
          Program.fromInt(51),
          Program.fromBytes(newPuzzleHash),
          Program.fromInt(1),
          Program.list([
            Program.fromBytes(newPuzzleHash),
          ]),
        ],
      ),
      Program.list([
        Program.fromInt(-10),
        Program.fromBytes(newDid),
        tradePricesListP,
        Program.fromBytes(newDidInnerHash),
      ])
    ]);
    final solution = Program.list(
      [
        Program.list(
          [
            solutionForConditions(conditionList),
          ],
        ),
      ],
    );
    return solution;
  }
}

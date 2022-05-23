import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:chia_utils/src/nft0/puzzles/nft_state_layer/nft_state_layer.clvm.hex.dart';
import 'package:chia_utils/src/nft0/puzzles/singleton_top_layer_v1_1/singleton_top_layer_v1_1.clvm.hex.dart';

import '../../clvm/keywords.dart';

/// A simple solution for uncurry NFT puzzle.

class UncurriedNFT {
  /// Initial the class with a full NFT puzzle, it will do a deep uncurry.
  /// This is the only place you need to change after modified the Chialisp curried parameters.

  final Program nftModHash;

  /// NFT module hash

  final Program nftStateLayer;

  /// NFT state layer puzzle
  final Program singletonStruct;

  ///  Singleton struct
  /// [singleton_mod_hash, singleton_launcher_id, launcher_puzhash]
  final Program singletonModHash;
  final Program singletonLauncherId;
  final Program launcherPuzhash;

  /// Owner's DID
  final Program ownerDid;

  /// Metadata updater puzzle hash
  final Program metadataUpdaterHash;

  /// Puzzle hash of the transfer program
  final Program transferProgramHash;

  /// Curried parameters of the transfer program
  /// [royalty_address, trade_price_percentage, settlement_mod_hash, cat_mod_hash]
  final Program transferProgramCurryParams;
  final Program royaltyAddress;
  final Program tradePricePercentage;
  final Program settlementModHash;
  final Program catModHash;

  final Program metadata;

  ///  NFT metadata
  /// [("u", data_uris), ("h", data_hash)]
  final Program dataUris;
  final Program dataHash;

  ///  NFT state layer inner puzzle
  final Program innerPuzzle;

  UncurriedNFT._({
    required this.nftModHash,
    required this.nftStateLayer,
    required this.singletonStruct,
    required this.singletonModHash,
    required this.singletonLauncherId,
    required this.launcherPuzhash,
    required this.ownerDid,
    required this.metadataUpdaterHash,
    required this.transferProgramHash,
    required this.transferProgramCurryParams,
    required this.royaltyAddress,
    required this.tradePricePercentage,
    required this.settlementModHash,
    required this.catModHash,
    required this.metadata,
    required this.dataUris,
    required this.dataHash,
    required this.innerPuzzle,
  });

  static UncurriedNFT uncurry(Program puzzle) {
    late Program singletonStruct;
    late Program nftStateLayer;
    late Program sinletonModHash;
    late Program singletonLauncherId;
    late Program launcherPuzzhash;
    late Program dataUris;
    late Program dataHash;

    final uncurried = puzzle.uncurry();
    final mod = uncurried.program;
    final curried_args = uncurried.arguments;
    if (mod.toSource() != singletonTopLayerProgram.toSource()) {
      throw ArgumentError(
          "Cannot uncurry NFT puzzle, failed on singleton top layer: Mod ${mod}");
    }
    try {
      singletonStruct = curried_args[0];
      nftStateLayer = curried_args[1];
      sinletonModHash = singletonStruct.first();
      singletonLauncherId = singletonStruct.rest().first();
      launcherPuzzhash = singletonStruct.rest().rest();
    } catch (e) {
      throw ArgumentError(
          "Cannot uncurry singleton top layer: Args ${curried_args}");
    }

    //TODO [curried_args] maybe would be has the method [rest], but not found, is posible the solution if corect

    final uncurriedNft = curried_args[1].first().uncurry();
    final nftMod = uncurriedNft.program;
    final nftArgs = uncurriedNft.arguments;
    if (nftMod.toSource() != nftStateLayerProgram.toSource()) {
      throw ArgumentError(
          "Cannot uncurry NFT puzzle, failed on NFT state layer: Mod ${mod}");
    }
    try {
      final nftModHash = nftArgs[0];
      final metadata = nftArgs[1];
      final metadataUpdaterHash = nftArgs[2];
      final innerPuzzleHash = nftArgs[3];

      for (var kvPair in metadata.toList()) {
        if (bytesEqual(kvPair.first().atom, encodeBigInt(keywords['u']!))) {
          dataUris = kvPair.rest();
        }
        if (bytesEqual(kvPair.first().atom, encodeBigInt(keywords['h']!))) {
          dataHash = kvPair.rest();
        }
      }
      return UncurriedNFT._(
        nftModHash: nftModHash,
        nftStateLayer: nftStateLayer,
        singletonStruct: singletonStruct,
        singletonModHash: sinletonModHash,
        singletonLauncherId: singletonLauncherId,
        launcherPuzhash: launcherPuzzhash,
        metadata: metadata,
        dataUris: dataUris,
        dataHash: dataHash,
        innerPuzzle: innerPuzzleHash,
        metadataUpdaterHash: metadataUpdaterHash,

        // TODO Set/Remove following fields after NFT1 implemented

        ownerDid: Program.fromBytes([]),
        transferProgramHash: Program.fromBytes([]),
        transferProgramCurryParams: Program.fromBytes([]),
        royaltyAddress: Program.fromBytes([]),
        tradePricePercentage: Program.fromBytes([]),
        settlementModHash: Program.fromBytes([]),
        catModHash: Program.fromBytes([]),
      );
    } catch (e) {
      throw Exception("Cannot uncurry NFT state layer: Args ${curried_args}");
    }
  }

  UncurriedNFT copyWith({
    Program? nftModHash,
    Program? nftStateLayer,
    Program? singletonStruct,
    Program? singletonModHash,
    Program? singletonLauncherId,
    Program? launcherPuzhash,
    Program? ownerDid,
    Program? metadataUpdaterHash,
    Program? transferProgramHash,
    Program? transferProgramCurryParams,
    Program? royaltyAddress,
    Program? tradePricePercentage,
    Program? settlementModHash,
    Program? catModHash,
    Program? metadata,
    Program? dataUris,
    Program? dataHash,
    Program? innerPuzzle,
  }) {
    return UncurriedNFT._(
      nftModHash: nftModHash ?? this.nftModHash,
      nftStateLayer: nftStateLayer ?? this.nftStateLayer,
      singletonStruct: singletonStruct ?? this.singletonStruct,
      singletonModHash: singletonModHash ?? this.singletonModHash,
      singletonLauncherId: singletonLauncherId ?? this.singletonLauncherId,
      launcherPuzhash: launcherPuzhash ?? this.launcherPuzhash,
      ownerDid: ownerDid ?? this.ownerDid,
      metadataUpdaterHash: metadataUpdaterHash ?? this.metadataUpdaterHash,
      transferProgramHash: transferProgramHash ?? this.transferProgramHash,
      transferProgramCurryParams:
          transferProgramCurryParams ?? this.transferProgramCurryParams,
      royaltyAddress: royaltyAddress ?? this.royaltyAddress,
      tradePricePercentage: tradePricePercentage ?? this.tradePricePercentage,
      settlementModHash: settlementModHash ?? this.settlementModHash,
      catModHash: catModHash ?? this.catModHash,
      metadata: metadata ?? this.metadata,
      dataUris: dataUris ?? this.dataUris,
      dataHash: dataHash ?? this.dataHash,
      innerPuzzle: innerPuzzle ?? this.innerPuzzle,
    );
  }
}

import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:chia_utils/src/nft0/puzzles/nft_state_layer/nft_state_layer.clvm.hex.dart';
import 'package:chia_utils/src/nft0/puzzles/singleton_top_layer_v1_1/singleton_top_layer_v1_1.clvm.hex.dart';

import '../../clvm/keywords.dart';

/// A simple solution for uncurry NFT puzzle.

class UncurriedNFT {
  /// Initial the class with a full NFT puzzle, it will do a deep uncurry.
  /// This is the only place you need to change after modified the Chialisp curried parameters.

  final Program nft_mod_hash;

  /// NFT module hash

  final Program nft_state_layer;

  /// NFT state layer puzzle
  final Program singleton_struct;

  ///  Singleton struct
  /// [singleton_mod_hash, singleton_launcher_id, launcher_puzhash]
  final Program singleton_mod_hash;
  final Program singleton_launcher_id;
  final Program launcher_puzhash;

  /// Owner's DID
  final Program owner_did;

  /// Metadata updater puzzle hash
  final Program metadataUpdaterHash;

  /// Puzzle hash of the transfer program
  final Program transfer_program_hash;

  /// Curried parameters of the transfer program
  /// [royalty_address, trade_price_percentage, settlement_mod_hash, cat_mod_hash]
  final Program transfer_program_curry_params;
  final Program royalty_address;
  final Program trade_price_percentage;
  final Program settlement_mod_hash;
  final Program cat_mod_hash;

  final Program metadata;

  ///  NFT metadata
  /// [("u", data_uris), ("h", data_hash)]
  final Program data_uris;
  final Program data_hash;

  ///  NFT state layer inner puzzle
  final Program inner_puzzle;

  UncurriedNFT._({
    required this.nft_mod_hash,
    required this.nft_state_layer,
    required this.singleton_struct,
    required this.singleton_mod_hash,
    required this.singleton_launcher_id,
    required this.launcher_puzhash,
    required this.owner_did,
    required this.metadataUpdaterHash,
    required this.transfer_program_hash,
    required this.transfer_program_curry_params,
    required this.royalty_address,
    required this.trade_price_percentage,
    required this.settlement_mod_hash,
    required this.cat_mod_hash,
    required this.metadata,
    required this.data_uris,
    required this.data_hash,
    required this.inner_puzzle,
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
        nft_mod_hash: nftModHash,
        nft_state_layer: nftStateLayer,
        singleton_struct: singletonStruct,
        singleton_mod_hash: sinletonModHash,
        singleton_launcher_id: singletonLauncherId,
        launcher_puzhash: launcherPuzzhash,
        metadata: metadata,
        data_uris: dataUris,
        data_hash: dataHash,
        inner_puzzle: innerPuzzleHash,
        metadataUpdaterHash: metadataUpdaterHash,

        // TODO Set/Remove following fields after NFT1 implemented

        owner_did: Program.fromBytes([]),

        transfer_program_hash: Program.fromBytes([]),
        transfer_program_curry_params: Program.fromBytes([]),
        royalty_address: Program.fromBytes([]),
        trade_price_percentage: Program.fromBytes([]),
        settlement_mod_hash: Program.fromBytes([]),
        cat_mod_hash: Program.fromBytes([]),
      );
    } catch (e) {
      throw Exception("Cannot uncurry NFT state layer: Args ${curried_args}");
    }
  }

  UncurriedNFT copyWith({
    Program? nft_mod_hash,
    Program? nft_state_layer,
    Program? singleton_struct,
    Program? singleton_mod_hash,
    Program? singleton_launcher_id,
    Program? launcher_puzhash,
    Program? owner_did,
    Program? metadataUpdaterHash,
    Program? transfer_program_hash,
    Program? transfer_program_curry_params,
    Program? royalty_address,
    Program? trade_price_percentage,
    Program? settlement_mod_hash,
    Program? cat_mod_hash,
    Program? metadata,
    Program? data_uris,
    Program? data_hash,
    Program? inner_puzzle,
  }) {
    return UncurriedNFT._(
      nft_mod_hash: nft_mod_hash ?? this.nft_mod_hash,
      nft_state_layer: nft_state_layer ?? this.nft_state_layer,
      singleton_struct: singleton_struct ?? this.singleton_struct,
      singleton_mod_hash: singleton_mod_hash ?? this.singleton_mod_hash,
      singleton_launcher_id:
          singleton_launcher_id ?? this.singleton_launcher_id,
      launcher_puzhash: launcher_puzhash ?? this.launcher_puzhash,
      owner_did: owner_did ?? this.owner_did,
      metadataUpdaterHash: metadataUpdaterHash ?? this.metadataUpdaterHash,
      transfer_program_hash:
          transfer_program_hash ?? this.transfer_program_hash,
      transfer_program_curry_params:
          transfer_program_curry_params ?? this.transfer_program_curry_params,
      royalty_address: royalty_address ?? this.royalty_address,
      trade_price_percentage:
          trade_price_percentage ?? this.trade_price_percentage,
      cat_mod_hash: cat_mod_hash ?? this.cat_mod_hash,
      settlement_mod_hash: settlement_mod_hash ?? this.settlement_mod_hash,
      metadata: metadata ?? this.metadata,
      data_uris: data_uris ?? this.data_uris,
      data_hash: data_hash ?? this.data_hash,
      inner_puzzle: inner_puzzle ?? this.inner_puzzle,
    );
  }
}

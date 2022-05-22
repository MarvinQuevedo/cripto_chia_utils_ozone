import 'package:chia_utils/chia_crypto_utils.dart';

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
  final Program metdata_updater_hash;

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

  UncurriedNFT({
    required this.nft_mod_hash,
    required this.nft_state_layer,
    required this.singleton_struct,
    required this.singleton_mod_hash,
    required this.singleton_launcher_id,
    required this.launcher_puzhash,
    required this.owner_did,
    required this.metdata_updater_hash,
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

  UncurriedNFT copyWith({
    Program? nft_mod_hash,
    Program? nft_state_layer,
    Program? singleton_struct,
    Program? singleton_mod_hash,
    Program? singleton_launcher_id,
    Program? launcher_puzhash,
    Program? owner_did,
    Program? metdata_updater_hash,
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
    return UncurriedNFT(
      nft_mod_hash: nft_mod_hash ?? this.nft_mod_hash,
      nft_state_layer: nft_state_layer ?? this.nft_state_layer,
      singleton_struct: singleton_struct ?? this.singleton_struct,
      singleton_mod_hash: singleton_mod_hash ?? this.singleton_mod_hash,
      singleton_launcher_id:
          singleton_launcher_id ?? this.singleton_launcher_id,
      launcher_puzhash: launcher_puzhash ?? this.launcher_puzhash,
      owner_did: owner_did ?? this.owner_did,
      metdata_updater_hash: metdata_updater_hash ?? this.metdata_updater_hash,
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

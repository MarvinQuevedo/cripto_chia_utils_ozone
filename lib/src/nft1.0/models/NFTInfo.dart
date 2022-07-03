import 'package:meta/meta.dart';

import '../../../chia_crypto_utils.dart';

/// NFT Info for displaying NFT on the UI
class NFTInfo {
  /// Launcher coin ID
  final Bytes launcherId;

  /// Current NFT coin ID
  final Bytes nftCoinId;

  /// Owner DID
  final Bytes? didOwner;

  /// Percentage of the transaction fee paid to the author, e.g. 1000 = 1%
  final int? royaltyPercentage;

  /// Puzzle hash where royalty will be sent to
  final Bytes? royaltyPuzzlehash;

  /// A list of content URIs
  final List<String> dataUris;

  /// Hash of the content
  final String dataHash;

  /// A list of metadata URIs
  final List<String> metadataUris;

  /// Hash of the metadata
  final String metadataHash;

  /// A list of license URIs
  final List<String> licenseUris;

  /// Hash of the license
  final String licenseHash;

  /// How many NFTs in the current series
  final String seriesTotal;

  /// Number of the current NFT in the series
  final int seriesNumber;

  final Bytes updaterPuzzlehash;

  /// Information saved on the chain in hex
  final String chainInfo;

  /// Block height of the NFT minting
  final int mintHeight;

  /// If the inner puzzle supports DID
  final bool supportsDid;

  final bool pendingTransaction;

  final launcherPuzzlehash = singletonLauncherProgram.hash;

  NFTInfo(
      {required this.launcherId,
      required this.nftCoinId,
      required this.didOwner,
      required this.royaltyPercentage,
      required this.dataUris,
      required this.metadataUris,
      required this.licenseUris,
      required this.dataHash,
      required this.metadataHash,
      required this.licenseHash,
      required this.chainInfo,
      required this.mintHeight,
      required this.pendingTransaction,
      required this.royaltyPuzzlehash,
      required this.seriesNumber,
      required this.seriesTotal,
      required this.updaterPuzzlehash,
      required this.supportsDid});

  factory NFTInfo.fromJson(Map<String, dynamic> json) {
    return NFTInfo(
        launcherId: Bytes.fromHex(json['launcher_id'] as String),
        nftCoinId: Bytes.fromHex(json['nft_coin_id'] as String),
        didOwner: Bytes.fromHex(json['did_owner'] as String),
        royaltyPercentage: json['royalty'] as int,
        dataUris: List<String>.from(json['data_uris'] as List),
        dataHash: json['data_hash'] as String,
        metadataUris: List<String>.from(json['metadata_uris'] as List),
        metadataHash: json['metadata_hash'] as String,
        licenseUris: List<String>.from(json['license_uris'] as List),
        licenseHash: json['license_hash'] as String,
        chainInfo: json["chain_info"] as String,
        mintHeight: json["mint_height"],
        pendingTransaction: json["pending_transaction"],
        royaltyPuzzlehash:
            json["royalty_puzzle_hash"] != null ? Bytes.fromHex(json["royalty_puzzle_hash"]) : null,
        seriesNumber: json['series_number'],
        seriesTotal: json["series_total"],
        supportsDid: json["supports_did"],
        updaterPuzzlehash: Bytes.fromHex(json['updater_puzhash']));
  }

  Map<String, dynamic> toMap() {
    return {
      'launcher_id': launcherId.toHex(),
      'nft_coin_id': nftCoinId.toHex(),
      'did_owner': didOwner?.toHex(),
      'royalty': royaltyPercentage,
      'data_uris': dataUris,
      'data_hash': dataHash,
      'metadata_uris': metadataUris,
      'metadata_hash': metadataHash,
      'license_uris': licenseUris,
      'license_hash': licenseHash,
      "chain_info": chainInfo,
      'mint_height': mintHeight,
      'pending_transaction': pendingTransaction,
      'royalty_puzzle_hash': royaltyPuzzlehash,
      "series_number": seriesNumber,
      "series_total": seriesTotal,
      "supports_did": supportsDid
    };
  }
}

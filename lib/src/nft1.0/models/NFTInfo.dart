import '../../../chia_crypto_utils.dart';

/// NFT Info for displaying NFT on the UI
class NFTInfo {
  /// Launcher coin ID
  final Bytes launcherId;

  /// Current NFT coin ID
  final Bytes nftCoinId;

  /// Owner DID
  final Bytes didOwner;

  /// Percentage of the transaction fee paid to the author, e.g. 1000 = 1%
  final int royalty;

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

  /// Current NFT version
  final String version;

  /// How many NFTs in the current series
  final int editionCount;

  /// Number of the current NFT in the series"
  final int editionNumber;

  NFTInfo({
    required this.launcherId,
    required this.nftCoinId,
    required this.didOwner,
    required this.royalty,
    required this.dataUris,
    required this.metadataUris,
    required this.licenseUris,
    required this.dataHash,
    required this.metadataHash,
    required this.licenseHash,
    required this.version,
    required this.editionCount,
    required this.editionNumber,
  });

  factory NFTInfo.fromJson(Map<String, dynamic> json) {
    return NFTInfo(
      launcherId: Bytes.fromHex(json['launcher_id'] as String),
      nftCoinId: Bytes.fromHex(json['nft_coin_id'] as String),
      didOwner: Bytes.fromHex(json['did_owner'] as String),
      royalty: json['royalty'] as int,
      dataUris: List<String>.from(json['data_uris'] as List),
      dataHash: json['data_hash'] as String,
      metadataUris: List<String>.from(json['metadata_uris'] as List),
      metadataHash: json['metadata_hash'] as String,
      licenseUris: List<String>.from(json['license_uris'] as List),
      licenseHash: json['license_hash'] as String,
      version: json['version'] as String,
      editionCount: json['edition_count'] as int,
      editionNumber: json['edition_number'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'launcher_id': launcherId.toHex(),
      'nft_coin_id': nftCoinId.toHex(),
      'did_owner': didOwner.toHex(),
      'royalty': royalty,
      'data_uris': dataUris,
      'data_hash': dataHash,
      'metadata_uris': metadataUris,
      'metadata_hash': metadataHash,
      'license_uris': licenseUris,
      'license_hash': licenseHash,
      'version': version,
      'edition_count': editionCount,
      'edition_number': editionNumber,
    };
  }

  NFTInfo copyWith({
    Bytes? launcherId,
    Bytes? nftCoinId,
    Bytes? didOwner,
    int? royalty,
    List<String>? dataUris,
    String? dataHash,
    List<String>? metadataUris,
    String? metadataHash,
    List<String>? licenseUris,
    String? licenseHash,
    String? version,
    int? editionCount,
    int? editionNumber,
  }) {
    return NFTInfo(
      launcherId: launcherId ?? this.launcherId,
      nftCoinId: nftCoinId ?? this.nftCoinId,
      didOwner: didOwner ?? this.didOwner,
      royalty: royalty ?? this.royalty,
      dataUris: dataUris ?? this.dataUris,
      dataHash: dataHash ?? this.dataHash,
      metadataUris: metadataUris ?? this.metadataUris,
      metadataHash: metadataHash ?? this.metadataHash,
      licenseUris: licenseUris ?? this.licenseUris,
      licenseHash: licenseHash ?? this.licenseHash,
      version: version ?? this.version,
      editionCount: editionCount ?? this.editionCount,
      editionNumber: editionNumber ?? this.editionNumber,
    );
  }
}

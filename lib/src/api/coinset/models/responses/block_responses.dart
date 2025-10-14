import 'package:chia_crypto_utils/chia_crypto_utils.dart';

/// Response from get_block endpoint
class GetBlockResponse {
  const GetBlockResponse({
    this.block,
    this.error,
    required this.success,
  });

  factory GetBlockResponse.fromJson(Map<String, dynamic> json) {
    return GetBlockResponse(
      block: json['block'] != null
          ? json['block'] as Map<String, dynamic> // Keep as dynamic for now
          : null,
      error: json['error'] as String?,
      success: json['success'] as bool,
    );
  }

  final Map<String, dynamic>? block; // FullBlock type - keeping as Map for simplicity
  final String? error;
  final bool success;

  Map<String, dynamic> toJson() => {
        if (block != null) 'block': block,
        if (error != null) 'error': error,
        'success': success,
      };
}

/// Response from get_block_record endpoint
class GetBlockRecordResponse {
  const GetBlockRecordResponse({
    this.blockRecord,
    this.error,
    required this.success,
  });

  factory GetBlockRecordResponse.fromJson(Map<String, dynamic> json) {
    return GetBlockRecordResponse(
      blockRecord: json['block_record'] != null
          ? json['block_record'] as Map<String, dynamic> // Keep as dynamic for now
          : null,
      error: json['error'] as String?,
      success: json['success'] as bool,
    );
  }

  final Map<String, dynamic>? blockRecord; // BlockRecord type
  final String? error;
  final bool success;

  Map<String, dynamic> toJson() => {
        if (blockRecord != null) 'block_record': blockRecord,
        if (error != null) 'error': error,
        'success': success,
      };
}

/// Response from get_block_record_by_height endpoint
typedef GetBlockRecordByHeightResponse = GetBlockRecordResponse;

/// Response from get_block_records endpoint
class GetBlockRecordsResponse {
  const GetBlockRecordsResponse({
    this.blockRecords,
    this.error,
    required this.success,
  });

  factory GetBlockRecordsResponse.fromJson(Map<String, dynamic> json) {
    return GetBlockRecordsResponse(
      blockRecords: json['block_records'] != null
          ? (json['block_records'] as List).map((e) => e as Map<String, dynamic>).toList()
          : null,
      error: json['error'] as String?,
      success: json['success'] as bool,
    );
  }

  final List<Map<String, dynamic>>? blockRecords; // List<BlockRecord>
  final String? error;
  final bool success;

  Map<String, dynamic> toJson() => {
        if (blockRecords != null) 'block_records': blockRecords,
        if (error != null) 'error': error,
        'success': success,
      };
}

/// Response from get_blocks endpoint
class GetBlocksResponse {
  const GetBlocksResponse({
    this.blocks,
    this.error,
    required this.success,
  });

  factory GetBlocksResponse.fromJson(Map<String, dynamic> json) {
    return GetBlocksResponse(
      blocks: json['blocks'] != null
          ? (json['blocks'] as List).map((e) => e as Map<String, dynamic>).toList()
          : null,
      error: json['error'] as String?,
      success: json['success'] as bool,
    );
  }

  final List<Map<String, dynamic>>? blocks; // List<FullBlock>
  final String? error;
  final bool success;

  Map<String, dynamic> toJson() => {
        if (blocks != null) 'blocks': blocks,
        if (error != null) 'error': error,
        'success': success,
      };
}

/// Response from get_block_spends endpoint
class GetBlockSpendsResponse {
  const GetBlockSpendsResponse({
    this.blockSpends,
    this.error,
    required this.success,
  });

  factory GetBlockSpendsResponse.fromJson(Map<String, dynamic> json) {
    return GetBlockSpendsResponse(
      blockSpends: json['block_spends'] != null
          ? (json['block_spends'] as List)
              .map((e) => CoinSpend.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      error: json['error'] as String?,
      success: json['success'] as bool,
    );
  }

  final List<CoinSpend>? blockSpends;
  final String? error;
  final bool success;

  Map<String, dynamic> toJson() => {
        if (blockSpends != null) 'block_spends': blockSpends!.map((e) => e.toJson()).toList(),
        if (error != null) 'error': error,
        'success': success,
      };
}

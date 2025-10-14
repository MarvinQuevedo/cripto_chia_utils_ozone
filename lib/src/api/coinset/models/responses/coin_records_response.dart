import '../coin_record.dart';

/// Response from endpoints that return coin records
class GetCoinRecordsResponse {
  const GetCoinRecordsResponse({
    this.coinRecords,
    this.error,
    required this.success,
  });

  factory GetCoinRecordsResponse.fromJson(Map<String, dynamic> json) {
    return GetCoinRecordsResponse(
      coinRecords: json['coin_records'] != null
          ? (json['coin_records'] as List)
              .map((e) => CoinsetCoinRecord.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      error: json['error'] as String?,
      success: json['success'] as bool,
    );
  }

  final List<CoinsetCoinRecord>? coinRecords;
  final String? error;
  final bool success;

  Map<String, dynamic> toJson() => {
        if (coinRecords != null) 'coin_records': coinRecords!.map((e) => e.toJson()).toList(),
        if (error != null) 'error': error,
        'success': success,
      };
}

/// Response from get_coin_record_by_name endpoint
class GetCoinRecordResponse {
  const GetCoinRecordResponse({
    this.coinRecord,
    this.error,
    required this.success,
  });

  factory GetCoinRecordResponse.fromJson(Map<String, dynamic> json) {
    return GetCoinRecordResponse(
      coinRecord: json['coin_record'] != null
          ? CoinsetCoinRecord.fromJson(json['coin_record'] as Map<String, dynamic>)
          : null,
      error: json['error'] as String?,
      success: json['success'] as bool,
    );
  }

  final CoinsetCoinRecord? coinRecord;
  final String? error;
  final bool success;

  Map<String, dynamic> toJson() => {
        if (coinRecord != null) 'coin_record': coinRecord!.toJson(),
        if (error != null) 'error': error,
        'success': success,
      };
}

import '../coin_record.dart';

/// Response from get_additions_and_removals endpoint
class AdditionsAndRemovalsResponse {
  const AdditionsAndRemovalsResponse({
    this.additions,
    this.removals,
    this.error,
    required this.success,
  });

  factory AdditionsAndRemovalsResponse.fromJson(Map<String, dynamic> json) {
    return AdditionsAndRemovalsResponse(
      additions: json['additions'] != null
          ? (json['additions'] as List)
              .map((e) => CoinsetCoinRecord.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      removals: json['removals'] != null
          ? (json['removals'] as List)
              .map((e) => CoinsetCoinRecord.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      error: json['error'] as String?,
      success: json['success'] as bool,
    );
  }

  final List<CoinsetCoinRecord>? additions;
  final List<CoinsetCoinRecord>? removals;
  final String? error;
  final bool success;

  Map<String, dynamic> toJson() => {
        if (additions != null) 'additions': additions!.map((e) => e.toJson()).toList(),
        if (removals != null) 'removals': removals!.map((e) => e.toJson()).toList(),
        if (error != null) 'error': error,
        'success': success,
      };
}

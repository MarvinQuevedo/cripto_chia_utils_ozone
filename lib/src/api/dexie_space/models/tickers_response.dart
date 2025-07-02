import 'ticker.dart';

class DexieTickersResponse {
  final bool success;
  final List<DexieTicker> tickers;

  DexieTickersResponse({
    required this.success,
    required this.tickers,
  });

  factory DexieTickersResponse.fromJson(Map<String, dynamic> json) {
    return DexieTickersResponse(
      success: json['success'] as bool,
      tickers: (json['tickers'] as List<dynamic>)
          .map((tickerJson) => DexieTicker.fromJson(tickerJson as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'tickers': tickers.map((ticker) => ticker.toJson()).toList(),
    };
  }

  @override
  String toString() {
    return 'DexieTickersResponse(success: $success, tickersCount: ${tickers.length})';
  }
}

import 'historical_trade.dart';

/// Response model for historical trades from Dexie Space API
class DexieHistoricalTradesResponse {
  final bool success;
  final String tickerId;
  final String poolId;
  final int timestamp;
  final List<DexieHistoricalTrade> trades;

  DexieHistoricalTradesResponse({
    required this.success,
    required this.tickerId,
    required this.poolId,
    required this.timestamp,
    required this.trades,
  });

  /// Creates a DexieHistoricalTradesResponse from JSON data
  factory DexieHistoricalTradesResponse.fromJson(Map<String, dynamic> json) {
    final tradesList = json['trades'] as List<dynamic>;
    final trades = tradesList
        .map((tradeJson) => DexieHistoricalTrade.fromJson(tradeJson as Map<String, dynamic>))
        .toList();

    return DexieHistoricalTradesResponse(
      success: json['success'] as bool,
      tickerId: json['ticker_id'] as String,
      poolId: json['pool_id'] as String,
      timestamp: json['timestamp'] as int,
      trades: trades,
    );
  }

  /// Converts the response to JSON
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'ticker_id': tickerId,
      'pool_id': poolId,
      'timestamp': timestamp,
      'trades': trades.map((trade) => trade.toJson()).toList(),
    };
  }

  /// Gets the response timestamp as a DateTime
  DateTime get responseDateTime => DateTime.fromMillisecondsSinceEpoch(timestamp);

  /// Gets the total number of trades
  int get totalTrades => trades.length;

  /// Gets only buy trades
  List<DexieHistoricalTrade> get buyTrades => trades.where((trade) => trade.isBuy).toList();

  /// Gets only sell trades
  List<DexieHistoricalTrade> get sellTrades => trades.where((trade) => trade.isSell).toList();

  /// Gets the total base volume
  double get totalBaseVolume {
    return trades.fold(0.0, (sum, trade) => sum + trade.baseVolumeAsDouble);
  }

  /// Gets the total target volume
  double get totalTargetVolume {
    return trades.fold(0.0, (sum, trade) => sum + trade.targetVolumeAsDouble);
  }

  /// Gets the average price
  double get averagePrice {
    if (trades.isEmpty) return 0.0;
    final totalPrice = trades.fold(0.0, (sum, trade) => sum + trade.priceAsDouble);
    return totalPrice / trades.length;
  }

  /// Gets the highest price
  double get highestPrice {
    if (trades.isEmpty) return 0.0;
    return trades.map((trade) => trade.priceAsDouble).reduce((a, b) => a > b ? a : b);
  }

  /// Gets the lowest price
  double get lowestPrice {
    if (trades.isEmpty) return 0.0;
    return trades.map((trade) => trade.priceAsDouble).reduce((a, b) => a < b ? a : b);
  }

  /// Gets trades within a specific time range
  List<DexieHistoricalTrade> getTradesInRange(DateTime start, DateTime end) {
    return trades.where((trade) {
      return trade.tradeDateTime.isAfter(start) && trade.tradeDateTime.isBefore(end);
    }).toList();
  }

  /// Gets trades from the last N hours
  List<DexieHistoricalTrade> getTradesFromLastHours(int hours) {
    final cutoffTime = DateTime.now().subtract(Duration(hours: hours));
    return trades.where((trade) => trade.tradeDateTime.isAfter(cutoffTime)).toList();
  }

  /// Gets trades from the last N days
  List<DexieHistoricalTrade> getTradesFromLastDays(int days) {
    final cutoffTime = DateTime.now().subtract(Duration(days: days));
    return trades.where((trade) => trade.tradeDateTime.isAfter(cutoffTime)).toList();
  }

  @override
  String toString() {
    return 'DexieHistoricalTradesResponse(success: $success, tickerId: $tickerId, totalTrades: $totalTrades, timestamp: $responseDateTime)';
  }
}

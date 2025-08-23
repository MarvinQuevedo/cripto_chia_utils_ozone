/// Represents a single historical trade from Dexie Space API
class DexieHistoricalTrade {
  final String tradeId;
  final String price;
  final String baseVolume;
  final String targetVolume;
  final int tradeTimestamp;
  final String type;

  DexieHistoricalTrade({
    required this.tradeId,
    required this.price,
    required this.baseVolume,
    required this.targetVolume,
    required this.tradeTimestamp,
    required this.type,
  });

  /// Creates a DexieHistoricalTrade from JSON data
  factory DexieHistoricalTrade.fromJson(Map<String, dynamic> json) {
    return DexieHistoricalTrade(
      tradeId: json['trade_id'] as String,
      price: json['price'] as String,
      baseVolume: json['base_volume'] as String,
      targetVolume: json['target_volume'] as String,
      tradeTimestamp: json['trade_timestamp'] as int,
      type: json['type'] as String,
    );
  }

  /// Converts the trade to JSON
  Map<String, dynamic> toJson() {
    return {
      'trade_id': tradeId,
      'price': price,
      'base_volume': baseVolume,
      'target_volume': targetVolume,
      'trade_timestamp': tradeTimestamp,
      'type': type,
    };
  }

  /// Gets the price as a double
  double get priceAsDouble => double.tryParse(price) ?? 0.0;

  /// Gets the base volume as a double
  double get baseVolumeAsDouble => double.tryParse(baseVolume) ?? 0.0;

  /// Gets the target volume as a double
  double get targetVolumeAsDouble => double.tryParse(targetVolume) ?? 0.0;

  /// Gets the trade timestamp as a DateTime
  DateTime get tradeDateTime => DateTime.fromMillisecondsSinceEpoch(tradeTimestamp);

  /// Checks if this is a buy trade
  bool get isBuy => type.toLowerCase() == 'buy';

  /// Checks if this is a sell trade
  bool get isSell => type.toLowerCase() == 'sell';

  @override
  String toString() {
    return 'DexieHistoricalTrade(tradeId: $tradeId, price: $price, baseVolume: $baseVolume, targetVolume: $targetVolume, type: $type, timestamp: $tradeDateTime)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DexieHistoricalTrade && other.tradeId == tradeId;
  }

  @override
  int get hashCode => tradeId.hashCode;
}

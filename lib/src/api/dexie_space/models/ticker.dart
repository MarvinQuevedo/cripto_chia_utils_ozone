class DexieTicker {
  final String tickerId;
  final String baseCurrency;
  final String targetCurrency;
  final String baseCode;
  final String targetCode;
  final String baseName;
  final String targetName;
  final String? lastPrice;
  final String? currentAvgPrice;
  final String? baseVolume;
  final String? targetVolume;
  final String? baseVolume7d;
  final String? targetVolume7d;
  final String? baseVolume30d;
  final String? targetVolume30d;
  final String? poolId;
  final String? bid;
  final String? ask;
  final String? high;
  final String? low;

  DexieTicker({
    required this.tickerId,
    required this.baseCurrency,
    required this.targetCurrency,
    required this.baseCode,
    required this.targetCode,
    required this.baseName,
    required this.targetName,
    this.lastPrice,
    this.currentAvgPrice,
    this.baseVolume,
    this.targetVolume,
    this.baseVolume7d,
    this.targetVolume7d,
    this.baseVolume30d,
    this.targetVolume30d,
    this.poolId,
    this.bid,
    this.ask,
    this.high,
    this.low,
  });

  factory DexieTicker.fromJson(Map<String, dynamic> json) {
    return DexieTicker(
      tickerId: json['ticker_id'] as String,
      baseCurrency: json['base_currency'] as String,
      targetCurrency: json['target_currency'] as String,
      baseCode: json['base_code'] as String,
      targetCode: json['target_code'] as String,
      baseName: json['base_name'] as String,
      targetName: json['target_name'] as String,
      lastPrice: json['last_price'] as String?,
      currentAvgPrice: json['current_avg_price'] as String?,
      baseVolume: json['base_volume'] as String?,
      targetVolume: json['target_volume'] as String?,
      baseVolume7d: json['base_volume_7d'] as String?,
      targetVolume7d: json['target_volume_7d'] as String?,
      baseVolume30d: json['base_volume_30d'] as String?,
      targetVolume30d: json['target_volume_30d'] as String?,
      poolId: json['pool_id'] as String?,
      bid: json['bid'] as String?,
      ask: json['ask'] as String?,
      high: json['high'] as String?,
      low: json['low'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ticker_id': tickerId,
      'base_currency': baseCurrency,
      'target_currency': targetCurrency,
      'base_code': baseCode,
      'target_code': targetCode,
      'base_name': baseName,
      'target_name': targetName,
      'last_price': lastPrice,
      'current_avg_price': currentAvgPrice,
      'base_volume': baseVolume,
      'target_volume': targetVolume,
      'base_volume_7d': baseVolume7d,
      'target_volume_7d': targetVolume7d,
      'base_volume_30d': baseVolume30d,
      'target_volume_30d': targetVolume30d,
      'pool_id': poolId,
      'bid': bid,
      'ask': ask,
      'high': high,
      'low': low,
    };
  }

  @override
  String toString() {
    return 'DexieTicker(tickerId: $tickerId, baseCode: $baseCode, targetCode: $targetCode, lastPrice: $lastPrice)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DexieTicker && other.tickerId == tickerId;
  }

  @override
  int get hashCode => tickerId.hashCode;
}

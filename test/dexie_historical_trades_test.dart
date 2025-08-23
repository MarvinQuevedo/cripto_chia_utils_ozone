import 'package:test/test.dart';
import 'package:chia_crypto_utils/chia_crypto_utils.dart';

void main() {
  group('Dexie Space Historical Trades Tests', () {
    late DexieSpaceClient client;

    setUp(() {
      client = DexieSpaceClient();
    });

    test('should create DexieHistoricalTrade from JSON', () {
      final json = {
        'trade_id': 'test_trade_id',
        'price': '0.00482331009301753514',
        'base_volume': '414.653',
        'target_volume': '2',
        'trade_timestamp': 1751547841000,
        'type': 'buy',
      };

      final trade = DexieHistoricalTrade.fromJson(json);

      expect(trade.tradeId, equals('test_trade_id'));
      expect(trade.price, equals('0.00482331009301753514'));
      expect(trade.baseVolume, equals('414.653'));
      expect(trade.targetVolume, equals('2'));
      expect(trade.tradeTimestamp, equals(1751547841000));
      expect(trade.type, equals('buy'));
      expect(trade.isBuy, isTrue);
      expect(trade.isSell, isFalse);
      expect(trade.priceAsDouble, equals(0.00482331009301753514));
      expect(trade.baseVolumeAsDouble, equals(414.653));
      expect(trade.targetVolumeAsDouble, equals(2.0));
    });

    test('should create DexieHistoricalTradesResponse from JSON', () {
      final json = {
        'success': true,
        'ticker_id': 'test_ticker_id',
        'pool_id': 'test_pool_id',
        'timestamp': 1751555439189,
        'trades': [
          {
            'trade_id': 'trade1',
            'price': '0.00482331009301753514',
            'base_volume': '414.653',
            'target_volume': '2',
            'trade_timestamp': 1751547841000,
            'type': 'buy',
          },
          {
            'trade_id': 'trade2',
            'price': '0.004846072921076',
            'base_volume': '500',
            'target_volume': '2.423036460538',
            'trade_timestamp': 1751547705000,
            'type': 'sell',
          },
        ],
      };

      final response = DexieHistoricalTradesResponse.fromJson(json);

      expect(response.success, isTrue);
      expect(response.tickerId, equals('test_ticker_id'));
      expect(response.poolId, equals('test_pool_id'));
      expect(response.timestamp, equals(1751555439189));
      expect(response.trades.length, equals(2));
      expect(response.totalTrades, equals(2));
      expect(response.buyTrades.length, equals(1));
      expect(response.sellTrades.length, equals(1));
      expect(response.averagePrice, greaterThan(0));
      expect(response.highestPrice, greaterThan(0));
      expect(response.lowestPrice, greaterThan(0));
      expect(response.totalBaseVolume, greaterThan(0));
      expect(response.totalTargetVolume, greaterThan(0));
    });

    test('should filter trades by type', () {
      final trades = [
        DexieHistoricalTrade(
          tradeId: 'trade1',
          price: '1.0',
          baseVolume: '100',
          targetVolume: '100',
          tradeTimestamp: DateTime.now().millisecondsSinceEpoch,
          type: 'buy',
        ),
        DexieHistoricalTrade(
          tradeId: 'trade2',
          price: '2.0',
          baseVolume: '200',
          targetVolume: '100',
          tradeTimestamp: DateTime.now().millisecondsSinceEpoch,
          type: 'sell',
        ),
        DexieHistoricalTrade(
          tradeId: 'trade3',
          price: '3.0',
          baseVolume: '300',
          targetVolume: '100',
          tradeTimestamp: DateTime.now().millisecondsSinceEpoch,
          type: 'buy',
        ),
      ];

      final response = DexieHistoricalTradesResponse(
        success: true,
        tickerId: 'test',
        poolId: 'test',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        trades: trades,
      );

      expect(response.buyTrades.length, equals(2));
      expect(response.sellTrades.length, equals(1));
    });

    test('should filter trades by time range', () {
      final now = DateTime.now();
      final oneHourAgo = now.subtract(const Duration(hours: 1));
      final twoHoursAgo = now.subtract(const Duration(hours: 2));

      final trades = [
        DexieHistoricalTrade(
          tradeId: 'trade1',
          price: '1.0',
          baseVolume: '100',
          targetVolume: '100',
          tradeTimestamp: now.millisecondsSinceEpoch,
          type: 'buy',
        ),
        DexieHistoricalTrade(
          tradeId: 'trade2',
          price: '2.0',
          baseVolume: '200',
          targetVolume: '100',
          tradeTimestamp: oneHourAgo.millisecondsSinceEpoch,
          type: 'sell',
        ),
        DexieHistoricalTrade(
          tradeId: 'trade3',
          price: '3.0',
          baseVolume: '300',
          targetVolume: '100',
          tradeTimestamp: twoHoursAgo.millisecondsSinceEpoch,
          type: 'buy',
        ),
      ];

      final response = DexieHistoricalTradesResponse(
        success: true,
        tickerId: 'test',
        poolId: 'test',
        timestamp: now.millisecondsSinceEpoch,
        trades: trades,
      );

      final recentTrades = response.getTradesFromLastHours(1);
      expect(recentTrades.length, equals(1));

      final veryRecentTrades = response.getTradesFromLastHours(0);
      expect(veryRecentTrades.length, equals(0));

      final twoHourTrades = response.getTradesFromLastHours(2);
      expect(twoHourTrades.length, equals(2));
    });

    test('should calculate statistics correctly', () {
      final trades = [
        DexieHistoricalTrade(
          tradeId: 'trade1',
          price: '1.0',
          baseVolume: '100',
          targetVolume: '100',
          tradeTimestamp: DateTime.now().millisecondsSinceEpoch,
          type: 'buy',
        ),
        DexieHistoricalTrade(
          tradeId: 'trade2',
          price: '2.0',
          baseVolume: '200',
          targetVolume: '100',
          tradeTimestamp: DateTime.now().millisecondsSinceEpoch,
          type: 'sell',
        ),
        DexieHistoricalTrade(
          tradeId: 'trade3',
          price: '3.0',
          baseVolume: '300',
          targetVolume: '100',
          tradeTimestamp: DateTime.now().millisecondsSinceEpoch,
          type: 'buy',
        ),
      ];

      final response = DexieHistoricalTradesResponse(
        success: true,
        tickerId: 'test',
        poolId: 'test',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        trades: trades,
      );

      expect(response.averagePrice, equals(2.0));
      expect(response.highestPrice, equals(3.0));
      expect(response.lowestPrice, equals(1.0));
      expect(response.totalBaseVolume, equals(600.0));
      expect(response.totalTargetVolume, equals(300.0));
    });

    test('should handle empty trades list', () {
      final response = DexieHistoricalTradesResponse(
        success: true,
        tickerId: 'test',
        poolId: 'test',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        trades: [],
      );

      expect(response.totalTrades, equals(0));
      expect(response.buyTrades.length, equals(0));
      expect(response.sellTrades.length, equals(0));
      expect(response.averagePrice, equals(0.0));
      expect(response.highestPrice, equals(0.0));
      expect(response.lowestPrice, equals(0.0));
      expect(response.totalBaseVolume, equals(0.0));
      expect(response.totalTargetVolume, equals(0.0));
    });

    test('should convert trade to JSON correctly', () {
      final trade = DexieHistoricalTrade(
        tradeId: 'test_trade_id',
        price: '0.00482331009301753514',
        baseVolume: '414.653',
        targetVolume: '2',
        tradeTimestamp: 1751547841000,
        type: 'buy',
      );

      final json = trade.toJson();

      expect(json['trade_id'], equals('test_trade_id'));
      expect(json['price'], equals('0.00482331009301753514'));
      expect(json['base_volume'], equals('414.653'));
      expect(json['target_volume'], equals('2'));
      expect(json['trade_timestamp'], equals(1751547841000));
      expect(json['type'], equals('buy'));
    });

    test('should convert response to JSON correctly', () {
      final trades = [
        DexieHistoricalTrade(
          tradeId: 'trade1',
          price: '1.0',
          baseVolume: '100',
          targetVolume: '100',
          tradeTimestamp: DateTime.now().millisecondsSinceEpoch,
          type: 'buy',
        ),
      ];

      final response = DexieHistoricalTradesResponse(
        success: true,
        tickerId: 'test_ticker',
        poolId: 'test_pool',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        trades: trades,
      );

      final json = response.toJson();

      expect(json['success'], isTrue);
      expect(json['ticker_id'], equals('test_ticker'));
      expect(json['pool_id'], equals('test_pool'));
      expect(json['trades'], isA<List>());
      expect((json['trades'] as List).length, equals(1));
    });
  });
}

import 'package:chia_crypto_utils/chia_crypto_utils.dart';

/// Example demonstrating how to use the Dexie Space historical trades client
void main() async {
  // Create a Dexie Space client
  final dexieClient = DexieSpaceClient();

  // Example ticker ID for XCH trading pair
  const tickerId = 'db1a9020d48d9d4ad22631b66ab4b9ebd3637ef7758ad38881348c5d24c38f20_xch';

  try {
    print('=== Dexie Space Historical Trades Example ===\n');

    // 1. Get all historical trades for the ticker
    print('1. Fetching all historical trades...');
    final allTrades = await dexieClient.getHistoricalTrades(tickerId);
    print('Total trades: ${allTrades.totalTrades}');
    print('Response timestamp: ${allTrades.responseDateTime}');
    print('Ticker ID: ${allTrades.tickerId}');
    print('Pool ID: ${allTrades.poolId}');
    print('');

    // 2. Get recent trades (last 24 hours)
    print('2. Fetching recent trades (last 24 hours)...');
    final recentTrades = await dexieClient.getRecentTrades(tickerId);
    print('Recent trades: ${recentTrades.totalTrades}');
    print('');

    // 3. Get only buy trades
    print('3. Fetching buy trades only...');
    final buyTrades = await dexieClient.getBuyTrades(tickerId);
    print('Buy trades: ${buyTrades.totalTrades}');
    print('');

    // 4. Get only sell trades
    print('4. Fetching sell trades only...');
    final sellTrades = await dexieClient.getSellTrades(tickerId);
    print('Sell trades: ${sellTrades.totalTrades}');
    print('');

    // 5. Get filtered trades (last 48 hours, buy only)
    print('5. Fetching filtered trades (last 48 hours, buy only)...');
    final filteredTrades = await dexieClient.getHistoricalTradesFiltered(
      tickerId,
      tradeType: 'buy',
      hoursBack: 48,
    );
    print('Filtered trades: ${filteredTrades.totalTrades}');
    print('');

    // 6. Display some statistics
    print('6. Market Statistics:');
    print('Average price: ${allTrades.averagePrice.toStringAsFixed(8)}');
    print('Highest price: ${allTrades.highestPrice.toStringAsFixed(8)}');
    print('Lowest price: ${allTrades.lowestPrice.toStringAsFixed(8)}');
    print('Total base volume: ${allTrades.totalBaseVolume.toStringAsFixed(2)}');
    print('Total target volume: ${allTrades.totalTargetVolume.toStringAsFixed(2)}');
    print('');

    // 7. Display some sample trades
    if (allTrades.trades.isNotEmpty) {
      print('7. Sample trades (first 5):');
      for (int i = 0; i < 5 && i < allTrades.trades.length; i++) {
        final trade = allTrades.trades[i];
        print('  Trade ${i + 1}:');
        print('    ID: ${trade.tradeId}');
        print('    Type: ${trade.type}');
        print('    Price: ${trade.price}');
        print('    Base Volume: ${trade.baseVolume}');
        print('    Target Volume: ${trade.targetVolume}');
        print('    Timestamp: ${trade.tradeDateTime}');
        print('');
      }
    }

    // 8. Get trades from specific time range
    print('8. Trades from last 7 days:');
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final weekTrades = allTrades.getTradesInRange(weekAgo, DateTime.now());
    print('Trades in last 7 days: ${weekTrades.length}');
    print('');

    // 9. Get trades from last 12 hours
    print('9. Trades from last 12 hours:');
    final halfDayTrades = allTrades.getTradesFromLastHours(12);
    print('Trades in last 12 hours: ${halfDayTrades.length}');
    print('');

    // 10. Get trades from last 3 days
    print('10. Trades from last 3 days:');
    final threeDayTrades = allTrades.getTradesFromLastDays(3);
    print('Trades in last 3 days: ${threeDayTrades.length}');
  } catch (e) {
    print('Error: $e');
  }
}

/// Example showing how to work with individual trade data
void tradeDataExample() async {
  final dexieClient = DexieSpaceClient();
  const tickerId = 'db1a9020d48d9d4ad22631b66ab4b9ebd3637ef7758ad38881348c5d24c38f20_xch';

  try {
    final response = await dexieClient.getHistoricalTrades(tickerId);

    if (response.trades.isNotEmpty) {
      final trade = response.trades.first;

      print('=== Individual Trade Data Example ===');
      print('Trade ID: ${trade.tradeId}');
      print('Type: ${trade.type}');
      print('Is Buy: ${trade.isBuy}');
      print('Is Sell: ${trade.isSell}');
      print('Price: ${trade.price}');
      print('Price as double: ${trade.priceAsDouble}');
      print('Base Volume: ${trade.baseVolume}');
      print('Base Volume as double: ${trade.baseVolumeAsDouble}');
      print('Target Volume: ${trade.targetVolume}');
      print('Target Volume as double: ${trade.targetVolumeAsDouble}');
      print('Timestamp: ${trade.tradeTimestamp}');
      print('DateTime: ${trade.tradeDateTime}');
      print('JSON: ${trade.toJson()}');
    }
  } catch (e) {
    print('Error: $e');
  }
}

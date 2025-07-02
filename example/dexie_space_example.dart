import 'package:chia_crypto_utils/chia_crypto_utils.dart';

/// Example demonstrating how to use the Dexie Space API client
void main() async {
  // Create a Dexie Space client
  final dexieClient = DexieSpaceClient();

  try {
    print('=== Dexie Space API Example ===\n');

    // Get all tickers
    print('1. Fetching all tickers...');
    final tickersResponse = await dexieClient.getTickers();
    print('Total tickers: ${tickersResponse.tickers.length}');
    print('Success: ${tickersResponse.success}\n');

    // Get XCH trading pairs
    print('2. Fetching XCH trading pairs...');
    final xchTickers = await dexieClient.getTickersByTargetCurrency('xch');
    print('XCH trading pairs: ${xchTickers.length}');

    // Show first 5 XCH pairs
    for (int i = 0; i < 5 && i < xchTickers.length; i++) {
      final ticker = xchTickers[i];
      print(
          '  ${ticker.baseCode} (${ticker.baseName}) -> ${ticker.targetCode}: ${ticker.lastPrice ?? 'N/A'} XCH');
    }
    print('');

    // Get active tickers (with bid/ask prices)
    print('3. Fetching active tickers...');
    final activeTickers = await dexieClient.getActiveTickers();
    print('Active tickers: ${activeTickers.length}\n');

    // Get top 5 tickers by volume
    print('4. Top 5 tickers by volume:');
    final topVolumeTickers = await dexieClient.getTickersSortedByVolume();
    for (int i = 0; i < 5 && i < topVolumeTickers.length; i++) {
      final ticker = topVolumeTickers[i];
      final volume = double.tryParse(ticker.baseVolume ?? '0') ?? 0;
      print('  ${ticker.baseCode} (${ticker.baseName}): ${volume.toStringAsFixed(2)} volume');
    }
    print('');

    // Search for specific tokens
    print('5. Searching for "LOVE" token...');
    final loveTickers = await dexieClient.searchTickers('LOVE');
    print('Found ${loveTickers.length} LOVE tickers:');
    for (final ticker in loveTickers) {
      print(
          '  ${ticker.baseCode} (${ticker.baseName}) -> ${ticker.targetCode}: ${ticker.lastPrice ?? 'N/A'} ${ticker.targetCode}');
    }
    print('');

    // Get market statistics
    print('6. Market statistics:');
    final marketStats = await dexieClient.getMarketStats();
    print('  Total tickers: ${marketStats.totalTickers}');
    print('  Active tickers: ${marketStats.activeTickers}');
    print('  Total volume: ${marketStats.totalVolume.toStringAsFixed(2)} XCH');
    print('  7-day volume: ${marketStats.totalVolume7d.toStringAsFixed(2)} XCH');
    print('  30-day volume: ${marketStats.totalVolume30d.toStringAsFixed(2)} XCH');
  } catch (e) {
    print('Error: $e');
  }
}

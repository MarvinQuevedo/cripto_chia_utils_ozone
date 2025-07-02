# Dexie Space API Client

A Dart client for interacting with the [Dexie Space API](https://api.dexie.space), a decentralized exchange for Chia tokens.

## Features

- **Market Data**: Fetch real-time ticker information for all trading pairs
- **Filtering**: Filter tickers by currency, code, or trading status
- **Sorting**: Sort tickers by volume, price, or other metrics
- **Search**: Search for specific tokens by name or symbol
- **Statistics**: Get aggregated market statistics
- **Error Handling**: Comprehensive error handling with custom exceptions

## Quick Start

```dart
import 'package:chia_crypto_utils/chia_crypto_utils.dart';

void main() async {
  // Create a Dexie Space client
  final dexieClient = DexieSpaceClient();

  // Get all tickers
  final tickersResponse = await dexieClient.getTickers();
  print('Total tickers: ${tickersResponse.tickers.length}');

  // Get XCH trading pairs
  final xchTickers = await dexieClient.getTickersByTargetCurrency('xch');
  print('XCH trading pairs: ${xchTickers.length}');
}
```

## API Methods

### Basic Operations

#### `getTickers()`
Fetches all available tickers from Dexie Space.

```dart
final response = await dexieClient.getTickers();
print('Success: ${response.success}');
print('Tickers: ${response.tickers.length}');
```

#### `getTickerById(String tickerId)`
Fetches a specific ticker by its unique identifier.

```dart
final ticker = await dexieClient.getTickerById('ticker_id_here');
if (ticker != null) {
  print('Ticker: ${ticker.baseCode} -> ${ticker.targetCode}');
}
```

### Filtering Methods

#### `getTickersByBaseCurrency(String baseCurrency)`
Filters tickers by base currency.

```dart
final xchBaseTickers = await dexieClient.getTickersByBaseCurrency('xch');
```

#### `getTickersByTargetCurrency(String targetCurrency)`
Filters tickers by target currency.

```dart
final xchTargetTickers = await dexieClient.getTickersByTargetCurrency('xch');
```

#### `getTickersByBaseCode(String baseCode)`
Filters tickers by base currency code/symbol.

```dart
final spellPowerTickers = await dexieClient.getTickersByBaseCode('🪄⚡️');
```

#### `getTickersByTargetCode(String targetCode)`
Filters tickers by target currency code/symbol.

```dart
final xchCodeTickers = await dexieClient.getTickersByTargetCode('XCH');
```

#### `getActiveTickers()`
Gets only tickers with active trading (non-null bid/ask prices).

```dart
final activeTickers = await dexieClient.getActiveTickers();
print('Active trading pairs: ${activeTickers.length}');
```

### Sorting Methods

#### `getTickersSortedByVolume({String period = 'base'})`
Sorts tickers by volume. Supports different periods:
- `'base'`: Current volume
- `'7d'`: 7-day volume
- `'30d'`: 30-day volume

```dart
// Sort by current volume
final volumeSorted = await dexieClient.getTickersSortedByVolume();

// Sort by 7-day volume
final volume7dSorted = await dexieClient.getTickersSortedByVolume(period: '7d');
```

#### `getTickersSortedByPrice()`
Sorts tickers by last price in descending order.

```dart
final priceSorted = await dexieClient.getTickersSortedByPrice();
```

### Search and Analysis

#### `searchTickers(String query)`
Searches for tickers by name or code.

```dart
final loveTickers = await dexieClient.searchTickers('LOVE');
print('Found ${loveTickers.length} LOVE tickers');
```

#### `getMarketStats()`
Gets aggregated market statistics.

```dart
final stats = await dexieClient.getMarketStats();
print('Total tickers: ${stats.totalTickers}');
print('Active tickers: ${stats.activeTickers}');
print('Total volume: ${stats.totalVolume} XCH');
```

## Data Models

### DexieTicker
Represents a single trading pair with all its market data.

```dart
class DexieTicker {
  final String tickerId;           // Unique identifier
  final String baseCurrency;       // Base currency ID
  final String targetCurrency;     // Target currency ID
  final String baseCode;           // Base currency symbol (e.g., "🪄⚡️")
  final String targetCode;         // Target currency symbol (e.g., "XCH")
  final String baseName;           // Base currency name
  final String targetName;         // Target currency name
  final String? lastPrice;         // Last traded price
  final String? currentAvgPrice;   // Current average price
  final String? baseVolume;        // Base currency volume
  final String? targetVolume;      // Target currency volume
  final String? baseVolume7d;      // 7-day base volume
  final String? targetVolume7d;    // 7-day target volume
  final String? baseVolume30d;     // 30-day base volume
  final String? targetVolume30d;   // 30-day target volume
  final String? poolId;            // Pool identifier
  final String? bid;               // Best bid price
  final String? ask;               // Best ask price
  final String? high;              // 24h high price
  final String? low;               // 24h low price
}
```

### DexieTickersResponse
Represents the complete API response.

```dart
class DexieTickersResponse {
  final bool success;              // API success status
  final List<DexieTicker> tickers; // List of all tickers
}
```

### DexieMarketStats
Represents aggregated market statistics.

```dart
class DexieMarketStats {
  final int totalTickers;          // Total number of tickers
  final int activeTickers;         // Number of active tickers
  final double totalVolume;        // Total volume in XCH
  final double totalVolume7d;      // 7-day total volume
  final double totalVolume30d;     // 30-day total volume
}
```

## Error Handling

The client throws `DexieSpaceException` for API-related errors:

```dart
try {
  final tickers = await dexieClient.getTickers();
} on DexieSpaceException catch (e) {
  print('API Error: ${e.message} (Status: ${e.statusCode})');
} catch (e) {
  print('Unexpected error: $e');
}
```

## Configuration

### Timeout
You can configure the request timeout when creating the client:

```dart
final dexieClient = DexieSpaceClient(
  timeout: Duration(seconds: 60), // 60 second timeout
);
```

## Examples

See `example/dexie_space_example.dart` for a complete usage example.

## API Endpoints

The client currently supports:
- `GET /v3/prices/tickers` - Get all tickers

## Rate Limiting

The Dexie Space API has rate limits. The client includes a 30-second default timeout to help manage requests appropriately.

## Contributing

To add new features or endpoints:
1. Add new methods to `DexieSpaceClient`
2. Create corresponding model classes if needed
3. Update this documentation
4. Add tests for new functionality 
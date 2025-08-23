import 'dart:convert';

import '../client.dart';
import 'models/index.dart';

/// Client for interacting with the Dexie Space API
///
/// Dexie Space is a decentralized exchange for Chia tokens.
/// This client provides access to market data and trading information.
class DexieSpaceClient {
  static const String _baseUrl = 'https://api.dexie.space';
  static const String _apiVersion = 'v3';

  final Client _client;

  /// Creates a new Dexie Space API client
  ///
  /// [timeout] - Optional timeout for API requests (default: 30 seconds)
  DexieSpaceClient({Duration? timeout})
      : _client = Client(
          _baseUrl,
          timeout: timeout ?? const Duration(seconds: 30),
        );

  /// Gets all available tickers from Dexie Space
  ///
  /// Returns a list of all trading pairs with their current market data
  /// including prices, volumes, and trading information.
  Future<DexieTickersResponse> getTickers() async {
    try {
      final response = await _client.get(
        Uri.parse('$_apiVersion/prices/tickers'),
      );

      if (response.statusCode != 200) {
        throw DexieSpaceException(
          'Failed to fetch tickers. Status code: ${response.statusCode}',
          response.statusCode,
        );
      }

      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
      return DexieTickersResponse.fromJson(jsonData);
    } catch (e) {
      if (e is DexieSpaceException) {
        rethrow;
      }
      throw DexieSpaceException(
        'Error fetching tickers: $e',
        0,
      );
    }
  }

  /// Gets tickers filtered by base currency
  ///
  /// [baseCurrency] - The base currency to filter by (e.g., 'xch' for Chia)
  /// Returns only tickers where the base currency matches
  Future<List<DexieTicker>> getTickersByBaseCurrency(String baseCurrency) async {
    final response = await getTickers();
    return response.tickers
        .where((ticker) => ticker.baseCurrency.toLowerCase() == baseCurrency.toLowerCase())
        .toList();
  }

  /// Gets tickers filtered by target currency
  ///
  /// [targetCurrency] - The target currency to filter by (e.g., 'xch' for Chia)
  /// Returns only tickers where the target currency matches
  Future<List<DexieTicker>> getTickersByTargetCurrency(String targetCurrency) async {
    final response = await getTickers();
    return response.tickers
        .where((ticker) => ticker.targetCurrency.toLowerCase() == targetCurrency.toLowerCase())
        .toList();
  }

  /// Gets a specific ticker by its ID
  ///
  /// [tickerId] - The unique identifier of the ticker
  /// Returns the specific ticker if found, null otherwise
  Future<DexieTicker?> getTickerById(String tickerId) async {
    final response = await getTickers();
    try {
      return response.tickers.firstWhere(
        (ticker) => ticker.tickerId == tickerId,
      );
    } catch (e) {
      return null;
    }
  }

  /// Gets tickers filtered by base currency code (symbol)
  ///
  /// [baseCode] - The base currency code/symbol to filter by (e.g., '🪄⚡️', '☕')
  /// Returns only tickers where the base code matches
  Future<List<DexieTicker>> getTickersByBaseCode(String baseCode) async {
    final response = await getTickers();
    return response.tickers.where((ticker) => ticker.baseCode == baseCode).toList();
  }

  /// Gets tickers filtered by target currency code (symbol)
  ///
  /// [targetCode] - The target currency code/symbol to filter by (e.g., 'XCH')
  /// Returns only tickers where the target code matches
  Future<List<DexieTicker>> getTickersByTargetCode(String targetCode) async {
    final response = await getTickers();
    return response.tickers.where((ticker) => ticker.targetCode == targetCode).toList();
  }

  /// Gets tickers with active trading (non-null bid/ask prices)
  ///
  /// Returns only tickers that have active bid and ask prices
  Future<List<DexieTicker>> getActiveTickers() async {
    final response = await getTickers();
    return response.tickers.where((ticker) => ticker.bid != null && ticker.ask != null).toList();
  }

  /// Gets tickers sorted by volume (highest first)
  ///
  /// [period] - The volume period to sort by ('base', '7d', '30d')
  /// Returns tickers sorted by the specified volume period
  Future<List<DexieTicker>> getTickersSortedByVolume({String period = 'base'}) async {
    final response = await getTickers();
    final tickers = List<DexieTicker>.from(response.tickers);

    switch (period.toLowerCase()) {
      case '7d':
        tickers.sort((a, b) {
          final aVolume = double.tryParse(a.baseVolume7d ?? '0') ?? 0;
          final bVolume = double.tryParse(b.baseVolume7d ?? '0') ?? 0;
          return bVolume.compareTo(aVolume);
        });
        break;
      case '30d':
        tickers.sort((a, b) {
          final aVolume = double.tryParse(a.baseVolume30d ?? '0') ?? 0;
          final bVolume = double.tryParse(b.baseVolume30d ?? '0') ?? 0;
          return bVolume.compareTo(aVolume);
        });
        break;
      default: // 'base' or any other value
        tickers.sort((a, b) {
          final aVolume = double.tryParse(a.baseVolume ?? '0') ?? 0;
          final bVolume = double.tryParse(b.baseVolume ?? '0') ?? 0;
          return bVolume.compareTo(aVolume);
        });
    }

    return tickers;
  }

  /// Gets tickers sorted by price (highest first)
  ///
  /// Returns tickers sorted by last price in descending order
  Future<List<DexieTicker>> getTickersSortedByPrice() async {
    final response = await getTickers();
    final tickers = List<DexieTicker>.from(response.tickers);

    tickers.sort((a, b) {
      final aPrice = double.tryParse(a.lastPrice ?? '0') ?? 0;
      final bPrice = double.tryParse(b.lastPrice ?? '0') ?? 0;
      return bPrice.compareTo(aPrice);
    });

    return tickers;
  }

  /// Searches tickers by name or code
  ///
  /// [query] - The search query to match against ticker names or codes
  /// Returns tickers that match the search query
  Future<List<DexieTicker>> searchTickers(String query) async {
    final response = await getTickers();
    final lowerQuery = query.toLowerCase();

    return response.tickers.where((ticker) {
      return ticker.baseName.toLowerCase().contains(lowerQuery) ||
          ticker.targetName.toLowerCase().contains(lowerQuery) ||
          ticker.baseCode.toLowerCase().contains(lowerQuery) ||
          ticker.targetCode.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Gets market statistics
  ///
  /// Returns aggregated market statistics including total volume and active pairs
  Future<DexieMarketStats> getMarketStats() async {
    final response = await getTickers();
    final activeTickers = response.tickers.where((t) => t.bid != null && t.ask != null).toList();

    double totalVolume = 0;
    double totalVolume7d = 0;
    double totalVolume30d = 0;

    for (final ticker in response.tickers) {
      totalVolume += double.tryParse(ticker.targetVolume ?? '0') ?? 0;
      totalVolume7d += double.tryParse(ticker.targetVolume7d ?? '0') ?? 0;
      totalVolume30d += double.tryParse(ticker.targetVolume30d ?? '0') ?? 0;
    }

    return DexieMarketStats(
      totalTickers: response.tickers.length,
      activeTickers: activeTickers.length,
      totalVolume: totalVolume,
      totalVolume7d: totalVolume7d,
      totalVolume30d: totalVolume30d,
    );
  }

  /// Gets historical trades for a specific ticker
  ///
  /// [tickerId] - The unique identifier of the ticker (e.g., 'db1a9020d48d9d4ad22631b66ab4b9ebd3637ef7758ad38881348c5d24c38f20_xch')
  /// Returns historical trade data including prices, volumes, and timestamps
  Future<DexieHistoricalTradesResponse> getHistoricalTrades(String tickerId) async {
    try {
      final response = await _client.get(
        Uri.parse('$_apiVersion/prices/historical_trades?ticker_id=$tickerId'),
      );

      if (response.statusCode != 200) {
        throw DexieSpaceException(
          'Failed to fetch historical trades. Status code: ${response.statusCode}',
          response.statusCode,
        );
      }

      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
      return DexieHistoricalTradesResponse.fromJson(jsonData);
    } catch (e) {
      if (e is DexieSpaceException) {
        rethrow;
      }
      throw DexieSpaceException(
        'Error fetching historical trades: $e',
        0,
      );
    }
  }

  /// Gets historical trades for a specific ticker with optional filtering
  ///
  /// [tickerId] - The unique identifier of the ticker
  /// [tradeType] - Optional filter for trade type ('buy', 'sell', or null for all)
  /// [hoursBack] - Optional filter for trades from the last N hours
  /// Returns filtered historical trade data
  Future<DexieHistoricalTradesResponse> getHistoricalTradesFiltered(
    String tickerId, {
    String? tradeType,
    int? hoursBack,
  }) async {
    final response = await getHistoricalTrades(tickerId);

    List<DexieHistoricalTrade> filteredTrades = response.trades;

    // Filter by trade type if specified
    if (tradeType != null) {
      final lowerType = tradeType.toLowerCase();
      if (lowerType == 'buy' || lowerType == 'sell') {
        filteredTrades =
            filteredTrades.where((trade) => trade.type.toLowerCase() == lowerType).toList();
      }
    }

    // Filter by time if specified
    if (hoursBack != null && hoursBack > 0) {
      final cutoffTime = DateTime.now().subtract(Duration(hours: hoursBack));
      filteredTrades =
          filteredTrades.where((trade) => trade.tradeDateTime.isAfter(cutoffTime)).toList();
    }

    return DexieHistoricalTradesResponse(
      success: response.success,
      tickerId: response.tickerId,
      poolId: response.poolId,
      timestamp: response.timestamp,
      trades: filteredTrades,
    );
  }

  /// Gets recent trades for a specific ticker (last 24 hours)
  ///
  /// [tickerId] - The unique identifier of the ticker
  /// Returns historical trades from the last 24 hours
  Future<DexieHistoricalTradesResponse> getRecentTrades(String tickerId) async {
    return getHistoricalTradesFiltered(tickerId, hoursBack: 24);
  }

  /// Gets buy trades for a specific ticker
  ///
  /// [tickerId] - The unique identifier of the ticker
  /// Returns only buy trades from historical data
  Future<DexieHistoricalTradesResponse> getBuyTrades(String tickerId) async {
    return getHistoricalTradesFiltered(tickerId, tradeType: 'buy');
  }

  /// Gets sell trades for a specific ticker
  ///
  /// [tickerId] - The unique identifier of the ticker
  /// Returns only sell trades from historical data
  Future<DexieHistoricalTradesResponse> getSellTrades(String tickerId) async {
    return getHistoricalTradesFiltered(tickerId, tradeType: 'sell');
  }
}

/// Market statistics for Dexie Space
class DexieMarketStats {
  final int totalTickers;
  final int activeTickers;
  final double totalVolume;
  final double totalVolume7d;
  final double totalVolume30d;

  DexieMarketStats({
    required this.totalTickers,
    required this.activeTickers,
    required this.totalVolume,
    required this.totalVolume7d,
    required this.totalVolume30d,
  });

  @override
  String toString() {
    return 'DexieMarketStats(totalTickers: $totalTickers, activeTickers: $activeTickers, totalVolume: $totalVolume)';
  }
}

/// Exception thrown by Dexie Space API operations
class DexieSpaceException implements Exception {
  final String message;
  final int statusCode;

  DexieSpaceException(this.message, this.statusCode);

  @override
  String toString() => 'DexieSpaceException: $message (Status: $statusCode)';
}

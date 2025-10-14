import 'dart:convert';
import 'package:chia_crypto_utils/chia_crypto_utils.dart';

/// HTTP client for interacting with coinset.org API
///
/// coinset.org provides a public API for querying Chia blockchain data
/// similar to a full node RPC interface but optimized for light clients.
///
/// This client implements the same interface as the Rust SDK's CoinsetClient.
class CoinsetClient {
  CoinsetClient({
    required String baseUrl,
    Duration? timeout,
  })  : _baseUrl = baseUrl,
        _client = Client(
          baseUrl,
          timeout: timeout ?? const Duration(seconds: 30),
        );

  /// Creates a client for mainnet
  factory CoinsetClient.mainnet({Duration? timeout}) {
    return CoinsetClient(
      baseUrl: 'https://api.coinset.org',
      timeout: timeout,
    );
  }

  /// Creates a client for testnet11
  factory CoinsetClient.testnet11({Duration? timeout}) {
    return CoinsetClient(
      baseUrl: 'https://testnet11.api.coinset.org',
      timeout: timeout,
    );
  }

  final String _baseUrl;
  final Client _client;

  String get baseUrl => _baseUrl;

  /// Makes a POST request to the API
  Future<T> _makePostRequest<T>({
    required String endpoint,
    required Map<String, dynamic> body,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse(endpoint),
        body,
      );

      if (response.statusCode != 200) {
        throw CoinsetException(
          'HTTP ${response.statusCode}: ${response.body}',
          response.statusCode,
        );
      }

      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
      return fromJson(jsonData);
    } catch (e) {
      if (e is CoinsetException) {
        rethrow;
      }
      throw CoinsetException('Request failed: $e', 0);
    }
  }

  /// Gets the current blockchain state
  Future<CoinsetBlockchainStateResponse> getBlockchainState() async {
    return _makePostRequest(
      endpoint: 'get_blockchain_state',
      body: {},
      fromJson: CoinsetBlockchainStateResponse.fromJson,
    );
  }

  /// Gets additions and removals for a specific block
  Future<AdditionsAndRemovalsResponse> getAdditionsAndRemovals(
    Puzzlehash headerHash,
  ) async {
    return _makePostRequest(
      endpoint: 'get_additions_and_removals',
      body: {
        'header_hash': '0x${headerHash.toHex()}',
      },
      fromJson: AdditionsAndRemovalsResponse.fromJson,
    );
  }

  /// Gets a full block by its header hash
  Future<GetBlockResponse> getBlock(
    Puzzlehash headerHash,
  ) async {
    return _makePostRequest(
      endpoint: 'get_block',
      body: {
        'header_hash': '0x${headerHash.toHex()}',
      },
      fromJson: GetBlockResponse.fromJson,
    );
  }

  /// Gets a block record by its header hash
  Future<GetBlockRecordResponse> getBlockRecord(
    Puzzlehash headerHash,
  ) async {
    return _makePostRequest(
      endpoint: 'get_block_record',
      body: {
        'header_hash': '0x${headerHash.toHex()}',
      },
      fromJson: GetBlockRecordResponse.fromJson,
    );
  }

  /// Gets a block record by its height
  Future<GetBlockRecordByHeightResponse> getBlockRecordByHeight(
    int height,
  ) async {
    return _makePostRequest(
      endpoint: 'get_block_record_by_height',
      body: {
        'height': height,
      },
      fromJson: GetBlockRecordByHeightResponse.fromJson,
    );
  }

  /// Gets multiple block records in a height range
  Future<GetBlockRecordsResponse> getBlockRecords(
    int startHeight,
    int endHeight,
  ) async {
    return _makePostRequest(
      endpoint: 'get_block_records',
      body: {
        'start_height': startHeight,
        'end_height': endHeight,
      },
      fromJson: GetBlockRecordsResponse.fromJson,
    );
  }

  /// Gets multiple blocks in a height range
  Future<GetBlocksResponse> getBlocks(
    int start,
    int end, {
    bool excludeHeaderHash = false,
    bool excludeReorged = false,
  }) async {
    return _makePostRequest(
      endpoint: 'get_blocks',
      body: {
        'start': start,
        'end': end,
        'exclude_header_hash': excludeHeaderHash,
        'exclude_reorged': excludeReorged,
      },
      fromJson: GetBlocksResponse.fromJson,
    );
  }

  /// Gets all coin spends in a block
  Future<GetBlockSpendsResponse> getBlockSpends(
    Puzzlehash headerHash,
  ) async {
    return _makePostRequest(
      endpoint: 'get_block_spends',
      body: {
        'header_hash': '0x${headerHash.toHex()}',
      },
      fromJson: GetBlockSpendsResponse.fromJson,
    );
  }

  /// Gets a coin record by its name (coin ID)
  Future<GetCoinRecordResponse> getCoinRecordByName(
    Puzzlehash name,
  ) async {
    return _makePostRequest(
      endpoint: 'get_coin_record_by_name',
      body: {
        'name': '0x${name.toHex()}',
      },
      fromJson: GetCoinRecordResponse.fromJson,
    );
  }

  /// Gets coin records by hint
  Future<GetCoinRecordsResponse> getCoinRecordsByHint(
    Puzzlehash hint, {
    int? startHeight,
    int? endHeight,
    bool? includeSpentCoins,
  }) async {
    return _makePostRequest(
      endpoint: 'get_coin_records_by_hint',
      body: {
        'hint': '0x${hint.toHex()}',
        if (startHeight != null) 'start_height': startHeight,
        if (endHeight != null) 'end_height': endHeight,
        if (includeSpentCoins != null) 'include_spent_coins': includeSpentCoins,
      },
      fromJson: GetCoinRecordsResponse.fromJson,
    );
  }

  /// Gets coin records by multiple names
  Future<GetCoinRecordsResponse> getCoinRecordsByNames(
    List<Puzzlehash> names, {
    int? startHeight,
    int? endHeight,
    bool? includeSpentCoins,
  }) async {
    return _makePostRequest(
      endpoint: 'get_coin_records_by_names',
      body: {
        'names': names.map((name) => '0x${name.toHex()}').toList(),
        if (startHeight != null) 'start_height': startHeight,
        if (endHeight != null) 'end_height': endHeight,
        if (includeSpentCoins != null) 'include_spent_coins': includeSpentCoins,
      },
      fromJson: GetCoinRecordsResponse.fromJson,
    );
  }

  /// Gets coin records by parent IDs
  Future<GetCoinRecordsResponse> getCoinRecordsByParentIds(
    List<Puzzlehash> parentIds, {
    int? startHeight,
    int? endHeight,
    bool? includeSpentCoins,
  }) async {
    return _makePostRequest(
      endpoint: 'get_coin_records_by_parent_ids',
      body: {
        'parent_ids': parentIds.map((id) => '0x${id.toHex()}').toList(),
        if (startHeight != null) 'start_height': startHeight,
        if (endHeight != null) 'end_height': endHeight,
        if (includeSpentCoins != null) 'include_spent_coins': includeSpentCoins,
      },
      fromJson: GetCoinRecordsResponse.fromJson,
    );
  }

  /// Gets coin records by puzzle hash
  Future<GetCoinRecordsResponse> getCoinRecordsByPuzzleHash(
    Puzzlehash puzzleHash, {
    int? startHeight,
    int? endHeight,
    bool? includeSpentCoins,
  }) async {
    return _makePostRequest(
      endpoint: 'get_coin_records_by_puzzle_hash',
      body: {
        'puzzle_hash': '0x${puzzleHash.toHex()}',
        if (startHeight != null) 'start_height': startHeight,
        if (endHeight != null) 'end_height': endHeight,
        if (includeSpentCoins != null) 'include_spent_coins': includeSpentCoins,
      },
      fromJson: GetCoinRecordsResponse.fromJson,
    );
  }

  /// Gets coin records by multiple puzzle hashes
  Future<GetCoinRecordsResponse> getCoinRecordsByPuzzleHashes(
    List<Puzzlehash> puzzleHashes, {
    int? startHeight,
    int? endHeight,
    bool? includeSpentCoins,
  }) async {
    return _makePostRequest(
      endpoint: 'get_coin_records_by_puzzle_hashes',
      body: {
        'puzzle_hashes': puzzleHashes.map((ph) => '0x${ph.toHex()}').toList(),
        if (startHeight != null) 'start_height': startHeight,
        if (endHeight != null) 'end_height': endHeight,
        if (includeSpentCoins != null) 'include_spent_coins': includeSpentCoins,
      },
      fromJson: GetCoinRecordsResponse.fromJson,
    );
  }

  /// Gets the puzzle and solution for a coin
  Future<GetPuzzleAndSolutionResponse> getPuzzleAndSolution(
    Puzzlehash coinId, {
    int? height,
  }) async {
    return _makePostRequest(
      endpoint: 'get_puzzle_and_solution',
      body: {
        'coin_id': '0x${coinId.toHex()}',
        if (height != null) 'height': height,
      },
      fromJson: GetPuzzleAndSolutionResponse.fromJson,
    );
  }

  /// Pushes a transaction (spend bundle) to the network
  Future<PushTxResponse> pushTx(SpendBundle spendBundle) async {
    return _makePostRequest(
      endpoint: 'push_tx',
      body: {
        'spend_bundle': _spendBundleToJson(spendBundle),
      },
      fromJson: PushTxResponse.fromJson,
    );
  }

  /// Gets network information
  Future<GetNetworkInfoResponse> getNetworkInfo() async {
    return _makePostRequest(
      endpoint: 'get_network_info',
      body: {},
      fromJson: GetNetworkInfoResponse.fromJson,
    );
  }

  /// Gets a mempool item by transaction ID
  Future<GetMempoolItemResponse> getMempoolItemByTxId(
    Puzzlehash txId,
  ) async {
    return _makePostRequest(
      endpoint: 'get_mempool_item_by_tx_id',
      body: {
        'tx_id': '0x${txId.toHex()}',
      },
      fromJson: GetMempoolItemResponse.fromJson,
    );
  }

  /// Gets mempool items by coin name
  Future<GetMempoolItemsResponse> getMempoolItemsByCoinName(
    Puzzlehash coinName,
  ) async {
    return _makePostRequest(
      endpoint: 'get_mempool_items_by_coin_name',
      body: {
        'coin_name': '0x${coinName.toHex()}',
      },
      fromJson: GetMempoolItemsResponse.fromJson,
    );
  }

  /// Converts a SpendBundle to JSON format expected by the API
  Map<String, dynamic> _spendBundleToJson(SpendBundle spendBundle) {
    return {
      'coin_spends': spendBundle.coinSpends.map((coinSpend) {
        return {
          'coin': {
            'amount': coinSpend.coin.amount,
            'parent_coin_info': '0x${coinSpend.coin.parentCoinInfo.toHex()}',
            'puzzle_hash': '0x${coinSpend.coin.puzzlehash.toHex()}',
          },
          'puzzle_reveal': '0x${coinSpend.puzzleReveal.toHex()}',
          'solution': '0x${coinSpend.solution.toHex()}',
        };
      }).toList(),
      'aggregated_signature': '0x${spendBundle.aggregatedSignature?.toHex() ?? '0x' + 'c' * 192}',
    };
  }
}

/// Exception thrown when a coinset.org API request fails
class CoinsetException implements Exception {
  const CoinsetException(this.message, this.statusCode);

  final String message;
  final int statusCode;

  @override
  String toString() => 'CoinsetException($statusCode): $message';
}

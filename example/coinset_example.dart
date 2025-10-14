// ignore_for_file: avoid_print

import 'package:chia_crypto_utils/chia_crypto_utils.dart';

/// Example demonstrating how to use the CoinsetClient to interact with coinset.org API
Future<void> main() async {
  // Create a client for mainnet
  final client = CoinsetClient.mainnet();

  // Or for testnet11
  // final client = CoinsetClient.testnet11();

  print('=== Coinset.org API Client Example ===\n');

  // 1. Get blockchain state
  await getBlockchainStateExample(client);

  // 2. Get network info
  await getNetworkInfoExample(client);

  // 3. Search coins by puzzle hash
  await searchCoinsByPuzzleHashExample(client);

  // 4. Search coins by hint
  await searchCoinsByHintExample(client);

  // 5. Get block record by height
  await getBlockRecordByHeightExample(client, 1000000);

  print('\n=== Example completed ===');
}

/// Example: Get the current blockchain state
Future<void> getBlockchainStateExample(CoinsetClient client) async {
  print('--- Getting Blockchain State ---');

  try {
    final response = await client.getBlockchainState();

    if (response.success && response.blockchainState != null) {
      final state = response.blockchainState!;
      print('✓ Blockchain state retrieved successfully');
      print('  Synced: ${state.sync.synced}');
      print('  Sync mode: ${state.sync.syncMode}');
      print('  Mempool size: ${state.mempoolSize}');
      print('  Mempool cost: ${state.mempoolCost}');
      print('  Mempool fees: ${state.mempoolFees}');
      print('  Average block time: ${state.averageBlockTime}s');
      print('  Difficulty: ${state.difficulty}');
      print('  Space: ${state.space}');
    } else {
      print('✗ Error: ${response.error}');
    }
  } catch (e) {
    print('✗ Exception: $e');
  }

  print('');
}

/// Example: Get network information
Future<void> getNetworkInfoExample(CoinsetClient client) async {
  print('--- Getting Network Info ---');

  try {
    final response = await client.getNetworkInfo();

    if (response.success) {
      print('✓ Network info retrieved successfully');
      print('  Network name: ${response.networkName}');
      print('  Network prefix: ${response.networkPrefix}');
      print('  Genesis challenge: ${response.genesisChallenge}');
    } else {
      print('✗ Error: ${response.error}');
    }
  } catch (e) {
    print('✗ Exception: $e');
  }

  print('');
}

/// Example: Search for coins by puzzle hash
Future<void> searchCoinsByPuzzleHashExample(CoinsetClient client) async {
  print('--- Searching Coins by Puzzle Hash ---');

  // Example puzzle hash - replace with a real one
  final examplePuzzleHash = '0x${'a' * 64}'; // dummy hash for demonstration

  try {
    final puzzleHash = Puzzlehash.fromHex(examplePuzzleHash);

    final response = await client.getCoinRecordsByPuzzleHash(
      puzzleHash,
      includeSpentCoins: false,
    );

    if (response.success && response.coinRecords != null) {
      print('✓ Found ${response.coinRecords!.length} coins');

      for (final record in response.coinRecords!) {
        print('  Coin ID: ${record.coin.id.toHex()}');
        print('    Amount: ${record.coin.amount}');
        print('    Confirmed at height: ${record.confirmedBlockIndex}');
        print('    Spent: ${record.spent}');
        if (record.spent) {
          print('    Spent at height: ${record.spentBlockIndex}');
        }
        print('');
      }
    } else {
      print('✗ Error: ${response.error ?? "No coins found"}');
    }
  } catch (e) {
    print('✗ Exception: $e');
  }

  print('');
}

/// Example: Search for coins by hint
Future<void> searchCoinsByHintExample(CoinsetClient client) async {
  print('--- Searching Coins by Hint ---');

  // Example hint - replace with a real one
  final exampleHint = '0x${'b' * 64}'; // dummy hint for demonstration

  try {
    final hint = Puzzlehash.fromHex(exampleHint);

    final response = await client.getCoinRecordsByHint(
      hint,
      includeSpentCoins: true,
    );

    if (response.success && response.coinRecords != null) {
      print('✓ Found ${response.coinRecords!.length} coins with hint');

      var totalAmount = 0;
      var spentCount = 0;
      var unspentCount = 0;

      for (final record in response.coinRecords!) {
        totalAmount += record.coin.amount;
        if (record.spent) {
          spentCount++;
        } else {
          unspentCount++;
        }
      }

      print('  Total coins: ${response.coinRecords!.length}');
      print('  Unspent: $unspentCount');
      print('  Spent: $spentCount');
      print('  Total amount: $totalAmount mojos');
    } else {
      print('✗ Error: ${response.error ?? "No coins found"}');
    }
  } catch (e) {
    print('✗ Exception: $e');
  }

  print('');
}

/// Example: Get coin by name (ID)
Future<void> getCoinByNameExample(CoinsetClient client, String coinId) async {
  print('--- Getting Coin by Name ---');

  try {
    final coinName = Puzzlehash.fromHex(coinId);

    final response = await client.getCoinRecordByName(coinName);

    if (response.success && response.coinRecord != null) {
      final record = response.coinRecord!;
      print('✓ Coin found');
      print('  Coin ID: ${record.coin.id.toHex()}');
      print('  Parent: ${record.coin.parentCoinInfo.toHex()}');
      print('  Puzzle hash: ${record.coin.puzzlehash.toHex()}');
      print('  Amount: ${record.coin.amount}');
      print('  Coinbase: ${record.coinbase}');
      print('  Confirmed at: ${record.confirmedBlockIndex}');
      print('  Spent: ${record.spent}');
      if (record.spent) {
        print('  Spent at: ${record.spentBlockIndex}');
      }
    } else {
      print('✗ Error: ${response.error ?? "Coin not found"}');
    }
  } catch (e) {
    print('✗ Exception: $e');
  }

  print('');
}

/// Example: Get puzzle and solution for a spent coin
Future<void> getPuzzleAndSolutionExample(CoinsetClient client, String coinId) async {
  print('--- Getting Puzzle and Solution ---');

  try {
    final coinName = Puzzlehash.fromHex(coinId);

    final response = await client.getPuzzleAndSolution(coinName);

    if (response.success && response.coinSolution != null) {
      final coinSpend = response.coinSolution!;
      print('✓ Puzzle and solution retrieved');
      print('  Coin: ${coinSpend.coin}');
      print('  Puzzle reveal: ${coinSpend.puzzleReveal.toHex()}');
      print('  Solution: ${coinSpend.solution.toHex()}');
    } else {
      print('✗ Error: ${response.error ?? "Puzzle and solution not found"}');
    }
  } catch (e) {
    print('✗ Exception: $e');
  }

  print('');
}

/// Example: Search coins by multiple puzzle hashes
Future<void> searchCoinsByMultiplePuzzleHashesExample(
  CoinsetClient client,
  List<String> puzzleHashes,
) async {
  print('--- Searching Coins by Multiple Puzzle Hashes ---');

  try {
    final puzzleHashList = puzzleHashes.map((ph) => Puzzlehash.fromHex(ph)).toList();

    final response = await client.getCoinRecordsByPuzzleHashes(
      puzzleHashList,
      includeSpentCoins: false,
    );

    if (response.success && response.coinRecords != null) {
      print(
          '✓ Found ${response.coinRecords!.length} coins across ${puzzleHashes.length} puzzle hashes');

      final coinsByPuzzleHash = <String, int>{};
      for (final record in response.coinRecords!) {
        final ph = record.coin.puzzlehash.toHex();
        coinsByPuzzleHash[ph] = (coinsByPuzzleHash[ph] ?? 0) + 1;
      }

      print('  Distribution:');
      for (final entry in coinsByPuzzleHash.entries) {
        print('    ${entry.key.substring(0, 16)}...: ${entry.value} coins');
      }
    } else {
      print('✗ Error: ${response.error ?? "No coins found"}');
    }
  } catch (e) {
    print('✗ Exception: $e');
  }

  print('');
}

/// Example: Get mempool items by coin name
Future<void> getMempoolItemsExample(CoinsetClient client, String coinName) async {
  print('--- Getting Mempool Items ---');

  try {
    final coinId = Puzzlehash.fromHex(coinName);

    final response = await client.getMempoolItemsByCoinName(coinId);

    if (response.success && response.mempoolItems != null) {
      print('✓ Found ${response.mempoolItems!.length} mempool items');

      for (final item in response.mempoolItems!) {
        print('  Fee: ${item.fee} mojos');
        print('  Coin spends: ${item.spendBundle.coinSpends.length}');
      }
    } else {
      print('✗ Error: ${response.error ?? "No mempool items found"}');
    }
  } catch (e) {
    print('✗ Exception: $e');
  }

  print('');
}

/// Example: Get block record by height
Future<void> getBlockRecordByHeightExample(CoinsetClient client, int height) async {
  print('--- Getting Block Record by Height ---');

  try {
    final response = await client.getBlockRecordByHeight(height);

    if (response.success && response.blockRecord != null) {
      final record = response.blockRecord! as Map<String, dynamic>;
      print('✓ Block record found at height $height');
      print('  Height: ${record['height']}');
      print('  Header hash: ${record['header_hash']}');
      print('  Timestamp: ${record['timestamp']}');
      if (record['prev_hash'] != null) {
        print('  Previous hash: ${record['prev_hash']}');
      }
    } else {
      print('✗ Error: ${response.error ?? "Block record not found"}');
    }
  } catch (e) {
    print('✗ Exception: $e');
  }

  print('');
}

/// Example: Get block spends
Future<void> getBlockSpendsExample(CoinsetClient client, String headerHash) async {
  print('--- Getting Block Spends ---');

  try {
    final hash = Puzzlehash.fromHex(headerHash);

    final response = await client.getBlockSpends(hash);

    if (response.success && response.blockSpends != null) {
      print('✓ Found ${response.blockSpends!.length} coin spends in block');

      for (final spend in response.blockSpends!) {
        print('  Coin: ${spend.coin}');
        print('    Puzzle reveal: ${spend.puzzleReveal.toHex().substring(0, 32)}...');
      }
    } else {
      print('✗ Error: ${response.error ?? "No spends found"}');
    }
  } catch (e) {
    print('✗ Exception: $e');
  }

  print('');
}

/// Example: Get block records range
Future<void> getBlockRecordsExample(CoinsetClient client, int startHeight, int endHeight) async {
  print('--- Getting Block Records Range ---');

  try {
    final response = await client.getBlockRecords(startHeight, endHeight);

    if (response.success && response.blockRecords != null) {
      print('✓ Found ${response.blockRecords!.length} block records');
      print('  Height range: $startHeight - $endHeight');

      if (response.blockRecords!.isNotEmpty) {
        final first = response.blockRecords!.first as Map<String, dynamic>;
        final last = response.blockRecords!.last as Map<String, dynamic>;
        print('  First block height: ${first['height']}');
        print('  Last block height: ${last['height']}');
      }
    } else {
      print('✗ Error: ${response.error ?? "No block records found"}');
    }
  } catch (e) {
    print('✗ Exception: $e');
  }

  print('');
}

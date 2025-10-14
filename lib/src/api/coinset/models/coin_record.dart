import 'package:chia_crypto_utils/chia_crypto_utils.dart';

/// Represents a coin record from the coinset.org API
class CoinsetCoinRecord {
  const CoinsetCoinRecord({
    required this.coin,
    required this.coinbase,
    required this.confirmedBlockIndex,
    required this.spent,
    required this.spentBlockIndex,
    required this.timestamp,
  });

  factory CoinsetCoinRecord.fromJson(Map<String, dynamic> json) {
    final coinJson = json['coin'] as Map<String, dynamic>;

    // Parse hex strings, removing '0x' prefix if present
    final parentCoinInfoHex = (coinJson['parent_coin_info'] as String).replaceFirst('0x', '');
    final puzzleHashHex = (coinJson['puzzle_hash'] as String).replaceFirst('0x', '');

    final confirmedBlockIndex = json['confirmed_block_index'] as int;
    final spentBlockIndex = json['spent_block_index'] as int;
    final coinbase = json['coinbase'] as bool;
    final timestamp = json['timestamp'] as int;

    return CoinsetCoinRecord(
      coin: Coin(
        confirmedBlockIndex: confirmedBlockIndex,
        spentBlockIndex: spentBlockIndex,
        coinbase: coinbase,
        timestamp: timestamp,
        parentCoinInfo: Puzzlehash.fromHex(parentCoinInfoHex),
        puzzlehash: Puzzlehash.fromHex(puzzleHashHex),
        amount: coinJson['amount'] as int,
      ),
      coinbase: coinbase,
      confirmedBlockIndex: confirmedBlockIndex,
      spent: json['spent'] as bool,
      spentBlockIndex: spentBlockIndex,
      timestamp: timestamp,
    );
  }

  final Coin coin;
  final bool coinbase;
  final int confirmedBlockIndex;
  final bool spent;
  final int spentBlockIndex;
  final int timestamp;

  Map<String, dynamic> toJson() => {
        'coin': {
          'parent_coin_info': coin.parentCoinInfo.toHex(),
          'puzzle_hash': coin.puzzlehash.toHex(),
          'amount': coin.amount,
        },
        'coinbase': coinbase,
        'confirmed_block_index': confirmedBlockIndex,
        'spent': spent,
        'spent_block_index': spentBlockIndex,
        'timestamp': timestamp,
      };

  @override
  String toString() {
    return 'CoinsetCoinRecord(coin: $coin, coinbase: $coinbase, '
        'confirmedBlockIndex: $confirmedBlockIndex, spent: $spent, '
        'spentBlockIndex: $spentBlockIndex, timestamp: $timestamp)';
  }
}

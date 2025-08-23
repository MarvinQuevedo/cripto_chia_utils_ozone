import 'package:chia_crypto_utils/chia_crypto_utils.dart' as utils;

import 'coin.dart';

class CoinState with utils.Streamable {
  final StreamableCoin coin;
  final int? spentHeight;
  final int? createdHeight;

  CoinState({
    required this.coin,
    this.spentHeight,
    this.createdHeight,
  });

  @override
  utils.Bytes toStreamBytes() {
    final streamWriter = utils.StreamWriter();
    streamWriter.writeStreamable(coin);
    streamWriter.writeOptional(spentHeight, (value) => streamWriter.writeUint32(value));
    streamWriter.writeOptional(createdHeight, (value) => streamWriter.writeUint32(value));
    return streamWriter.toBytes();
  }

  factory CoinState.fromStreamBytes(utils.Bytes bytes) {
    final reader = utils.StreamReader(bytes);
    final coin = reader.readStreamable(StreamableCoin.fromStreamReader);
    final spentHeight = reader.readOptional(reader.readUint32);
    final createdHeight = reader.readOptional(reader.readUint32);
    return CoinState(
      coin: coin,
      spentHeight: spentHeight,
      createdHeight: createdHeight,
    );
  }

  factory CoinState.fromStreamReader(utils.StreamReader reader) {
    final coin = StreamableCoin.fromStreamReader(reader);
    final spentHeight = reader.readOptional(reader.readUint32);
    final createdHeight = reader.readOptional(reader.readUint32);
    return CoinState(coin: coin, spentHeight: spentHeight, createdHeight: createdHeight);
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'coin': coin.toJson(),
      'spentHeight': spentHeight,
      'createdHeight': createdHeight,
    };
  }
}

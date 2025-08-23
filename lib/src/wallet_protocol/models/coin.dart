import 'package:chia_crypto_utils/chia_crypto_utils.dart' as utils;

class StreamableCoin extends utils.CoinPrototype with utils.Streamable {
  final utils.Bytes32 parentCoinInfo;
  final utils.Bytes32 puzzleHash;
  final int amount;

  StreamableCoin({
    required this.parentCoinInfo,
    required this.puzzleHash,
    required this.amount,
  }) : super(
          parentCoinInfo: parentCoinInfo,
          puzzlehash: puzzleHash,
          amount: amount,
        );

  @override
  utils.Bytes toStreamBytes() {
    final streamWriter = utils.StreamWriter();
    streamWriter.writeBytes32(parentCoinInfo);
    streamWriter.writeBytes32(puzzleHash);
    streamWriter.writeUint64(amount);
    return streamWriter.toBytes();
  }

  factory StreamableCoin.fromStreamBytes(utils.Bytes bytes) {
    final reader = utils.StreamReader(bytes);
    final parentCoinInfo = reader.readBytes32();
    final puzzleHash = reader.readBytes32();
    final amount = reader.readUint64();
    return StreamableCoin(
      parentCoinInfo: parentCoinInfo,
      puzzleHash: puzzleHash,
      amount: amount,
    );
  }
  factory StreamableCoin.fromStreamReader(utils.StreamReader reader) {
    final parentCoinInfo = reader.readBytes32();
    final puzzleHash = reader.readBytes32();
    final amount = reader.readUint64();
    return StreamableCoin(parentCoinInfo: parentCoinInfo, puzzleHash: puzzleHash, amount: amount);
  }
}

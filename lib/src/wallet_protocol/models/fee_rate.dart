import 'package:chia_crypto_utils/chia_crypto_utils.dart' as utils;

class FeeRate with utils.Streamable {
  final int mojosPerClvmCost;

  FeeRate({
    required this.mojosPerClvmCost,
  });

  @override
  utils.Bytes toStreamBytes() {
    final streamWriter = utils.StreamWriter();
    streamWriter.writeUint64(mojosPerClvmCost);
    return streamWriter.toBytes();
  }

  factory FeeRate.fromStreamBytes(utils.Bytes bytes) {
    final reader = utils.StreamReader(bytes);
    final mojosPerClvmCost = reader.readUint64();
    return FeeRate(mojosPerClvmCost: mojosPerClvmCost);
  }

  factory FeeRate.fromStreamReader(utils.StreamReader reader) {
    final mojosPerClvmCost = reader.readUint64();
    return FeeRate(mojosPerClvmCost: mojosPerClvmCost);
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'mojosPerClvmCost': mojosPerClvmCost,
    };
  }
}

import 'package:chia_crypto_utils/chia_crypto_utils.dart' as utils;
import 'fee_rate.dart';

class FeeEstimate with utils.Streamable {
  final String? error;
  final int timeTarget;
  final FeeRate estimatedFeeRate;

  FeeEstimate({
    this.error,
    required this.timeTarget,
    required this.estimatedFeeRate,
  });

  @override
  utils.Bytes toStreamBytes() {
    final streamWriter = utils.StreamWriter();
    streamWriter.writeOptional(error, (value) => streamWriter.writeString(value));
    streamWriter.writeUint64(timeTarget);
    streamWriter.writeBytes(estimatedFeeRate.toStreamBytes());
    return streamWriter.toBytes();
  }

  factory FeeEstimate.fromStreamBytes(utils.Bytes bytes) {
    final reader = utils.StreamReader(bytes);
    final error = reader.readOptional(reader.readString);
    final timeTarget = reader.readUint64();
    final estimatedFeeRate = FeeRate.fromStreamReader(reader);
    return FeeEstimate(
      error: error,
      timeTarget: timeTarget,
      estimatedFeeRate: estimatedFeeRate,
    );
  }

  factory FeeEstimate.fromStreamReader(utils.StreamReader reader) {
    final error = reader.readOptional(reader.readString);
    final timeTarget = reader.readUint64();
    final estimatedFeeRate = FeeRate.fromStreamReader(reader);
    return FeeEstimate(
      error: error,
      timeTarget: timeTarget,
      estimatedFeeRate: estimatedFeeRate,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'error': error,
      'timeTarget': timeTarget,
      'estimatedFeeRate': estimatedFeeRate.toJson(),
    };
  }
}

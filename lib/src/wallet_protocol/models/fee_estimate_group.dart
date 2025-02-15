import 'package:chia_crypto_utils/chia_crypto_utils.dart' as utils;
import 'fee_estimate.dart';

class FeeEstimateGroup with utils.Streamable {
  final String? error;
  final List<FeeEstimate> estimates;

  FeeEstimateGroup({
    this.error,
    required this.estimates,
  });

  @override
  utils.Bytes toStreamBytes() {
    final streamWriter = utils.StreamWriter();
    streamWriter.writeOptional(error, (value) => streamWriter.writeString(value));
    streamWriter.writeList(
      estimates.map((estimate) => estimate.toStreamBytes()).toList(),
    );
    return streamWriter.toBytes();
  }

  factory FeeEstimateGroup.fromStreamBytes(utils.Bytes bytes) {
    final reader = utils.StreamReader(bytes);
    final error = reader.readOptional(reader.readString);
    final estimates = reader.readList<FeeEstimate>(
      (reader) => FeeEstimate.fromStreamReader(reader),
    );
    return FeeEstimateGroup(
      error: error,
      estimates: estimates,
    );
  }

  factory FeeEstimateGroup.fromStreamReader(utils.StreamReader reader) {
    final error = reader.readOptional(reader.readString);
    final estimates = reader.readList<FeeEstimate>(
      (reader) => FeeEstimate.fromStreamReader(reader),
    );
    return FeeEstimateGroup(
      error: error,
      estimates: estimates,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'error': error,
      'estimates': estimates.map((estimate) => estimate.toJson()).toList(),
    };
  }
}

import 'package:chia_crypto_utils/chia_crypto_utils.dart';

import 'index.dart';

class ClassgroupElement with Streamable {
  final Bytes100 data;

  ClassgroupElement({required this.data});
  @override
  Map<String, dynamic> toJson() {
    return {
      'data': data.toHex(),
    };
  }

  @override
  Bytes toStreamBytes() {
    final streamWriter = StreamWriter();
    streamWriter.writeBytes(data);
    return streamWriter.toBytes();
  }

  factory ClassgroupElement.fromStreamBytes(Bytes bytes) {
    final streamReader = StreamReader(bytes);
    return ClassgroupElement(data: streamReader.readBytes100());
  }

  factory ClassgroupElement.fromStreamReader(StreamReader reader) {
    return ClassgroupElement(data: reader.readBytes100());
  }
}

/**pub struct VDFInfo {
    challenge: Bytes32,
    number_of_iterations: u64,
    output: ClassgroupElement,
}  */

class VDFInfo with Streamable {
  final Bytes32 challenge;
  final int numberOfIterations;
  final ClassgroupElement output;

  VDFInfo({required this.challenge, required this.numberOfIterations, required this.output});

  @override
  Map<String, dynamic> toJson() {
    return {
      'challenge': challenge.toHex(),
      'numberOfIterations': numberOfIterations,
      'output': output.toJson(),
    };
  }

  @override
  Bytes toStreamBytes() {
    final streamWriter = StreamWriter();
    streamWriter.writeBytes32(challenge);
    streamWriter.writeUint64(numberOfIterations);
    streamWriter.writeStreamable(output);
    return streamWriter.toBytes();
  }

  factory VDFInfo.fromStreamBytes(Bytes bytes) {
    final streamReader = StreamReader(bytes);
    return VDFInfo(
      challenge: streamReader.readBytes32(),
      numberOfIterations: streamReader.readUint64(),
      output: streamReader.readStreamable(ClassgroupElement.fromStreamReader),
    );
  }

  factory VDFInfo.fromStreamReader(StreamReader reader) {
    return VDFInfo(
      challenge: reader.readBytes32(),
      numberOfIterations: reader.readUint64(),
      output: reader.readStreamable(ClassgroupElement.fromStreamReader),
    );
  }
}

import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class VDFProof with Streamable {
  final int witnessType;
  final Bytes witness;
  final bool normalizedToIdentity;

  VDFProof({
    required this.witnessType,
    required this.witness,
    required this.normalizedToIdentity,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'witnessType': witnessType,
      'witness': witness.toHex(),
      'normalizedToIdentity': normalizedToIdentity,
    };
  }

  @override
  Bytes toStreamBytes() {
    final streamWriter = StreamWriter();
    streamWriter.writeUint32(witnessType);
    streamWriter.writeBytes(witness);
    streamWriter.writeBool(normalizedToIdentity);
    return streamWriter.toBytes();
  }

  factory VDFProof.fromStreamBytes(Bytes bytes) {
    final streamReader = StreamReader(bytes);
    return VDFProof(
      witnessType: streamReader.readUint32(),
      witness: streamReader.readBytes(),
      normalizedToIdentity: streamReader.readBool(),
    );
  }

  factory VDFProof.fromStreamReader(StreamReader reader) {
    return VDFProof(
      witnessType: reader.readUint32(),
      witness: reader.readBytes(),
      normalizedToIdentity: reader.readBool(),
    );
  }
}

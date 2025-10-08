import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class ChiaProtocolMessage with Streamable {
  final ProtocolMessageTypes msgType;
  final int? id;
  final Bytes data;

  ChiaProtocolMessage({
    required this.msgType,
    this.id,
    required this.data,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': msgType.value,
      'id': id,
      'data': data.toHex(),
    };
  }

  @override
  Bytes toStreamBytes() {
    final stream = StreamWriter();
    stream.writeUint32(msgType.value);
    stream.writeUint32(id != null ? 1 : 0);
    stream.writeUint16(id ?? 0);
    stream.writeBytes(data);
    return stream.toBytes();
  }

  factory ChiaProtocolMessage.fromStreamBytes(Bytes bytes) {
    final stream = StreamReader(bytes);
    final type = ProtocolMessageTypes.values[stream.readUint32()];
    final id = stream.readUint16();
    final data = stream.readBytes();
    return ChiaProtocolMessage(msgType: type, id: id, data: Bytes(data));
  }
}

enum NodeType {
  fullNode(1),
  harvester(2),
  farmer(3),
  timeLord(4),
  introducer(5),
  wallet(6),
  dataLayer(7);

  final int value;
  const NodeType(this.value);

  // Factory constructor to create from value
  factory NodeType.fromValue(int value) {
    return NodeType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => throw ArgumentError('Invalid NodeType value: $value'),
    );
  }
}

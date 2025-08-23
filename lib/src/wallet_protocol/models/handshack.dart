import 'dart:typed_data';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/wallet_protocol/models/message.dart';
import 'package:tuple/tuple.dart';

class Handshake with Streamable {
  /// Network id, usually the genesis challenge of the blockchain
  final String networkId;

  /// Protocol version to determine which messages the peer supports
  final String protocolVersion;

  /// Version of the software, to debug and determine feature support
  final String softwareVersion;

  /// Which port the server is listening on
  final int serverPort;

  /// NodeType (full node, wallet, farmer, etc.)
  final int nodeType;

  /// Key value dict to signal support for additional capabilities/features
  final List<Tuple2<int, String>> capabilities;

  const Handshake({
    required this.networkId,
    required this.protocolVersion,
    required this.softwareVersion,
    required this.serverPort,
    required this.nodeType,
    required this.capabilities,
  });

  factory Handshake.fromJson(Map<String, dynamic> json) {
    return Handshake(
      networkId: json['network_id'] as String,
      protocolVersion: json['protocol_version'] as String,
      softwareVersion: json['software_version'] as String,
      serverPort: json['server_port'] as int,
      nodeType: NodeType.values[json['node_type'] as int].index,
      capabilities: (json['capabilities'] as List)
          .map((e) => Tuple2<int, String>(e[0] as int, e[1] as String))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'network_id': networkId,
        'protocol_version': protocolVersion,
        'software_version': softwareVersion,
        'server_port': serverPort,
        'node_type': nodeType,
        'capabilities': capabilities.map((e) => [e.item1, e.item2]).toList(),
      };

  @override
  Bytes toStreamBytes() {
    final streamWriter = StreamWriter();
    streamWriter.writeString(networkId);
    streamWriter.writeString(protocolVersion);
    streamWriter.writeString(softwareVersion);
    streamWriter.writeUint16(serverPort);
    streamWriter.writeUint8(nodeType);

    streamWriter.writeUint32(capabilities.length);

    for (var capability in capabilities) {
      streamWriter.writeUint16(capability.item1);
      streamWriter.writeString(capability.item2);
    }
    return streamWriter.toBytes();
  }

  factory Handshake.fromBytes(Bytes bytes) {
    final reader = StreamReader(bytes);
    final networkId = reader.readString();
    final protocolVersion = reader.readString();
    final softwareVersion = reader.readString();
    final serverPort = reader.readUint16();
    final nodeTypeRaw = reader.readUint8();
    final capabilities = reader
        .readTupleList<Uint16List, String>()
        .map((e) => Tuple2(e.item1 as int, e.item2 as String))
        .toList();
    return Handshake(
      networkId: networkId,
      protocolVersion: protocolVersion,
      softwareVersion: softwareVersion,
      serverPort: serverPort,
      nodeType: nodeTypeRaw,
      capabilities: List<Tuple2<int, String>>.from(capabilities),
    );
  }
}

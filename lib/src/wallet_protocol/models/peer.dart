import 'dart:async';
import 'dart:io';
import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:tuple/tuple.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class PeerOptions {
  final double rateLimitFactor;

  const PeerOptions({this.rateLimitFactor = 0.6});
}

class Peer {
  final WebSocketChannel connection;
  final InternetAddress address;
  final int port;
  DateTime lastMessage;
  int bytesRead;
  int bytesWritten;
  int? peerServerPort;
  int? nodeType;
  String protocolVersion;
  String softwareVersion;
  String networkId;
  List<Tuple2<int, String>> capabilities;
  bool isConnected;

  Peer({
    required this.connection,
    required this.address,
    required this.port,
    required this.protocolVersion,
    required this.softwareVersion,
    required this.networkId,
    required this.capabilities,
    this.peerServerPort,
    this.nodeType,
    DateTime? lastMessage,
    int? bytesRead,
    int? bytesWritten,
    bool? isConnected,
  })  : lastMessage = lastMessage ?? DateTime.now(),
        bytesRead = bytesRead ?? 0,
        bytesWritten = bytesWritten ?? 0,
        isConnected = isConnected ?? true;

  Future<void> sendMessage(ChiaProtocolMessage message) async {
    if (!isConnected) {
      throw Exception('Peer is not connected');
    }
    final messageBytes = message.toStreamBytes();
    bytesWritten += messageBytes.length;
    connection.sink.add(messageBytes.byteList);
    lastMessage = DateTime.now();
  }

  Future<void> close() async {
    isConnected = false;
    await connection.sink.close();
  }

  void updateLastMessage() {
    lastMessage = DateTime.now();
  }

  bool isStale({Duration timeout = const Duration(minutes: 5)}) {
    return DateTime.now().difference(lastMessage) > timeout;
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address.address,
      'port': port,
      'peerServerPort': peerServerPort,
      'nodeType': nodeType,
      'protocolVersion': protocolVersion,
      'softwareVersion': softwareVersion,
      'networkId': networkId,
      'capabilities': capabilities.map((c) => [c.item1, c.item2]).toList(),
      'lastMessage': lastMessage.toIso8601String(),
      'bytesRead': bytesRead,
      'bytesWritten': bytesWritten,
      'isConnected': isConnected,
    };
  }
}

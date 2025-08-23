import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:tuple/tuple.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'models/peer.dart';
import 'models/network.dart';
import 'models/message.dart';
import 'models/handshack.dart';

class WalletProtocolClient {
  final PeerNetwork network;
  final ClientState state;
  final String protocolVersion;
  final String softwareVersion;
  final int nodeType;
  final List<Tuple2<int, String>> capabilities;

  WalletProtocolClient._({
    required this.network,
    required this.protocolVersion,
    required this.softwareVersion,
    required this.nodeType,
    required this.capabilities,
  }) : state = ClientState();

  factory WalletProtocolClient({
    required PeerNetwork network,
    String protocolVersion = '0.0.37',
    String softwareVersion = '0.0.0',
    int nodeType = 1, // NodeType.wallet
    List<Tuple2<int, String>> capabilities = const [
      Tuple2(1, '1'),
      Tuple2(2, '1'),
      Tuple2(3, '1'),
    ],
  }) {
    return WalletProtocolClient._(
      network: network,
      protocolVersion: protocolVersion,
      softwareVersion: softwareVersion,
      nodeType: nodeType,
      capabilities: capabilities,
    );
  }

  String get networkId => network.id;

  PeerNetwork get getNetwork => network;

  Future<Stream<ChiaProtocolMessage>> connect(
    InternetAddress socketAddr,
    PeerOptions options,
    String certPath,
    String keyPath, {
    int? port,
  }) async {
    if (state.isBanned(socketAddr)) {
      throw ClientError('BannedPeer');
    }

    final uri = Uri.parse('wss://${socketAddr.address}:${port ?? network.defaultPort}');
    final context = SecurityContext();

    try {
      context.useCertificateChain(certPath);
      context.usePrivateKey(keyPath);
    } catch (e) {
      print('Error loading certificate or key: $e');
      throw ClientError('CertificateError: $e');
    }

    SecureSocket? socket;
    WebSocket? webSocket;
    IOWebSocketChannel? wsChannel;
    final messageController = StreamController<ChiaProtocolMessage>.broadcast();

    try {
      socket = await SecureSocket.connect(
        uri.host,
        uri.port,
        onBadCertificate: (_) => true,
        context: context,
      );

      webSocket = WebSocket.fromUpgradedSocket(
        socket,
        serverSide: false,
        protocol: 'ws',
      );

      wsChannel = IOWebSocketChannel(webSocket);

      final peer = Peer(
        connection: wsChannel,
        address: socketAddr,
        port: port ?? network.defaultPort,
        protocolVersion: protocolVersion,
        softwareVersion: softwareVersion,
        networkId: networkId,
        capabilities: capabilities,
      );

      state.peers[socketAddr] = peer;

      // Handle incoming messages
      wsChannel.stream.listen(
        (data) {
          if (data is! List<int>) {
            print('Received unexpected message type: ${data.runtimeType}');
            return;
          }

          try {
            final message = ChiaProtocolMessage.fromStreamBytes(Bytes(data));
            peer.bytesRead += data.length;
            peer.updateLastMessage();

            if (message.msgType == ProtocolMessageTypes.handshake) {
              final handshake = Handshake.fromBytes(Bytes(message.data));
              _handleHandshake(peer, handshake);
            }

            messageController.add(message);
          } catch (e) {
            print('Error processing message: $e');
            messageController.addError(e);
          }
        },
        onError: (error) {
          print('WebSocket error: $error');
          _cleanupConnection(socketAddr, socket, webSocket, wsChannel, messageController);
          messageController.addError(error);
        },
        onDone: () {
          print('WebSocket closed');
          _cleanupConnection(socketAddr, socket, webSocket, wsChannel, messageController);
        },
      );

      // Send handshake
      final handshake = Handshake(
        networkId: networkId,
        protocolVersion: protocolVersion,
        softwareVersion: softwareVersion,
        serverPort: 0,
        nodeType: nodeType,
        capabilities: capabilities,
      );

      await peer.sendMessage(ChiaProtocolMessage(
        msgType: ProtocolMessageTypes.handshake,
        id: null,
        data: handshake.toStreamBytes(),
      ));

      return messageController.stream;
    } catch (e) {
      _cleanupConnection(socketAddr, socket, webSocket, wsChannel, messageController);
      throw ClientError('ConnectionError: $e');
    }
  }

  void _cleanupConnection(
    InternetAddress socketAddr,
    SecureSocket? socket,
    WebSocket? webSocket,
    IOWebSocketChannel? wsChannel,
    StreamController<ChiaProtocolMessage> messageController,
  ) {
    state.disconnect(socketAddr);
    try {
      wsChannel?.sink.close();
      webSocket?.close();
      socket?.close();
    } catch (e) {
      print('Error during cleanup: $e');
    }
    messageController.close();
  }

  void _handleHandshake(Peer peer, Handshake message) {
    peer.protocolVersion = message.protocolVersion;
    peer.softwareVersion = message.softwareVersion;
    peer.nodeType = message.nodeType;
    peer.capabilities = message.capabilities;
    peer.peerServerPort = message.serverPort;
  }
}

class ClientState {
  final Map<InternetAddress, Peer> peers;
  final Map<InternetAddress, int> bannedPeers;
  final Set<InternetAddress> trustedPeers;

  ClientState()
      : peers = {},
        bannedPeers = {},
        trustedPeers = {};

  Iterable<Peer> getPeers() {
    return peers.values;
  }

  bool disconnect(InternetAddress ipAddr) {
    final peer = peers.remove(ipAddr);
    if (peer != null) {
      peer.close();
      return true;
    }
    return false;
  }

  bool isBanned(InternetAddress ipAddr) {
    return bannedPeers.containsKey(ipAddr);
  }

  bool isTrusted(InternetAddress ipAddr) {
    return trustedPeers.contains(ipAddr);
  }

  bool ban(InternetAddress ipAddr) {
    if (isTrusted(ipAddr)) {
      return false;
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    disconnect(ipAddr);
    final existed = bannedPeers.containsKey(ipAddr);
    bannedPeers.putIfAbsent(ipAddr, () => timestamp);
    return !existed;
  }

  bool unban(InternetAddress ipAddr) {
    return bannedPeers.remove(ipAddr) != null;
  }

  bool trust(InternetAddress ipAddr) {
    final result = trustedPeers.add(ipAddr);
    bannedPeers.remove(ipAddr);
    return result;
  }

  bool untrust(InternetAddress ipAddr) {
    return trustedPeers.remove(ipAddr);
  }
}

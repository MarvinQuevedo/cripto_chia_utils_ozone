// cripto_chia_utils_ozone/lib/src/wallet_protocol/models/connect.dart

import 'dart:async';
import 'dart:io';
import 'package:chia_crypto_utils/src/wallet_protocol/models/handshack.dart';
import 'package:chia_crypto_utils/src/wallet_protocol/models/message.dart';
import 'package:chia_crypto_utils/src/wallet_protocol/models/peer.dart';
import 'package:chia_crypto_utils/src/wallet_protocol/models/protocol_message_type.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:tuple/tuple.dart';
import 'package:logging/logging.dart';

import 'client_error.dart';

class ChiaWebSocket {
  final WebSocketChannel channel;
  final Logger _logger = Logger('ChiaWebSocket');
  final String networkId;
  final PeerOptions options;

  ChiaWebSocket._({
    required this.channel,
    required this.networkId,
    required this.options,
  });

  static Future<ChiaWebSocket> connect({
    required String url,
    required String networkId,
    required PeerOptions options,
    String? certPath,
    String? keyPath,
  }) async {
    final uri = Uri.parse(url);
    WebSocketChannel channel;

    // Create a secure WebSocket similar to Peer class
    channel = await _createSecureWebSocket(
      uri,
      allowSelfSigned: true,
      certPath: certPath,
      keyPath: keyPath,
    );

    return ChiaWebSocket._(
      channel: channel,
      networkId: networkId,
      options: options,
    );
  }

  // Helper method to create a secure WebSocket with option to allow self-signed certificates
  static Future<WebSocketChannel> _createSecureWebSocket(Uri uri,
      {bool allowSelfSigned = true, String? certPath, String? keyPath}) async {
    if (allowSelfSigned) {
      // Create a SecurityContext with the provided certificate and key if available
      final context = SecurityContext();

      if (certPath != null && keyPath != null) {
        try {
          context.useCertificateChain(certPath);
          context.usePrivateKey(keyPath);
        } catch (e) {
          print('Error loading certificate or key: $e');
        }
      }

      // Connect to the host directly
      final socket = await SecureSocket.connect(
        uri.host,
        uri.port,
        onBadCertificate: (_) => true,
        context: context,
      );

      // Create a WebSocket connection manually
      final webSocket = WebSocket.fromUpgradedSocket(
        socket,
        serverSide: false,
      );

      return IOWebSocketChannel(webSocket);
    } else {
      // Use the standard connection method if self-signed certs aren't allowed
      return WebSocketChannel.connect(uri);
    }
  }

  Future<Tuple2<ChiaWebSocket, StreamController<ChiaProtocolMessage>>> initConnection() async {
    try {
      await channel.ready;
      _logger.info('Connected to WebSocket');

      final controller = StreamController<ChiaProtocolMessage>();

      // Setup handshake
      final handshake = Handshake(
        networkId: networkId,
        protocolVersion: '0.0.37',
        softwareVersion: '0.0.0',
        serverPort: 0,
        nodeType: NodeType.wallet.value,
        capabilities: [
          Tuple2(1, '1'),
          Tuple2(2, '1'),
          Tuple2(3, '1'),
        ],
      );

      final firstMessageCompleter = Completer<ChiaProtocolMessage>();

      // Listen for response
      channel.stream.listen((dynamic data) async {
        final message = ChiaProtocolMessage.fromStreamBytes(data);
        firstMessageCompleter.complete(message);
        print('message: ${message.toJson()}');

        if (message.msgType != ProtocolMessageTypes.handshake.value) {
          throw ClientErrors.invalidResponse(
            [ProtocolMessageTypes.handshake],
            message.msgType,
          );
        }

        final responseHandshake = Handshake.fromBytes(message.data);

        if (responseHandshake.nodeType != NodeType.fullNode.value) {
          throw ClientErrors.wrongNodeType(
            NodeType.fullNode,
            NodeType.values[responseHandshake.nodeType],
          );
        }

        if (responseHandshake.networkId != networkId) {
          throw ClientErrors.wrongNetwork(
            networkId,
            responseHandshake.networkId,
          );
        }

        controller.add(message);
      });

      // Send handshake
      send(handshake);

      final message = await firstMessageCompleter.future;
      print('message: ${message.toJson()}');

      return Tuple2(this, controller);
    } catch (e) {
      _logger.severe('Failed to connect: $e');
      rethrow;
    }
  }

  void listen(void Function(dynamic) onData) {
    channel.stream.listen(
      onData,
      onError: (error) => _logger.severe('Error: $error'),
      onDone: () => _logger.info('Connection closed'),
    );
  }

  void send(dynamic data) {
    if (data is Handshake) {
      final bytes = data.toStreamBytes();
      print('send bytes: ${bytes.toHex()}');
      channel.sink.add(bytes.byteList);
    } else {
      channel.sink.add(data);
    }
  }

  Future<void> close() async {
    await channel.sink.close();
  }
}

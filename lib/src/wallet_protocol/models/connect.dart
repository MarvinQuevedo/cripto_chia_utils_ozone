// cripto_chia_utils_ozone/lib/src/wallet_protocol/models/connect.dart

import 'dart:async';
import 'package:chia_crypto_utils/src/wallet_protocol/models/handshack.dart';
import 'package:chia_crypto_utils/src/wallet_protocol/models/message.dart';
import 'package:chia_crypto_utils/src/wallet_protocol/models/misc.dart';
import 'package:chia_crypto_utils/src/wallet_protocol/models/protocol_message_type.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:tuple/tuple.dart';
import 'package:logging/logging.dart';

import 'client_error.dart';

class ChiaWebSocket {
  final WebSocketChannel channel;
  final Logger _logger = Logger('ChiaWebSocket');
  final String networkId;
  final PeerOptions options;

  ChiaWebSocket({
    required String url,
    required this.networkId,
    required this.options,
  }) : channel = WebSocketChannel.connect(Uri.parse(url));

  Future<Tuple2<ChiaWebSocket, StreamController<ChiaProtocolMessage>>> connect() async {
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

      // Send handshake
      send(handshake);

      // Listen for response
      channel.stream.listen((dynamic data) async {
        final message = ChiaProtocolMessage.fromStreamBytes(data);

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
      channel.sink.add(bytes);
    } else {
      channel.sink.add(data);
    }
  }

  Future<void> close() async {
    await channel.sink.close();
  }
}

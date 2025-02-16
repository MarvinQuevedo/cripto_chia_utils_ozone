import 'dart:async';
import 'dart:io';
import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/wallet_protocol/models/client_error.dart';
import 'package:chia_crypto_utils/src/wallet_protocol/models/message.dart';
import 'package:chia_crypto_utils/src/wallet_protocol/models/rate_limit.dart';
import 'package:chia_crypto_utils/src/wallet_protocol/models/request_map.dart';
import 'package:chia_crypto_utils/src/wallet_protocol/models/wallet_protocol_models.dart';
import 'package:tuple/tuple.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:synchronized/synchronized.dart';

class PeerOptions {
  final double rateLimitFactor;

  PeerOptions({this.rateLimitFactor = 0.6});
}

class Peer {
  final WebSocketChannel _ws;
  final StreamController<ChiaProtocolMessage> _messageController;
  final RequestMap _requests;
  final InternetAddress address;
  final int port;
  final RateLimiter _outboundRateLimiter;
  final _rateLimiterLock = Lock();

  Peer._(
    this._ws,
    this._messageController,
    this._requests,
    this.address,
    this.port,
    this._outboundRateLimiter,
  ) {
    _handleInboundMessages();
  }

  static Future<Tuple2<Peer, Stream<ChiaProtocolMessage>>> connect(
    String host,
    int port,
    PeerOptions options,
  ) async {
    final uri = Uri.parse('wss://$host:$port/ws');
    final ws = WebSocketChannel.connect(uri);

    final address = await InternetAddress.lookup(host).then((addresses) => addresses.first);

    return _createPeer(
      ws,
      address,
      port,
      options,
    );
  }

  static Future<Tuple2<Peer, Stream<ChiaProtocolMessage>>> connectFullUri(
    String uri,
    PeerOptions options,
  ) async {
    final ws = WebSocketChannel.connect(Uri.parse(uri));
    final host = uri.split(':')[1].replaceAll('//', '');
    final port = int.parse(uri.split(':')[2].split('/')[0]);

    final address = await InternetAddress.lookup(host).then((addresses) => addresses.first);

    return _createPeer(ws, address, port, options);
  }

  static Future<Tuple2<Peer, Stream<ChiaProtocolMessage>>> _createPeer(
    WebSocketChannel ws,
    InternetAddress address,
    int port,
    PeerOptions options,
  ) async {
    final messageController = StreamController<ChiaProtocolMessage>.broadcast();
    final requests = RequestMap();
    final rateLimiter = RateLimiter(
      incoming: false,
      resetSeconds: 60,
      limitFactor: options.rateLimitFactor,
      rateLimits: RateLimits.v2RateLimits,
    );

    final peer = Peer._(
      ws,
      messageController,
      requests,
      address,
      port,
      rateLimiter,
    );

    return Tuple2(peer, messageController.stream);
  }

  Future<void> sendTransaction(SpendBundle spendBundle) async {
    await requestInfallible(
      SendTransaction(spendBundle),
      fromBytes: (bytes) => SendTransaction.fromBytes(
        Bytes(bytes),
      ),
    );
  }

  // ... Other request methods following similar pattern ...

  Future<void> send<T extends ChiaProtocolMessage>(T body) async {
    await _sendRaw(ChiaProtocolMessage(
      msgType: body.msgType,
      id: null,
      data: body.toStreamBytes(),
    ));
  }

  Future<R> requestInfallible<R extends ChiaProtocolMessage, B extends ChiaProtocolMessage>(B body,
      {required R Function(List<int>) fromBytes}) async {
    final message = await _requestRaw(body);
    if (message.msgType != body.msgType) {
      throw ClientErrors.invalidResponse([body.msgType], message.msgType);
    }
    return fromBytes(message.data);
  }

  Future<ChiaProtocolMessage> _requestRaw<T extends ChiaProtocolMessage>(T body) async {
    final completer = Completer<ChiaProtocolMessage>();
    final id = await _requests.insert(
      Request(
        completer,
        () async {
          await _rateLimiterLock.synchronized(() {
            return _outboundRateLimiter.releasePermit();
          });
        },
      ),
    );

    await _sendRaw(ChiaProtocolMessage(
      msgType: body.msgType,
      id: id,
      data: body.toStreamBytes(),
    ));

    return completer.future;
  }

  Future<void> _sendRaw(ChiaProtocolMessage message) async {
    while (true) {
      final canSend = await _rateLimiterLock.synchronized(() {
        return _outboundRateLimiter.handleMessage(message);
      });

      if (!canSend) {
        await Future.delayed(Duration(seconds: 1));
        continue;
      }

      _ws.sink.add(message.toStreamBytes());
      break;
    }
  }

  void _handleInboundMessages() {
    _ws.stream.listen(
      (data) {
        if (data is! List<int>) {
          print('Received unexpected message type: ${data.runtimeType}');
          return;
        }

        final message = ChiaProtocolMessage.fromStreamBytes(Bytes(data));

        if (message.id == null) {
          _messageController.add(message);
          return;
        }

        final request = _requests.remove(message.id!);
        if (request == null) {
          print('Received message with untracked id ${message.id}');
          return;
        }

        request.setAsCompleted(message);
      },
      onError: (error) {
        print('WebSocket error: $error');
      },
      onDone: () {
        _messageController.close();
      },
    );
  }

  Future<void> close() async {
    await _ws.sink.close();
    await _messageController.close();
  }
}

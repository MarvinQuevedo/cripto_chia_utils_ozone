// client_error.dart

import 'package:chia_crypto_utils/src/wallet_protocol/models/message.dart';
import 'package:chia_crypto_utils/src/wallet_protocol/models/protocol_message_type.dart';

/// Represents various client-side errors that can occur during Chia operations
class ClientError implements Exception {
  final String message;
  final ClientErrorType type;
  final dynamic originalError;

  ClientError(this.type, {this.message = '', this.originalError});

  @override
  String toString() => '${type.name}: $message';
}

/// Enum representing different types of client errors
enum ClientErrorType {
  ssl('SSL error'),
  unsupportedTls('TLS method is not supported'),
  streamable('Streamable error'),
  webSocket('WebSocket error'),
  nativeTls('Native TLS error'),
  rustls('Rustls error'),
  missingPkcs8Key('Missing pkcs8 private key'),
  missingCa('Missing CA cert'),
  unexpectedMessage('Unexpected message received'),
  invalidResponse('Invalid response type'),
  recv('Failed to receive message'),
  io('IO error'),
  missingHandshake('Missing response during handshake'),
  wrongNodeType('Wrong node type'),
  wrongNetwork('Wrong network'),
  bannedPeer('The peer is banned');

  final String description;
  const ClientErrorType(this.description);
}

/// Factory methods to create specific error instances
class ClientErrors {
  static ClientError ssl(dynamic error) =>
      ClientError(ClientErrorType.ssl, message: error.toString(), originalError: error);

  static ClientError unsupportedTls() => ClientError(ClientErrorType.unsupportedTls);

  static ClientError streamable(dynamic error) =>
      ClientError(ClientErrorType.streamable, message: error.toString(), originalError: error);

  static ClientError webSocket(dynamic error) =>
      ClientError(ClientErrorType.webSocket, message: error.toString(), originalError: error);

  static ClientError unexpectedMessage(ProtocolMessageTypes type) => ClientError(
        ClientErrorType.unexpectedMessage,
        message: 'Unexpected message type: ${type.toString()}',
      );

  static ClientError invalidResponse(
          List<ProtocolMessageTypes> expected, ProtocolMessageTypes received) =>
      ClientError(
        ClientErrorType.invalidResponse,
        message: 'Expected ${expected.toString()}, found: ${received.toString()}',
      );

  static ClientError wrongNodeType(NodeType expected, NodeType found) => ClientError(
        ClientErrorType.wrongNodeType,
        message: 'Expected ${expected.toString()}, found: ${found.toString()}',
      );

  static ClientError wrongNetwork(String expected, String found) => ClientError(
        ClientErrorType.wrongNetwork,
        message: 'Expected $expected, found: $found',
      );

  static ClientError bannedPeer() => ClientError(ClientErrorType.bannedPeer);
}

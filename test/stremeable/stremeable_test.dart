import 'package:chia_crypto_utils/src/wallet_protocol/models/handshack.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';
import 'package:tuple/tuple.dart';

void main() {
  final handshake = Handshake(
    networkId: "mainnet",
    protocolVersion: "1.0.0",
    softwareVersion: "0.0.0",
    serverPort: 8444,
    nodeType: 0,
    capabilities: [
      Tuple2(5, "00000"),
    ],
  );

  final handshakeBytes = handshake.toStreamBytes();
  print("handshake bytes: $handshakeBytes");

  final expectedBytesHex =
      '000000076d61696e6e657400000005312e302e3000000005302e302e3020fc00000000010005000000053030303030';

  test('compare streamable and stream bytes', () {
    expect(
      handshakeBytes.toHex(),
      expectedBytesHex,
    );
  });

  test("Test restore from bytes", () {
    final parsedHandshake = Handshake.fromBytes(handshakeBytes);
    print("parsed handshake: $parsedHandshake");
    expect(parsedHandshake.networkId, "mainnet");
    expect(parsedHandshake.protocolVersion, "1.0.0");
    expect(parsedHandshake.softwareVersion, "0.0.0");
    expect(parsedHandshake.serverPort, 8444);
    expect(parsedHandshake.nodeType, 0);
    expect(parsedHandshake.capabilities, [Tuple2(5, "00000")]);
  });
}

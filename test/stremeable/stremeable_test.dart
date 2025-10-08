import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';
import 'package:tuple/tuple.dart';

void main() {
  final handshake = Handshake(
    networkId: "mainnet",
    protocolVersion: "1.0.0",
    softwareVersion: "0.0.0",
    serverPort: 8444,
    nodeType: 2,
    capabilities: [
      Tuple2(5, "15784"),
    ],
  );

  final handshakeBytes = handshake.toStreamBytes();
  print("handshake bytes: $handshakeBytes");

  final expectedBytesHex =
      '000000076d61696e6e657400000005312e302e3000000005302e302e3020fc02000000010005000000053135373834';

  test('(Handshake) compare streamable and stream bytes', () {
    expect(
      handshakeBytes.toHex(),
      expectedBytesHex,
    );
  });

  test("(Handshake) Test restore from bytes", () {
    final parsedHandshake = Handshake.fromBytes(handshakeBytes);
    print("parsed handshake: $parsedHandshake");
    expect(parsedHandshake.networkId, handshake.networkId);
    expect(parsedHandshake.protocolVersion, handshake.protocolVersion);
    expect(parsedHandshake.softwareVersion, handshake.softwareVersion);
    expect(parsedHandshake.serverPort, handshake.serverPort);
    expect(parsedHandshake.nodeType, handshake.nodeType);
    expect(parsedHandshake.capabilities, handshake.capabilities);
  });

  final coinState = CoinState(
    coin: StreamableCoin(
      amount: 999,
      puzzleHash:
          Bytes32.fromHex("0bd55666b6be0214263e0ebdc632f526393b1ddd920774934947b917d37bda56"),
      parentCoinInfo:
          Bytes32.fromHex("69543c910a6982a08ae446742ec9b8655ce433617cfe772120881dda2c7fea2a"),
    ),
    spentHeight: 10,
    createdHeight: 5,
  );

  final coinStateBytes = coinState.toStreamBytes().toHex();

  print("coin state bytes: $coinStateBytes");

  final coinStateHex =
      '69543c910a6982a08ae446742ec9b8655ce433617cfe772120881dda2c7fea2a0bd55666b6be0214263e0ebdc632f526393b1ddd920774934947b917d37bda5600000000000003e7010000000a0100000005';

  test("(CoinState) Test streamable and stream bytes", () {
    expect(coinStateBytes, coinStateHex);
  });

  test("(CoinState) Test restore from bytes", () {
    final parsedCoinState = CoinState.fromStreamBytes(Bytes.fromHex(coinStateHex));
    print("parsed coin state: $parsedCoinState");
    expect(parsedCoinState.coin.amount, 999);
    expect(parsedCoinState.coin.puzzleHash.toHex(),
        "0bd55666b6be0214263e0ebdc632f526393b1ddd920774934947b917d37bda56");
    expect(parsedCoinState.coin.parentCoinInfo.toHex(),
        "69543c910a6982a08ae446742ec9b8655ce433617cfe772120881dda2c7fea2a");

    expect(parsedCoinState.spentHeight, 10);
    expect(parsedCoinState.createdHeight, 5);
  });

  final spendBundlHex =
      "00000001682714f24da13091f3c34a0f57dce0ab04abf4eeb6560a585108af7a234a8db96752e93ab550bd297f0f2be9f131c9e23d024cf1e183f6b66d50c32bc17e13aa000000e1d4867d71ff02ffff01ff02ffff01ff02ffff03ff0bffff01ff02ffff03ffff09ff05ffff1dff0bffff1effff0bff0bffff02ff06ffff04ff02ffff04ff17ff8080808080808080ffff01ff02ff17ff2f80ffff01ff088080ff0180ffff01ff04ffff04ff04ffff04ff05ffff04ffff02ff06ffff04ff02ffff04ff17ff80808080ff80808080ffff02ff17ff2f808080ff0180ffff04ffff01ff32ff02ffff03ffff07ff0580ffff01ff0bffff0102ffff02ff06ffff04ff02ffff04ff09ff80808080ffff02ff06ffff04ff02ffff04ff0dff8080808080ffff01ff0bffff0101ff058080ff0180ff018080ffff04ffff01b081d32b654af21a50150893416f30cf654f13f049b2ffd0af4f5306c867c16556a541101aff8fcd20b38123bb22c4c3d2ff018080ff80ffff01ffff33ffa0103076e23bbc3e51ab0ebc521a2b87d9ee5068168530b4e4556b5ab734405e67ff8600e8d4a51000ff8080ffff33ffa0d9833532bd704a1e95652fc4f9f79137aa8dcc001187ab4a060173a0c0885d86ff841dcd6500ffff894f5a4f4e455f4645458080ffff33ffa0eebcd30abf5eff065e0171d96808377a579961b36f0806b848fc1298a09f15b2ff8502bdfbbbff80ffff34ff8459682f0080ffff3cffa05babdf9546549e231fcc8452863948f32fa36f04989aa035d2cee20bf5dce0958080ff8080a10055f843c7845cce56d20b07140e4ae1b6fc138a53affd9ba36f3452503f948872b7719fbbe465b6ad9263688eaa3714e1dfc4b2076b044ed5da39c0f06650be0bc0a09d6dac2dd70f722e4c27b0bc6b7067e4447849be90f16886127c7972";

  final spendBundle = SpendBundle(
      coinSpends: [
        CoinSpend(
          coin: StreamableCoin(
            amount: 969933225329,
            puzzleHash:
                Bytes32.fromHex("6752e93ab550bd297f0f2be9f131c9e23d024cf1e183f6b66d50c32bc17e13aa"),
            parentCoinInfo:
                Bytes32.fromHex("682714f24da13091f3c34a0f57dce0ab04abf4eeb6560a585108af7a234a8db9"),
          ),
          puzzleReveal: Program.deserializeHex(
              "ff02ffff01ff02ffff01ff02ffff03ff0bffff01ff02ffff03ffff09ff05ffff1dff0bffff1effff0bff0bffff02ff06ffff04ff02ffff04ff17ff8080808080808080ffff01ff02ff17ff2f80ffff01ff088080ff0180ffff01ff04ffff04ff04ffff04ff05ffff04ffff02ff06ffff04ff02ffff04ff17ff80808080ff80808080ffff02ff17ff2f808080ff0180ffff04ffff01ff32ff02ffff03ffff07ff0580ffff01ff0bffff0102ffff02ff06ffff04ff02ffff04ff09ff80808080ffff02ff06ffff04ff02ffff04ff0dff8080808080ffff01ff0bffff0101ff058080ff0180ff018080ffff04ffff01b081d32b654af21a50150893416f30cf654f13f049b2ffd0af4f5306c867c16556a541101aff8fcd20b38123bb22c4c3d2ff018080"),
          solution: Program.deserializeHex(
              "ff80ffff01ffff33ffa0103076e23bbc3e51ab0ebc521a2b87d9ee5068168530b4e4556b5ab734405e67ff8600e8d4a51000ff8080ffff33ffa0d9833532bd704a1e95652fc4f9f79137aa8dcc001187ab4a060173a0c0885d86ff841dcd6500ffff894f5a4f4e455f4645458080ffff33ffa0eebcd30abf5eff065e0171d96808377a579961b36f0806b848fc1298a09f15b2ff8502bdfbbbff80ffff34ff8459682f0080ffff3cffa05babdf9546549e231fcc8452863948f32fa36f04989aa035d2cee20bf5dce0958080ff8080"),
        ),
      ],
      aggregatedSignature: JacobianPoint.fromHexG2(
          "a10055f843c7845cce56d20b07140e4ae1b6fc138a53affd9ba36f3452503f948872b7719fbbe465b6ad9263688eaa3714e1dfc4b2076b044ed5da39c0f06650be0bc0a09d6dac2dd70f722e4c27b0bc6b7067e4447849be90f16886127c7972"));

  final spendBundleBytes = spendBundle.toBytes().toHex();
  print("spend bundle bytes: $spendBundleBytes");

  test("(SpendBundle) Test streamable and stream bytes", () {
    expect(spendBundleBytes, spendBundlHex);
  });

  test("(SpendBundle) Test restore from bytes", () {
    final parsedSpendBundle = SpendBundle.fromBytes(Bytes.fromHex(spendBundleBytes));
    print("parsed spend bundle: $parsedSpendBundle");
    expect(parsedSpendBundle.coinSpends.length, spendBundle.coinSpends.length);
    expect(
        parsedSpendBundle.aggregatedSignature?.toHex(), spendBundle.aggregatedSignature?.toHex());
  });
}

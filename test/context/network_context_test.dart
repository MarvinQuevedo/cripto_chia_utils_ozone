// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/test.dart';

void main() {
  test('should save network context correctly', () {
    ChiaNetworkContextWrapper().registerNetworkContext(Network.mainnet);

    var blockchainNetwork = ChiaNetworkContextWrapper().blockchainNetwork;

    expect(blockchainNetwork.name, 'mainnet');
    expect(blockchainNetwork.addressPrefix, 'xch');
    expect(
      blockchainNetwork.aggSigMeExtraData,
      'ccd5bb71183532bff220ba46c268991a3ff07eb358e8255a65c30a2dce0e5fbb',
    );

    ChiaNetworkContextWrapper().registerNetworkContext(Network.testnet10);

    blockchainNetwork = ChiaNetworkContextWrapper().blockchainNetwork;

    expect(blockchainNetwork.name, 'testnet10');
    expect(blockchainNetwork.addressPrefix, 'txch');
    expect(
      blockchainNetwork.aggSigMeExtraData,
      'eb8c4d20b322be8d9fddbf9412016bdffe9a2901d7edb0e364e94266d0e095f7',
    );
  });

  test('should switch between environments', () {
    ChiaNetworkContextWrapper().registerNetworkContext(Network.mainnet);

    var blockchainNetwork = ChiaNetworkContextWrapper().blockchainNetwork;

    expect(blockchainNetwork.name, 'mainnet');
    expect(blockchainNetwork.addressPrefix, 'xch');
    expect(
      blockchainNetwork.aggSigMeExtraData,
      'ccd5bb71183532bff220ba46c268991a3ff07eb358e8255a65c30a2dce0e5fbb',
    );

    ChiaNetworkContextWrapper().registerNetworkContext(
      Network.testnet10,
      environment: Environment.flutter,
    );

    blockchainNetwork = ChiaNetworkContextWrapper().blockchainNetwork;

    expect(blockchainNetwork.name, 'testnet10');
    expect(blockchainNetwork.addressPrefix, 'txch');
    expect(
      blockchainNetwork.aggSigMeExtraData,
      'eb8c4d20b322be8d9fddbf9412016bdffe9a2901d7edb0e364e94266d0e095f7',
    );
  });
}

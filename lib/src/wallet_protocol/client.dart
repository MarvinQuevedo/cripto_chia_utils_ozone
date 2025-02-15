import 'dart:async';
import 'dart:io';

import 'package:chia_crypto_utils/src/wallet_protocol/models/message.dart';
import 'package:chia_crypto_utils/src/wallet_protocol/models/misc.dart';
import 'package:chia_crypto_utils/src/wallet_protocol/models/network.dart';

class Client {
  final String networkId;
  final PeerNetwork network;
  final dynamic connector; // Replace with appropriate connector type
  final ClientState state;

  Client(this.networkId, this.network, this.connector) : state = ClientState();

  String get getNetworkId => networkId;

  PeerNetwork get getNetwork => network;

  Future<StreamController<ChiaProtocolMessage>> connect(
    InternetAddress socketAddr,
    PeerOptions options,
  ) async {
    final result = await connectPeer(
      networkId,
      connector,
      socketAddr,
      options,
    );

    final peer = result.item1;
    final receiver = result.item2;

    final ipAddr = peer.socketAddr.address;

    if (state.isBanned(ipAddr)) {
      throw ClientError('BannedPeer');
    }

    state.peers[ipAddr] = peer;

    return receiver;
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
    return peers.remove(ipAddr) != null;
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

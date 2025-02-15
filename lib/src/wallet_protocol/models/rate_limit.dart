import 'dart:collection';

import 'package:chia_crypto_utils/src/wallet_protocol/models/message.dart';
import 'package:chia_crypto_utils/src/wallet_protocol/models/protocol_message_type.dart';

class RateLimits {
  late final RateLimit defaultSettings;
  late final double nonTxFrequency;
  late final double nonTxMaxTotalSize;
  late final Map<ProtocolMessageTypes, RateLimit> tx;
  late final Map<ProtocolMessageTypes, RateLimit> other;

  RateLimits({
    required this.defaultSettings,
    required this.nonTxFrequency,
    required this.nonTxMaxTotalSize,
    required this.tx,
    required this.other,
  });

  RateLimits clone() {
    return RateLimits(
      defaultSettings: defaultSettings,
      nonTxFrequency: nonTxFrequency,
      nonTxMaxTotalSize: nonTxMaxTotalSize,
      tx: Map.from(tx),
      other: Map.from(other),
    );
  }

  void extend(RateLimits other) {
    defaultSettings = other.defaultSettings;
    nonTxFrequency = other.nonTxFrequency;
    nonTxMaxTotalSize = other.nonTxMaxTotalSize;
    tx.addAll(other.tx);
    other.addAll(other.other);
  }

  void addAll(Map<ProtocolMessageTypes, RateLimit> settings) {
    tx.addAll(settings);
  }

  static final RateLimits v1RateLimits = _initV1RateLimits();
  static final RateLimits v2RateLimits = _initV2RateLimits();
}

class RateLimit {
  final double frequency;
  final double maxSize;
  final double? maxTotalSize;

  const RateLimit({
    required this.frequency,
    required this.maxSize,
    this.maxTotalSize,
  });
}

class RateLimiter {
  final bool incoming;
  final int resetSeconds;
  int period;
  final Map<ProtocolMessageTypes, double> messageCounts;
  final Map<ProtocolMessageTypes, double> messageCumulativeSizes;
  final double limitFactor;
  double nonTxCount;
  double nonTxSize;
  final RateLimits rateLimits;

  RateLimiter({
    required this.incoming,
    required this.resetSeconds,
    required this.limitFactor,
    required this.rateLimits,
  })  : period = _time() ~/ resetSeconds,
        messageCounts = HashMap(),
        messageCumulativeSizes = HashMap(),
        nonTxCount = 0.0,
        nonTxSize = 0.0;

  bool handleMessage(ChiaProtocolMessage message) {
    final size = message.data.length.toDouble();
    final period = _time() ~/ resetSeconds;

    if (this.period != period) {
      this.period = period;
      messageCounts.clear();
      messageCumulativeSizes.clear();
      nonTxCount = 0.0;
      nonTxSize = 0.0;
    }

    final newMessageCount = (messageCounts[message.msgType] ?? 0.0) + 1.0;
    final newCumulativeSize = (messageCumulativeSizes[message.msgType] ?? 0.0) + size;
    var newNonTxCount = nonTxCount;
    var newNonTxSize = nonTxSize;

    bool passed = () {
      var limits = rateLimits.defaultSettings;

      if (rateLimits.tx.containsKey(message.msgType)) {
        limits = rateLimits.tx[message.msgType]!;
      } else if (rateLimits.other.containsKey(message.msgType)) {
        limits = rateLimits.other[message.msgType]!;

        newNonTxCount += 1.0;
        newNonTxSize += size;

        if (newNonTxCount > rateLimits.nonTxFrequency * limitFactor) {
          return false;
        }

        if (newNonTxSize > rateLimits.nonTxMaxTotalSize * limitFactor) {
          return false;
        }
      }

      final maxTotalSize = limits.maxTotalSize ?? (limits.frequency * limits.maxSize);

      if (newMessageCount > limits.frequency * limitFactor) {
        return false;
      }

      if (size > limits.maxSize) {
        return false;
      }

      if (newCumulativeSize > maxTotalSize * limitFactor) {
        return false;
      }

      return true;
    }();

    if (incoming || passed) {
      messageCounts[message.msgType] = newMessageCount;
      messageCumulativeSizes[message.msgType] = newCumulativeSize;
      nonTxCount = newNonTxCount;
      nonTxSize = newNonTxSize;
    }

    return passed;
  }
}

int _time() {
  return DateTime.now().millisecondsSinceEpoch ~/ 1000;
}

Map<ProtocolMessageTypes, RateLimit> _createSettings(
    Map<ProtocolMessageTypes, List<num>> settings) {
  return settings.map((key, value) => MapEntry(
        key,
        RateLimit(
          frequency: value[0].toDouble(),
          maxSize: value[1].toDouble(),
          maxTotalSize: value.length > 2 ? value[2].toDouble() : null,
        ),
      ));
}

final RateLimits _v1RateLimits = RateLimits(
  defaultSettings: RateLimit(
    frequency: 100.0,
    maxSize: 1024.0 * 1024.0,
    maxTotalSize: 100.0 * 1024.0 * 1024.0,
  ),
  nonTxFrequency: 1000.0,
  nonTxMaxTotalSize: 100.0 * 1024.0 * 1024.0,
  tx: _createSettings({
    ProtocolMessageTypes.newTransaction: [5000, 100, 5000 * 100],
    ProtocolMessageTypes.requestTransaction: [5000, 100, 5000 * 100],
    ProtocolMessageTypes.respondTransaction: [5000, 1024 * 1024, 20 * 1024 * 1024],
    ProtocolMessageTypes.sendTransaction: [5000, 1024 * 1024],
    ProtocolMessageTypes.transactionAck: [5000, 2048],
  }),
  other: _createSettings({
    ProtocolMessageTypes.handshake: [5, 10 * 1024, 5 * 10 * 1024],
    ProtocolMessageTypes.harvesterHandshake: [5, 1024 * 1024],
    ProtocolMessageTypes.newSignagePointHarvester: [100, 4886],
    ProtocolMessageTypes.newProofOfSpace: [100, 2048],
    ProtocolMessageTypes.requestSignatures: [100, 2048],
    ProtocolMessageTypes.respondSignatures: [100, 2048],
    ProtocolMessageTypes.newSignagePoint: [200, 2048],
    ProtocolMessageTypes.declareProofOfSpace: [100, 10 * 1024],
    ProtocolMessageTypes.requestSignedValues: [100, 10 * 1024],
    ProtocolMessageTypes.farmingInfo: [100, 1024],
    ProtocolMessageTypes.signedValues: [100, 1024],
    ProtocolMessageTypes.newPeakTimelord: [100, 20 * 1024],
    ProtocolMessageTypes.newUnfinishedBlockTimelord: [100, 10 * 1024],
    ProtocolMessageTypes.newSignagePointVdf: [100, 100 * 1024],
    ProtocolMessageTypes.newInfusionPointVdf: [100, 100 * 1024],
    ProtocolMessageTypes.newEndOfSubSlotVdf: [100, 100 * 1024],
    ProtocolMessageTypes.requestCompactProofOfTime: [100, 10 * 1024],
    ProtocolMessageTypes.respondCompactProofOfTime: [100, 100 * 1024],
    ProtocolMessageTypes.newPeak: [200, 512],
    ProtocolMessageTypes.requestProofOfWeight: [5, 100],
    ProtocolMessageTypes.respondProofOfWeight: [5, 50 * 1024 * 1024, 100 * 1024 * 1024],
    ProtocolMessageTypes.requestBlock: [200, 100],
    ProtocolMessageTypes.rejectBlock: [200, 100],
    ProtocolMessageTypes.requestBlocks: [500, 100],
    ProtocolMessageTypes.respondBlocks: [100, 50 * 1024 * 1024, 5 * 50 * 1024 * 1024],
    ProtocolMessageTypes.rejectBlocks: [100, 100],
    ProtocolMessageTypes.respondBlock: [200, 2 * 1024 * 1024, 10 * 2 * 1024 * 1024],
    ProtocolMessageTypes.newUnfinishedBlock: [200, 100],
    ProtocolMessageTypes.requestUnfinishedBlock: [200, 100],
    ProtocolMessageTypes.newUnfinishedBlock2: [200, 100],
    ProtocolMessageTypes.requestUnfinishedBlock2: [200, 100],
    ProtocolMessageTypes.respondUnfinishedBlock: [200, 2 * 1024 * 1024, 10 * 2 * 1024 * 1024],
    ProtocolMessageTypes.newSignagePointOrEndOfSubSlot: [200, 200],
    ProtocolMessageTypes.requestSignagePointOrEndOfSubSlot: [200, 200],
    ProtocolMessageTypes.respondSignagePoint: [200, 50 * 1024],
    ProtocolMessageTypes.respondEndOfSubSlot: [100, 50 * 1024],
    ProtocolMessageTypes.requestMempoolTransactions: [5, 1024 * 1024],
    ProtocolMessageTypes.requestCompactVdf: [200, 1024],
    ProtocolMessageTypes.respondCompactVdf: [200, 100 * 1024],
    ProtocolMessageTypes.newCompactVdf: [100, 1024],
    ProtocolMessageTypes.requestPeers: [10, 100],
    ProtocolMessageTypes.respondPeers: [10, 1024 * 1024],
    ProtocolMessageTypes.requestPuzzleSolution: [1000, 100],
    ProtocolMessageTypes.respondPuzzleSolution: [1000, 1024 * 1024],
    ProtocolMessageTypes.rejectPuzzleSolution: [1000, 100],
    ProtocolMessageTypes.newPeakWallet: [200, 300],
  }),
);

final RateLimits _v2RateLimitChanges = RateLimits(
  defaultSettings: RateLimit(
    frequency: 100.0,
    maxSize: 1024.0 * 1024.0,
    maxTotalSize: 100.0 * 1024.0 * 1024.0,
  ),
  nonTxFrequency: 1000.0,
  nonTxMaxTotalSize: 100.0 * 1024.0 * 1024.0,
  tx: _createSettings({
    ProtocolMessageTypes.requestBlockHeader: [500, 100],
    ProtocolMessageTypes.respondBlockHeader: [500, 500 * 1024],
    ProtocolMessageTypes.rejectHeaderRequest: [500, 100],
    ProtocolMessageTypes.requestRemovals: [5000, 50 * 1024, 10 * 1024 * 1024],
    ProtocolMessageTypes.respondRemovals: [5000, 1024 * 1024, 10 * 1024 * 1024],
    ProtocolMessageTypes.rejectRemovalsRequest: [500, 100],
    ProtocolMessageTypes.requestAdditions: [50000, 100 * 1024 * 1024],
    ProtocolMessageTypes.respondAdditions: [50000, 100 * 1024 * 1024],
    ProtocolMessageTypes.rejectAdditionsRequest: [500, 100],
    ProtocolMessageTypes.rejectHeaderBlocks: [1000, 100],
    ProtocolMessageTypes.respondHeaderBlocks: [5000, 2 * 1024 * 1024],
    ProtocolMessageTypes.requestBlockHeaders: [5000, 100],
    ProtocolMessageTypes.rejectBlockHeaders: [1000, 100],
    ProtocolMessageTypes.respondBlockHeaders: [5000, 2 * 1024 * 1024],
    ProtocolMessageTypes.requestChildren: [2000, 1024 * 1024],
    ProtocolMessageTypes.respondChildren: [2000, 1024 * 1024],
    ProtocolMessageTypes.requestPuzzleSolution: [5000, 100],
    ProtocolMessageTypes.respondPuzzleSolution: [5000, 1024 * 1024],
    ProtocolMessageTypes.rejectPuzzleSolution: [5000, 100],
    ProtocolMessageTypes.noneResponse: [500, 100],
  }),
  other: _createSettings({
    ProtocolMessageTypes.requestHeaderBlocks: [5000, 100],
  }),
);

RateLimits _initV2RateLimits() {
  final rateLimits = _v1RateLimits.clone();
  rateLimits.extend(_v2RateLimitChanges);
  return rateLimits;
}

RateLimits _initV1RateLimits() {
  return _v1RateLimits;
}

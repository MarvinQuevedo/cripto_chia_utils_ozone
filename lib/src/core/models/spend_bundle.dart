// ignore_for_file: lines_longer_than_80_chars

import 'dart:async';
import 'dart:typed_data';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/utils/serialization.dart';
import 'package:meta/meta.dart';

@immutable
class SpendBundle with ToBytesMixin {
  SpendBundle({
    required this.coinSpends,
    this.aggregatedSignature,
  });

  factory SpendBundle.fromBytes(Bytes bytes) {
    final iterator = bytes.toList().iterator;

    // length of list is encoded with 32 bits
    final coinSpendsLengthBytes = iterator.extractBytesAndAdvance(4);
    final coinSpendsLength = bytesToInt(coinSpendsLengthBytes, Endian.big);

    final coinSpends = <CoinSpend>[];
    for (var i = 0; i < coinSpendsLength; i++) {
      coinSpends.add(CoinSpend.fromStream(iterator));
    }

    final signatureExists = iterator.moveNext();
    if (!signatureExists) {
      return SpendBundle(coinSpends: coinSpends);
    }

    final firstSignatureByte = iterator.current;
    final restOfSignatureBytes = iterator.extractBytesAndAdvance(JacobianPoint.g2BytesLength - 1);

    final signature = JacobianPoint.fromBytesG2(
      [firstSignatureByte, ...restOfSignatureBytes],
    );

    return SpendBundle(coinSpends: coinSpends, aggregatedSignature: signature);
  }

  factory SpendBundle.fromHex(String hex) {
    return SpendBundle.fromBytes(Bytes.fromHex(hex));
  }
  SpendBundle.fromJson(Map<String, dynamic> json)
      : coinSpends = (json['coin_spends'] as Iterable)
            .map((dynamic e) => CoinSpend.fromJson(e as Map<String, dynamic>))
            .toList(),
        aggregatedSignature = JacobianPoint.fromHexG2(json['aggregated_signature'] as String);

  factory SpendBundle.aggregate(List<SpendBundle> bundles) {
    var totalBundle = SpendBundle.empty;

    for (final bundle in bundles) {
      totalBundle += bundle;
    }
    return totalBundle;
  }
  Bytes get id => toBytes().sha256Hash();

  final List<CoinSpend> coinSpends;
  final JacobianPoint? aggregatedSignature;

  bool get isSigned => aggregatedSignature != null;

  List<Program> get outputConditions {
    final conditions = <Program>[];
    for (final spend in coinSpends) {
      final spendOutput = spend.puzzleReveal.run(spend.solution).program;
      conditions.addAll(spendOutput.toList());
    }
    return conditions;
  }

  List<CoinPrototype> get additions {
    return coinSpends.fold(
      <CoinPrototype>[],
      (previousValue, coinSpend) => previousValue + coinSpend.additions,
    );
  }

  List<CoinPrototype> get removals {
    return coinSpends.map((e) => e.coin).toList();
  }

  List<CoinPrototype> get netAdditions {
    final removalsSet = removals.toSet();

    return additions.where((a) => !removalsSet.contains(a)).toList();
  }

  Future<List<CoinPrototype>> get additionsAsync async {
    final additions = <CoinPrototype>[];
    for (final coinSpend in coinSpends) {
      additions.addAll(await coinSpend.additionsAsync);
    }
    return additions;
  }

  List<CoinPrototype> get coins => coinSpends.map((cs) => cs.coin).toList();

  // ignore: prefer_constructors_over_static_methods
  static SpendBundle get empty => SpendBundle(coinSpends: const []);

  Map<String, dynamic> toJson() => <String, dynamic>{
        'coin_spends': coinSpends.map((e) => e.toJson()).toList(),
        'aggregated_signature': aggregatedSignature?.toHex(),
      };

  SpendBundle operator +(SpendBundle other) {
    final signatures = <JacobianPoint>[];
    if (aggregatedSignature != null) {
      signatures.add(aggregatedSignature!);
    }
    if (other.aggregatedSignature != null) {
      signatures.add(other.aggregatedSignature!);
    }
    return SpendBundle(
      coinSpends: coinSpends + other.coinSpends,
      aggregatedSignature: (signatures.isNotEmpty) ? AugSchemeMPL.aggregate(signatures) : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (other is! SpendBundle) {
      return false;
    }
    if (other.coinSpends.length != coinSpends.length) {
      return false;
    }
    final otherHexCoinSpends = other.coinSpends.map((cs) => cs.toHex()).toList();
    for (final coinSpend in coinSpends) {
      if (!otherHexCoinSpends.contains(coinSpend.toHex())) {
        return false;
      }
    }
    if (aggregatedSignature != other.aggregatedSignature) {
      return false;
    }
    return true;
  }

  SpendBundle addSignature(JacobianPoint signature) {
    final signatures = <JacobianPoint>[signature];
    if (aggregatedSignature != null) {
      signatures.add(aggregatedSignature!);
    }
    final newAggregatedSignature = AugSchemeMPL.aggregate(signatures);

    return SpendBundle(
      coinSpends: coinSpends,
      aggregatedSignature: newAggregatedSignature,
    );
  }

  Future<SpendBundle> sign(
    FutureOr<JacobianPoint> Function(CoinSpend coinSpend) makeSignatureForCoinSpend,
  ) async {
    final signatures = <JacobianPoint>[];
    for (final coinSpend in coinSpends) {
      signatures.add(await makeSignatureForCoinSpend(coinSpend));
    }
    final newAggregatedSignature = AugSchemeMPL.aggregate(signatures);

    return SpendBundle(
      coinSpends: coinSpends,
      aggregatedSignature: newAggregatedSignature,
    );
  }

  SpendBundle signSync(
    JacobianPoint? Function(CoinSpend coinSpend) makeSignatureForCoinSpend,
  ) {
    final signatures = <JacobianPoint>[];
    for (final coinSpend in coinSpends) {
      final signature = makeSignatureForCoinSpend(coinSpend);
      if (signature != null) {
        signatures.add(signature);
      }
    }
    final newAggregatedSignature = AugSchemeMPL.aggregate(signatures);

    return SpendBundle(
      coinSpends: coinSpends,
      aggregatedSignature: newAggregatedSignature,
    );
  }

  @override
  Bytes toBytes() {
    return serializeListChia(coinSpends) + Bytes(aggregatedSignature?.toBytes() ?? []);
  }

  void debug() {
    for (final spend in coinSpends) {
      print('---------');
      print('coin: ${spend.coin.toJson()}');
      print('puzzle reveal: ${spend.puzzleReveal}');
      print('solution: ${spend.solution}');
      print('result: ${spend.puzzleReveal.run(spend.solution).program}');
    }
  }

  @override
  String toString() =>
      'SpendBundle(coinSpends: $coinSpends, aggregatedSignature: $aggregatedSignature)';

  @override
  int get hashCode {
    var hc = coinSpends.fold(
      0,
      (int previousValue, cs) => previousValue ^ cs.hashCode,
    );
    if (aggregatedSignature != null) {
      hc = hc ^ aggregatedSignature.hashCode;
    }
    return hc;
  }
}

// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:chia_utils/src/core/models/serializable.dart';

class SpendBundle implements Serializable{
  List<CoinSpend> coinSpends;
  JacobianPoint? aggregatedSignature;

  bool get isSigned => aggregatedSignature != null;

  List<Program> get outputConditions {
    final conditions = <Program>[];
    for (final spend in coinSpends) { 
      final spendOutput = spend.puzzleReveal.run(spend.solution).program;
      conditions.addAll(spendOutput.toList());
    }
    return conditions;
  }

  SpendBundle({
    required this.coinSpends,
    this.aggregatedSignature,
  });

  Map<String, dynamic> toJson() => <String, dynamic> {
      'coin_spends': coinSpends.map((e) => e.toJson()).toList(),
      'aggregated_signature': aggregatedSignature?.toHex(),
    };
  SpendBundle.fromJson(Map<String, dynamic> json)
    : coinSpends = (json['coin_solutions'] as Iterable).map((dynamic e) => CoinSpend.fromJson(e as Map<String, dynamic>)).toList(),
      aggregatedSignature = JacobianPoint.fromHexG2(json['aggregated_signature'] as String); 

  SpendBundle operator +(SpendBundle other) {
    final signatures = <JacobianPoint>[];
    if(aggregatedSignature != null) {
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

  void addSignature(JacobianPoint signature) {
    final signatures = <JacobianPoint>[signature];
    if(aggregatedSignature != null) {
      signatures.add(aggregatedSignature!);
    }
    aggregatedSignature = AugSchemeMPL.aggregate(signatures);
  }

  @override
  Bytes toBytes() {
    return serializeList(coinSpends) + Bytes(aggregatedSignature?.toBytes() ?? []);
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
  String toString() => 'SpendBundle(coinSpends: $coinSpends, aggregatedSignature: $aggregatedSignature)';
}

// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_utils/chia_crypto_utils.dart';

class SpendBundle {
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

  factory SpendBundle.aggregate(List<SpendBundle> spendBundles) {
    final signatures = <JacobianPoint>[];
    var coinSpends = <CoinSpend>[];
    for (final spendBundle in spendBundles) {
      if(spendBundle.isSigned) {
        signatures.add(spendBundle.aggregatedSignature!);
      }
      coinSpends += spendBundle.coinSpends;
    }
    final aggregatedSignature = AugSchemeMPL.aggregate(signatures);
    return SpendBundle(coinSpends: coinSpends, aggregatedSignature: aggregatedSignature);
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
}

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:deep_pick/deep_pick.dart';

class CoinPrototypeWithParentSpend with CoinPrototypeDecoratorMixin implements CoinPrototype {
  CoinPrototypeWithParentSpend({
    required this.delegate,
    required this.parentSpend,
  });

  factory CoinPrototypeWithParentSpend.fromCoin(CoinPrototype coin, CoinSpend parentSpend) {
    return CoinPrototypeWithParentSpend(
      delegate: coin,
      parentSpend: parentSpend,
    );
  }

  @override
  final CoinPrototype delegate;

  final CoinSpend? parentSpend;
}

class CoinWithParentSpend extends FullCoin {
  CoinWithParentSpend({
    required Coin delegate,
    required CoinSpend? parentSpend,
  }) : super(
          coin: delegate,
          parentCoinSpend: parentSpend,
        );

  factory CoinWithParentSpend.fromJson(Map<String, dynamic> json) {
    final coin = Coin.fromJson(json);

    final parentSpend = pick(json, 'parent_coin_spend').letJsonOrNull(CoinSpend.fromJson);

    return CoinWithParentSpend.fromCoin(coin, parentSpend);
  }

  factory CoinWithParentSpend.fromCoin(Coin coin, CoinSpend? parentSpend) {
    return CoinWithParentSpend(
      delegate: coin,
      parentSpend: parentSpend,
    );
  }

  Coin get delegate => coin;

  bool get coinbase => delegate.coinbase;

  int get confirmedBlockIndex => delegate.confirmedBlockIndex;

  int get spentBlockIndex => delegate.spentBlockIndex;

  int get timestamp => delegate.timestamp;

  Map<String, dynamic> toFullJson() {
    return {
      ...delegate.toFullJson(),
      'parent_coin_spend': parentCoinSpend?.toJson(),
    };
  }
}

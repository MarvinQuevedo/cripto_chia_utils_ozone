import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class CoinNotInBundle implements Exception {
  CoinNotInBundle(this.coinId) : super();
  final Bytes coinId;

  @override
  String toString() {
    return 'The specified coin is not a coin in this bundle  ${coinId.toHex()}';
  }
}

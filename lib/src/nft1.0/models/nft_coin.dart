import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class NftCoin {

  NftCoin({
    required this.coin,
    required this.lineageProof,
    required this.fullPuzzle,
  });
  final CoinPrototype coin;
  final LineageProof lineageProof;
  final Program fullPuzzle;
}

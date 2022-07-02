import '../../../chia_crypto_utils.dart';
import 'lineage_proof.dart';

class NftCoin {
  final CoinPrototype coin;
  final LineageProof lineageProof;
  final Program fullPuzzle;

  NftCoin({
    required this.coin,
    required this.lineageProof,
    required this.fullPuzzle,
  });
}

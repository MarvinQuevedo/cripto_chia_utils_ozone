import 'package:chia_crypto_utils/chia_crypto_utils.dart';

/// Represents a mempool item from the coinset.org API
class CoinsetMempoolItem {
  const CoinsetMempoolItem({
    required this.spendBundle,
    required this.fee,
  });

  factory CoinsetMempoolItem.fromJson(Map<String, dynamic> json) {
    return CoinsetMempoolItem(
      spendBundle: SpendBundle.fromJson(json['spend_bundle'] as Map<String, dynamic>),
      fee: json['fee'] as int,
    );
  }

  final SpendBundle spendBundle;
  final int fee;

  Map<String, dynamic> toJson() => {
        'spend_bundle': spendBundle.toJson(),
        'fee': fee,
      };

  @override
  String toString() {
    return 'CoinsetMempoolItem(fee: $fee, spendBundle: $spendBundle)';
  }
}

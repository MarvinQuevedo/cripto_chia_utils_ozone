import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:chia_utils/src/api/models/responses/chia_base_response.dart';
import 'package:meta/meta.dart';

@immutable
class CoinSpendResponse extends ChiaBaseResponse {
  final CoinSpend? coinSpend;

  const CoinSpendResponse({
    required this.coinSpend,
    required bool success,
    required String? error,
  }) : super(
    success: success,
    error: error,
  );

  factory CoinSpendResponse.fromJson(Map<String, dynamic> json) {
    final chiaBaseResponse = ChiaBaseResponse.fromJson(json);

    return CoinSpendResponse(
      coinSpend: 
        json['coin_solution'] != null ?
            CoinSpend.fromJson(json['coin_solution'] as Map<String, dynamic>)
          :
            null
          ,
      success: chiaBaseResponse.success,
      error: chiaBaseResponse.error,
    );
  }
}

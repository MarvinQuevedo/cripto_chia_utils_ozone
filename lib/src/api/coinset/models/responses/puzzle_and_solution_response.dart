import 'package:chia_crypto_utils/chia_crypto_utils.dart';

/// Response from get_puzzle_and_solution endpoint
class GetPuzzleAndSolutionResponse {
  const GetPuzzleAndSolutionResponse({
    this.coinSolution,
    this.error,
    required this.success,
  });

  factory GetPuzzleAndSolutionResponse.fromJson(Map<String, dynamic> json) {
    return GetPuzzleAndSolutionResponse(
      coinSolution: json['coin_solution'] != null
          ? CoinSpend.fromJson(json['coin_solution'] as Map<String, dynamic>)
          : null,
      error: json['error'] as String?,
      success: json['success'] as bool,
    );
  }

  final CoinSpend? coinSolution;
  final String? error;
  final bool success;

  Map<String, dynamic> toJson() => {
        if (coinSolution != null) 'coin_solution': coinSolution!.toJson(),
        if (error != null) 'error': error,
        'success': success,
      };
}

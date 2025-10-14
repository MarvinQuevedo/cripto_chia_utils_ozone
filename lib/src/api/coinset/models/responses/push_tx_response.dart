/// Response from push_tx endpoint
class PushTxResponse {
  const PushTxResponse({
    required this.status,
    this.error,
    required this.success,
  });

  factory PushTxResponse.fromJson(Map<String, dynamic> json) {
    return PushTxResponse(
      status: json['status'] as String,
      error: json['error'] as String?,
      success: json['success'] as bool,
    );
  }

  final String status;
  final String? error;
  final bool success;

  Map<String, dynamic> toJson() => {
        'status': status,
        if (error != null) 'error': error,
        'success': success,
      };
}

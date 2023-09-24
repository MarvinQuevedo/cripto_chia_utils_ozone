import 'package:meta/meta.dart';

@immutable
class ChiaBaseResponse {
  final String? error;
  final bool success;
  final Map<String, dynamic>? body;

  const ChiaBaseResponse({
    required this.error,
    required this.success,
    this.body,
  });

  factory ChiaBaseResponse.fromJson(Map<String, dynamic> json) {
    return ChiaBaseResponse(
      error: json['error'] as String?,
      success: json['success'] as bool? ?? false,
      body: json['body'] as Map<String, dynamic>?,
    );
  }
  Map<String, dynamic> toJson() => <String, dynamic>{
        'error': error,
        'success': success,
      };

  @override
  String toString() => 'ChiaBaseResponse(success: $success, error: $error)';
}

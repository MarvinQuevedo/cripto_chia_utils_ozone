/// Response from get_network_info endpoint
class GetNetworkInfoResponse {
  const GetNetworkInfoResponse({
    this.networkName,
    this.networkPrefix,
    this.genesisChallenge,
    this.error,
    required this.success,
  });

  factory GetNetworkInfoResponse.fromJson(Map<String, dynamic> json) {
    return GetNetworkInfoResponse(
      networkName: json['network_name'] as String?,
      networkPrefix: json['network_prefix'] as String?,
      genesisChallenge: json['genesis_challenge'] as String?,
      error: json['error'] as String?,
      success: json['success'] as bool,
    );
  }

  final String? networkName;
  final String? networkPrefix;
  final String? genesisChallenge;
  final String? error;
  final bool success;

  Map<String, dynamic> toJson() => {
        if (networkName != null) 'network_name': networkName,
        if (networkPrefix != null) 'network_prefix': networkPrefix,
        if (genesisChallenge != null) 'genesis_challenge': genesisChallenge,
        if (error != null) 'error': error,
        'success': success,
      };
}

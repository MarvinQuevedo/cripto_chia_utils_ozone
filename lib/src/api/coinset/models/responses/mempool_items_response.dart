import '../mempool_item.dart';

/// Response from get_mempool_item_by_tx_id endpoint
class GetMempoolItemResponse {
  const GetMempoolItemResponse({
    this.mempoolItem,
    this.error,
    required this.success,
  });

  factory GetMempoolItemResponse.fromJson(Map<String, dynamic> json) {
    return GetMempoolItemResponse(
      mempoolItem: json['mempool_item'] != null
          ? CoinsetMempoolItem.fromJson(json['mempool_item'] as Map<String, dynamic>)
          : null,
      error: json['error'] as String?,
      success: json['success'] as bool,
    );
  }

  final CoinsetMempoolItem? mempoolItem;
  final String? error;
  final bool success;

  Map<String, dynamic> toJson() => {
        if (mempoolItem != null) 'mempool_item': mempoolItem!.toJson(),
        if (error != null) 'error': error,
        'success': success,
      };
}

/// Response from get_mempool_items_by_coin_name endpoint
class GetMempoolItemsResponse {
  const GetMempoolItemsResponse({
    this.mempoolItems,
    this.error,
    required this.success,
  });

  factory GetMempoolItemsResponse.fromJson(Map<String, dynamic> json) {
    return GetMempoolItemsResponse(
      mempoolItems: json['mempool_items'] != null
          ? (json['mempool_items'] as List)
              .map((e) => CoinsetMempoolItem.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      error: json['error'] as String?,
      success: json['success'] as bool,
    );
  }

  final List<CoinsetMempoolItem>? mempoolItems;
  final String? error;
  final bool success;

  Map<String, dynamic> toJson() => {
        if (mempoolItems != null) 'mempool_items': mempoolItems!.map((e) => e.toJson()).toList(),
        if (error != null) 'error': error,
        'success': success,
      };
}

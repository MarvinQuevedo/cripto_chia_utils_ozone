/// Response from get_blockchain_state endpoint
class CoinsetBlockchainStateResponse {
  const CoinsetBlockchainStateResponse({
    this.blockchainState,
    this.error,
    required this.success,
  });

  factory CoinsetBlockchainStateResponse.fromJson(Map<String, dynamic> json) {
    return CoinsetBlockchainStateResponse(
      blockchainState: json['blockchain_state'] != null
          ? CoinsetBlockchainState.fromJson(json['blockchain_state'] as Map<String, dynamic>)
          : null,
      error: json['error'] as String?,
      success: json['success'] as bool,
    );
  }

  final CoinsetBlockchainState? blockchainState;
  final String? error;
  final bool success;

  Map<String, dynamic> toJson() => {
        if (blockchainState != null) 'blockchain_state': blockchainState!.toJson(),
        if (error != null) 'error': error,
        'success': success,
      };
}

/// Represents the blockchain state
class CoinsetBlockchainState {
  const CoinsetBlockchainState({
    required this.averageBlockTime,
    required this.blockMaxCost,
    required this.difficulty,
    required this.genesisChallengeInitialized,
    required this.mempoolCost,
    required this.mempoolFees,
    required this.mempoolMaxTotalCost,
    required this.mempoolMinFees,
    required this.mempoolSize,
    required this.nodeId,
    required this.peak,
    required this.space,
    required this.subSlotIters,
    required this.sync,
  });

  factory CoinsetBlockchainState.fromJson(Map<String, dynamic> json) {
    return CoinsetBlockchainState(
      averageBlockTime: json['average_block_time'] as int,
      blockMaxCost: json['block_max_cost'] as int,
      difficulty: json['difficulty'] as int,
      genesisChallengeInitialized: json['genesis_challenge_initialized'] as bool,
      mempoolCost: json['mempool_cost'] as int,
      mempoolFees: json['mempool_fees'] as int,
      mempoolMaxTotalCost: json['mempool_max_total_cost'] as int,
      mempoolMinFees: MempoolMinFees.fromJson(json['mempool_min_fees'] as Map<String, dynamic>),
      mempoolSize: json['mempool_size'] as int,
      nodeId: json['node_id'] as String,
      peak: json['peak'], // This would need proper BlockRecord parsing
      space: json['space'] is int ? json['space'] as int : int.parse(json['space'].toString()),
      subSlotIters: json['sub_slot_iters'] as int,
      sync: SyncState.fromJson(json['sync'] as Map<String, dynamic>),
    );
  }

  final int averageBlockTime;
  final int blockMaxCost;
  final int difficulty;
  final bool genesisChallengeInitialized;
  final int mempoolCost;
  final int mempoolFees;
  final int mempoolMaxTotalCost;
  final MempoolMinFees mempoolMinFees;
  final int mempoolSize;
  final String nodeId;
  final dynamic peak; // BlockRecord type
  final int space;
  final int subSlotIters;
  final SyncState sync;

  Map<String, dynamic> toJson() => {
        'average_block_time': averageBlockTime,
        'block_max_cost': blockMaxCost,
        'difficulty': difficulty,
        'genesis_challenge_initialized': genesisChallengeInitialized,
        'mempool_cost': mempoolCost,
        'mempool_fees': mempoolFees,
        'mempool_max_total_cost': mempoolMaxTotalCost,
        'mempool_min_fees': mempoolMinFees.toJson(),
        'mempool_size': mempoolSize,
        'node_id': nodeId,
        'peak': peak,
        'space': space,
        'sub_slot_iters': subSlotIters,
        'sync': sync.toJson(),
      };
}

/// Mempool minimum fees
class MempoolMinFees {
  const MempoolMinFees({
    required this.cost5000000,
  });

  factory MempoolMinFees.fromJson(Map<String, dynamic> json) {
    return MempoolMinFees(
      cost5000000: json['cost_5000000'] as int,
    );
  }

  final int cost5000000;

  Map<String, dynamic> toJson() => {
        'cost_5000000': cost5000000,
      };
}

/// Sync state information
class SyncState {
  const SyncState({
    required this.syncMode,
    required this.syncProgressHeight,
    required this.syncTipHeight,
    required this.synced,
  });

  factory SyncState.fromJson(Map<String, dynamic> json) {
    return SyncState(
      syncMode: json['sync_mode'] as bool,
      syncProgressHeight: json['sync_progress_height'] as int,
      syncTipHeight: json['sync_tip_height'] as int,
      synced: json['synced'] as bool,
    );
  }

  final bool syncMode;
  final int syncProgressHeight;
  final int syncTipHeight;
  final bool synced;

  Map<String, dynamic> toJson() => {
        'sync_mode': syncMode,
        'sync_progress_height': syncProgressHeight,
        'sync_tip_height': syncTipHeight,
        'synced': synced,
      };
}

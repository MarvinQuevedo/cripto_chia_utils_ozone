import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:equatable/equatable.dart';
import 'package:tuple/tuple.dart';

class DidInfo extends Equatable {
  final Coin? originCoin;
  final List<Bytes> backupsIds;
  final int numOfBackupIdsNeeded;
  final List<Tuple2<Bytes, LineageProof?>> parentInfo;
  final Program? currentInner;
  final Coin? tempCoin;
  final Bytes? tempPuzzlehash;
  final Bytes? tempPubKey;
  final bool sentRecoveryTransaction;
  final String metadata;
  DidInfo({
    required this.originCoin,
    required this.backupsIds,
    required this.numOfBackupIdsNeeded,
    required this.parentInfo,
    this.currentInner,
    this.tempCoin,
    this.tempPuzzlehash,
    this.tempPubKey,
    required this.sentRecoveryTransaction,
    required this.metadata,
  });

  @override
  List<Object> get props {
    return [
      originCoin ?? "",
      backupsIds,
      numOfBackupIdsNeeded,
      parentInfo,
      currentInner ?? "",
      tempCoin ?? "",
      tempPuzzlehash ?? "",
      tempPubKey ?? "",
      sentRecoveryTransaction,
      metadata,
    ];
  }

  DidInfo copyWith({
    Coin? originCoin,
    List<Bytes>? backupsIds,
    int? numOfBackupIdsNeeded,
    List<Tuple2<Bytes, LineageProof?>>? parentInfo,
    Program? currentInner,
    Coin? tempCoin,
    Bytes? tempPuzzlehash,
    Bytes? tempPubKey,
    bool? sentRecoveryTransaction,
    String? metadata,
  }) {
    return DidInfo(
      originCoin: originCoin ?? this.originCoin,
      backupsIds: backupsIds ?? this.backupsIds,
      numOfBackupIdsNeeded: numOfBackupIdsNeeded ?? this.numOfBackupIdsNeeded,
      parentInfo: parentInfo ?? this.parentInfo,
      currentInner: currentInner ?? this.currentInner,
      tempCoin: tempCoin ?? this.tempCoin,
      tempPuzzlehash: tempPuzzlehash ?? this.tempPuzzlehash,
      tempPubKey: tempPubKey ?? this.tempPubKey,
      sentRecoveryTransaction: sentRecoveryTransaction ?? this.sentRecoveryTransaction,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'DidInfo(originCoin: $originCoin, backupsIds: $backupsIds, numOfBackupIdsNeeded: $numOfBackupIdsNeeded, parentInfo: $parentInfo, currentInner: $currentInner, tempCoin: $tempCoin, tempPuzzlehash: $tempPuzzlehash, tempPubKey: $tempPubKey, sentRecoveryTransaction: $sentRecoveryTransaction, metadata: $metadata)';
  }
}

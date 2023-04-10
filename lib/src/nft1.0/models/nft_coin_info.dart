import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class NFTCoinInfo extends CoinPrototype {
  /// The launcher coin ID of the NFT
  final Bytes nftId;
  final CoinPrototype coin;
  final LineageProof? lineageProof;
  final Program fullPuzzle;
  final int mintHeight;
  final Bytes? minterDid;
  final int latestHeight;
  final bool pendingTransaction;

  Bytes get launcherId => nftId;

  NFTCoinInfo({
    required this.nftId,
    required this.coin,
    this.lineageProof,
    required this.fullPuzzle,
    required this.mintHeight,
    required this.latestHeight,
    this.pendingTransaction = false,
    this.minterDid,
  }) : super(
          amount: coin.amount,
          puzzlehash: coin.puzzlehash,
          parentCoinInfo: coin.parentCoinInfo,
        );

  NFTCoinInfo copyWith({
    Bytes? nftId,
    CoinPrototype? coin,
    LineageProof? lineageProof,
    Program? fullPuzzle,
    int? mintHeight,
    int? latestHeight,
    bool? pendingTransaction,
    Bytes? minterDid,
  }) {
    return NFTCoinInfo(
      nftId: nftId ?? this.nftId,
      coin: coin ?? this.coin,
      lineageProof: lineageProof ?? this.lineageProof,
      fullPuzzle: fullPuzzle ?? this.fullPuzzle,
      mintHeight: mintHeight ?? this.mintHeight,
      latestHeight: latestHeight ?? this.latestHeight,
      pendingTransaction: pendingTransaction ?? this.pendingTransaction,
      minterDid: minterDid ?? this.minterDid,
    );
  }

  @override
  String toString() {
    return 'NFTCoinInfo(nftId: $nftId, coin: $coin, lineageProof: $lineageProof, fullPuzzle: $fullPuzzle, mintHeight: $mintHeight, latestHeight: $latestHeight, pendingTransaction: $pendingTransaction)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is NFTCoinInfo &&
        other.nftId == nftId &&
        other.coin == coin &&
        other.lineageProof == lineageProof &&
        other.fullPuzzle == fullPuzzle &&
        other.mintHeight == mintHeight &&
        other.latestHeight == latestHeight &&
        other.pendingTransaction == pendingTransaction;
  }

  @override
  int get hashCode {
    return nftId.hashCode ^
        coin.hashCode ^
        lineageProof.hashCode ^
        fullPuzzle.hashCode ^
        mintHeight.hashCode ^
        latestHeight.hashCode ^
        pendingTransaction.hashCode;
  }
}

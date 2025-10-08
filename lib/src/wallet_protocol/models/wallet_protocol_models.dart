import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:tuple/tuple.dart';

import 'fee_estimate_group.dart';

class RequestPuzzleSolution extends ChiaProtocolMessage {
  final Bytes32 coinName;
  final int height;

  @override
  Bytes get data => toStreamBytes();

  RequestPuzzleSolution(this.coinName, this.height)
      : super(
          msgType: ProtocolMessageTypes.requestPuzzleSolution,
          data: Bytes([]),
        );

  @override
  Bytes toStreamBytes() {
    final streamWriter = StreamWriter();
    streamWriter.writeBytes32(coinName);
    streamWriter.writeUint32(height);
    return streamWriter.toBytes();
  }

  factory RequestPuzzleSolution.fromBytes(Bytes bytes) {
    final reader = StreamReader(bytes);
    return RequestPuzzleSolution.fromStreamReader(reader);
  }

  factory RequestPuzzleSolution.fromStreamReader(StreamReader reader) {
    final coinName = reader.readBytes32();
    final height = reader.readUint32();
    return RequestPuzzleSolution(coinName, height);
  }
}

class PuzzleSolutionResponse {
  final Bytes32 coinName;
  final int height;
  final Program puzzle;
  final Program solution;

  PuzzleSolutionResponse(this.coinName, this.height, this.puzzle, this.solution);

  Bytes toStreamBytes() {
    final streamWriter = StreamWriter();
    streamWriter.writeBytes32(coinName);
    streamWriter.writeUint32(height);
    streamWriter.writeBytes(puzzle.toBytes());
    streamWriter.writeBytes(solution.toBytes());
    return streamWriter.toBytes();
  }

  factory PuzzleSolutionResponse.fromBytes(Bytes bytes) {
    final reader = StreamReader(bytes);
    return PuzzleSolutionResponse.fromStreamReader(reader);
  }

  factory PuzzleSolutionResponse.fromStreamReader(StreamReader reader) {
    final coinName = reader.readBytes32();
    final height = reader.readUint32();
    final puzzle = Program.fromBytes(reader.readBytes());
    final solution = Program.fromBytes(reader.readBytes());
    return PuzzleSolutionResponse(coinName, height, puzzle, solution);
  }
}

class RespondPuzzleSolution extends ChiaProtocolMessage {
  final PuzzleSolutionResponse response;

  @override
  Bytes get data => toStreamBytes();

  RespondPuzzleSolution(this.response)
      : super(
          msgType: ProtocolMessageTypes.respondPuzzleSolution,
          data: response.toStreamBytes(),
        );

  @override
  Bytes toStreamBytes() {
    return response.toStreamBytes();
  }

  factory RespondPuzzleSolution.fromBytes(Bytes bytes) {
    final reader = StreamReader(bytes);
    return RespondPuzzleSolution.fromStreamReader(reader);
  }

  factory RespondPuzzleSolution.fromStreamReader(StreamReader reader) {
    return RespondPuzzleSolution(PuzzleSolutionResponse.fromStreamReader(reader));
  }
}

class RejectPuzzleSolution extends ChiaProtocolMessage {
  final Bytes32 coinName;
  final int height;

  @override
  Bytes get data => toStreamBytes();

  RejectPuzzleSolution(this.coinName, this.height)
      : super(
          msgType: ProtocolMessageTypes.rejectPuzzleSolution,
          data: coinName,
        );

  @override
  Bytes toStreamBytes() {
    final streamWriter = StreamWriter();
    streamWriter.writeBytes32(coinName);
    streamWriter.writeUint32(height);
    return streamWriter.toBytes();
  }

  factory RejectPuzzleSolution.fromBytes(Bytes bytes) {
    final reader = StreamReader(bytes);
    return RejectPuzzleSolution.fromStreamReader(reader);
  }

  factory RejectPuzzleSolution.fromStreamReader(StreamReader reader) {
    final coinName = reader.readBytes32();
    final height = reader.readUint32();
    return RejectPuzzleSolution(coinName, height);
  }
}

class SendTransaction extends ChiaProtocolMessage {
  final SpendBundle transaction;

  SendTransaction(this.transaction)
      : super(
          msgType: ProtocolMessageTypes.sendTransaction,
          data: transaction.toBytes(),
        );

  @override
  Bytes toStreamBytes() {
    return transaction.toBytes();
  }

  factory SendTransaction.fromBytes(Bytes bytes) {
    final reader = StreamReader(bytes);
    return SendTransaction.fromStreamReader(reader);
  }

  factory SendTransaction.fromStreamReader(StreamReader reader) {
    final transaction = SpendBundle.fromBytes(reader.readBytes());
    return SendTransaction(transaction);
  }
}

class TransactionAck extends ChiaProtocolMessage {
  final Bytes32 txid;
  final int status; // MempoolInclusionStatus
  final String? error;

  TransactionAck(this.txid, this.status, {this.error})
      : super(
          msgType: ProtocolMessageTypes.transactionAck,
          data: Bytes([]),
        );

  @override
  Bytes toStreamBytes() {
    final streamWriter = StreamWriter();
    streamWriter.writeBytes32(txid);
    streamWriter.writeUint8(status);
    if (error != null) {
      streamWriter.writeString(error!);
    } else {
      streamWriter.writeString('');
    }
    return streamWriter.toBytes();
  }

  factory TransactionAck.fromBytes(Bytes bytes) {
    final reader = StreamReader(bytes);
    return TransactionAck.fromStreamReader(reader);
  }

  factory TransactionAck.fromStreamReader(StreamReader reader) {
    final txid = reader.readBytes32();
    final status = reader.readUint8();
    final error = reader.readString();
    return TransactionAck(txid, status, error: error.isNotEmpty ? error : null);
  }
}

class NewPeakWallet extends ChiaProtocolMessage {
  final Bytes32 headerHash;
  final int height;
  final BigInt weight;
  final int forkPointWithPreviousPeak;

  NewPeakWallet(this.headerHash, this.height, this.weight, this.forkPointWithPreviousPeak)
      : super(
          msgType: ProtocolMessageTypes.newPeakWallet,
          data: headerHash,
        );

  @override
  Bytes toStreamBytes() {
    final streamWriter = StreamWriter();
    streamWriter.writeBytes32(headerHash);
    streamWriter.writeUint32(height);
    streamWriter.writeUint128(weight);
    streamWriter.writeUint32(forkPointWithPreviousPeak);
    return streamWriter.toBytes();
  }

  factory NewPeakWallet.fromBytes(Bytes bytes) {
    final reader = StreamReader(bytes);
    return NewPeakWallet.fromStreamReader(reader);
  }

  factory NewPeakWallet.fromStreamReader(StreamReader reader) {
    final headerHash = reader.readBytes32();
    final height = reader.readUint32();
    final weight = reader.readUint128();
    final forkPoint = reader.readUint32();
    return NewPeakWallet(headerHash, height, weight, forkPoint);
  }
}

enum RejectStateReason {
  reorg,
  exceededSubscriptionLimit,
}

enum MempoolRemoveReason {
  conflict,
  blockInclusion,
  poolFull,
  expired,
}
/* 
class RequestBlockHeader extends ChiaProtocolMessage {
  final int height;

  RequestBlockHeader(this.height)
      : super(
          msgType: ProtocolMessageTypes.requestBlockHeader,
          data: Bytes([]),
        );

  @override
  Bytes toStreamBytes() {
    final streamWriter = StreamWriter();
    streamWriter.writeUint32(height);
    return streamWriter.toBytes();
  }

  factory RequestBlockHeader.fromBytes(Bytes bytes) {
    final reader = StreamReader(bytes);
    final height = reader.readUint32();
    return RequestBlockHeader(height);
  }
}

class RespondBlockHeader extends ChiaProtocolMessage {
  final HeaderBlock headerBlock;

  RespondBlockHeader(this.headerBlock)
      : super(
          msgType: ProtocolMessageTypes.respondBlockHeader,
          data: headerBlock.toBytes(),
        );

  @override
  Bytes toStreamBytes() {
    return headerBlock.toBytes();
  }

  factory RespondBlockHeader.fromBytes(Bytes bytes) {
    final headerBlock = HeaderBlock.fromBytes(bytes);
    return RespondBlockHeader(headerBlock);
  }
} */

class RejectHeaderRequest extends ChiaProtocolMessage {
  final int height;

  RejectHeaderRequest(this.height)
      : super(
          msgType: ProtocolMessageTypes.rejectHeaderRequest,
          data: Bytes([]),
        );

  @override
  Bytes toStreamBytes() {
    final streamWriter = StreamWriter();
    streamWriter.writeUint32(height);
    return streamWriter.toBytes();
  }

  factory RejectHeaderRequest.fromBytes(Bytes bytes) {
    final reader = StreamReader(bytes);
    return RejectHeaderRequest.fromStreamReader(reader);
  }

  factory RejectHeaderRequest.fromStreamReader(StreamReader reader) {
    final height = reader.readUint32();
    return RejectHeaderRequest(height);
  }
}

class RequestRemovals extends ChiaProtocolMessage {
  final int height;
  final Bytes32 headerHash;
  final List<Bytes32>? coinNames;

  RequestRemovals(this.height, this.headerHash, {this.coinNames})
      : super(
          msgType: ProtocolMessageTypes.requestRemovals,
          data: Bytes([]),
        );

  @override
  Bytes toStreamBytes() {
    final streamWriter = StreamWriter();
    streamWriter.writeUint32(height);
    streamWriter.writeBytes32(headerHash);
    if (coinNames != null) {
      streamWriter.writeUint32(coinNames!.length);
      for (var coinName in coinNames!) {
        streamWriter.writeBytes32(coinName);
      }
    } else {
      streamWriter.writeUint32(0);
    }
    return streamWriter.toBytes();
  }

  factory RequestRemovals.fromBytes(Bytes bytes) {
    final reader = StreamReader(bytes);
    return RequestRemovals.fromStreamReader(reader);
  }

  factory RequestRemovals.fromStreamReader(StreamReader reader) {
    final height = reader.readUint32();
    final headerHash = reader.readBytes32();
    final coinNamesLength = reader.readUint32();
    List<Bytes32>? coinNames;
    if (coinNamesLength > 0) {
      coinNames = List.generate(coinNamesLength, (_) => reader.readBytes32());
    }
    return RequestRemovals(height, headerHash, coinNames: coinNames);
  }
}

class RespondRemovals extends ChiaProtocolMessage {
  final int height;
  final Bytes32 headerHash;
  final List<Tuple2<Bytes32, Coin?>> coins;
  final List<Tuple2<Bytes32, Bytes>>? proofs;

  RespondRemovals(this.height, this.headerHash, this.coins, {this.proofs})
      : super(
          msgType: ProtocolMessageTypes.respondRemovals,
          data: Bytes([]),
        );

  @override
  Bytes toStreamBytes() {
    final streamWriter = StreamWriter();
    streamWriter.writeUint32(height);
    streamWriter.writeBytes32(headerHash);
    streamWriter.writeUint32(coins.length);
    for (var coin in coins) {
      streamWriter.writeBytes32(coin.item1);
      if (coin.item2 != null) {
        streamWriter.writeBytes(coin.item2!.toBytes());
      } else {
        streamWriter.writeBytes(Bytes([]));
      }
    }
    if (proofs != null) {
      streamWriter.writeUint32(proofs!.length);
      for (var proof in proofs!) {
        streamWriter.writeBytes32(proof.item1);
        streamWriter.writeBytes(proof.item2);
      }
    } else {
      streamWriter.writeUint32(0);
    }
    return streamWriter.toBytes();
  }

  factory RespondRemovals.fromBytes(Bytes bytes) {
    final reader = StreamReader(bytes);
    return RespondRemovals.fromStreamReader(reader);
  }

  factory RespondRemovals.fromStreamReader(StreamReader reader) {
    final height = reader.readUint32();
    final headerHash = reader.readBytes32();
    final coinsLength = reader.readUint32();
    final coins = List.generate(coinsLength, (_) {
      final coinName = reader.readBytes32();
      final coinBytes = reader.readBytes();
      final coin = coinBytes.isNotEmpty ? Coin.fromBytes(coinBytes) : null;
      return Tuple2(coinName, coin);
    });
    final proofsLength = reader.readUint32();
    List<Tuple2<Bytes32, Bytes>>? proofs;
    if (proofsLength > 0) {
      proofs = List.generate(proofsLength, (_) {
        final proofName = reader.readBytes32();
        final proofBytes = reader.readBytes();
        return Tuple2(proofName, proofBytes);
      });
    }
    return RespondRemovals(height, headerHash, coins, proofs: proofs);
  }
}

class RejectRemovalsRequest extends ChiaProtocolMessage {
  final int height;
  final Bytes32 headerHash;

  RejectRemovalsRequest(this.height, this.headerHash)
      : super(
          msgType: ProtocolMessageTypes.rejectRemovalsRequest,
          data: Bytes([]),
        );

  @override
  Bytes toStreamBytes() {
    final streamWriter = StreamWriter();
    streamWriter.writeUint32(height);
    streamWriter.writeBytes32(headerHash);
    return streamWriter.toBytes();
  }

  factory RejectRemovalsRequest.fromBytes(Bytes bytes) {
    final reader = StreamReader(bytes);
    return RejectRemovalsRequest.fromStreamReader(reader);
  }

  factory RejectRemovalsRequest.fromStreamReader(StreamReader reader) {
    final height = reader.readUint32();
    final headerHash = reader.readBytes32();
    return RejectRemovalsRequest(height, headerHash);
  }
}

class RequestAdditions extends ChiaProtocolMessage {
  final int height;
  final Bytes32? headerHash;
  final List<Bytes32>? puzzleHashes;

  RequestAdditions(this.height, {this.headerHash, this.puzzleHashes})
      : super(
          msgType: ProtocolMessageTypes.requestAdditions,
          data: Bytes([]),
        );

  @override
  Bytes toStreamBytes() {
    final streamWriter = StreamWriter();
    streamWriter.writeUint32(height);
    if (headerHash != null) {
      streamWriter.writeBytes32(headerHash!);
    } else {
      streamWriter.writeBytes(Bytes([]));
    }
    if (puzzleHashes != null) {
      streamWriter.writeUint32(puzzleHashes!.length);
      for (var puzzleHash in puzzleHashes!) {
        streamWriter.writeBytes32(puzzleHash);
      }
    } else {
      streamWriter.writeUint32(0);
    }
    return streamWriter.toBytes();
  }

  factory RequestAdditions.fromBytes(Bytes bytes) {
    final reader = StreamReader(bytes);
    return RequestAdditions.fromStreamReader(reader);
  }

  factory RequestAdditions.fromStreamReader(StreamReader reader) {
    final height = reader.readUint32();
    final headerHash = reader.readBytes32();
    final puzzleHashesLength = reader.readUint32();
    List<Bytes32>? puzzleHashes;
    if (puzzleHashesLength > 0) {
      puzzleHashes = List.generate(puzzleHashesLength, (_) => reader.readBytes32());
    }
    return RequestAdditions(height, headerHash: headerHash, puzzleHashes: puzzleHashes);
  }
}

class RespondAdditions extends ChiaProtocolMessage {
  final int height;
  final Bytes32 headerHash;
  final List<Tuple2<Bytes32, List<Coin>>> coins;
  final List<Tuple3<Bytes32, Bytes, Bytes?>>? proofs;

  RespondAdditions(this.height, this.headerHash, this.coins, {this.proofs})
      : super(
          msgType: ProtocolMessageTypes.respondAdditions,
          data: Bytes([]),
        );

  @override
  Bytes toStreamBytes() {
    final streamWriter = StreamWriter();
    streamWriter.writeUint32(height);
    streamWriter.writeBytes32(headerHash);
    streamWriter.writeUint32(coins.length);
    for (var coin in coins) {
      streamWriter.writeBytes32(coin.item1);
      streamWriter.writeUint32(coin.item2.length);
      for (var c in coin.item2) {
        streamWriter.writeBytes(c.toBytes());
      }
    }
    if (proofs != null) {
      streamWriter.writeUint32(proofs!.length);
      for (var proof in proofs!) {
        streamWriter.writeBytes32(proof.item1);
        streamWriter.writeBytes(proof.item2);
        if (proof.item3 != null) {
          streamWriter.writeBytes(proof.item3!);
        } else {
          streamWriter.writeBytes(Bytes([]));
        }
      }
    } else {
      streamWriter.writeUint32(0);
    }
    return streamWriter.toBytes();
  }

  factory RespondAdditions.fromBytes(Bytes bytes) {
    final reader = StreamReader(bytes);
    return RespondAdditions.fromStreamReader(reader);
  }

  factory RespondAdditions.fromStreamReader(StreamReader reader) {
    final height = reader.readUint32();
    final headerHash = reader.readBytes32();
    final coinsLength = reader.readUint32();
    final coins = List.generate(coinsLength, (_) {
      final coinName = reader.readBytes32();
      final coinCount = reader.readUint32();
      final coinList = List.generate(coinCount, (_) => Coin.fromBytes(reader.readBytes()));
      return Tuple2(coinName, coinList);
    });
    final proofsLength = reader.readUint32();
    List<Tuple3<Bytes32, Bytes, Bytes?>>? proofs;
    if (proofsLength > 0) {
      proofs = List.generate(proofsLength, (_) {
        final proofName = reader.readBytes32();
        final proofBytes = reader.readBytes();
        final optionalBytes = reader.readBytes();
        final optional = optionalBytes.isNotEmpty ? optionalBytes : null;
        return Tuple3(proofName, proofBytes, optional);
      });
    }
    return RespondAdditions(height, headerHash, coins, proofs: proofs);
  }
}

class RejectAdditionsRequest extends ChiaProtocolMessage {
  final int height;
  final Bytes32 headerHash;

  RejectAdditionsRequest(this.height, this.headerHash)
      : super(
          msgType: ProtocolMessageTypes.rejectAdditionsRequest,
          data: Bytes([]),
        );

  @override
  Bytes toStreamBytes() {
    final streamWriter = StreamWriter();
    streamWriter.writeUint32(height);
    streamWriter.writeBytes32(headerHash);
    return streamWriter.toBytes();
  }

  factory RejectAdditionsRequest.fromBytes(Bytes bytes) {
    final reader = StreamReader(bytes);
    return RejectAdditionsRequest.fromStreamReader(reader);
  }

  factory RejectAdditionsRequest.fromStreamReader(StreamReader reader) {
    final height = reader.readUint32();
    final headerHash = reader.readBytes32();
    return RejectAdditionsRequest(height, headerHash);
  }
}
/* 
class RespondBlockHeaders extends ChiaProtocolMessage {
  final int startHeight;
  final int endHeight;
  final List<HeaderBlock> headerBlocks;

  RespondBlockHeaders(this.startHeight, this.endHeight, this.headerBlocks)
      : super(
          msgType: ProtocolMessageTypes.respondBlockHeaders,
          data: Bytes([]),
        );

  @override
  Bytes toStreamBytes() {
    final streamWriter = StreamWriter();
    streamWriter.writeUint32(startHeight);
    streamWriter.writeUint32(endHeight);
    streamWriter.writeUint32(headerBlocks.length);
    for (var block in headerBlocks) {
      streamWriter.writeBytes(block.toBytes());
    }
    return streamWriter.toBytes();
  }

  factory RespondBlockHeaders.fromBytes(Bytes bytes) {
    final reader = StreamReader(bytes);
    final startHeight = reader.readUint32();
    final endHeight = reader.readUint32();
    final blocksLength = reader.readUint32();
    final headerBlocks =
        List.generate(blocksLength, (_) => HeaderBlock.fromBytes(reader.readBytes()));
    return RespondBlockHeaders(startHeight, endHeight, headerBlocks);
  }
} */

class RejectBlockHeaders extends ChiaProtocolMessage {
  final int startHeight;
  final int endHeight;

  RejectBlockHeaders(this.startHeight, this.endHeight)
      : super(
          msgType: ProtocolMessageTypes.rejectBlockHeaders,
          data: Bytes([]),
        );

  @override
  Bytes toStreamBytes() {
    final streamWriter = StreamWriter();
    streamWriter.writeUint32(startHeight);
    streamWriter.writeUint32(endHeight);
    return streamWriter.toBytes();
  }

  factory RejectBlockHeaders.fromBytes(Bytes bytes) {
    final reader = StreamReader(bytes);
    return RejectBlockHeaders.fromStreamReader(reader);
  }

  factory RejectBlockHeaders.fromStreamReader(StreamReader reader) {
    final startHeight = reader.readUint32();
    final endHeight = reader.readUint32();
    return RejectBlockHeaders(startHeight, endHeight);
  }
}

class RequestBlockHeaders extends ChiaProtocolMessage {
  final int startHeight;
  final int endHeight;
  final bool returnFilter;

  RequestBlockHeaders(this.startHeight, this.endHeight, this.returnFilter)
      : super(
          msgType: ProtocolMessageTypes.requestBlockHeaders,
          data: Bytes([]),
        );

  @override
  Bytes toStreamBytes() {
    final streamWriter = StreamWriter();
    streamWriter.writeUint32(startHeight);
    streamWriter.writeUint32(endHeight);
    streamWriter.writeBool(returnFilter);
    return streamWriter.toBytes();
  }

  factory RequestBlockHeaders.fromBytes(Bytes bytes) {
    final reader = StreamReader(bytes);
    return RequestBlockHeaders.fromStreamReader(reader);
  }

  factory RequestBlockHeaders.fromStreamReader(StreamReader reader) {
    final startHeight = reader.readUint32();
    final endHeight = reader.readUint32();
    final returnFilter = reader.readBool();
    return RequestBlockHeaders(startHeight, endHeight, returnFilter);
  }
}

class RequestHeaderBlocks extends ChiaProtocolMessage {
  final int startHeight;
  final int endHeight;

  RequestHeaderBlocks(this.startHeight, this.endHeight)
      : super(
          msgType: ProtocolMessageTypes.requestHeaderBlocks,
          data: Bytes([]),
        );

  @override
  Bytes toStreamBytes() {
    final streamWriter = StreamWriter();
    streamWriter.writeUint32(startHeight);
    streamWriter.writeUint32(endHeight);
    return streamWriter.toBytes();
  }

  factory RequestHeaderBlocks.fromBytes(Bytes bytes) {
    final reader = StreamReader(bytes);
    return RequestHeaderBlocks.fromStreamReader(reader);
  }

  factory RequestHeaderBlocks.fromStreamReader(StreamReader reader) {
    final startHeight = reader.readUint32();
    final endHeight = reader.readUint32();
    return RequestHeaderBlocks(startHeight, endHeight);
  }
}

class RejectHeaderBlocks extends ChiaProtocolMessage {
  final int startHeight;
  final int endHeight;

  RejectHeaderBlocks(this.startHeight, this.endHeight)
      : super(
          msgType: ProtocolMessageTypes.rejectHeaderBlocks,
          data: Bytes([]),
        );

  @override
  Bytes toStreamBytes() {
    final streamWriter = StreamWriter();
    streamWriter.writeUint32(startHeight);
    streamWriter.writeUint32(endHeight);
    return streamWriter.toBytes();
  }

  factory RejectHeaderBlocks.fromBytes(Bytes bytes) {
    final reader = StreamReader(bytes);
    return RejectHeaderBlocks.fromStreamReader(reader);
  }

  factory RejectHeaderBlocks.fromStreamReader(StreamReader reader) {
    final startHeight = reader.readUint32();
    final endHeight = reader.readUint32();
    return RejectHeaderBlocks(startHeight, endHeight);
  }
}

/* 
class RespondHeaderBlocks extends ChiaProtocolMessage {
  final int startHeight;
  final int endHeight;
  final List<HeaderBlock> headerBlocks;

  RespondHeaderBlocks(this.startHeight, this.endHeight, this.headerBlocks)
      : super(
          msgType: ProtocolMessageTypes.respondHeaderBlocks,
          data: Bytes([]),
        );

  @override
  Bytes toStreamBytes() {
    final streamWriter = StreamWriter();
    streamWriter.writeUint32(startHeight);
    streamWriter.writeUint32(endHeight);
    streamWriter.writeUint32(headerBlocks.length);
    for (var block in headerBlocks) {
      streamWriter.writeBytes(block.toBytes());
    }
    return streamWriter.toBytes();
  }

  factory RespondHeaderBlocks.fromBytes(Bytes bytes) {
    final reader = StreamReader(bytes);
    final startHeight = reader.readUint32();
    final endHeight = reader.readUint32();
    final blocksLength = reader.readUint32();
    final headerBlocks =
        List.generate(blocksLength, (_) => HeaderBlock.fromBytes(reader.readBytes()));
    return RespondHeaderBlocks(startHeight, endHeight, headerBlocks);
  }
}
 */
class RegisterForPhUpdates extends ChiaProtocolMessage {
  final List<Bytes32> puzzleHashes;
  final int minHeight;

  RegisterForPhUpdates(this.puzzleHashes, this.minHeight)
      : super(
          msgType: ProtocolMessageTypes.registerForPhUpdates,
          data: Bytes([]),
        );

  @override
  Bytes toStreamBytes() {
    final streamWriter = StreamWriter();
    streamWriter.writeUint32(puzzleHashes.length);
    for (var puzzleHash in puzzleHashes) {
      streamWriter.writeBytes32(puzzleHash);
    }
    streamWriter.writeUint32(minHeight);
    return streamWriter.toBytes();
  }

  factory RegisterForPhUpdates.fromBytes(Bytes bytes) {
    final reader = StreamReader(bytes);
    return RegisterForPhUpdates.fromStreamReader(reader);
  }

  factory RegisterForPhUpdates.fromStreamReader(StreamReader reader) {
    final puzzleHashesLength = reader.readUint32();
    final puzzleHashes = List.generate(puzzleHashesLength, (_) => reader.readBytes32());
    final minHeight = reader.readUint32();
    return RegisterForPhUpdates(puzzleHashes, minHeight);
  }
}

class RespondToPhUpdates extends ChiaProtocolMessage {
  final List<Bytes32> puzzleHashes;
  final int minHeight;
  final List<CoinState> coinStates;

  RespondToPhUpdates(this.puzzleHashes, this.minHeight, this.coinStates)
      : super(
          msgType: ProtocolMessageTypes.respondToPhUpdates,
          data: Bytes([]),
        );

  @override
  Bytes toStreamBytes() {
    final streamWriter = StreamWriter();
    streamWriter.writeUint32(puzzleHashes.length);
    for (var puzzleHash in puzzleHashes) {
      streamWriter.writeBytes32(puzzleHash);
    }
    streamWriter.writeUint32(minHeight);
    streamWriter.writeUint32(coinStates.length);
    for (var coinState in coinStates) {
      streamWriter.writeBytes(coinState.toStreamBytes());
    }
    return streamWriter.toBytes();
  }

  factory RespondToPhUpdates.fromBytes(Bytes bytes) {
    final reader = StreamReader(bytes);
    return RespondToPhUpdates.fromStreamReader(reader);
  }

  factory RespondToPhUpdates.fromStreamReader(StreamReader reader) {
    final puzzleHashesLength = reader.readUint32();
    final puzzleHashes = List.generate(puzzleHashesLength, (_) => reader.readBytes32());
    final minHeight = reader.readUint32();
    final coinStatesLength = reader.readUint32();
    final coinStates = List.generate(coinStatesLength, (_) => CoinState.fromStreamReader(reader));
    return RespondToPhUpdates(puzzleHashes, minHeight, coinStates);
  }
}

class RegisterForCoinUpdates extends ChiaProtocolMessage {
  final List<Bytes32> coinIds;
  final int minHeight;

  RegisterForCoinUpdates(this.coinIds, this.minHeight)
      : super(
          msgType: ProtocolMessageTypes.registerForCoinUpdates,
          data: Bytes([]),
        );

  @override
  Bytes toStreamBytes() {
    final streamWriter = StreamWriter();
    streamWriter.writeUint32(coinIds.length);
    for (var coinId in coinIds) {
      streamWriter.writeBytes32(coinId);
    }
    streamWriter.writeUint32(minHeight);
    return streamWriter.toBytes();
  }

  factory RegisterForCoinUpdates.fromBytes(Bytes bytes) {
    final reader = StreamReader(bytes);
    return RegisterForCoinUpdates.fromStreamReader(reader);
  }

  factory RegisterForCoinUpdates.fromStreamReader(StreamReader reader) {
    final coinIdsLength = reader.readUint32();
    final coinIds = List.generate(coinIdsLength, (_) => reader.readBytes32());
    final minHeight = reader.readUint32();
    return RegisterForCoinUpdates(coinIds, minHeight);
  }
}

class RespondToCoinUpdates extends ChiaProtocolMessage {
  final List<Bytes32> coinIds;
  final int minHeight;
  final List<CoinState> coinStates;

  RespondToCoinUpdates(this.coinIds, this.minHeight, this.coinStates)
      : super(
          msgType: ProtocolMessageTypes.respondToCoinUpdates,
          data: Bytes([]),
        );

  @override
  Bytes toStreamBytes() {
    final streamWriter = StreamWriter();
    streamWriter.writeUint32(coinIds.length);
    for (var coinId in coinIds) {
      streamWriter.writeBytes32(coinId);
    }
    streamWriter.writeUint32(minHeight);
    streamWriter.writeUint32(coinStates.length);
    for (var coinState in coinStates) {
      streamWriter.writeBytes(coinState.toStreamBytes());
    }
    return streamWriter.toBytes();
  }

  factory RespondToCoinUpdates.fromBytes(Bytes bytes) {
    final reader = StreamReader(bytes);
    return RespondToCoinUpdates.fromStreamReader(reader);
  }

  factory RespondToCoinUpdates.fromStreamReader(StreamReader reader) {
    final coinIdsLength = reader.readUint32();
    final coinIds = List.generate(coinIdsLength, (_) => reader.readBytes32());
    final minHeight = reader.readUint32();
    final coinStatesLength = reader.readUint32();
    final coinStates = List.generate(coinStatesLength, (_) => CoinState.fromStreamReader(reader));
    return RespondToCoinUpdates(coinIds, minHeight, coinStates);
  }
}

class CoinStateUpdate extends ChiaProtocolMessage {
  final int height;
  final int forkHeight;
  final Bytes32 peakHash;
  final List<CoinState> items;

  CoinStateUpdate(this.height, this.forkHeight, this.peakHash, this.items)
      : super(
          msgType: ProtocolMessageTypes.coinStateUpdate,
          data: Bytes([]),
        );

  @override
  Bytes toStreamBytes() {
    final streamWriter = StreamWriter();
    streamWriter.writeUint32(height);
    streamWriter.writeUint32(forkHeight);
    streamWriter.writeBytes32(peakHash);
    streamWriter.writeUint32(items.length);
    for (var item in items) {
      streamWriter.writeBytes(item.toStreamBytes());
    }
    return streamWriter.toBytes();
  }

  factory CoinStateUpdate.fromBytes(Bytes bytes) {
    final reader = StreamReader(bytes);
    return CoinStateUpdate.fromStreamReader(reader);
  }

  factory CoinStateUpdate.fromStreamReader(StreamReader reader) {
    final height = reader.readUint32();
    final forkHeight = reader.readUint32();
    final peakHash = reader.readBytes32();
    final itemsLength = reader.readUint32();
    final items = List.generate(itemsLength, (_) => CoinState.fromStreamReader(reader));
    return CoinStateUpdate(height, forkHeight, peakHash, items);
  }
}

class RequestChildren extends ChiaProtocolMessage {
  final Bytes32 coinName;

  RequestChildren(this.coinName)
      : super(
          msgType: ProtocolMessageTypes.requestChildren,
          data: Bytes([]),
        );

  @override
  Bytes toStreamBytes() {
    final streamWriter = StreamWriter();
    streamWriter.writeBytes32(coinName);
    return streamWriter.toBytes();
  }

  factory RequestChildren.fromBytes(Bytes bytes) {
    final reader = StreamReader(bytes);
    return RequestChildren.fromStreamReader(reader);
  }

  factory RequestChildren.fromStreamReader(StreamReader reader) {
    final coinName = reader.readBytes32();
    return RequestChildren(coinName);
  }
}

class RespondChildren extends ChiaProtocolMessage {
  final List<CoinState> coinStates;

  RespondChildren(this.coinStates)
      : super(
          msgType: ProtocolMessageTypes.respondChildren,
          data: Bytes([]),
        );

  @override
  Bytes toStreamBytes() {
    final streamWriter = StreamWriter();
    streamWriter.writeUint32(coinStates.length);
    for (var coinState in coinStates) {
      streamWriter.writeBytes(coinState.toStreamBytes());
    }
    return streamWriter.toBytes();
  }

  factory RespondChildren.fromBytes(Bytes bytes) {
    final reader = StreamReader(bytes);
    return RespondChildren.fromStreamReader(reader);
  }

  factory RespondChildren.fromStreamReader(StreamReader reader) {
    final coinStatesLength = reader.readUint32();
    final coinStates = List.generate(coinStatesLength, (_) => CoinState.fromStreamReader(reader));
    return RespondChildren(coinStates);
  }
}

class RequestSesInfo extends ChiaProtocolMessage {
  final int startHeight;
  final int endHeight;

  RequestSesInfo(this.startHeight, this.endHeight)
      : super(
          msgType: ProtocolMessageTypes.requestSesInfo,
          data: Bytes([]),
        );

  @override
  Bytes toStreamBytes() {
    final streamWriter = StreamWriter();
    streamWriter.writeUint32(startHeight);
    streamWriter.writeUint32(endHeight);
    return streamWriter.toBytes();
  }

  factory RequestSesInfo.fromBytes(Bytes bytes) {
    final reader = StreamReader(bytes);
    return RequestSesInfo.fromStreamReader(reader);
  }

  factory RequestSesInfo.fromStreamReader(StreamReader reader) {
    final startHeight = reader.readUint32();
    final endHeight = reader.readUint32();
    return RequestSesInfo(startHeight, endHeight);
  }
}

class RespondSesInfo extends ChiaProtocolMessage {
  final List<Bytes32> rewardChainHash;
  final List<List<int>> heights;

  RespondSesInfo(this.rewardChainHash, this.heights)
      : super(
          msgType: ProtocolMessageTypes.respondSesInfo,
          data: Bytes([]),
        );

  @override
  Bytes toStreamBytes() {
    final streamWriter = StreamWriter();
    streamWriter.writeUint32(rewardChainHash.length);
    for (var hash in rewardChainHash) {
      streamWriter.writeBytes32(hash);
    }
    streamWriter.writeUint32(heights.length);
    for (var heightList in heights) {
      streamWriter.writeUint32(heightList.length);
      for (var height in heightList) {
        streamWriter.writeUint32(height);
      }
    }
    return streamWriter.toBytes();
  }

  factory RespondSesInfo.fromBytes(Bytes bytes) {
    final reader = StreamReader(bytes);
    return RespondSesInfo.fromStreamReader(reader);
  }

  factory RespondSesInfo.fromStreamReader(StreamReader reader) {
    final rewardChainHashLength = reader.readUint32();
    final rewardChainHash = List.generate(rewardChainHashLength, (_) => reader.readBytes32());
    final heightsLength = reader.readUint32();
    final heights = List.generate(heightsLength, (_) {
      final innerLength = reader.readUint32();
      return List.generate(innerLength, (_) => reader.readUint32());
    });
    return RespondSesInfo(rewardChainHash, heights);
  }
}

class RequestFeeEstimates extends ChiaProtocolMessage {
  final List<int> timeTargets;

  RequestFeeEstimates(this.timeTargets)
      : super(
          msgType: ProtocolMessageTypes.requestFeeEstimates,
          data: Bytes([]),
        );

  @override
  Bytes toStreamBytes() {
    final streamWriter = StreamWriter();
    streamWriter.writeUint32(timeTargets.length);
    for (var target in timeTargets) {
      streamWriter.writeUint64(target);
    }
    return streamWriter.toBytes();
  }

  factory RequestFeeEstimates.fromBytes(Bytes bytes) {
    final reader = StreamReader(bytes);
    return RequestFeeEstimates.fromStreamReader(reader);
  }

  factory RequestFeeEstimates.fromStreamReader(StreamReader reader) {
    final length = reader.readUint32();
    final timeTargets = List.generate(length, (_) => reader.readUint64());
    return RequestFeeEstimates(timeTargets);
  }
}

class RespondFeeEstimates extends ChiaProtocolMessage {
  final FeeEstimateGroup estimates;

  RespondFeeEstimates(this.estimates)
      : super(
          msgType: ProtocolMessageTypes.respondFeeEstimates,
          data: estimates.toStreamBytes(),
        );

  @override
  Bytes toStreamBytes() {
    return estimates.toStreamBytes();
  }

  factory RespondFeeEstimates.fromBytes(Bytes bytes) {
    final reader = StreamReader(bytes);
    return RespondFeeEstimates.fromStreamReader(reader);
  }

  factory RespondFeeEstimates.fromStreamReader(StreamReader reader) {
    final estimates = FeeEstimateGroup.fromStreamReader(reader);
    return RespondFeeEstimates(estimates);
  }
}

class RequestRemovePuzzleSubscriptions extends ChiaProtocolMessage {
  final List<Bytes32>? puzzleHashes;

  RequestRemovePuzzleSubscriptions({this.puzzleHashes})
      : super(
          msgType: ProtocolMessageTypes.requestRemovePuzzleSubscriptions,
          data: Bytes([]),
        );

  @override
  Bytes toStreamBytes() {
    final streamWriter = StreamWriter();
    if (puzzleHashes != null) {
      streamWriter.writeUint32(puzzleHashes!.length);
      for (var hash in puzzleHashes!) {
        streamWriter.writeBytes32(hash);
      }
    } else {
      streamWriter.writeUint32(0);
    }
    return streamWriter.toBytes();
  }

  factory RequestRemovePuzzleSubscriptions.fromBytes(Bytes bytes) {
    final reader = StreamReader(bytes);
    final length = reader.readUint32();
    List<Bytes32>? puzzleHashes;
    if (length > 0) {
      puzzleHashes = List.generate(length, (_) => reader.readBytes32());
    }
    return RequestRemovePuzzleSubscriptions(puzzleHashes: puzzleHashes);
  }
}

class RespondRemovePuzzleSubscriptions extends ChiaProtocolMessage {
  final List<Bytes32> puzzleHashes;

  RespondRemovePuzzleSubscriptions(this.puzzleHashes)
      : super(
          msgType: ProtocolMessageTypes.respondRemovePuzzleSubscriptions,
          data: Bytes([]),
        );

  @override
  Bytes toStreamBytes() {
    final streamWriter = StreamWriter();
    streamWriter.writeUint32(puzzleHashes.length);
    for (var hash in puzzleHashes) {
      streamWriter.writeBytes32(hash);
    }
    return streamWriter.toBytes();
  }

  factory RespondRemovePuzzleSubscriptions.fromBytes(Bytes bytes) {
    final reader = StreamReader(bytes);
    final length = reader.readUint32();
    final puzzleHashes = List.generate(length, (_) => reader.readBytes32());
    return RespondRemovePuzzleSubscriptions(puzzleHashes);
  }
}

class RequestRemoveCoinSubscriptions extends ChiaProtocolMessage {
  final List<Bytes32>? coinIds;

  RequestRemoveCoinSubscriptions({this.coinIds})
      : super(
          msgType: ProtocolMessageTypes.requestRemoveCoinSubscriptions,
          data: Bytes([]),
        );

  @override
  Bytes toStreamBytes() {
    final streamWriter = StreamWriter();
    if (coinIds != null) {
      streamWriter.writeUint32(coinIds!.length);
      for (var id in coinIds!) {
        streamWriter.writeBytes32(id);
      }
    } else {
      streamWriter.writeUint32(0);
    }
    return streamWriter.toBytes();
  }

  factory RequestRemoveCoinSubscriptions.fromBytes(Bytes bytes) {
    final reader = StreamReader(bytes);
    final length = reader.readUint32();
    List<Bytes32>? coinIds;
    if (length > 0) {
      coinIds = List.generate(length, (_) => reader.readBytes32());
    }
    return RequestRemoveCoinSubscriptions(coinIds: coinIds);
  }
}

class RespondRemoveCoinSubscriptions extends ChiaProtocolMessage {
  final List<Bytes32> coinIds;

  RespondRemoveCoinSubscriptions(this.coinIds)
      : super(
          msgType: ProtocolMessageTypes.respondRemoveCoinSubscriptions,
          data: Bytes([]),
        );

  @override
  Bytes toStreamBytes() {
    final streamWriter = StreamWriter();
    streamWriter.writeUint32(coinIds.length);
    for (var id in coinIds) {
      streamWriter.writeBytes32(id);
    }
    return streamWriter.toBytes();
  }

  factory RespondRemoveCoinSubscriptions.fromBytes(Bytes bytes) {
    final reader = StreamReader(bytes);
    final length = reader.readUint32();
    final coinIds = List.generate(length, (_) => reader.readBytes32());
    return RespondRemoveCoinSubscriptions(coinIds);
  }
}

class CoinStateFilters {
  final bool includeSpent;
  final bool includeUnspent;
  final bool includeHinted;
  final int minAmount;

  CoinStateFilters({
    required this.includeSpent,
    required this.includeUnspent,
    required this.includeHinted,
    required this.minAmount,
  });

  Bytes toStreamBytes() {
    final streamWriter = StreamWriter();
    streamWriter.writeBool(includeSpent);
    streamWriter.writeBool(includeUnspent);
    streamWriter.writeBool(includeHinted);
    streamWriter.writeUint64(minAmount);
    return streamWriter.toBytes();
  }

  factory CoinStateFilters.fromBytes(Bytes bytes) {
    final reader = StreamReader(bytes);
    return CoinStateFilters.fromStreamReader(reader);
  }

  factory CoinStateFilters.fromStreamReader(StreamReader reader) {
    final includeSpent = reader.readBool();
    final includeUnspent = reader.readBool();
    final includeHinted = reader.readBool();
    final minAmount = reader.readUint64();
    return CoinStateFilters(
      includeSpent: includeSpent,
      includeUnspent: includeUnspent,
      includeHinted: includeHinted,
      minAmount: minAmount,
    );
  }
}

class RequestPuzzleState extends ChiaProtocolMessage {
  final List<Bytes32> puzzleHashes;
  final int? previousHeight;
  final Bytes32 headerHash;
  final CoinStateFilters filters;
  final bool subscribeWhenFinished;

  RequestPuzzleState(
    this.puzzleHashes,
    this.previousHeight,
    this.headerHash,
    this.filters,
    this.subscribeWhenFinished,
  ) : super(
          msgType: ProtocolMessageTypes.requestPuzzleState,
          data: Bytes([]),
        );

  @override
  Bytes toStreamBytes() {
    final streamWriter = StreamWriter();
    streamWriter.writeUint32(puzzleHashes.length);
    for (var hash in puzzleHashes) {
      streamWriter.writeBytes32(hash);
    }
    if (previousHeight != null) {
      streamWriter.writeUint32(previousHeight!);
    } else {
      streamWriter.writeUint32(0);
    }
    streamWriter.writeBytes32(headerHash);
    streamWriter.writeBytes(filters.toStreamBytes());
    streamWriter.writeBool(subscribeWhenFinished);
    return streamWriter.toBytes();
  }

  factory RequestPuzzleState.fromBytes(Bytes bytes) {
    final reader = StreamReader(bytes);
    return RequestPuzzleState.fromStreamReader(reader);
  }

  factory RequestPuzzleState.fromStreamReader(StreamReader reader) {
    final puzzleHashesLength = reader.readUint32();
    final puzzleHashes = List.generate(puzzleHashesLength, (_) => reader.readBytes32());
    final previousHeight = reader.readUint32();
    final headerHash = reader.readBytes32();
    final filters = CoinStateFilters.fromStreamReader(reader);
    final subscribeWhenFinished = reader.readBool();
    return RequestPuzzleState(
      puzzleHashes,
      previousHeight == 0 ? null : previousHeight,
      headerHash,
      filters,
      subscribeWhenFinished,
    );
  }
}

class RespondPuzzleState extends ChiaProtocolMessage {
  final List<Bytes32> puzzleHashes;
  final int height;
  final Bytes32 headerHash;
  final bool isFinished;
  final List<CoinState> coinStates;

  RespondPuzzleState(
    this.puzzleHashes,
    this.height,
    this.headerHash,
    this.isFinished,
    this.coinStates,
  ) : super(
          msgType: ProtocolMessageTypes.respondPuzzleState,
          data: Bytes([]),
        );

  @override
  Bytes toStreamBytes() {
    final streamWriter = StreamWriter();
    streamWriter.writeUint32(puzzleHashes.length);
    for (var hash in puzzleHashes) {
      streamWriter.writeBytes32(hash);
    }
    streamWriter.writeUint32(height);
    streamWriter.writeBytes32(headerHash);
    streamWriter.writeBool(isFinished);
    streamWriter.writeUint32(coinStates.length);
    for (var coinState in coinStates) {
      streamWriter.writeBytes(coinState.toStreamBytes());
    }
    return streamWriter.toBytes();
  }

  factory RespondPuzzleState.fromBytes(Bytes bytes) {
    final reader = StreamReader(bytes);
    return RespondPuzzleState.fromStreamReader(reader);
  }

  factory RespondPuzzleState.fromStreamReader(StreamReader reader) {
    final puzzleHashesLength = reader.readUint32();
    final puzzleHashes = List.generate(puzzleHashesLength, (_) => reader.readBytes32());
    final height = reader.readUint32();
    final headerHash = reader.readBytes32();
    final isFinished = reader.readBool();
    final coinStatesLength = reader.readUint32();
    final coinStates = List.generate(
      coinStatesLength,
      (_) => CoinState.fromStreamReader(reader),
    );
    return RespondPuzzleState(puzzleHashes, height, headerHash, isFinished, coinStates);
  }
}

class RejectPuzzleState extends ChiaProtocolMessage {
  final RejectStateReason reason;

  RejectPuzzleState(this.reason)
      : super(
          msgType: ProtocolMessageTypes.rejectPuzzleState,
          data: Bytes([]),
        );

  @override
  Bytes toStreamBytes() {
    final streamWriter = StreamWriter();
    streamWriter.writeUint8(reason.index);
    return streamWriter.toBytes();
  }

  factory RejectPuzzleState.fromBytes(Bytes bytes) {
    final reader = StreamReader(bytes);
    return RejectPuzzleState.fromStreamReader(reader);
  }

  factory RejectPuzzleState.fromStreamReader(StreamReader reader) {
    final reasonIndex = reader.readUint8();
    final reason = RejectStateReason.values[reasonIndex];
    return RejectPuzzleState(reason);
  }
}

class RequestCoinState extends ChiaProtocolMessage {
  final List<Bytes32> coinIds;
  final int? previousHeight;
  final Bytes32 headerHash;
  final bool subscribe;

  RequestCoinState(
    this.coinIds,
    this.previousHeight,
    this.headerHash,
    this.subscribe,
  ) : super(
          msgType: ProtocolMessageTypes.requestCoinState,
          data: Bytes([]),
        );

  @override
  Bytes toStreamBytes() {
    final streamWriter = StreamWriter();
    streamWriter.writeUint32(coinIds.length);
    for (var id in coinIds) {
      streamWriter.writeBytes32(id);
    }
    if (previousHeight != null) {
      streamWriter.writeUint32(previousHeight!);
    } else {
      streamWriter.writeUint32(0);
    }
    streamWriter.writeBytes32(headerHash);
    streamWriter.writeBool(subscribe);
    return streamWriter.toBytes();
  }

  factory RequestCoinState.fromBytes(Bytes bytes) {
    final reader = StreamReader(bytes);
    return RequestCoinState.fromStreamReader(reader);
  }

  factory RequestCoinState.fromStreamReader(StreamReader reader) {
    final coinIdsLength = reader.readUint32();
    final coinIds = List.generate(coinIdsLength, (_) => reader.readBytes32());
    final previousHeight = reader.readUint32();
    final headerHash = reader.readBytes32();
    final subscribe = reader.readBool();
    return RequestCoinState(
      coinIds,
      previousHeight == 0 ? null : previousHeight,
      headerHash,
      subscribe,
    );
  }
}

class RespondCoinState extends ChiaProtocolMessage {
  final List<Bytes32> coinIds;
  final List<CoinState> coinStates;

  RespondCoinState(this.coinIds, this.coinStates)
      : super(
          msgType: ProtocolMessageTypes.respondCoinState,
          data: Bytes([]),
        );

  @override
  Bytes toStreamBytes() {
    final streamWriter = StreamWriter();
    streamWriter.writeUint32(coinIds.length);
    for (var id in coinIds) {
      streamWriter.writeBytes32(id);
    }
    streamWriter.writeUint32(coinStates.length);
    for (var coinState in coinStates) {
      streamWriter.writeBytes(coinState.toStreamBytes());
    }
    return streamWriter.toBytes();
  }

  factory RespondCoinState.fromBytes(Bytes bytes) {
    final reader = StreamReader(bytes);
    return RespondCoinState.fromStreamReader(reader);
  }

  factory RespondCoinState.fromStreamReader(StreamReader reader) {
    final coinIdsLength = reader.readUint32();
    final coinIds = List.generate(coinIdsLength, (_) => reader.readBytes32());
    final coinStatesLength = reader.readUint32();
    final coinStates = List.generate(
      coinStatesLength,
      (_) => CoinState.fromStreamReader(reader),
    );
    return RespondCoinState(coinIds, coinStates);
  }
}

class RejectCoinState extends ChiaProtocolMessage {
  final RejectStateReason reason;

  RejectCoinState(this.reason)
      : super(
          msgType: ProtocolMessageTypes.rejectCoinState,
          data: Bytes([]),
        );

  @override
  Bytes toStreamBytes() {
    final streamWriter = StreamWriter();
    streamWriter.writeUint8(reason.index);
    return streamWriter.toBytes();
  }

  factory RejectCoinState.fromBytes(Bytes bytes) {
    final reader = StreamReader(bytes);
    return RejectCoinState.fromStreamReader(reader);
  }

  factory RejectCoinState.fromStreamReader(StreamReader reader) {
    final reasonIndex = reader.readUint8();
    final reason = RejectStateReason.values[reasonIndex];
    return RejectCoinState(reason);
  }
}

class RemovedMempoolItem {
  final Bytes32 transactionId;
  final MempoolRemoveReason reason;

  RemovedMempoolItem(this.transactionId, this.reason);

  Bytes toStreamBytes() {
    final streamWriter = StreamWriter();
    streamWriter.writeBytes32(transactionId);
    streamWriter.writeUint8(reason.index);
    return streamWriter.toBytes();
  }

  factory RemovedMempoolItem.fromBytes(Bytes bytes) {
    final reader = StreamReader(bytes);
    final transactionId = reader.readBytes32();
    final reasonIndex = reader.readUint8();
    final reason = MempoolRemoveReason.values[reasonIndex];
    return RemovedMempoolItem(transactionId, reason);
  }
}

class MempoolItemsAdded extends ChiaProtocolMessage {
  final List<Bytes32> transactionIds;

  MempoolItemsAdded(this.transactionIds)
      : super(
          msgType: ProtocolMessageTypes.mempoolItemsAdded,
          data: Bytes([]),
        );

  @override
  Bytes toStreamBytes() {
    final streamWriter = StreamWriter();
    streamWriter.writeUint32(transactionIds.length);
    for (var id in transactionIds) {
      streamWriter.writeBytes32(id);
    }
    return streamWriter.toBytes();
  }

  factory MempoolItemsAdded.fromBytes(Bytes bytes) {
    final reader = StreamReader(bytes);
    final length = reader.readUint32();
    final transactionIds = List.generate(length, (_) => reader.readBytes32());
    return MempoolItemsAdded(transactionIds);
  }
}

class MempoolItemsRemoved extends ChiaProtocolMessage {
  final List<RemovedMempoolItem> removedItems;

  MempoolItemsRemoved(this.removedItems)
      : super(
          msgType: ProtocolMessageTypes.mempoolItemsRemoved,
          data: Bytes([]),
        );

  @override
  Bytes toStreamBytes() {
    final streamWriter = StreamWriter();
    streamWriter.writeUint32(removedItems.length);
    for (var item in removedItems) {
      streamWriter.writeBytes(item.toStreamBytes());
    }
    return streamWriter.toBytes();
  }

  factory MempoolItemsRemoved.fromBytes(Bytes bytes) {
    final reader = StreamReader(bytes);
    final length = reader.readUint32();
    final removedItems =
        List.generate(length, (_) => RemovedMempoolItem.fromBytes(reader.readBytes()));
    return MempoolItemsRemoved(removedItems);
  }
}

class RequestCostInfo extends ChiaProtocolMessage {
  RequestCostInfo()
      : super(
          msgType: ProtocolMessageTypes.requestCostInfo,
          data: Bytes([]),
        );

  @override
  Bytes toStreamBytes() {
    return Bytes([]);
  }

  factory RequestCostInfo.fromBytes(Bytes bytes) {
    return RequestCostInfo();
  }
}

class RespondCostInfo extends ChiaProtocolMessage {
  final int maxTransactionCost;
  final int maxBlockCost;
  final int maxMempoolCost;
  final int mempoolCost;
  final int mempoolFee;
  final int bumpFeePerCost;

  RespondCostInfo(
    this.maxTransactionCost,
    this.maxBlockCost,
    this.maxMempoolCost,
    this.mempoolCost,
    this.mempoolFee,
    this.bumpFeePerCost,
  ) : super(
          msgType: ProtocolMessageTypes.respondCostInfo,
          data: Bytes([]),
        );

  @override
  Bytes toStreamBytes() {
    final streamWriter = StreamWriter();
    streamWriter.writeUint64(maxTransactionCost);
    streamWriter.writeUint64(maxBlockCost);
    streamWriter.writeUint64(maxMempoolCost);
    streamWriter.writeUint64(mempoolCost);
    streamWriter.writeUint64(mempoolFee);
    streamWriter.writeUint8(bumpFeePerCost);
    return streamWriter.toBytes();
  }

  factory RespondCostInfo.fromBytes(Bytes bytes) {
    final reader = StreamReader(bytes);
    final maxTransactionCost = reader.readUint64();
    final maxBlockCost = reader.readUint64();
    final maxMempoolCost = reader.readUint64();
    final mempoolCost = reader.readUint64();
    final mempoolFee = reader.readUint64();
    final bumpFeePerCost = reader.readUint8();
    return RespondCostInfo(
      maxTransactionCost,
      maxBlockCost,
      maxMempoolCost,
      mempoolCost,
      mempoolFee,
      bumpFeePerCost,
    );
  }
}

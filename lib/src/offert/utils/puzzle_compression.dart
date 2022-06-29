import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/nft0/puzzles/nft_transfer_program/nft_transfer_program.clvm.hex.dart';
import '../../nft0/puzzles/nft_metadata_updater/nft_metadata_updater.clvm.hex.dart';
import '../../nft0/puzzles/nft_state_layer/nft_state_layer.clvm.hex.dart';
import '../puzzles/settlement_payments/settlement_payments.clvm.hex.dart';

import '../../nft0/puzzles/nft_ownership_layer/nft_ownership_layer.clvm.hex.dart';
import '../../standard/puzzles/p2_delegated_puzzle_or_hidden_puzzle/p2_delegated_puzzle_or_hidden_puzzle.clvm.hex.dart';

final ZDICT = [
  p2DelegatedPuzzleOrHiddenPuzzleProgram.toBytes() + catProgram.toBytes(),
  offertProgram.toBytes(),
  (singletonTopLayerProgram.toBytes() +
      nftStateLayerProgram.toBytes() +
      nftOwnershipLayer.toBytes() +
      nftMetadataUpdaterProgram.toBytes() +
      nftTransferProgram.toBytes()),
  // more dictionaries go here
];

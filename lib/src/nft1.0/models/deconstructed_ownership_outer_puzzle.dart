import 'package:chia_crypto_utils/chia_crypto_utils.dart';

// _, current_owner, transfer_program, inner_puzzle = curried_args

class DeconstructedOwnershipOuterPuzzle {

  DeconstructedOwnershipOuterPuzzle({
    required this.currentOwner,
    required this.transferProgram,
    required this.innerPuzzle,
  });
  final Bytes currentOwner;
  final Program transferProgram;

  final Program innerPuzzle;
}

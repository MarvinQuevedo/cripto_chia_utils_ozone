import 'package:chia_crypto_utils/chia_crypto_utils.dart';

// _, current_owner, transfer_program, inner_puzzle = curried_args

class DeconstructedTransferProgramPuzzle {

  DeconstructedTransferProgramPuzzle(
      {required this.royaltyAddressP,
      required this.royaltyPercentage,
      required this.singletonStruct,});
  final int royaltyPercentage;
  final Program royaltyAddressP;
  final Program singletonStruct;
}

import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class DeconstructedSingletonPuzzle {

  DeconstructedSingletonPuzzle({
    required this.sinletonModHash,
    required this.launcherPuzzhash,
    required this.singletonLauncherId,
    required this.innerPuzzle,
  });
  final Puzzlehash sinletonModHash;
  final Puzzlehash launcherPuzzhash;
  final Puzzlehash singletonLauncherId;
  final Program innerPuzzle;
}

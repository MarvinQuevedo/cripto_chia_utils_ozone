import 'package:chia_crypto_utils/chia_crypto_utils.dart';

/// Create DID inner puzzle
/// [p2Puzzle] Standard P2 puzzle
///[recoveryList] A list of DIDs used for the recovery
///[numOfBackupIdsNeeded] Need how many DIDs for the recovery
///[launcherId] ID of the launch coin
///[metadata] DID customized metadata
///
///Returns  DID inner puzzle [Program]
Program createDidInnerpuz(
    {required Program p2Puzzle,
    required List<Bytes> recoveryList,
    required int numOfBackupIdsNeeded,
    required Bytes launcherId,
    Program? metadata}) {
  if (metadata == null) {
    metadata = Program.fromBytes(Bytes.empty);
  }

  final backupIdsHash = Program.list(recoveryList.map((e) => Program.fromBytes(e)).toList()).hash();
  final sinletonStruct = Program.cons(
      Program.fromBytes(SINGLETON_MOD_HASH),
      Program.cons(
        Program.fromBytes(launcherId),
        Program.fromBytes(singletonLauncherProgram.hash()),
      ));

  return DID_INNERPUZ_MOD.curry([
    p2Puzzle,
    Program.fromBytes(backupIdsHash),
    Program.fromInt(numOfBackupIdsNeeded),
    sinletonStruct,
    metadata
  ]);
}

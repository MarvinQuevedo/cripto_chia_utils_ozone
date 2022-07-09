import 'package:chia_crypto_utils/chia_crypto_utils.dart';

import '../../utils/serialization.dart';

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
      Program.fromBytes(LAUNCHER_PUZZLE_HASH),
    ),
  );

  return DID_INNERPUZ_MOD.curry([
    p2Puzzle,
    Program.fromBytes(backupIdsHash),
    Program.fromInt(numOfBackupIdsNeeded),
    sinletonStruct,
    metadata
  ]);
}

/// Create a full puzzle of DID
///   innerpuz: DID inner puzzle
/// launcher_id:
///
/// Return DID full puzzle
Program createDidFullpuz(Program innerpuz, Bytes launcherId) {
  final mod_hash = SINGLETON_MOD_HASH;
  final sinletonStruct = Program.cons(
    Program.fromBytes(mod_hash),
    Program.cons(
      Program.fromBytes(launcherId),
      Program.fromBytes(LAUNCHER_PUZZLE_HASH),
    ),
  );

  return singletonTopLayerProgram.curry([sinletonStruct, innerpuz]);
}

/// Convert the metadata dict to a Chialisp program
///  [metadata]: User defined metadata
///
///  Return Chialisp program
Program metadataToProgram(Map<Bytes, dynamic> metadata) {
  final kvList = <Program>[];

  metadata.forEach((key, value) {
    kvList.add(Program.cons(
      Program.fromBytes(key),
      Program.fromBytes(serializeItem(value)),
    ));
  });

  return Program.list(kvList);
}

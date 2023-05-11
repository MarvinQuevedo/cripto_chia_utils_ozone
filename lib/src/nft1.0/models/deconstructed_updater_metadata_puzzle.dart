import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class DeconstructedUpdateMetadataPuzzle {
  DeconstructedUpdateMetadataPuzzle({
    required this.metadata,
    required this.metadataUpdaterHash,
    required this.innerPuzzle,
  });
  final Program metadata;
  final Program metadataUpdaterHash;

  final Program innerPuzzle;

  List<Program> get metadataList => metadata.toList();
}

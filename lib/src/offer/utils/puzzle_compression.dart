import 'dart:io';
import 'dart:typed_data';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/nft0/puzzles/nft_transfer_program/nft_transfer_program.clvm.hex.dart';
import 'package:quiver/iterables.dart';
import '../../nft0/puzzles/nft_metadata_updater/nft_metadata_updater.clvm.hex.dart';
import '../../nft0/puzzles/nft_state_layer/nft_state_layer.clvm.hex.dart';
import '../puzzles/settlement_payments/settlement_payments.clvm.hex.dart';

import '../../nft0/puzzles/nft_ownership_layer/nft_ownership_layer.clvm.hex.dart';
import '../../standard/puzzles/p2_delegated_puzzle_or_hidden_puzzle/p2_delegated_puzzle_or_hidden_puzzle.clvm.hex.dart';

final ZDICT = [
  p2DelegatedPuzzleOrHiddenPuzzleProgram.toBytes() + catProgram.toBytes(),
  offertProgram.toBytes(),
  singletonTopLayerV1Program.toBytes() +
      nftStateLayerProgram.toBytes() +
      nftOwnershipLayer.toBytes() +
      nftMetadataUpdaterProgram.toBytes() +
      nftTransferProgram.toBytes(),
  // more dictionaries go here
];

final LATEST_VERSION = ZDICT.length;

class CompressionVersionError {
  late final String message;
  CompressionVersionError(int versionNumber) {
    message =
        "The data is compressed with version ${versionNumber} and cannot be parsed. Update software and try again.";
  }
}

Bytes zDictForVersion(int version) {
  Bytes summedDict = Bytes.empty;
  final subList = ZDICT.sublist(0, version);
  print("zdict len ${subList.length}");
  for (var item in subList) {
    summedDict += item;
  }
  return summedDict;
}

Bytes compressWithZdict(Bytes blob, Bytes zdict) {
  final codec = ZLibCodec(dictionary: zdict);
  final compressObj = codec.encode(blob);
  return Bytes(compressObj);
}

Bytes decompressWithZdict(Bytes blob, Bytes zdict) {
  final codec = ZLibCodec(dictionary: zdict);
  final compressObj = codec.decode(blob);
  return Bytes(compressObj);
}

Bytes compressObjectWithPuzzles(Bytes objectBytes, int version) {
  final versionBlob = intToBytes(version, 2, Endian.big);
  final zdict = zDictForVersion(version);
  final compressedObjectBlob = compressWithZdict(objectBytes, zdict);
  return versionBlob + compressedObjectBlob;
}

Bytes decompressObjectWithPuzzles(Bytes compressedObjectBlob) {
  final blobIterator = compressedObjectBlob.iterator;
  final version = bytesToInt(blobIterator.extractBytesAndAdvance(2), Endian.big);
  if (version > LATEST_VERSION) {
    throw CompressionVersionError(version);
  }
  final zdict = zDictForVersion(version);
  print(zdict.length);
  print("zdict hash = ${zdict.sha256Hash()}");
  final objectBytes = decompressWithZdict(
      blobIterator.extractBytesAndAdvance(compressedObjectBlob.length - 2), zdict);
  return objectBytes;
}

int lowestBestVersion(List<Bytes> puzzleList, {int? maxVersion}) {
  if (maxVersion == null) {
    maxVersion = LATEST_VERSION;
  }
  int highestVersion = 1;
  for (var mod in puzzleList) {
    for (var v = 0; v < maxVersion; v++) {
      final version = v + 1;
      final dict = ZDICT[v];
      if (version > maxVersion) {
        break;
      }
      if (dict.contains(mod)) {
        highestVersion = max([highestVersion, version])!;
      }
    }
  }

  return highestVersion;
}

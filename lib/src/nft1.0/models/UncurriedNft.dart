import 'package:chia_crypto_utils/src/nft1.0/puzzles/nft_ownership_layer/nft_ownership_layer.clvm.hex.dart';

import '../../../chia_crypto_utils.dart';
import '../../clvm/keywords.dart';
import '../puzzles/nft_state_layer/nft_state_layer.clvm.hex.dart';

export '../puzzles/singleton_top_layer_v1_1/singleton_top_layer_v1_1.clvm.hex.dart';
export '../puzzles/nft_state_layer/nft_state_layer.clvm.hex.dart';
export '../puzzles/nft_ownership_layer/nft_ownership_layer.clvm.hex.dart';

/// A simple solution for uncurry NFT puzzle.

class UncurriedNFT {
  /// Initial the class with a full NFT puzzle, it will do a deep uncurry.
  /// This is the only place you need to change after modified the Chialisp curried parameters.

  final Program nftModHash;

  /// NFT module hash

  final Program nftStateLayer;

  /// NFT state layer puzzle
  final Program singletonStruct;

  ///  Singleton struct
  /// [singleton_mod_hash, singleton_launcher_id, launcher_puzhash]
  final Program singletonModHash;
  final Program singletonLauncherId;
  final Program launcherPuzhash;

  /// Metadata updater puzzle hash
  final Program metadataUpdaterHash;

  /// NFT metadata
  /// [("u", data_uris), ("h", data_hash)]
  final Program metadata;

  /// Puzzle hash of the transfer program
  final Program? transferProgram;

  //final Program settlementModHash;
  //final Program catModHash;

  ///  NFT metadata
  /// [("u", data_uris), ("h", data_hash)]
  final Program dataUris;
  final Program dataHash;
  final Program metaUris;
  final Program metaHash;
  final Program licenseUris;
  final Program licenseHash;
  final Program seriesNumber;
  final Program seriesTotal;

  ///  NFT state layer inner puzzle
  final Program innerPuzzle;

  /// p2 puzzle of the owner, either for ownership layer or standard
  final Program p2Puzzlehash;

  /// Owner's DID
  final Bytes? ownerDid;

  /// If the inner puzzle support the DID
  final bool supportDid;

  /// Puzzle hash of the ownership layer inner puzzle
  final Bytes? nftInnerPuzzleHash;

  /// Curried parameters of the transfer program
  /// [royalty_address, trade_price_percentage, settlement_mod_hash, cat_mod_hash]
  final Program? transferProgramCurryParams;

  final Bytes? royaltyAddress;
  final int? tradePricePercentage;

  UncurriedNFT._({
    required this.metaUris,
    required this.metaHash,
    required this.licenseUris,
    required this.licenseHash,
    required this.seriesNumber,
    required this.seriesTotal,
    required this.p2Puzzlehash,
    required this.supportDid,
    required this.nftInnerPuzzleHash,
    required this.transferProgram,
    required this.nftModHash,
    required this.nftStateLayer,
    required this.singletonStruct,
    required this.singletonModHash,
    required this.singletonLauncherId,
    required this.launcherPuzhash,
    required this.ownerDid,
    required this.metadataUpdaterHash,
    required this.transferProgramCurryParams,
    required this.royaltyAddress,
    required this.tradePricePercentage,
    required this.metadata,
    required this.dataUris,
    required this.dataHash,
    required this.innerPuzzle,
  });

  static UncurriedNFT uncurry(Program puzzle) {
    late Program singletonStruct;
    late Program nftStateLayer;
    late Program sinletonModHash;
    late Program singletonLauncherId;
    late Program launcherPuzzhash;
    late Program dataUris;
    late Program dataHash;
    late Program metaUris;
    late Program metaHash;
    late Program licenseUris;
    late Program licenseHash;
    late Program seriesNumber;
    late Program seriesTotal;

    final uncurried = puzzle.uncurry();
    final mod = uncurried.program;
    final curried_args = uncurried.arguments;
    if (mod.toSource() != singletonTopLayerProgram.toSource()) {
      throw ArgumentError("Cannot uncurry NFT puzzle, failed on singleton top layer: Mod ${mod}");
    }

    try {
      singletonStruct = curried_args[0];
      nftStateLayer = curried_args[1];

      sinletonModHash = singletonStruct.first();
      singletonLauncherId = singletonStruct.rest().first();
      launcherPuzzhash = singletonStruct.rest().rest();
    } catch (e) {
      throw ArgumentError("Cannot uncurry singleton top layer: Args ${curried_args}");
    }

    //TODO [curried_args] maybe would be has the method [rest], but not found, is posible the solution if corect

    final uncurriedNft = curried_args[1].first().uncurry();

    final nftMod = uncurriedNft.program;
    final nftArgs = uncurriedNft.arguments;

    if (nftMod.toSource() != nftStateLayerProgram.toSource()) {
      throw ArgumentError("Cannot uncurry NFT puzzle, failed on NFT state layer: Mod ${mod}");
    }
    try {
      final nftModHash = nftArgs[0];
      final metadata = nftArgs[1];
      final metadataUpdaterHash = nftArgs[2];
      final innerPuzzle = nftArgs[3];

      for (var kvPair in metadata.toList()) {
        if (bytesEqual(kvPair.first().atom, encodeBigInt(keywords['u']!))) {
          dataUris = kvPair.rest();
        }
        if (bytesEqual(kvPair.first().atom, encodeBigInt(keywords['h']!))) {
          dataHash = kvPair.rest();
        }
        if (bytesEqual(kvPair.first().atom, encodeBigInt(keywords['mu']!))) {
          metaUris = kvPair.rest();
        }
        if (bytesEqual(kvPair.first().atom, encodeBigInt(keywords['mmhu']!))) {
          metaHash = kvPair.rest();
        }
        if (bytesEqual(kvPair.first().atom, encodeBigInt(keywords['lu']!))) {
          licenseUris = kvPair.rest();
        }
        if (bytesEqual(kvPair.first().atom, encodeBigInt(keywords['lh']!))) {
          licenseHash = kvPair.rest();
        }
        if (bytesEqual(kvPair.first().atom, encodeBigInt(keywords['sn']!))) {
          seriesNumber = kvPair.rest();
        }
        if (bytesEqual(kvPair.first().atom, encodeBigInt(keywords['st']!))) {
          seriesTotal = kvPair.rest();
        }
      }

      Bytes? currentDid;
      Program? transferProgram;
      Program? transferProgramArgs;
      late Program p2Puzzle;
      Bytes? royaltyAddress;
      int? royaltyPercentage;
      Bytes? nftInnerPuzzleMod;

      final innerPuzzleUncurried = innerPuzzle.uncurry();
      final mod = innerPuzzleUncurried.arguments.first;
      final olArgs = innerPuzzleUncurried.arguments[1];

      bool supportsDid = false;

      if (mod == nftOwnershipLayer) {
        supportsDid = true;
        print("parsing ownership layer");
        final olArgsList = olArgs.toList();
        final currentDidP = olArgsList.first;
        transferProgram = olArgsList[1];
        p2Puzzle = olArgsList[2];
        final uncurriedTransferProgram = transferProgram.uncurry();
        //final transferProgramMod = uncurriedTransferProgram.program;
        final transferProgramArgs = uncurriedTransferProgram.arguments;
        final royaltyAddressP = transferProgramArgs.first;
        final royaltyPercentageP = transferProgramArgs[1];
        royaltyPercentage = royaltyPercentageP.toInt();
        royaltyAddress = royaltyAddressP.atom;
        currentDid = currentDidP.atom;
        if (currentDid.isEmpty) {
          currentDid = null;
        }
      } else {
        p2Puzzle = innerPuzzle;
      }

      return UncurriedNFT._(
          nftModHash: nftModHash,
          nftStateLayer: nftStateLayer,
          singletonStruct: singletonStruct,
          singletonModHash: sinletonModHash,
          singletonLauncherId: singletonLauncherId,
          launcherPuzhash: launcherPuzzhash,
          metadata: metadata,
          dataUris: dataUris,
          dataHash: dataHash,
          p2Puzzlehash: p2Puzzle,
          metaUris: metaUris,
          metaHash: metaHash,
          licenseUris: licenseUris,
          licenseHash: licenseHash,
          seriesNumber: seriesNumber,
          seriesTotal: seriesTotal,
          innerPuzzle: innerPuzzle,
          metadataUpdaterHash: metadataUpdaterHash,

          // TODO Set/Remove following fields after NFT1 implemented

          ownerDid: currentDid,
          supportDid: supportsDid,
          transferProgram: transferProgram,
          transferProgramCurryParams: transferProgramArgs,
          royaltyAddress: royaltyAddress,
          tradePricePercentage: royaltyPercentage,
          nftInnerPuzzleHash: nftInnerPuzzleMod);
    } catch (e) {
      throw Exception("Cannot uncurry NFT state layer: Args ${curried_args}");
    }
  }
}

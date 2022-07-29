// ignore_for_file: lines_longer_than_80_chars, avoid_equals_and_hash_code_on_mutable_classes

import 'package:bip39/bip39.dart' as bip39;
import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/core/models/singleton_wallet_vector.dart';
import 'package:chia_crypto_utils/src/utils/serialization.dart';

class WalletKeychain with ToBytesMixin {
  WalletKeychain({
    required this.hardenedMap,
    required this.unhardenedMap,
    required this.singletonWalletVectorsMap,
  });

  WalletKeychain._internal(
      {required this.hardenedMap,
      required this.unhardenedMap,
      required this.singletonWalletVectorsMap});

  factory WalletKeychain.fromWalletSets(List<WalletSet> walletSets) {
    final newHardenedMap = <Puzzlehash, WalletVector>{};
    final newUnhardenedMap = <Puzzlehash, UnhardenedWalletVector>{};

    for (final walletSet in walletSets) {
      newHardenedMap[walletSet.hardened.puzzlehash] = walletSet.hardened;
      newUnhardenedMap[walletSet.unhardened.puzzlehash] = walletSet.unhardened;
    }

    return WalletKeychain(
      hardenedMap: newHardenedMap,
      unhardenedMap: newUnhardenedMap,
      singletonWalletVectorsMap: {},
    );
  }

  factory WalletKeychain.fromCoreSecret(
    KeychainCoreSecret coreSecret, {
    int walletSize = 5,
    int plotNftWalletSize = 2,
  }) {
    final masterPrivateKey = coreSecret.masterPrivateKey;
    final walletVectors = <Puzzlehash, WalletVector>{};
    final unhardenedWalletVectors = <Puzzlehash, UnhardenedWalletVector>{};
    for (var i = 0; i < walletSize; i++) {
      final walletVector = WalletVector.fromPrivateKey(masterPrivateKey, i);
      final unhardenedWalletVector = UnhardenedWalletVector.fromPrivateKey(masterPrivateKey, i);

      walletVectors[walletVector.puzzlehash] = walletVector;
      unhardenedWalletVectors[unhardenedWalletVector.puzzlehash] = unhardenedWalletVector;
    }

    final singletonVectors = <JacobianPoint, SingletonWalletVector>{};
    for (var i = 0; i < plotNftWalletSize; i++) {
      final singletonWalletVector = SingletonWalletVector.fromMasterPrivateKey(masterPrivateKey, i);
      singletonVectors[singletonWalletVector.singletonOwnerPublicKey] = singletonWalletVector;
    }

    return WalletKeychain(
      hardenedMap: walletVectors,
      unhardenedMap: unhardenedWalletVectors,
      singletonWalletVectorsMap: singletonVectors,
    );
  }

  factory WalletKeychain.fromBytes(Bytes bytes) {
    final iterator = bytes.iterator;

    final hardenedWalletVectorMap = <Puzzlehash, WalletVector>{};
    final unhardenedWalletVectorMap = <Puzzlehash, UnhardenedWalletVector>{};
    final singletonWalletVectorMap = <JacobianPoint, SingletonWalletVector>{};

    final nHardenedWalletVectors = intFrom32BitsStream(iterator);
    for (var _ = 0; _ < nHardenedWalletVectors; _++) {
      final wv = WalletVector.fromStream(iterator);
      hardenedWalletVectorMap[wv.puzzlehash] = wv;
    }

    final nUnhardenedWalletVectors = intFrom32BitsStream(iterator);
    for (var _ = 0; _ < nUnhardenedWalletVectors; _++) {
      final wv = UnhardenedWalletVector.fromStream(iterator);
      unhardenedWalletVectorMap[wv.puzzlehash] = wv;
      for (final outerPuzzlehash in wv.assetIdtoOuterPuzzlehash.values) {
        unhardenedWalletVectorMap[outerPuzzlehash] = wv;
      }
    }

    final nSingletonWalletVectors = intFrom32BitsStream(iterator);
    for (var _ = 0; _ < nSingletonWalletVectors; _++) {
      final wv = SingletonWalletVector.fromStream(iterator);
      singletonWalletVectorMap[wv.singletonOwnerPublicKey] = wv;
    }

    return WalletKeychain(
      hardenedMap: hardenedWalletVectorMap,
      unhardenedMap: unhardenedWalletVectorMap,
      singletonWalletVectorsMap: singletonWalletVectorMap,
    );
  }

  @override
  Bytes toBytes() {
    return serializeListChia(hardenedWalletVectors) +
        serializeListChia(unhardenedWalletVectors) +
        serializeListChia(singletonWalletVectors);
  }

  final Map<Puzzlehash, WalletVector> hardenedMap;
  List<WalletVector> get hardenedWalletVectors => hardenedMap.values.toList();

  final Map<Puzzlehash, UnhardenedWalletVector> unhardenedMap;
  List<UnhardenedWalletVector> get unhardenedWalletVectors => unhardenedMap.values.toList();

  final Map<JacobianPoint, SingletonWalletVector> singletonWalletVectorsMap;

  List<SingletonWalletVector> get singletonWalletVectors =>
      singletonWalletVectorsMap.values.toList();

  SingletonWalletVector getNextSingletonWalletVector(PrivateKey masterPrivateKey) {
    final usedDerivationIndices = singletonWalletVectors.map((wv) => wv.derivationIndex).toList();

    var newDerivationIndex = 0;
    while (usedDerivationIndices.contains(newDerivationIndex)) {
      newDerivationIndex++;
    }

    final newSingletonWalletVector =
        SingletonWalletVector.fromMasterPrivateKey(masterPrivateKey, newDerivationIndex);

    singletonWalletVectorsMap[newSingletonWalletVector.singletonOwnerPublicKey] =
        newSingletonWalletVector;

    return newSingletonWalletVector;
  }

  SingletonWalletVector addSingletonWalletVectorForSingletonOwnerPublicKey(
    JacobianPoint singletonOwnerPublicKey,
    PrivateKey masterPrivateKey,
  ) {
    const maxIndexToCheck = 1000;
    for (var i = 0; i < maxIndexToCheck; i++) {
      final singletonOwnerSecretKey = masterSkToSingletonOwnerSk(masterPrivateKey, i);
      if (singletonOwnerSecretKey.getG1() == singletonOwnerPublicKey) {
        final newSingletonWalletVector =
            SingletonWalletVector.fromMasterPrivateKey(masterPrivateKey, i);
        singletonWalletVectorsMap[singletonOwnerPublicKey] = newSingletonWalletVector;
        return newSingletonWalletVector;
      }
    }
    throw ArgumentError(
      'Given singletonOwnerPublicKey does not match mnemonic up to derivation index $maxIndexToCheck',
    );
  }

  SingletonWalletVector? getSingletonWalletVector(JacobianPoint ownerPublicKey) {
    return singletonWalletVectorsMap[ownerPublicKey];
  }

  WalletVector? getWalletVector(Puzzlehash puzzlehash) {
    final walletVector = unhardenedMap[puzzlehash];

    if (walletVector != null) {
      return walletVector;
    }

    return hardenedMap[puzzlehash];
  }

  List<Puzzlehash> get puzzlehashes =>
      unhardenedMap.values.map((wv) => wv.puzzlehash).toSet().toList();
  List<Puzzlehash> getOuterPuzzleHashesForAssetId(Puzzlehash assetId) {
    if (!unhardenedMap.values.first.assetIdtoOuterPuzzlehash.containsKey(assetId)) {
      throw ArgumentError(
        'Puzzlehashes for given Asset Id are not in keychain',
      );
    }
    return unhardenedMap.values.map((v) => v.assetIdtoOuterPuzzlehash[assetId]!).toList();
  }

  void addOuterPuzzleHashesForAssetId(Puzzlehash assetId) {
    final entriesToAdd = <Puzzlehash, UnhardenedWalletVector>{};
    for (final walletVector in unhardenedMap.values) {
      final outerPuzzleHash = makeOuterPuzzleHash(walletVector.puzzlehash, assetId);
      walletVector.assetIdtoOuterPuzzlehash[assetId] = outerPuzzleHash;
      entriesToAdd[outerPuzzleHash] = walletVector;
    }

    unhardenedMap.addAll(entriesToAdd);

    /**
     * Add the hardened puzzlehashes for the assetId
     */
    final hardenedEntriesToAdd = <Puzzlehash, WalletVector>{};
    for (final walletVector in hardenedMap.values) {
      final outerPuzzleHash = WalletKeychain.makeOuterPuzzleHash(walletVector.puzzlehash, assetId);

      hardenedEntriesToAdd[outerPuzzleHash] = walletVector;
    }
    hardenedMap.addAll(hardenedEntriesToAdd);
  }

  static Puzzlehash makeOuterPuzzleHash(Puzzlehash innerPuzzleHash, Puzzlehash assetId) {
    final solution = Program.list([
      Program.fromBytes(CAT_MOD.hash()),
      Program.fromBytes(assetId.byteList),
      Program.fromBytes(innerPuzzleHash.byteList)
    ]);
    final result = curryAndTreehashProgram.run(solution);
    return Puzzlehash(result.program.atom);
  }

  static List<String> generateMnemonic({int strength = 256}) {
    return bip39.generateMnemonic(strength: strength).split(" ");
  }

  factory WalletKeychain.fromMap(Map<String, dynamic> json) {
    final hardened = json['hardenedMap'] as Map<String, dynamic>;
    final unhardened = json['unhardenedMap'] as Map<String, dynamic>;

    final hardenedMap = <Puzzlehash, WalletVector>{};
    final unhardenedMap = <Puzzlehash, UnhardenedWalletVector>{};

    for (final key in hardened.keys) {
      final value = hardened[key] as Map<String, dynamic>;
      final puzzlehash = Puzzlehash.fromHex(key);
      final walletVector = WalletVector.fromMap(value);
      hardenedMap[puzzlehash] = walletVector;
    }
    for (final key in unhardened.keys) {
      final value = unhardened[key] as Map<String, dynamic>;
      final puzzlehash = Puzzlehash.fromHex(key);
      final unhardenedWalletVector = UnhardenedWalletVector.fromMap(value);
      unhardenedMap[puzzlehash] = unhardenedWalletVector;
    }
    Map<JacobianPoint, SingletonWalletVector> singletonWalletVectorsMap = {};
    if (json['singletonWalletVectorsMap'] != null) {
      final singletonWalletVectorsMapJson =
          json['singletonWalletVectorsMap'] as Map<String, dynamic>;
      singletonWalletVectorsMap = {};
      for (final key in singletonWalletVectorsMapJson.keys) {
        final value = singletonWalletVectorsMapJson[key] as Map<String, dynamic>;
        final singletonOwnerPublicKey = JacobianPoint.fromBytesG1(Bytes.fromHex(key));
        final singletonWalletVector = SingletonWalletVector.fromMap(value);
        singletonWalletVectorsMap[singletonOwnerPublicKey] = singletonWalletVector;
      }
    }
    return WalletKeychain._internal(
        hardenedMap: hardenedMap,
        unhardenedMap: unhardenedMap,
        singletonWalletVectorsMap: singletonWalletVectorsMap);
  }
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    map['hardenedMap'] = hardenedMap.map((k, v) => MapEntry(k.toHex(), v.toMap()));
    map['unhardenedMap'] = unhardenedMap.map((k, v) => MapEntry(k.toHex(), v.toMap()));
    map['singletonWalletVectorsMap'] =
        singletonWalletVectorsMap.map((k, v) => MapEntry(k.toBytes().toHex(), v.toMap()));
    return map;
  }
}

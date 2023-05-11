import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:meta/meta.dart';

@immutable
class WalletVector with ToBytesMixin {
  WalletVector({
    required this.childPrivateKey,
    required this.puzzlehash,
    required this.derivationIndex,
    Map<Puzzlehash, Puzzlehash>? assetIdtoOuterPuzzlehash,
  }) {
    this.assetIdtoOuterPuzzlehash = assetIdtoOuterPuzzlehash ?? {};
  }
  factory WalletVector.fromStream(Iterator<int> iterator, int derivationIndex) {
    final childPrivateKey = PrivateKey.fromStream(iterator);
    final puzzlehash = Puzzlehash.fromStream(iterator);

    return WalletVector(
      childPrivateKey: childPrivateKey,
      puzzlehash: puzzlehash,
      derivationIndex: derivationIndex,
    );
  }

  factory WalletVector.fromBytes(Bytes bytes, int derivationIndex) {
    final iterator = bytes.iterator;
    return WalletVector.fromStream(iterator, derivationIndex);
  }

  factory WalletVector.fromPrivateKey(
    PrivateKey masterPrivateKey,
    int derivationIndex,
  ) {
    final childPrivateKeyHardened = masterSkToWalletSk(masterPrivateKey, derivationIndex);
    final childPublicKeyHardened = childPrivateKeyHardened.getG1();

    final puzzleHardened = getPuzzleFromPk(childPublicKeyHardened);
    final puzzlehashHardened = Puzzlehash(puzzleHardened.hash());

    return WalletVector(
      childPrivateKey: childPrivateKeyHardened,
      puzzlehash: puzzlehashHardened,
      derivationIndex: derivationIndex,
    );
  }

  Map<String, dynamic> toMap() {
    final assetIdtoOuterPuzzlehashMap = <String, String>{};
    assetIdtoOuterPuzzlehash.forEach((key, value) {
      assetIdtoOuterPuzzlehashMap[key.toHex()] = value.toHex();
    });

    final map = <String, dynamic>{};
    map['childPrivateKey'] = childPrivateKey.toHex();
    map['childPublicKey'] = childPublicKey.toHex();
    map['puzzlehash'] = puzzlehash.toHex();
    map['assetIdtoOuterPuzzlehash'] = assetIdtoOuterPuzzlehashMap;
    map['derivationIndex'] = derivationIndex;

    return map;
  }

  factory WalletVector.fromMap(Map<String, dynamic> map) {
    final childPrivateKey = PrivateKey.fromHex(map['childPrivateKey'] as String);
    //final childPublicKey = childPrivateKey.getG1();
    final puzzlehash = Puzzlehash.fromHex(map['puzzlehash'] as String);

    var assetIdtoOuterPuzzlehashMap = <Puzzlehash, Puzzlehash>{};
    var assetIdtoOuterPuzzlehash = Map<String, String>.from(
      map['assetIdtoOuterPuzzlehash'] as Map<String, dynamic>,
    );

    // ignore: cascade_invocations
    assetIdtoOuterPuzzlehash.forEach((key, value) {
      assetIdtoOuterPuzzlehashMap[Puzzlehash.fromHex(key)] = Puzzlehash.fromHex(value);
    });

    return WalletVector(
      childPrivateKey: childPrivateKey,
      derivationIndex: map['derivationIndex'] as int,
      puzzlehash: puzzlehash,
      assetIdtoOuterPuzzlehash: assetIdtoOuterPuzzlehashMap,
    );
  }

  final PrivateKey childPrivateKey;
  JacobianPoint get childPublicKey => childPrivateKey.getG1();
  final Puzzlehash puzzlehash;
  final int derivationIndex;
  late final Map<Puzzlehash, Puzzlehash> assetIdtoOuterPuzzlehash;

  WalletPuzzlehash get walletPuzzlehash =>
      WalletPuzzlehash.fromPuzzlehash(puzzlehash, derivationIndex);

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      childPrivateKey.hashCode ^
      childPublicKey.hashCode ^
      puzzlehash.hashCode ^
      derivationIndex.hashCode;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is WalletVector &&
            runtimeType == other.runtimeType &&
            childPrivateKey == other.childPrivateKey &&
            childPublicKey == other.childPublicKey &&
            puzzlehash == other.puzzlehash &&
            derivationIndex == other.derivationIndex;
  }

  @override
  Bytes toBytes() {
    return childPrivateKey.toBytes() + puzzlehash.byteList;
  }
}

class UnhardenedWalletVector extends WalletVector {
  UnhardenedWalletVector({
    required super.childPrivateKey,
    required super.puzzlehash,
    required super.derivationIndex,
    super.assetIdtoOuterPuzzlehash,
  });

  factory UnhardenedWalletVector.fromPrivateKey(
    PrivateKey masterPrivateKey,
    int derivationIndex,
  ) {
    final childPrivateKeyUnhardened =
        masterSkToWalletSkUnhardened(masterPrivateKey, derivationIndex);
    final childPublicKeyUnhardened = childPrivateKeyUnhardened.getG1();

    final puzzleUnhardened = getPuzzleFromPk(childPublicKeyUnhardened);
    final puzzlehashUnhardened = Puzzlehash(puzzleUnhardened.hash());

    return UnhardenedWalletVector(
      childPrivateKey: childPrivateKeyUnhardened,
      puzzlehash: puzzlehashUnhardened,
      derivationIndex: derivationIndex,
    );
  }

  @override
  Bytes toBytes() {
    var bytesList = <int>[];
    bytesList += childPrivateKey.toBytes();
    bytesList += puzzlehash.byteList;

    bytesList += intTo32Bits(assetIdtoOuterPuzzlehash.length);

    assetIdtoOuterPuzzlehash.forEach((assetId, outerPuzzlehash) {
      bytesList
        ..addAll(assetId)
        ..addAll(outerPuzzlehash);
    });

    return Bytes(bytesList);
  }

  factory UnhardenedWalletVector.fromStream(Iterator<int> iterator, int derivationIndex) {
    final childPrivateKey = PrivateKey.fromStream(iterator);
    final puzzlehash = Puzzlehash.fromStream(iterator);

    final assetIdToOuterPuzzlehashMap = <Puzzlehash, Puzzlehash>{};

    final assetIdMapLength = intFrom32BitsStream(iterator);

    for (var _ = 0; _ < assetIdMapLength; _++) {
      final assetId = Puzzlehash.fromStream(iterator);
      final outerPuzzlehash = Puzzlehash.fromStream(iterator);
      assetIdToOuterPuzzlehashMap[assetId] = outerPuzzlehash;
    }

    return UnhardenedWalletVector(
      childPrivateKey: childPrivateKey,
      puzzlehash: puzzlehash,
      assetIdtoOuterPuzzlehash: assetIdToOuterPuzzlehashMap,
      derivationIndex: derivationIndex,
    );
  }
  factory UnhardenedWalletVector.fromMap(Map<String, dynamic> map) {
    final childPrivateKey = PrivateKey.fromHex(map['childPrivateKey'] as String);

    final puzzlehash = Puzzlehash.fromHex(map['puzzlehash'] as String);

    var assetIdtoOuterPuzzlehashMap = <Puzzlehash, Puzzlehash>{};
    var assetIdtoOuterPuzzlehash = Map<String, String>.from(
      map['assetIdtoOuterPuzzlehash'] as Map<String, dynamic>,
    );

    // ignore: cascade_invocations
    assetIdtoOuterPuzzlehash.forEach((key, value) {
      assetIdtoOuterPuzzlehashMap[Puzzlehash.fromHex(key)] = Puzzlehash.fromHex(value);
    });

    return UnhardenedWalletVector(
      childPrivateKey: childPrivateKey,
      derivationIndex: map['derivationIndex'] as int,
      puzzlehash: puzzlehash,
      assetIdtoOuterPuzzlehash: assetIdtoOuterPuzzlehashMap,
    );
  }

  factory UnhardenedWalletVector.fromBytes(Bytes bytes, int derivationIndex) {
    final iterator = bytes.iterator;
    return UnhardenedWalletVector.fromStream(iterator, derivationIndex);
  }

  @override
  int get hashCode => super.hashCode ^ assetIdtoOuterPuzzlehash.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    final firstCheck = other is UnhardenedWalletVector &&
        runtimeType == other.runtimeType &&
        childPrivateKey == other.childPrivateKey &&
        childPublicKey == other.childPublicKey &&
        puzzlehash == other.puzzlehash &&
        derivationIndex == other.derivationIndex;

    if (!firstCheck) {
      return false;
    }

    for (final assetId in assetIdtoOuterPuzzlehash.keys) {
      if (other.assetIdtoOuterPuzzlehash[assetId] != assetIdtoOuterPuzzlehash[assetId]) {
        return false;
      }
    }
    return true;
  }
}

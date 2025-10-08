import 'dart:convert';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/bls/op_swu_g2.dart';
import 'package:chia_crypto_utils/src/bls/pairing.dart';
import 'package:quiver/collection.dart';

final basicSchemeDst = utf8.encode('BLS_SIG_BLS12381G2_XMD:SHA-256_SSWU_RO_NUL_');
final augSchemeDst = utf8.encode('BLS_SIG_BLS12381G2_XMD:SHA-256_SSWU_RO_AUG_');
final popSchemeDst = utf8.encode('BLS_SIG_BLS12381G2_XMD:SHA-256_SSWU_RO_POP_');
final popSchemePopDst = utf8.encode('BLS_POP_BLS12381G2_XMD:SHA-256_SSWU_RO_POP_');

JacobianPoint coreSignMpl(PrivateKey sk, List<int> message, List<int> dst) {
  return g2Map(message, dst) * sk.value;
}

bool coreVerifyMpl(JacobianPoint pk, List<int> message, JacobianPoint signature, List<int> dst) {
  if (!signature.isValid || !pk.isValid) {
    return false;
  }
  final q = g2Map(message, dst);
  final one = Fq12.one(defaultEc.q);
  final pairingResult = atePairingMulti([pk, -JacobianPoint.generateG1()], [q, signature]);
  return pairingResult == one;
}

JacobianPoint coreAggregateMpl(List<JacobianPoint> signatures) {
  if (signatures.isEmpty) {
    throw ArgumentError('Must aggregate at least 1 signature.');
  }
  var aggregate = signatures[0];
  assert(aggregate.isValid);
  for (final signature in signatures.sublist(1)) {
    assert(signature.isValid);
    aggregate += signature;
  }
  return aggregate;
}

bool coreAggregateVerify(
  List<JacobianPoint> pks,
  List<List<int>> ms,
  JacobianPoint signature,
  List<int> dst,
) {
  if (pks.length != ms.length || pks.isEmpty) {
    return false;
  }
  if (!signature.isValid) {
    return false;
  }
  final qs = [signature];
  final ps = [-JacobianPoint.generateG1()];
  for (var i = 0; i < pks.length; i++) {
    if (!pks[i].isValid) {
      return false;
    }
    qs.add(g2Map(ms[i], dst));
    ps.add(pks[i]);
  }
  return Fq12.one(defaultEc.q) == atePairingMulti(ps, qs);
}

class BasicSchemeMPL {
  /// Obtiene el provider BLS a usar (puede ser Dart o externo)
  static BlsProvider get _provider => BlsProvider.instance;

  static PrivateKey keyGen(List<int> seed) {
    return _provider.keyGen(seed);
  }

  static JacobianPoint sign(PrivateKey sk, List<int> message) {
    return _provider.sign(sk, message, basicSchemeDst);
  }

  static bool verify(JacobianPoint pk, List<int> message, JacobianPoint signature) {
    return _provider.verify(pk, message, signature, basicSchemeDst);
  }

  static JacobianPoint aggregate(List<JacobianPoint> signatures) {
    return _provider.aggregate(signatures);
  }

  static bool aggregateVerify(
    List<JacobianPoint> pks,
    List<List<int>> ms,
    JacobianPoint signature,
  ) {
    if (pks.length != ms.length || pks.isEmpty) {
      return false;
    }
    for (final msg in ms) {
      for (final match in ms) {
        if (msg != match && listsEqual(msg, match)) {
          return false;
        }
      }
    }
    return _provider.aggregateVerify(pks, ms, signature, basicSchemeDst);
  }

  static PrivateKey deriveChildSk(PrivateKey sk, int index) {
    return _provider.deriveChildSk(sk, index);
  }

  static PrivateKey deriveChildSkUnhardened(PrivateKey sk, int index) {
    return _provider.deriveChildSkUnhardened(sk, index);
  }

  static JacobianPoint deriveChildPkUnhardened(JacobianPoint pk, int index) {
    return _provider.deriveChildPkUnhardened(pk, index);
  }
}

class AugSchemeMPL {
  /// Obtiene el provider BLS a usar (puede ser Dart o externo)
  static BlsProvider get _provider => BlsProvider.instance;

  static PrivateKey keyGen(List<int> seed) {
    return _provider.keyGen(seed);
  }

  static JacobianPoint sign(PrivateKey sk, List<int> message) {
    final pk = sk.getG1();
    return _provider.sign(sk, pk.toBytes() + message, augSchemeDst);
  }

  static JacobianPoint hashAugScheme(JacobianPoint pk, List<int> message) {
    return g2Map(pk.toBytes() + message, augSchemeDst);
  }

  static Future<JacobianPoint> signAsync(PrivateKey sk, List<int> message) {
    return _provider.signAsync(sk, sk.getG1().toBytes() + message, augSchemeDst);
  }

  static bool verify(JacobianPoint pk, List<int> message, JacobianPoint signature) {
    return _provider.verify(pk, pk.toBytes() + message, signature, augSchemeDst);
  }

  static JacobianPoint aggregate(List<JacobianPoint> signatures) {
    return _provider.aggregate(signatures);
  }

  static bool aggregateVerify(
    List<JacobianPoint> pks,
    List<List<int>> ms,
    JacobianPoint signature,
  ) {
    if (pks.length != ms.length || pks.isEmpty) {
      return false;
    }
    final mPrimes = <List<int>>[];
    for (var i = 0; i < pks.length; i++) {
      mPrimes.add(pks[i].toBytes() + ms[i]);
    }
    return _provider.aggregateVerify(pks, mPrimes, signature, augSchemeDst);
  }

  static PrivateKey deriveChildSk(PrivateKey sk, int index) {
    return _provider.deriveChildSk(sk, index);
  }

  static PrivateKey deriveChildSkUnhardened(PrivateKey sk, int index) {
    return _provider.deriveChildSkUnhardened(sk, index);
  }

  static JacobianPoint deriveChildPkUnhardened(JacobianPoint pk, int index) {
    return _provider.deriveChildPkUnhardened(pk, index);
  }
}

class PopSchemeMPL {
  /// Obtiene el provider BLS a usar (puede ser Dart o externo)
  static BlsProvider get _provider => BlsProvider.instance;

  static PrivateKey keyGen(List<int> seed) {
    return _provider.keyGen(seed);
  }

  static JacobianPoint sign(PrivateKey sk, List<int> message) {
    return _provider.sign(sk, message, popSchemeDst);
  }

  static bool verify(JacobianPoint pk, List<int> message, JacobianPoint signature) {
    return _provider.verify(pk, message, signature, popSchemeDst);
  }

  static JacobianPoint aggregate(List<JacobianPoint> signatures) {
    return _provider.aggregate(signatures);
  }

  static bool aggregateVerify(
    List<JacobianPoint> pks,
    List<List<int>> ms,
    JacobianPoint signature,
  ) {
    if (pks.length != ms.length || pks.isEmpty) {
      return false;
    }
    for (final msg in ms) {
      for (final match in ms) {
        if (msg != match && listsEqual(msg, match)) {
          return false;
        }
      }
    }
    return _provider.aggregateVerify(pks, ms, signature, popSchemeDst);
  }

  static JacobianPoint popProve(PrivateKey sk) {
    final result = _provider.popProve(sk);
    if (result != null) return result;
    // Fallback a implementación Dart si el provider no soporta POP
    final pk = sk.getG1();
    return g2Map(pk.toBytes(), popSchemePopDst) * sk.value;
  }

  static bool popVerify(JacobianPoint pk, JacobianPoint proof) {
    final result = _provider.popVerify(pk, proof);
    if (result != null) return result;
    // Fallback a implementación Dart si el provider no soporta POP
    try {
      assert(proof.isValid);
      assert(pk.isValid);
      final q = g2Map(pk.toBytes(), popSchemePopDst);
      final one = Fq12.one(defaultEc.q);
      final pairingResult = atePairingMulti([pk, -JacobianPoint.generateG1()], [q, proof]);
      return pairingResult == one;
    } on AssertionError {
      return false;
    }
  }

  static bool fastAggregateVerify(
    List<JacobianPoint> pks,
    List<int> message,
    JacobianPoint signature,
  ) {
    return _provider.fastAggregateVerify(pks, message, signature, popSchemeDst);
  }

  static PrivateKey deriveChildSk(PrivateKey sk, int index) {
    return _provider.deriveChildSk(sk, index);
  }

  static PrivateKey deriveChildSkUnhardened(PrivateKey sk, int index) {
    return _provider.deriveChildSkUnhardened(sk, index);
  }

  static JacobianPoint deriveChildPkUnhardened(JacobianPoint pk, int index) {
    return _provider.deriveChildPkUnhardened(pk, index);
  }
}

/// Interfaz abstracta para operaciones BLS12-381
///
/// Esto permite usar diferentes implementaciones:
/// - DartBlsProvider: Implementación pura en Dart (actual)
/// - NativeBlsProvider: Implementación nativa (Rust, C++, etc.)
/// - MockBlsProvider: Para testing
///
/// Ejemplo de uso:
/// ```dart
/// // Usar implementación de Dart (default)
/// BlsProvider.setProvider(DartBlsProvider());
///
/// // O usar implementación nativa
/// BlsProvider.setProvider(MyNativeBlsProvider());
///
/// // Usar en cualquier lugar
/// final sig = BlsProvider.instance.sign(privateKey, message);
/// ```
library bls_provider;

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/bls/hd_keys.dart' as hd_keys;
import 'package:chia_crypto_utils/src/bls/op_swu_g2.dart';
import 'package:chia_crypto_utils/src/bls/pairing.dart';
import 'package:chia_crypto_utils/src/bls/schemes.dart';

/// Provider abstracto para operaciones BLS
abstract class BlsProvider {
  static BlsProvider? _instance;

  /// Obtiene la instancia actual del provider
  ///
  /// Si no se ha configurado, usa DartBlsProvider por defecto
  static BlsProvider get instance {
    _instance ??= DartBlsProvider();
    return _instance!;
  }

  /// Configura el provider a usar globalmente
  ///
  /// Ejemplo:
  /// ```dart
  /// BlsProvider.setProvider(NativeBlsProvider());
  /// ```
  static void setProvider(BlsProvider provider) {
    _instance = provider;
  }

  /// Resetea al provider por defecto (Dart)
  static void resetToDefault() {
    _instance = DartBlsProvider();
  }

  // ============================================================
  // OPERACIONES DE FIRMA
  // ============================================================

  /// Firma un mensaje con una clave privada
  ///
  /// [sk] - Clave privada
  /// [message] - Mensaje a firmar
  /// [dst] - Domain separation tag
  ///
  /// Retorna la firma como JacobianPoint (G2)
  JacobianPoint sign(PrivateKey sk, List<int> message, List<int> dst);

  /// Firma asíncrona (útil para implementaciones nativas)
  Future<JacobianPoint> signAsync(PrivateKey sk, List<int> message, List<int> dst) async {
    return sign(sk, message, dst);
  }

  // ============================================================
  // OPERACIONES DE VERIFICACIÓN
  // ============================================================

  /// Verifica una firma BLS
  ///
  /// [pk] - Clave pública (G1)
  /// [message] - Mensaje original
  /// [signature] - Firma a verificar (G2)
  /// [dst] - Domain separation tag
  ///
  /// Retorna true si la firma es válida
  bool verify(
    JacobianPoint pk,
    List<int> message,
    JacobianPoint signature,
    List<int> dst,
  );

  /// Verificación asíncrona
  Future<bool> verifyAsync(
    JacobianPoint pk,
    List<int> message,
    JacobianPoint signature,
    List<int> dst,
  ) async {
    return verify(pk, message, signature, dst);
  }

  // ============================================================
  // OPERACIONES DE AGREGACIÓN
  // ============================================================

  /// Agrega múltiples firmas en una sola
  ///
  /// [signatures] - Lista de firmas a agregar
  ///
  /// Retorna la firma agregada
  JacobianPoint aggregate(List<JacobianPoint> signatures);

  /// Verifica una firma agregada
  ///
  /// [pks] - Lista de claves públicas
  /// [messages] - Lista de mensajes (uno por clave pública)
  /// [signature] - Firma agregada a verificar
  /// [dst] - Domain separation tag
  ///
  /// Retorna true si la firma agregada es válida
  bool aggregateVerify(
    List<JacobianPoint> pks,
    List<List<int>> messages,
    JacobianPoint signature,
    List<int> dst,
  );

  /// Verificación rápida de agregación (PopScheme)
  ///
  /// Asume que todos los mensajes son iguales
  bool fastAggregateVerify(
    List<JacobianPoint> pks,
    List<int> message,
    JacobianPoint signature,
    List<int> dst,
  );

  // ============================================================
  // OPERACIONES DE CLAVES
  // ============================================================

  /// Genera una clave privada desde seed
  PrivateKey keyGen(List<int> seed);

  /// Deriva una clave hija (hardened)
  PrivateKey deriveChildSk(PrivateKey sk, int index);

  /// Deriva una clave hija (unhardened)
  PrivateKey deriveChildSkUnhardened(PrivateKey sk, int index);

  /// Deriva una clave pública hija (unhardened)
  JacobianPoint deriveChildPkUnhardened(JacobianPoint pk, int index);

  // ============================================================
  // POP (Proof of Possession) - Solo PopScheme
  // ============================================================

  /// Genera proof of possession
  JacobianPoint? popProve(PrivateKey sk) => null;

  /// Verifica proof of possession
  bool? popVerify(JacobianPoint pk, JacobianPoint proof) => null;

  // ============================================================
  // UTILIDADES
  // ============================================================

  /// Retorna el nombre del provider
  String get name;

  /// Retorna true si es una implementación nativa
  bool get isNative => false;

  /// Retorna información sobre el provider
  Map<String, dynamic> getInfo() {
    return {
      'name': name,
      'isNative': isNative,
      'type': runtimeType.toString(),
    };
  }
}

/// Implementación del provider usando el código Dart actual
class DartBlsProvider extends BlsProvider {
  @override
  String get name => 'Dart BLS (Pure Dart Implementation)';

  @override
  bool get isNative => false;

  @override
  JacobianPoint sign(PrivateKey sk, List<int> message, List<int> dst) {
    // Usa la implementación actual
    return coreSignMpl(sk, message, dst);
  }

  @override
  bool verify(
    JacobianPoint pk,
    List<int> message,
    JacobianPoint signature,
    List<int> dst,
  ) {
    return coreVerifyMpl(pk, message, signature, dst);
  }

  @override
  JacobianPoint aggregate(List<JacobianPoint> signatures) {
    return coreAggregateMpl(signatures);
  }

  @override
  bool aggregateVerify(
    List<JacobianPoint> pks,
    List<List<int>> messages,
    JacobianPoint signature,
    List<int> dst,
  ) {
    return coreAggregateVerify(pks, messages, signature, dst);
  }

  @override
  bool fastAggregateVerify(
    List<JacobianPoint> pks,
    List<int> message,
    JacobianPoint signature,
    List<int> dst,
  ) {
    if (pks.isEmpty) return false;
    var aggregate = pks[0];
    for (final pk in pks.sublist(1)) {
      aggregate += pk;
    }
    return coreVerifyMpl(aggregate, message, signature, dst);
  }

  @override
  PrivateKey keyGen(List<int> seed) {
    return hd_keys.keyGen(seed);
  }

  @override
  PrivateKey deriveChildSk(PrivateKey sk, int index) {
    return hd_keys.deriveChildSk(sk, index);
  }

  @override
  PrivateKey deriveChildSkUnhardened(PrivateKey sk, int index) {
    return hd_keys.deriveChildSkUnhardened(sk, index);
  }

  @override
  JacobianPoint deriveChildPkUnhardened(JacobianPoint pk, int index) {
    return hd_keys.deriveChildG1Unhardened(pk, index);
  }

  @override
  JacobianPoint? popProve(PrivateKey sk) {
    final pk = sk.getG1();
    return g2Map(pk.toBytes(), popSchemePopDst) * sk.value;
  }

  @override
  bool? popVerify(JacobianPoint pk, JacobianPoint proof) {
    try {
      if (!proof.isValid || !pk.isValid) return false;
      final q = g2Map(pk.toBytes(), popSchemePopDst);
      final one = Fq12.one(defaultEc.q);
      final pairingResult = atePairingMulti([pk, -JacobianPoint.generateG1()], [q, proof]);
      return pairingResult == one;
    } catch (_) {
      return false;
    }
  }
}

/// Clase base para implementaciones externas/nativas
///
/// Extiende de esta clase para crear tu propia implementación
///
/// Ejemplo:
/// ```dart
/// class MyNativeBlsProvider extends ExternalBlsProvider {
///   @override
///   String get name => 'My Native BLS';
///
///   @override
///   bool get isNative => true;
///
///   @override
///   JacobianPoint sign(PrivateKey sk, List<int> message, List<int> dst) {
///     // Llamar a tu implementación nativa
///     final sigBytes = myNativeLib.sign(sk.toBytes(), message, dst);
///     return JacobianPoint.fromBytesG2(sigBytes);
///   }
///
///   // ... implementar otros métodos
/// }
/// ```
abstract class ExternalBlsProvider extends BlsProvider {
  @override
  bool get isNative => true;

  /// Método helper para convertir PrivateKey a bytes
  List<int> privateKeyToBytes(PrivateKey sk) => sk.toBytes();

  /// Método helper para convertir JacobianPoint a bytes
  List<int> publicKeyToBytes(JacobianPoint pk) => pk.toBytes();

  /// Método helper para convertir bytes a JacobianPoint G1
  JacobianPoint bytesToPublicKey(List<int> bytes) => JacobianPoint.fromBytesG1(bytes);

  /// Método helper para convertir bytes a JacobianPoint G2 (firma)
  JacobianPoint bytesToSignature(List<int> bytes) => JacobianPoint.fromBytesG2(bytes);

  /// Si tu implementación nativa no soporta alguna operación,
  /// puedes hacer fallback a la implementación Dart
  final BlsProvider _dartFallback = DartBlsProvider();

  /// Usa fallback para key derivation si no está implementado nativamente
  @override
  PrivateKey keyGen(List<int> seed) => _dartFallback.keyGen(seed);

  @override
  PrivateKey deriveChildSk(PrivateKey sk, int index) => _dartFallback.deriveChildSk(sk, index);

  @override
  PrivateKey deriveChildSkUnhardened(PrivateKey sk, int index) =>
      _dartFallback.deriveChildSkUnhardened(sk, index);

  @override
  JacobianPoint deriveChildPkUnhardened(JacobianPoint pk, int index) =>
      _dartFallback.deriveChildPkUnhardened(pk, index);
}

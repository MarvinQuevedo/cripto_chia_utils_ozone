/// Ejemplo de cómo crear un provider BLS nativo
///
/// Este es un template que puedes adaptar para usar tu librería nativa
/// desde ozone_chia_wallet_core
///
/// IMPORTANTE: Este es solo un ejemplo. Debes adaptar las llamadas
/// a las funciones específicas de tu librería nativa.

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'dart:ffi' as ffi;
// Para usar FFI con allocación de memoria, agregar a pubspec.yaml:
// dependencies:
//   ffi: ^2.1.0
// Luego descomentar:
// import 'package:ffi/ffi.dart' as ffi_alloc;

/// Ejemplo de provider que conecta con una librería nativa
///
/// Uso desde ozone_chia_wallet_core:
/// ```dart
/// // En tu código de ozone_chia_wallet_core
/// import 'package:chia_crypto_utils/chia_crypto_utils.dart';
///
/// // Configurar el provider nativo al inicio de tu app
/// void initBls() {
///   BlsProvider.setProvider(OzoneNativeBlsProvider());
///   print('Using native BLS: ${BlsProvider.instance.name}');
/// }
///
/// // Ahora todas las operaciones BLS usan tu implementación nativa
/// final signature = AugSchemeMPL.sign(privateKey, message);
/// // ^^ Esto ahora usa tu código nativo, no Dart!
/// ```
class OzoneNativeBlsProvider extends ExternalBlsProvider {
  // Aquí puedes guardar referencias a tu librería nativa
  // Por ejemplo:
  // final MyNativeBlsLibrary _nativeLib;

  // Fallback a Dart disponible desde la clase base
  final BlsProvider _dartFallback = DartBlsProvider();

  OzoneNativeBlsProvider() {
    // Inicializar tu librería nativa aquí
    // _nativeLib = MyNativeBlsLibrary.initialize();
  }

  @override
  String get name => 'Ozone Native BLS Provider';

  @override
  bool get isNative => true;

  // ============================================================
  // IMPLEMENTA LAS OPERACIONES USANDO TU LIBRERÍA NATIVA
  // ============================================================

  @override
  JacobianPoint sign(PrivateKey sk, List<int> message, List<int> dst) {
    // Ejemplo de cómo conectar con tu librería nativa:

    // 1. Convertir inputs a formato nativo (descomentar cuando uses nativo)
    // final skBytes = privateKeyToBytes(sk);
    // final messageBytes = Uint8List.fromList(message);
    // final dstBytes = Uint8List.fromList(dst);

    // 2. Llamar a tu función nativa
    // Reemplaza esto con tu implementación real:
    // final signatureBytes = _nativeLib.sign(skBytes, messageBytes, dstBytes);

    // 3. Por ahora, usa fallback a Dart (para que compile)
    return _dartFallback.sign(sk, message, dst);

    // 4. Una vez tengas tu librería nativa, descomentar y usar:
    // return bytesToSignature(signatureBytes);
  }

  @override
  Future<JacobianPoint> signAsync(PrivateKey sk, List<int> message, List<int> dst) async {
    // Si tu librería nativa soporta async, implementar aquí
    // Por ejemplo con compute() para no bloquear UI:
    // return compute(_signInIsolate, SignParams(sk, message, dst));

    return sign(sk, message, dst);
  }

  @override
  bool verify(
    JacobianPoint pk,
    List<int> message,
    JacobianPoint signature,
    List<int> dst,
  ) {
    // Ejemplo:
    // final pkBytes = publicKeyToBytes(pk);
    // final sigBytes = publicKeyToBytes(signature);
    // final messageBytes = Uint8List.fromList(message);
    // final dstBytes = Uint8List.fromList(dst);
    //
    // return _nativeLib.verify(pkBytes, messageBytes, sigBytes, dstBytes);

    // Fallback a Dart por ahora:
    return _dartFallback.verify(pk, message, signature, dst);
  }

  @override
  JacobianPoint aggregate(List<JacobianPoint> signatures) {
    // Ejemplo:
    // final sigBytesList = signatures.map((s) => publicKeyToBytes(s)).toList();
    // final aggregatedBytes = _nativeLib.aggregate(sigBytesList);
    // return bytesToSignature(aggregatedBytes);

    return _dartFallback.aggregate(signatures);
  }

  @override
  bool aggregateVerify(
    List<JacobianPoint> pks,
    List<List<int>> messages,
    JacobianPoint signature,
    List<int> dst,
  ) {
    // Ejemplo:
    // final pkBytesList = pks.map((pk) => publicKeyToBytes(pk)).toList();
    // final sigBytes = publicKeyToBytes(signature);
    // final dstBytes = Uint8List.fromList(dst);
    //
    // return _nativeLib.aggregateVerify(
    //   pkBytesList,
    //   messages,
    //   sigBytes,
    //   dstBytes,
    // );

    return _dartFallback.aggregateVerify(pks, messages, signature, dst);
  }

  @override
  bool fastAggregateVerify(
    List<JacobianPoint> pks,
    List<int> message,
    JacobianPoint signature,
    List<int> dst,
  ) {
    // Similar a aggregateVerify pero con un solo mensaje
    return _dartFallback.fastAggregateVerify(pks, message, signature, dst);
  }

  // POP operations (opcional)
  @override
  JacobianPoint? popProve(PrivateKey sk) {
    // Si tu librería nativa soporta POP:
    // final skBytes = privateKeyToBytes(sk);
    // final proofBytes = _nativeLib.popProve(skBytes);
    // return bytesToSignature(proofBytes);

    return _dartFallback.popProve(sk);
  }

  @override
  bool? popVerify(JacobianPoint pk, JacobianPoint proof) {
    // final pkBytes = publicKeyToBytes(pk);
    // final proofBytes = publicKeyToBytes(proof);
    // return _nativeLib.popVerify(pkBytes, proofBytes);

    return _dartFallback.popVerify(pk, proof);
  }

  @override
  Map<String, dynamic> getInfo() {
    return {
      ...super.getInfo(),
      'backend': 'Ozone Wallet Core Native Library',
      'performance': '10-100x faster than Dart',
    };
  }
}

// ============================================================
// EJEMPLO CON FFI (si usas Rust/C/C++)
// ============================================================

/// Ejemplo usando dart:ffi para conectar con librería nativa
///
/// Si tu librería nativa está en Rust/C/C++, puedes usar FFI:
///
/// NOTA: Este ejemplo está comentado porque requiere la dependencia 'ffi'.
/// Para usarlo, agregar a pubspec.yaml:
///   dependencies:
///     ffi: ^2.1.0
/// Y descomentar el código correspondiente.
class FfiBlsProvider extends ExternalBlsProvider {
  late final ffi.DynamicLibrary _dylib;
  // ignore: unused_field
  late final BlsSignNative _signNative;
  // ignore: unused_field
  late final BlsVerifyNative _verifyNative;

  // Fallback a Dart
  final BlsProvider _dartFallback = DartBlsProvider();

  FfiBlsProvider() {
    // Cargar la librería nativa
    // En producción, detectar plataforma automáticamente
    _dylib = _loadLibrary();

    // Cargar las funciones
    _signNative = _dylib.lookupFunction<BlsSignC, BlsSignNative>('bls_sign');

    _verifyNative = _dylib.lookupFunction<BlsVerifyC, BlsVerifyNative>('bls_verify');
  }

  ffi.DynamicLibrary _loadLibrary() {
    // Detectar plataforma y cargar librería apropiada
    // if (Platform.isAndroid) return ffi.DynamicLibrary.open('libbls.so');
    // if (Platform.isIOS) return ffi.DynamicLibrary.process();
    // if (Platform.isMacOS) return ffi.DynamicLibrary.open('libbls.dylib');
    // if (Platform.isWindows) return ffi.DynamicLibrary.open('bls.dll');

    throw UnimplementedError('Platform not supported yet');
  }

  @override
  String get name => 'FFI Native BLS Provider';

  @override
  JacobianPoint sign(PrivateKey sk, List<int> message, List<int> dst) {
    // Nota: Requiere package:ffi para usar calloc
    // Descomentar cuando agregues la dependencia ffi
    /*
    final skBytes = ffi_alloc.calloc.allocate<ffi.Uint8>(32);
    final msgBytes = ffi_alloc.calloc.allocate<ffi.Uint8>(message.length);
    final dstBytes = ffi_alloc.calloc.allocate<ffi.Uint8>(dst.length);
    final sigBytes = ffi_alloc.calloc.allocate<ffi.Uint8>(96);
    
    try {
      // Copiar datos a memoria nativa
      final skList = privateKeyToBytes(sk);
      for (var i = 0; i < 32; i++) {
        skBytes[i] = skList[i];
      }
      for (var i = 0; i < message.length; i++) {
        msgBytes[i] = message[i];
      }
      for (var i = 0; i < dst.length; i++) {
        dstBytes[i] = dst[i];
      }
      
      // Llamar función nativa
      _signNative(
        sigBytes,
        skBytes,
        msgBytes,
        message.length,
        dstBytes,
        dst.length,
      );
      
      // Convertir resultado
      final signature = List<int>.generate(96, (i) => sigBytes[i]);
      return bytesToSignature(signature);
    } finally {
      // Liberar memoria
      ffi_alloc.calloc.free(skBytes);
      ffi_alloc.calloc.free(msgBytes);
      ffi_alloc.calloc.free(dstBytes);
      ffi_alloc.calloc.free(sigBytes);
    }
    */

    // Fallback mientras no implementes FFI
    return _dartFallback.sign(sk, message, dst);
  }

  @override
  bool verify(
    JacobianPoint pk,
    List<int> message,
    JacobianPoint signature,
    List<int> dst,
  ) {
    // Nota: Requiere package:ffi para usar calloc
    // Descomentar cuando agregues la dependencia ffi
    /*
    final pkBytes = ffi_alloc.calloc.allocate<ffi.Uint8>(48);
    final msgBytes = ffi_alloc.calloc.allocate<ffi.Uint8>(message.length);
    final sigBytes = ffi_alloc.calloc.allocate<ffi.Uint8>(96);
    final dstBytes = ffi_alloc.calloc.allocate<ffi.Uint8>(dst.length);
    
    try {
      // Copiar datos
      final pkList = publicKeyToBytes(pk);
      final sigList = publicKeyToBytes(signature);
      for (var i = 0; i < 48; i++) pkBytes[i] = pkList[i];
      for (var i = 0; i < message.length; i++) msgBytes[i] = message[i];
      for (var i = 0; i < 96; i++) sigBytes[i] = sigList[i];
      for (var i = 0; i < dst.length; i++) dstBytes[i] = dst[i];
      
      // Llamar función nativa
      final result = _verifyNative(
        pkBytes,
        msgBytes,
        message.length,
        sigBytes,
        dstBytes,
        dst.length,
      );
      
      return result == 1;
    } finally {
      ffi_alloc.calloc.free(pkBytes);
      ffi_alloc.calloc.free(msgBytes);
      ffi_alloc.calloc.free(sigBytes);
      ffi_alloc.calloc.free(dstBytes);
    }
    */

    // Fallback mientras no implementes FFI
    return _dartFallback.verify(pk, message, signature, dst);
  }

  @override
  JacobianPoint aggregate(List<JacobianPoint> signatures) {
    // Implementar usando tu función nativa de agregación
    return _dartFallback.aggregate(signatures);
  }

  @override
  bool aggregateVerify(
    List<JacobianPoint> pks,
    List<List<int>> messages,
    JacobianPoint signature,
    List<int> dst,
  ) {
    // Implementar usando tu función nativa
    return _dartFallback.aggregateVerify(pks, messages, signature, dst);
  }

  @override
  bool fastAggregateVerify(
    List<JacobianPoint> pks,
    List<int> message,
    JacobianPoint signature,
    List<int> dst,
  ) {
    return _dartFallback.fastAggregateVerify(pks, message, signature, dst);
  }
}

// Definiciones FFI (C signatures)
typedef BlsSignC = ffi.Void Function(
  ffi.Pointer<ffi.Uint8> signature,
  ffi.Pointer<ffi.Uint8> privateKey,
  ffi.Pointer<ffi.Uint8> message,
  ffi.Int32 messageLen,
  ffi.Pointer<ffi.Uint8> dst,
  ffi.Int32 dstLen,
);

typedef BlsSignNative = void Function(
  ffi.Pointer<ffi.Uint8> signature,
  ffi.Pointer<ffi.Uint8> privateKey,
  ffi.Pointer<ffi.Uint8> message,
  int messageLen,
  ffi.Pointer<ffi.Uint8> dst,
  int dstLen,
);

typedef BlsVerifyC = ffi.Int32 Function(
  ffi.Pointer<ffi.Uint8> publicKey,
  ffi.Pointer<ffi.Uint8> message,
  ffi.Int32 messageLen,
  ffi.Pointer<ffi.Uint8> signature,
  ffi.Pointer<ffi.Uint8> dst,
  ffi.Int32 dstLen,
);

typedef BlsVerifyNative = int Function(
  ffi.Pointer<ffi.Uint8> publicKey,
  ffi.Pointer<ffi.Uint8> message,
  int messageLen,
  ffi.Pointer<ffi.Uint8> signature,
  ffi.Pointer<ffi.Uint8> dst,
  int dstLen,
);

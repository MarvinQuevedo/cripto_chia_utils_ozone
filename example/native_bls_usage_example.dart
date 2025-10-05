/// Ejemplo completo de cómo usar un provider BLS nativo
/// con chia_crypto_utils desde ozone_chia_wallet_core
///
/// Este ejemplo muestra el flujo completo:
/// 1. Configurar el provider nativo
/// 2. Usar operaciones BLS normalmente
/// 3. Benchmarking para ver la mejora

import 'package:chia_crypto_utils/chia_crypto_utils.dart';

// ============================================================
// PASO 1: Crear tu provider nativo
// (Este sería el código en ozone_chia_wallet_core)
// ============================================================

/// Provider que conecta con tu librería nativa
///
/// Reemplaza las implementaciones con llamadas reales a tu librería
class OzoneNativeBlsProvider extends ExternalBlsProvider {
  // Fallback a Dart
  final BlsProvider _dartFallback = DartBlsProvider();

  @override
  String get name => 'Ozone Native BLS';

  @override
  bool get isNative => true;

  @override
  JacobianPoint sign(PrivateKey sk, List<int> message, List<int> dst) {
    // AQUÍ: Llamar a tu librería nativa
    // Por ejemplo:
    // final sigBytes = yourNativeLib.sign(sk.toBytes(), message, dst);
    // return JacobianPoint.fromBytesG2(sigBytes);

    // Por ahora, usa Dart (para que compile el ejemplo)
    return _dartFallback.sign(sk, message, dst);
  }

  @override
  bool verify(
    JacobianPoint pk,
    List<int> message,
    JacobianPoint signature,
    List<int> dst,
  ) {
    // AQUÍ: Llamar a tu librería nativa
    // Por ejemplo:
    // return yourNativeLib.verify(
    //   pk.toBytes(),
    //   message,
    //   signature.toBytes(),
    //   dst,
    // );

    return _dartFallback.verify(pk, message, signature, dst);
  }

  @override
  JacobianPoint aggregate(List<JacobianPoint> signatures) {
    // AQUÍ: Llamar a tu librería nativa
    return _dartFallback.aggregate(signatures);
  }

  @override
  bool aggregateVerify(
    List<JacobianPoint> pks,
    List<List<int>> messages,
    JacobianPoint signature,
    List<int> dst,
  ) {
    // AQUÍ: Llamar a tu librería nativa
    return _dartFallback.aggregateVerify(pks, messages, signature, dst);
  }

  @override
  bool fastAggregateVerify(
    List<JacobianPoint> pks,
    List<int> message,
    JacobianPoint signature,
    List<int> dst,
  ) {
    // AQUÍ: Llamar a tu librería nativa
    return _dartFallback.fastAggregateVerify(pks, message, signature, dst);
  }
}

// ============================================================
// PASO 2: Usar el provider en tu aplicación
// ============================================================

void main() {
  print('=== Ejemplo de BLS Provider Nativo ===\n');

  // Configurar el provider nativo
  initializeNativeBlsProvider();

  // Ahora todo el código BLS usa tu implementación nativa automáticamente
  print('\n--- Ejemplo básico de firma ---');
  basicSignatureExample();

  print('\n--- Ejemplo de verificación ---');
  verificationExample();

  print('\n--- Ejemplo de agregación ---');
  aggregationExample();

  print('\n--- Benchmark: Dart vs Nativo ---');
  benchmarkComparison();

  print('\n--- Cambiar provider dinámicamente ---');
  dynamicProviderExample();
}

/// Inicializar el provider nativo
void initializeNativeBlsProvider() {
  // Opción 1: Usar siempre el provider nativo
  BlsProvider.setProvider(OzoneNativeBlsProvider());

  print('Provider BLS configurado:');
  print('  Nombre: ${BlsProvider.instance.name}');
  print('  Es nativo: ${BlsProvider.instance.isNative}');
  print('  Info: ${BlsProvider.instance.getInfo()}');
}

/// Ejemplo básico: Firmar un mensaje
void basicSignatureExample() {
  // 1. Crear una clave privada
  final seed = List.generate(32, (i) => i);
  final privateKey = PrivateKey.fromSeed(seed);

  print('Clave privada: ${privateKey.toHex().substring(0, 20)}...');

  // 2. Obtener la clave pública
  final publicKey = privateKey.getG1();
  print('Clave pública: ${publicKey.toHex().substring(0, 20)}...');

  // 3. Firmar un mensaje
  final message = 'Hello from Ozone!'.codeUnits;

  // IMPORTANTE: Esta llamada ahora usa tu implementación nativa!
  final signature = AugSchemeMPL.sign(privateKey, message);

  print('Firma generada: ${signature.toHex().substring(0, 20)}...');
  print('Longitud de firma: ${signature.toBytes().length} bytes');
}

/// Ejemplo de verificación
void verificationExample() {
  final privateKey = PrivateKey.fromSeed([1, 2, 3, 4, 5]);
  final publicKey = privateKey.getG1();
  final message = 'Test message'.codeUnits;

  // Firmar (usa tu implementación nativa)
  final signature = AugSchemeMPL.sign(privateKey, message);

  // Verificar (también usa tu implementación nativa)
  final isValid = AugSchemeMPL.verify(publicKey, message, signature);

  print('Firma válida: $isValid');

  // Verificar con mensaje incorrecto
  final wrongMessage = 'Different message'.codeUnits;
  final isInvalid = AugSchemeMPL.verify(publicKey, wrongMessage, signature);

  print('Firma con mensaje incorrecto: $isInvalid (debería ser false)');
}

/// Ejemplo de agregación de firmas
void aggregationExample() {
  print('Creando múltiples firmas...');

  // Crear 5 claves privadas diferentes
  final privateKeys = List.generate(
    5,
    (i) => PrivateKey.fromSeed(List.generate(32, (j) => i * 10 + j)),
  );

  // Mensajes diferentes para cada clave
  final messages = [
    'Message 1'.codeUnits,
    'Message 2'.codeUnits,
    'Message 3'.codeUnits,
    'Message 4'.codeUnits,
    'Message 5'.codeUnits,
  ];

  // Firmar cada mensaje (usa tu implementación nativa)
  final signatures = <JacobianPoint>[];
  for (var i = 0; i < 5; i++) {
    signatures.add(AugSchemeMPL.sign(privateKeys[i], messages[i]));
  }
  print('  ✓ ${signatures.length} firmas creadas');

  // Agregar todas las firmas en una sola (usa tu implementación nativa)
  final aggregatedSignature = AugSchemeMPL.aggregate(signatures);
  print('  ✓ Firmas agregadas');

  // Verificar la firma agregada (usa tu implementación nativa)
  final publicKeys = privateKeys.map((sk) => sk.getG1()).toList();
  final isValid = AugSchemeMPL.aggregateVerify(
    publicKeys,
    messages,
    aggregatedSignature,
  );

  print('Firma agregada válida: $isValid');
  print('Tamaño firma agregada: ${aggregatedSignature.toBytes().length} bytes');
  print('  (igual a firma individual - ¡espacio ahorrado!)');
}

/// Benchmark para comparar Dart vs Nativo
void benchmarkComparison() {
  final testKey = PrivateKey.fromSeed([1, 2, 3, 4, 5]);
  final message = 'Benchmark test'.codeUnits;

  const iterations = 10;

  // Test con provider nativo
  print('Ejecutando $iterations firmas con provider nativo...');
  final sw1 = Stopwatch()..start();
  for (var i = 0; i < iterations; i++) {
    AugSchemeMPL.sign(testKey, message);
  }
  sw1.stop();
  final nativeTime = sw1.elapsedMilliseconds;
  print('  Tiempo total: ${nativeTime}ms');
  print('  Por firma: ${nativeTime / iterations}ms');

  // Test con provider Dart
  print('\nEjecutando $iterations firmas con provider Dart...');
  BlsProvider.resetToDefault();
  final sw2 = Stopwatch()..start();
  for (var i = 0; i < iterations; i++) {
    AugSchemeMPL.sign(testKey, message);
  }
  sw2.stop();
  final dartTime = sw2.elapsedMilliseconds;
  print('  Tiempo total: ${dartTime}ms');
  print('  Por firma: ${dartTime / iterations}ms');

  // Comparación
  print('\nComparación:');
  if (dartTime > 0 && nativeTime > 0) {
    final speedup = dartTime / nativeTime;
    print('  Speedup: ${speedup.toStringAsFixed(1)}x más rápido');
    print('  Tiempo ahorrado: ${dartTime - nativeTime}ms en $iterations operaciones');
  }

  // Restaurar provider nativo
  BlsProvider.setProvider(OzoneNativeBlsProvider());
}

/// Ejemplo de cambiar provider dinámicamente
void dynamicProviderExample() {
  final testKey = PrivateKey.fromSeed([1, 2, 3]);
  final message = 'test'.codeUnits;

  // Usar nativo
  BlsProvider.setProvider(OzoneNativeBlsProvider());
  print('Provider actual: ${BlsProvider.instance.name}');
  final sig1 = AugSchemeMPL.sign(testKey, message);
  print('Firma con nativo: ${sig1.toHex().substring(0, 20)}...');

  // Cambiar a Dart
  BlsProvider.resetToDefault();
  print('\nProvider actual: ${BlsProvider.instance.name}');
  final sig2 = AugSchemeMPL.sign(testKey, message);
  print('Firma con Dart: ${sig2.toHex().substring(0, 20)}...');

  // Las firmas deben ser idénticas!
  if (sig1.toHex() == sig2.toHex()) {
    print('\n✓ Las firmas son idénticas (correcto!)');
  } else {
    print('\n✗ ERROR: Las firmas difieren!');
  }

  // Volver a nativo
  BlsProvider.setProvider(OzoneNativeBlsProvider());
}

// ============================================================
// EJEMPLO DE USO EN CÓDIGO REAL DE WALLET
// ============================================================

/// Ejemplo de cómo usar en tu código de wallet
class WalletExample {
  void signTransaction() {
    // El código no cambia! Solo configuras el provider al inicio de la app

    final privateKey = getPrivateKeyFromWallet();
    final transaction = createTransaction();

    // Esta firma ahora usa tu implementación nativa automáticamente
    final signature = AugSchemeMPL.sign(
      privateKey,
      transaction.messageToSign,
    );

    transaction.addSignature(signature);
  }

  bool verifyReceivedTransaction(Transaction transaction) {
    // La verificación también usa tu implementación nativa
    if (transaction.signature == null) return false;

    return AugSchemeMPL.verify(
      transaction.publicKey,
      transaction.message,
      transaction.signature!,
    );
  }

  void createMultiSigTransaction(List<PrivateKey> keys, List<int> message) {
    // Firmar con cada clave
    final signatures = keys.map((key) => AugSchemeMPL.sign(key, message)).toList();

    // Agregar (usa implementación nativa)
    final aggregated = AugSchemeMPL.aggregate(signatures);

    // La firma agregada es del mismo tamaño que una firma individual!
    print('Agregado ${keys.length} firmas en ${aggregated.toBytes().length} bytes');
  }

  // Helpers de ejemplo
  PrivateKey getPrivateKeyFromWallet() => PrivateKey.fromSeed([1, 2, 3]);
  Transaction createTransaction() => Transaction(
        messageToSign: 'tx data'.codeUnits,
        publicKey: JacobianPoint.generateG1(),
      );
}

class Transaction {
  Transaction({
    required this.messageToSign,
    required this.publicKey,
  });

  final List<int> messageToSign;
  final JacobianPoint publicKey;
  JacobianPoint? signature;

  void addSignature(JacobianPoint sig) => signature = sig;
  List<int> get message => messageToSign;
}

# Guía de Integración de BLS Nativo

## 📋 Resumen

Esta guía explica cómo usar tu propia implementación nativa de BLS (desde `ozone_chia_wallet_core` u otra librería) en lugar de la implementación Dart pura de `chia_crypto_utils`.

## 🎯 Ventajas

- **10-100x más rápido** en operaciones criptográficas
- **Sin cambios en el código existente** - solo configurar el provider
- **Fallback automático** - si algo falla, usa Dart
- **Flexible** - puedes mezclar operaciones nativas y Dart

## 🏗️ Arquitectura

```
┌─────────────────────────────────────┐
│   Tu Aplicación                     │
│   (ozone_chia_wallet_core)          │
└───────────┬─────────────────────────┘
            │
            │ AugSchemeMPL.sign()
            │ AugSchemeMPL.verify()
            ↓
┌─────────────────────────────────────┐
│   chia_crypto_utils                 │
│   ┌──────────────────────┐          │
│   │  BlsProvider.instance│          │
│   └─────────┬────────────┘          │
│             ↓                        │
│   ┌─────────────────────────────┐   │
│   │ DartBlsProvider (Default)   │←──┼── Dart puro (lento)
│   └─────────────────────────────┘   │
│             O                        │
│   ┌─────────────────────────────┐   │
│   │ TU PROVIDER NATIVO          │←──┼── Nativo (rápido!)
│   └─────────────────────────────┘   │
└─────────────────────────────────────┘
```

## 🚀 Uso Básico

### 1. En `ozone_chia_wallet_core`, crea tu provider:

```dart
// En: ozone_chia_wallet_core/lib/bls/ozone_native_bls_provider.dart

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:your_native_lib/your_native_lib.dart'; // Tu librería nativa

class OzoneNativeBlsProvider extends ExternalBlsProvider {
  final YourNativeBlsLibrary _nativeLib;
  
  OzoneNativeBlsProvider() : _nativeLib = YourNativeBlsLibrary.initialize();

  @override
  String get name => 'Ozone Native BLS';

  @override
  bool get isNative => true;

  @override
  JacobianPoint sign(PrivateKey sk, List<int> message, List<int> dst) {
    // Usar tu librería nativa
    final signatureBytes = _nativeLib.sign(
      sk.toBytes(),
      message,
      dst,
    );
    
    // Convertir resultado a formato chia_crypto_utils
    return JacobianPoint.fromBytesG2(signatureBytes);
  }

  @override
  bool verify(
    JacobianPoint pk,
    List<int> message,
    JacobianPoint signature,
    List<int> dst,
  ) {
    return _nativeLib.verify(
      pk.toBytes(),
      message,
      signature.toBytes(),
      dst,
    );
  }

  @override
  JacobianPoint aggregate(List<JacobianPoint> signatures) {
    final sigBytes = signatures.map((s) => s.toBytes()).toList();
    final aggregated = _nativeLib.aggregate(sigBytes);
    return JacobianPoint.fromBytesG2(aggregated);
  }

  @override
  bool aggregateVerify(
    List<JacobianPoint> pks,
    List<List<int>> messages,
    JacobianPoint signature,
    List<int> dst,
  ) {
    return _nativeLib.aggregateVerify(
      pks.map((pk) => pk.toBytes()).toList(),
      messages,
      signature.toBytes(),
      dst,
    );
  }

  @override
  bool fastAggregateVerify(
    List<JacobianPoint> pks,
    List<int> message,
    JacobianPoint signature,
    List<int> dst,
  ) {
    return _nativeLib.fastAggregateVerify(
      pks.map((pk) => pk.toBytes()).toList(),
      message,
      signature.toBytes(),
      dst,
    );
  }

  // Las funciones de key derivation pueden usar fallback a Dart
  // ya que no son tan críticas de rendimiento:
  // keyGen(), deriveChildSk(), etc. heredan de ExternalBlsProvider
}
```

### 2. Configura el provider al inicio de tu app:

```dart
// En tu main.dart o archivo de inicialización

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:ozone_chia_wallet_core/bls/ozone_native_bls_provider.dart';

void main() {
  // Configurar el provider nativo
  BlsProvider.setProvider(OzoneNativeBlsProvider());
  
  print('BLS Provider: ${BlsProvider.instance.name}');
  print('Is Native: ${BlsProvider.instance.isNative}');
  
  runApp(MyApp());
}
```

### 3. ¡Usa el código normal! Ahora es nativo automáticamente:

```dart
// TODO el código BLS existente ahora usa tu implementación nativa

// Firmar
final privateKey = PrivateKey.fromSeed(seed);
final signature = AugSchemeMPL.sign(privateKey, message);
// ^^ Esto ahora llama a tu código nativo, no a Dart!

// Verificar
final publicKey = privateKey.getG1();
final valid = AugSchemeMPL.verify(publicKey, message, signature);
// ^^ También usa tu código nativo

// Agregar
final signatures = [sig1, sig2, sig3];
final aggregated = AugSchemeMPL.aggregate(signatures);
// ^^ Nativo también!

// Verificar agregada
final valid = AugSchemeMPL.aggregateVerify(pks, messages, aggregated);
```

## 📊 Benchmark de Mejora

### Antes (Dart puro):
```dart
final sw = Stopwatch()..start();
final signature = AugSchemeMPL.sign(privateKey, message);
sw.stop();
print('Time: ${sw.elapsedMilliseconds}ms'); // ~150ms
```

### Después (con provider nativo):
```dart
BlsProvider.setProvider(OzoneNativeBlsProvider());

final sw = Stopwatch()..start();
final signature = AugSchemeMPL.sign(privateKey, message);
sw.stop();
print('Time: ${sw.elapsedMilliseconds}ms'); // ~1-2ms ⚡ ¡100x más rápido!
```

## 🔄 Cambiar entre Dart y Nativo Dinámicamente

Puedes cambiar el provider en runtime:

```dart
// Usar nativo para producción
if (kReleaseMode) {
  BlsProvider.setProvider(OzoneNativeBlsProvider());
} else {
  // Usar Dart para debug (más fácil de debuggear)
  BlsProvider.resetToDefault();
}

// O cambiar basado en performance
if (await isNativeAvailable()) {
  BlsProvider.setProvider(OzoneNativeBlsProvider());
  print('Using native BLS: ~100x faster!');
} else {
  print('Native BLS not available, using Dart');
}
```

## 🛡️ Fallback Automático

Si tu implementación nativa no soporta alguna operación, el provider puede usar fallback a Dart:

```dart
class OzoneNativeBlsProvider extends ExternalBlsProvider {
  // ...
  
  @override
  PrivateKey keyGen(List<int> seed) {
    // Key generation no es crítico de rendimiento
    // Usa el fallback a Dart automáticamente
    return super.keyGen(seed); // Usa _dartFallback
  }
  
  @override
  JacobianPoint sign(PrivateKey sk, List<int> message, List<int> dst) {
    try {
      // Intentar usar nativo
      return _nativeLib.sign(sk.toBytes(), message, dst);
    } catch (e) {
      // Si falla, usar Dart
      print('Native sign failed, using Dart fallback: $e');
      return _dartFallback.sign(sk, message, dst);
    }
  }
}
```

## 🔌 Integración con tu Librería Nativa Actual

### Opción 1: Si ya tienes una librería nativa en `ozone_chia_wallet_core`

```dart
// Suponiendo que tienes algo como:
// ozone_chia_wallet_core/lib/native/bls_native.dart

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:ozone_chia_wallet_core/native/bls_native.dart' as native;

class OzoneNativeBlsProvider extends ExternalBlsProvider {
  @override
  String get name => 'Ozone Core Native BLS';

  @override
  JacobianPoint sign(PrivateKey sk, List<int> message, List<int> dst) {
    // Adaptar tu API existente
    final sig = native.blsSign(
      secretKey: sk.toBytes(),
      message: message,
      domainSeparationTag: dst,
    );
    return JacobianPoint.fromBytesG2(sig);
  }

  @override
  bool verify(
    JacobianPoint pk,
    List<int> message,
    JacobianPoint signature,
    List<int> dst,
  ) {
    return native.blsVerify(
      publicKey: pk.toBytes(),
      message: message,
      signature: signature.toBytes(),
      domainSeparationTag: dst,
    );
  }

  // Implementar las demás operaciones...
}
```

### Opción 2: Si usas Rust con flutter_rust_bridge

```dart
// Asumiendo que tienes Rust con flutter_rust_bridge
import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:ozone_chia_wallet_core/bridge_generated.dart';

class RustBlsProvider extends ExternalBlsProvider {
  late final BlsApi _api;

  RustBlsProvider() {
    _api = BlsApi.instance; // Tu bridge de Rust
  }

  @override
  String get name => 'Rust BLS Provider';

  @override
  Future<JacobianPoint> signAsync(PrivateKey sk, List<int> message, List<int> dst) async {
    final sig = await _api.blsSign(
      secretKey: Uint8List.fromList(sk.toBytes()),
      message: Uint8List.fromList(message),
      dst: Uint8List.fromList(dst),
    );
    return JacobianPoint.fromBytesG2(sig);
  }

  @override
  JacobianPoint sign(PrivateKey sk, List<int> message, List<int> dst) {
    // Versión sincrónica si es necesaria
    return _dartFallback.sign(sk, message, dst);
  }

  @override
  Future<bool> verifyAsync(
    JacobianPoint pk,
    List<int> message,
    JacobianPoint signature,
    List<int> dst,
  ) async {
    return await _api.blsVerify(
      publicKey: Uint8List.fromList(pk.toBytes()),
      message: Uint8List.fromList(message),
      signature: Uint8List.fromList(signature.toBytes()),
      dst: Uint8List.fromList(dst),
    );
  }

  @override
  bool verify(
    JacobianPoint pk,
    List<int> message,
    JacobianPoint signature,
    List<int> dst,
  ) {
    return _dartFallback.verify(pk, message, signature, dst);
  }
}
```

### Opción 3: Si usas FFI directo

Ver el archivo `native_bls_provider_example.dart` para un ejemplo completo con FFI.

## 📝 Checklist de Integración

- [ ] 1. Crear tu clase que extiende `ExternalBlsProvider`
- [ ] 2. Implementar `sign()` y `verify()` (mínimo requerido)
- [ ] 3. Implementar `aggregate()` y `aggregateVerify()` para mejor rendimiento
- [ ] 4. (Opcional) Implementar `signAsync()` y `verifyAsync()` para UI responsiva
- [ ] 5. Configurar el provider con `BlsProvider.setProvider()` al inicio de tu app
- [ ] 6. Probar que funciona con tu código existente
- [ ] 7. Benchmarking para confirmar mejora de rendimiento
- [ ] 8. (Opcional) Implementar fallback para casos de error

## 🧪 Testing

```dart
import 'package:test/test.dart';
import 'package:chia_crypto_utils/chia_crypto_utils.dart';

void main() {
  group('Native BLS Provider Tests', () {
    late PrivateKey testKey;
    late List<int> testMessage;

    setUp(() {
      // Configurar provider nativo
      BlsProvider.setProvider(OzoneNativeBlsProvider());
      
      testKey = PrivateKey.fromSeed([1, 2, 3, 4, 5]);
      testMessage = 'Hello BLS'.toBytes();
    });

    test('Sign produces valid signature', () {
      final signature = AugSchemeMPL.sign(testKey, testMessage);
      expect(signature.isValid, isTrue);
      expect(signature.toBytes().length, equals(96));
    });

    test('Verify works correctly', () {
      final publicKey = testKey.getG1();
      final signature = AugSchemeMPL.sign(testKey, testMessage);
      
      final valid = AugSchemeMPL.verify(publicKey, testMessage, signature);
      expect(valid, isTrue);
      
      // Verificar que falla con mensaje diferente
      final invalid = AugSchemeMPL.verify(publicKey, [0, 0, 0], signature);
      expect(invalid, isFalse);
    });

    test('Native is faster than Dart', () {
      // Test con nativo
      final sw1 = Stopwatch()..start();
      for (var i = 0; i < 10; i++) {
        AugSchemeMPL.sign(testKey, testMessage);
      }
      sw1.stop();
      final nativeTime = sw1.elapsedMilliseconds;

      // Test con Dart
      BlsProvider.resetToDefault();
      final sw2 = Stopwatch()..start();
      for (var i = 0; i < 10; i++) {
        AugSchemeMPL.sign(testKey, testMessage);
      }
      sw2.stop();
      final dartTime = sw2.elapsedMilliseconds;

      print('Native: ${nativeTime}ms');
      print('Dart: ${dartTime}ms');
      print('Speedup: ${dartTime / nativeTime}x');

      // Nativo debe ser al menos 5x más rápido
      expect(nativeTime < dartTime / 5, isTrue);
    });

    test('Aggregate signatures', () {
      final keys = List.generate(5, (i) => PrivateKey.fromSeed([i]));
      final messages = List.generate(5, (i) => [i]);
      final signatures = [
        for (var i = 0; i < 5; i++)
          AugSchemeMPL.sign(keys[i], messages[i])
      ];

      final aggregated = AugSchemeMPL.aggregate(signatures);
      expect(aggregated.isValid, isTrue);

      final publicKeys = keys.map((k) => k.getG1()).toList();
      final valid = AugSchemeMPL.aggregateVerify(
        publicKeys,
        messages,
        aggregated,
      );
      expect(valid, isTrue);
    });
  });
}
```

## 🔍 Debugging

```dart
// Ver qué provider está en uso
void debugBlsProvider() {
  final provider = BlsProvider.instance;
  print('BLS Provider Info:');
  print(provider.getInfo());
  // Output:
  // {
  //   name: "Ozone Native BLS",
  //   isNative: true,
  //   type: "OzoneNativeBlsProvider",
  //   backend: "...",
  // }
}

// Comparar resultados entre Dart y Nativo
void compareProviders() {
  final testKey = PrivateKey.fromSeed([1, 2, 3]);
  final message = 'test'.toBytes();

  // Firmar con nativo
  BlsProvider.setProvider(OzoneNativeBlsProvider());
  final nativeSig = AugSchemeMPL.sign(testKey, message);

  // Firmar con Dart
  BlsProvider.resetToDefault();
  final dartSig = AugSchemeMPL.sign(testKey, message);

  // Deben ser idénticas
  assert(nativeSig.toHex() == dartSig.toHex(), 'Signatures differ!');
  print('✓ Native and Dart produce same signatures');
}
```

## 📚 Referencia Completa de la API

### Métodos que DEBES implementar (mínimo):
- `sign()` - Firma BLS
- `verify()` - Verificación BLS
- `aggregate()` - Agregar firmas
- `aggregateVerify()` - Verificar firma agregada

### Métodos opcionales (pero recomendados):
- `signAsync()` - Firma asíncrona (mejor para UI)
- `verifyAsync()` - Verificación asíncrona
- `fastAggregateVerify()` - Verificación rápida cuando todos los mensajes son iguales
- `popProve()` - Proof of Possession (solo PopScheme)
- `popVerify()` - Verificar POP (solo PopScheme)

### Métodos que pueden usar fallback a Dart:
- `keyGen()` - Generación de claves desde seed
- `deriveChildSk()` - Derivación de claves hijas (hardened)
- `deriveChildSkUnhardened()` - Derivación unhardened
- `deriveChildPkUnhardened()` - Derivación de claves públicas

## ⚠️ Notas Importantes

1. **Thread Safety**: Asegúrate de que tu implementación nativa es thread-safe si usas isolates
2. **Memoria**: Libera memoria nativa apropiadamente (especialmente con FFI)
3. **Errores**: Maneja errores nativos gracefully, usa fallback a Dart si es necesario
4. **Compatibilidad**: Las firmas nativas DEBEN ser idénticas a las de Dart
5. **Testing**: Prueba extensivamente antes de usar en producción

## 🎓 Recursos Adicionales

- Ver `native_bls_provider_example.dart` para ejemplos completos
- Ver `bls_provider.dart` para la interfaz completa
- Documentación de BLS12-381: https://electriccoin.co/blog/new-snark-curve/
- Chia BLS signatures: https://github.com/Chia-Network/bls-signatures

## 🚀 Próximos Pasos

1. Implementa tu provider basado en el ejemplo
2. Configúralo en tu app
3. Ejecuta benchmarks para confirmar mejora
4. ¡Disfruta de operaciones BLS 10-100x más rápidas!

---

**¿Necesitas ayuda?** Crea un issue en el repositorio con detalles de tu implementación nativa.


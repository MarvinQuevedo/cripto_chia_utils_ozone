// ignore_for_file: lines_longer_than_80_chars

import 'dart:typed_data';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:flutter_chia_rust_utils/ffi.io.dart' as frb;
import 'package:flutter_chia_rust_utils/generated/bridge_generated.dart' show Rust;
import 'package:get_it/get_it.dart';

/// A `(privateKey, message)` pair to pass to [BlsSigner.signBatch].
class SignTask {
  const SignTask(this.sk, this.message);
  final PrivateKey sk;
  final List<int> message;
}

/// Abstraction over BLS signing so consumers can plug in a faster
/// implementation (e.g. native `blst` via `flutter_chia_rust_utils`)
/// without changing wallet-service code.
///
/// Resolution order when calling [resolve]:
/// 1. a [BlsSigner] explicitly registered in [GetIt]
/// 2. [NativeBlsSigner] (backed by `flutter_chia_rust_utils` / `blst`)
///
/// Register a different signer early in your app bootstrap if you want
/// to force the pure-Dart path:
/// ```dart
/// GetIt.I.registerSingleton<BlsSigner>(DartBlsSigner());
/// ```
abstract class BlsSigner {
  /// Sign [message] with [sk] using AugScheme.
  Future<JacobianPoint> sign(PrivateKey sk, List<int> message);

  /// Sign a batch of tasks. Default: [Future.wait] over [sign].
  /// Native backends can override for true parallelism.
  Future<List<JacobianPoint>> signBatch(List<SignTask> items) =>
      Future.wait(items.map((t) => sign(t.sk, t.message)));

  /// Aggregate a list of BLS signatures.
  Future<JacobianPoint> aggregate(List<JacobianPoint> signatures);

  /// Resolves the signer to use. Consumers can override by registering
  /// a [BlsSigner] singleton in [GetIt].
  static BlsSigner resolve() {
    if (GetIt.I.isRegistered<BlsSigner>()) {
      return GetIt.I<BlsSigner>();
    }
    return NativeBlsSigner();
  }
}

/// Pure-Dart signer — the original `AugSchemeMPL` implementation.
/// Slow (~120 ms per `sign` on Apple Silicon) but requires no native code.
class DartBlsSigner implements BlsSigner {
  @override
  Future<JacobianPoint> sign(PrivateKey sk, List<int> message) async =>
      AugSchemeMPL.sign(sk, message);

  @override
  Future<List<JacobianPoint>> signBatch(List<SignTask> items) async {
    // Dart BLS is single-threaded BigInt work; Future.wait wouldn't help.
    // Callers that need true parallelism should use AugSchemeMPL.signAsync
    // directly, which spawns an isolate per sign.
    return [for (final t in items) AugSchemeMPL.sign(t.sk, t.message)];
  }

  @override
  Future<JacobianPoint> aggregate(List<JacobianPoint> signatures) async =>
      AugSchemeMPL.aggregate(signatures);
}

/// Native signer backed by `flutter_chia_rust_utils` (Rust + `blst`).
/// ~250× faster than [DartBlsSigner] per sign. Default when no signer
/// is registered in [GetIt].
///
/// In production (Flutter app on iOS/Android/macOS/Windows/Linux), leave
/// [api] null and the plugin's own loader is used. For tests or custom
/// dylib paths, inject a `Rust` instance built from a manually-loaded
/// `DynamicLibrary`.
class NativeBlsSigner implements BlsSigner {
  NativeBlsSigner({Rust? api}) : _api = api ?? frb.api;

  final Rust _api;

  Uint8List _u8(List<int> x) => x is Uint8List ? x : Uint8List.fromList(x);

  @override
  Future<JacobianPoint> sign(PrivateKey sk, List<int> message) async {
    final sigBytes = await _api.signatureSign(
      sk: _u8(sk.toBytes().byteList),
      msg: _u8(message),
    );
    return JacobianPoint.fromBytesG2(sigBytes.toList());
  }

  @override
  Future<List<JacobianPoint>> signBatch(List<SignTask> items) async {
    // flutter_rust_bridge serialises dispatch on a single worker thread,
    // but Future.wait keeps the pipeline full while each call does work.
    final sigBytes = await Future.wait([
      for (final t in items)
        _api.signatureSign(
          sk: _u8(t.sk.toBytes().byteList),
          msg: _u8(t.message),
        ),
    ]);
    return [for (final b in sigBytes) JacobianPoint.fromBytesG2(b.toList())];
  }

  @override
  Future<JacobianPoint> aggregate(List<JacobianPoint> signatures) async {
    // Rust `signature_aggregate` takes a concatenated stream of 96-byte sigs.
    final buf = BytesBuilder();
    for (final s in signatures) {
      buf.add(s.toBytes().byteList);
    }
    final aggregated = await _api.signatureAggregate(
      sigsStream: buf.toBytes(),
      length: signatures.length,
    );
    return JacobianPoint.fromBytesG2(aggregated.toList());
  }
}

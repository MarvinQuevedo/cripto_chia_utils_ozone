// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:get_it/get_it.dart';

/// A `(privateKey, message)` pair to pass to [BlsSigner.signBatch].
class SignTask {
  const SignTask(this.sk, this.message);
  final PrivateKey sk;
  final List<int> message;
}

/// Abstraction over BLS signing so consumers can plug in a faster
/// implementation without changing wallet-service code.
///
/// Resolution order when calling [resolve]:
/// 1. a [BlsSigner] explicitly registered in [GetIt]
/// 2. [DartBlsSigner] (pure-Dart `AugSchemeMPL`)
///
/// The native (`flutter_chia_rust_utils` / `blst`) signer was removed as
/// part of the Sage-engine migration: the Rust BLS now lives in the Sage
/// FFI engine (flutter_rust_bridge v2). Register a Sage-backed [BlsSigner]
/// early in app bootstrap to keep signing fast:
/// ```dart
/// GetIt.I.registerSingleton<BlsSigner>(SageBlsSigner());
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
  /// a [BlsSigner] singleton in [GetIt] (e.g. a Sage-backed signer).
  static BlsSigner resolve() {
    if (GetIt.I.isRegistered<BlsSigner>()) {
      return GetIt.I<BlsSigner>();
    }
    return DartBlsSigner();
  }
}

/// Pure-Dart signer — the original `AugSchemeMPL` implementation.
/// Slow (~120 ms per `sign` on Apple Silicon) but requires no native code.
/// This is the default; register a Sage-backed [BlsSigner] in [GetIt] for
/// the fast native path.
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

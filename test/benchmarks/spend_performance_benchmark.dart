// ignore_for_file: lines_longer_than_80_chars
//
// Benchmark measures the cost of creating spend bundles with many coins,
// and compares:
//   - pure-Dart path: StandardWalletService.createSpendBundle (sync)
//   - native path:    StandardWalletService.createSpendBundleAsync
//                     with a NativeBlsSigner backed by Rust + blst.
//
// The native path requires the Rust dylib to be available. In a real
// Flutter app on macOS/iOS/Android/Linux/Windows the plugin links it
// automatically. Under `dart test` / `flutter test` there is nothing
// linked, so this benchmark builds the dylib on demand and loads it
// via DynamicLibrary.open. Set env var `BLS_DYLIB_PATH` to point at a
// prebuilt library and skip the build step.

import 'dart:ffi' as ffi;
import 'dart:io';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:flutter_chia_rust_utils/generated/bridge_generated.dart';
import 'package:flutter_chia_rust_utils/generated/bridge_generated.io.dart';
import 'package:test/test.dart';

// ─── helpers ─────────────────────────────────────────────────────────────────

const _testMnemonic = [
  'elder', 'quality', 'this', 'chalk', 'crane', 'endless',
  'machine', 'hotel', 'unfair', 'castle', 'expand', 'refuse',
  'lizard', 'vacuum', 'embody', 'track', 'crash', 'truth',
  'arrow', 'tree', 'poet', 'audit', 'grid', 'mesh',
];

/// Unique, deterministic 32-byte parent coin info for index [i].
Bytes _parentInfo(int i) =>
    Bytes(List.generate(32, (j) => (i * 7 + j * 13) & 0xff));

/// Creates [n] coins all locked to [puzzlehash], each worth 1 XCH (1e12 mojo).
List<Coin> _makeCoins(int n, Puzzlehash puzzlehash) => List.generate(
      n,
      (i) => Coin(
        spentBlockIndex: 0,
        confirmedBlockIndex: 100 + i,
        coinbase: false,
        timestamp: 1700000000 + i,
        parentCoinInfo: _parentInfo(i),
        puzzlehash: puzzlehash,
        amount: 1000000000000,
      ),
    );

/// Pretty-prints a duration.
String _fmt(Duration d) {
  if (d.inMicroseconds < 1000) return '${d.inMicroseconds} µs';
  if (d.inMilliseconds < 1000) return '${d.inMilliseconds} ms';
  return '${(d.inMilliseconds / 1000).toStringAsFixed(2)} s';
}

/// Locate or build `librust_bls_flutter.dylib` so the benchmark can load it
/// from a pure Dart test (the plugin's default loader expects Flutter linkage).
/// Returns null when the dylib cannot be produced on this host.
Rust? _buildOrLoadNativeApi() {
  // 1. honour explicit override
  final override = Platform.environment['BLS_DYLIB_PATH'];
  if (override != null && File(override).existsSync()) {
    return RustImpl(ffi.DynamicLibrary.open(override));
  }

  // 2. cached path from a previous run of this benchmark
  final cached = '/tmp/flutter_chia_rust_utils/chia_rust_utils/target/release/librust_bls_flutter.dylib';
  if (File(cached).existsSync()) {
    return RustImpl(ffi.DynamicLibrary.open(cached));
  }

  // 3. clone + build (slow, one-time)
  print('[setup] Rust dylib not found — cloning + building...');
  final cloneResult = Process.runSync(
    'bash',
    [
      '-c',
      'cd /tmp && '
          'git clone --branch fix_android_package https://github.com/MarvinQuevedo/flutter_chia_rust_utils.git 2>/dev/null; '
          'cd flutter_chia_rust_utils && git submodule update --init --recursive && '
          'cd chia_rust_utils && cargo build --release --lib',
    ],
  );
  if (cloneResult.exitCode != 0) {
    print('[setup] build failed:\n${cloneResult.stderr}');
    return null;
  }
  if (File(cached).existsSync()) {
    return RustImpl(ffi.DynamicLibrary.open(cached));
  }
  return null;
}

// ─── benchmark ───────────────────────────────────────────────────────────────

void main() {
  ChiaNetworkContextWrapper().registerNetworkContext(Network.mainnet);

  final keychainSecret = KeychainCoreSecret.fromMnemonic(_testMnemonic);

  // 60 wallet sets — enough for all test sizes below.
  final walletSets = [
    for (var i = 0; i < 60; i++)
      WalletSet.fromPrivateKey(keychainSecret.masterPrivateKey, i),
  ];
  final keychain = WalletKeychain.fromWalletSets(walletSets);

  final spenderPuzzlehash = keychain.unhardenedMap.values.first.puzzlehash;
  final changePuzzlehash = keychain.unhardenedMap.values.toList()[1].puzzlehash;
  final destinationPuzzlehash =
      keychain.unhardenedMap.values.toList()[2].puzzlehash;

  final walletService = StandardWalletService();

  // ── 1. micro-benchmarks ────────────────────────────────────────────────────

  group('micro-benchmarks (single operation)', () {
    final walletVector = keychain.getWalletVector(spenderPuzzlehash)!;
    final pk = walletVector.childPublicKey;
    final sk = walletVector.childPrivateKey;
    final puzzle = getPuzzleFromPk(pk);

    test('getPuzzleFromPk (puzzle reveal generation)', () {
      const iterations = 20;
      final sw = Stopwatch()..start();
      for (var i = 0; i < iterations; i++) {
        getPuzzleFromPk(pk);
      }
      sw.stop();
      final avg = sw.elapsed ~/ iterations;
      print('\n[micro] getPuzzleFromPk  avg = ${_fmt(avg)}  '
          '(${iterations}x total = ${_fmt(sw.elapsed)})');
    });

    test('CLVM puzzle.run(solution) — standard puzzle', () {
      const iterations = 20;
      final solution = BaseWalletService.makeSolutionFromConditions([
        CreateCoinCondition(destinationPuzzlehash, 1000),
        ReserveFeeCondition(0),
      ]);
      final sw = Stopwatch()..start();
      for (var i = 0; i < iterations; i++) {
        puzzle.run(solution);
      }
      sw.stop();
      final avg = sw.elapsed ~/ iterations;
      print('\n[micro] puzzle.run()     avg = ${_fmt(avg)}  '
          '(${iterations}x total = ${_fmt(sw.elapsed)})');
    });

    test('AugSchemeMPL.sign — single BLS signature', () {
      const iterations = 10;
      final dummyMsg = List.filled(96, 0x42);
      final sw = Stopwatch()..start();
      for (var i = 0; i < iterations; i++) {
        AugSchemeMPL.sign(sk, dummyMsg);
      }
      sw.stop();
      final avg = sw.elapsed ~/ iterations;
      print('\n[micro] AugSchemeMPL.sign  avg = ${_fmt(avg)}  '
          '(${iterations}x total = ${_fmt(sw.elapsed)})');
    });

    test('AugSchemeMPL.aggregate — aggregating 20 signatures', () {
      const n = 20;
      final dummyMsg = List.filled(96, 0x42);
      final sigs = [for (var i = 0; i < n; i++) AugSchemeMPL.sign(sk, dummyMsg)];
      final sw = Stopwatch()..start();
      AugSchemeMPL.aggregate(sigs);
      sw.stop();
      print('\n[micro] AugSchemeMPL.aggregate(20 sigs)  = ${_fmt(sw.elapsed)}');
    });

    test('program.hash() — tree hash of standard puzzle', () {
      const iterations = 50;
      final sw = Stopwatch()..start();
      for (var i = 0; i < iterations; i++) {
        puzzle.hash();
      }
      sw.stop();
      final avg = sw.elapsed ~/ iterations;
      print('\n[micro] puzzle.hash()    avg = ${_fmt(avg)}  '
          '(${iterations}x total = ${_fmt(sw.elapsed)})');
    });

    test('program.toSource() — used in debug prints', () {
      final solution = BaseWalletService.makeSolutionFromConditions([
        CreateCoinCondition(destinationPuzzlehash, 1000),
        ReserveFeeCondition(0),
      ]);
      const iterations = 50;
      final sw = Stopwatch()..start();
      for (var i = 0; i < iterations; i++) {
        solution.toSource();
      }
      sw.stop();
      final avg = sw.elapsed ~/ iterations;
      print('\n[micro] solution.toSource()  avg = ${_fmt(avg)}  '
          '(${iterations}x total = ${_fmt(sw.elapsed)})');
    });
  });

  // ── 2. end-to-end spend benchmarks ────────────────────────────────────────

  group('createSpendBundle — end-to-end by coin count', () {
    for (final n in [1, 5, 10, 20, 50]) {
      test('spend $n coin(s)', () {
        final coins = _makeCoins(n, spenderPuzzlehash);
        final totalValue = coins.fold(0, (s, c) => s + c.amount);

        final sw = Stopwatch()..start();
        final result = walletService.createSpendBundle(
          payments: [Payment(totalValue - 100000, destinationPuzzlehash)],
          coinsInput: coins,
          changePuzzlehash: changePuzzlehash,
          keychain: keychain,
          fee: 0,
        );
        sw.stop();

        final bundle = result.item1;
        expect(bundle.coinSpends.length, n);

        final perCoin = sw.elapsed ~/ n;
        print('\n[e2e] spend $n coins: total=${_fmt(sw.elapsed)}  '
            'per-coin avg=${_fmt(perCoin)}');
      });
    }
  });

  // ── 3. phase-by-phase breakdown ────────────────────────────────────────────

  group('phase breakdown (20 coins)', () {
    const n = 20;
    final coins = _makeCoins(n, spenderPuzzlehash);
    final walletVector = keychain.getWalletVector(spenderPuzzlehash)!;
    final pk = walletVector.childPublicKey;
    final sk = walletVector.childPrivateKey;

    test('phase 1 — puzzle reveal (getPuzzleFromPk) × $n', () {
      final sw = Stopwatch()..start();
      for (var i = 0; i < n; i++) {
        getPuzzleFromPk(pk);
      }
      sw.stop();
      print('\n[phase 1] $n × getPuzzleFromPk   = ${_fmt(sw.elapsed)}');
    });

    test('phase 2 — solution building × $n', () {
      final sw = Stopwatch()..start();
      for (var i = 0; i < n; i++) {
        BaseWalletService.makeSolutionFromConditions([
          CreateCoinCondition(destinationPuzzlehash, 1000),
        ]);
      }
      sw.stop();
      print('\n[phase 2] $n × makeSolutionFromConditions  = ${_fmt(sw.elapsed)}');
    });

    test('phase 3 — CLVM run × $n', () {
      final puzzle = getPuzzleFromPk(pk);
      final solution = BaseWalletService.makeSolutionFromConditions([
        CreateCoinCondition(destinationPuzzlehash, 1000),
      ]);
      final sw = Stopwatch()..start();
      for (var i = 0; i < n; i++) {
        puzzle.run(solution);
      }
      sw.stop();
      print('\n[phase 3] $n × puzzle.run()   = ${_fmt(sw.elapsed)}  '
          '(avg ${_fmt(sw.elapsed ~/ n)})');
    });

    test('phase 4 — BLS sign × $n', () {
      final puzzle = getPuzzleFromPk(pk);
      final solution = BaseWalletService.makeSolutionFromConditions([
        CreateCoinCondition(destinationPuzzlehash, 1000),
      ]);
      final syntheticSk = calculateSyntheticPrivateKey(sk);
      final result = puzzle.run(solution);

      // Compute the message the way makeSignature does.
      final addsigmeMsg = result.program
          .toList()
          .singleWhere(AggSigMeCondition.isThisCondition);
      final baseMsg = Bytes(addsigmeMsg.toList()[2].atom) +
          coins.first.id +
          Bytes.fromHex(
            ChiaNetworkContextWrapper().blockchainNetwork.aggSigMeExtraData,
          );

      final sw = Stopwatch()..start();
      for (var i = 0; i < n; i++) {
        AugSchemeMPL.sign(syntheticSk, baseMsg);
      }
      sw.stop();
      print('\n[phase 4] $n × AugSchemeMPL.sign   = ${_fmt(sw.elapsed)}  '
          '(avg ${_fmt(sw.elapsed ~/ n)})');
    });

    test('phase 5 — BLS aggregate $n signatures (standalone)', () {
      final dummyMsg = List.filled(96, 0x55);
      final syntheticSk = calculateSyntheticPrivateKey(sk);
      final sigs = [for (var i = 0; i < n; i++) AugSchemeMPL.sign(syntheticSk, dummyMsg)];

      final sw = Stopwatch()..start();
      AugSchemeMPL.aggregate(sigs);
      sw.stop();
      print('\n[phase 5] aggregate($n sigs)   = ${_fmt(sw.elapsed)}');
    });

    test('phase X — toSource() debug overhead × $n (current code)', () {
      final solution = BaseWalletService.makeSolutionFromConditions([
        CreateCoinCondition(destinationPuzzlehash, 1000),
      ]);
      final sw = Stopwatch()..start();
      for (var i = 0; i < n; i++) {
        // This mirrors what base_wallet.dart currently does on every iteration.
        solution.toSource();
      }
      sw.stop();
      print('\n[phase X] $n × solution.toSource() WASTED by debug prints  '
          '= ${_fmt(sw.elapsed)}');
    });
  });

  // ── 4. native vs dart comparison ──────────────────────────────────────────

  final nativeApi = _buildOrLoadNativeApi();
  final skipReason = nativeApi == null
      ? 'Rust dylib unavailable (could not build/find librust_bls_flutter)'
      : null;

  group('createSpendBundle DART vs NATIVE (Rust blst)', () {
    for (final n in [1, 5, 10, 20, 50]) {
      test('$n coins — DART sync path', () {
        final coins = _makeCoins(n, spenderPuzzlehash);
        final totalValue = coins.fold(0, (s, c) => s + c.amount);

        final sw = Stopwatch()..start();
        final result = walletService.createSpendBundle(
          payments: [Payment(totalValue - 100000, destinationPuzzlehash)],
          coinsInput: coins,
          changePuzzlehash: changePuzzlehash,
          keychain: keychain,
        );
        sw.stop();
        expect(result.item1.coinSpends.length, n);
        print('\n[DART ] $n coins  total=${_fmt(sw.elapsed)}  per-coin=${_fmt(sw.elapsed ~/ n)}');
      });

      test('$n coins — NATIVE async path', () async {
        final signer = NativeBlsSigner(api: nativeApi!);
        final coins = _makeCoins(n, spenderPuzzlehash);
        final totalValue = coins.fold(0, (s, c) => s + c.amount);

        final sw = Stopwatch()..start();
        final result = await walletService.createSpendBundleAsync(
          payments: [Payment(totalValue - 100000, destinationPuzzlehash)],
          coinsInput: coins,
          changePuzzlehash: changePuzzlehash,
          keychain: keychain,
          signer: signer,
        );
        sw.stop();
        expect(result.item1.coinSpends.length, n);
        print('\n[RUST ] $n coins  total=${_fmt(sw.elapsed)}  per-coin=${_fmt(sw.elapsed ~/ n)}');
      }, skip: skipReason);
    }

    test('sanity: DART and NATIVE produce the same aggregated signature', () async {
      final signer = NativeBlsSigner(api: nativeApi!);
      final coins = _makeCoins(5, spenderPuzzlehash);
      final totalValue = coins.fold(0, (s, c) => s + c.amount);

      final dartBundle = walletService.createSpendBundle(
        payments: [Payment(totalValue - 100000, destinationPuzzlehash)],
        coinsInput: coins,
        changePuzzlehash: changePuzzlehash,
        keychain: keychain,
      ).item1;

      final nativeBundle = (await walletService.createSpendBundleAsync(
        payments: [Payment(totalValue - 100000, destinationPuzzlehash)],
        coinsInput: coins,
        changePuzzlehash: changePuzzlehash,
        keychain: keychain,
        signer: signer,
      )).item1;

      final dartAgg = dartBundle.aggregatedSignature!.toBytes().toHex();
      final nativeAgg = nativeBundle.aggregatedSignature!.toBytes().toHex();
      print('\n[sanity] dart agg:   ${dartAgg.substring(0, 32)}...');
      print('[sanity] native agg: ${nativeAgg.substring(0, 32)}...');
      expect(nativeAgg, dartAgg, reason: 'native signer must produce the same aggregated sig as Dart');
      print('[sanity] ✓ aggregated signatures match — native signer is a drop-in replacement');

      // Also validate via Dart path (native must pass the same signature check).
      walletService.validateSpendBundle(nativeBundle);
      print('[sanity] ✓ native bundle passes Dart BLS signature verification');
    }, skip: skipReason);
  });
}

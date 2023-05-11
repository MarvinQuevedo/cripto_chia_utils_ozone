import 'package:chia_crypto_utils/src/clvm.dart';
import 'package:chia_crypto_utils/src/core/index.dart';

typedef BuildKeychain = Future<WalletKeychain?> Function(Set<Puzzlehash> phs);

import 'dart:typed_data';

import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:chia_utils/src/core/puzzles/calculate_synthetic_public_key/calculate_synthetic_public_key.clvm.hex.dart';
import 'package:chia_utils/src/standard/puzzles/default_hidden_puzzle/default_hidden_puzzle.clvm.hex.dart';
import 'package:chia_utils/src/standard/puzzles/p2_delegated_puzzle_or_hidden_puzzle/p2_delegated_puzzle_or_hidden_puzzle.clvm.hex.dart';
import 'package:crypto/crypto.dart';

// cribbed from chia/wallet/derive_keys.py
// EIP 2334 bls key derivation
// https://eips.ethereum.org/EIPS/eip-2334
// 12381 = bls spec number
// 8444 = Chia blockchain number and port number
// farmer: 0, pool: 1, wallet: 2, local: 3, backup key: 4, singleton: 5,
// pooling authentication key numbers: 6

const blsSpecNumber = 12381;
const chiaBlockchanNumber = 8444;
const farmerPathNumber = 0;
const poolPathNumber = 1;
const walletPathNumber = 2;
const localPathNumber = 3;
const backupKeyPathNumber = 4;
const singletonPathNumber = 5;
const poolingAuthenticationPathNumber = 6;

PrivateKey derivePath(PrivateKey sk, List<int> path) {
  return path.fold(sk, AugSchemeMPL.deriveChildSk);
}

PrivateKey derivePathUnhardened(PrivateKey sk, List<int> path) {
  return path.fold(sk, AugSchemeMPL.deriveChildSkUnhardened);
}

PrivateKey masterSkToFarmerSk(PrivateKey masterSk) {
  return derivePath(
    masterSk,
    [blsSpecNumber, chiaBlockchanNumber, farmerPathNumber, 0],
  );
}

PrivateKey masterSkToPoolSk(PrivateKey masterSk) {
  return derivePath(
    masterSk,
    [blsSpecNumber, chiaBlockchanNumber, poolPathNumber, 0],
  );
}

PrivateKey masterSkToWalletSk(PrivateKey masterSk, int index) {
  return derivePath(
    masterSk,
    [blsSpecNumber, chiaBlockchanNumber, walletPathNumber, index],
  );
}

PrivateKey masterSkToWalletSkUnhardened(PrivateKey masterSk, int index) {
  return derivePathUnhardened(
    masterSk,
    [blsSpecNumber, chiaBlockchanNumber, walletPathNumber, index],
  );
}

PrivateKey masterSkToLocalSk(PrivateKey masterSk) {
  return derivePath(
    masterSk,
    [blsSpecNumber, chiaBlockchanNumber, localPathNumber, 0],
  );
}

PrivateKey masterSkToBackupSk(PrivateKey masterSk) {
  return derivePath(
    masterSk,
    [blsSpecNumber, chiaBlockchanNumber, backupKeyPathNumber, 0],
  );
}

// This key controls a singleton on the blockchain, allowing for dynamic
// pooling (changing pools)
PrivateKey masterSkToSingletonOwnerSk(
  PrivateKey masterSk,
  int poolWalletIndex,
) {
  return derivePath(masterSk, [
    blsSpecNumber,
    chiaBlockchanNumber,
    singletonPathNumber,
    poolWalletIndex
  ]);
}

// This key is used for the farmer to authenticate
// to the pool when sending partials
PrivateKey masterSkToPoolingAuthenticationSk(
  PrivateKey masterSk,
  int poolWalletIndex,
  int index,
) {
  assert(index < 10000, 'Index must be less tah 10000');
  assert(poolWalletIndex < 10000, 'Pool wallet index must be less tah 10000');
  return derivePath(masterSk, [
    blsSpecNumber,
    chiaBlockchanNumber,
    poolingAuthenticationPathNumber,
    poolWalletIndex * 10000 + index
  ]);
}

// cribbed from chia/wallet/puzzles/p2_delegated_puzzle_or_hidden_puzzle.py
Program getPuzzleFromPk(JacobianPoint publicKey) {
  final syntheticPubKey = calculateSyntheticPublicKeyProgram.run(
    Program.list([
      Program.fromBytes(publicKey.toBytes()),
      Program.fromBytes(defaultHiddenPuzzleProgram.hash())
    ]),
  );

  final curried = p2DelegatedPuzzleOrHiddenPuzzleProgram.curry([syntheticPubKey.program]);

  return curried;
}

final groupOrder = BigInt.parse(
  '0x73EDA753299D7D483339D80809A1D80553BDA402FFFE5BFEFFFFFFFF00000001',
);

BigInt calculateSyntheticOffset(JacobianPoint publicKey) {
  final blob =
      sha256.convert(publicKey.toBytes() + defaultHiddenPuzzleProgram.hash()).bytes;
  // print(blob);
  final offset = bytesToBigInt(blob, Endian.big, signed: true);
  // print(offset.toString());
  final newOffset = offset % groupOrder;
  return newOffset;
}

PrivateKey calculateSyntheticPrivateKey(PrivateKey privateKey) {
  final secretExponent = bytesToBigInt(privateKey.toBytes(), Endian.big);

  final publicKey = privateKey.getG1();

  final syntheticOffset = calculateSyntheticOffset(publicKey);

  final syntheticSecretExponent =
      (secretExponent + syntheticOffset) % groupOrder;

  final blob = bigIntToBytes(syntheticSecretExponent, 32, Endian.big);
  final syntheticPrivateKey = PrivateKey.fromBytes(blob);

  return syntheticPrivateKey;
}

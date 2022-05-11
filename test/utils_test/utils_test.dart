// ignore_for_file: avoid_void_async, lines_longer_than_80_chars

import 'dart:convert';
import 'dart:io';

import 'package:bip39/bip39.dart';
import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:csv/csv.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'resources/index.dart';

const testMnemonic = [
  'elder', 'quality', 'this', 'chalk', 'crane', 'endless',
  'machine', 'hotel', 'unfair', 'castle', 'expand', 'refuse',
  'lizard', 'vacuum', 'embody', 'track', 'crash', 'truth',
  'arrow', 'tree', 'poet', 'audit', 'grid', 'mesh',
];

// master public key generated by chia wallet from above mnemonic
const chiaFingerprint = 3109357790;
const chiaMasterPublicKeyHex = '901acd53bf61a63120f15442baf0f2a656267b08ba42c511b9bb543e31c32a9b49a0e0aa5e897bc81878d703fcd889f3';
const chiaFarmerPublicKeyHex = '8351d5afd1ab40bf37565d25600c9b147dcda344e19d413b2c468316d1efd312f61a1eca02a74f8d5f0d6e79911c23ca';
const chiaPoolPublicKeyHex = '926c9b71f4cfc3f8a595fc77d7edc509e2f426704489eaba6f86728bc391c628c402e00190ba3617931649d8c53b5520';
const chiaFirstAddress = Address('txch1v8vergyvwugwv0tmxwnmeecuxh3tat5jaskkunnn79zjz0muds0qlg2szv',
);

void main() async {
  // get chia wallet sets generated from testMnemonic
  var filePath = path.join(path.current, 'test/utils_test/resources/chia_wallet_sets.csv');
  filePath = path.normalize(filePath);
  final input = File(filePath).openRead();
  final chiaWalletSetRows =
      await input.transform(utf8.decoder).transform(const CsvToListConverter(eol: '\n')).toList();

  test('should generate correct puzzle hashes from mnemonic', () {
    final keychainSecret = KeychainCoreSecret.fromMnemonic(testMnemonic);
    final masterPrivateKey = keychainSecret.masterPrivateKey;

    final fingerprint = keychainSecret.masterPublicKey.getFingerprint();
    final masterPublicKeyHex = keychainSecret.masterPublicKey.toHex();
    final farmerPublicKeyHex = masterSkToFarmerSk(masterPrivateKey).getG1().toHex();
    final poolPublicKeyHex = masterSkToPoolSk(masterPrivateKey).getG1().toHex();

    expect(fingerprint, chiaFingerprint);
    expect(masterPublicKeyHex, chiaMasterPublicKeyHex);
    expect(farmerPublicKeyHex, chiaFarmerPublicKeyHex);
    expect(poolPublicKeyHex, chiaPoolPublicKeyHex);

    late Address firstAddress;
    for (var i = 0; i < 20; i++) {
      final chiaSet = ChiaWalletSet.fromRow(chiaWalletSetRows[i]);
      final set = WalletSet.fromPrivateKey(keychainSecret.masterPrivateKey, i);

      if (i == 0) {
        firstAddress = Address.fromPuzzlehash(set.hardened.puzzlehash, 'txch');
      }

      expect(chiaSet.hardened.puzzlehashHex, set.hardened.puzzlehash.toHex());
      expect(chiaSet.hardened.childPublicKeyHex, set.hardened.childPublicKey.toHex());
      expect(chiaSet.unhardened.puzzlehashHex, set.unhardened.puzzlehash.toHex());
      expect(chiaSet.unhardened.childPublicKeyHex, set.unhardened.childPublicKey.toHex());
      expect(firstAddress, chiaFirstAddress);
    }

    print('Fingerprint: $fingerprint');
    print('Master public key (m): $masterPublicKeyHex');
    print('Farmer public key (m/$blsSpecNumber/$chiaBlockchanNumber/$farmerPathNumber/0): $farmerPublicKeyHex',);
    print('Pool public key (m/$blsSpecNumber/$chiaBlockchanNumber/$poolPathNumber/0: $poolPublicKeyHex',);
    print('First wallet address: ${firstAddress.address}');
  });

  test('should generate a 24 word mnemonic', () {
    final mnemonicPhrase = generateMnemonic(strength: 256);
    print(mnemonicPhrase);

    expect(24, mnemonicPhrase.split(' ').length);
  });
}

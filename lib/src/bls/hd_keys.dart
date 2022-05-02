import 'dart:convert';
import 'dart:typed_data';

import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:chia_utils/src/bls/hkdf.dart';
import 'package:chia_utils/src/bls/util.dart';

PrivateKey keyGen(List<int> seed) {
  var L = 48;
  var okm =
      extractExpand(L, seed + [0], utf8.encode('BLS-SIG-KEYGEN-SALT-'), [0, L]);
  return PrivateKey(bytesToBigInt(okm, Endian.big) % defaultEc.n);
}

Bytes ikmToLamportSk(List<int> ikm, List<int> salt) {
  return extractExpand(32 * 255, ikm, salt, []);
}

Bytes parentSkToLamportPk(PrivateKey parentSk, int index) {
  var salt = intToBytes(index, 4, Endian.big);
  var ikm = parentSk.toBytes();
  var notIkm = ikm.map((e) => e ^ 0xFF).toList();
  var lamport0 = ikmToLamportSk(ikm, salt);
  var lamport1 = ikmToLamportSk(notIkm, salt);
  List<int> lamportPk = [];
  for (var i = 0; i < 255; i++) {
    lamportPk += hash256(lamport0.sublist(i * 32, (i + 1) * 32));
  }
  for (var i = 0; i < 255; i++) {
    lamportPk += hash256(lamport1.sublist(i * 32, (i + 1) * 32));
  }
  return hash256(lamportPk);
}

PrivateKey deriveChildSk(PrivateKey parentSk, int index) {
  return keyGen(parentSkToLamportPk(parentSk, index));
}

PrivateKey deriveChildSkUnhardened(PrivateKey parentSk, int index) {
  var h =
      hash256(parentSk.getG1().toBytes() + intToBytes(index, 4, Endian.big));
  return PrivateKey.aggregate([PrivateKey.fromBytes(h), parentSk]);
}

JacobianPoint deriveChildG1Unhardened(JacobianPoint parentPk, int index) {
  var h = hash256(parentPk.toBytes() + intToBytes(index, 4, Endian.big));
  return parentPk + JacobianPoint.generateG1() * PrivateKey.fromBytes(h).value;
}

JacobianPoint deriveChildG2Unhardened(JacobianPoint parentPk, int index) {
  var h = hash256(parentPk.toBytes() + intToBytes(index, 4, Endian.big));
  return parentPk + JacobianPoint.generateG2() * PrivateKey.fromBytes(h).value;
}

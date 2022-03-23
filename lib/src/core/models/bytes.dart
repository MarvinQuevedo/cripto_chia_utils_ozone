import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:hex/hex.dart';
import 'package:meta/meta.dart';

@immutable
class Bytes {
  static String bytesPrefix = '0x';
  final List<int> _byteList;

  const Bytes(this._byteList);

  // empty byte array
  // ignore: prefer_constructors_over_static_methods
  static Bytes get empty {
    return const Bytes([]);
  }

  factory Bytes.fromHex(String phHex) {
    if (phHex.startsWith(bytesPrefix)) {
      return Bytes(
        const HexDecoder().convert(phHex.replaceFirst(bytesPrefix, '')),
      );
    }
    return Bytes(const HexDecoder().convert(phHex));
  }

  Uint8List toUint8List() {
    return Uint8List.fromList(_byteList);
  }

  String toHex() {
    return const HexEncoder().convert(_byteList);
  }

  String get hexWithBytesPrefix {
    return bytesPrefix + toHex();
  }

  /// Returns a concatenation of this puzzlehash and [other].
  Bytes operator +(Bytes other) {
    return Bytes(toUint8List() + other.toUint8List());
  }

  @override
  bool operator ==(Object other) =>
      other is Bytes &&
      other.runtimeType == runtimeType &&
      other.toHex() == toHex();

  @override
  int get hashCode => toHex().hashCode;

  @override
  String toString() {
    return toHex();
  }

  Bytes sha256Hash() {
    return Bytes(sha256.convert(toUint8List()).bytes);
  }
}

typedef Puzzlehash = Bytes;

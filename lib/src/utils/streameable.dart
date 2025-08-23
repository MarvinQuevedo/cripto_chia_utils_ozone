import 'dart:convert';
import 'dart:typed_data';

import 'package:tuple/tuple.dart';

import '../../chia_crypto_utils.dart';
import '../wallet_protocol/models/index.dart';

Bytes streamClass(List<dynamic> fields) {
  StreamWriter writer = StreamWriter();
  for (final field in fields) {
    if (field is int) {
      writer.writeUint32(field);
    } else if (field is String) {
      writer.writeString(field);
    } else if (field is bool) {
      writer.writeBool(field);
    } else if (field is List<int>) {
      writer.writeBytes(field);
    } else if (field is List && field.isNotEmpty && field.first is Tuple2) {
      writer.writeList(field);
    } else if (field is Tuple2<dynamic, dynamic>) {
      writer.writeTuple(field);
    } else if (field is List<Tuple2<int, String>>) {
      for (final tuple in field) {
        writer.writeTuple(tuple);
      }
    } else {
      throw UnsupportedType('Unsupported type: ${field.runtimeType}');
    }
  }

  return Bytes(writer.toBytes());
}

abstract class Streamable {
  // Base class for all streamable objects
  Bytes toStreamBytes();
  Map<String, dynamic> toJson();
}

class StreamableError implements Exception {
  final String message;
  StreamableError(this.message);

  @override
  String toString() => 'StreamableError: $message';
}

class UnsupportedType extends StreamableError {
  UnsupportedType(super.message);
}

class InvalidTypeError extends StreamableError {
  final Type expected;
  final Type actual;

  InvalidTypeError(this.expected, this.actual)
      : super('Invalid type: Expected ${expected.toString()}, Actual: ${actual.toString()}');
}

class StreamWriter {
  final BytesBuilder _buffer = BytesBuilder();

  void writeUint8(int value) {
    _buffer.addByte(value);
  }

  void writeUint32(int value) {
    _buffer.add(Uint8List(4)..buffer.asByteData().setUint32(0, value, Endian.big));
  }

  void writeUint64(int value) {
    _buffer.add(Uint8List(8)..buffer.asByteData().setInt64(0, value, Endian.big));
  }

  void writeUint128(BigInt value) {
    _buffer.add(Uint8List(16)..buffer.asByteData().setInt64(0, value.toInt(), Endian.big));
  }

  void writeBytes(List<int> bytes) {
    writeUint32(bytes.length);
    _buffer.add(bytes);
  }

  void writeBytes32(Bytes32 value) {
    _buffer.add(value.byteList);
  }

  void writeBytes100(Bytes100 value) {
    _buffer.add(value.byteList);
  }

  void writeString(String value) {
    final bytes = utf8.encode(value);
    writeBytes(bytes);
  }

  void writeBool(bool value) {
    writeUint8(value ? 1 : 0);
  }

  void writeList(List<dynamic> value) {
    writeUint32(value.length);
    for (final item in value) {
      if (item is int) {
        writeUint32(item);
      } else if (item is String) {
        writeString(item);
      } else if (item is bool) {
        writeBool(item);
      } else if (item is List<int>) {
        writeList(item.map((e) => e as dynamic).toList());
      } else if (item is Tuple2<dynamic, dynamic>) {
        writeTuple(item);
      } else {
        throw UnsupportedType('Unsupported type: ${item.runtimeType}');
      }
    }
  }

  void writeTuple(Tuple2<dynamic, dynamic> value) {
    writeList([value.item1, value.item2]);
  }

  void writeUint16(int value, [Endian endian = Endian.big]) {
    _buffer.add(Uint8List(2)..buffer.asByteData().setUint16(0, value, endian));
  }

  void writeOptional<T>(T? value, void Function(T) writeInner) {
    if (value == null) {
      writeUint8(0);
    } else {
      writeUint8(1);
      writeInner(value);
    }
  }

  Bytes toBytes() => Bytes(_buffer.toBytes());

  void writeStreamable(Streamable streamable) {
    final streamBytes = streamable.toStreamBytes();
    _buffer.add(streamBytes.byteList);
  }
}

class StreamReader {
  final ByteData _data;
  int _offset = 0;

  StreamReader(Bytes bytes) : _data = bytes.byteList.buffer.asByteData();

  int readUint8() {
    final value = _data.getUint8(_offset);
    _offset += 1;
    return value;
  }

  int readUint64() {
    final value = _data.getUint64(_offset, Endian.big);
    _offset += 8;
    return value;
  }

  int readUint32([Endian endian = Endian.big]) {
    final value = _data.getUint32(_offset, endian);
    _offset += 4;
    return value;
  }

  int readUint16([Endian endian = Endian.big]) {
    final value = _data.getUint16(_offset, endian);
    _offset += 2;
    return value;
  }

  BigInt readUint128() {
    final value = _data.getUint64(_offset, Endian.big);
    _offset += 8;
    return BigInt.from(value);
  }

  Bytes readBytes() {
    final length = readUint32();
    if (_offset + length > _data.lengthInBytes) {
      throw InvalidSizeError(length, _data.lengthInBytes - _offset);
    }
    final bytes = Uint8List.view(_data.buffer, _offset, length);
    _offset += length;
    return Bytes(bytes);
  }

  Bytes32 readBytes32() {
    final bytes = Uint8List.view(_data.buffer, _offset, 32);
    _offset += 32;
    return Bytes32(bytes);
  }

  Bytes100 readBytes100() {
    final bytes = Uint8List.view(_data.buffer, _offset, 100);
    _offset += 100;
    return Bytes100(bytes);
  }

  String readString() {
    final bytes = readBytes();
    return utf8.decode(bytes);
  }

  bool readBool() {
    final value = readUint8();
    if (value == 0) return false;
    if (value == 1) return true;
    throw StreamableError('Bool byte must be 0 or 1');
  }

  T? readOptional<T>(T Function() readInner) {
    final isPresent = readUint8();
    if (isPresent == 0) return null;
    if (isPresent == 1) return readInner();
    throw StreamableError('Optional must be 0 or 1');
  }

  List<T> readList<T>(T Function(StreamReader reader) parser) {
    final length = readUint32();
    final list = <T>[];
    final reader = StreamReader(Bytes(readBytes()));

    for (var i = 0; i < length; i++) {
      list.add(parser(reader));
    }
    return list;
  }

  JacobianPoint readStreamG2() {
    final bytes = readBytes96();
    return JacobianPoint.fromBytesG2(bytes.byteList);
  }

  List<dynamic> readTupleList<T, R>() {
    final length = readUint32();
    final list = <dynamic>[];
    for (var i = 0; i < length; i++) {
      list.add(this.readTuple<T, R>());
    }
    return list;
  }

  dynamic _readValue(Type type, StreamReader reader) {
    if (type == Uint16List) {
      return reader.readUint16();
    } else if (type == int) {
      return reader.readUint32();
    } else if (type == String) {
      return reader.readString();
    } else if (type == bool) {
      return reader.readBool();
    } else if (type == List<int>) {
      return reader.readList<int>((reader) => reader.readUint32());
    } else if (type.toString().contains('Tuple2')) {
      throw UnsupportedType('Tuple2 is not supported');
    } else {
      throw UnsupportedType('Unsupported type: $type');
    }
  }

  Tuple2<dynamic, dynamic> readTuple<T, R>() {
    final item0 = _readValue(T, this);
    final item1 = _readValue(R, this);
    return Tuple2(item0, item1);
  }

  T readStreamable<T extends Streamable>(T Function(StreamReader reader) parser) {
    return parser(this);
  }

  T? readOptionalStreamable<T extends Streamable>(T Function(StreamReader reader) parser) {
    return readOptional(() => readStreamable(parser));
  }

  @override
  String toString() {
    return Bytes(_data.buffer.asUint8List()).toHex();
  }

  Bytes readBytes96() {
    final bytes = Uint8List.view(_data.buffer, _offset, 96);
    _offset += 96;
    return Bytes(bytes);
  }
}

// Example of a streamable class
class VersionedBlob extends Streamable {
  final int version;
  final Uint8List blob;

  VersionedBlob(this.version, this.blob);

  @override
  Bytes toStreamBytes() {
    final writer = StreamWriter()
      ..writeUint16(version)
      ..writeBytes(blob);
    return Bytes(writer.toBytes());
  }

  static VersionedBlob fromBytes(Uint8List bytes) {
    final reader = StreamReader(Bytes(bytes));
    return VersionedBlob(
      reader.readUint16(),
      reader.readBytes().byteList,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'version': version,
        'blob': '0x${blob.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}'
      };

  static VersionedBlob fromJson(Map<String, dynamic> json) {
    return VersionedBlob(
      json['version'] as int,
      _hexToBytes(json['blob'] as String),
    );
  }
}

// Utility function to convert hex string to bytes
Uint8List _hexToBytes(String hex) {
  hex = hex.startsWith('0x') ? hex.substring(2) : hex;
  if (hex.length % 2 != 0) hex = '0$hex';

  var result = Uint8List(hex.length ~/ 2);
  for (var i = 0; i < result.length; i++) {
    var value = int.parse(hex.substring(i * 2, (i * 2) + 2), radix: 16);
    result[i] = value;
  }
  return result;
}

class InvalidSizeError extends StreamableError {
  final int expected;
  final int actual;

  InvalidSizeError(this.expected, this.actual)
      : super('Invalid size: Expected $expected, Actual: $actual');
}

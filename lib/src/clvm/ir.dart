import 'package:chia_utils/src/clvm/bytes.dart';
import 'package:chia_utils/src/clvm/program.dart';

Program deserialize(Iterator<int> program) {
  final sizeBytes = <int>[];
  if (program.current <= 0x7f) {
    return Program.fromBytes([program.current]);
  } else if (program.current <= 0xbf) {
    sizeBytes.add(program.current & 0x3f);
  } else if (program.current <= 0xdf) {
    sizeBytes.add(0x1F);
    if (!program.moveNext()) {
      throw StateError('Expected next size byte in source.');
    }
    sizeBytes.add(program.current);
  } else if (program.current <= 0xef) {
    sizeBytes.add(0x0F);
    for (var i = 0; i < 2; i++) {
      if (!program.moveNext()) {
        throw StateError('Expected next size byte in source.');
      }
      sizeBytes.add(program.current);
    }
  } else if (program.current <= 0xf7) {
    sizeBytes.add(0x07);
    for (var i = 0; i < 3; i++) {
      if (!program.moveNext()) {
        throw StateError('Expected next size byte in source.');
      }
      sizeBytes.add(program.current);
    }
  } else if (program.current <= 0xfb) {
    sizeBytes.add(0x03);
    for (var i = 0; i < 4; i++) {
      if (!program.moveNext()) {
        throw StateError('Expected next size byte in source.');
      }
      sizeBytes.add(program.current);
    }
  } else if (program.current == 0xff) {
    if (!program.moveNext()) {
      throw StateError('Expected first atom in cons.');
    }
    final first = deserialize(program);
    if (!program.moveNext()) {
      throw StateError('Expected rest atom in cons.');
    }
    final rest = deserialize(program);
    return Program.cons(first, rest);
  } else {
    throw StateError('Invalid encoding.');
  }
  final size = decodeInt(sizeBytes);
  final bytes = <int>[];
  for (var i = 0; i < size; i++) {
    if (!program.moveNext()) {
      throw StateError('Expected next byte in atom.');
    }
    bytes.add(program.current);
  }
  return Program.fromBytes(bytes);
}

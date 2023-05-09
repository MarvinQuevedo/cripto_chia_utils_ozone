// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes, lines_longer_than_80_chars

import 'dart:convert';
import 'dart:io';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/clvm/instructions.dart';
import 'package:chia_crypto_utils/src/clvm/ir.dart';
import 'package:chia_crypto_utils/src/clvm/keywords.dart';
import 'package:chia_crypto_utils/src/clvm/parser.dart';
import 'package:chia_crypto_utils/src/clvm/printable.dart';
import 'package:compute/compute.dart';
import 'package:crypto/crypto.dart';
import 'package:hex/hex.dart';
import 'package:path/path.dart' as path;
import 'package:quiver/core.dart';

class Output {
  final Program program;
  final BigInt cost;
  Output(this.program, this.cost);

  Output.fromJson(Map<String, dynamic> json)
      : cost = BigInt.parse(json['cost'] as String),
        program = Program.parse(json['program'] as String);

  Map<String, dynamic> toJson() => <String, dynamic>{
        'cost': cost.toString(),
        'program': program.toSource(),
      };
}

class RunOptions {
  final BigInt? maxCost;
  final bool strict;
  RunOptions({this.maxCost, bool? strict}) : strict = strict ?? false;
}

typedef Validator = bool Function(Program);

/// Dart representation of a clvm program
///
/// Here are some example translations from a chia-blockchain [Program](https://github.com/Chia-Network/chia-blockchain/blob/9a951d835e25187b988e1fcc4af69e948eacfc82/chia/types/blockchain_format/program.py) to a chia-crypto-utils Program:
///
/// ```dart
/// Program.to([...]) => Program.list([...])
/// ```
///
/// ```dart
/// Program.to((...)) => Program.cons(...)
///  ```
/// ```dart
/// Program.to([bytes, 1, "hello"]) => Program.list([Program.fromBytes(bytes), Program.fromInt(1)], Program.fromString("hello"),)
/// ```
///  ```dart
/// program.get_tree_hash() => program.hash()
/// ```
class Program with ToBytesMixin, ToProgramMixin {
  List<Program>? _cons;
  Bytes? _atom;
  Position? position;

  static int cost = 11000000000;
  static Program nil = Program.fromBytes([]);

  @override
  Program toProgram() => this;

  @override
  bool operator ==(Object other) =>
      other is Program &&
      isCons == other.isCons &&
      (isCons
          ? first() == other.first() && rest() == other.rest()
          : toBigInt() == other.toBigInt());

  @override
  int get hashCode => isCons ? hash2(first().hashCode, rest().hashCode) : toBigInt().hashCode;

  bool get isNull => isAtom && atom.isEmpty;
  bool get isAtom => _atom != null;
  bool get isCons => _cons != null;
  Bytes get atom => _atom!;
  Bytes? get maybeAtom => _atom?.isNotEmpty == true ? _atom : null;
  List<Program> get cons => _cons!;
  String get positionSuffix => position == null ? '' : ' at $position';

  Program.cons(ToProgramMixin left, ToProgramMixin right)
      : _cons = [left.toProgram(), right.toProgram()];
  Program.fromBytes(List<int> atom) : _atom = Bytes(atom);
  static Program? maybeFromBytes(List<int>? atom) {
    if (atom == null) return null;
    return Program.fromBytes(atom);
  }

  factory Program.fromBytesOrNil(List<int>? atom) {
    if (atom == null) return Program.nil;
    return Program.fromBytes(atom);
  }
  Program.fromHex(String hex) : _atom = Bytes(const HexDecoder().convert(hex));
  // ignore: avoid_positional_boolean_parameters
  Program.fromBool(bool value) : _atom = Bytes(value ? [1] : []);
  Program.fromInt(int number) : _atom = encodeInt(number);
  Program.fromBigInt(BigInt number) : _atom = encodeBigInt(number);
  Program.fromString(String text) : _atom = Bytes(utf8.encode(text));

  factory Program.list(List<ToProgramMixin> items) {
    var result = Program.nil;
    for (var i = items.length - 1; i >= 0; i--) {
      result = Program.cons(items[i], result);
    }
    return result;
  }

  factory Program.parse(String source) {
    final stream = tokenStream(source);
    final iterator = stream.iterator;
    if (iterator.moveNext()) {
      return tokenizeExpr(source, iterator);
    } else {
      throw StateError('Unexpected end of source.');
    }
  }

  // TODO(nvjoshi2): dont want to keep reloading this every time
  factory Program.deserializeHexFilePath(String pathToFile) {
    var filePath = path.join(path.current, pathToFile);
    filePath = path.normalize(filePath);
    return Program.deserializeHexFile(File(filePath));
  }

  /// Loads a program from a [File].
  factory Program.deserializeHexFile(File file) {
    final lines = file.readAsLinesSync();

    try {
      final line = lines.singleWhere((line) => line.isNotEmpty);
      return Program.deserializeHex(line);
    } catch (_) {
      throw Exception('Invalid file input: Should include one line of hex');
    }
  }

  factory Program.deserialize(List<int> source) {
    final iterator = source.iterator;
    if (iterator.moveNext()) {
      return deserialize(iterator);
    } else {
      throw StateError('Unexpected end of source.');
    }
  }
  factory Program.fromStream(Iterator<int> iterator) {
    if (iterator.moveNext()) {
      return deserialize(iterator);
    } else {
      throw StateError('Unexpected end of source.');
    }
  }

  factory Program.deserializeHex(String source) {
    var _source = source;
    if (source.startsWith('0x')) {
      _source = source.replaceFirst('0x', '');
    }
    return Program.deserialize(const HexDecoder().convert(_source));
  }

  static Output runProgramIsolateTask(PuzzleAndSolution puzzleAndSolution) {
    final puzzle = puzzleAndSolution.puzzle;
    final solution = puzzleAndSolution.solution;
    final output = puzzle.run(solution, options: puzzleAndSolution.options);
    return output;
  }

  Future<Output> runAsync(Program args, {RunOptions? options}) async {
    return compute<PuzzleAndSolution, Output>(
      runProgramIsolateTask,
      PuzzleAndSolution(puzzle: this, solution: args, options: options),
    );
    // return spawnAndWaitForIsolate(
    //   taskArgument: PuzzleAndSolution(puzzle: this, solution: args, options: options),
    //   isolateTask: runProgramIsolateTask,
    //   handleTaskCompletion: Output.fromJson,
    // );
  }

  Output run(Program args, {RunOptions? options}) {
    options ??= RunOptions();
    final instructions = <Instruction>[eval];
    final stack = [Program.cons(this, args)];
    var cost = BigInt.zero;
    while (instructions.isNotEmpty) {
      final instruction = instructions.removeLast();
      cost += instruction(instructions, stack, options);
      if (options.maxCost != null && cost > options.maxCost!) {
        throw StateError(
          'Exceeded cost of ${options.maxCost}${stack[stack.length - 1].positionSuffix}.',
        );
      }
    }
    return Output(stack[stack.length - 1], cost);
  }

  Program curry(List<ToProgramMixin> args) {
    var current = Program.fromBigInt(keywords['q']!);
    for (final argument in args.reversed) {
      current = Program.cons(
        Program.fromBigInt(keywords['c']!),
        Program.cons(
          Program.cons(Program.fromBigInt(keywords['q']!), argument),
          Program.cons(current, Program.nil),
        ),
      );
    }
    return Program.parse('(a (q . ${toString()}) ${current.toString()})');
  }

  static Map<String, dynamic> _curryIsolateTask(CurryIsolateArguments arguments) {
    final curriedProgram = arguments.programToCurryTo.curry(arguments.programsToCurryIn);
    return <String, dynamic>{
      'program': curriedProgram.serializeHex(),
    };
  }

  Future<Program> curryAsync(List<Program> args) async {
    return spawnAndWaitForIsolate(
      taskArgument: CurryIsolateArguments(args, this),
      isolateTask: _curryIsolateTask,
      handleTaskCompletion: (taskResultJson) =>
          Program.deserializeHex(taskResultJson['program'] as String),
    );
  }

  static Map<String, dynamic> _uncurryIsolateTask(Program program) {
    final modAndArguments = program.uncurry();
    return <String, dynamic>{
      'mod': modAndArguments.mod.serializeHex(),
      'arguments': modAndArguments.arguments.map((e) => e.serializeHex()).toList()
    };
  }

  Future<ModAndArguments> uncurryAsync() {
    return spawnAndWaitForIsolate(
      taskArgument: this,
      isolateTask: _uncurryIsolateTask,
      handleTaskCompletion: ModAndArguments.fromJson,
    );
  }

  ModAndArguments uncurry() {
    final programList = toList();
    if (programList.length != 3) {
      throw ArgumentError(
        'Program is wrong length, should contain 3: (operator, puzzle, arguments)',
      );
    }
    if (programList[0].toInt() != 2) {
      throw ArgumentError('Program is missing apply operator (a)');
    }
    final uncurriedModule = _matchQuotedProgram(programList[1]);
    if (uncurriedModule == null) {
      throw ArgumentError('Puzzle did not match expected pattern');
    }
    final uncurriedArgs = _matchCurriedArgs(programList[2]);

    return ModAndArguments(uncurriedArgs, uncurriedModule);
  }

  static Program? _matchQuotedProgram(Program program) {
    final cons = program.cons;
    if (cons[0].toInt() == 1 && !cons[1].isAtom) {
      return cons[1];
    }
    return null;
  }

  static List<Program> _matchCurriedArgs(Program program) {
    final result = _matchCurriedArgsHelper([], program);
    return result.arguments;
  }

  static ModAndArguments _matchCurriedArgsHelper(
    List<Program> uncurriedArguments,
    Program inputProgram,
  ) {
    final inputProgramList = inputProgram.toList();
    // base case
    if (inputProgramList.isEmpty) {
      return ModAndArguments(uncurriedArguments, inputProgram);
    }
    final atom = _matchQuotedAtom(inputProgramList[1]);
    if (atom != null) {
      uncurriedArguments.add(atom);
    } else {
      final program = _matchQuotedProgram(inputProgramList[1]);
      if (program == null) {
        return ModAndArguments(uncurriedArguments, inputProgram);
      }
      uncurriedArguments.add(program);
    }
    final nextArgumentToParse = inputProgramList[2];
    return _matchCurriedArgsHelper(uncurriedArguments, nextArgumentToParse);
  }

  static Program? _matchQuotedAtom(Program program) {
    final cons = program.cons;
    if (cons[0].toInt() == 1 && cons[1].isAtom) {
      return cons[1];
    }
    return null;
  }

  Program first() {
    if (isAtom) {
      throw StateError('Cannot access first of ${toString()}$positionSuffix.');
    }
    return cons[0];
  }

  Program rest() {
    if (isAtom) {
      throw StateError('Cannot access rest of ${toString()}$positionSuffix.');
    }
    return cons[1];
  }

  Puzzlehash hash() {
    if (isAtom) {
      return Puzzlehash(sha256.convert([1] + atom.toList()).bytes);
    } else {
      return Puzzlehash(
        sha256.convert([2] + cons[0].hash().toList() + cons[1].hash().toList()).bytes,
      );
    }
  }

  String serializeHex() => const HexEncoder().convert(serialize());

  @override
  Bytes toBytes() => serialize();
  Bytes serialize() {
    if (isAtom) {
      if (atom.isEmpty) {
        return Bytes([0x80]);
      } else if (atom.length == 1 && atom[0] <= 0x7f) {
        return Bytes([atom[0]]);
      } else {
        final size = atom.length;
        final result = <int>[];
        if (size < 0x40) {
          result.add(0x80 | size);
        } else if (size < 0x2000) {
          result
            ..add(0xC0 | (size >> 8))
            ..add((size >> 0) & 0xFF);
        } else if (size < 0x100000) {
          result
            ..add(0xE0 | (size >> 16))
            ..add((size >> 8) & 0xFF)
            ..add((size >> 0) & 0xFF);
        } else if (size < 0x8000000) {
          result
            ..add(0xF0 | (size >> 24))
            ..add((size >> 16) & 0xFF)
            ..add((size >> 8) & 0xFF)
            ..add((size >> 0) & 0xFF);
        } else if (size < 0x400000000) {
          result
            ..add(0xF8 | (size >> 32))
            ..add((size >> 24) & 0xFF)
            ..add((size >> 16) & 0xFF)
            ..add((size >> 8) & 0xFF)
            ..add((size >> 0) & 0xFF);
        } else {
          throw RangeError(
            'Cannot serialize ${toString()} as it is 17,179,869,184 '
            'or more bytes in size$positionSuffix.',
          );
        }
        result.addAll(atom);
        return Bytes(result);
      }
    } else {
      return Bytes([
        0xff,
        ...cons[0].serialize(),
        ...cons[1].serialize(),
      ]);
    }
  }

  List<Program> toList({
    int? min,
    int? max,
    int? size,
    String? suffix,
    Validator? validator,
    String? type,
  }) {
    final result = <Program>[];
    var current = this;
    while (current.isCons) {
      final item = current.first();
      if (validator != null && !validator(item)) {
        throw ArgumentError(
          'Expected type $type for argument ${result.length + 1}'
          '${suffix != null ? ' $suffix' : ''}${item.positionSuffix}.',
        );
      }
      result.add(item);
      current = current.rest();
    }
    if (size != null && result.length != size) {
      throw ArgumentError(
        'Expected $size arguments'
        '${suffix != null ? ' $suffix' : ''}$positionSuffix.',
      );
    } else if (min != null && result.length < min) {
      throw ArgumentError(
        'Expected at least $min arguments'
        '${suffix != null ? ' $suffix' : ''}$positionSuffix.',
      );
    } else if (max != null && result.length > max) {
      throw ArgumentError(
        'Expected at most $max arguments'
        '${suffix != null ? ' $suffix' : ''}$positionSuffix.',
      );
    }
    return result;
  }

  List<Program> toAtomList({int? min, int? max, int? size, String? suffix}) {
    return toList(
      min: min,
      max: max,
      size: size,
      suffix: suffix,
      validator: (arg) => arg.isAtom,
      type: 'atom',
    );
  }

  List<bool> toBoolList({int? min, int? max, int? size, String? suffix}) {
    return toList(
      min: min,
      max: max,
      size: size,
      suffix: suffix,
      validator: (arg) => arg.isAtom,
      type: 'boolean',
    ).map((arg) => !arg.isNull).toList();
  }

  List<Program> toConsList({int? min, int? max, int? size, String? suffix}) {
    return toList(
      min: min,
      max: max,
      size: size,
      suffix: suffix,
      validator: (arg) => arg.isCons,
      type: 'cons',
    );
  }

  List<int> toIntList({int? min, int? max, int? size, String? suffix}) {
    return toList(
      min: min,
      max: max,
      size: size,
      suffix: suffix,
      validator: (arg) => arg.isAtom,
      type: 'int',
    ).map((arg) => arg.toInt()).toList();
  }

  List<BigInt> toBigIntList({int? min, int? max, int? size, String? suffix}) {
    return toList(
      min: min,
      max: max,
      size: size,
      suffix: suffix,
      validator: (arg) => arg.isAtom,
      type: 'int',
    ).map((arg) => arg.toBigInt()).toList();
  }

  @override
  String toHex() {
    if (isCons) {
      throw StateError(
        'Cannot convert ${toString()} to hex format$positionSuffix.',
      );
    } else {
      return const HexEncoder().convert(atom);
    }
  }

  bool toBool() {
    if (isCons) {
      throw StateError(
        'Cannot convert ${toString()} to boolean format$positionSuffix.',
      );
    } else {
      return !isNull;
    }
  }

  int toInt() {
    if (isCons) {
      throw StateError(
        'Cannot convert ${toString()} to int format$positionSuffix.',
      );
    } else {
      return decodeInt(atom);
    }
  }

  String get string => toString().replaceAll('"', '');

  BigInt toBigInt() {
    if (isCons) {
      throw StateError('Cannot convert ${toString()} to bigint format.');
    } else {
      return decodeBigInt(atom);
    }
  }

  // ignore: use_setters_to_change_properties
  void at(Position? position) => this.position = position;

  String toSource({bool? showKeywords}) {
    showKeywords ??= true;
    if (isAtom) {
      if (atom.isEmpty) {
        return '()';
      } else if (atom.length > 2) {
        try {
          final string = utf8.decode(atom);
          for (var i = 0; i < string.length; i++) {
            if (!printable.contains(string[i])) {
              return '0x${toHex()}';
            }
          }
          if (string.contains('"') && string.contains("'")) {
            return '0x${toHex()}';
          }
          final quote = string.contains('"') ? "'" : '"';
          return quote + string + quote;
        } catch (e) {
          return '0x${toHex()}';
        }
      } else if (bytesEqual(encodeInt(decodeInt(atom)), atom)) {
        return decodeInt(atom).toString();
      } else {
        return '0x${toHex()}';
      }
    } else {
      final buffer = StringBuffer('(');
      if (showKeywords) {
        try {
          final value = cons[0].toBigInt();
          buffer.write(keywords.keys.firstWhere((key) => keywords[key] == value));
        } catch (e) {
          buffer.write(cons[0].toSource(showKeywords: showKeywords));
        }
      } else {
        buffer.write(cons[0].toSource(showKeywords: showKeywords));
      }
      var current = cons[1];
      while (current.isCons) {
        buffer.write(' ${current.cons[0].toSource(showKeywords: showKeywords)}');
        current = current.cons[1];
      }
      if (!current.isNull) {
        buffer.write(' . ${current.toSource(showKeywords: showKeywords)}');
      }
      buffer.write(')');
      return buffer.toString();
    }
  }

  @override
  String toString() => toSource();
}

class ModAndArguments {
  ModAndArguments(this.arguments, this.mod);

  factory ModAndArguments.fromJson(Map<String, dynamic> json) => ModAndArguments(
        List<String>.from(json['arguments'] as Iterable<dynamic>)
            .map(Program.deserializeHex)
            .toList(),
        Program.deserializeHex(json['mod'] as String),
      );

  List<Program> arguments;
  Program mod;

  Map<String, dynamic> toJson() =>
      <String, dynamic>{'mod': mod, 'arguments': arguments.map((e) => e.serializeHex()).toList()};
}

class PuzzleAndSolution {
  final Program puzzle;
  final Program solution;
  final RunOptions? options;

  PuzzleAndSolution({
    required this.puzzle,
    required this.solution,
    required this.options,
  });
}

class CurryIsolateArguments {
  CurryIsolateArguments(this.programsToCurryIn, this.programToCurryTo);

  final List<Program> programsToCurryIn;
  final Program programToCurryTo;
}

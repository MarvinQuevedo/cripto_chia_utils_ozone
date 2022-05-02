// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:chia_utils/src/cat/puzzles/cat/cat.clvm.hex.dart';
import 'package:chia_utils/src/core/models/serializable.dart';
import 'package:chia_utils/src/standard/puzzles/p2_delegated_puzzle_or_hidden_puzzle/p2_delegated_puzzle_or_hidden_puzzle.clvm.hex.dart';
import 'package:hex/hex.dart';

class CoinSpend implements Serializable{
  CoinPrototype coin;
  Program puzzleReveal;
  Program solution;

  CoinSpend({
    required this.coin,
    required this.puzzleReveal,
    required this.solution,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
      'coin': coin.toJson(),
      'puzzle_reveal': const HexEncoder().convert(puzzleReveal.serialize()),
      'solution': const HexEncoder().convert(solution.serialize())
    };

  @override
  Bytes toBytes() {
    return coin.toBytes() + Bytes(puzzleReveal.serialize()) + Bytes(solution.serialize());
  }

  factory CoinSpend.fromJson(Map<String, dynamic> json) {
    return CoinSpend(
      coin: CoinPrototype.fromJson(json['coin'] as Map<String, dynamic>) ,
      puzzleReveal: Program.deserializeHex(json['puzzle_reveal'] as String) ,
      solution: Program.deserializeHex(json['solution'] as String),
    );
  }

  SpendType get type {
    final uncurriedPuzzleSource = puzzleReveal.uncurry().program.toSource();
    if (uncurriedPuzzleSource == p2DelegatedPuzzleOrHiddenPuzzleProgram.toSource()) {
      return SpendType.standard;
    }
    if (uncurriedPuzzleSource == catProgram.toSource()) {
      return SpendType.cat;
    }
    throw UnimplementedError('Unimplemented spend type');
  }
  @override
  String toString() => 'CoinSpend(coin: $coin, puzzleReveal: $puzzleReveal, solution: $solution)';
}

enum SpendType {
  standard,
  cat,
  nft
}

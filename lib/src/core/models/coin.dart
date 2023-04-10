// ignore_for_file: lines_longer_than_80_chars

import 'dart:typed_data';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:meta/meta.dart';

@immutable
class Coin extends CoinPrototype with ToBytesMixin {
  final int confirmedBlockIndex;
  final int spentBlockIndex;
  final bool coinbase;
  final int timestamp;

  DateTime get dateConfirmed => DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);

  bool get isSpent => spentBlockIndex != 0;

  double get amountXch => amount / mojosPerXch;

  const Coin({
    required this.confirmedBlockIndex,
    required this.spentBlockIndex,
    required this.coinbase,
    required this.timestamp,
    required super.parentCoinInfo,
    required super.puzzlehash,
    required super.amount,
  });

  Coin copyWith({
    int? confirmedBlockIndex,
    int? spentBlockIndex,
    bool? coinbase,
    int? timestamp,
    Bytes? parentCoinInfo,
    Puzzlehash? puzzlehash,
    int? amount,
  }) {
    return Coin(
        confirmedBlockIndex: confirmedBlockIndex ?? this.confirmedBlockIndex,
        spentBlockIndex: spentBlockIndex ?? this.spentBlockIndex,
        coinbase: coinbase ?? this.coinbase,
        timestamp: timestamp ?? this.timestamp,
        amount: amount ?? this.amount,
        parentCoinInfo: parentCoinInfo ?? this.parentCoinInfo,
        puzzlehash: puzzlehash ?? this.puzzlehash);
  }

  factory Coin.fromChiaCoinRecordJson(Map<String, dynamic> json) {
    final coinPrototype = CoinPrototype.fromJson(json['coin'] as Map<String, dynamic>);
    return Coin(
      confirmedBlockIndex: json['confirmed_block_index'] as int,
      spentBlockIndex: json['spent_block_index'] as int,
      coinbase: json['coinbase'] as bool,
      timestamp: json['timestamp'] as int,
      parentCoinInfo: coinPrototype.parentCoinInfo,
      puzzlehash: coinPrototype.puzzlehash,
      amount: coinPrototype.amount,
    );
  }

  factory Coin.fromBytes(Bytes bytes) {
    var length = decodeInt(bytes.sublist(0, 4));
    var left = 4;
    var right = left + length;

    final confirmedBlockIndex = decodeInt(bytes.sublist(left, right));

    length = decodeInt(bytes.sublist(right, right + 4));
    left = right + 4;
    right = left + length;
    final spentBlockIndex = decodeInt(bytes.sublist(left, right));

    length = decodeInt(bytes.sublist(right, right + 4));
    left = right + 4;
    right = left + length;
    assert(
      bytes.sublist(left, right).length == 1,
      'bool should have only one byte',
    );
    final coinbase = bytes.sublist(left, right)[0] == 1;

    length = decodeInt(bytes.sublist(right, right + 4));
    left = right + 4;
    right = left + length;
    final timestamp = decodeInt(bytes.sublist(left, right));

    length = decodeInt(bytes.sublist(right, right + 4));
    left = right + 4;
    right = left + length;
    final coinPrototype = CoinPrototype.fromBytes(bytes.sublist(left, right));

    return Coin(
      confirmedBlockIndex: confirmedBlockIndex,
      spentBlockIndex: spentBlockIndex,
      coinbase: coinbase,
      timestamp: timestamp,
      parentCoinInfo: coinPrototype.parentCoinInfo,
      puzzlehash: coinPrototype.puzzlehash,
      amount: coinPrototype.amount,
    );
  }

  factory Coin.fromBlokchainBytes(Bytes bytes) {
    final bytesIter = bytes.iterator;
    final coinPrototype = CoinPrototype.fromStream(bytesIter);

    final confirmedBlockIndex = bytesToInt(bytesIter.extractBytesAndAdvance(4), Endian.big);
    final spentBlockIndex = bytesToInt(bytesIter.extractBytesAndAdvance(4), Endian.big);
    final coinbase = bytesToInt(bytesIter.extractBytesAndAdvance(1), Endian.big) == 1;
    final timestamp = bytesToBigInt(bytesIter.extractBytesAndAdvance(8), Endian.big);

    return Coin(
      confirmedBlockIndex: confirmedBlockIndex,
      spentBlockIndex: spentBlockIndex,
      coinbase: coinbase,
      timestamp: timestamp.toInt(),
      parentCoinInfo: coinPrototype.parentCoinInfo,
      puzzlehash: coinPrototype.puzzlehash,
      amount: coinPrototype.amount,
    );
  }

  factory Coin.fromJson(Map<String, dynamic> json) {
    final coinPrototype = CoinPrototype.fromJson(json);
    return Coin(
      confirmedBlockIndex: json['confirmed_block_index'] as int,
      spentBlockIndex: json['spent_block_index'] as int,
      coinbase: json['coinbase'] as bool,
      timestamp: json['timestamp'] as int,
      parentCoinInfo: coinPrototype.parentCoinInfo,
      puzzlehash: coinPrototype.puzzlehash,
      amount: coinPrototype.amount,
    );
  }

  Map<String, dynamic> toFullJson() {
    final json = super.toJson()
      ..addAll(<String, dynamic>{
        'confirmed_block_index': confirmedBlockIndex,
        'spent_block_index': spentBlockIndex,
        'coinbase': coinbase,
        'timestamp': timestamp,
      });
    return json;
  }

  CoinPrototype toCoinPrototype() => CoinPrototype(
        parentCoinInfo: parentCoinInfo,
        puzzlehash: puzzlehash,
        amount: amount,
      );

  Bytes toCoinBytes() {
    final coinPrototypeBytes = super.toBytes();
    final coinPrototypeBytesLength = coinPrototypeBytes.length;
    return serializeList(<dynamic>[
          confirmedBlockIndex,
          spentBlockIndex,
          coinbase,
          timestamp,
        ]) +
        [...intTo32Bits(coinPrototypeBytesLength), ...coinPrototypeBytes];
  }

  @override
  String toString() =>
      'Coin(id: $id, parentCoinInfo: $parentCoinInfo puzzlehash: $puzzlehash, amount: $amount, confirmedBlockIndex: $confirmedBlockIndex), spentBlockIndex: $spentBlockIndex, coinbase: $coinbase, timestamp: $timestamp';
}

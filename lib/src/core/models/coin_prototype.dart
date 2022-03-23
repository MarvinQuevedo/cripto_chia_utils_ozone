import 'dart:typed_data';

import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';

@immutable
class CoinPrototype {
  final Bytes parentCoinInfo;
  final Puzzlehash puzzlehash;
  final int amount;

  const CoinPrototype({
    required this.parentCoinInfo,
    required this.puzzlehash,
    required this.amount,
  });

  CoinPrototype.fromJson(Map<String, dynamic> json)
      : parentCoinInfo = Bytes.fromHex(json['parent_coin_info'] as String),
        puzzlehash = Puzzlehash.fromHex(json['puzzle_hash'] as String),
        amount = json['amount'] as int;

  Bytes get id {
    return Bytes(sha256
        .convert(
            parentCoinInfo.toUint8List() +
            puzzlehash.toUint8List() +
            intToBytesStandard(amount, Endian.big),
          )
        .bytes,
      );
  }

  Map<String, dynamic> toJson() => <String, dynamic> {
      'parent_coin_info': parentCoinInfo.toHex(),
      'puzzle_hash': puzzlehash.toHex(),
      'amount': amount
  };
  
  @override
  bool operator ==(Object other) =>
      other is CoinPrototype &&
      other.runtimeType == runtimeType &&
      other.id == id;

  @override
  int get hashCode => id.hashCode;
}

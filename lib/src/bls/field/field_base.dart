import 'dart:typed_data';

import 'package:chia_utils/src/bls/failed_op.dart';
import 'package:chia_utils/src/bls/field/field.dart';
import 'package:chia_utils/src/clvm/bytes.dart';
import 'package:hex/hex.dart';
import 'package:quiver/core.dart';

class Fq implements Field {
  @override
  BigInt Q;

  @override
  int extension = 1;

  BigInt value;

  Fq(this.Q, BigInt value) : value = value % Q;
  Fq.nil()
      : Q = BigInt.zero,
        value = BigInt.zero;

  @override
  Fq myFromBytes(List<int> bytes, BigInt Q) {
    assert(bytes.length == 48, 'There must be 48 bytes');
    return Fq(Q, bytesToBigInt(bytes, Endian.big));
  }

  @override
  Fq myFromHex(String hex, BigInt Q) =>
      myFromBytes(const HexDecoder().convert(hex), Q);

  factory Fq.zero(BigInt Q) => Fq(Q, BigInt.zero);

  factory Fq.one(BigInt Q) => Fq(Q, BigInt.one);

  factory Fq.fromFq(BigInt Q, Fq fq) => fq;

  factory Fq.fromBytes(List<int> bytes, BigInt Q) =>
      Fq.nil().myFromBytes(bytes, Q);

  factory Fq.fromHex(String hex, BigInt Q) => Fq.nil().myFromHex(hex, Q);

  @override
  Field operator +(other) {
    try {
      return add(other);
    } on FailedOp {
      return other.add(this);
    }
  }

  @override
  Field operator *(other) {
    try {
      return multiply(other);
    } on FailedOp {
      return other.multiply(this);
    }
  }

  @override
  Fq operator -() => Fq(Q, -value);

  @override
  Field operator -(other) =>
      other is Fq ? Fq(Q, value - other.value) : this + -other;

  @override
  bool operator ==(Object other) => equal(other);

  @override
  int get hashCode => hash2(value, Q);

  @override
  bool operator <(Fq other) => value < other.value;

  @override
  bool operator >(Fq other) => value > other.value;

  bool operator <=(Fq other) => value <= other.value;

  bool operator >=(Fq other) => value >= other.value;

  @override
  Fq add(other) {
    if (other is! Fq) {
      throw FailedOp();
    }
    return Fq(Q, value + other.value);
  }

  @override
  Fq multiply(other) {
    if (other is! Fq) {
      throw FailedOp();
    }
    return Fq(Q, value * other.value);
  }

  @override
  bool equal(other) => other is Fq && value == other.value && Q == other.Q;

  @override
  String toString() {
    final hex = value.toRadixString(16);
    return 'Fq(0x${hex.length > 10 ? '${hex.substring(0, 5)}..${hex.substring(hex.length - 5, hex.length)}' : hex})';
  }

  @override
  Uint8List toBytes() => bigIntToBytes(value, 48, Endian.big);

  @override
  String toHex() => const HexEncoder().convert(toBytes());

  @override
  Fq pow(BigInt other) => other == BigInt.zero
      ? Fq(Q, BigInt.one)
      : other == BigInt.one
          ? Fq(Q, value)
          : other % BigInt.two == BigInt.zero
              ? Fq(Q, value * value).pow(other ~/ BigInt.two)
              : Fq(Q, value * value).pow(other ~/ BigInt.two) * this as Fq;
  @override
  Fq qiPower(int i) => this;

  @override
  Fq operator ~() {
    var x0 = BigInt.one, x1 = BigInt.zero, y0 = BigInt.zero, y1 = BigInt.one;
    var a = Q;
    var b = value;
    while (a != BigInt.zero) {
      final q = b ~/ a;
      final tempB = b;
      b = a;
      a = tempB % a;
      final tempX0 = x0;
      x0 = x1;
      x1 = tempX0 - q * x1;
      final tempY0 = y0;
      y0 = y1;
      y1 = tempY0 - q * y1;
    }
    return Fq(Q, x0);
  }

  @override
  Field operator ~/(other) {
    if (other is Fq) {
      return this * ~other;
    } else if (other is BigInt) {
      return this * ~Fq(Q, other);
    }
    throw ArgumentError('Can only divide by Fq or int objects.');
  }

  @override
  Field operator /(other) => this ~/ other;

  Fq modSqrt() {
    if (value == BigInt.zero) {
      return Fq(Q, BigInt.zero);
    } else if (value.modPow((Q - BigInt.one) ~/ BigInt.two, Q) != BigInt.one) {
      throw ArgumentError('No sqrt exists.');
    } else if (Q.remainder(BigInt.from(4)) == BigInt.from(3)) {
      return Fq(Q, value.modPow((Q + BigInt.one) ~/ BigInt.from(4), Q));
    } else if (Q.remainder(BigInt.from(8)) == BigInt.from(5)) {
      return Fq(Q, value.modPow((Q + BigInt.from(3)) ~/ BigInt.from(8), Q));
    }
    var S = BigInt.zero;
    var q = Q - BigInt.one;
    while (q.remainder(BigInt.two) == BigInt.zero) {
      q ~/= BigInt.two;
      S += BigInt.one;
    }
    var z = BigInt.zero;
    for (var i = BigInt.zero; i < Q; i += BigInt.one) {
      final euler = i.modPow((Q - BigInt.one) ~/ BigInt.two, Q);
      if (euler == BigInt.from(-1) % Q) {
        z = i;
        break;
      }
    }
    var M = S;
    var c = z.modPow(q, Q);
    var t = value.modPow(q, Q);
    var R = value.modPow((q + BigInt.one) ~/ BigInt.two, Q);
    while (true) {
      if (t == BigInt.zero) {
        return Fq(Q, BigInt.zero);
      } else if (t == BigInt.one) {
        return Fq(Q, R);
      }
      var i = BigInt.zero;
      var f = t;
      while (f != BigInt.one) {
        f = f.pow(2) % Q;
        i += BigInt.one;
      }
      final b = c.modPow(BigInt.two.modPow(M - i - BigInt.one, Q), Q);
      M = i;
      c = b.pow(2) % Q;
      t = (t * c) % Q;
      R = (R * b) % Q;
    }
  }

  @override
  Fq clone() => Fq(Q, value);

  @override
  Fq myZero(BigInt Q) => Fq(Q, BigInt.zero);

  @override
  Fq myOne(BigInt Q) => Fq(Q, BigInt.one);

  @override
  Fq myFromFq(BigInt Q, Fq fq) => fq;

  @override
  bool toBool() => true;
}

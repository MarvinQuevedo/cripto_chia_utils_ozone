import '../../../chia_crypto_utils.dart';

class Bytes100 extends Bytes {
  static const bytesLength = 100;
  static const hexLength = 200;
  Bytes100(List<int> bytesList) : super(bytesList) {
    if (bytesList.length != bytesLength) {
      throw ArgumentError('Bytes100 must have 100 bytes');
    }
  }
}

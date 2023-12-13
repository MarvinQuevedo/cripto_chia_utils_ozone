import 'package:bech32m/bech32m.dart';
import 'package:chia_crypto_utils/src/clvm/bytes.dart';
import 'package:meta/meta.dart';

const DID_HRP = 'did:chia';

@immutable
class DidAddress {
  const DidAddress(this.address);

  DidAddress.fromPuzzlehash(
    Puzzlehash puzzlehash,
  ) : address = segwit.encode(Segwit(DID_HRP, puzzlehash));

  final String address;

  Puzzlehash toPuzzlehash() {
    return Puzzlehash(segwit.decode(address).program);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ address.hashCode;

  @override
  bool operator ==(Object other) {
    return other is DidAddress && other.address == address;
  }

  @override
  String toString() => 'Address($address)';
}

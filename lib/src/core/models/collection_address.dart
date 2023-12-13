import 'package:bech32m/bech32m.dart';
import 'package:chia_crypto_utils/src/clvm/bytes.dart';
import 'package:chia_crypto_utils/src/utils.dart';
import 'package:meta/meta.dart';

const COL_HRP = 'col';

@immutable
class CollectionAddress {
  const CollectionAddress(this.address);

  CollectionAddress.fromPuzzlehash(
    Puzzlehash puzzlehash,
  ) : address = segwit.encode(Segwit(COL_HRP, puzzlehash));

  final String address;

  Puzzlehash toPuzzlehash() {
    return Puzzlehash(segwit.decode(address).program);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ address.hashCode;

  @override
  bool operator ==(Object other) {
    return other is CollectionAddress && other.address == address;
  }

  @override
  String toString() => 'Address($address)';
}

CollectionAddress calcSpaceScanCollection({required Bytes didId, required String collectionId}) {
  final concatData = didId.toHex().toBytes() + collectionId.toBytes();
  final hash = concatData.sha256Hash();
  return CollectionAddress.fromPuzzlehash(Puzzlehash(hash));
}

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:equatable/equatable.dart';

class SignatureHashes {
  late final List<MessageSignTuple> signatureHashes;

  SignatureHashes({
    List<MessageSignTuple> signatureHashes = const [],
  }) {
    this.signatureHashes = List<MessageSignTuple>.from(signatureHashes.toList());
  }

  factory SignatureHashes.fromMap(Map<String, dynamic> map) {
    final list = map['list'] as List;
    final signatureHashes = list
        .map(
          (e) => MessageSignTuple.fromJson(e),
        )
        .toList();
    return SignatureHashes(signatureHashes: signatureHashes);
  }

  List<String> get hashes => signatureHashes.map((e) => e.message.toHex()).toList();

  Map<String, dynamic> toMap() {
    return {
      'list': signatureHashes.map((e) => e.toJson()).toList(),
    };
  }

  void aggreate(SignatureHashes? other) {
    if (other == null) {
      return;
    }
    signatureHashes.addAll(other.signatureHashes);
  }

  void addSignatureHashes({
    required Bytes messageHash,
    required Bytes publicKey,
    required Puzzlehash puzzlehash,
  }) {
    final item = MessageSignTuple(
      message: messageHash,
      pk: publicKey,
      puzzlehash: puzzlehash,
    );
    signatureHashes.add(item);
  }

  void addSignatureHashTuple(MessageSignTuple data) {
    signatureHashes.add(data);
  }

  SpendBundle aggregateSignatures(
    Map<Bytes, Bytes> messagesWithSignatures,
    SpendBundle spendBundle,
  ) {
    List<JacobianPoint> signatures = [];
    for (final item in signatureHashes) {
      final signature = messagesWithSignatures[item.message];
      if (signature == null) {
        throw Exception('Signature not found');
      }
      final signaturePoint = JacobianPoint.fromBytesG2(signature);
      signatures.add(signaturePoint);
    }
    final aggregate = AugSchemeMPL.aggregate(signatures);
    return SpendBundle(
      coinSpends: spendBundle.coinSpends,
      aggregatedSignature: aggregate,
    );
  }

  Map<Bytes, List<Bytes>> getSignatureHashGroupedByPk() {
    final grouped = <Bytes, List<Bytes>>{};
    for (final item in signatureHashes) {
      final messageHash = item.message;
      final publicKey = item.pk;
      if (grouped[publicKey] == null) {
        grouped[publicKey] = [];
      }
      grouped[publicKey]!.add(messageHash);
    }
    return grouped;
  }
}

class MessageSignTuple extends Equatable {
  final Bytes message;
  final Bytes pk;
  final Puzzlehash puzzlehash;

  MessageSignTuple({
    required this.message,
    required this.pk,
    required this.puzzlehash,
  });

  @override
  List<Object?> get props => [message, pk];
  Map<String, String> toJson() {
    return {
      'message': message.toHex(),
      'pk': pk.toHex(),
      'ph': puzzlehash.toHex(),
    };
  }

  factory MessageSignTuple.fromJson(Map<String, dynamic> json) {
    return MessageSignTuple(
      message: Bytes.fromHex(json['message']),
      pk: Bytes.fromHex(json['pk']),
      puzzlehash: Puzzlehash.fromHex(json['ph']),
    );
  }
}

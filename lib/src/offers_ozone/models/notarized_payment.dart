import 'package:chia_crypto_utils/chia_crypto_utils.dart';

final ZERO_32 = Bytes(List.generate(32, (_) => 0));

class NotarizedPayment extends Payment {
  NotarizedPayment(
    super.amount,
    super.puzzlehash, {
    List<Bytes>? super.memos,
    Bytes? nonce,
  }) {
    this.nonce = nonce ?? ZERO_32;
  }

  factory NotarizedPayment.fromConditionAndNonce(
      {required Program condition, required Bytes nonce,}) {
    final withOpcode = Program.list([Program.fromInt(51), condition]);
    final p = Payment.fromCondition(withOpcode);
    //final args = p.toProgram();
    return NotarizedPayment(p.amount, p.puzzlehash, memos: p.memos, nonce: nonce);
  }
  late final Bytes nonce;

  NotarizedPayment copyWith({
    int? amount,
    Puzzlehash? puzzlehash,
    Bytes? nonce,
    List<Bytes>? memos,
  }) {
    return NotarizedPayment(
      amount ?? this.amount,
      puzzlehash ?? this.puzzlehash,
      nonce: nonce ?? this.nonce,
      memos: memos ?? this.memos,
    );
  }
}

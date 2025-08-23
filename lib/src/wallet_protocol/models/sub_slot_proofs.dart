import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/wallet_protocol/models/header_block.dart';

class SubSlotProofs with Streamable {
  final VDFProof challengeChainSlotProof;
  final VDFProof? infusedChallengeChainSlotProof;
  final VDFProof rewardChainSlotProof;

  SubSlotProofs({
    required this.challengeChainSlotProof,
    this.infusedChallengeChainSlotProof,
    required this.rewardChainSlotProof,
  });

  @override
  Map<String, dynamic> toJson() => {
        'challengeChainSlotProof': challengeChainSlotProof.toJson(),
        'infusedChallengeChainSlotProof': infusedChallengeChainSlotProof?.toJson(),
        'rewardChainSlotProof': rewardChainSlotProof.toJson(),
      };

  @override
  Bytes toStreamBytes() {
    final writer = StreamWriter();
    writer.writeStreamable(challengeChainSlotProof);
    writer.writeOptional(infusedChallengeChainSlotProof, (value) => writer.writeStreamable(value));
    writer.writeStreamable(rewardChainSlotProof);
    return writer.toBytes();
  }

  factory SubSlotProofs.fromStreamBytes(Bytes bytes) {
    final reader = StreamReader(bytes);
    return SubSlotProofs(
      challengeChainSlotProof: reader.readStreamable(VDFProof.fromStreamReader),
      infusedChallengeChainSlotProof: reader.readOptionalStreamable(VDFProof.fromStreamReader),
      rewardChainSlotProof: reader.readStreamable(VDFProof.fromStreamReader),
    );
  }
}

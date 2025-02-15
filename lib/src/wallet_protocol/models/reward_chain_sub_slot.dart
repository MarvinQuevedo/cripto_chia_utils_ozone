import '../../../chia_crypto_utils.dart';
import 'index.dart';

class RewardChainSubSlot with Streamable {
  final VDFInfo endOfSlotVdf;
  final Bytes32 challengeChainSubSlotHash;
  final Bytes32? infusedChallengeChainSubSlotHash;
  final int deficit; // 16 or less, usually zero

  RewardChainSubSlot({
    required this.endOfSlotVdf,
    required this.challengeChainSubSlotHash,
    this.infusedChallengeChainSubSlotHash,
    required this.deficit,
  });

  @override
  Map<String, dynamic> toJson() => {
        'endOfSlotVdf': endOfSlotVdf.toJson(),
        'challengeChainSubSlotHash': challengeChainSubSlotHash.toHex(),
        'infusedChallengeChainSubSlotHash': infusedChallengeChainSubSlotHash?.toHex(),
        'deficit': deficit,
      };

  @override
  Bytes toStreamBytes() {
    final writer = StreamWriter();
    writer.writeStreamable(endOfSlotVdf);
    writer.writeBytes32(challengeChainSubSlotHash);
    writer.writeOptional(infusedChallengeChainSubSlotHash, (value) => writer.writeBytes32(value));
    writer.writeUint8(deficit);
    return writer.toBytes();
  }

  factory RewardChainSubSlot.fromStreamBytes(Bytes bytes) {
    final reader = StreamReader(bytes);
    return RewardChainSubSlot(
      endOfSlotVdf: reader.readStreamable(VDFInfo.fromStreamReader),
      challengeChainSubSlotHash: reader.readBytes32(),
      infusedChallengeChainSubSlotHash: reader.readOptional(reader.readBytes32),
      deficit: reader.readUint8(),
    );
  }
}

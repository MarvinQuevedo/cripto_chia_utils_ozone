import '../../../../chia_crypto_utils.dart';

class Announcement extends AssertCoinAnnouncementCondition {
  final Bytes message;
  Announcement(Bytes coinId, this.message, {Bytes? morphBytes})
      : super(
          coinId,
          message,
          morphBytes: morphBytes,
        );
}

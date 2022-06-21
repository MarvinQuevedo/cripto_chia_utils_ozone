import '../../../../chia_crypto_utils.dart';

class Announcement extends AssertCoinAnnouncementCondition {
  Announcement(Bytes coinId, Bytes message, {Bytes? morphBytes})
      : super(
          coinId,
          message,
          morphBytes: morphBytes,
        );

  Bytes get originInfo => this.coinId;
}

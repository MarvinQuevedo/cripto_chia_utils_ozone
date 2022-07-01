import '../../../../chia_crypto_utils.dart';

class Announcement extends AssertPuzzleAnnouncementCondition {
  final Bytes message;
  Announcement(Bytes coinId, this.message, {Bytes? morphBytes})
      : super(
          coinId,
        );

  Bytes get originInfo => this.announcementHash;
}

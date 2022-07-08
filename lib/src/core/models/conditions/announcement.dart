import '../../../../chia_crypto_utils.dart';

class Announcement extends AssertPuzzleAnnouncementCondition {
  Announcement(
    Bytes settlementPh,
    Bytes message,
  ) : super((settlementPh + message).sha256Hash());
}

import '../../../../chia_crypto_utils.dart';
import '../../../standard/exceptions/invalid_condition_cast_exception.dart';

class Announcement extends AssertPuzzleAnnouncementCondition {
  Announcement(
    Bytes settlementPh,
    Bytes message,
  ) : super((settlementPh + message).sha256Hash());
}

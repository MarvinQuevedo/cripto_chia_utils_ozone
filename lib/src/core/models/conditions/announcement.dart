import '../../../../chia_crypto_utils.dart';

class Announcement extends AssertPuzzleCondition {
  Announcement(
    Bytes settlementPh,
    Bytes message,
  ) : super((settlementPh + message).sha256Hash());
}

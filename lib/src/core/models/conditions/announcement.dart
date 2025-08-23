import '../../../../chia_crypto_utils.dart';

class Announcement extends AssertPuzzleCondition {
  final Bytes settlementPh;
  final Bytes message;
  Announcement(
    this.settlementPh,
    this.message,
  ) : super((settlementPh + message).sha256Hash());

  Program toAnnouncementList() {
    return Program.list([
      Program.fromBytes(
        settlementPh,
      ),
      Program.fromBytes(
        message,
      ),
    ]);
  }

  factory Announcement.fromProgramList(Program program) {
    final list = program.toList();
    return Announcement(
      list[0].atom,
      list[1].atom,
    );
  }
}

import 'package:chia_crypto_utils/src/tangem/standart_wallet.dart';

import '../clvm/bytes.dart';
import '../clvm/program.dart';
import '../core/index.dart';
import '../nft1.0/index.dart';
import '../standard/index.dart';

class TangemNftWallet extends NftWallet {
  final _standardWalletService = TangemStandardWalletService();

  @override
  StandardWalletService get standardWalletService => _standardWalletService;

  @override
  Program makeSolutionFromConditions(List<Condition> conditions) {
    return BaseWalletService.makeSolutionFromConditionsP2Delegate(conditions);
  }

  @override
  Program makeSolution({
    required List<Payment> primaries,
    List<AssertCoinAnnouncementCondition> coinAnnouncementsToAssert = const [],
    List<AssertPuzzleCondition> puzzleAnnouncementsToAssert = const [],
    Set<Bytes> coinAnnouncements = const {},
    Set<Bytes> puzzleAnnouncements = const {},
  }) {
    return BaseWalletService.makeSolution(
      primaries: primaries,
      coinAnnouncementsToAssert: coinAnnouncementsToAssert,
      puzzleAnnouncementsToAssert: puzzleAnnouncementsToAssert,
      coinAnnouncements: coinAnnouncements,
      puzzleAnnouncements: puzzleAnnouncements,
      makeSolutionFromConditions: BaseWalletService.makeSolutionFromConditionsP2Delegate,
    );
  }
}

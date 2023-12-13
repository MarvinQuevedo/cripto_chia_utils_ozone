import '../../clvm/bytes.dart';
import '../index.dart';

class AnalizedOffer {
  /// List of payments that are requested for you
  final Map<OfferAssetData?, List<int>> requested;

  /// List of payments that are offered to you
  final Map<OfferAssetData?, int> offered;

  /// Amounts for apply royalties
  final Map<Bytes?, int> fungibleAmounts;

  /// If true, this offer use the old trade program
  final bool isOld;
  final int? royaltyPer;
  final Map<Bytes?, int?>? royaltyAmounts;

  AnalizedOffer(
      {required this.requested,
      required this.offered,
      required this.isOld,
      required this.royaltyPer,
      required this.royaltyAmounts,
      required this.fungibleAmounts});
}

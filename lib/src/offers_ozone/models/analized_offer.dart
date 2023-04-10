import '../index.dart';

class AnalizedOffer {
  /// List of payments that are requested for you
  final Map<OfferAssetData?, List<int>> requested;

  /// List of payments that are offered to you
  final Map<OfferAssetData?, int> offered;

  /// If true, this offer use the old trade program
  final bool isOld;

  AnalizedOffer({
    required this.requested,
    required this.offered,
    required this.isOld,
  });
}

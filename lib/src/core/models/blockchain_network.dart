class BlockchainNetwork {
  BlockchainNetwork({
    required this.name,
    required this.addressPrefix, required this.aggSigMeExtraData, this.unit,
    this.ticker,
    this.precision,
    this.fee,
    this.networkConfig,
  });
  String name;
  String? unit;
  // TODO(nvjoshi2): logo https://pub.dev/packages/image
  String? ticker;
  String addressPrefix;
  String aggSigMeExtraData;
  int? precision;
  int? fee;
  dynamic networkConfig;
}

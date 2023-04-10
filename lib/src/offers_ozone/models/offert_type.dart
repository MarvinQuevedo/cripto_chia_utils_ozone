enum OfferType {
  cat("CAT"),
  singleton("singleton"),
  ownership("ownership"),
  metadata("metadata"),
  ToyaltyTransferProgram("royalty transfer program");

  final String value;
  const OfferType(this.value);
}

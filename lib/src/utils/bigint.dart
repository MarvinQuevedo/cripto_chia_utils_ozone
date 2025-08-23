BigInt bigIntMin(BigInt a, BigInt b) {
  if (a > b) return b;
  return a;
}

BigInt bigIntMax(BigInt a, BigInt b) {
  if (a > b) return a;
  return b;
}

enum ProtocolMessageTypes {
  // Shared protocol (all services)
  handshake(1),

  // Harvester protocol (harvester <-> farmer)
  harvesterHandshake(3),
  newProofOfSpace(5),
  requestSignatures(6),
  respondSignatures(7),

  // Farmer protocol (farmer <-> fullNode)
  newSignagePoint(8),
  declareProofOfSpace(9),
  requestSignedValues(10),
  signedValues(11),
  farmingInfo(12),

  // Timelord protocol (timelord <-> fullNode)
  newPeakTimelord(13),
  newUnfinishedBlockTimelord(14),
  newInfusionPointVdf(15),
  newSignagePointVdf(16),
  newEndOfSubSlotVdf(17),
  requestCompactProofOfTime(18),
  respondCompactProofOfTime(19),

  // Full node protocol (fullNode <-> fullNode)
  newPeak(20),
  newTransaction(21),
  requestTransaction(22),
  respondTransaction(23),
  requestProofOfWeight(24),
  respondProofOfWeight(25),
  requestBlock(26),
  respondBlock(27),
  rejectBlock(28),
  requestBlocks(29),
  respondBlocks(30),
  rejectBlocks(31),
  newUnfinishedBlock(32),
  requestUnfinishedBlock(33),
  respondUnfinishedBlock(34),
  newSignagePointOrEndOfSubSlot(35),
  requestSignagePointOrEndOfSubSlot(36),
  respondSignagePoint(37),
  respondEndOfSubSlot(38),
  requestMempoolTransactions(39),
  requestCompactVdf(40),
  respondCompactVdf(41),
  newCompactVdf(42),
  requestPeers(43),
  respondPeers(44),
  noneResponse(91),

  // Wallet protocol (wallet <-> fullNode)
  requestPuzzleSolution(45),
  respondPuzzleSolution(46),
  rejectPuzzleSolution(47),
  sendTransaction(48),
  transactionAck(49),
  newPeakWallet(50),
  requestBlockHeader(51),
  respondBlockHeader(52),
  rejectHeaderRequest(53),
  requestRemovals(54),
  respondRemovals(55),
  rejectRemovalsRequest(56),
  requestAdditions(57),
  respondAdditions(58),
  rejectAdditionsRequest(59),
  requestHeaderBlocks(60),
  rejectHeaderBlocks(61),
  respondHeaderBlocks(62),

  // Introducer protocol (introducer <-> fullNode)
  requestPeersIntroducer(63),
  respondPeersIntroducer(64),

  // Simulator protocol
  farmNewBlock(65),

  // New harvester protocol
  newSignagePointHarvester(66),
  requestPlots(67),
  respondPlots(68),
  plotSyncStart(78),
  plotSyncLoaded(79),
  plotSyncRemoved(80),
  plotSyncInvalid(81),
  plotSyncKeysMissing(82),
  plotSyncDuplicates(83),
  plotSyncDone(84),
  plotSyncResponse(85),

  // More wallet protocol
  coinStateUpdate(69),
  registerForPhUpdates(70),
  respondToPhUpdates(71),
  registerForCoinUpdates(72),
  respondToCoinUpdates(73),
  requestChildren(74),
  respondChildren(75),
  requestSesInfo(76),
  respondSesInfo(77),
  requestBlockHeaders(86),
  rejectBlockHeaders(87),
  respondBlockHeaders(88),
  requestFeeEstimates(89),
  respondFeeEstimates(90),

  // Unfinished block protocol
  newUnfinishedBlock2(92),
  requestUnfinishedBlock2(93),

  // New wallet sync protocol
  requestRemovePuzzleSubscriptions(94),
  respondRemovePuzzleSubscriptions(95),
  requestRemoveCoinSubscriptions(96),
  respondRemoveCoinSubscriptions(97),
  requestPuzzleState(98),
  respondPuzzleState(99),
  rejectPuzzleState(100),
  requestCoinState(101),
  respondCoinState(102),
  rejectCoinState(103),

  // Wallet protocol mempool updates
  mempoolItemsAdded(104),
  mempoolItemsRemoved(105),
  requestCostInfo(106),
  respondCostInfo(107),

  error(255);

  final int value;
  const ProtocolMessageTypes(this.value);
}

ProtocolMessageTypes protocolMessageTypesFromInt(int value) {
  return ProtocolMessageTypes.values.firstWhere((e) => e.value == value);
}

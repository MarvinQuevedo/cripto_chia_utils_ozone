// ignore_for_file: lines_longer_than_80_chars

import 'dart:async';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class SimulatorFullNodeInterface extends ChiaFullNodeInterface {
  SimulatorFullNodeInterface(this.fullNode) : super(fullNode);

  @override
  // ignore: overridden_fields
  final SimulatorHttpRpc fullNode;

  // address used only to move to next block
  static const utilAddress =
      Address('xch1ye5dzd44kkatnxx2je4s2agpwtqds5lsm5mlyef7plum5danxalq2dnqap');

  Future<void> moveToNextBlock([int blocks = 1]) async {
    for (var i = 0; i < blocks; i++) {
      await fullNode.farmTransactionBlock(utilAddress);
    }
  }

  Future<void> farmCoins(Address address) async {
    await fullNode.farmTransactionBlock(address);
  }

  Timer? blockCreationTimer;

  void run({Duration blockPeriod = const Duration(seconds: 19)}) {
    stop();
    blockCreationTimer = Timer.periodic(blockPeriod, (timer) {
      fullNode.farmTransactionBlock(utilAddress);
    });
  }

  void stop() {
    blockCreationTimer?.cancel();
  }

  // finds any coins that were spent to initialize an exchange by creating a 3 mojo coin to the message puzzlehash
  // with the required memos
  Future<List<Coin>> scroungeForExchangeInitializationCoins(
    List<Puzzlehash> puzzlehashes,
  ) async {
    final allCoins = await getCoinsByPuzzleHashes(puzzlehashes, includeSpentCoins: true);

    final initializationCoins = <Coin>[];
    for (final coin in allCoins) {
      if (coin.isNotSpent) continue;

      final coinSpend = await getCoinSpend(coin);

      final paymentsAndAdditions = await coinSpend!.paymentsAndAdditionsAsync;

      // if there is no 3 mojo child, which is used to cancel the offer, this is not a valid initialization coin
      if (paymentsAndAdditions.additions.where((addition) => addition.amount == 3).isEmpty) {
        continue;
      }

      final memos = paymentsAndAdditions.payments.memos;

      // memo should look like: <derivationIndex, serializedOfferFile>
      if (memos.length != 2) continue;

      try {
        final derivationIndexMemo = decodeInt(memos.first);
        if (derivationIndexMemo.toString().length != ExchangeOfferService.derivationIndexLength) {
          continue;
        }

        final serializedOfferFileMemo = memos.last.decodedString;
        final offerFile =
            await CrossChainOfferFile.fromSerializedOfferFileAsync(serializedOfferFileMemo!);
        if (offerFile.prefix != CrossChainOfferFilePrefix.ccoffer) continue;
      } catch (e) {
        continue;
      }

      initializationCoins.add(coin);
    }
    return initializationCoins;
  }

  Future<DateTime?> getCurrentBlockDateTime() async {
    final currentHeight = await getCurrentBlockIndex();

    if (currentHeight == null) return null;

    final currentDateTime = getDateTimeFromBlockIndex(currentHeight);

    return currentDateTime;
  }

  Future<List<NotificationCoin>> scroungeForSentNotificationCoins(
    List<Puzzlehash> puzzlehashes,
  ) async {
    final allCoins = await getCoinsByPuzzleHashes(puzzlehashes, includeSpentCoins: true);

    final spentCoins = allCoins.where((c) => c.isSpent);
    final notificationCoins = <NotificationCoin>[];
    for (final spentCoin in spentCoins) {
      final parentCoinSpend = await getCoinSpend(spentCoin);
      final additions = await parentCoinSpend!.additionsAsync;

      for (final addition in additions) {
        final childCoin = await getCoinById(addition.id);
        if (childCoin!.isSpent) {
          final coinSpend = await getCoinSpend(childCoin);
          final programAndArgs = await coinSpend!.puzzleReveal.uncurry();
          if (programAndArgs.program == notificationProgram) {
            try {
              final notificationCoin = await NotificationCoin.fromParentSpend(
                parentCoinSpend: parentCoinSpend,
                coin: childCoin,
              );
              notificationCoins.add(notificationCoin);
            } catch (e) {
              continue;
            }
          }
        }
      }
    }
    return notificationCoins;
  }

  Future<List<Coin>> getCoinsByHint(Puzzlehash hint, {bool includeSpentCoins = false}) async {
    final coinRecordsResponse = await fullNode.getCoinsByHint(
      hint,
      includeSpentCoins: includeSpentCoins,
    );
    mapResponseToError(coinRecordsResponse);

    return coinRecordsResponse.coinRecords.map((record) => record.toCoin()).toList();
  }

  static void mapResponseToError(
    ChiaBaseResponse baseResponse, {
    List<String> passStrings = const [],
  }) {
    if (baseResponse.success && baseResponse.error == null) {
      return;
    }
    final errorMessage = baseResponse.error!;

    // no error on resource not found
    if (errorMessage.contains('not found') || passStrings.any(errorMessage.contains)) {
      return;
    }

    if (errorMessage.contains('DOUBLE_SPEND')) {
      throw DoubleSpendException();
    }

    if (errorMessage.contains('bad bytes32 initializer')) {
      throw BadCoinIdException();
    }

    if (errorMessage.contains('ASSERT_ANNOUNCE_CONSUMED_FAILED')) {
      throw AssertAnnouncementConsumeFailedException();
    }

    throw BadRequestException(message: errorMessage);
  }

  Future<DateTime?> getDateTimeFromBlockIndex(int spentBlockIndex) async {
    try {
      final blockRecordByHeight = await fullNode.getBlockRecordByHeight(spentBlockIndex);
      return blockRecordByHeight.blockRecord?.dateTime;
    } catch (e) {
      return null;
    }
  }
}

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import '../../core/models/outer_puzzle.dart' as outerPuzzle;

import '../../core/models/conditions/announcement.dart';
import '../puzzles/settlement_payments/settlement_payments.clvm.hex.dart';
import 'notarized_payment.dart';
import 'puzzle_info.dart';

class Offert {
  /// The key is the asset id of the asset being requested, if is null then request XCH
  final Map<Bytes?, List<NotarizedPayment>> requestedPayments;
  final SpendBundle spendBundle;

  ///  asset_id -> asset driver
  final Map<Bytes, PuzzleInfo> driverDict;

  Offert({
    required this.requestedPayments,
    required this.spendBundle,
    required this.driverDict,
  });

  Bytes get ph => offertProgram.hash();

  /// calc the coins hash [nonce]
  Map<Bytes?, List<NotarizedPayment>> notarizePayments({
    required Map<Bytes?, List<NotarizedPayment>>
        requestedPayments, //`Null` means you are requesting XCH
    required List<Coin> coins,
  }) {
    // This sort should be reproducible in CLVM with `>s`

    final sortedCoins = coins.toList()..sort((a, b) => a.id.compareTo(b.id));
    final sortedCoinList = sortedCoins.toList().map((e) => e.toProgram()).toList();
    final nonce = Program.list(sortedCoinList).hash();

    final result = Map<Bytes?, List<NotarizedPayment>>();
    requestedPayments.forEach((assetId, payments) {
      result[assetId] = [];
      payments.forEach((payment) {
        result[assetId]!.add(
          payment.copyWith(
            nonce: nonce,
          ),
        );
      });
    });
    return result;
  }

  List<Announcement> calculateAnnouncements({
    required Map<Bytes?, List<NotarizedPayment>> notarizedPayment,
    required Map<Bytes, PuzzleInfo> driverDict,
  }) {
    final result = <Announcement>[];
    notarizedPayment.forEach((assetId, payments) {
      Bytes? settlementPh;
      if (assetId != null) {
        if (!driverDict.containsKey(assetId)) {
          throw Exception(
              "Cannot calculate announcements without driver of requested item $assetId");
        }
        settlementPh = outerPuzzle
            .constructPuzzle(
              constructor: driverDict[assetId]!,
              innerPuzzle: offertProgram,
            )
            .hash();
      } else {
        settlementPh = offertProgram.hash();
      }

      Bytes msg = Program.list([
        Program.fromBytes(payments[0].nonce),
        Program.list(payments.map((e) => e.toProgram()).toList()),
      ]).hash();

      result.add(Announcement(settlementPh, msg));
    });
    return result;
  }

  Map<Bytes?, List<CoinPrototype>> getOfferedCoins() {
    final offeredCoins = <Bytes?, List<CoinPrototype>>{};
    final additions = spendBundle.additions;

    for (var addition in additions) {
      final parentPuzzle = spendBundle.coinSpends
          .where((element) => element.coin.id == addition.id)
          .first
          .puzzleReveal;
      Bytes? assetId;
      late Puzzlehash offertPh;

      final puzzleDriver = outerPuzzle.matchPuzzle(parentPuzzle);
      if (puzzleDriver != null) {
        assetId = outerPuzzle.createAssetId(puzzleDriver);
        offertPh = outerPuzzle
            .constructPuzzle(
              constructor: puzzleDriver,
              innerPuzzle: offertProgram,
            )
            .hash();
      } else {
        assetId = null;
        offertPh = offertProgram.hash();
      }
      if (addition.puzzlehash == offertPh) {
        offeredCoins[assetId] ??= [];
        offeredCoins[assetId]!.add(addition);
      }
    }

    return offeredCoins;
  }

  Map<Bytes?, int> getOfferedAmounts() {
    final offeredAmounts = <Bytes?, int>{};
    final coins = getOfferedCoins();
    coins.forEach((assetId, coins) {
      offeredAmounts[assetId] = coins.fold(0, (a, b) => a + b.amount);
    });
    return offeredAmounts;
  }

  /*  Map<Bytes?, List<NotarizedPayment>> getRequestedPayments() {
    return requestedPayments;
  } */

  Map<Bytes?, int> getRequestedAmounts() {
    final offeredAmounts = <Bytes?, int>{};
    final coins = requestedPayments;
    coins.forEach((assetId, coins) {
      offeredAmounts[assetId] = coins.fold(0, (a, b) => a + b.amount);
    });
    return offeredAmounts;
  }

  Map<Bytes?, int> arbitrage() {
    final arbitrageDict = <Bytes?, int>{};
    final offered_amounts = getOfferedAmounts();
    final requested_amounts = getRequestedAmounts();
    final keys = [...offered_amounts.keys, ...requested_amounts.keys].toSet().toList();
    for (var tailId in keys) {
      arbitrageDict[tailId] = (offered_amounts[tailId] ?? 0) - (requested_amounts[tailId] ?? 0);
    }
    return arbitrageDict;
  }

  List<Map<String, dynamic>> summary() {
    final offered_amounts = getOfferedAmounts();
    final requested_amounts = getRequestedAmounts();

    final driverDictR = <Bytes, Map<String, dynamic>>{};
    driverDict.forEach((key, value) {
      driverDictR[key] = value.info;
    });

    return [
      _keysToStrings(offered_amounts),
      _keysToStrings(requested_amounts),
      _keysToStrings(driverDictR)
    ];
  }
}

Map<String, dynamic> _keysToStrings(Map<Bytes?, dynamic> dic) {
  final result = <String, dynamic>{};
  dic.forEach((key, value) {
    if (key == null) {
      result["XCH"] = value;
    } else {
      result[key.toHex()] = value;
    }
  });
  return result;
}

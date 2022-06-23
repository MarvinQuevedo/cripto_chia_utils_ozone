import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/utils/check_set_overlay.dart';
import '../../core/models/outer_puzzle.dart' as outerPuzzle;

import '../../core/models/conditions/announcement.dart';
import '../exceptions/coin_not_in_bundle.dart';
import '../puzzles/settlement_payments/settlement_payments.clvm.hex.dart';
import 'notarized_payment.dart';
import 'puzzle_info.dart';

class Offert {
  /// The key is the asset id of the asset being requested, if is null then request XCH
  final Map<Bytes?, List<NotarizedPayment>> requestedPayments;
  final SpendBundle bundle;

  ///  asset_id -> asset driver
  final Map<Bytes, PuzzleInfo> driverDict;

  Offert({
    required this.requestedPayments,
    required this.bundle,
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
    final additions = bundle.additions;

    for (var addition in additions) {
      final parentPuzzle =
          bundle.coinSpends.where((element) => element.coin.id == addition.id).first.puzzleReveal;
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

  /// Also mostly for the UI, returns a dictionary of assets and how much of them is pended for this offer
  /// This method is also imperfect for sufficiently complex spends
  Map<String, int> getPendingAmounts() {
    final allAdittions = bundle.additions;
    final allRemovals = bundle.removals;
    final notEphomeralRemovals = allRemovals
        .where(
          (coin) => !allAdittions.contains(coin),
        )
        .toList();
    Map<String, int> pendingDict = {};
    // First we add up the amounts of all coins that share an ancestor with the offered coins (i.e. a primary coin)
    final offerred = getOfferedCoins();
    offerred.forEach((assetId, coins) {
      final name = assetId == null ? "xch" : assetId.toHex();
      pendingDict[name] = 0;
      for (var coin in coins) {
        final rootRemoval = getRootRemoval(coin);
        final pocessableAdditions =
            allAdittions.where((element) => element.parentCoinInfo == rootRemoval.id).toList();
        pocessableAdditions.forEach((addition) {
          final lastAmount = pendingDict[name]!;
          pendingDict[name] = lastAmount + addition.amount;
        });
      }
    });

    // Then we gather anything else as unknown
    final sumOfadditionssoFar =
        pendingDict.values.fold<int>(0, (previousValue, element) => previousValue + element);

    final nonEphimeralsSum = notEphomeralRemovals
        .map((e) => e.amount)
        .fold<int>(0, (previousValue, element) => previousValue + element);

    final unknownAmount = nonEphimeralsSum - sumOfadditionssoFar;
    if (unknownAmount > 0) {
      pendingDict["unknown"] = unknownAmount;
    }
    return pendingDict;
  }

  List<CoinPrototype> getInvolvedCoins() {
    final additions = bundle.additions;
    return bundle.removals.where((coin) => !additions.contains(coin)).toList();
  }

  /// This returns the non-ephemeral removal that is an ancestor of the specified coins
  /// This should maybe move to the SpendBundle object at some point
  CoinPrototype getRootRemoval(CoinPrototype coin) {
    final allRemovals = bundle.removals.toSet();
    final allRemovalsIds = allRemovals.map((e) => e.id).toList().toSet();
    final nonEphemeralRemovals = allRemovals
        .where((element) => !allRemovalsIds.contains(
              element.parentCoinInfo,
            ))
        .toSet();
    if (!allRemovalsIds.contains(coin.id) && !allRemovalsIds.contains(coin.parentCoinInfo)) {
      throw CoinNotInBundle(coin.id);
    }

    while (!nonEphemeralRemovals.contains(coin)) {
      final removalsIter =
          allRemovals.where((element) => element.id == coin.parentCoinInfo).iterator;
      removalsIter.moveNext();
      coin = removalsIter.current;
    }
    return coin;
  }

  /// This will only return coins that are ancestors of settlement payments
  List<CoinPrototype> getPrimaryCoins() {
    final pCoins = Set<CoinPrototype>();
    final offerredCoins = getOfferedCoins();
    offerredCoins.forEach((_, coins) {
      coins.forEach((coin) {
        final rootRemoval = getRootRemoval(coin);
        if (!pCoins.contains(rootRemoval)) {
          pCoins.add(rootRemoval);
        }
      });
    });
    return pCoins.toList();
  }

  static aggreate(List<Offert> offerts) {
    final totalRequestedPayments = <Bytes?, List<NotarizedPayment>>{};
    SpendBundle totalBundle = SpendBundle.empty;
    final totalDriverDict = <Bytes, PuzzleInfo>{};
    for (var offert in offerts) {
      final totalInputs = totalBundle.coinSpends.map((e) => e.coin).toSet();
      final offerInputs = offert.bundle.coinSpends.map((e) => e.coin).toSet();
      if (totalInputs.checkOverlay(offerInputs)) {
        throw Exception("The aggregated offers overlap inputs $offert");
      }

      // Next,  do the aggregation
      final requestedPayments = offert.requestedPayments;
      requestedPayments.forEach((Bytes? assetId, List<NotarizedPayment> payments) {
        if (totalRequestedPayments[assetId] != null) {
          totalRequestedPayments[assetId]!.addAll(payments);
        } else {
          totalRequestedPayments[assetId] = payments.toList();
        }
      });
      offert.driverDict.forEach((Bytes? key, PuzzleInfo value) {
        if (totalDriverDict.containsKey(key) && totalDriverDict[key] != value) {
          throw Exception("The offers to aggregate disagree on the drivers for ${key?.toHex()}");
        }
      });

      totalBundle = totalBundle + offert.bundle;
      offert.driverDict.forEach((offerKey, offerValue) {
        totalDriverDict.update(offerKey, (value) => offerValue);
      });
    }
    return Offert(
        requestedPayments: totalRequestedPayments,
        bundle: totalBundle,
        driverDict: totalDriverDict);
  }

  /// Validity is defined by having enough funds within the offer to satisfy both sidess
  bool isValid() {
    final arbitrageValues = arbitrage().values;
    return arbitrageValues
            .where(
              (element) => (element >= 0),
            )
            .length ==
        arbitrageValues.length;
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

import 'package:bech32m/bech32m.dart';
import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/offer/models/solver.dart';
import 'package:chia_crypto_utils/src/offer/utils/puzzle_compression.dart';
import 'package:chia_crypto_utils/src/utils/check_set_overlay.dart';
import 'package:quiver/iterables.dart';
import '../../core/models/outer_puzzle.dart' as outerPuzzle;

import '../../core/models/conditions/announcement.dart';
import '../../utils/from_bench32.dart';
import '../exceptions/coin_not_in_bundle.dart';
import '../puzzles/settlement_payments/settlement_payments.clvm.hex.dart';
import '../utils/clean_dulicates_values.dart';
import 'notarized_payment.dart';
import 'puzzle_info.dart';

class Offer {
  /// The key is the asset id of the asset being requested, if is null then request XCH
  final Map<Bytes?, List<NotarizedPayment>> requestedPayments;
  final SpendBundle bundle;

  ///  asset_id -> asset driver
  final Map<Bytes, PuzzleInfo> driverDict;

  Offer({
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

    final OFFER_HASH = offertProgram.hash();
    for (var parentSpend in bundle.coinSpends) {
      final coinForThisSpend = <CoinPrototype>[];
      final parentPuzzle = parentSpend.puzzleReveal;
      final parentSolution = parentSpend.solution;
      final additions =
          bundle.additions.where((element) => !bundle.removals.contains(element)).toList();
      final puzzleDriver = outerPuzzle.matchPuzzle(parentPuzzle);

      Bytes? assetId;

      if (puzzleDriver != null) {
        assetId = outerPuzzle.createAssetId(puzzleDriver);
        final innerPuzzle = outerPuzzle.getInnerPuzzle(
          constructor: puzzleDriver,
          puzzleReveal: parentPuzzle,
        );
        final innerSolution = outerPuzzle.getInnerSolution(
          constructor: puzzleDriver,
          solution: parentSolution,
        );
        //assert(innerSolution != null && innerPuzzle != null);
        final conditionResult = innerPuzzle.run(innerSolution);
        final conditionResultIter = conditionResult.program.toList();
        for (var condition in conditionResultIter) {
          try {
            if (condition.first().toInt() == 51 && condition.rest().first().atom == OFFER_HASH) {
              final additionsWAmount = additions
                  .where((element) => element.amount == condition.rest().rest().first().toInt())
                  .toList();
              if (additionsWAmount.length == 1) {
                coinForThisSpend.add(additionsWAmount.first);
              } else {
                final additionsWAmountAndPuzzlehashes = additionsWAmount.where((element) =>
                    element.puzzlehash ==
                    outerPuzzle
                        .constructPuzzle(
                          constructor: puzzleDriver,
                          innerPuzzle: offertProgram,
                        )
                        .hash());

                if (additionsWAmountAndPuzzlehashes.length == 1) {
                  coinForThisSpend.add(additionsWAmountAndPuzzlehashes.first);
                }
              }
            }
          } catch (_) {}
        }
      } else {
        assetId = null;
        coinForThisSpend
            .addAll(additions.where((element) => element.puzzlehash == OFFER_HASH).toList());
      }
      if (coinForThisSpend.isNotEmpty) {
        offeredCoins[assetId] ??= [];
        offeredCoins[assetId]!.addAll(coinForThisSpend);
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

  static aggreate(List<Offer> offerts) {
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
    return Offer(
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

  CoinSpend _getSpendSpendOfCoin(CoinPrototype coin) {
    return bundle.coinSpends.where((element) => element.coin.id == coin.id).first;
  }

  ///  A "valid" spend means that this bundle can be pushed to the network and will succeed
  /// This differs from the `to_spend_bundle` method which deliberately creates an invalid SpendBundle
  SpendBundle toValidSpend({Bytes? arbitragePh}) {
    Offer offert = this;
    if (!isValid()) {
      throw Exception("Offer is currently incomplete");
    }
    final completionSpends = <CoinSpend>[];
    final allOfferredCoins = offert.getOfferedCoins();
    final allArbitragePh = offert.arbitrage();
    offert.requestedPayments.forEach((Bytes? assetId, List<NotarizedPayment> payments) {
      final List<CoinPrototype> offerredCoins = allOfferredCoins[assetId]!;

      // Because of CAT supply laws, we must specify a place for the leftovers to go
      final int? arbitrageAmount = allArbitragePh[assetId];
      final allPayments = payments.toList();
      if ((arbitrageAmount ?? 0) > 0) {
        assert(arbitrageAmount == null,
            "Amount can't be null when arbitrage Amount is more than 0, ${arbitrageAmount}");
        assert(
          arbitragePh == null,
          "ArbitragePH can't be null when arbitrage Amount is more than 0, ${arbitrageAmount}",
        );
        allPayments.add(NotarizedPayment(arbitrageAmount!, Puzzlehash(arbitragePh!)));
      }

      // Some assets need to know about siblings so we need to collect all spends first to be able to use them
      final coinToSpendDict = <CoinPrototype, CoinSpend>{};
      final coinToSolutionDict = <CoinPrototype, Program>{};
      for (var coin in offerredCoins) {
        final parentSpend = _getSpendSpendOfCoin(coin);
        coinToSpendDict[coin] = parentSpend;
        final List<Program> innerSolutions = [];
        if (coin == offerredCoins.first) {
          final nonces = allPayments.map((e) => e.nonce).toList();

          final noncesValues = cleanDuplicatesValues(nonces);
          for (var nonce in noncesValues) {
            final noncePayments = allPayments.where((p) => p.nonce == nonce).toList();

            innerSolutions.add(Program.list(<Program>[
              Program.fromBytes(nonce),
              Program.list(
                noncePayments
                    .map(
                      (e) => e.toProgram(),
                    )
                    .toList(),
              )
            ]));
          }
        }
        coinToSolutionDict[coin] = Program.list(innerSolutions);
      }

      for (var coin in offerredCoins) {
        Program? solution;

        if (assetId != null) {
          String siblings = "(";
          String siblingsSpends = "(";
          String silblingsPuzzles = "(";
          String silblingsSolutions = "(";
          String disassembledOfferMod = offertProgram.toSource();
          for (var siblingCoin in offerredCoins) {
            if (siblingCoin != coin) {
              siblings += siblingCoin.toBytes().toHexWithPrefix();
              siblingsSpends += "0x" + coinToSpendDict[siblingCoin]!.toHex() + ")";
              silblingsPuzzles += disassembledOfferMod;
              silblingsSolutions += coinToSolutionDict[siblingCoin]!.toSource();
            }
          }
          siblings += ")";
          siblingsSpends += ")";
          silblingsPuzzles += ")";
          silblingsSolutions += ")";

          final solver = Solver({
            "coin": coin.toBytes().toHexWithPrefix(),
            "parent_spend": coinToSolutionDict[coin]!.toHexWithPrefix(),
            "siblings": siblings,
            "sibling_spends": siblingsSpends,
            "sibling_puzzles": silblingsPuzzles,
            "sibling_solutions": silblingsSolutions,
          });

          solution = outerPuzzle.solvePuzzle(
            constructor: offert.driverDict[assetId]!,
            solver: solver,
            innerPuzzle: offertProgram,
            innerSolution: coinToSolutionDict[coin]!,
          );
        } else {
          solution = coinToSolutionDict[coin]!;
        }
        final puzzleReveal = (assetId != null)
            ? outerPuzzle.constructPuzzle(
                constructor: offert.driverDict[assetId]!,
                innerPuzzle: offertProgram,
              )
            : offertProgram;
        completionSpends.add(CoinSpend(
          coin: coin,
          puzzleReveal: puzzleReveal,
          solution: solution,
        ));
      }
    });

    return SpendBundle(coinSpends: completionSpends) + offert.bundle;
  }

  /// Before we serialze this as a SpendBundle, we need to serialze the `requested_payments` as dummy CoinSpends
  SpendBundle toSpendBundle() {
    final aditionalCoinSpends = <CoinSpend>[];
    requestedPayments.forEach((assetId, payments) {
      final puzzleReveal = outerPuzzle.constructPuzzle(
        constructor: driverDict[assetId]!,
        innerPuzzle: offertProgram,
      );

      List innerSolutions = [];
      final nonces = cleanDuplicatesValues(payments.map((e) => e.nonce).toList());
      nonces.forEach((nonce) {
        final noncePayments = payments.where((element) => element.nonce == nonce).toList();
        innerSolutions.add(Program.list(<Program>[
          Program.fromBytes(nonce),
          Program.list(
            noncePayments
                .map(
                  (e) => e.toProgram(),
                )
                .toList(),
          )
        ]));
      });
    });

    return SpendBundle(coinSpends: aditionalCoinSpends) + this.bundle;
  }

  static Offer fromSpendBundle(SpendBundle bundle) {
    final requestedPayments = <Bytes?, List<NotarizedPayment>>{};
    final driverDict = <Bytes, PuzzleInfo>{};
    final leftoverCoinSpends = <CoinSpend>[];
    for (var coinSpend in bundle.coinSpends) {
      final driver = outerPuzzle.matchPuzzle(coinSpend.puzzleReveal);
      Bytes? assetId;
      if (driver != null) {
        assetId = outerPuzzle.createAssetId(driver);

        driverDict[assetId] = driver;
      }

      if (coinSpend.coin.parentCoinInfo == ZERO_32) {
        final notarizedPayments = <NotarizedPayment>[];
        for (var paymentGroup in coinSpend.solution.toList()) {
          final nonce = paymentGroup.first().atom;
          final paymentArgsList = paymentGroup.rest().toList();

          notarizedPayments.addAll(paymentArgsList.map((condition) {
            return NotarizedPayment.fromConditionAndNonce(condition: condition, nonce: nonce);
          }).toList());
        }
        if (requestedPayments[assetId] == null) {
          requestedPayments[assetId] = [];
        }
        requestedPayments[assetId]!.addAll(notarizedPayments);
      } else {
        leftoverCoinSpends.add(coinSpend);
      }
    }

    return Offer(
        requestedPayments: requestedPayments,
        bundle: SpendBundle(
          coinSpends: leftoverCoinSpends,
          aggregatedSignature: bundle.aggregatedSignature,
        ),
        driverDict: driverDict);
  }

  Bytes compress({int? version}) {
    final asSpendBundle = toSpendBundle();
    if (version == null) {
      final mods =
          asSpendBundle.coinSpends.map((e) => e.puzzleReveal.uncurry().program.toBytes()).toList();
      version = max([lowestBestVersion(mods), 2])!;
    }
    return compressObjectWithPuzzles(asSpendBundle.toBytes(), version);
  }

  Bytes get id => toBytes().sha256Hash();

  Bytes toBytes() {
    return toSpendBundle().toBytes();
  }

  String toBench32({String prefix = "offert", int? compressionVersion}) {
    final offertBytes = compress(version: compressionVersion);
    final encoded = segwit.encode(Segwit(prefix, offertBytes));
    return encoded;
  }

  static Offer fromBench32(String offerBech32) {
    final bytes = Bytes(OfferSegwitDecoder().convert(offerBech32).program);

    return try_offer_decompression(bytes);
  }

  static Offer try_offer_decompression(Bytes dataBytes) {
    // try {
    return Offer.fromCompressed(dataBytes);
    /*  } catch (e) {
      print(e);
      return Offer.fromBytes(dataBytes);
    } */
  }

  static Offer fromCompressed(Bytes compressedBytes) {
    return Offer.fromBytes(decompressObjectWithPuzzles(compressedBytes));
  }

  static Offer fromBytes(Bytes objectBytes) {
    return Offer.fromSpendBundle(SpendBundle.fromBytes(objectBytes));
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

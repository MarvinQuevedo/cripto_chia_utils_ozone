import 'package:bech32m/bech32m.dart';
import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/utils/check_set_overlay.dart';
import 'package:quiver/iterables.dart';
import '../../core/models/outer_puzzle.dart' as outerPuzzle;

import '../../core/models/conditions/announcement.dart';
import '../../utils/from_bench32.dart';

final OFFERS_HASHES = {OFFER_MOD_HASH, OFFER_MOD_V1_HASH};

class Offer {
  /// The key is the asset id of the asset being requested, if is null then request XCH
  final Map<Bytes?, List<NotarizedPayment>> requestedPayments;
  final SpendBundle bundle;

  ///  asset_id -> asset driver
  final Map<Bytes?, PuzzleInfo> driverDict;

  Offer({
    required this.requestedPayments,
    required this.bundle,
    required this.driverDict,
  });

  static Puzzlehash get ph => OFFER_MOD_HASH;

  /// calc the coins hash [nonce]
  static Map<Bytes?, List<NotarizedPayment>> notarizePayments({
    required Map<Bytes?, List<Payment>> requestedPayments, //`Null` means you are requesting XCH
    required List<CoinPrototype> coins,
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
          NotarizedPayment(
            payment.amount,
            payment.puzzlehash,
            memos: payment.memos,
            nonce: nonce,
          ),
        );
      });
    });
    return result;
  }

  static List<Announcement> calculateAnnouncements({
    required Map<Bytes?, List<NotarizedPayment>> notarizedPayment,
    required Map<Bytes?, PuzzleInfo> driverDict,
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
              innerPuzzle: OFFER_MOD,
            )
            .hash();
      } else {
        settlementPh = OFFER_MOD_HASH;
      }
      final msgProgram = Program.list([
        Program.fromBytes(payments.first.nonce),
      ]..addAll(payments.map((e) => e.toProgram()).toList()));

      Bytes msg = msgProgram.hash();

      result.add(Announcement(settlementPh, msg));
    });
    return result;
  }

  Map<Bytes?, List<CoinPrototype>> getOfferedCoins() {
    final offeredCoins = <Bytes?, List<CoinPrototype>>{};

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
        assert(innerSolution != null && innerPuzzle != null);

        final conditionResult = innerPuzzle!.run(innerSolution!);
        final conditionResultIter = conditionResult.program.toList();
        for (var condition in conditionResultIter) {
          try {
            if (condition.first().toInt() == 51 &&
                OFFERS_HASHES.contains(condition.rest().first().atom)) {
              final additionsWAmount = additions
                  .where((element) => element.amount == condition.rest().rest().first().toInt())
                  .toList();
              if (additionsWAmount.length == 1) {
                coinForThisSpend.add(additionsWAmount.first);
              } else {
                final additionsWAmountAndPuzzlehashes = additionsWAmount.where((element) => [
                      outerPuzzle
                          .constructPuzzle(
                            constructor: puzzleDriver,
                            innerPuzzle: OFFER_MOD,
                          )
                          .hash(),
                      outerPuzzle
                          .constructPuzzle(
                            constructor: puzzleDriver,
                            innerPuzzle: OFFER_MOD_V1,
                          )
                          .hash()
                    ].contains(element.puzzlehash));

                if (additionsWAmountAndPuzzlehashes.length == 1) {
                  coinForThisSpend.add(additionsWAmountAndPuzzlehashes.first);
                }
              }
            }
          } catch (_) {}
        }
      } else {
        assetId = null;
        coinForThisSpend.addAll(
            additions.where((element) => OFFERS_HASHES.contains(element.puzzlehash)).toList());
      }
      if (coinForThisSpend.isNotEmpty) {
        offeredCoins[assetId] ??= [];
        offeredCoins[assetId]!.addAll(coinForThisSpend);
        offeredCoins[assetId] = offeredCoins[assetId]!.toSet().toList();
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

    final driverDictR = <Bytes?, Map<String, dynamic>>{};
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

  static Offer aggreate(List<Offer> offers) {
    final totalRequestedPayments = <Bytes?, List<NotarizedPayment>>{};
    SpendBundle totalBundle = SpendBundle.empty;
    final totalDriverDict = <Bytes?, PuzzleInfo>{};
    for (var offer in offers) {
      final totalInputs = totalBundle.coinSpends.map((e) => e.coin).toSet().toList();
      final offerInputs = offer.bundle.coinSpends.map((e) => e.coin).toSet().toList();
      if (totalInputs.checkOverlay(offerInputs)) {
        throw Exception("The aggregated offers overlap inputs $offer");
      }

      // Next,  do the aggregation
      final requestedPayments = offer.requestedPayments;
      requestedPayments.forEach((Bytes? assetId, List<NotarizedPayment> payments) {
        if (totalRequestedPayments[assetId] != null) {
          totalRequestedPayments[assetId]!.addAll(payments);
        } else {
          totalRequestedPayments[assetId] = payments.toList();
        }
      });
      offer.driverDict.forEach((Bytes? key, PuzzleInfo value) {
        if (totalDriverDict.containsKey(key) && totalDriverDict[key] != value) {
          throw Exception(
              "The offers to aggregate disagree on the drivers for ${key?.toHex()} ${totalDriverDict[key]} != ${totalDriverDict[key]}");
        }
      });

      totalBundle = totalBundle + offer.bundle;
      offer.driverDict.forEach((offerKey, offerValue) {
        totalDriverDict.update(offerKey, (value) => offerValue, ifAbsent: () => offerValue);
      });
    }
    return Offer(
        requestedPayments: totalRequestedPayments,
        bundle: totalBundle,
        driverDict: totalDriverDict);
  }

  /// Validity is defined by having enough funds within the offer to satisfy both sidess
  bool isValid() {
    final _arbitrage = arbitrage();
    final arbitrageValues = _arbitrage.values.toList();
    final satisfaceds = arbitrageValues
        .where(
          (element) => (element >= 0),
        )
        .length;
    final valid = satisfaceds == arbitrageValues.length;

    return valid;
  }

  CoinSpend _getSpendSpendOfCoin(CoinPrototype coin) {
    return bundle.coinSpends.where((element) => element.coin.id == coin.parentCoinInfo).first;
  }

  ///  A "valid" spend means that this bundle can be pushed to the network and will succeed
  /// This differs from the `to_spend_bundle` method which deliberately creates an invalid SpendBundle
  SpendBundle toValidSpend({Bytes? arbitragePh}) {
    Offer offer = this;
    if (!isValid()) {
      throw Exception("Offer is currently incomplete");
    }
    final completionSpends = <CoinSpend>[];
    final allOfferredCoins = offer.getOfferedCoins();
    final allArbitragePh = offer.arbitrage();
    offer.requestedPayments.forEach((Bytes? assetId, List<NotarizedPayment> payments) {
      final List<CoinPrototype> offerredCoins = allOfferredCoins[assetId]!;

      // Because of CAT supply laws, we must specify a place for the leftovers to go
      final int? arbitrageAmount = allArbitragePh[assetId];
      final allPayments = payments.toList();
      if (arbitrageAmount == null) {
        throw Exception(
            "Amount can't be null when arbitrage Amount is more than 0, ${arbitrageAmount}");
      }

      if (arbitrageAmount > 0) {
        if (arbitragePh == null) {
          throw Exception(
            "ArbitragePH can't be null when arbitrage Amount is more than 0, ${arbitrageAmount}",
          );
        }

        allPayments.add(NotarizedPayment(
          arbitrageAmount,
          Puzzlehash(arbitragePh),
        ));
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
            ]..addAll(
                noncePayments
                    .map(
                      (e) => e.toProgram(),
                    )
                    .toList(),
              )));
          }
        }
        coinToSolutionDict[coin] = Program.list(innerSolutions);
      }

      for (var coin in offerredCoins) {
        Program? solution;
        Program offerMod = OFFER_MOD;
        if (assetId != null) {
          if (outerPuzzle
                  .constructPuzzle(
                    constructor: offer.driverDict[assetId]!,
                    innerPuzzle: OFFER_MOD_V1,
                  )
                  .hash() ==
              coin.puzzlehash) {
            print("Using OFFER V1 ${OFFER_MOD_V1.hash().toHex()}");
            offerMod = OFFER_MOD_V1;
          }
          String siblings = "(";
          String siblingsSpends = "(";
          String silblingsPuzzles = "(";
          String silblingsSolutions = "(";
          String disassembledOfferMod = offerMod.toSource();
          for (var siblingCoin in offerredCoins) {
            if (siblingCoin != coin) {
              siblings += siblingCoin.toBytes().toHexWithPrefix();
              silblingsPuzzles += disassembledOfferMod;
              silblingsSolutions += coinToSolutionDict[siblingCoin]!.serialize().toHexWithPrefix();
            }
          }
          siblings += ")";
          siblingsSpends += ")";
          silblingsPuzzles += ")";
          silblingsSolutions += ")";
          /*    print("parent spend =  " +
              coinToSpendDict[coin]!.toProgramList().serialize().toHexWithPrefix()); */

          final solver = Solver({
            "coin": coin.toBytes().toHexWithPrefix(),
            "parent_spend": coinToSpendDict[coin]!.toProgram().serialize().toHexWithPrefix(),
            "siblings": siblings,
            "sibling_spends": siblingsSpends,
            "sibling_puzzles": silblingsPuzzles,
            "sibling_solutions": silblingsSolutions,
          });

          solution = outerPuzzle.solvePuzzle(
            constructor: offer.driverDict[assetId]!,
            solver: solver,
            innerPuzzle: offerMod,
            innerSolution: coinToSolutionDict[coin]!,
          );
        } else {
          if (coin.puzzlehash == OFFER_MOD_V1) {
            offerMod = OFFER_MOD_V1;
            print("2 Using OFFER V1 ${OFFER_MOD_V1.hash().toHex()}");
          }
          solution = coinToSolutionDict[coin]!;
        }
        final puzzleReveal = (assetId != null)
            ? outerPuzzle.constructPuzzle(
                constructor: offer.driverDict[assetId]!,
                innerPuzzle: offerMod,
              )
            : offerMod;
        final coinSpend = CoinSpend(
          coin: coin,
          puzzleReveal: puzzleReveal,
          solution: solution,
        );
        completionSpends.add(coinSpend);
      }
    });
    final completionSpendBundle = SpendBundle(coinSpends: completionSpends);

    return completionSpendBundle + offer.bundle;
  }

  /// Before we serialze this as a SpendBundle, we need to serialze the `requested_payments` as dummy CoinSpends
  SpendBundle toSpendBundle() {
    final aditionalCoinSpends = <CoinSpend>[];
    requestedPayments.forEach((assetId, payments) {
      final puzzleReveal = (assetId == null)
          ? OFFER_MOD
          : outerPuzzle.constructPuzzle(
              constructor: driverDict[assetId]!,
              innerPuzzle: OFFER_MOD,
            );

      List<Program> innerSolutions = [];
      final nonces = cleanDuplicatesValues(payments.map((e) => e.nonce).toList());
      nonces.forEach((nonce) {
        final noncePayments = payments.where((element) => element.nonce == nonce).toList();
        innerSolutions.add(Program.list(<Program>[
          Program.fromBytes(nonce),
        ]..addAll(noncePayments
            .map(
              (e) => e.toProgram(),
            )
            .toList())));
      });
      aditionalCoinSpends.add(CoinSpend(
          coin: CoinPrototype(
            parentCoinInfo: ZERO_32,
            puzzlehash: puzzleReveal.hash(),
            amount: 0,
          ),
          puzzleReveal: puzzleReveal,
          solution: Program.list(innerSolutions)));
    });

    return SpendBundle(coinSpends: aditionalCoinSpends) + this.bundle;
  }

  static Offer fromSpendBundle(SpendBundle bundle) {
    final requestedPayments = <Bytes?, List<NotarizedPayment>>{};
    final driverDict = <Bytes?, PuzzleInfo>{};
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
      version = max([lowestBestVersion(mods), 5])!;
    }

    return compressObjectWithPuzzles(asSpendBundle.toBytes(), version);
  }

  Bytes get id => toBytes().sha256Hash();

  Bytes toBytes() {
    return toSpendBundle().toBytes();
  }

  String toBench32({String prefix = "offer", int? compressionVersion}) {
    final offerBytes = compress(version: compressionVersion);

    final encoded = OfferSegwitEncoder().convert(Segwit(prefix, offerBytes));
    return encoded;
  }

  static Offer fromBench32(String offerBech32) {
    final bytes = Bytes(OfferSegwitDecoder().convert(offerBech32).program);

    return try_offer_decompression(bytes);
  }

  static Offer try_offer_decompression(Bytes dataBytes) {
    return Offer.fromCompressed(dataBytes);
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

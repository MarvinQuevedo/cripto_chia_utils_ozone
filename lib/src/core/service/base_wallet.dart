// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/clvm/keywords.dart';
import 'package:chia_crypto_utils/src/core/exceptions/change_puzzlehash_needed_exception.dart';
import 'package:chia_crypto_utils/src/core/models/contidions_args.dart';
import 'package:chia_crypto_utils/src/standard/exceptions/origin_id_not_in_coins_exception.dart';
import 'package:chia_crypto_utils/src/standard/exceptions/spend_bundle_validation/duplicate_coin_exception.dart';
import 'package:chia_crypto_utils/src/standard/exceptions/spend_bundle_validation/failed_signature_verification.dart';
import 'package:get_it/get_it.dart';
import 'package:tuple/tuple.dart';

class BaseWalletService {
  BlockchainNetwork get blockchainNetwork => GetIt.I.get<BlockchainNetwork>();

  SpendBundle createSpendBundleBase({
    required List<Payment> payments,
    required List<CoinPrototype> coinsInput,
    required Program Function(Puzzlehash puzzlehash) makePuzzleRevealFromPuzzlehash,
    required JacobianPoint Function(CoinSpend coinSpend) makeSignatureForCoinSpend,
    Puzzlehash? changePuzzlehash,
    int fee = 0,
    int surplus = 0,
    Bytes? originId,
    List<Bytes> coinIdsToAssert = const [],
    List<AssertCoinAnnouncementCondition> coinAnnouncementsToAssert = const [],
    List<AssertPuzzleAnnouncementCondition> puzzleAnnouncementsToAssert = const [],
    Program Function(Program standardSolution)? transformStandardSolution,
    void Function(Bytes message)? useCoinMessage,
  }) {
    Program makeSolutionFromConditions(List<Condition> conditions) {
      final standardSolution = BaseWalletService.makeSolutionFromConditions(conditions);
      if (transformStandardSolution == null) {
        return standardSolution;
      }
      return transformStandardSolution(standardSolution);
    }

    // copy coins input since coins list is modified in this function
    final coins = List<CoinPrototype>.from(coinsInput);
    final totalCoinValue = coins.fold(0, (int previousValue, coin) => previousValue + coin.amount);

    final totalPaymentAmount = payments.fold(
      0,
      (int previousValue, payment) => previousValue + payment.amount,
    );
    final change = totalCoinValue - totalPaymentAmount - fee - surplus;

    if (changePuzzlehash == null && change > 0) {
      throw ChangePuzzlehashNeededException();
    }

    final signatures = <JacobianPoint>[];
    final spends = <CoinSpend>[];

    // returns -1 if originId is given but is not in coins
    final originIndex = originId == null ? 0 : coins.indexWhere((coin) => coin.id == originId);

    if (originIndex == -1) {
      throw OriginIdNotInCoinsException();
    }

    // origin coin should be processed first so move it to the front of the list
    if (originIndex != 0) {
      final originCoin = coins.removeAt(originIndex);
      coins.insert(0, originCoin);
    }

    AssertCoinAnnouncementCondition? primaryAssertCoinAnnouncement;

    var first = true;
    for (var i = 0; i < coins.length; i++) {
      final coin = coins[i];

      Program? solution;
      // create output for origin coin
      if (first) {
        first = false;
        final conditions = <Condition>[];
        final createdCoins = <CoinPrototype>[];
        for (final payment in payments) {
          final sendCreateCoinCondition = payment.toCreateCoinCondition();
          conditions.add(sendCreateCoinCondition);
          createdCoins.add(
            CoinPrototype(
              parentCoinInfo: coin.id,
              puzzlehash: payment.puzzlehash,
              amount: payment.amount,
            ),
          );
        }

        if (change > 0) {
          conditions.add(CreateCoinCondition(changePuzzlehash!, change));
          createdCoins.add(
            CoinPrototype(
              parentCoinInfo: coin.id,
              puzzlehash: changePuzzlehash,
              amount: change,
            ),
          );
        }

        if (fee > 0) {
          conditions.add(ReserveFeeCondition(fee));
        }

        conditions
          ..addAll(coinAnnouncementsToAssert)
          ..addAll(puzzleAnnouncementsToAssert);

        // generate message for coin announcements by appending coin_ids
        // see https://github.com/Chia-Network/chia-blockchain/blob/4bd5c53f48cb049eff36c87c00d21b1f2dd26b27/chia/wallet/wallet.py#L383
        //   message: bytes32 = std_hash(b"".join(message_list))
        final existingCoinsMessage = coins.fold(
          Bytes.empty,
          (Bytes previousValue, coin) => previousValue + coin.id,
        );
        final createdCoinsMessage = createdCoins.fold(
          Bytes.empty,
          (Bytes previousValue, coin) => previousValue + coin.id,
        );
        final message = (existingCoinsMessage + createdCoinsMessage).sha256Hash();

        useCoinMessage?.call(message);
        conditions.add(CreateCoinAnnouncementCondition(message));

        for (final coinIdToAssert in coinIdsToAssert) {
          conditions.add(AssertCoinAnnouncementCondition(coinIdToAssert, message));
        }

        primaryAssertCoinAnnouncement = AssertCoinAnnouncementCondition(coin.id, message);

        solution = makeSolutionFromConditions(conditions);
      } else {
        solution = makeSolutionFromConditions(
          [primaryAssertCoinAnnouncement!],
        );
      }

      final puzzle = makePuzzleRevealFromPuzzlehash(coin.puzzlehash);
      final coinSpend = CoinSpend(coin: coin, puzzleReveal: puzzle, solution: solution);
      spends.add(coinSpend);

      final signature = makeSignatureForCoinSpend(coinSpend);
      signatures.add(signature);
    }

    final aggregate = AugSchemeMPL.aggregate(signatures);

    return SpendBundle(coinSpends: spends, aggregatedSignature: aggregate);
  }

  JacobianPoint makeSignature(
    PrivateKey privateKey,
    CoinSpend coinSpend, {
    bool useSyntheticOffset = true,
  }) {
    final result = coinSpend.puzzleReveal.run(coinSpend.solution);

    final addsigmessage = getAddSigMeMessageFromResult(result.program, coinSpend.coin);

    final privateKey0 = useSyntheticOffset ? calculateSyntheticPrivateKey(privateKey) : privateKey;
    final signature = AugSchemeMPL.sign(privateKey0, addsigmessage);

    return signature;
  }

  Bytes getAddSigMeMessageFromResult(Program result, CoinPrototype coin) {
    final aggSigMeCondition = result.toList().where(AggSigMeCondition.isThisCondition);
    // TODO(nvjoshi2): figure out more robust way to get correct AggSigMeCondition.
    // this works because tail AggSigMeConditions come before standard ones
    return Bytes(aggSigMeCondition.last.toList()[2].atom) +
        coin.id +
        Bytes.fromHex(
          blockchainNetwork.aggSigMeExtraData,
        );
  }

  Tuple3<Exception?, Map<ConditionOpcode, List<ConditionWithArgs>>?, BigInt>
      conditionsDictForSolution({
    required Program puzzleReveal,
    required Program solution,
    int maxCost = Program.cost,
  }) {
    final result =
        conditionsForSolution(puzzleReveal: puzzleReveal, solution: solution, maxCost: maxCost);
    if (result.item1 != null || result.item2 == null) {
      return Tuple3(result.item1, null, result.item3);
    }
    final dictResult = conditionsByOpcode(conditions: result.item2!);
    return Tuple3(null, dictResult, result.item3);
  }

  Map<ConditionOpcode, List<ConditionWithArgs>> conditionsByOpcode({
    required List<ConditionWithArgs> conditions,
  }) {
    final dict = <ConditionOpcode, List<ConditionWithArgs>>{};

    for (final condition in conditions) {
      if (dict[condition.conditionOpcode] == null) {
        dict[condition.conditionOpcode] = <ConditionWithArgs>[];
      }
      dict[condition.conditionOpcode]!.add(condition);
    }
    return dict;
  }

  Tuple3<Exception?, List<ConditionWithArgs>?, BigInt> conditionsForSolution({
    required Program puzzleReveal,
    required Program solution,
    int maxCost = Program.cost,
  }) {
    try {
      final result = puzzleReveal.run(solution);
      print(result.program.hash().toHex());
      final parsed = parseSexpToConditions(result.program);
      return Tuple3(parsed.item1, parsed.item2, result.cost);
    } on Exception catch (e, stackTrace) {
      print(stackTrace);
      print(solution);
      return Tuple3(e, null, BigInt.from(0));
    }
  }

  //parse_sexp_to_condition

  /// Takes a ChiaLisp sexp (list) and returns the list of ConditionWithArgss
  /// If it fails, returns as Error
  Tuple2<Exception?, ConditionWithArgs?> parseSexpToCondition(Program sexp) {
    try {
      print(sexp.toSource());
      final atoms = sexp.toList();
      if (atoms.isEmpty) {
        return Tuple2(Exception('INVALID_CONDITION'), null);
      }
      final opCode = ConditionOpcode(atoms.first.atom);
      return Tuple2(
          null,
          ConditionWithArgs(
            conditionOpcode: opCode,
            vars: atoms
                .sublist(1)
                .where((e) {
                  try {
                    final _ = e.atom;
                    return true;
                  } catch (e) {
                    return false;
                  }
                })
                .map((e) => e.atom)
                .toList(),
          ),);
    } catch (e, stackTrace) {
      print(stackTrace);
      print(e);
      print(sexp.toSource());
      return Tuple2(Exception('INVALID_CONDITION'), null);
    }
  }

  ///   Takes a ChiaLisp sexp (list) and returns the list of ConditionWithArgss
  /// If it fails, returns as Error
  Tuple2<Exception?, List<ConditionWithArgs>?> parseSexpToConditions(
    Program sexp,
  ) {
    final results = <ConditionWithArgs>[];
    try {
      //final sexpList = sexp.toList();
      for (final item in sexp.toList()) {
        final result = parseSexpToCondition(item);
        if (result.item1 != null) {
          return Tuple2(result.item1, null);
        }
        results.add(result.item2!);
      }
      return Tuple2(null, results);
    } on Exception catch (e) {
      return Tuple2(e, null);
    }
  }

  static Program makeSolutionFromConditions(List<Condition> conditions) {
    return makeSolutionFromProgram(
      Program.list([
        Program.fromBigInt(keywords['q']!),
        ...conditions.map((condition) => condition.toProgram())
      ]),
    );
  }

  static List<T> extractConditionsFromSolution<T>(
    Program solution,
    ConditionChecker<T> conditionChecker,
    ConditionFromProgramConstructor<T> conditionFromProgramConstructor,
  ) {
    final programList = solution.toList();
    if (programList.length < 2) {
      return [];
    }
    return extractConditionsFromResult(
      programList[1],
      conditionChecker,
      conditionFromProgramConstructor,
    );
  }

  static List<Payment> extractPaymentsFromSolution(Program solution) {
    return BaseWalletService.extractConditionsFromSolution(
      solution,
      CreateCoinCondition.isThisCondition,
      CreateCoinCondition.fromProgram,
    ).map((e) => e.toPayment()).toList();
  }

  static List<T> extractConditionsFromResult<T>(
    Program result,
    ConditionChecker<T> conditionChecker,
    ConditionFromProgramConstructor<T> conditionFromProgramConstructor,
  ) {
    return result
        .toList()
        .where(conditionChecker)
        .map((p) => conditionFromProgramConstructor(p))
        .toList();
  }

  static List<T> extractConditionsFromProgramList<T>(
    List<Program> result,
    ConditionChecker<T> conditionChecker,
    ConditionFromProgramConstructor<T> conditionFromProgramConstructor,
  ) {
    return result.where(conditionChecker).map((p) => conditionFromProgramConstructor(p)).toList();
  }

  static Program makeSolutionFromProgram(Program program) {
    return Program.list([
      Program.nil,
      program,
      Program.nil,
    ]);
  }

  void validateSpendBundleSignature(SpendBundle spendBundle) {
    final publicKeys = <JacobianPoint>[];
    final messages = <List<int>>[];
    for (final spend in spendBundle.coinSpends) {
      final outputConditions = spend.puzzleReveal.run(spend.solution).program.toList();

      // look for assert agg sig me condition
      final aggSigMeProgram = outputConditions.singleWhere(AggSigMeCondition.isThisCondition);

      final aggSigMeCondition = AggSigMeCondition.fromProgram(aggSigMeProgram);
      publicKeys.add(aggSigMeCondition.publicKey);
      messages.add(
        aggSigMeCondition.message +
            spend.coin.id +
            Bytes.fromHex(blockchainNetwork.aggSigMeExtraData),
      );
    }

    // validate signature
    if (!AugSchemeMPL.aggregateVerify(
      publicKeys,
      messages,
      spendBundle.aggregatedSignature!,
    )) {
      throw FailedSignatureVerificationException();
    }
  }

  static void checkForDuplicateCoins(List<CoinPrototype> coins) {
    final idSet = <String>{};
    for (final coin in coins) {
      final coinIdHex = coin.id.toHex();
      if (idSet.contains(coinIdHex)) {
        throw DuplicateCoinException(coinIdHex);
      } else {
        idSet.add(coinIdHex);
      }
    }
  }

  static Program makeSolution({
    required List<Payment> primaries,
    List<AssertCoinAnnouncementCondition> coinAnnouncementsToAssert = const [],
    List<AssertPuzzleCondition> puzzleAnnouncementsToAssert = const [],
    Set<Bytes> coinAnnouncements = const {},
    Set<Bytes> puzzleAnnouncements = const {},
  }) {
    final conditions = <Condition>[];
    if (primaries.isNotEmpty) {
      for (final payment in primaries) {
        final createCondition = payment.toCreateCoinCondition();
        conditions.add(createCondition);
      }
    }

    conditions
      ..addAll(coinAnnouncements.map(
        CreateCoinAnnouncementCondition.new,
      ),)
      ..addAll(coinAnnouncementsToAssert)
      ..addAll(puzzleAnnouncements.map(
        CreatePuzzleAnnouncementCondition.new,
      ),)
      ..addAll(puzzleAnnouncementsToAssert);

    return BaseWalletService.makeSolutionFromConditions(conditions);
  }
}

class CoinSpendAndSignature {
  const CoinSpendAndSignature(this.coinSpend, this.signature);

  final CoinSpend coinSpend;
  final JacobianPoint signature;
}

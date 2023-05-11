// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/did/puzzles/did_puzzles.dart' as didPuzzles;
import 'package:chia_crypto_utils/src/offers_ozone/models/full_coin.dart' as fullCoin;

class CoinSpend with ToBytesMixin {
  CoinSpend({
    required this.coin,
    required this.puzzleReveal,
    required this.solution,
  });

  factory CoinSpend.fromJson(Map<String, dynamic> json) {
    return CoinSpend(
      coin: CoinPrototype.fromJson(json['coin'] as Map<String, dynamic>),
      puzzleReveal: Program.deserializeHex(json['puzzle_reveal'] as String),
      solution: Program.deserializeHex(json['solution'] as String),
    );
  }
  factory CoinSpend.fromStream(Iterator<int> iterator) {
    final coin = CoinPrototype.fromStream(iterator);
    final puzzleReveal = Program.fromStream(iterator);
    final solution = Program.fromStream(iterator);
    return CoinSpend(
      coin: coin,
      puzzleReveal: puzzleReveal,
      solution: solution,
    );
  }

  factory CoinSpend.fromBytes(Bytes bytes) {
    final iterator = bytes.iterator;
    return CoinSpend.fromStream(iterator);
  }
  CoinPrototype coin;
  Program puzzleReveal;
  Program solution;

  Program get outputProgram => puzzleReveal.run(solution).program;

  Future<Program> get outputProgramAsync async {
    return puzzleReveal.runAsync(solution).then((value) => value.program);
  }

  List<CoinPrototype> get additions {
    final createCoinConditions = BaseWalletService.extractConditionsFromResult(
      outputProgram,
      CreateCoinCondition.isThisCondition,
      CreateCoinCondition.fromProgram,
    );

    return createCoinConditions
        .map(
          (ccc) => CoinPrototype(
            parentCoinInfo: coin.id,
            puzzlehash: ccc.destinationPuzzlehash,
            amount: ccc.amount,
          ),
        )
        .toList();
  }

  Future<List<CoinPrototype>> get additionsAsync async {
    final outputProgram = await outputProgramAsync;
    return _getAdditionsFromOutputProgram(outputProgram);
  }

  List<CoinPrototype> _getAdditionsFromOutputProgram(Program outputProgram) {
    final createCoinConditions = BaseWalletService.extractConditionsFromResult(
      outputProgram,
      CreateCoinCondition.isThisCondition,
      CreateCoinCondition.fromProgram,
    );

    return createCoinConditions
        .map(
          (ccc) => CoinPrototype(
            parentCoinInfo: coin.id,
            puzzlehash: ccc.destinationPuzzlehash,
            amount: ccc.amount,
          ),
        )
        .toList();
  }

  Puzzlehash? getTailHash() {
    return fullCoin.getTailHash(this);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'coin': coin.toJson(),
        'puzzle_reveal': puzzleReveal.serialize().toHexWithPrefix(),
        'solution': solution.serialize().toHexWithPrefix()
      };

  @override
  Bytes toBytes() {
    var coinBytes = coin.toBytes();
    if (coin is CatCoin) {
      coinBytes = (coin as CatCoin).toCoinPrototype().toBytes();
    }
    return coinBytes + Bytes(puzzleReveal.serialize()) + Bytes(solution.serialize());
  }

  Program toProgram() {
    var coinBytes = coin.toBytes();
    if (coin is CatCoin) {
      coinBytes = (coin as CatCoin).toCoinPrototype().toBytes();
    }
    return Program.list([
      Program.fromBytes(coinBytes),
      Program.fromBytes(puzzleReveal.serialize()),
      Program.fromBytes(solution.serialize()),
    ]);
  }

  static CoinSpend fromProgram(Program program) {
    final args = program.toList();
    final coin = CoinPrototype.fromBytes(args[0].atom);
    final puzzleReveal = Program.deserialize(args[1].atom);
    final solution = Program.deserialize(args[2].atom);
    return CoinSpend(coin: coin, puzzleReveal: puzzleReveal, solution: solution);
  }

  SpendType get type {
    final uncurried = puzzleReveal.uncurry();
    final uncurriedPuzzleSource = uncurried.program.toSource();
    if (uncurriedPuzzleSource == p2DelegatedPuzzleOrHiddenPuzzleProgram.toSource()) {
      return SpendType.standard;
    }
    if (uncurriedPuzzleSource == CAT_MOD.toSource()) {
      return SpendType.cat2;
    }
    if (uncurriedPuzzleSource == LEGACY_CAT_MOD.toSource()) {
      return SpendType.cat1;
    }
    if (uncurriedPuzzleSource == SINGLETON_TOP_LAYER_MOD_v1_1.toSource()) {
      final nftUncurried = UncurriedNFT.tryUncurry(puzzleReveal);
      if (nftUncurried != null) {
        return SpendType.nft;
      }

      final args = uncurried.arguments;

      final uncurriedDid = didPuzzles.uncurryInnerpuz(args[1]);
      if (uncurriedDid != null) {
        return SpendType.did;
      }
    }
    return SpendType.unknown;
    //throw UnimplementedError('Unimplemented spend type');
  }

  // TODO(nvjoshi2): make async the default
  List<Payment> get payments => _getPaymentsFromOutputProgram(outputProgram);

  Future<List<Payment>> get paymentsAsync async {
    return _getPaymentsFromOutputProgram(await outputProgramAsync);
  }

  List<Memo> get memosSync => payments.memos;

  Future<List<Memo>> get memos async {
    final payments = await paymentsAsync;
    return payments.memos;
  }

  Future<List<String>> get memoStrings async {
    final payments = await paymentsAsync;
    final memoStrings = payments.fold(
      <String>[],
      (List<String> previousValue, payment) => previousValue + payment.memoStrings,
    );
    return memoStrings;
  }

  List<Payment> _getPaymentsFromOutputProgram(Program outputProgram) {
    final createCoinConditions = BaseWalletService.extractConditionsFromResult(
      outputProgram,
      CreateCoinCondition.isThisCondition,
      CreateCoinCondition.fromProgram,
    );

    return createCoinConditions.map((e) => e.toPayment()).toList();
  }

  Future<PaymentsAndAdditions> get paymentsAndAdditionsAsync async {
    final outputProgram = await outputProgramAsync;
    final additions = _getAdditionsFromOutputProgram(outputProgram);
    final payments = _getPaymentsFromOutputProgram(outputProgram);
    return PaymentsAndAdditions(payments, additions);
  }

  @override
  String toString() => 'CoinSpend(coin: $coin, puzzleReveal: $puzzleReveal, solution: $solution)';
}

enum SpendType {
  unknown('unknown'),
  standard('xch'),
  cat1('cat1'),
  cat2('cat'),
  nft('nft'),
  did('did');

  const SpendType(this.value);
  final String value;
}

SpendType? spendTypeFromString(String? value) {
  if (value == null) {
    return null;
  }
  return SpendType.values.firstWhere((element) => element.value == value);
}

class PaymentsAndAdditions {
  PaymentsAndAdditions(this.payments, this.additions);
  final List<Payment> payments;
  final List<CoinPrototype> additions;
}

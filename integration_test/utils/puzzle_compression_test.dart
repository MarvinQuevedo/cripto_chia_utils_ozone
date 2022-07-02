import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/offers_ozone/puzzles/settlement_payments/settlement_payments.clvm.hex.dart';
import 'package:chia_crypto_utils/src/offers_ozone/utils/puzzle_compression.dart';
import 'package:test/test.dart';

Future<void> main() async {
  final keychainSecret = KeychainCoreSecret.generate();

  final walletsSetList = <WalletSet>[];
  for (var i = 0; i < 2; i++) {
    final set1 = WalletSet.fromPrivateKey(keychainSecret.masterPrivateKey, i);
    walletsSetList.add(set1);
  }

  final keychain = WalletKeychain.fromWalletSets(walletsSetList);

  final zDict = zDictForVersion(LATEST_VERSION);

  final ZERO_32 = Bytes(List.generate(32, (_) => 0));
  final ONE_32 = Bytes(List.generate(32, (_) => 17));
  final COIN = CoinPrototype(parentCoinInfo: ZERO_32, puzzlehash: Puzzlehash(ZERO_32), amount: 0);
  final SOLUTION = Program.list([]);

  void testStandardPuzzle() {
    final coinSpend = CoinSpend(
        coin: COIN,
        puzzleReveal: getPuzzleFromPk(keychain.unhardenedMap.values.toList()[0].childPublicKey),
        solution: SOLUTION);
    final compressed = compressObjectWithPuzzles(coinSpend.toBytes(), LATEST_VERSION);

    assert(coinSpend.toBytes().length > compressed.length);

    final coinsSpendUncompressed = CoinSpend.fromBytes(decompressObjectWithPuzzles(compressed));
    assert(coinsSpendUncompressed == coinSpend);
    final factor = compressed.length / coinSpend.toBytes().length;
    print("standart factor = ${factor}");
  }

  void testCatPuzzle() {
    final puzzle = CatWalletService.makeCatPuzzle(Program.list([]).hash(),
        getPuzzleFromPk(keychain.unhardenedMap.values.toList()[0].childPublicKey));
    final coinSpend = CoinSpend(coin: COIN, puzzleReveal: puzzle, solution: SOLUTION);
    final compressed = compressObjectWithPuzzles(coinSpend.toBytes(), LATEST_VERSION);

    assert(coinSpend.toBytes().length > compressed.length);

    final coinsSpendUncompressed = CoinSpend.fromBytes(decompressObjectWithPuzzles(compressed));
    assert(coinsSpendUncompressed == coinSpend);
    final factor = compressed.length / coinSpend.toBytes().length;
    print("Cat factor = ${factor}");
  }

  void testOfferPuzzle() {
    final coinSpend = CoinSpend(coin: COIN, puzzleReveal: OFFER_MOD, solution: SOLUTION);
    final compressed = compressObjectWithPuzzles(coinSpend.toBytes(), LATEST_VERSION);

    assert(coinSpend.toBytes().length > compressed.length);

    final coinsSpendUncompressed = CoinSpend.fromBytes(decompressObjectWithPuzzles(compressed));
    assert(coinsSpendUncompressed == coinSpend);
    final factor = compressed.length / coinSpend.toBytes().length;
    print("Offer factor = ${factor}");
  }

  void testLowestBestVersion() {
    assert(lowestBestVersion([catProgram.toBytes()]) == 1);
    assert(lowestBestVersion([OFFER_MOD.toBytes()]) == 2);
  }

  test('Test Puzzle compression', () async {
    testStandardPuzzle();
    testCatPuzzle();
    testOfferPuzzle();
    testLowestBestVersion();
  });
}

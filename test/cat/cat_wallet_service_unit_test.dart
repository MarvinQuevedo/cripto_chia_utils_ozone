/* // ignore_for_file: lines_longer_than_80_chars

import 'dart:convert';
import 'dart:io';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/cat/exceptions/mixed_asset_ids_exception.dart';
import 'package:chia_crypto_utils/src/core/exceptions/change_puzzlehash_needed_exception.dart';
import 'package:chia_crypto_utils/src/core/exceptions/insufficient_coins_exception.dart';
import 'package:test/test.dart';

import 'wallet_keychain_map.dart';

Future<void> main() async {
  final assetId = Puzzlehash.fromHex(
    '9995f30b83e7d3f3ea0eec7e450dbcade83f76516da79daa9a84a9daafec2329',
  );
  const parentCoinSpendMap = {
    "coin": {
      "parent_coin_info": "0xbbf49b881fd1e56b01067f3b07849eb745ea75209ebc2e762dc11c67f3bcac11",
      "puzzle_hash": "0x36be78563a6b18d1a1e3a5d08201935fc9cb70d5f765b5129754489135e03461",
      "amount": 42804
    },
    "puzzle_reveal":
        "0xff02ffff01ff02ffff01ff02ff5effff04ff02ffff04ffff04ff05ffff04ffff0bff34ff0580ffff04ff0bff80808080ffff04ffff02ff17ff2f80ffff04ff5fffff04ffff02ff2effff04ff02ffff04ff17ff80808080ffff04ffff02ff2affff04ff02ffff04ff82027fffff04ff82057fffff04ff820b7fff808080808080ffff04ff81bfffff04ff82017fffff04ff8202ffffff04ff8205ffffff04ff820bffff80808080808080808080808080ffff04ffff01ffffffff3d46ff02ff333cffff0401ff01ff81cb02ffffff20ff02ffff03ff05ffff01ff02ff32ffff04ff02ffff04ff0dffff04ffff0bff7cffff0bff34ff2480ffff0bff7cffff0bff7cffff0bff34ff2c80ff0980ffff0bff7cff0bffff0bff34ff8080808080ff8080808080ffff010b80ff0180ffff02ffff03ffff22ffff09ffff0dff0580ff2280ffff09ffff0dff0b80ff2280ffff15ff17ffff0181ff8080ffff01ff0bff05ff0bff1780ffff01ff088080ff0180ffff02ffff03ff0bffff01ff02ffff03ffff09ffff02ff2effff04ff02ffff04ff13ff80808080ff820b9f80ffff01ff02ff56ffff04ff02ffff04ffff02ff13ffff04ff5fffff04ff17ffff04ff2fffff04ff81bfffff04ff82017fffff04ff1bff8080808080808080ffff04ff82017fff8080808080ffff01ff088080ff0180ffff01ff02ffff03ff17ffff01ff02ffff03ffff20ff81bf80ffff0182017fffff01ff088080ff0180ffff01ff088080ff018080ff0180ff04ffff04ff05ff2780ffff04ffff10ff0bff5780ff778080ffffff02ffff03ff05ffff01ff02ffff03ffff09ffff02ffff03ffff09ff11ff5880ffff0159ff8080ff0180ffff01818f80ffff01ff02ff26ffff04ff02ffff04ff0dffff04ff0bffff04ffff04ff81b9ff82017980ff808080808080ffff01ff02ff7affff04ff02ffff04ffff02ffff03ffff09ff11ff5880ffff01ff04ff58ffff04ffff02ff76ffff04ff02ffff04ff13ffff04ff29ffff04ffff0bff34ff5b80ffff04ff2bff80808080808080ff398080ffff01ff02ffff03ffff09ff11ff7880ffff01ff02ffff03ffff20ffff02ffff03ffff09ffff0121ffff0dff298080ffff01ff02ffff03ffff09ffff0cff29ff80ff3480ff5c80ffff01ff0101ff8080ff0180ff8080ff018080ffff0109ffff01ff088080ff0180ffff010980ff018080ff0180ffff04ffff02ffff03ffff09ff11ff5880ffff0159ff8080ff0180ffff04ffff02ff26ffff04ff02ffff04ff0dffff04ff0bffff04ff17ff808080808080ff80808080808080ff0180ffff01ff04ff80ffff04ff80ff17808080ff0180ffff02ffff03ff05ffff01ff04ff09ffff02ff56ffff04ff02ffff04ff0dffff04ff0bff808080808080ffff010b80ff0180ff0bff7cffff0bff34ff2880ffff0bff7cffff0bff7cffff0bff34ff2c80ff0580ffff0bff7cffff02ff32ffff04ff02ffff04ff07ffff04ffff0bff34ff3480ff8080808080ffff0bff34ff8080808080ffff02ffff03ffff07ff0580ffff01ff0bffff0102ffff02ff2effff04ff02ffff04ff09ff80808080ffff02ff2effff04ff02ffff04ff0dff8080808080ffff01ff0bffff0101ff058080ff0180ffff04ffff04ff30ffff04ff5fff808080ffff02ff7effff04ff02ffff04ffff04ffff04ff2fff0580ffff04ff5fff82017f8080ffff04ffff02ff26ffff04ff02ffff04ff0bffff04ff05ffff01ff808080808080ffff04ff17ffff04ff81bfffff04ff82017fffff04ffff02ff2affff04ff02ffff04ff8204ffffff04ffff02ff76ffff04ff02ffff04ff09ffff04ff820affffff04ffff0bff34ff2d80ffff04ff15ff80808080808080ffff04ff8216ffff808080808080ffff04ff8205ffffff04ff820bffff808080808080808080808080ff02ff5affff04ff02ffff04ff5fffff04ff3bffff04ffff02ffff03ff17ffff01ff09ff2dffff02ff2affff04ff02ffff04ff27ffff04ffff02ff76ffff04ff02ffff04ff29ffff04ff57ffff04ffff0bff34ff81b980ffff04ff59ff80808080808080ffff04ff81b7ff80808080808080ff8080ff0180ffff04ff17ffff04ff05ffff04ff8202ffffff04ffff04ffff04ff78ffff04ffff0eff5cffff02ff2effff04ff02ffff04ffff04ff2fffff04ff82017fff808080ff8080808080ff808080ffff04ffff04ff20ffff04ffff0bff81bfff5cffff02ff2effff04ff02ffff04ffff04ff15ffff04ffff10ff82017fffff11ff8202dfff2b80ff8202ff80ff808080ff8080808080ff808080ff138080ff80808080808080808080ff018080ffff04ffff01a037bef360ee858133b69d595a906dc45d01af50379dad515eb9518abb7c1d2a7affff04ffff01a0d82dd03f8a9ad2f84353cd953c4de6b21dbaaf7de3ba3f4ddd9abe31ecba80adffff04ffff01ff02ffff01ff02ffff01ff02ffff03ff0bffff01ff02ffff03ffff09ff05ffff1dff0bffff1effff0bff0bffff02ff06ffff04ff02ffff04ff17ff8080808080808080ffff01ff02ff17ff2f80ffff01ff088080ff0180ffff01ff04ffff04ff04ffff04ff05ffff04ffff02ff06ffff04ff02ffff04ff17ff80808080ff80808080ffff02ff17ff2f808080ff0180ffff04ffff01ff32ff02ffff03ffff07ff0580ffff01ff0bffff0102ffff02ff06ffff04ff02ffff04ff09ff80808080ffff02ff06ffff04ff02ffff04ff0dff8080808080ffff01ff0bffff0101ff058080ff0180ff018080ffff04ffff01b0b8bbeb52912f1d9e2e3cf12b3ebbf5681798688a28df84833f088fd1ee75c720b7182bcb552f0e1417d38f1005ca4954ff018080ff0180808080",
    "solution":
        "0xffff80ffff01ffff33ffa0ed4a20ca98a5ae0971169c761fc9a72f706450511db4206c8db3378fbfbcc297ff8261a8ffffa0ed4a20ca98a5ae0971169c761fc9a72f706450511db4206c8db3378fbfbcc2978080ffff33ffa068ec29f071cb9ebfec79a22ed504799e120a2ad38c126856565f0c15d5f8120eff82458c80ffff3cffa06320fb4a3764640803618bd92602da87f6c8c42891a6c710f431f047d84e615b8080ff8080ffffa0d3c5acb1452b1517df355e231a86fefbb33895186aeb6e29c7c6505d2135e7f1ffa0cfbfdeed5c4ca2de3d0bf520b9cb4bb7743a359bd2e6a188d19ce7dffc21d3e7ff8300a73480ffa0c0ad5ad03cf6969636417c4a0f3945b82c69d131f638c8dae2fed345136a6228ffffa0bbf49b881fd1e56b01067f3b07849eb745ea75209ebc2e762dc11c67f3bcac11ffa036be78563a6b18d1a1e3a5d08201935fc9cb70d5f765b5129754489135e03461ff8300a73480ffffa0bbf49b881fd1e56b01067f3b07849eb745ea75209ebc2e762dc11c67f3bcac11ffa007d4508f3fbf1e73649723559b9707a36b4962db6cc828093a45da0316e5473dff8300a73480ff80ff8080"
  };
  final parentCoinSpend = CoinSpend.fromJson(
    parentCoinSpendMap,
  );
  final coin0 = Coin(
    confirmedBlockIndex: 17409283,
    spentBlockIndex: 0,
    coinbase: false,
    timestamp: 2748299274,
    parentCoinInfo: Bytes.fromHex(
      '0xc0ad5ad03cf6969636417c4a0f3945b82c69d131f638c8dae2fed345136a6228',
    ),
    puzzlehash: Puzzlehash.fromHex(
      '0xef66a941b531766dbb953766f31b810d4a6e7424198f5f0b74e7adeb2096fe9a',
    ),
    amount: 25000,
  );
  final catCoin0 = CatCoin(
    coin: coin0,
    parentCoinSpend: parentCoinSpend,
  );
  const parentCoinSpendMap1 = {
    "coin": {
      "parent_coin_info": "0x7d8793aa3b56729ad37ce06d1a40a01edd193c801f0376e3469cc4353f609058",
      "puzzle_hash": "0x464a7b9fda3e87d04b4d7f6d109d742ff840a7b7ce1996327572a83ebe5c45f7",
      "amount": 1000
    },
    "puzzle_reveal":
        "0xff02ffff01ff02ffff01ff02ff5effff04ff02ffff04ffff04ff05ffff04ffff0bff34ff0580ffff04ff0bff80808080ffff04ffff02ff17ff2f80ffff04ff5fffff04ffff02ff2effff04ff02ffff04ff17ff80808080ffff04ffff02ff2affff04ff02ffff04ff82027fffff04ff82057fffff04ff820b7fff808080808080ffff04ff81bfffff04ff82017fffff04ff8202ffffff04ff8205ffffff04ff820bffff80808080808080808080808080ffff04ffff01ffffffff3d46ff02ff333cffff0401ff01ff81cb02ffffff20ff02ffff03ff05ffff01ff02ff32ffff04ff02ffff04ff0dffff04ffff0bff7cffff0bff34ff2480ffff0bff7cffff0bff7cffff0bff34ff2c80ff0980ffff0bff7cff0bffff0bff34ff8080808080ff8080808080ffff010b80ff0180ffff02ffff03ffff22ffff09ffff0dff0580ff2280ffff09ffff0dff0b80ff2280ffff15ff17ffff0181ff8080ffff01ff0bff05ff0bff1780ffff01ff088080ff0180ffff02ffff03ff0bffff01ff02ffff03ffff09ffff02ff2effff04ff02ffff04ff13ff80808080ff820b9f80ffff01ff02ff56ffff04ff02ffff04ffff02ff13ffff04ff5fffff04ff17ffff04ff2fffff04ff81bfffff04ff82017fffff04ff1bff8080808080808080ffff04ff82017fff8080808080ffff01ff088080ff0180ffff01ff02ffff03ff17ffff01ff02ffff03ffff20ff81bf80ffff0182017fffff01ff088080ff0180ffff01ff088080ff018080ff0180ff04ffff04ff05ff2780ffff04ffff10ff0bff5780ff778080ffffff02ffff03ff05ffff01ff02ffff03ffff09ffff02ffff03ffff09ff11ff5880ffff0159ff8080ff0180ffff01818f80ffff01ff02ff26ffff04ff02ffff04ff0dffff04ff0bffff04ffff04ff81b9ff82017980ff808080808080ffff01ff02ff7affff04ff02ffff04ffff02ffff03ffff09ff11ff5880ffff01ff04ff58ffff04ffff02ff76ffff04ff02ffff04ff13ffff04ff29ffff04ffff0bff34ff5b80ffff04ff2bff80808080808080ff398080ffff01ff02ffff03ffff09ff11ff7880ffff01ff02ffff03ffff20ffff02ffff03ffff09ffff0121ffff0dff298080ffff01ff02ffff03ffff09ffff0cff29ff80ff3480ff5c80ffff01ff0101ff8080ff0180ff8080ff018080ffff0109ffff01ff088080ff0180ffff010980ff018080ff0180ffff04ffff02ffff03ffff09ff11ff5880ffff0159ff8080ff0180ffff04ffff02ff26ffff04ff02ffff04ff0dffff04ff0bffff04ff17ff808080808080ff80808080808080ff0180ffff01ff04ff80ffff04ff80ff17808080ff0180ffff02ffff03ff05ffff01ff04ff09ffff02ff56ffff04ff02ffff04ff0dffff04ff0bff808080808080ffff010b80ff0180ff0bff7cffff0bff34ff2880ffff0bff7cffff0bff7cffff0bff34ff2c80ff0580ffff0bff7cffff02ff32ffff04ff02ffff04ff07ffff04ffff0bff34ff3480ff8080808080ffff0bff34ff8080808080ffff02ffff03ffff07ff0580ffff01ff0bffff0102ffff02ff2effff04ff02ffff04ff09ff80808080ffff02ff2effff04ff02ffff04ff0dff8080808080ffff01ff0bffff0101ff058080ff0180ffff04ffff04ff30ffff04ff5fff808080ffff02ff7effff04ff02ffff04ffff04ffff04ff2fff0580ffff04ff5fff82017f8080ffff04ffff02ff26ffff04ff02ffff04ff0bffff04ff05ffff01ff808080808080ffff04ff17ffff04ff81bfffff04ff82017fffff04ffff02ff2affff04ff02ffff04ff8204ffffff04ffff02ff76ffff04ff02ffff04ff09ffff04ff820affffff04ffff0bff34ff2d80ffff04ff15ff80808080808080ffff04ff8216ffff808080808080ffff04ff8205ffffff04ff820bffff808080808080808080808080ff02ff5affff04ff02ffff04ff5fffff04ff3bffff04ffff02ffff03ff17ffff01ff09ff2dffff02ff2affff04ff02ffff04ff27ffff04ffff02ff76ffff04ff02ffff04ff29ffff04ff57ffff04ffff0bff34ff81b980ffff04ff59ff80808080808080ffff04ff81b7ff80808080808080ff8080ff0180ffff04ff17ffff04ff05ffff04ff8202ffffff04ffff04ffff04ff78ffff04ffff0eff5cffff02ff2effff04ff02ffff04ffff04ff2fffff04ff82017fff808080ff8080808080ff808080ffff04ffff04ff20ffff04ffff0bff81bfff5cffff02ff2effff04ff02ffff04ffff04ff15ffff04ffff10ff82017fffff11ff8202dfff2b80ff8202ff80ff808080ff8080808080ff808080ff138080ff80808080808080808080ff018080ffff04ffff01a037bef360ee858133b69d595a906dc45d01af50379dad515eb9518abb7c1d2a7affff04ffff01a06d95dae356e32a71db5ddcb42224754a02524c615c5fc35f568c2af04774e589ffff04ffff01ff02ffff01ff02ffff01ff02ffff03ff0bffff01ff02ffff03ffff09ff05ffff1dff0bffff1effff0bff0bffff02ff06ffff04ff02ffff04ff17ff8080808080808080ffff01ff02ff17ff2f80ffff01ff088080ff0180ffff01ff04ffff04ff04ffff04ff05ffff04ffff02ff06ffff04ff02ffff04ff17ff80808080ff80808080ffff02ff17ff2f808080ff0180ffff04ffff01ff32ff02ffff03ffff07ff0580ffff01ff0bffff0102ffff02ff06ffff04ff02ffff04ff09ff80808080ffff02ff06ffff04ff02ffff04ff0dff8080808080ffff01ff0bffff0101ff058080ff0180ff018080ffff04ffff01b08d7b883b95c5521a7e585b929532b15361fef066c24ec5477004987dfea421875edaf823848cbe8d9f0512605ee71a86ff018080ff0180808080",
    "solution":
        "0xffff80ffff01ffff33ffa061061739507933a9305844f8a67d8316e15274d4e322bda70a73da2ac7bc9b69ff8203e8ffffa061061739507933a9305844f8a67d8316e15274d4e322bda70a73da2ac7bc9b698080ffff3cffa00e6bf2e4a981db1cde296fa8dcd250aaff402f2d00489582636b05ade591d0728080ff8080ffffa0cd1cadb80b5028b60777a239af963f20e0d314b155022b2d4e075f0459680b27ffa0cfbfdeed5c4ca2de3d0bf520b9cb4bb7743a359bd2e6a188d19ce7dffc21d3e7ff830ab1ed80ffa02543fdbd22b933fb34dec229e970e05e37b669566b031a2754fc8d6dc7aa92c5ffffa07d8793aa3b56729ad37ce06d1a40a01edd193c801f0376e3469cc4353f609058ffa0464a7b9fda3e87d04b4d7f6d109d742ff840a7b7ce1996327572a83ebe5c45f7ff8203e880ffffa07d8793aa3b56729ad37ce06d1a40a01edd193c801f0376e3469cc4353f609058ffa03038971b64733fa1151892d13a793fcf38d287c39a4c8b98a4ca875641f67e69ff8203e880ff80ff8080"
  };
  final parentCoinSpend1 = CoinSpend.fromJson(
    parentCoinSpendMap1,
  );

  final coin1 = Coin(
    confirmedBlockIndex: 17409283,
    spentBlockIndex: 0,
    coinbase: false,
    timestamp: 274829924,
    parentCoinInfo: Bytes.fromHex(
      '0x2543fdbd22b933fb34dec229e970e05e37b669566b031a2754fc8d6dc7aa92c5',
    ),
    puzzlehash: Puzzlehash.fromHex(
      '0xe5b27e6161e513a77d0a0b7b0532d395a49b8d23c3b6e3120d1fbbafb085bfe9',
    ),
    amount: 1000,
  );
  final otherCatCoin1 = CatCoin(
    coin: coin1,
    parentCoinSpend: parentCoinSpend1,
  );

  final catCoins = [catCoin0];

  final standardCoin = Coin(
    confirmedBlockIndex: 16409283,
    spentBlockIndex: 0,
    coinbase: false,
    timestamp: 274829924,
    parentCoinInfo: Bytes.fromHex(
      '0xa9f58c30a6ded5c743a948c43fbeaef654e4572dc3fdcb78c88f031ab60bebae',
    ),
    puzzlehash: Puzzlehash.fromHex(
      '0x84724e33c59dc542e3ead3cbdd2a5aa25229fd7a61950b32adfafbd1659cab83',
    ),
    amount: 109000,
  );

  ChiaNetworkContextWrapper().registerNetworkContext(Network.mainnet);
  final catWalletService = CatWalletService();

  /* const testMnemonic =
  */
  "impose canal layer two calm nurse above kiwi resist trip vague welcome into gossip pattern device believe oval river miracle erosion universe ride wine";
  //final keychainSecret = KeychainCoreSecret.fromMnemonic(testMnemonic.split(" "));
/* 
  final walletsSetList = <WalletSet>[];
  for (var i = 0; i < 460; i++) {
    final set1 = WalletSet.fromPrivateKey(keychainSecret.masterPrivateKey, i);
    walletsSetList.add(set1);
    print('WalletSet $i - 460');
  } */
/* 
  final walletKeychain = WalletKeychain.fromWalletSets(walletsSetList)
    ..addOuterPuzzleHashesForAssetId(assetId); */
  final walletKeychain = WalletKeychain.fromMap(Map<String, dynamic>.from(walletKeychainMap));

  final changePuzzlehash = walletKeychain.unhardenedMap.values.toList()[0].puzzlehash;
  final targetPuzzlehash = walletKeychain.unhardenedMap.values.toList()[1].puzzlehash;

  test('Produces valid spendbundle', () async {
    final payment = Payment(250, targetPuzzlehash);
    final spendBundle = catWalletService.createSpendBundle(
      payments: [payment],
      catCoinsInput: catCoins,
      changePuzzlehash: changePuzzlehash,
      keychain: walletKeychain,
    );
    catWalletService.validateSpendBundle(spendBundle);
  });

/*   test('Produces valid spendbundle with fee', () async {
    final payment = Payment(250, targetPuzzlehash);
    final spendBundle = catWalletService.createSpendBundle(
      payments: [payment],
      catCoinsInput: catCoins,
      changePuzzlehash: changePuzzlehash,
      keychain: walletKeychain,
      fee: 1000,
      standardCoinsForFee: [standardCoin],
    );
    catWalletService.validateSpendBundle(spendBundle);
  }); */

  test('Produces valid spendbundle with fee and multiple payments', () async {
    final payment = Payment(200, targetPuzzlehash, memos: const <String>['Chia is really cool']);
    final payment1 = Payment(100, targetPuzzlehash, memos: const <int>[1000]);
    final spendBundle = catWalletService.createSpendBundle(
      payments: [payment, payment1],
      catCoinsInput: catCoins,
      changePuzzlehash: changePuzzlehash,
      keychain: walletKeychain,
      fee: 1000,
      standardCoinsForFee: [standardCoin],
    );
    catWalletService.validateSpendBundle(spendBundle);
  });

  test('Should throw error when mixing cat types', () {
    final payment = Payment(5, targetPuzzlehash);
    expect(
      () {
        catWalletService.createSpendBundle(
          payments: [payment],
          catCoinsInput: catCoins + [otherCatCoin1],
          changePuzzlehash: changePuzzlehash,
          keychain: walletKeychain,
        );
      },
      throwsA(isA<MixedAssetIdsException>()),
    );
  });

  test('Should create valid spendbundle without change puzzlehash when there is no change', () {
    final totalCoinsValue = catCoins.fold(
      0,
      (int previousValue, coin) => previousValue + coin.amount,
    );
    final spendBundle = catWalletService.createSpendBundle(
      payments: [Payment(totalCoinsValue, targetPuzzlehash)],
      catCoinsInput: catCoins,
      keychain: walletKeychain,
    );

    catWalletService.validateSpendBundle(spendBundle);
  });

  test('Should throw exception when change puzzlehash is not given and there is change', () {
    expect(
      () {
        catWalletService.createSpendBundle(
          payments: [Payment(100, targetPuzzlehash)],
          catCoinsInput: catCoins,
          keychain: walletKeychain,
        );
      },
      throwsA(isA<ChangePuzzlehashNeededException>()),
    );
  });

  test('Should throw exception when there are insufficient funds to make payment', () {
    expect(
      () {
        catWalletService.createSpendBundle(
          payments: [Payment(999999, targetPuzzlehash)],
          catCoinsInput: catCoins,
          keychain: walletKeychain,
        );
      },
      throwsA(isA<InsufficientCoinsException>()),
    );
  });
}
 */

Future<void> main() async {}

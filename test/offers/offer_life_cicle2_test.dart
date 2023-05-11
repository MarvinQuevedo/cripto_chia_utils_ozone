// ignore_for_file: unused_local_variable

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/core/models/conditions/announcement.dart';
import 'package:test/test.dart';

Puzzlehash str_to_tail_hash(String tail_str) {
  return Program.list([
    Program.fromInt(3),
    Program.list([]),
    Program.list([Program.fromInt(1), Program.fromString(tail_str)]),
    Program.list([])
  ]).hash();
}

/// `generate_secure_bundle` simulates a wallet's `generate_signed_transaction`
/// but doesn't bother with non-offer announcements
Offer generate_secure_bundle(
    {required List<FullCoin> selectedCoins,
    required List<Announcement> announcements,
    required Map<Bytes?, int> offeredAmounts,
    required WalletKeychain keychain,
    required int fee,
    required Puzzlehash changePuzzlehash,
    required Map<Bytes, PuzzleInfo> driverDict,
    required Map<Bytes?, List<NotarizedPayment>> notarizedPayments}) {
  final transactions = <SpendBundle>[];

  final feeLeftToPay = fee;

  for (var coin in selectedCoins) {
    if (coin.assetId == null) {
      final standarBundle = StandardWalletService().createSpendBundle(
          payments: [Payment(offeredAmounts[coin.assetId]!, Offer.ph(false))],
          coinsInput: selectedCoins,
          keychain: keychain,
          fee: feeLeftToPay,
          changePuzzlehash: changePuzzlehash);
      transactions.add(standarBundle);
    } else if (coin.assetId != null) {
      final catBundle = CatWalletService().createSpendBundle(
        payments: [Payment(offeredAmounts[coin.assetId]!, Offer.ph(false))],
        catCoinsInput:
            selectedCoins.where((element) => element.isCatCoin).map((e) => e.toCatCoin()).toList(),
        keychain: keychain,
        fee: feeLeftToPay,
        puzzleAnnouncementsToAssert: announcements,
      );
      transactions.add(catBundle);
    }
  }
  final totalSpendBundle = transactions.fold<SpendBundle>(
      SpendBundle.empty, (previousValue, spendBundle) => previousValue + spendBundle);

  return Offer(
      requestedPayments: notarizedPayments,
      bundle: totalSpendBundle,
      driverDict: driverDict,
      old: false);
}

Future<void> main() async {
  final acs = Program.fromInt(1);
  final acs_ph = acs.hash();
  final destinationPuzzleHash =
      Address("xch1m2use8pwfm3plxkvjcz880l7s9gaxacfx53k2mzcuxsnkezeu4zqldxch6").toPuzzlehash();
  final assetId = Puzzlehash.fromHex(
    '9995f30b83e7d3f3ea0eec7e450dbcade83f76516da79daa9a84a9daafec2329',
  );
  const parentCoinSpendMap = {
    "coin": {
      "parent_coin_info": "0x2e7c92d7152fc8287c1cdf5206380715f8936080250154235bc87fc7f644868d",
      "puzzle_hash": "0x62ba1a71db79f5f0820d78dccd11183499ff0601f2c8aa82725a6942e8cadd50",
      "amount": 109000
    },
    "puzzle_reveal":
        "0xff02ffff01ff02ffff01ff02ff5effff04ff02ffff04ffff04ff05ffff04ffff0bff34ff0580ffff04ff0bff80808080ffff04ffff02ff17ff2f80ffff04ff5fffff04ffff02ff2effff04ff02ffff04ff17ff80808080ffff04ffff02ff2affff04ff02ffff04ff82027fffff04ff82057fffff04ff820b7fff808080808080ffff04ff81bfffff04ff82017fffff04ff8202ffffff04ff8205ffffff04ff820bffff80808080808080808080808080ffff04ffff01ffffffff3d46ff02ff333cffff0401ff01ff81cb02ffffff20ff02ffff03ff05ffff01ff02ff32ffff04ff02ffff04ff0dffff04ffff0bff7cffff0bff34ff2480ffff0bff7cffff0bff7cffff0bff34ff2c80ff0980ffff0bff7cff0bffff0bff34ff8080808080ff8080808080ffff010b80ff0180ffff02ffff03ffff22ffff09ffff0dff0580ff2280ffff09ffff0dff0b80ff2280ffff15ff17ffff0181ff8080ffff01ff0bff05ff0bff1780ffff01ff088080ff0180ffff02ffff03ff0bffff01ff02ffff03ffff09ffff02ff2effff04ff02ffff04ff13ff80808080ff820b9f80ffff01ff02ff56ffff04ff02ffff04ffff02ff13ffff04ff5fffff04ff17ffff04ff2fffff04ff81bfffff04ff82017fffff04ff1bff8080808080808080ffff04ff82017fff8080808080ffff01ff088080ff0180ffff01ff02ffff03ff17ffff01ff02ffff03ffff20ff81bf80ffff0182017fffff01ff088080ff0180ffff01ff088080ff018080ff0180ff04ffff04ff05ff2780ffff04ffff10ff0bff5780ff778080ffffff02ffff03ff05ffff01ff02ffff03ffff09ffff02ffff03ffff09ff11ff5880ffff0159ff8080ff0180ffff01818f80ffff01ff02ff26ffff04ff02ffff04ff0dffff04ff0bffff04ffff04ff81b9ff82017980ff808080808080ffff01ff02ff7affff04ff02ffff04ffff02ffff03ffff09ff11ff5880ffff01ff04ff58ffff04ffff02ff76ffff04ff02ffff04ff13ffff04ff29ffff04ffff0bff34ff5b80ffff04ff2bff80808080808080ff398080ffff01ff02ffff03ffff09ff11ff7880ffff01ff02ffff03ffff20ffff02ffff03ffff09ffff0121ffff0dff298080ffff01ff02ffff03ffff09ffff0cff29ff80ff3480ff5c80ffff01ff0101ff8080ff0180ff8080ff018080ffff0109ffff01ff088080ff0180ffff010980ff018080ff0180ffff04ffff02ffff03ffff09ff11ff5880ffff0159ff8080ff0180ffff04ffff02ff26ffff04ff02ffff04ff0dffff04ff0bffff04ff17ff808080808080ff80808080808080ff0180ffff01ff04ff80ffff04ff80ff17808080ff0180ffff02ffff03ff05ffff01ff04ff09ffff02ff56ffff04ff02ffff04ff0dffff04ff0bff808080808080ffff010b80ff0180ff0bff7cffff0bff34ff2880ffff0bff7cffff0bff7cffff0bff34ff2c80ff0580ffff0bff7cffff02ff32ffff04ff02ffff04ff07ffff04ffff0bff34ff3480ff8080808080ffff0bff34ff8080808080ffff02ffff03ffff07ff0580ffff01ff0bffff0102ffff02ff2effff04ff02ffff04ff09ff80808080ffff02ff2effff04ff02ffff04ff0dff8080808080ffff01ff0bffff0101ff058080ff0180ffff04ffff04ff30ffff04ff5fff808080ffff02ff7effff04ff02ffff04ffff04ffff04ff2fff0580ffff04ff5fff82017f8080ffff04ffff02ff26ffff04ff02ffff04ff0bffff04ff05ffff01ff808080808080ffff04ff17ffff04ff81bfffff04ff82017fffff04ffff02ff2affff04ff02ffff04ff8204ffffff04ffff02ff76ffff04ff02ffff04ff09ffff04ff820affffff04ffff0bff34ff2d80ffff04ff15ff80808080808080ffff04ff8216ffff808080808080ffff04ff8205ffffff04ff820bffff808080808080808080808080ff02ff5affff04ff02ffff04ff5fffff04ff3bffff04ffff02ffff03ff17ffff01ff09ff2dffff02ff2affff04ff02ffff04ff27ffff04ffff02ff76ffff04ff02ffff04ff29ffff04ff57ffff04ffff0bff34ff81b980ffff04ff59ff80808080808080ffff04ff81b7ff80808080808080ff8080ff0180ffff04ff17ffff04ff05ffff04ff8202ffffff04ffff04ffff04ff78ffff04ffff0eff5cffff02ff2effff04ff02ffff04ffff04ff2fffff04ff82017fff808080ff8080808080ff808080ffff04ffff04ff20ffff04ffff0bff81bfff5cffff02ff2effff04ff02ffff04ffff04ff15ffff04ffff10ff82017fffff11ff8202dfff2b80ff8202ff80ff808080ff8080808080ff808080ff138080ff80808080808080808080ff018080ffff04ffff01a037bef360ee858133b69d595a906dc45d01af50379dad515eb9518abb7c1d2a7affff04ffff01a09995f30b83e7d3f3ea0eec7e450dbcade83f76516da79daa9a84a9daafec2329ffff04ffff01ff02ffff01ff02ff0affff04ff02ffff04ff03ff80808080ffff04ffff01ffff333effff02ffff03ff05ffff01ff04ffff04ff0cffff04ffff02ff1effff04ff02ffff04ff09ff80808080ff808080ffff02ff16ffff04ff02ffff04ff19ffff04ffff02ff0affff04ff02ffff04ff0dff80808080ff808080808080ff8080ff0180ffff02ffff03ff05ffff01ff02ffff03ffff15ff29ff8080ffff01ff04ffff04ff08ff0980ffff02ff16ffff04ff02ffff04ff0dffff04ff0bff808080808080ffff01ff088080ff0180ffff010b80ff0180ff02ffff03ffff07ff0580ffff01ff0bffff0102ffff02ff1effff04ff02ffff04ff09ff80808080ffff02ff1effff04ff02ffff04ff0dff8080808080ffff01ff0bffff0101ff058080ff0180ff018080ff0180808080",
    "solution":
        "0xffffffa01685aa7d24d92b1335e9deb7075be5a4a0842293aa9d5dbc306e4c0d2a952e7dffffa0dab90c9c2e4ee21f9acc960473bffe8151d377093523656c58e1a13b6459e544ff8301a9c8ffffa0dab90c9c2e4ee21f9acc960473bffe8151d377093523656c58e1a13b6459e54480808080ffffa045d9fca55d73f21db9e1d2fee47f067a1bd62dce959390b0815301525662a76fffa0e8ca61c88e4354440e2b88a0c25f206ecc1bc1f5526a4ec06c2e05c291860c80ff8306496080ffa0a9f58c30a6ded5c743a948c43fbeaef654e4572dc3fdcb78c88f031ab60bebaeffffa02e7c92d7152fc8287c1cdf5206380715f8936080250154235bc87fc7f644868dffa062ba1a71db79f5f0820d78dccd11183499ff0601f2c8aa82725a6942e8cadd50ff8301a9c880ffffa02e7c92d7152fc8287c1cdf5206380715f8936080250154235bc87fc7f644868dffa0cfbfdeed5c4ca2de3d0bf520b9cb4bb7743a359bd2e6a188d19ce7dffc21d3e7ff8301a9c880ff80ff8080"
  };
  final parentCoinSpend = CoinSpend.fromJson(parentCoinSpendMap);
  final coin0 = Coin(
    confirmedBlockIndex: 17409283,
    spentBlockIndex: 0,
    coinbase: false,
    timestamp: 2748299274,
    parentCoinInfo: Bytes.fromHex(
      '0xa9f58c30a6ded5c743a948c43fbeaef654e4572dc3fdcb78c88f031ab60bebae',
    ),
    puzzlehash: Puzzlehash.fromHex(
      '0x84724e33c59dc542e3ead3cbdd2a5aa25229fd7a61950b32adfafbd1659cab83',
    ),
    amount: 109000,
  );
  final catCoin0 = CatCoin(
    coin: coin0,
    parentCoinSpend: parentCoinSpend,
  );

  final coin1 = Coin(
    confirmedBlockIndex: 17409283,
    spentBlockIndex: 0,
    coinbase: false,
    timestamp: 274829924,
    parentCoinInfo: Bytes.fromHex(
      'c1fdd54dd268a26fde78bb203a32a14ca942f015a9343d4ea5e9961f997256a1',
    ),
    puzzlehash: Puzzlehash.fromHex(
      '5db372b6e7577013035b4ee3fced2a7466d6ff1d3716b182afe520d83ee3427a',
    ),
    amount: 109000,
  );
  final catCoin1 = CatCoin(
    coin: coin1,
    parentCoinSpend: parentCoinSpend,
  );

  final catCoins = [catCoin0, catCoin1];

  final otherCoin = Coin(
    confirmedBlockIndex: 17409283,
    spentBlockIndex: 0,
    coinbase: false,
    timestamp: 274829924,
    parentCoinInfo: Bytes.fromHex(
      '45d9fca55d73f21db9e1d2fee47f067a1bd62dce959390b0815301525662a76f',
    ),
    puzzlehash: Puzzlehash.fromHex(
      'd930dc400ce7b5a6e1f89bc9c88e70da00eb429ecce8552f130764b2ab4dfde2',
    ),
    amount: 412000,
  );
  const otherCatParentMap = {
    "coin": {
      "parent_coin_info": "0xd48773284569e8331a27168c4a95afdf04590d0a050e951d993c79aa15a7f344",
      "puzzle_hash": "0xd930dc400ce7b5a6e1f89bc9c88e70da00eb429ecce8552f130764b2ab4dfde2",
      "amount": 521000
    },
    "puzzle_reveal":
        "0xff02ffff01ff02ffff01ff02ff5effff04ff02ffff04ffff04ff05ffff04ffff0bff34ff0580ffff04ff0bff80808080ffff04ffff02ff17ff2f80ffff04ff5fffff04ffff02ff2effff04ff02ffff04ff17ff80808080ffff04ffff02ff2affff04ff02ffff04ff82027fffff04ff82057fffff04ff820b7fff808080808080ffff04ff81bfffff04ff82017fffff04ff8202ffffff04ff8205ffffff04ff820bffff80808080808080808080808080ffff04ffff01ffffffff3d46ff02ff333cffff0401ff01ff81cb02ffffff20ff02ffff03ff05ffff01ff02ff32ffff04ff02ffff04ff0dffff04ffff0bff7cffff0bff34ff2480ffff0bff7cffff0bff7cffff0bff34ff2c80ff0980ffff0bff7cff0bffff0bff34ff8080808080ff8080808080ffff010b80ff0180ffff02ffff03ffff22ffff09ffff0dff0580ff2280ffff09ffff0dff0b80ff2280ffff15ff17ffff0181ff8080ffff01ff0bff05ff0bff1780ffff01ff088080ff0180ffff02ffff03ff0bffff01ff02ffff03ffff09ffff02ff2effff04ff02ffff04ff13ff80808080ff820b9f80ffff01ff02ff56ffff04ff02ffff04ffff02ff13ffff04ff5fffff04ff17ffff04ff2fffff04ff81bfffff04ff82017fffff04ff1bff8080808080808080ffff04ff82017fff8080808080ffff01ff088080ff0180ffff01ff02ffff03ff17ffff01ff02ffff03ffff20ff81bf80ffff0182017fffff01ff088080ff0180ffff01ff088080ff018080ff0180ff04ffff04ff05ff2780ffff04ffff10ff0bff5780ff778080ffffff02ffff03ff05ffff01ff02ffff03ffff09ffff02ffff03ffff09ff11ff5880ffff0159ff8080ff0180ffff01818f80ffff01ff02ff26ffff04ff02ffff04ff0dffff04ff0bffff04ffff04ff81b9ff82017980ff808080808080ffff01ff02ff7affff04ff02ffff04ffff02ffff03ffff09ff11ff5880ffff01ff04ff58ffff04ffff02ff76ffff04ff02ffff04ff13ffff04ff29ffff04ffff0bff34ff5b80ffff04ff2bff80808080808080ff398080ffff01ff02ffff03ffff09ff11ff7880ffff01ff02ffff03ffff20ffff02ffff03ffff09ffff0121ffff0dff298080ffff01ff02ffff03ffff09ffff0cff29ff80ff3480ff5c80ffff01ff0101ff8080ff0180ff8080ff018080ffff0109ffff01ff088080ff0180ffff010980ff018080ff0180ffff04ffff02ffff03ffff09ff11ff5880ffff0159ff8080ff0180ffff04ffff02ff26ffff04ff02ffff04ff0dffff04ff0bffff04ff17ff808080808080ff80808080808080ff0180ffff01ff04ff80ffff04ff80ff17808080ff0180ffff02ffff03ff05ffff01ff04ff09ffff02ff56ffff04ff02ffff04ff0dffff04ff0bff808080808080ffff010b80ff0180ff0bff7cffff0bff34ff2880ffff0bff7cffff0bff7cffff0bff34ff2c80ff0580ffff0bff7cffff02ff32ffff04ff02ffff04ff07ffff04ffff0bff34ff3480ff8080808080ffff0bff34ff8080808080ffff02ffff03ffff07ff0580ffff01ff0bffff0102ffff02ff2effff04ff02ffff04ff09ff80808080ffff02ff2effff04ff02ffff04ff0dff8080808080ffff01ff0bffff0101ff058080ff0180ffff04ffff04ff30ffff04ff5fff808080ffff02ff7effff04ff02ffff04ffff04ffff04ff2fff0580ffff04ff5fff82017f8080ffff04ffff02ff26ffff04ff02ffff04ff0bffff04ff05ffff01ff808080808080ffff04ff17ffff04ff81bfffff04ff82017fffff04ffff02ff2affff04ff02ffff04ff8204ffffff04ffff02ff76ffff04ff02ffff04ff09ffff04ff820affffff04ffff0bff34ff2d80ffff04ff15ff80808080808080ffff04ff8216ffff808080808080ffff04ff8205ffffff04ff820bffff808080808080808080808080ff02ff5affff04ff02ffff04ff5fffff04ff3bffff04ffff02ffff03ff17ffff01ff09ff2dffff02ff2affff04ff02ffff04ff27ffff04ffff02ff76ffff04ff02ffff04ff29ffff04ff57ffff04ffff0bff34ff81b980ffff04ff59ff80808080808080ffff04ff81b7ff80808080808080ff8080ff0180ffff04ff17ffff04ff05ffff04ff8202ffffff04ffff04ffff04ff78ffff04ffff0eff5cffff02ff2effff04ff02ffff04ffff04ff2fffff04ff82017fff808080ff8080808080ff808080ffff04ffff04ff20ffff04ffff0bff81bfff5cffff02ff2effff04ff02ffff04ffff04ff15ffff04ffff10ff82017fffff11ff8202dfff2b80ff8202ff80ff808080ff8080808080ff808080ff138080ff80808080808080808080ff018080ffff04ffff01a037bef360ee858133b69d595a906dc45d01af50379dad515eb9518abb7c1d2a7affff04ffff01a09995f30b83e7d3f3ea0eec7e450dbcade83f76516da79daa9a84a9daafec2329ffff04ffff01ff02ffff01ff02ffff01ff02ffff03ff0bffff01ff02ffff03ffff09ff05ffff1dff0bffff1effff0bff0bffff02ff06ffff04ff02ffff04ff17ff8080808080808080ffff01ff02ff17ff2f80ffff01ff088080ff0180ffff01ff04ffff04ff04ffff04ff05ffff04ffff02ff06ffff04ff02ffff04ff17ff80808080ff80808080ffff02ff17ff2f808080ff0180ffff04ffff01ff32ff02ffff03ffff07ff0580ffff01ff0bffff0102ffff02ff06ffff04ff02ffff04ff09ff80808080ffff02ff06ffff04ff02ffff04ff0dff8080808080ffff01ff0bffff0101ff058080ff0180ff018080ffff04ffff01b08e18fa7bcbd51194351fcbf0bd0c1eb73c4b855cf63e12df28958c720d030cf5b70a82196c6ddd31c38ff09395c0ca7cff018080ff0180808080",
    "solution":
        "0xffff80ffff01ffff33ffa0cfbfdeed5c4ca2de3d0bf520b9cb4bb7743a359bd2e6a188d19ce7dffc21d3e7ff8301a9c880ffff33ffa0e8ca61c88e4354440e2b88a0c25f206ecc1bc1f5526a4ec06c2e05c291860c80ff8306496080ffff3fffa03f1d5d16896e124c293ed277476ca4c393c217a32ccb4fcedcc240bcc259b68680ffff3cffa0606b948e1fd5cd48af4ee782835de8ab1578ba28ff5b587a9dec8db472e336e58080ff8080ffffa0306775a3fb434beef0aecb08d7dceb101ab6468bc5e770d46e56c4d4c70f6963ffa0e8ca61c88e4354440e2b88a0c25f206ecc1bc1f5526a4ec06c2e05c291860c80ff8308cde880ffa045d9fca55d73f21db9e1d2fee47f067a1bd62dce959390b0815301525662a76fffffa0d48773284569e8331a27168c4a95afdf04590d0a050e951d993c79aa15a7f344ffa0d930dc400ce7b5a6e1f89bc9c88e70da00eb429ecce8552f130764b2ab4dfde2ff8307f32880ffffa0d48773284569e8331a27168c4a95afdf04590d0a050e951d993c79aa15a7f344ffa0e8ca61c88e4354440e2b88a0c25f206ecc1bc1f5526a4ec06c2e05c291860c80ff8307f32880ff80ff8080"
  };
  final otherParentCoinSpend = CoinSpend.fromJson(otherCatParentMap);

  final otherCat = CatCoin(
    coin: otherCoin,
    parentCoinSpend: otherParentCoinSpend,
  );

  final standardCoin = Coin(
    confirmedBlockIndex: 16409283,
    spentBlockIndex: 0,
    coinbase: false,
    timestamp: 274829924,
    parentCoinInfo: Bytes.fromHex(
      'e3b0c44298fc1c149afbf4c8996fb92400000000000000000000000000000003',
    ),
    puzzlehash: Puzzlehash.fromHex(
      '0b7a3d5e723e0b046fd51f95cabf2d3e2616f05d9d1833e8166052b43d9454ad',
    ),
    amount: 100000,
  );

  ChiaNetworkContextWrapper().registerNetworkContext(Network.mainnet);

  final catWalletService = CatWalletService();

  const testMnemonic = [
    'elder',
    'quality',
    'this',
    'chalk',
    'crane',
    'endless',
    'machine',
    'hotel',
    'unfair',
    'castle',
    'expand',
    'refuse',
    'lizard',
    'vacuum',
    'embody',
    'track',
    'crash',
    'truth',
    'arrow',
    'tree',
    'poet',
    'audit',
    'grid',
    'mesh',
  ];

  final keychainSecret = KeychainCoreSecret.fromMnemonic(testMnemonic);

  final walletsSetList = <WalletSet>[];
  for (var i = 0; i < 20; i++) {
    final set1 = WalletSet.fromPrivateKey(keychainSecret.masterPrivateKey, i);
    walletsSetList.add(set1);
  }

  final walletKeychain = WalletKeychain.fromWalletSets(walletsSetList)
    ..addOuterPuzzleHashesForAssetId(assetId);

  final changePuzzlehash = walletKeychain.unhardenedMap.values.toList()[0].puzzlehash;
  final targetPuzzlehash = walletKeychain.unhardenedMap.values.toList()[1].puzzlehash;

  test('Produces valid offert', () async {
    final stardarCoins = [standardCoin];
    final driverDict = <Bytes, PuzzleInfo>{
      str_to_tail_hash("red"): PuzzleInfo(
        {
          "type": "CAT",
          "tail": str_to_tail_hash("red"),
        },
      ),
      str_to_tail_hash("blue"): PuzzleInfo(
        {
          "type": "CAT",
          "tail": str_to_tail_hash("blue"),
        },
      )
    };
    final chiaRequestedPayments = <Bytes?, List<Payment>>{
      str_to_tail_hash("red").toBytes(): [
        Payment(
          100,
          acs_ph,
          memos: <String>["memo"],
        ),
        Payment(
          200,
          acs_ph,
          memos: <String>["memo"],
        ),
      ],
    };
    final chiaOfferedAmount = 100;

    final chiaNotariedPayments = Offer.notarizePayments(
      requestedPayments: chiaRequestedPayments,
      coins: stardarCoins,
    );

    chiaNotariedPayments.forEach((key, value) {
      value.forEach((element) {
        print("${element.amount}");
        print("${element.puzzlehash}");
        print("${element.memos}");
        print("${element.nonce}");
      });
      print("");
    });
    final chiaAnnouncements = Offer.calculateAnnouncements(
        notarizedPayment: chiaNotariedPayments, driverDict: driverDict, old: false);

    for (var ann in chiaAnnouncements) {
      final mesasge = ann.announcementHash.toHex();
      print("hash=" + mesasge);
      print(ann.program.toSource());
    }

    final chia_offer = generate_secure_bundle(
      announcements: chiaAnnouncements,
      offeredAmounts: {null: chiaOfferedAmount},
      selectedCoins: stardarCoins.map((e) => FullCoin(coin: e)).toList(),
      fee: 0,
      changePuzzlehash: changePuzzlehash,
      keychain: walletKeychain,
      notarizedPayments: chiaNotariedPayments,
      driverDict: driverDict,
    );

    print(chia_offer.toBench32());
  });
}

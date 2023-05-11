import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/test.dart';

final coinMap = {
  "coin": {
    "parent_coin_info": "0xed166329e3f7cd671dd85fd70cb15ba46cbc3a9e9bbd81c643e75250fb2d9a8a",
    "puzzle_hash": "0xaca3b3bf3cd8f4ee91d124a6ac506d979f7eb05aed8415f2ccf28bee6b57b24c",
    "amount": 1
  },
  "confirmed_block_index": 2523394,
  "spent_block_index": 0,
  "coinbase": false,
  "timestamp": 1682101719
};
final parentCoinSpendMap = {
  "coin": {
    "parent_coin_info": "0xbe3289f80507085c3131f05c6e3a339fdace415d543d1535fcdb05a93175fd12",
    "puzzle_hash": "0x9c05f79b6ef5dbdb972868f68b7b8b9144c5eee40dcf7b811d51a04834cee1c5",
    "amount": 1
  },
  "puzzle_reveal":
      "0xff02ffff01ff02ffff01ff02ffff03ffff18ff2fff3480ffff01ff04ffff04ff20ffff04ff2fff808080ffff04ffff02ff3effff04ff02ffff04ff05ffff04ffff02ff2affff04ff02ffff04ff27ffff04ffff02ffff03ff77ffff01ff02ff36ffff04ff02ffff04ff09ffff04ff57ffff04ffff02ff2effff04ff02ffff04ff05ff80808080ff808080808080ffff011d80ff0180ffff04ffff02ffff03ff77ffff0181b7ffff015780ff0180ff808080808080ffff04ff77ff808080808080ffff02ff3affff04ff02ffff04ff05ffff04ffff02ff0bff5f80ffff01ff8080808080808080ffff01ff088080ff0180ffff04ffff01ffffffff4947ff0233ffff0401ff0102ffffff20ff02ffff03ff05ffff01ff02ff32ffff04ff02ffff04ff0dffff04ffff0bff3cffff0bff34ff2480ffff0bff3cffff0bff3cffff0bff34ff2c80ff0980ffff0bff3cff0bffff0bff34ff8080808080ff8080808080ffff010b80ff0180ffff02ffff03ffff22ffff09ffff0dff0580ff2280ffff09ffff0dff0b80ff2280ffff15ff17ffff0181ff8080ffff01ff0bff05ff0bff1780ffff01ff088080ff0180ff02ffff03ff0bffff01ff02ffff03ffff02ff26ffff04ff02ffff04ff13ff80808080ffff01ff02ffff03ffff20ff1780ffff01ff02ffff03ffff09ff81b3ffff01818f80ffff01ff02ff3affff04ff02ffff04ff05ffff04ff1bffff04ff34ff808080808080ffff01ff04ffff04ff23ffff04ffff02ff36ffff04ff02ffff04ff09ffff04ff53ffff04ffff02ff2effff04ff02ffff04ff05ff80808080ff808080808080ff738080ffff02ff3affff04ff02ffff04ff05ffff04ff1bffff04ff34ff8080808080808080ff0180ffff01ff088080ff0180ffff01ff04ff13ffff02ff3affff04ff02ffff04ff05ffff04ff1bffff04ff17ff8080808080808080ff0180ffff01ff02ffff03ff17ff80ffff01ff088080ff018080ff0180ffffff02ffff03ffff09ff09ff3880ffff01ff02ffff03ffff18ff2dffff010180ffff01ff0101ff8080ff0180ff8080ff0180ff0bff3cffff0bff34ff2880ffff0bff3cffff0bff3cffff0bff34ff2c80ff0580ffff0bff3cffff02ff32ffff04ff02ffff04ff07ffff04ffff0bff34ff3480ff8080808080ffff0bff34ff8080808080ffff02ffff03ffff07ff0580ffff01ff0bffff0102ffff02ff2effff04ff02ffff04ff09ff80808080ffff02ff2effff04ff02ffff04ff0dff8080808080ffff01ff0bffff0101ff058080ff0180ff02ffff03ffff21ff17ffff09ff0bff158080ffff01ff04ff30ffff04ff0bff808080ffff01ff088080ff0180ff018080ffff04ffff01ffa07faa3253bfddd1e0decb0906b2dc6247bbc4cf608f58345d173adb63e8b47c9fffa0e80321b0ec2100f6cae1541f315a150119752d3ab00e353daf0fe1c9364f3bbaa0eff07522495060c066f66f32acc2a77e3a3e737aca8baea4d1a64ea4cdc13da9ffff04ffff01ff02ffff01ff02ffff01ff02ff3effff04ff02ffff04ff05ffff04ffff02ff2fff5f80ffff04ff80ffff04ffff04ffff04ff0bffff04ff17ff808080ffff01ff808080ffff01ff8080808080808080ffff04ffff01ffffff0233ff04ff0101ffff02ff02ffff03ff05ffff01ff02ff1affff04ff02ffff04ff0dffff04ffff0bff12ffff0bff2cff1480ffff0bff12ffff0bff12ffff0bff2cff3c80ff0980ffff0bff12ff0bffff0bff2cff8080808080ff8080808080ffff010b80ff0180ffff0bff12ffff0bff2cff1080ffff0bff12ffff0bff12ffff0bff2cff3c80ff0580ffff0bff12ffff02ff1affff04ff02ffff04ff07ffff04ffff0bff2cff2c80ff8080808080ffff0bff2cff8080808080ffff02ffff03ffff07ff0580ffff01ff0bffff0102ffff02ff2effff04ff02ffff04ff09ff80808080ffff02ff2effff04ff02ffff04ff0dff8080808080ffff01ff0bffff0101ff058080ff0180ff02ffff03ff0bffff01ff02ffff03ffff09ff23ff1880ffff01ff02ffff03ffff18ff81b3ff2c80ffff01ff02ffff03ffff20ff1780ffff01ff02ff3effff04ff02ffff04ff05ffff04ff1bffff04ff33ffff04ff2fffff04ff5fff8080808080808080ffff01ff088080ff0180ffff01ff04ff13ffff02ff3effff04ff02ffff04ff05ffff04ff1bffff04ff17ffff04ff2fffff04ff5fff80808080808080808080ff0180ffff01ff02ffff03ffff09ff23ffff0181e880ffff01ff02ff3effff04ff02ffff04ff05ffff04ff1bffff04ff17ffff04ffff02ffff03ffff22ffff09ffff02ff2effff04ff02ffff04ff53ff80808080ff82014f80ffff20ff5f8080ffff01ff02ff53ffff04ff818fffff04ff82014fffff04ff81b3ff8080808080ffff01ff088080ff0180ffff04ff2cff8080808080808080ffff01ff04ff13ffff02ff3effff04ff02ffff04ff05ffff04ff1bffff04ff17ffff04ff2fffff04ff5fff80808080808080808080ff018080ff0180ffff01ff04ffff04ff18ffff04ffff02ff16ffff04ff02ffff04ff05ffff04ff27ffff04ffff0bff2cff82014f80ffff04ffff02ff2effff04ff02ffff04ff818fff80808080ffff04ffff0bff2cff0580ff8080808080808080ff378080ff81af8080ff0180ff018080ffff04ffff01a0a04d9f57764f54a43e4030befb4d80026e870519aaa66334aef8304f5d0393c2ffff04ffff01ffff75ffc04468747470733a2f2f696d616765732e706578656c732e636f6d2f70686f746f732f31313035333037322f706578656c732d70686f746f2d31313035333037322e6a70656780ffff68a014836b86a48e1b2b5e857213af97534704475b4c155d34b2cb83ed4b7cba2bb0ffff826d75ffc06668747470733a2f2f62616679626569686c6233626e63786a6e6f347573357172356a336c6768696933356a74353370376b666c70336b6f6d796b796d7875336d7735652e697066732e6e667473746f726167652e6c696e6b2f6d657461646174612e6a736f6e80ffff826c7580ffff82736e01ffff82737401ffff826d68a0d4a08eb2e6bb2e84a0a026a5edb256ea36ccb43ab2a97dc51e31675befa0ab9c80ffff04ffff01a0fe8a4b4e27a2e29a4d3fc7ce9d527adbcaccbab6ada3903ccf3ba9a769d2d78bffff04ffff01ff02ffff01ff02ffff01ff02ff26ffff04ff02ffff04ff05ffff04ff17ffff04ff0bffff04ffff02ff2fff5f80ff80808080808080ffff04ffff01ffffff82ad4cff0233ffff3e04ff81f601ffffff0102ffff02ffff03ff05ffff01ff02ff2affff04ff02ffff04ff0dffff04ffff0bff32ffff0bff3cff3480ffff0bff32ffff0bff32ffff0bff3cff2280ff0980ffff0bff32ff0bffff0bff3cff8080808080ff8080808080ffff010b80ff0180ff04ffff04ff38ffff04ffff02ff36ffff04ff02ffff04ff05ffff04ff27ffff04ffff02ff2effff04ff02ffff04ffff02ffff03ff81afffff0181afffff010b80ff0180ff80808080ffff04ffff0bff3cff4f80ffff04ffff0bff3cff0580ff8080808080808080ff378080ff82016f80ffffff02ff3effff04ff02ffff04ff05ffff04ff0bffff04ff17ffff04ff2fffff04ff2fffff01ff80ff808080808080808080ff0bff32ffff0bff3cff2880ffff0bff32ffff0bff32ffff0bff3cff2280ff0580ffff0bff32ffff02ff2affff04ff02ffff04ff07ffff04ffff0bff3cff3c80ff8080808080ffff0bff3cff8080808080ffff02ffff03ffff07ff0580ffff01ff0bffff0102ffff02ff2effff04ff02ffff04ff09ff80808080ffff02ff2effff04ff02ffff04ff0dff8080808080ffff01ff0bffff0101ff058080ff0180ff02ffff03ff5fffff01ff02ffff03ffff09ff82011fff3880ffff01ff02ffff03ffff09ffff18ff82059f80ff3c80ffff01ff02ffff03ffff20ff81bf80ffff01ff02ff3effff04ff02ffff04ff05ffff04ff0bffff04ff17ffff04ff2fffff04ff81dfffff04ff82019fffff04ff82017fff80808080808080808080ffff01ff088080ff0180ffff01ff04ff819fffff02ff3effff04ff02ffff04ff05ffff04ff0bffff04ff17ffff04ff2fffff04ff81dfffff04ff81bfffff04ff82017fff808080808080808080808080ff0180ffff01ff02ffff03ffff09ff82011fff2c80ffff01ff02ffff03ffff20ff82017f80ffff01ff04ffff04ff24ffff04ffff0eff10ffff02ff2effff04ff02ffff04ff82019fff8080808080ff808080ffff02ff3effff04ff02ffff04ff05ffff04ff0bffff04ff17ffff04ff2fffff04ff81dfffff04ff81bfffff04ffff02ff0bffff04ff17ffff04ff2fffff04ff82019fff8080808080ff8080808080808080808080ffff01ff088080ff0180ffff01ff02ffff03ffff09ff82011fff2480ffff01ff02ffff03ffff20ffff02ffff03ffff09ffff0122ffff0dff82029f8080ffff01ff02ffff03ffff09ffff0cff82029fff80ffff010280ff1080ffff01ff0101ff8080ff0180ff8080ff018080ffff01ff04ff819fffff02ff3effff04ff02ffff04ff05ffff04ff0bffff04ff17ffff04ff2fffff04ff81dfffff04ff81bfffff04ff82017fff8080808080808080808080ffff01ff088080ff0180ffff01ff04ff819fffff02ff3effff04ff02ffff04ff05ffff04ff0bffff04ff17ffff04ff2fffff04ff81dfffff04ff81bfffff04ff82017fff808080808080808080808080ff018080ff018080ff0180ffff01ff02ff3affff04ff02ffff04ff05ffff04ff0bffff04ff81bfffff04ffff02ffff03ff82017fffff0182017fffff01ff02ff0bffff04ff17ffff04ff2fffff01ff808080808080ff0180ff8080808080808080ff0180ff018080ffff04ffff01a0c5abea79afaa001b5427dfa0c8cf42ca6f38f5841b78f9b3c252733eb2de2726ffff04ffff0180ffff04ffff01ff02ffff01ff02ffff01ff02ffff03ff81bfffff01ff04ff82013fffff04ff80ffff04ffff02ffff03ffff22ff82013fffff20ffff09ff82013fff2f808080ffff01ff04ffff04ff10ffff04ffff0bffff02ff2effff04ff02ffff04ff09ffff04ff8205bfffff04ffff02ff3effff04ff02ffff04ffff04ff09ffff04ff82013fff1d8080ff80808080ff808080808080ff1580ff808080ffff02ff16ffff04ff02ffff04ff0bffff04ff17ffff04ff8202bfffff04ff15ff8080808080808080ffff01ff02ff16ffff04ff02ffff04ff0bffff04ff17ffff04ff8202bfffff04ff15ff8080808080808080ff0180ff80808080ffff01ff04ff2fffff01ff80ff80808080ff0180ffff04ffff01ffffff3f02ff04ff0101ffff822710ff02ff02ffff03ff05ffff01ff02ff3affff04ff02ffff04ff0dffff04ffff0bff2affff0bff2cff1480ffff0bff2affff0bff2affff0bff2cff3c80ff0980ffff0bff2aff0bffff0bff2cff8080808080ff8080808080ffff010b80ff0180ffff02ffff03ff17ffff01ff04ffff04ff10ffff04ffff0bff81a7ffff02ff3effff04ff02ffff04ffff04ff2fffff04ffff04ff05ffff04ffff05ffff14ffff12ff47ff0b80ff128080ffff04ffff04ff05ff8080ff80808080ff808080ff8080808080ff808080ffff02ff16ffff04ff02ffff04ff05ffff04ff0bffff04ff37ffff04ff2fff8080808080808080ff8080ff0180ffff0bff2affff0bff2cff1880ffff0bff2affff0bff2affff0bff2cff3c80ff0580ffff0bff2affff02ff3affff04ff02ffff04ff07ffff04ffff0bff2cff2c80ff8080808080ffff0bff2cff8080808080ff02ffff03ffff07ff0580ffff01ff0bffff0102ffff02ff3effff04ff02ffff04ff09ff80808080ffff02ff3effff04ff02ffff04ff0dff8080808080ffff01ff0bffff0101ff058080ff0180ff018080ffff04ffff01ffa07faa3253bfddd1e0decb0906b2dc6247bbc4cf608f58345d173adb63e8b47c9fffa0e80321b0ec2100f6cae1541f315a150119752d3ab00e353daf0fe1c9364f3bbaa0eff07522495060c066f66f32acc2a77e3a3e737aca8baea4d1a64ea4cdc13da9ffff04ffff01a0fbd4fb435b0469dab9e992d51d6505cfd166060f6ffc2273b6ff824f9d4dd568ffff04ffff01820320ff0180808080ffff04ffff01ff02ffff01ff02ffff01ff02ffff03ff0bffff01ff02ffff03ffff09ff05ffff1dff0bffff1effff0bff0bffff02ff06ffff04ff02ffff04ff17ff8080808080808080ffff01ff02ff17ff2f80ffff01ff088080ff0180ffff01ff04ffff04ff04ffff04ff05ffff04ffff02ff06ffff04ff02ffff04ff17ff80808080ff80808080ffff02ff17ff2f808080ff0180ffff04ffff01ff32ff02ffff03ffff07ff0580ffff01ff0bffff0102ffff02ff06ffff04ff02ffff04ff09ff80808080ffff02ff06ffff04ff02ffff04ff0dff8080808080ffff01ff0bffff0101ff058080ff0180ff018080ffff04ffff01b0942ee5f33092840dc6d7c2377b7d6c3d5747ce60612d6b755b8b9cfa3faf81e9ba1153f6c2927b39e030c583794169b3ff018080ff018080808080ff018080808080ff01808080",
  "solution":
      "0xffffa0df11a60e60f02d6b6d1bc92899fa92ce9cd6841a43d97c0b029535124a0b4f6cffa01c39a4fe00d0c70824b1e24ef091aef7c8ed2e17b61d9cb510f2fa80cda8ffa8ff0180ff01ffffffff80ffff01ffff81f6ff80ff80ff8080ffff33ffa0fbd4fb435b0469dab9e992d51d6505cfd166060f6ffc2273b6ff824f9d4dd568ff01ffffa0fbd4fb435b0469dab9e992d51d6505cfd166060f6ffc2273b6ff824f9d4dd5688080ffff3cffa0ed166329e3f7cd671dd85fd70cb15ba46cbc3a9e9bbd81c643e75250fb2d9a8a8080ff8080808080"
};

late FullCoin fullCoin;
late FullNFTCoinInfo fullNFTCoinInfo;
Future<void> main() async {
  ChiaNetworkContextWrapper().registerNetworkContext(Network.testnet10);
  final mnemonic =
      'kitten seat dial receive water peasant obvious tuition rifle ethics often improve mutual invest gospel unaware cushion trigger credit scare critic edge digital valid'
          .split(' ');

  final keychainSecret = KeychainCoreSecret.fromMnemonic(mnemonic);
  final walletsSetList = <WalletSet>[];
  for (var i = 0; i < 5; i++) {
    final set1 = WalletSet.fromPrivateKey(keychainSecret.masterPrivateKey, i);
    walletsSetList.add(set1);
  }

  final keychain = WalletKeychain.fromWalletSets(walletsSetList);
  test('FulCoin Creation', () async {
    final coin = Coin.fromChiaCoinRecordJson(coinMap);
    final parentSpend = CoinSpend.fromJson(parentCoinSpendMap);
    fullCoin = FullCoin(coin: coin, parentCoinSpend: parentSpend);
    expect(fullCoin.type, SpendType.nft);
  });

  test('Creation of FullNFTCoinInfo for transfer', () async {
    final result = await NftWallet().getNFTFullCoinInfo(
      fullCoin,
      buildKeychain: (phs) async => keychain,
    );
    fullNFTCoinInfo = result.item1;
    final fullPuzzle = result.item2;

    final puzzleInfo = OuterPuzzleDriver.matchPuzzle(fullPuzzle);
    expect(puzzleInfo, isNotNull);
    final innerPuzzle =
        OuterPuzzleDriver.getInnerPuzzle(constructor: puzzleInfo!, puzzleReveal: fullPuzzle);
    expect(innerPuzzle, isNotNull);
    final p2Puzzlehash = innerPuzzle!.hash();
    final vector = keychain.getWalletVector(p2Puzzlehash);
    expect(vector, isNotNull);
  });

  test('Transfer nft', () async {
    // Creating new keychain
    final keychainSecret = KeychainCoreSecret.generate();
    final walletsSetList = <WalletSet>[];
    for (var i = 0; i < 1; i++) {
      final set = WalletSet.fromPrivateKey(keychainSecret.masterPrivateKey, i);
      walletsSetList.add(set);
    }

    final otherKeychain = WalletKeychain.fromWalletSets(walletsSetList);

    // get one puzzle hash for transfer the nft
    final targetPuzzleHash = otherKeychain.hardenedWalletVectors.first.puzzlehash;

    //Create the transfer bundle
    final transferBundle = NftWallet().createTransferSpendBundle(
        nftCoin: fullNFTCoinInfo.toNftCoinInfo(),
        keychain: keychain,
        targetPuzzleHash: targetPuzzleHash,
        standardCoinsForFee: [],
        fee: 0);

    print("coins additions = ${transferBundle.additions.length}");

    final newUserNftCoin = transferBundle.additions.first;
    CoinSpend? parentCoinSpend;
    for (var coinSpend in transferBundle.coinSpends) {
      if (newUserNftCoin.parentCoinInfo == coinSpend.coin.id) {
        parentCoinSpend = coinSpend;
        break;
      }
    }
    print("parentCoinSpend = ${parentCoinSpend?.toJson()}");
    expect(parentCoinSpend, isNotNull);
    final newNftFullCoin = FullCoin(
      coin: Coin(
        amount: newUserNftCoin.amount,
        coinbase: false,
        confirmedBlockIndex: 1,
        spentBlockIndex: 0,
        parentCoinInfo: newUserNftCoin.parentCoinInfo,
        puzzlehash: newUserNftCoin.puzzlehash,
        timestamp: 0,
      ),
      parentCoinSpend: parentCoinSpend,
    );

    final result = await NftWallet().getNFTFullCoinInfo(
      newNftFullCoin,
      buildKeychain: (phs) async => otherKeychain,
    );
    fullNFTCoinInfo = result.item1;
    final fullPuzzle = result.item2;

    final puzzleInfo = OuterPuzzleDriver.matchPuzzle(fullPuzzle);
    expect(puzzleInfo, isNotNull);
    final innerPuzzle =
        OuterPuzzleDriver.getInnerPuzzle(constructor: puzzleInfo!, puzzleReveal: fullPuzzle);
    expect(innerPuzzle, isNotNull);
    final p2Puzzlehash = innerPuzzle!.hash();
    expect(p2Puzzlehash.toHex(), targetPuzzleHash.toHex());
    final vector = otherKeychain.getWalletVector(p2Puzzlehash);
    expect(vector, isNotNull);
  });
}

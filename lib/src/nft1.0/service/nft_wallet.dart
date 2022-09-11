import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/core/models/conditions/announcement.dart';
import 'package:chia_crypto_utils/src/core/service/base_wallet.dart';
import 'package:tuple/tuple.dart';

import '../../core/exceptions/change_puzzlehash_needed_exception.dart';
import '../../core/service/conditions_utils.dart';

final spendtedBundle = SpendBundle.fromJson({
  'aggregated_signature':
      '0xb204952b92363f2a013083d303a087f5381daf7538e63d3153d0521434808528039505bdd0b998fcf1e1a1bb4b8bc53f0b33291654237ba8eb103e1aeb769a9b41d53e200415e02837a521c765f30d8b6ed0368cfdb6874b682b7ced36538992',
  'coin_spends': [
    {
      'coin': {
        'amount': 1,
        'parent_coin_info': '0x2ed4cc6c3d0be79b93624e4973869d469e9bf9daa28d6655927175e0ceda47f3',
        'puzzle_hash': '0x3e684896e768689d1e2d9b7d94cb4d8632090ae3fb8ed73c2f690f2c99442540'
      },
      'puzzle_reveal':
          '0xff02ffff01ff02ffff01ff02ffff03ffff18ff2fff3480ffff01ff04ffff04ff20ffff04ff2fff808080ffff04ffff02ff3effff04ff02ffff04ff05ffff04ffff02ff2affff04ff02ffff04ff27ffff04ffff02ffff03ff77ffff01ff02ff36ffff04ff02ffff04ff09ffff04ff57ffff04ffff02ff2effff04ff02ffff04ff05ff80808080ff808080808080ffff011d80ff0180ffff04ffff02ffff03ff77ffff0181b7ffff015780ff0180ff808080808080ffff04ff77ff808080808080ffff02ff3affff04ff02ffff04ff05ffff04ffff02ff0bff5f80ffff01ff8080808080808080ffff01ff088080ff0180ffff04ffff01ffffffff4947ff0233ffff0401ff0102ffffff20ff02ffff03ff05ffff01ff02ff32ffff04ff02ffff04ff0dffff04ffff0bff3cffff0bff34ff2480ffff0bff3cffff0bff3cffff0bff34ff2c80ff0980ffff0bff3cff0bffff0bff34ff8080808080ff8080808080ffff010b80ff0180ffff02ffff03ffff22ffff09ffff0dff0580ff2280ffff09ffff0dff0b80ff2280ffff15ff17ffff0181ff8080ffff01ff0bff05ff0bff1780ffff01ff088080ff0180ff02ffff03ff0bffff01ff02ffff03ffff02ff26ffff04ff02ffff04ff13ff80808080ffff01ff02ffff03ffff20ff1780ffff01ff02ffff03ffff09ff81b3ffff01818f80ffff01ff02ff3affff04ff02ffff04ff05ffff04ff1bffff04ff34ff808080808080ffff01ff04ffff04ff23ffff04ffff02ff36ffff04ff02ffff04ff09ffff04ff53ffff04ffff02ff2effff04ff02ffff04ff05ff80808080ff808080808080ff738080ffff02ff3affff04ff02ffff04ff05ffff04ff1bffff04ff34ff8080808080808080ff0180ffff01ff088080ff0180ffff01ff04ff13ffff02ff3affff04ff02ffff04ff05ffff04ff1bffff04ff17ff8080808080808080ff0180ffff01ff02ffff03ff17ff80ffff01ff088080ff018080ff0180ffffff02ffff03ffff09ff09ff3880ffff01ff02ffff03ffff18ff2dffff010180ffff01ff0101ff8080ff0180ff8080ff0180ff0bff3cffff0bff34ff2880ffff0bff3cffff0bff3cffff0bff34ff2c80ff0580ffff0bff3cffff02ff32ffff04ff02ffff04ff07ffff04ffff0bff34ff3480ff8080808080ffff0bff34ff8080808080ffff02ffff03ffff07ff0580ffff01ff0bffff0102ffff02ff2effff04ff02ffff04ff09ff80808080ffff02ff2effff04ff02ffff04ff0dff8080808080ffff01ff0bffff0101ff058080ff0180ff02ffff03ffff21ff17ffff09ff0bff158080ffff01ff04ff30ffff04ff0bff808080ffff01ff088080ff0180ff018080ffff04ffff01ffa07faa3253bfddd1e0decb0906b2dc6247bbc4cf608f58345d173adb63e8b47c9fffa04264c974a8e303453acf4951646a421f4eade51a6d6b8a321256d174b29ef0c1a0eff07522495060c066f66f32acc2a77e3a3e737aca8baea4d1a64ea4cdc13da9ffff04ffff01ff02ffff01ff02ffff01ff02ff3effff04ff02ffff04ff05ffff04ffff02ff2fff5f80ffff04ff80ffff04ffff04ffff04ff0bffff04ff17ff808080ffff01ff808080ffff01ff8080808080808080ffff04ffff01ffffff0233ff04ff0101ffff02ff02ffff03ff05ffff01ff02ff1affff04ff02ffff04ff0dffff04ffff0bff12ffff0bff2cff1480ffff0bff12ffff0bff12ffff0bff2cff3c80ff0980ffff0bff12ff0bffff0bff2cff8080808080ff8080808080ffff010b80ff0180ffff0bff12ffff0bff2cff1080ffff0bff12ffff0bff12ffff0bff2cff3c80ff0580ffff0bff12ffff02ff1affff04ff02ffff04ff07ffff04ffff0bff2cff2c80ff8080808080ffff0bff2cff8080808080ffff02ffff03ffff07ff0580ffff01ff0bffff0102ffff02ff2effff04ff02ffff04ff09ff80808080ffff02ff2effff04ff02ffff04ff0dff8080808080ffff01ff0bffff0101ff058080ff0180ff02ffff03ff0bffff01ff02ffff03ffff09ff23ff1880ffff01ff02ffff03ffff18ff81b3ff2c80ffff01ff02ffff03ffff20ff1780ffff01ff02ff3effff04ff02ffff04ff05ffff04ff1bffff04ff33ffff04ff2fffff04ff5fff8080808080808080ffff01ff088080ff0180ffff01ff04ff13ffff02ff3effff04ff02ffff04ff05ffff04ff1bffff04ff17ffff04ff2fffff04ff5fff80808080808080808080ff0180ffff01ff02ffff03ffff09ff23ffff0181e880ffff01ff02ff3effff04ff02ffff04ff05ffff04ff1bffff04ff17ffff04ffff02ffff03ffff22ffff09ffff02ff2effff04ff02ffff04ff53ff80808080ff82014f80ffff20ff5f8080ffff01ff02ff53ffff04ff818fffff04ff82014fffff04ff81b3ff8080808080ffff01ff088080ff0180ffff04ff2cff8080808080808080ffff01ff04ff13ffff02ff3effff04ff02ffff04ff05ffff04ff1bffff04ff17ffff04ff2fffff04ff5fff80808080808080808080ff018080ff0180ffff01ff04ffff04ff18ffff04ffff02ff16ffff04ff02ffff04ff05ffff04ff27ffff04ffff0bff2cff82014f80ffff04ffff02ff2effff04ff02ffff04ff818fff80808080ffff04ffff0bff2cff0580ff8080808080808080ff378080ff81af8080ff0180ff018080ffff04ffff01a0a04d9f57764f54a43e4030befb4d80026e870519aaa66334aef8304f5d0393c2ffff04ffff01ffff75ffc04868747470733a2f2f7261772e67697468756275736572636f6e74656e742e636f6d2f4d617276696e5175657665646f2f6e66745f66696c65732f6d61696e2f6f7a6f6e652e706e6780ffff68a01725145c0a007a82fd8d0993b57b94b656bb25951384a603b777b4833156e785ffff826d7580ffff826c7580ffff82736e01ffff8273740180ffff04ffff01a0fe8a4b4e27a2e29a4d3fc7ce9d527adbcaccbab6ada3903ccf3ba9a769d2d78bffff04ffff01ff02ffff01ff02ffff01ff02ff26ffff04ff02ffff04ff05ffff04ff17ffff04ff0bffff04ffff02ff2fff5f80ff80808080808080ffff04ffff01ffffff82ad4cff0233ffff3e04ff81f601ffffff0102ffff02ffff03ff05ffff01ff02ff2affff04ff02ffff04ff0dffff04ffff0bff32ffff0bff3cff3480ffff0bff32ffff0bff32ffff0bff3cff2280ff0980ffff0bff32ff0bffff0bff3cff8080808080ff8080808080ffff010b80ff0180ff04ffff04ff38ffff04ffff02ff36ffff04ff02ffff04ff05ffff04ff27ffff04ffff02ff2effff04ff02ffff04ffff02ffff03ff81afffff0181afffff010b80ff0180ff80808080ffff04ffff0bff3cff4f80ffff04ffff0bff3cff0580ff8080808080808080ff378080ff82016f80ffffff02ff3effff04ff02ffff04ff05ffff04ff0bffff04ff17ffff04ff2fffff04ff2fffff01ff80ff808080808080808080ff0bff32ffff0bff3cff2880ffff0bff32ffff0bff32ffff0bff3cff2280ff0580ffff0bff32ffff02ff2affff04ff02ffff04ff07ffff04ffff0bff3cff3c80ff8080808080ffff0bff3cff8080808080ffff02ffff03ffff07ff0580ffff01ff0bffff0102ffff02ff2effff04ff02ffff04ff09ff80808080ffff02ff2effff04ff02ffff04ff0dff8080808080ffff01ff0bffff0101ff058080ff0180ff02ffff03ff5fffff01ff02ffff03ffff09ff82011fff3880ffff01ff02ffff03ffff09ffff18ff82059f80ff3c80ffff01ff02ffff03ffff20ff81bf80ffff01ff02ff3effff04ff02ffff04ff05ffff04ff0bffff04ff17ffff04ff2fffff04ff81dfffff04ff82019fffff04ff82017fff80808080808080808080ffff01ff088080ff0180ffff01ff04ff819fffff02ff3effff04ff02ffff04ff05ffff04ff0bffff04ff17ffff04ff2fffff04ff81dfffff04ff81bfffff04ff82017fff808080808080808080808080ff0180ffff01ff02ffff03ffff09ff82011fff2c80ffff01ff02ffff03ffff20ff82017f80ffff01ff04ffff04ff24ffff04ffff0eff10ffff02ff2effff04ff02ffff04ff82019fff8080808080ff808080ffff02ff3effff04ff02ffff04ff05ffff04ff0bffff04ff17ffff04ff2fffff04ff81dfffff04ff81bfffff04ffff02ff0bffff04ff17ffff04ff2fffff04ff82019fff8080808080ff8080808080808080808080ffff01ff088080ff0180ffff01ff02ffff03ffff09ff82011fff2480ffff01ff02ffff03ffff20ffff02ffff03ffff09ffff0122ffff0dff82029f8080ffff01ff02ffff03ffff09ffff0cff82029fff80ffff010280ff1080ffff01ff0101ff8080ff0180ff8080ff018080ffff01ff04ff819fffff02ff3effff04ff02ffff04ff05ffff04ff0bffff04ff17ffff04ff2fffff04ff81dfffff04ff81bfffff04ff82017fff8080808080808080808080ffff01ff088080ff0180ffff01ff04ff819fffff02ff3effff04ff02ffff04ff05ffff04ff0bffff04ff17ffff04ff2fffff04ff81dfffff04ff81bfffff04ff82017fff808080808080808080808080ff018080ff018080ff0180ffff01ff02ff3affff04ff02ffff04ff05ffff04ff0bffff04ff81bfffff04ffff02ffff03ff82017fffff0182017fffff01ff02ff0bffff04ff17ffff04ff2fffff01ff808080808080ff0180ff8080808080808080ff0180ff018080ffff04ffff01a0c5abea79afaa001b5427dfa0c8cf42ca6f38f5841b78f9b3c252733eb2de2726ffff04ffff0180ffff04ffff01ff02ffff01ff02ffff01ff02ffff03ff81bfffff01ff04ff82013fffff04ff80ffff04ffff02ffff03ffff22ff82013fffff20ffff09ff82013fff2f808080ffff01ff04ffff04ff10ffff04ffff0bffff02ff2effff04ff02ffff04ff09ffff04ff8205bfffff04ffff02ff3effff04ff02ffff04ffff04ff09ffff04ff82013fff1d8080ff80808080ff808080808080ff1580ff808080ffff02ff16ffff04ff02ffff04ff0bffff04ff17ffff04ff8202bfffff04ff15ff8080808080808080ffff01ff02ff16ffff04ff02ffff04ff0bffff04ff17ffff04ff8202bfffff04ff15ff8080808080808080ff0180ff80808080ffff01ff04ff2fffff01ff80ff80808080ff0180ffff04ffff01ffffff3f02ff04ff0101ffff822710ff02ff02ffff03ff05ffff01ff02ff3affff04ff02ffff04ff0dffff04ffff0bff2affff0bff2cff1480ffff0bff2affff0bff2affff0bff2cff3c80ff0980ffff0bff2aff0bffff0bff2cff8080808080ff8080808080ffff010b80ff0180ffff02ffff03ff17ffff01ff04ffff04ff10ffff04ffff0bff81a7ffff02ff3effff04ff02ffff04ffff04ff2fffff04ffff04ff05ffff04ffff05ffff14ffff12ff47ff0b80ff128080ffff04ffff04ff05ff8080ff80808080ff808080ff8080808080ff808080ffff02ff16ffff04ff02ffff04ff05ffff04ff0bffff04ff37ffff04ff2fff8080808080808080ff8080ff0180ffff0bff2affff0bff2cff1880ffff0bff2affff0bff2affff0bff2cff3c80ff0580ffff0bff2affff02ff3affff04ff02ffff04ff07ffff04ffff0bff2cff2c80ff8080808080ffff0bff2cff8080808080ff02ffff03ffff07ff0580ffff01ff0bffff0102ffff02ff3effff04ff02ffff04ff09ff80808080ffff02ff3effff04ff02ffff04ff0dff8080808080ffff01ff0bffff0101ff058080ff0180ff018080ffff04ffff01ffa07faa3253bfddd1e0decb0906b2dc6247bbc4cf608f58345d173adb63e8b47c9fffa04264c974a8e303453acf4951646a421f4eade51a6d6b8a321256d174b29ef0c1a0eff07522495060c066f66f32acc2a77e3a3e737aca8baea4d1a64ea4cdc13da9ffff04ffff01a0f281dc1da8beccff00ebd713a8aa6bdca2addfedef5d11097120289031b83be3ffff04ffff0180ff0180808080ffff04ffff01ff02ffff01ff02ffff01ff02ffff03ff0bffff01ff02ffff03ffff09ff05ffff1dff0bffff1effff0bff0bffff02ff06ffff04ff02ffff04ff17ff8080808080808080ffff01ff02ff17ff2f80ffff01ff088080ff0180ffff01ff04ffff04ff04ffff04ff05ffff04ffff02ff06ffff04ff02ffff04ff17ff80808080ff80808080ffff02ff17ff2f808080ff0180ffff04ffff01ff32ff02ffff03ffff07ff0580ffff01ff0bffff0102ffff02ff06ffff04ff02ffff04ff09ff80808080ffff02ff06ffff04ff02ffff04ff0dff8080808080ffff01ff0bffff0101ff058080ff0180ff018080ffff04ffff01b0b3a7ef339349dc0f882da8ba8925a9572838dab661c86974ecbb001cb7b14a960798da6df8897b4b8f5d875d77ba781eff018080ff018080808080ff018080808080ff01808080',
      'solution':
          '0xffffa0f7ac6e5009338da5d49439e7e52eca769dfaf8bcd9d5d15d7ea42128b2e8360effa0ffd074d78953f2c00ce7535bd4b329f12eebe9a11b948cd9eda0c56ba4d9f8b5ff0180ff01ffffffff80ffff01ffff81f6ff80ff80ff8080ffff33ffa0a3489f29b0f64f6d17b6f5ab9d01ef2a5a13301007520022313c63c56cd3dea1ff01ffffa0a3489f29b0f64f6d17b6f5ab9d01ef2a5a13301007520022313c63c56cd3dea1808080ff8080808080'
    }
  ]
});

class NftWallet extends BaseWalletService {
  final StandardWalletService standardWalletService = StandardWalletService();

  SpendBundle createTransferSpendBundle({
    required NFTCoinInfo nftCoin,
    required WalletKeychain keychain,
    required Puzzlehash targetPuzzleHash,
    Puzzlehash? changePuzzlehash,
    int fee = 0,
    List<CoinPrototype>? standardCoinsForFee,
  }) {
    return generateSignedSpendBundle(
        payments: [
          Payment(
            nftCoin.coin.amount,
            targetPuzzleHash,
          )
        ],
        coins: [
          nftCoin.coin
        ],
        fee: fee,
        changePuzzlehash: changePuzzlehash,
        keychain: keychain,
        nftCoin: nftCoin,
        standardCoinsForFee: standardCoinsForFee,
        newOwner: null,
        newDidInnerhash: null);
  }

  SpendBundle generateSignedSpendBundle({
    required List<Payment> payments,
    required List<CoinPrototype> coins,
    List<CoinPrototype>? standardCoinsForFee,
    required WalletKeychain keychain,
    Puzzlehash? changePuzzlehash,
    List<AssertCoinAnnouncementCondition> coinAnnouncementsToAssert = const [],
    List<AssertPuzzleCondition> puzzleAnnouncementsToAssert = const [],
    int fee = 0,
    Bytes? newOwner,
    Bytes? newDidInnerhash,
    Program? tradePricesList,
    Map<String, String>? metadataUpdate,
    required NFTCoinInfo nftCoin,
    List<SpendBundle>? additionalBundles,
  }) {
    final generateSpendsTuple = generateUnsignedSpendbundle(
        payments: payments,
        coinsInput: coins,
        keychain: keychain,
        standardCoinsForFee: standardCoinsForFee,
        changePuzzlehash: changePuzzlehash,
        originId: nftCoin.nftId,
        nftCoin: nftCoin,
        fee: fee,
        coinAnnouncementsToAssert: coinAnnouncementsToAssert,
        puzzleAnnouncementsToAssert: puzzleAnnouncementsToAssert);

    var unsignedSpendBundle = generateSpendsTuple.item1;
    final chiaSpendBundle = generateSpendsTuple.item2;
    unsignedSpendBundle = SpendBundle(coinSpends: [
      CoinSpend(
          coin: unsignedSpendBundle.coinSpends.first.coin,
          puzzleReveal: spendtedBundle.coinSpends.first.puzzleReveal,
          solution: unsignedSpendBundle.coinSpends.first.solution)
    ]);
    SpendBundle spendBundle = _sign(
      unsignedSpendBundle: unsignedSpendBundle,
      keychain: keychain,
    );

    final spendBundle2 = spendtedBundle;

    standardWalletService.validateSpendBundle(spendBundle);
    standardWalletService.validateSpendBundle(spendBundle2);
    final spend1 = spendBundle.coinSpends.first;
    final spend2 = spendBundle2.coinSpends.first;

    final puz1 = spend1.puzzleReveal;
    final puz2 = spend2.puzzleReveal;

    print("spend bundles");
    print(spend1.toBytes().sha256Hash().toHex());
    print(spend2.toBytes().sha256Hash().toHex());

    print("puzzle reveal");
    print(spend1.puzzleReveal.toBytes().sha256Hash().toHex());
    print(spend2.puzzleReveal.toBytes().sha256Hash().toHex());

    print(spend1.puzzleReveal.toSource());
    print(spend2.puzzleReveal.toSource());
    standardWalletService.validateSpendBundleSignature(spendBundle);

    if (chiaSpendBundle != null) {
      spendBundle = spendBundle + chiaSpendBundle;
    }
    final spendBundleList = [spendBundle];

    spendBundleList.addAll(additionalBundles ?? []);

    return spendBundleList.fold<SpendBundle>(
      SpendBundle(coinSpends: []),
      (previousValue, element) => previousValue + element,
    );
  }

  SpendBundle _makeStandardSpendBundleForFee({
    required int fee,
    required List<CoinPrototype> standardCoins,
    required WalletKeychain keychain,
    required Puzzlehash? changePuzzlehash,
    List<AssertCoinAnnouncementCondition> coinAnnouncementsToAsset = const [],
  }) {
    assert(
      standardCoins.isNotEmpty,
      'If passing in a fee, you must also pass in standard coins to use for that fee.',
    );

    final totalStandardCoinsValue = standardCoins.fold(
      0,
      (int previousValue, standardCoin) => previousValue + standardCoin.amount,
    );
    assert(
      totalStandardCoinsValue >= fee,
      'Total value of passed in standad coins is not enough to cover fee.',
    );

    return standardWalletService.createSpendBundle(
      payments: [],
      coinsInput: standardCoins,
      changePuzzlehash: changePuzzlehash,
      keychain: keychain,
      fee: fee,
      coinAnnouncementsToAssert: coinAnnouncementsToAsset,
    );
  }

  Tuple2<SpendBundle, SpendBundle?> generateUnsignedSpendbundle({
    required List<Payment> payments,
    required List<CoinPrototype> coinsInput,
    required WalletKeychain keychain,
    Puzzlehash? changePuzzlehash,
    int fee = 0,
    Bytes? originId,
    List<AssertCoinAnnouncementCondition> coinAnnouncementsToAssert = const [],
    List<AssertPuzzleCondition> puzzleAnnouncementsToAssert = const [],
    required NFTCoinInfo nftCoin,
    List<CoinPrototype>? standardCoinsForFee,
    Map<String, String>? metadataUpdate,
  }) {
    // copy coins input since coins list is modified in this function
    final coins = List<CoinPrototype>.from(coinsInput);
    final totalCoinValue = coins.fold(0, (int previousValue, coin) => previousValue + coin.amount);

    final totalPaymentAmount = payments.fold(
      0,
      (int previousValue, payment) => previousValue + payment.amount,
    );
    final change = totalCoinValue - totalPaymentAmount - fee;

    if (changePuzzlehash == null && change > 0) {
      throw ChangePuzzlehashNeededException();
    }

    Set<Bytes> announcementsToMake = {};
    SpendBundle? feeSpendBundle;
    if (fee > 0) {
      announcementsToMake = {nftCoin.coin.id};
      feeSpendBundle = _makeStandardSpendBundleForFee(
          fee: fee,
          standardCoins: standardCoinsForFee!,
          keychain: keychain,
          changePuzzlehash: changePuzzlehash);

      // validateSpendBundleSignature(feeSpendBundle);
    }

    Program innerSol = BaseWalletService.makeSolution(
      primaries: payments,
      coinAnnouncements: announcementsToMake,
      coinAnnouncementsToAssert: coinAnnouncementsToAssert,
      puzzleAnnouncementsToAssert: puzzleAnnouncementsToAssert,
    );

    final unft = UncurriedNFT.uncurry(nftCoin.fullPuzzle);
    Program? magicCondition;

    if (unft.supportDid) {
      // TODO support for did
      /**
       * 
       *   if new_owner is None:
                # If no new owner was specified and we're sending this to ourselves, let's not reset the DID
                derivation_record: Optional[
                    DerivationRecord
                ] = await self.wallet_state_manager.puzzle_store.get_derivation_record_for_puzzle_hash(
                    payments[0].puzzle_hash
                )
                if derivation_record is not None:
                    new_owner = unft.owner_did
            magic_condition = Program.to([-10, new_owner, trade_prices_list, new_did_inner_hash])
      */
    }
    if (metadataUpdate != null) {
      final metadataUpdateListP = <Program>[];
      metadataUpdate.forEach((key, value) {
        metadataUpdateListP.add(Program.cons(
            Program.fromBytes(Bytes.fromHex(key)), Program.fromBytes(Bytes.fromHex(value))));
      });
      magicCondition = Program.list([
        Program.fromInt(-24),
        NFT_METADATA_UPDATER,
        Program.list(metadataUpdateListP),
      ]);
    }

    if (magicCondition != null) {
      innerSol = Program.list([
        Program.list([]),
        Program.cons(
          Program.fromInt(1),
          Program.cons(
            magicCondition.first(),
            innerSol.filterAt("rfr"),
          ),
        ),
        Program.list([]),
      ]);
    }
    if (unft.supportDid) {
      innerSol = Program.list([innerSol]);
    }

    final nftLayerSolution = Program.list([innerSol]);
    final lineageProof = nftCoin.lineageProof;
    if (lineageProof == null) {
      throw Exception("nftCoin.lineageProo can't be null");
    }

    final singletonSolution = Program.list([
      lineageProof.toProgram(),
      Program.fromInt(nftCoin.coin.amount),
      nftLayerSolution,
    ]);

    final coinSpend = CoinSpend(
      coin: nftCoin.coin,
      puzzleReveal: nftCoin.fullPuzzle,
      solution: singletonSolution,
    );
    SpendBundle nftSpendBundle = SpendBundle(
      coinSpends: [
        coinSpend,
      ],
    );

    return Tuple2(nftSpendBundle, feeSpendBundle);
  }

  SpendBundle _sign(
      {required SpendBundle unsignedSpendBundle,
      required WalletKeychain keychain,
      List<Puzzlehash>? puzzleHash}) {
    final signatures = <JacobianPoint>[];

    final puzzleHashList = puzzleHash ?? [];
    final keys = <Bytes, PrivateKey>{};

    for (final coinSpend in unsignedSpendBundle.coinSpends) {
      if (puzzleHashList.isEmpty) {
        final uncurried_nft = UncurriedNFT.tryUncurry(coinSpend.puzzleReveal);
        if (uncurried_nft != null) {
          print("Found a NFT state layer to sign");
          puzzleHashList.add(uncurried_nft.p2Puzzle.hash());
        }
      }
      for (final ph in puzzleHashList) {
        final coinWalletVector = keychain.getWalletVector(ph);

        final coinPrivateKey = coinWalletVector!.childPrivateKey;
        keys[coinPrivateKey.getG1().toBytes()] = coinPrivateKey;

        final synthSecretKey = calculateSyntheticPrivateKey(coinPrivateKey);
        keys[synthSecretKey.getG1().toBytes()] = synthSecretKey;
      }

      /*      final coinWalletVector = keychain.getWalletVector(puzzleHashList.first);
      final coinPrivateKey = coinWalletVector!.childPrivateKey;
      final signature1 = makeSignature(coinPrivateKey, coinSpend);
      signatures.add(signature1);
 */
      final conditionsResult = conditionsDictForSolution(
        puzzleReveal: coinSpend.puzzleReveal,
        solution: coinSpend.solution,
      );
      if (conditionsResult.item2 != null) {
        final pairs = pkmPairsForConditionsDict(
          conditionsDict: conditionsResult.item2!,
          additionalData: Bytes.fromHex(
            this.blockchainNetwork.aggSigMeExtraData,
          ),
          coinName: coinSpend.coin.id,
        );

        for (final pair in pairs) {
          final pk = pair.item1;
          final msg = pair.item2;
          try {
            final sk = keys[pk];
            if (sk != null) {
              final signature = AugSchemeMPL.sign(sk, msg);
              signatures.add(signature);
            } else {
              print("Cant foun sk for ${pk}");
            }
          } catch (e) {
            throw Exception("This spend bundle cannot be signed by the NFT wallet");
          }
        }
      }
    }

    final aggregatedSignature = AugSchemeMPL.aggregate(signatures);

    return unsignedSpendBundle.addSignature(aggregatedSignature);
  }

// generate_new_nft

  SpendBundle generateNewNft(
      {required List<CoinPrototype> coins,
      required WalletKeychain keychain,
      Puzzlehash? changePuzzlehash,
      required Program metadata,
      required Puzzlehash targetPuzzleHash,
      Puzzlehash? royaltyPuzzleHash,
      int percentage = 0,
      Puzzlehash? didId,
      int fee = 0}) {
    final amount = 1;
    final origin = coins.toList().first;
    // final genesisLauncherPuzz = LAUNCHER_PUZZLE;

    final launcherCoin = CoinPrototype(
      parentCoinInfo: origin.id,
      puzzlehash: LAUNCHER_PUZZLE_HASH,
      amount: amount,
    );

    print("Generating NFT with launcher coin %s and metadata:  ${launcherCoin}, ${metadata}");

    late Program innerPuzzle;

    final targetWalletVector = keychain.getWalletVector(targetPuzzleHash);
    final p2InnerPuzzle = getPuzzleFromPk(targetWalletVector!.childPublicKey);
    print("Attempt to generate a new NFT to ${targetPuzzleHash.toHex()}");
    if (didId != null) {
      innerPuzzle = NftService.createOwnwershipLayerPuzzle(
        nftId: origin.id,
        didId: didId,
        p2Puzzle: p2InnerPuzzle,
        percentage: percentage,
        royaltyPuzzleHash: royaltyPuzzleHash,
      );
    } else {
      innerPuzzle = p2InnerPuzzle;
    }

    final eveFullPuz = NftService.createFullPuzzle(
      singletonId: origin.id,
      metadata: metadata,
      metadataUpdaterHash: NFT_METADATA_UPDATER_HAHS,
      innerPuzzle: innerPuzzle,
    );

    final announcementMessage = Program.list([
      Program.fromBytes(eveFullPuz.hash()),
      Program.fromInt(amount),
      Program.list([]),
    ]).hash();
    final assertCoinAnnouncement =
        AssertCoinAnnouncementCondition(launcherCoin.id, announcementMessage);

    final createLauncherSpendBundle = standardWalletService.createSpendBundle(
      payments: [Payment(launcherCoin.amount, launcherCoin.puzzlehash)],
      coinsInput: coins,
      keychain: keychain,
      changePuzzlehash: changePuzzlehash,
      originId: origin.id,
      fee: fee,
      coinAnnouncementsToAssert: [assertCoinAnnouncement],
    );

    final genesisLauncherSolution = Program.list([
      Program.fromBytes(eveFullPuz.hash()),
      Program.fromInt(launcherCoin.amount),
      Program.list([]),
    ]);
    final launcherCoinSpend = CoinSpend(
      coin: launcherCoin,
      puzzleReveal: LAUNCHER_PUZZLE,
      solution: genesisLauncherSolution,
    );

    final launcherSpendBundle = SpendBundle(coinSpends: [launcherCoinSpend]);
    final eveCoin = CoinPrototype(
      amount: amount,
      parentCoinInfo: launcherCoin.id,
      puzzlehash: eveFullPuz.hash(),
    );

    final bundlesToAgg = createLauncherSpendBundle + launcherSpendBundle;

    Bytes? didInnerHash;

    if (didId != null && didId.isNotEmpty) {
      // did_inner_hash, did_bundle = await self.get_did_approval_info(launcher_coin.name())
      //bundles_to_agg.append(did_bundle)
      // TODO: implement DID
    }

    final nftCoin = NFTCoinInfo(
      nftId: launcherCoin.id,
      coin: eveCoin,
      fullPuzzle: eveFullPuz,
      mintHeight: 0,
      latestHeight: 0,
      lineageProof: LineageProof(parentName: launcherCoin.id, amount: launcherCoin.amount),
      pendingTransaction: true,
    );

    final signedSpendBundle = generateSignedSpendBundle(
      payments: [
        Payment(eveCoin.amount, targetPuzzleHash, memos: [targetPuzzleHash])
      ],
      coins: coins,
      keychain: keychain,
      nftCoin: nftCoin,
      newOwner: didId,
      additionalBundles: [bundlesToAgg],
      newDidInnerhash: didInnerHash,
    );
    return signedSpendBundle;
  }
}

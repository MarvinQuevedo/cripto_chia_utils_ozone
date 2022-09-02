import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/core/service/base_wallet.dart';
import 'package:tuple/tuple.dart';

import '../../core/exceptions/change_puzzlehash_needed_exception.dart';
import '../index.dart';

class Nft1Wallet extends BaseWalletService {
  final StandardWalletService standardWalletService = StandardWalletService();
  Tuple2<SpendBundle, SpendBundle?> generateUnsignedSpendBundle({
    required List<Payment> payments,
    required List<CoinPrototype> coins,
    required WalletKeychain keychain,
    Puzzlehash? changePuzzlehash,
    List<Coin> standardCoinsForFee = const [],
    List<AssertCoinAnnouncementCondition> coinAnnouncementsToAssert = const [],
    List<AssertPuzzleAnnouncementCondition> puzzleAnnouncementsToAssert = const [],
    int fee = 0,
    Bytes? newOwner,
    Bytes? newDidInnerhash,
    Program? tradePricesList,
    Map<String, String>? metadataUpdate,
    required NFTCoinInfo nftCoin,
  }) {
    // copy coins input since coins list is modified in this function

    final totalCoinValue = coins.fold(0, (int previousValue, coin) => previousValue + coin.amount);

    final totalPaymentAmount = payments.fold(
      0,
      (int previousValue, payment) => previousValue + payment.amount,
    );
    final change = totalCoinValue - totalPaymentAmount - fee;

    if (changePuzzlehash == null && change > 0) {
      throw ChangePuzzlehashNeededException();
    }

    final coin = coins.first;

    AssertCoinAnnouncementCondition? primaryAssertCoinAnnouncement;
    SpendBundle? feeStandardSpendBundle;
    final conditions = <Condition>[];
    final createdCoins = <CoinPrototype>[];

    for (final payment in payments) {
      final sendCreateCoinCondition = payment.toCreateCoinCondition();
      conditions.add(sendCreateCoinCondition);
      createdCoins.add(
        CoinPrototype(
          parentCoinInfo: nftCoin.coin.id,
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
      feeStandardSpendBundle = _makeStandardSpendBundleForFee(
        fee: fee,
        standardCoins: standardCoinsForFee,
        keychain: keychain,
        changePuzzlehash: changePuzzlehash,
      );
    }

    conditions
      ..addAll(coinAnnouncementsToAssert)
      ..addAll(puzzleAnnouncementsToAssert);

    final existingCoinsMessage = coins.fold(
      Bytes.empty,
      (Bytes previousValue, coin) => previousValue + coin.id,
    );
    final createdCoinsMessage = createdCoins.fold(
      Bytes.empty,
      (Bytes previousValue, coin) => previousValue + coin.id,
    );
    final message = (existingCoinsMessage + createdCoinsMessage).sha256Hash();
    conditions.add(CreateCoinAnnouncementCondition(message));

    //primaryAssertCoinAnnouncement = AssertCoinAnnouncementCondition(coin.id, message);

    Program innerSol = BaseWalletService.makeSolutionFromConditions(conditions);
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
    if (!(nftCoin.lineageProof is LineageProof)) {
      throw Exception("nftCoin.lineageProo can't be null");
    }
    final singletonSolution = Program.list([
      nftCoin.lineageProof!.toProgram(),
      Program.fromInt(nftCoin.coin.amount),
      nftLayerSolution
    ]);

    final coinSpend = CoinSpend(
      coin: nftCoin.coin,
      puzzleReveal: nftCoin.fullPuzzle,
      solution: singletonSolution,
    );
    final nftSpendBundle = SpendBundle(
      coinSpends: [coinSpend],
    );

    return Tuple2(nftSpendBundle, feeStandardSpendBundle);
  }

  SpendBundle _makeStandardSpendBundleForFee({
    required int fee,
    required List<Coin> standardCoins,
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
}

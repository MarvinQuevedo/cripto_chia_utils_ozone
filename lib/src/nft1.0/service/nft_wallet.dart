import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/core/service/base_wallet.dart';

import '../index.dart';

class Nft1Wallet extends BaseWalletService {
  final StandardWalletService standardWalletService = StandardWalletService();

  SpendBundle createTransferSpendBundle({
    required NFTCoinInfo nftCoin,
    required WalletKeychain keychain,
    required Puzzlehash targetPuzzleHash,
    Puzzlehash? changePuzzlehash,
    int fee = 0,
    List<Coin>? standardCoinsForFee,
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
        keychain: keychain,
        nftCoin: nftCoin,
        standardCoinsForFee: standardCoinsForFee,
        newOwner: null,
        newDidInnerhash: null);
  }

  SpendBundle generateSignedSpendBundle({
    required List<Payment> payments,
    required List<CoinPrototype> coins,
    List<Coin>? standardCoinsForFee,
    required WalletKeychain keychain,
    Puzzlehash? changePuzzlehash,
    List<AssertCoinAnnouncementCondition> coinAnnouncementsToAssert = const [],
    List<AssertPuzzleAnnouncementCondition> puzzleAnnouncementsToAssert = const [],
    int fee = 0,
    Bytes? newOwner,
    Bytes? newDidInnerhash,
    Program? tradePricesList,
    Map<String, String>? metadataUpdate,
    required NFTCoinInfo nftCoin,
    List<SpendBundle>? additionalBundles,
  }) {
    // copy coins input since coins list is modified in this function
    SpendBundle? feeSpendBundle;
    if (fee > 0) {
      final announcementMessage = nftCoin.coin.id;

      final assertCoinAnnouncement = AssertCoinAnnouncementCondition(
        nftCoin.coin.id,
        announcementMessage,
      );
      coinAnnouncementsToAssert.add(assertCoinAnnouncement);
      feeSpendBundle = _makeStandardSpendBundleForFee(
        fee: fee,
        standardCoins: standardCoinsForFee!,
        keychain: keychain,
        changePuzzlehash: changePuzzlehash,
        coinAnnouncementsToAsset: [assertCoinAnnouncement],
      );
    }

    final createLauncherSpendBundle = standardWalletService.createSpendBundle(
        payments: payments,
        coinsInput: coins,
        keychain: keychain,
        changePuzzlehash: changePuzzlehash,
        originId: nftCoin.nftId,
        fee: fee,
        coinAnnouncementsToAssert: coinAnnouncementsToAssert,
        puzzleAnnouncementsToAssert: puzzleAnnouncementsToAssert);

    Program innerSol = createLauncherSpendBundle.coinSpends.first.solution;
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
    SpendBundle nftSpendBundle = SpendBundle(
      coinSpends: [coinSpend],
    );

    if (feeSpendBundle != null) {
      nftSpendBundle = nftSpendBundle + feeSpendBundle;
    }

    return nftSpendBundle;
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

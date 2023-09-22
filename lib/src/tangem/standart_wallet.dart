// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/standard/exceptions/spend_bundle_validation/incorrect_announcement_id_exception.dart';
import 'package:chia_crypto_utils/src/standard/exceptions/spend_bundle_validation/multiple_origin_coin_exception.dart';
import 'package:chia_crypto_utils/src/standard/puzzles/p2_delegated/p2_delegated_conditions.clvm.hex.dart';

class TangemStandardWalletService extends BaseWalletService {
  SpendBundle createSpendBundle({
    required List<Payment> payments,
    required List<CoinPrototype> coinsInput,
    required WalletKeychain keychain,
    Puzzlehash? changePuzzlehash,
    int fee = 0,
    Bytes? originId,
    List<AssertCoinAnnouncementCondition> coinAnnouncementsToAssert = const [],
    List<AssertPuzzleCondition> puzzleAnnouncementsToAssert = const [],
  }) {
    return createSpendBundleBase(
      payments: payments,
      coinsInput: coinsInput,
      changePuzzlehash: changePuzzlehash,
      fee: fee,
      originId: originId,
      coinAnnouncementsToAssert: coinAnnouncementsToAssert,
      puzzleAnnouncementsToAssert: puzzleAnnouncementsToAssert,
      makePuzzleRevealFromPuzzlehash: (puzzlehash) {
        final walletVector = keychain.getWalletVector(puzzlehash);
        final publicKey = walletVector!.childPublicKey;
        return puzzleForPk(publicKey);
      },
      makeSignatureForCoinSpend: (coinSpend) {
        final walletVector = keychain.getWalletVector(coinSpend.coin.puzzlehash);
        return makeSignature(walletVector!.childPrivateKey, coinSpend);
      },
    );
  }

  void validateSpendBundle(SpendBundle spendBundle) {
    validateSpendBundleSignature(spendBundle);

    // validate assert_coin_announcement if it is created (if there are multiple coins spent)
    Bytes? actualAssertCoinAnnouncementId;
    final coinsToCreate = <CoinPrototype>[];
    final coinsBeingSpent = <CoinPrototype>[];
    Bytes? originId;
    for (final spend in spendBundle.coinSpends) {
      final outputConditions = spend.puzzleReveal.run(spend.solution).program.toList();

      // look for assert coin announcement condition
      final assertCoinAnnouncementPrograms =
          outputConditions.where(AssertCoinAnnouncementCondition.isThisCondition).toList();
      if (assertCoinAnnouncementPrograms.length == 1 && actualAssertCoinAnnouncementId == null) {
        actualAssertCoinAnnouncementId =
            AssertCoinAnnouncementCondition.getAnnouncementIdFromProgram(
          assertCoinAnnouncementPrograms[0],
        );
      }

      // find create_coin conditions
      final coinCreationConditions = outputConditions
          .where(CreateCoinCondition.isThisCondition)
          .map(CreateCoinCondition.fromProgram)
          .toList();

      if (coinCreationConditions.isNotEmpty) {
        // if originId is already set, multiple coins are creating output which is invalid
        if (originId != null) {
          throw MultipleOriginCoinsException();
        }
        originId = spend.coin.id;
      }
      for (final coinCreationCondition in coinCreationConditions) {
        coinsToCreate.add(
          CoinPrototype(
            parentCoinInfo: spend.coin.id,
            puzzlehash: coinCreationCondition.destinationPuzzlehash,
            amount: coinCreationCondition.amount,
          ),
        );
      }
      coinsBeingSpent.add(spend.coin);
    }
    // check for duplicate coins
    BaseWalletService.checkForDuplicateCoins(coinsToCreate);
    BaseWalletService.checkForDuplicateCoins(coinsBeingSpent);

    if (spendBundle.coinSpends.length > 1) {
      assert(
        actualAssertCoinAnnouncementId != null,
        'No assert_coin_announcement condition when multiple spends',
      );
      assert(originId != null, 'No create_coin conditions');

      // construct assert_coin_announcement id from spendbundle, verify against output

      final existingCoinsMessage = coinsBeingSpent.fold(
        Bytes.empty,
        (Bytes previousValue, coin) => previousValue + coin.id,
      );

      final createdCoinsMessage = coinsToCreate.fold(
        Bytes.empty,
        (Bytes previousValue, coin) => previousValue + coin.id,
      );

      final message = (existingCoinsMessage + createdCoinsMessage).sha256Hash();
      final constructedAnnouncementId = (originId! + message).sha256Hash();

      if (constructedAnnouncementId != actualAssertCoinAnnouncementId) {
        throw IncorrectAnnouncementIdException();
      }
    }
  }

  List<FullCoin> convertXchCoinsToFull(List<Coin> coins) {
    return coins
        .map((coin) => FullCoin(
              coin: coin,
              parentCoinSpend: null,
            ))
        .toList();
  }

  SpendBundle createFeeSpendBundle({
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

    return createSpendBundle(
      payments: [],
      coinsInput: standardCoins,
      changePuzzlehash: changePuzzlehash,
      keychain: keychain,
      fee: fee,
      coinAnnouncementsToAssert: coinAnnouncementsToAsset,
    );
  }
}

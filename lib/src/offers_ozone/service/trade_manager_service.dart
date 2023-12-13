import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'package:tuple/tuple.dart';

import '../../cat/index.dart';
import '../../clvm.dart';
import '../../context/index.dart';
import '../../core/index.dart';
import '../../nft1.0/index.dart';
import '../../standard/index.dart';
import '../../tangem/cat_wallet.dart';
import '../../tangem/nft_wallet.dart';
import '../../tangem/standart_wallet.dart';
import '../../utils.dart';
import '../index.dart';
import '../utils/build_keychain.dart';

class TradeManagerService extends BaseWalletService {
  final StandardWalletService standardWalletService = StandardWalletService();
  final catWallet = CatWalletService();

  /// `generate_secure_bundle` simulates a wallet's `generate_signed_transaction`
  /// but doesn't bother with non-offer announcements
  Tuple2<Offer, SignatureHashes?> createOfferBundle({
    required Map<OfferAssetData?, List<FullCoin>> selectedCoins,
    required List<AssertPuzzleCondition> announcements,
    required Map<Bytes?, int> offeredAmounts,
    required WalletKeychain keychain,
    required int fee,
    required Puzzlehash changePuzzlehash,
    required Map<Bytes, PuzzleInfo> driverDict,
    required Map<Bytes?, List<NotarizedPayment>> notarizedPayments,
    required bool old,
    required List<SpendBundle> extraSpendBundles,
  }) {
    final isTangem = keychain.isTangem;
    final unsigned = keychain.unsigned;
    final signatureHashes = SignatureHashes();
    final transactions = <SpendBundle>[];

    transactions.addAll(extraSpendBundles);

    int feeLeftToPay = fee;
    List<Coin> xchCoins = (selectedCoins[null] ?? []).map((e) => e.toCoin()).toList();

    List<MapEntry<Bytes?, int>> entries = offeredAmounts.entries.toList();
    entries.sort((a, b) {
      if (a.key == null && b.key == null) {
        return 0;
      } else if (a.key == null) {
        return -1;
      } else if (b.key == null) {
        return 1;
      } else {
        return 0;
      }
    });

    LinkedHashMap<Bytes?, int> sortedOfferedAmounts = LinkedHashMap.fromEntries(entries);

    sortedOfferedAmounts.forEach((assetId, amount) {
      if (assetId == null) {
        final wallet = isTangem ? TangemStandardWalletService() : StandardWalletService();
        final standarBundle = wallet.createSpendBundle(
          payments: [
            Payment(offeredAmounts[assetId]!.abs(), Offer.ph(old)),
          ],
          coinsInput: xchCoins,
          keychain: keychain,
          fee: feeLeftToPay,
          puzzleAnnouncementsToAssert: announcements,
          changePuzzlehash: changePuzzlehash,
          unsigned: unsigned,
        );
        transactions.add(standarBundle.item1);
        signatureHashes.aggregate(standarBundle.item2);
        feeLeftToPay = 0;
        xchCoins = [];
      } else {
        bool isCat = driverDict[assetId]!.type == AssetType.CAT;

        if (isCat) {
          final catPayments = [
            Payment(offeredAmounts[assetId]!.abs(), Offer.ph(old), memos: <Bytes>[
              Offer.ph(old).toBytes(),
            ]),
          ];
          final catCoins = selectedCoins[OfferAssetData.cat(tailHash: assetId)]!
              .map((e) => e.toCatCoin())
              .toList();
          var standardsCoins = <Coin>[];
          if (feeLeftToPay > 0) {
            standardsCoins = xchCoins;
          }
          final wallet = isTangem ? TangemCatWalletService() : CatWalletService();
          final catBundle = wallet.createSpendBundle(
            payments: catPayments,
            catCoinsInput: catCoins,
            keychain: keychain,
            fee: feeLeftToPay,
            standardCoinsForFee: standardsCoins,
            puzzleAnnouncementsToAssert: announcements,
            changePuzzlehash: changePuzzlehash,
            unsigned: unsigned,
          );
          final catBytes = catBundle.item1.toBytes();
          final _ = SpendBundle.fromBytes(catBytes);
          transactions.add(catBundle.item1);
          signatureHashes.aggregate(catBundle.item2);
          feeLeftToPay = 0;
        } else {
          throw Exception("Not implemented for ${driverDict[assetId]?.type}}");
        }
      }
    });

    final totalSpendBundle = transactions.fold<SpendBundle>(
      SpendBundle(coinSpends: []),
      (previousValue, spendBundle) => previousValue + spendBundle,
    );

    return Tuple2(
      Offer(
        requestedPayments: notarizedPayments,
        bundle: totalSpendBundle,
        driverDict: driverDict,
        old: old,
      ),
      signatureHashes,
    );
  }

  Tuple2<Offer, SignatureHashes?> createOfferForIds({
    required Map<OfferAssetData?, List<FullCoin>> coins,
    required Map<Bytes, PuzzleInfo> driverDict,
    required Map<Bytes?, List<Payment>> requiredPayments,
    required Map<Bytes?, int> offeredAmounts,
    int fee = 0,
    validateOnly = false,
    required Puzzlehash changePuzzlehash,
    required WalletKeychain keychain,
    required bool old,
    required List<SpendBundle> extraSpendBundles,
  }) {
    final chiaRequestedPayments = requiredPayments;
    final coinsList = coins.values.expand((element) => element).toList();
    final chiaNotariedPayments = Offer.notarizePayments(
      requestedPayments: chiaRequestedPayments,
      coins: coinsList,
    );
    final chiaAnnouncements = Offer.calculateAnnouncements(
      notarizedPayment: chiaNotariedPayments,
      driverDict: driverDict,
      old: old,
    );

    final chiaOffer = createOfferBundle(
      announcements: chiaAnnouncements,
      offeredAmounts: offeredAmounts,
      selectedCoins: coins,
      fee: fee,
      changePuzzlehash: changePuzzlehash,
      keychain: keychain,
      notarizedPayments: chiaNotariedPayments,
      driverDict: driverDict,
      old: old,
      extraSpendBundles: extraSpendBundles,
    );

    return chiaOffer;
  }

  Future<Map<OfferAssetData?, List<FullCoin>>> prepareFullCoins(
    List<FullCoin> coins, {
    required BuildKeychain? buildKeychain,
    required bool isTangem,
    required bool unsigned,
  }) async {
    final groupedCoins = <OfferAssetData?, List<FullCoin>>{};
    for (final coin in coins) {
      final assetData = OfferAssetData.fromFullCoin(coin);
      if (assetData?.type == SpendType.nft) {
        final FullNFTCoinInfo nftCoin = await constructFullNftCoin(
          fullCoin: coin,
          buildKeychain: buildKeychain,
          isTangem: isTangem,
          unsigned: unsigned,
        );
        final nftAssetData = OfferAssetData.singletonNft(
          launcherPuzhash: nftCoin.launcherId,
        );
        groupedCoins[nftAssetData] ??= [];
        groupedCoins[nftAssetData]!.add(nftCoin);
      } else if (assetData?.type == SpendType.cat2) {
        groupedCoins[assetData] ??= [];
        groupedCoins[assetData]!.add(coin);
      } else {
        groupedCoins[null] ??= [];
        groupedCoins[null]!.add(coin);
      }
    }
    return groupedCoins;
  }

  int? calculateRoyalty(PuzzleInfo puzzleInfo) {
    bool isRoyalty = puzzleInfo.checkType(types: [
      AssetType.SINGLETON,
      AssetType.METADATA,
      AssetType.OWNERSHIP,
    ]);

    if (isRoyalty) {
      var transferInfo = puzzleInfo.also!.also!;
      var royaltyPercentageRaw = transferInfo["transfer_program"]["royalty_percentage"];
      if (royaltyPercentageRaw == null) {
        throw Exception("Royalty percentage is not found in the transfer program");
      }
      // clvm encodes large ints as bytes

      if (royaltyPercentageRaw is Bytes) {
        return bytesToInt(royaltyPercentageRaw, Endian.big);
      } else if (royaltyPercentageRaw is int) {
        return royaltyPercentageRaw;
      } else {
        return int.parse(royaltyPercentageRaw as String);
      }
    }
    return null;
  }

  static int calculateRoyaltyAmount({required int fungibleAmount, required int percentageRaw}) {
    return (fungibleAmount.abs() * (percentageRaw / 10000)).floor();
  }

  Future<AnalizedOffer?> analizeOffer({
    required int fee,
    required Puzzlehash targetPuzzleHash,
    required Puzzlehash changePuzzlehash,
    required Offer offer,
  }) async {
    final isOld = offer.old;

    final takeOfferDict = <Bytes?, int>{};
    Map<OfferAssetData?, int> offerredAmounts = {};
    int? royaltyPercentage;
    Map<Bytes?, int?>? royaltyAmounts;

    final arbitrage = offer.arbitrage();
    final offerDriverDict = offer.driverDict;

    final offerRequestedAmounts = <Bytes?, int>{};
    final fungibleAssetAmount = <Bytes?, int>{};

    arbitrage.forEach((assetId, amount) {
      if (amount < 0) {
        offerRequestedAmounts[assetId] = amount.abs();
        if (assetId != null) {
          final type = offerDriverDict[assetId]!.type;
          if (type == AssetType.CAT) {
            fungibleAssetAmount[assetId] = amount.abs();
          }
        } else {
          fungibleAssetAmount[null] = amount.abs();
        }
      }
    });

    offerRequestedAmounts.forEach((assetId, amount) {
      takeOfferDict[assetId] = -(amount.abs());

      if (assetId == null) {
        final totalChia = amount;
        offerredAmounts[OfferAssetData.standart()] = -(totalChia.abs());
      } else {
        final assetType = offerDriverDict[assetId]!.type;
        if (assetType == AssetType.CAT) {
          final totalCat = amount;
          offerredAmounts[OfferAssetData.cat(tailHash: assetId)] = -(totalCat.abs());
        } else if (assetType == AssetType.SINGLETON) {
          royaltyPercentage = royaltyPercentage ?? calculateRoyalty(offerDriverDict[assetId]!);

          offerredAmounts[OfferAssetData.singletonNft(launcherPuzhash: assetId)] = -(amount.abs());
        }
      }
    });

    final offerOfferedAmounts = offer.getOfferedAmounts();
    Map<OfferAssetData?, List<int>> requestedAmounts = {};
    final payments = <Bytes?, List<Payment>>{};
    offerOfferedAmounts.forEach((assetId, amount) {
      if (payments[assetId] == null) {
        payments[assetId] = [];
      }
      payments[assetId]!.add(
        Payment(amount.abs(), targetPuzzleHash),
      );
      if (assetId == null) {
        fungibleAssetAmount[assetId] = amount.abs();
        requestedAmounts[OfferAssetData.standart()] = [amount.abs()];
      } else {
        final assetType = offerDriverDict[assetId]!.type;
        if (assetType == AssetType.CAT) {
          fungibleAssetAmount[assetId] = amount.abs();
          requestedAmounts[OfferAssetData.cat(tailHash: assetId)] = [amount.abs()];
        } else if (assetType == AssetType.SINGLETON) {
          royaltyPercentage = royaltyPercentage ?? calculateRoyalty(offerDriverDict[assetId]!);
          requestedAmounts[OfferAssetData.singletonNft(launcherPuzhash: assetId)] = [amount.abs()];
        }
      }
    });

    if (royaltyPercentage != null && fungibleAssetAmount.length >= 1) {
      royaltyAmounts = {};
      for (var key in fungibleAssetAmount.keys) {
        final fungibleAmount = fungibleAssetAmount[key]!;
        royaltyAmounts[key] = calculateRoyaltyAmount(
          fungibleAmount: fungibleAmount,
          percentageRaw: royaltyPercentage!,
        );
      }
    }

    final invertOfferred = convertRequestedToOffered(requestedAmounts);
    final invertRequested = convertOfferedToRequested(offerredAmounts);

    return AnalizedOffer(
      offered: invertOfferred,
      requested: invertRequested,
      isOld: isOld,
      royaltyAmounts: royaltyAmounts,
      royaltyPer: royaltyPercentage,
      fungibleAmounts: fungibleAssetAmount,
    );
  }

  Map<OfferAssetData?, int> convertRequestedToOffered(Map<OfferAssetData?, List<int>> requested) {
    final result = <OfferAssetData?, int>{};
    for (var key in requested.keys) {
      final amount =
          requested[key]!.fold<int>(0, (previousValue, element) => previousValue + element);
      result[key] = amount;
    }
    return result;
  }

  Map<OfferAssetData?, List<int>> convertOfferedToRequested(Map<OfferAssetData?, int> offered) {
    final result = <OfferAssetData?, List<int>>{};
    for (var key in offered.keys) {
      result[key] = [offered[key]!];
    }
    return result;
  }

  Future<Tuple2<Offer, SignatureHashes?>> responseOffer({
    required Map<OfferAssetData?, List<FullCoin>> groupedCoins,
    required WalletKeychain keychain,
    required int fee,
    required Puzzlehash targetPuzzleHash,
    required Puzzlehash changePuzzlehash,
    List<Coin>? standardCoinsForFee,
    required Offer offer,
    required BuildKeychain buildKeychainForNft,
    required List<SpendBundle> extraSpendBundles,
    required Network network,
    required Environment enviroment,
  }) async {
    final isOld = offer.old;
    final unsigned = keychain.unsigned;
    final isTangem = keychain.isTangem;

    final analizedOffer = await analizeOffer(
      fee: fee,
      targetPuzzleHash: targetPuzzleHash,
      changePuzzlehash: changePuzzlehash,
      offer: offer,
    );

    final coins = groupedCoins.values.expand((element) => element).toList();
    if (standardCoinsForFee == null && fee > 0) {
      if (analizedOffer!.requested[null]?.isEmpty ?? true) {
        standardCoinsForFee = groupedCoins[null]?.map((e) => e.toCoin()).toList();
        if (standardCoinsForFee == null) {
          throw Exception("Standard coins for fee not found");
        }
      }
    }
    final requestedAmounts = convertOfferedToRequested(analizedOffer!.offered);
    final offeredAmounts = convertRequestedToOffered(analizedOffer.requested);
    final preparedCoins = await prepareFullCoins(
      coins,
      buildKeychain: buildKeychainForNft,
      isTangem: isTangem,
      unsigned: unsigned,
    );

    Map<Bytes, PuzzleInfo> offerDriverDict = offer.driverDict;
    final preparedData = await _prepareOfferData(
      coins: preparedCoins,
      requestedAmounts: requestedAmounts,
      offerredAmounts: offeredAmounts,
      fee: fee,
      targetPuzzleHash: targetPuzzleHash,
      offerDriverDict: offerDriverDict,
      royaltyPercentage: analizedOffer.royaltyPer,
      royaltyAmounts: analizedOffer.royaltyAmounts,
    );
    offerDriverDict = preparedData.driverDict;

    if (preparedData.nftOfferedLauncher != null || preparedData.requestedLauncher) {
      Map<Bytes?, int> offerDict = {};

      if (preparedData.nftOfferedLauncher != null) {
        final nftOfferedAsset = OfferAssetData.singletonNft(
          launcherPuzhash: preparedData.nftOfferedLauncher!,
        );
        final nftCoins = preparedCoins[nftOfferedAsset] ?? [];
        if (!(nftCoins.isNotEmpty && nftCoins.first is FullNFTCoinInfo)) {
          throw Exception("Offered NFT coin not found ${preparedData.nftOfferedLauncher!.toHex()}");
        }
      }

      if (standardCoinsForFee == null && offeredAmounts[null] == null && fee > 0) {
        throw Exception("Standard coins for fee not found for NFT Offer");
      }
      offeredAmounts.forEach((OfferAssetData? asset, int amount) {
        offerDict[asset?.assetId] = -(amount.abs());
      });
      requestedAmounts.forEach((OfferAssetData? asset, List<int> amounts) {
        final amount = amounts.fold(0, (previousValue, element) => previousValue + element);
        if (amount > 0) {
          offerDict[asset?.assetId] = amount.abs();
        }
      });

      final offerSpenBundle = await spawnAndWaitForIsolate(
        taskArgument: MakeNft1OfferIsolatedArguments(
          offerDict: offerDict,
          driverDict: offerDriverDict,
          changePuzzlehash: changePuzzlehash,
          keychain: keychain,
          old: isOld,
          fee: fee,
          selectedCoins: preparedCoins,
          standardCoinsForFee: standardCoinsForFee ?? [],
          targetPuzzleHash: targetPuzzleHash,
          extraSpendBundles: extraSpendBundles,
          network: network,
          environment: enviroment,
        ),
        isolateTask: makeNft1OfferIsolate,
        handleTaskCompletion: decodeMapSpendResponse,
      );
      final nftOffer = Offer.fromSpendBundle(
        offerSpenBundle.item1,
      );
      final completedOffer = Offer.aggregate(
        [offer, nftOffer],
      );

      return Tuple2(
        completedOffer,
        offerSpenBundle.item2,
      );
    } else {
      final offerWallet = TradeManagerService();
      final responseOffer = await offerWallet.createOfferForIds(
          coins: groupedCoins,
          driverDict: preparedData.driverDict,
          requiredPayments: preparedData.payments,
          offeredAmounts: preparedData.offerredAmounts,
          changePuzzlehash: changePuzzlehash,
          keychain: keychain,
          old: isOld,
          fee: fee,
          extraSpendBundles: extraSpendBundles);

      final completedOffer = Offer.aggregate([
        offer,
        responseOffer.item1,
      ]);
      return Tuple2(
        completedOffer,
        responseOffer.item2,
      );
    }
  }

  // create doc comments
  ///   Create offer
  ///  [coins] - list of full  coins to use in offer
  /// [requestedAmounts] - map of asset id and amount to request,
  /// [offerredAmounts] - map of asset id and amount to offer
  /// [keychain] - keychain to use for offer
  /// [fee] - fee to use for offer
  /// [targetPuzzleHash] - puzzlehash to use for offer
  /// [isOld] - is old offer
  /// [changePuzzlehash] - puzzlehash to use for change
  Future<Tuple2<Offer, SignatureHashes?>> createOffer(
      {required Map<OfferAssetData?, List<FullCoin>> groupedCoins,
      required Map<OfferAssetData?, List<int>> requestedAmounts,
      required Map<OfferAssetData?, int> offerredAmounts,
      required WalletKeychain keychain,
      required int fee,
      required Puzzlehash targetPuzzleHash,
      required bool isOld,
      required Puzzlehash changePuzzlehash,
      required List<SpendBundle> extraSpendBundles,
      List<Coin>? standardCoinsForFee}) async {
    final unsigned = keychain.unsigned;
    List<FullCoin> coins = [];

    groupedCoins.forEach((key, value) {
      coins.addAll(value);
    });

    if (standardCoinsForFee == null && fee > 0) {
      if (offerredAmounts[null] == null) {
        standardCoinsForFee = groupedCoins[null]?.map((e) => e.toCoin()).toList();
        if (standardCoinsForFee == null) {
          throw Exception("Standard coins for fee not found");
        }
      }
    }

    Map<OfferAssetData?, List<FullCoin>> preparedCoins = groupedCoins;

    final preparedData = await _prepareOfferData(
      coins: preparedCoins,
      requestedAmounts: requestedAmounts,
      offerredAmounts: offerredAmounts,
      fee: fee,
      targetPuzzleHash: targetPuzzleHash,
    );

    Bytes? nftOfferedLauncher;
    Bytes? nftRequestedLauncher;
    preparedData.offerredAmounts.forEach((Bytes? assetId, int amount) {
      if (amount < 0) {
        if (assetId != null) {
          // check if asset is an NFT
          final offerringNft = preparedData.driverDict[assetId]?.type == AssetType.SINGLETON;
          if (offerringNft) {
            nftOfferedLauncher = assetId;
          }
        }
      }
    });
    requestedAmounts.forEach((OfferAssetData? asset, List<int> amounts) {
      final amount = amounts.fold(0, (previousValue, element) => previousValue + element);
      if (amount > 0) {
        if (asset != null) {
          final requestingNft = preparedData.driverDict[asset.assetId]?.type == AssetType.SINGLETON;

          if (requestingNft) {
            nftRequestedLauncher = asset.assetId;
          }
        }
      }
    });
    if (nftOfferedLauncher != null || nftRequestedLauncher != null) {
      Map<Bytes?, int> offerDict = {};

      if (nftOfferedLauncher != null) {
        final nftCoins = preparedCoins[OfferAssetData.singletonNft(
              launcherPuzhash: nftOfferedLauncher!,
            )] ??
            [];

        if (!(nftCoins.isNotEmpty && nftCoins.first is FullNFTCoinInfo)) {
          throw Exception("Offered NFT coin not found ${preparedData.nftOfferedLauncher!.toHex()}");
        }

        if (standardCoinsForFee == null && fee > 0) {
          throw Exception(
            "Standard coins for fee not found, pass into"
            "[standardCoinsForFee] or in  groupedCoins[null] ",
          );
        }
      } else {
        if (standardCoinsForFee == null) {
          standardCoinsForFee = [];
        }
      }
      preparedData.offerredAmounts.forEach((Bytes? assetId, int amount) {
        offerDict[assetId] = amount;
      });
      requestedAmounts.forEach((OfferAssetData? asset, List<int> amounts) {
        final amount = amounts.fold(0, (previousValue, element) => previousValue + element);
        if (amount > 0) {
          offerDict[asset?.assetId] = amount.abs();
        }
      });

      final NftWallet nftWallet = keychain.isTangem ? TangemNftWallet() : NftWallet();

      final nftOffer = await nftWallet.makeNft1Offer(
        offerDict: offerDict,
        driverDict: preparedData.driverDict,
        changePuzzlehash: changePuzzlehash,
        keychain: keychain,
        old: isOld,
        fee: fee,
        selectedCoins: preparedCoins,
        standardCoinsForFee: standardCoinsForFee ?? [],
        targetPuzzleHash: targetPuzzleHash,
        extraSpendBundles: extraSpendBundles,
        unsigned: unsigned,
      );
      return nftOffer;
    } else {
      final offerWallet = TradeManagerService();
      final offer = offerWallet.createOfferForIds(
        coins: preparedCoins,
        driverDict: preparedData.driverDict,
        requiredPayments: preparedData.payments,
        offeredAmounts: preparedData.offerredAmounts,
        changePuzzlehash: changePuzzlehash,
        keychain: keychain,
        old: isOld,
        fee: fee,
        extraSpendBundles: extraSpendBundles,
      );
      return offer;
    }
  }

  Future<Map<Bytes, PuzzleInfo>> createDict(
      {required Map<OfferAssetData?, List<int>> requestedAmounts,
      required Map<OfferAssetData?, int> offerredAmounts,
      required Map<OfferAssetData, FullNFTCoinInfo> nftCoins}) async {
    Map<Bytes, PuzzleInfo> driverDict = {};
    final uniqueAssetsData =
        (requestedAmounts.keys.toList() + offerredAmounts.keys.toList()).toSet();

    for (final assetData in uniqueAssetsData) {
      if (assetData != null) {
        if (assetData.type == SpendType.cat2) {
          final tailHash = assetData.assetId;
          driverDict[tailHash!] = PuzzleInfo({
            "type": AssetType.CAT,
            "tail": tailHash.toHexWithPrefix(),
          });
        } else if (assetData.type == SpendType.nft) {
          final puzzleInfo = await NftWallet().getPuzzleInfo(nftCoins[assetData]!.toNftCoinInfo());
          driverDict[assetData.assetId!] = puzzleInfo;
        }
      }
    }
    return driverDict;
  }

  Future<PreparedTradeData> _prepareOfferData({
    required Map<OfferAssetData?, List<int>> requestedAmounts,
    required Map<OfferAssetData?, int> offerredAmounts,
    required int fee,
    required Map<OfferAssetData?, List<FullCoin>> coins,
    required Puzzlehash targetPuzzleHash,
    Map<Bytes, PuzzleInfo>? offerDriverDict,
    int? royaltyPercentage,
    Map<Bytes?, int?>? royaltyAmounts,
  }) async {
    Bytes? nftOfferedLauncher;
    bool requestedLauncher = false;
    Map<OfferAssetData, FullNFTCoinInfo> nftCoins = {};

    coins.forEach((asset, coins) {
      if (asset != null) {
        if (asset.type == SpendType.nft) {
          final founded = coins.where((element) => element is FullNFTCoinInfo).toList();
          if (founded.isNotEmpty) {
            final nftCoin = founded.first as FullNFTCoinInfo;
            nftCoins[asset] = nftCoin;
          }
        }
      }
    });
    Map<Bytes, PuzzleInfo> driverDict = offerDriverDict ??
        await createDict(
          requestedAmounts: requestedAmounts,
          offerredAmounts: offerredAmounts,
          nftCoins: nftCoins,
        );

    offerredAmounts.forEach((OfferAssetData? asset, int amount) {
      if (asset != null) {
        if (asset.type == SpendType.nft) {
          nftOfferedLauncher = asset.assetId;
        }
      }
    });
    requestedAmounts.forEach((OfferAssetData? asset, List<int> amounts) {
      if (asset != null) {
        if (asset.type == SpendType.nft) {
          requestedLauncher = true;
        }
      }
    });

    // check offerredAmountsCoins
    offerredAmounts.forEach((assetData, amount) {
      int assetAmount = amount.abs();
      final assetCoins = coins[assetData];

      if (assetData == null) {
        // is standard, add fee for check coins amount
        assetAmount = (offerredAmounts[null] ?? 0) + fee;
      }
      if (assetCoins == null) {
        throw Exception(
            "Not enough coins for offerredAmounts in the asset: ${assetData ?? 'standard'}");
      }
      final coinsAmount = assetCoins.map((e) => e.amount).reduce((a, b) => a + b);
      if (coinsAmount < assetAmount) {
        throw Exception(
            "Not enough coins for offerredAmounts (${assetAmount} <  ${coinsAmount}) in the asset: ${assetData ?? 'standard'}");
      }
    });

    final payments = <Bytes?, List<Payment>>{};

    requestedAmounts.forEach((assetData, amounts) {
      final assetId = assetData?.assetId;
      if (payments[assetId] == null) {
        payments[assetId] = [];
      }
      for (var amount in amounts) {
        List<Bytes> memos = [];
        if (assetId != null) {
          memos = [targetPuzzleHash.toBytes()];
        }
        payments[assetId]!.add(Payment(
          amount,
          targetPuzzleHash,
          memos: memos,
        ));
      }
    });
    final offeredAmountsSimple = <Bytes?, int>{};
    offerredAmounts.forEach((assetData, amount) {
      final assetId = assetData?.assetId;
      offeredAmountsSimple[assetId] = amount;
    });

    return PreparedTradeData(
        payments: payments,
        driverDict: driverDict,
        offerredAmounts: offeredAmountsSimple,
        nftOfferedLauncher: nftOfferedLauncher,
        requestedLauncher: requestedLauncher);
  }

  Future<FullNFTCoinInfo> constructFullNftCoin(
      {required FullCoin fullCoin,
      required BuildKeychain? buildKeychain,
      required bool isTangem,
      required bool unsigned}) async {
    final wallet = isTangem ? TangemNftWallet() : NftWallet();
    final result = await wallet.getNFTFullCoinInfo(
      fullCoin,
      buildKeychain: buildKeychain,
    );
    return result.item1;
  }
}

FutureOr<Map<String, dynamic>> makeNft1OfferIsolate(
    MakeNft1OfferIsolatedArguments taskArgument) async {
  ChiaNetworkContextWrapper().registerNetworkContext(
    taskArgument.network,
    environment: taskArgument.environment,
  );
  final nftWallet = NftWallet();

  final nftOffer = await nftWallet.makeNft1Offer(
    offerDict: taskArgument.offerDict,
    driverDict: taskArgument.driverDict,
    changePuzzlehash: taskArgument.changePuzzlehash,
    keychain: taskArgument.keychain,
    old: taskArgument.old,
    fee: taskArgument.fee,
    selectedCoins: taskArgument.selectedCoins,
    standardCoinsForFee: taskArgument.standardCoinsForFee,
    targetPuzzleHash: taskArgument.targetPuzzleHash,
    extraSpendBundles: taskArgument.extraSpendBundles,
    unsigned: taskArgument.keychain.unsigned,
  );
  final resultJson = {
    "spend_bundle": nftOffer.item1.toSpendBundle().toJson(),
    "signature_hashes": nftOffer.item2?.toMap(),
  };
  return resultJson;
}

class CreateOfferArgumentsIsolated {
  final Map<OfferAssetData?, List<FullCoin>> groupedCoins;
  final Map<OfferAssetData?, List<int>> requestedAmounts;
  final Map<OfferAssetData?, int> offerredAmounts;
  final WalletKeychain keychain;
  final int fee;
  final Puzzlehash targetPuzzleHash;
  final bool isOld;
  final Puzzlehash changePuzzlehash;
  final List<Coin>? standardCoinsForFee;
  final Network network;
  final List<SpendBundle> extraSpendBundles;

  CreateOfferArgumentsIsolated({
    required this.groupedCoins,
    required this.requestedAmounts,
    required this.offerredAmounts,
    required this.keychain,
    required this.fee,
    required this.targetPuzzleHash,
    required this.isOld,
    required this.changePuzzlehash,
    this.standardCoinsForFee,
    required this.network,
    required this.extraSpendBundles,
  });
}

class MakeNft1OfferIsolatedArguments {
  final WalletKeychain keychain;
  final Map<Bytes?, int> offerDict;
  final Map<Bytes, PuzzleInfo> driverDict;
  final Puzzlehash targetPuzzleHash;
  final Map<OfferAssetData?, List<FullCoin>> selectedCoins;
  final int fee;
  final int? mintCoinAmount;
  final Puzzlehash? changePuzzlehash;
  final List<Coin> standardCoinsForFee;
  final bool old;
  final List<SpendBundle> extraSpendBundles;
  final Network network;
  final Environment environment;
  MakeNft1OfferIsolatedArguments({
    required this.keychain,
    required this.offerDict,
    required this.driverDict,
    required this.targetPuzzleHash,
    required this.selectedCoins,
    required this.standardCoinsForFee,
    required this.old,
    required this.extraSpendBundles,
    this.mintCoinAmount,
    this.changePuzzlehash,
    required this.fee,
    required this.network,
    required this.environment,
  });
}

Tuple2<SpendBundle, SignatureHashes?> decodeMapSpendResponse(Map<String, dynamic> dataMap) {
  final spendBundleJson = dataMap["spend_bundle"];
  final signatureHashesJson = dataMap["signature_hashes"];
  final spendBundle = SpendBundle.fromJson(spendBundleJson);
  final signatureHashes =
      signatureHashesJson != null ? SignatureHashes.fromMap(signatureHashesJson) : null;
  return Tuple2(spendBundle, signatureHashes);
}

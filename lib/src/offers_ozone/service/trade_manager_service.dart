import 'dart:typed_data';

import '../../cat/index.dart';
import '../../clvm.dart';
import '../../core/index.dart';
import '../../nft1.0/index.dart';
import '../../standard/index.dart';
import '../../utils.dart';
import '../index.dart';
import '../../core/models/outer_puzzle.dart' as outerPuzzle;

class TradeManagerService extends BaseWalletService {
  final StandardWalletService standardWalletService = StandardWalletService();
  final catWallet = CatWalletService();

  /// `generate_secure_bundle` simulates a wallet's `generate_signed_transaction`
  /// but doesn't bother with non-offer announcements
  Offer createOfferBundle(
      {required List<FullCoin> selectedCoins,
      required List<AssertPuzzleCondition> announcements,
      required Map<Bytes?, int> offeredAmounts,
      required WalletKeychain keychain,
      required int fee,
      required Puzzlehash changePuzzlehash,
      required Map<Bytes, PuzzleInfo> driverDict,
      required Map<Bytes?, List<NotarizedPayment>> notarizedPayments,
      required bool old}) {
    final transactions = <SpendBundle>[];

    final feeLeftToPay = fee;

    offeredAmounts.forEach((assetId, amount) {
      if (assetId == null) {
        final standarBundle = StandardWalletService().createSpendBundle(
          payments: [
            Payment(offeredAmounts[assetId]!.abs(), Offer.ph(old)),
          ],
          coinsInput: selectedCoins,
          keychain: keychain,
          fee: feeLeftToPay,
          puzzleAnnouncementsToAssert: announcements,
          changePuzzlehash: changePuzzlehash,
        );
        transactions.add(standarBundle);
      } else {
        bool isCat = driverDict[assetId]!.type == AssetType.CAT;

        if (isCat) {
          final catPayments = [
            Payment(offeredAmounts[assetId]!.abs(), Offer.ph(old), memos: <Bytes>[
              Offer.ph(old).toBytes(),
            ]),
          ];
          final catCoins = selectedCoins
              .where((element) => element.isCatCoin)
              .map((e) => e.toCatCoin())
              .toList();
          final standardsCoins =
              selectedCoins.where((element) => !element.isCatCoin).map((e) => e.coin).toList();
          final catBundle = CatWalletService().createSpendBundle(
            payments: catPayments,
            catCoinsInput: catCoins,
            keychain: keychain,
            fee: feeLeftToPay,
            standardCoinsForFee: standardsCoins,
            puzzleAnnouncementsToAssert: announcements,
            changePuzzlehash: changePuzzlehash,
          );
          final catBytes = catBundle.toBytes();
          final _ = SpendBundle.fromBytes(catBytes);
          transactions.add(catBundle);
        } else {
          throw Exception("Not implemented for ${driverDict[assetId]?.type}}");
        }
      }
    });

    final totalSpendBundle = transactions.fold<SpendBundle>(
      SpendBundle(coinSpends: []),
      (previousValue, spendBundle) => previousValue + spendBundle,
    );

    return Offer(
        requestedPayments: notarizedPayments,
        bundle: totalSpendBundle,
        driverDict: driverDict,
        old: old);
  }

  Offer createOfferForIds(
      {required List<FullCoin> coins,
      required Map<Bytes, PuzzleInfo> driverDict,
      required Map<Bytes?, List<Payment>> requiredPayments,
      required Map<Bytes?, int> offeredAmounts,
      int fee = 0,
      validateOnly = false,
      required Puzzlehash changePuzzlehash,
      required WalletKeychain keychain,
      required bool old}) {
    final chiaRequestedPayments = requiredPayments;

    final chiaNotariedPayments = Offer.notarizePayments(
      requestedPayments: chiaRequestedPayments,
      coins: coins,
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
    );

    return chiaOffer;
  }

  Map<OfferAssetData?, List<FullCoin>> prepareFullCoins(
    List<FullCoin> coins, {
    required WalletKeychain keychain,
  }) {
    final groupedCoins = <OfferAssetData?, List<FullCoin>>{};
    for (final coin in coins) {
      final assetData = OfferAssetData.fromFullCoin(coin);
      if (assetData?.type == SpendType.nft) {
        final FullNFTCoinInfo nftCoin = constructFullNftCoin(
          fullCoin: coin,
          keychain: keychain,
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
    int? royaltyAmount;

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
        requestedAmounts[OfferAssetData.standart()] = [amount.abs()];
      } else {
        final assetType = offerDriverDict[assetId]!.type;
        if (assetType == AssetType.CAT) {
          requestedAmounts[OfferAssetData.cat(tailHash: assetId)] = [amount.abs()];
        } else if (assetType == AssetType.SINGLETON) {
          bool isRoyalty = offerDriverDict[assetId]!.checkType(types: [
            AssetType.SINGLETON,
            AssetType.METADATA,
            AssetType.OWNERSHIP,
          ]);

          if (isRoyalty) {
            var transferInfo = offerDriverDict[assetId]!.also!.also!;
            var royaltyPercentageRaw = transferInfo["transfer_program"]["royalty_percentage"];
            if (royaltyPercentageRaw == null) {
              throw Exception("Royalty percentage is not found in the transfer program");
            }
            // clvm encodes large ints as bytes

            if (royaltyPercentageRaw is Bytes) {
              royaltyPercentage = bytesToInt(royaltyPercentageRaw, Endian.big);
            } else if (royaltyPercentageRaw is int) {
              royaltyPercentage = royaltyPercentageRaw;
            } else {
              royaltyPercentage = int.parse(royaltyPercentageRaw);
            }
          }

          requestedAmounts[OfferAssetData.singletonNft(launcherPuzhash: assetId)] = [amount.abs()];
        }
      }
    });
    if (royaltyPercentage != null && fungibleAssetAmount.length == 1) {
      final fungibleAmount = fungibleAssetAmount.values.first;
      royaltyAmount = (fungibleAmount.abs() * (royaltyPercentage! / 10000)).floor();
    }

    offerRequestedAmounts.forEach((assetId, amount) {
      takeOfferDict[assetId] = -(amount.abs());

      if (assetId == null) {
        final totalChia = amount + fee;
        offerredAmounts[OfferAssetData.standart()] = -(totalChia.abs());
      } else {
        final assetType = offerDriverDict[assetId]!.type;
        if (assetType == AssetType.CAT) {
          final totalCat = amount;
          offerredAmounts[OfferAssetData.cat(tailHash: assetId)] = -(totalCat.abs());
        } else if (assetType == AssetType.SINGLETON) {
          offerredAmounts[OfferAssetData.singletonNft(launcherPuzhash: assetId)] = -(amount.abs());
        }
      }
    });

    return AnalizedOffer(
      offered: convertRequestedToOffered(requestedAmounts),
      requested: convertOfferedToRequested(offerredAmounts),
      isOld: isOld,
      royaltyAmount: royaltyAmount,
      royaltyPer: royaltyPercentage,
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

  Future<Offer> responseOffer({
    required Map<OfferAssetData?, List<FullCoin>> groupedCoins,
    required WalletKeychain keychain,
    required int fee,
    required Puzzlehash targetPuzzleHash,
    required Puzzlehash changePuzzlehash,
    List<Coin>? standardCoinsForFee,
    required Offer offer,
  }) async {
    final isOld = offer.old;

    final offerDriverDict = offer.driverDict;

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

    final preparedData = await _prepareOfferData(
        coins: groupedCoins,
        requestedAmounts: requestedAmounts,
        offerredAmounts: convertRequestedToOffered(analizedOffer.requested),
        fee: fee,
        targetPuzzleHash: targetPuzzleHash,
        offerDriverDict: offerDriverDict);

    if (preparedData.nftOfferedLauncher != null || preparedData.requestedLauncher) {
      Map<Bytes?, int> offerDict = {};
      final preparedCoins = prepareFullCoins(coins, keychain: keychain);
      FullNFTCoinInfo? nftCoin;
      if (preparedData.nftOfferedLauncher != null) {
        final nftOfferedAsset = OfferAssetData.singletonNft(
          launcherPuzhash: preparedData.nftOfferedLauncher!,
        );
        final nftCoins = preparedCoins[nftOfferedAsset] ?? [];
        if (nftCoins.isNotEmpty) {
          nftCoin = nftCoins.first as FullNFTCoinInfo;
        } else {
          throw Exception("Offered NFT coin not found ${preparedData.nftOfferedLauncher!.toHex()}");
        }
      }
      final nftWallet = NftWallet();
      if (standardCoinsForFee == null && preparedData.offerredAmounts[null] == null && fee > 0) {
        throw Exception("Standard coins for fee not found for NFT Offer");
      }
      preparedData.offerredAmounts.forEach((Bytes? assetId, int amount) {
        offerDict[assetId] = -(amount.abs());
      });
      requestedAmounts.forEach((OfferAssetData? asset, List<int> amounts) {
        final amount = amounts.fold(0, (previousValue, element) => previousValue + element);
        if (amount > 0) {
          offerDict[asset?.assetId] = amount.abs();
        }
      });

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
        nftCoin: nftCoin,
      );
      final completedOffer = Offer.aggregate([offer, nftOffer]);
      return completedOffer;
    } else {
      final offerWallet = TradeManagerService();
      final responseOffer = await offerWallet.createOfferForIds(
        coins: coins,
        driverDict: preparedData.driverDict,
        requiredPayments: preparedData.payments,
        offeredAmounts: preparedData.offerredAmounts,
        changePuzzlehash: changePuzzlehash,
        keychain: keychain,
        old: isOld,
        fee: fee,
      );

      final completedOffer = Offer.aggregate([offer, responseOffer]);
      return completedOffer;
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
  Future<Offer> createOffer(
      {required Map<OfferAssetData?, List<FullCoin>> groupedCoins,
      required Map<OfferAssetData?, List<int>> requestedAmounts,
      required Map<OfferAssetData?, int> offerredAmounts,
      required WalletKeychain keychain,
      required int fee,
      required Puzzlehash targetPuzzleHash,
      required bool isOld,
      required Puzzlehash changePuzzlehash,
      List<Coin>? standardCoinsForFee}) async {
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
      FullNFTCoinInfo? nftCoin;
      if (nftOfferedLauncher != null) {
        final coins = preparedCoins[OfferAssetData.singletonNft(
          launcherPuzhash: nftOfferedLauncher!,
        )];
        if ((coins?.isNotEmpty ?? false) && coins!.first is FullNFTCoinInfo) {
          nftCoin = coins.first as FullNFTCoinInfo;
        }
        if (nftCoin == null) {
          throw Exception("Offered NFT coin not found ${nftOfferedLauncher!.toHex()}");
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

      final nftWallet = NftWallet();

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
        nftCoin: nftCoin,
      );
      return nftOffer;
    } else {
      final offerWallet = TradeManagerService();
      final offer = offerWallet.createOfferForIds(
        coins: coins,
        driverDict: preparedData.driverDict,
        requiredPayments: preparedData.payments,
        offeredAmounts: preparedData.offerredAmounts,
        changePuzzlehash: changePuzzlehash,
        keychain: keychain,
        old: isOld,
        fee: fee,
      );
      return offer;
    }
  }

  Future<Map<Bytes, PuzzleInfo>> _createDict(
      {required Map<OfferAssetData?, List<int>> requestedAmounts,
      required Map<OfferAssetData?, int> offerredAmounts,
      NFTCoinInfo? nftCoin}) async {
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
          final puzzleInfo = await NftWallet().getPuzzleInfo(nftCoin!);
          driverDict[assetData.assetId!] = puzzleInfo;
        }
      }
    }
    return driverDict;
  }

  Future<PreparedTradeData> _prepareOfferData(
      {required Map<OfferAssetData?, List<int>> requestedAmounts,
      required Map<OfferAssetData?, int> offerredAmounts,
      required int fee,
      required Map<OfferAssetData?, List<FullCoin>> coins,
      required Puzzlehash targetPuzzleHash,
      Map<Bytes, PuzzleInfo>? offerDriverDict}) async {
    FullNFTCoinInfo? nftCoin;
    Bytes? nftOfferedLauncher;
    bool requestedLauncher = false;

    coins.forEach((assetId, coins) {
      if (assetId != null) {
        if (assetId.type == SpendType.nft) {
          final founded = coins.where((element) => element is FullNFTCoinInfo).toList();
          if (founded.isNotEmpty) {
            nftCoin = founded.first as FullNFTCoinInfo;
          }
        }
      }
    });
    Map<Bytes, PuzzleInfo> driverDict = offerDriverDict ??
        await _createDict(
          requestedAmounts: requestedAmounts,
          offerredAmounts: offerredAmounts,
          nftCoin: nftCoin?.toNftCoinInfo(),
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

  FullNFTCoinInfo constructFullNftCoin({
    required FullCoin fullCoin,
    required WalletKeychain keychain,
  }) {
    final coin = fullCoin.toCoin();
    final coinSpend = fullCoin.parentCoinSpend!;

    final nftUncurried = UncurriedNFT.uncurry(coinSpend.puzzleReveal);
    final nftInfo = NFTInfo.fromUncurried(
      uncurriedNFT: nftUncurried,
      currentCoin: coin,
      mintHeight: fullCoin.coin.confirmedBlockIndex,
    );

    final data = NftService().getMetadataAndPhs(
      nftUncurried,
      coinSpend.solution,
    );
    final metadata = data.item1;

    final p2PuzzleHash = Puzzlehash(data.item2);

    final vector = keychain.getWalletVector(p2PuzzleHash);
    Program innerPuzzle = getPuzzleFromPk(vector!.childPublicKey);

    if (nftUncurried.supportDid) {
      innerPuzzle = NftService().recurryNftPuzzle(
        unft: nftUncurried,
        solution: coinSpend.solution,
        newInnerPuzzle: innerPuzzle,
      );
    }

    Program fullPuzzle = NftService.createFullPuzzle(
      singletonId: nftUncurried.singletonLauncherId.atom,
      metadata: metadata,
      metadataUpdaterHash: nftUncurried.metadataUpdaterHash.atom,
      innerPuzzle: innerPuzzle,
    );

    FullNFTCoinInfo nftCoin = FullNFTCoinInfo(
      coin: coin,
      fullPuzzle: fullPuzzle,
      latestHeight: coin.confirmedBlockIndex,
      mintHeight: nftInfo.mintHeight,
      minterDid: nftUncurried.ownerDid,
      nftId: nftUncurried.singletonLauncherId.atom,
      pendingTransaction: false,
      nftLineageProof: LineageProof(
        amount: coinSpend.coin.amount,
        innerPuzzleHash: nftUncurried.nftStateLayer.hash(),
        parentName: Puzzlehash(coinSpend.coin.parentCoinInfo),
      ),
      parentCoinSpend: fullCoin.parentCoinSpend,
    );
    return nftCoin;
  }
}

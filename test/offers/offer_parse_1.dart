import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/offer/models/offer.dart';
import 'package:chia_crypto_utils/src/offer/utils/puzzle_compression.dart';
import 'package:test/test.dart';

const testOfferData =
    'offer1qqp83w76wzru6cmqvpsxygqqd3za7dt9hetnam2uuc7u860au4qzjp533dfgzsjnl8em5hcx4gv30s75cxp8tdy7rwk7w3hth8gh5m45ncd7s7swtnkz6296wus2nh08etj42wex9kvfp443wzw6xd3ruuxrmu0fpv9adhhghees023vdd9v0vg0x53g9w22n0hwkf80urj8su7nmqaa5dks79wj3e6zex82l5zzwj6waprhayvzzvstyfp7cnjgc3ht0xnc3xrmhv3pjzpjjjfy7enae88avu9sxc6h7nvdgqy4jj2204h3n6dzwhcs8f6uxh8t6496uvqanxa0k3lw8s03mfhq0frf7mllnvvak9ss5y8xfc7x4c3jtjlwzh8aan8mg27fp62hajk9h5la3du9vaea0mf0y3mh6546aj9rke9j00a3lpm784j6xdm4hj6tklnr6hms572xrutx7cm5hyjhgshkzcrq0kvkduqzkklpanjad7cvzxuk9pwf57nn2xn7md3e65emtghlagudeyu5dy8m4u99j06a0e4qr5c5kth7f9ma0xnelhszfug8vmnamrjesz6nvsqj7hlstwc78yntmhcm6m0mnf72s37uvvkpmc839umk8mlfzktadegatnlelk2llx75q5dvq24rphlaav458hljjalrj7ad7uawznwqa8w28e2jgawtsxwr6xtm3cweaadlp520cpe7qp2ahlzlcz75zu6e7ewyle5g8wtjvw5czs95eedclfddx7da7hz4hzhdzdxjy8cr2hvl7h7snacw5lerd0luh6rhvuxpvhdg4au4l4eq74qau0lt50cu8kumamx2cqv8ulxyjx0mr0d089ju37wfxud3alq4dth7nzp203hhej0n8l6dt0ukfxl83jflwdrrww3t29em44f4thdmucdvk3a0krh5rzuvlg0pknthm9u8jn6d7ttu4309k8wsrw67rsuf0u0aaw2h0fmtn70xm7x8wd0l4cc7sxd9vqz3wn33c3r47ls';
const testOfferData2 =
    'offer1qqp83w76wzru6cmqvpsxygqqd3za7dt9hetnam2uuc7u860au4qzjp533dfgzsjnl8em5hcx4gv30s75cxp8tdy7rwk7w3hth8gh5m45ncd7s7swtnkz6296wus2nh08etj42wex9kvfp443wzw6xd3ruuxrmu0fpv9adhhghees023vdd9v0vg0x53g9w22n0hwkf80urj8su7nmqaa5dks79wj3e6zex82l5zzwj6waprhayvzzvstyfp7cnjgc3ht0xnc3xrmhv3pjzpjjjfy7enae88avu9sxc6h7nvdgqy4f3s2st4gk09j40pwtfdlunh34tgtxa0m5kal7udwlrsumcqh9yjptl4lf9wsqmxnc6hzxfwtac2ulhkvldptey8f2lk2ck7nlk9hs4nh84ld9uj8wl2jhtkg5wmykfalk8u80c7ktgehwk7tfwm7v02lwznegc03vmmrwjuj2azz7ctqvp7ejehsq26ny8kwl44tpsgmjc59exn6wdg60mdk882n8ddzll4r3hynj35slwhs5kflt4lx5qwnzjewleyh04u60877qf83qanw0hvwtxqt2djq2tk07pdmrcujd0wlr0tdlwd8e2z8m33jc80q7yhnwcl0ay2e04h9r4w0l87etl6nrtqw5zxxvgdj3uyleuq64dhlh7q9pwcf4r9wdlczhmlz73jxhlwdfr0dwm5laxtl0mafaf00w4awyv4w9j9d76r5l9fv23tsdzhduljv9nm4dly7ty77v9l7y3h09jqkj2hslr742uk9j73ytl7a7cu03d047dru0nrd744vcgg4m7hpncv9l7wdrdpzwtwlex75a7qe7fa05awtqt5328xv7a4wy0zhaw9hglf0hfsrpa02mlxk6m8zz273urg8tyhsqq92c0pqyflrc4m';
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

  void testParseOfferFile() {
    final offer = Offer.fromBench32(testOfferData);

    final offer2 = Offer.fromBench32(testOfferData2);

    print("offer ID = ${offer.id} ${offer2.id}");
    offer.toSpendBundle().coinSpends.forEach((element) {
      print(element.toHex());
    });
    print("----------");
    offer2.toSpendBundle().coinSpends.forEach((element) {
      print(element.toHex());
    });
    print('hola');
  }

  test('Parse Offer', () async {
    testParseOfferFile();
  });
}

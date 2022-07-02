import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/offers_ozone/models/offer.dart';
import 'package:chia_crypto_utils/src/offers_ozone/utils/puzzle_compression.dart';
import 'package:test/test.dart';

const testOfferData =
    'offer1qqp83w76wzru6cmqvpsxygqqd3za7dt9hetnam2uuc7u860au4qzjp533dfgzsjnl8em5hcx4gv30s75cxp8tdy7rwk7w3hth8gh5m45ncd7s7swtnkz6296wus2nh08etj42wex9kvfp443wzw6xd3ruuxrmu0fpv9adhhghees023vdd9v0vg0x53g9w22n0hwkf80urj8su7nmqaa5dks79wj3e6zex82l5zzwj6waprhayvzzvst5jl575pcz5nlhvfs4trh6ejd7xrkted3gu6kufjuhdl79c8l6u8gul2qy44ma040d49r67wvdl4mj62avu8fwzec79w3zzummlyw4xmz084e2cxklun82qfzjjqjctrxh5mtmj7nukrlsq484t5ja9k7llttax8nda9ldtzr082knf2tfw7rt5ny54l0ejdnj9w9wfmvu44nu0ar2tyjcd6w5hm7ygf8v6ac4c4fpsx92qtj3tuuw592a0saeucxrw7xr3he950sxf7mr06rckfdmwe0aqwfc087n20lh6d9lctldl5l67x4l2d06vmwgkweku2nwjtyvtt0v0qwcf9s6cry3xh7hasdwg785nmhhsl680m4fxdseavzdk8mg93dank88ue2hned4tarn0al7fl3hsut9d9s2xq6cz48kfhavdvhc2w3v0r0csu7jdx46wket987hth6w0hytsc369hvvf0jk0lmw4dx00tvg8cr42m0n0mqgteleapkfktexc2jw0a540cc93seldk8thuk843fuc3arc4wu9chhqd2anljlc8azja8ukutczk03vjr7hn6839t5484a87tef7n0ukfygfujnmww7tc9sa569a0rm0gpyal3rl0nvhuwhlpn5sr3da5ywknv3tw76cnmhnprl8jvwfwltwrls6mlnaax67855x0wzkt3rcgwt4w2ruhw0fff4khj04nc8zq7qwmeje6m30jxn37vlsfawhnt6kudlmj3aj5uprfx2dxety35k7hqgqf9kk4cv52whvy';

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

    final compressedAgain = offer.toBench32();

    final offer2 = Offer.fromBench32(compressedAgain);
    //print(compressedAgain);
    expect(compressedAgain == testOfferData, true);
  }

  test('Parse Offer', () async {
    testParseOfferFile();
  });
}

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/offer/models/offer.dart';
import 'package:chia_crypto_utils/src/offer/utils/puzzle_compression.dart';
import 'package:test/test.dart';

const testOfferData =
    'offer1qqp83w76wzru6cmqvpsxygqqd3za7dt9hetnam2uuc7u860au4qzjp533dfgzsjnl8em5hcx4gv30s75cxp8tdy7rwk7w3hth8gh5m45ncd7s7swtnkz6296wus2nh08etj42wex9kvfp443wzw6xd3ruuxrmu0fpv9adhhghees023vdd9v0vg0x53g9w22n0hwkf80urj8su7nmqaa5dks79wj3e6zex82l5zzwj6waprhayvzzvstjm0qadf206gml9rfmu66ar5ap3meaasahftuftdfjuu5n7ugljgalkupffmrl9tzx908ve7f24vkr87sj0h4nmqc8645udj2faghd2rn397jxp6v6jyjhzzsq6e8pttz5mqc9xuz4mdhh2ecxldylr70hs5aeemhe9n7hdmsrwgu6jjh7arpad2a8tucm3dlrwmadx4emdd9aw34alucywa9pj9n0valtxftcgn6pyps867tzpl404820gu000xpqeh43gnsd84v63vakmd7v4x06j90a2lrwp849f3aarpfwnkkt7dcxaky9julsf7at447davrj0zplxyawuakvqwkmgqyn5llzlk84eyc73lx7krlu70z5ylkr89sg7elfrxdh70cgan0tw2925l70a6hlehkrl06jzssrt9ka8p6lwrd5etsgm0upukx45rzuva269mtmpa6s7lmet7k43u49ld7elwlcmadytejqkjd4ehlq256a70j47vtmkx636t7c7kzad0wnvtrtamtn3almkkjd9f8qv0ukmqy42e0l07q7xwy2jw6x8tg84azdc7luu5l3x5en4luch85n4e8fe7fhx42kz9vxqsu5tfm5t5ln9crkch38nq786ae6n0psf9yl0mtf494rkamg57qxl3ghk5tn6ha2pj0rct0xlu6ntshx3eun7zu2mfnwlacum99jwdn6ykzfe496afduhvhejtjnyja82d9afrgv7729m908nzmdwemeuxguk2z265wng7qp4uw6x4q77drcq';
const testOfferData2 =
    'offer1qqp83w76wzru6cmqvpsxygqqd3za7dt9hetnam2uuc7u860au4qzjp533dfgzsjnl8em5hcx4gv30s75cxp8tdy7rwk7w3hth8gh5m45ncd7s7swtnkz6296wus2nh08etj42wex9kvfp443wzw6xd3ruuxrmu0fpv9adhhghees023vdd9v0vg0x53g9w22n0hwkf80urj8su7nmqaa5dks79wj3e6zex82l5zzwj6waprhayvzzvstjm0qadf206gml9rfmu66ar5ap3meaasahftuftdfjuu5n7ugljgalkupfgnrq4qh6nvk2927z7kj6la80p273kd6lhfdmlec2l70qehs3v2fyzhlm72tsqnv6ddv2nyrq5ms2hdh7at8zm45nu0f772nhr87lyk06eh7zd3znw26am5d834tka8jrw9h7dmw456h8da4h36xhhhnq4m55xgkdan8lvey09zlgysxqmtfwg07465ftutsaetcxrw7kpzwr5k5nw9n5mdhek5ea2g4l4tu0cv753x8h5y997w6e0ekqlkcsktj798m4w7ken4swfuf8ucrhmmkesp2edgpjf307t7c7hyrr60am6c0an3a25nwcvukp8m8ayycklelrr7vafech2n7emh6llxlcta02g2rqdvzmsvcd33hm6ghnyp9ym0n0uqhhke97c6cn74fdvnnkm4nwc7h4a5u9t4ka9umeyjnk4g08ey8xeqp6kxlv39fq2dp273rwme0ahunuchsk2n00zda27xgwrve5z2am3xu9j6akvp7d635n5pgw7arvjgwwadm7sz6nvjvdgkw6agkal80h9wa7acn0r6aunc0ymf02750ejlcnk7xylleyedk5mcffg276e0lk4kkdkrun82czkwm8p24fnlhw66kk8ka0rpu4skdumqahqj4gculldaxhnalen0rcey7d29yvd052hspqrgcl4x3pv3ehv';
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
    print(offer.bundle.coinSpends.first.solution.toSource());
    print(offer2.bundle.coinSpends.first.solution.toSource());
  }

  test('Parse Offer', () async {
    testParseOfferFile();
  });
}

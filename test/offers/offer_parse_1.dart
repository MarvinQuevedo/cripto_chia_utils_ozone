// ignore_for_file: unused_local_variable

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/test.dart';

const testOfferData =
    'offer1qqp83w76wzru6cmqvpsxygqqd3za7dt9hetnam2uuc7u860au4qzjp533dfgzsjnl8em5hcx4gv30s75cxp8tdy7rwk7w3hth8gh5m45ncd7s7swtnkz6296wus2nh08etj42wex9kvfp443wzw6xd3ruuxrmu0fpv9adhhghees023vdd9v0vg0x53g9w22n0hwkf80urj8su7nmqaa5dks79wj3e6zex82l5zzwj6waprhayvzzvst3jhl8776f36rayjh0tnkw79zdyad8egvc6djwykvja8lcu0jepxxjydqzg3krjar9nwgnh46t48ulfp80368hurdwl508r8493j4uh560aphah86mlxrnecrz84yqd57ap04qtvkt0c7atuhlh0dhmur0y8tpzq6dsyf8k9adfl9f64z8w8adm268trltd7tk6a4tkmt9lyuvk7f7xez3unmnl039fk7d466u0hg6flqvp4w2f5a030k9r6l2u8w02psmh4s4px9kn6c93as0z7pwlsn3r2ex85ncm7h88mgndmultckfp0k99y4x3kmn7dplrglgkcck84ely3h6mcytp4sxfz3la0mp6u3v0f0h0tplkwhh2jvmpnjcylvl5srzml8uv0en408ze2lm8xltlumlrd9glwn9q9pqxkd56uwvhvldsu9mxazln7elw6n9tn6h32vutlkry350nx4hhxf2x205m7k7cma7xzj0kq74rdwdlczlllwu7v4klpadnkw25a2zulda785mjtmmh2gutd22f7dfsdyenmpgkrcl7mll0aqhqu4xk6j6c7xk64ghpgt9r7zak63a9kvedlz3hyemgal8p0ap6850cpsnkcwddlv4xh00ujl0303lr80h8aewufk6weem8v00ph06zucldfnssxxu486ja48q4daxhuh3uv7k78cn2u8dlvn0jgm03hccng686mwr08r46770l3f6582jn4qxtcl0ueltdmmvtel3c92ha4suhffzu44r5l7v0cqsqqkqlt9jtauuls';
const testOfferData2 =
    'offer1qqp83w76wzru6cmqvpsxygqqwc7hynr6hum6e0mnf72sn7uvvkpt68eyumkhelprk0adeg42nlelk2mpafrgx923m0l4lv88wj9grzwn3m3tm3mje2z8eqakrsar8c7gztttsarrpeheddmpcapcqj3xxp2p04xev524u9ad94l6w7z4arvm4lwjmhlns4lu7pn0pzc5jg90lh7x7r3v55spq6cr6rqvrjfj89yekww963zvc32p9naunn8r3w7kwzt5ghz9mzdken2fk2emce32mx9tu6720jhhek4ee3acd5lmewq4yrpzz7js9pdx7tnht0cv2sejapky203q5kzv3kmys5ync95gke95g5ed5gsedkguqj6zh2653sx9m6p2y7c8jtd8mtjut66k855zp9536z7h894rxukw6qfel04svrkcmm3mw7sv4v4xwsw0k5pry2v2hd8fhe80yrjw3cmn0rda5dksx8wls4eza98vlq9z63z84d3hsawvpzgln0eqete8mf9lu6dcufw24wt265j4vv7fym8llruwe4ukx4fm06x04fmccg9x2ehqy44qzre3dx9yrwmla23l0044kmhfuuy30960tn5p6mg3memxxed57cwuu2e03220ut6cllte976n6qtvhjdhctk4jr0r3ftfsm9lu475gcjjcrvnhn9exk5c4lumfgx34l30jps2s7uahfzmnvh0tnr7dmahx3arh407lkxtlj8yy00xgf6ly4llxtxs9epftlllqkz25lusevdcsv5f2zfs7csj9zdgrmgfpapga07g0ye6rctj4jr2zead4mlenev375d3ytj6m86rvdeyghrdc64e2v6a5tqedktgcdjtg6djtg7djggagtqe7cplucyrxaxrh6847pwc0zl6nx22w2h044t8f8lgtr7uyl8exnjlf7e2y4s7axkhnum02v0a0vg82lr7egqc0ram46tzqd6hcrn0adlehasd534tza306tdft85hxqkeh7e3le8sa989hnpnlxxe4zxgs0hsc55pgzzldlchlplv3kmfja4m27l0gtnexu46klx3vxnnnstl6xum0l6l7v6knydshlcp25v3x5a44v95q4qjdcy9nnvq53875dffzcqzhe65qc03dya4ff7vw7hyv4jwt4hjcew4hgg5h0329kwemkn9urhl395zktfq6nsgqdvypzd5gnrrzrfppxs65830hnwpa43g33euh06qa70kmrzl7nn9js2ry4ykdkxh4mpdceehl44askaf7lxknwc3n6h2ma7lpxl328gcngx0ltt607j64egaslmw6g9anx2lusnp4p9dmpf49yaavz80hmwy64c3l8shd8hz3n2u0mlteff0qrquq07hyd3nnv';
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

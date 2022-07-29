// ignore_for_file: unused_local_variable

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/test.dart';

const testOfferData =
    'offer1qqp83w76wzru6cmqvpsxygqqwc7hynr6hum6e0mnf72sn7uvvkpt68eyumkhelprk0adeg42nlelk2mpafrgx923m0l4lgr3d29khell6nhvqag9yx0jmn0nldlzvhp22psmlv2zv89tmjka2625qfdhcn7m0lkm64atv38hydmhz6dtd20v3n42thmhxhu8e4tvnjutwf7l806fhqpkc3766nackt44794qwnpehevldz4r59deja75sf4l95v0am7tu5qm4vjfl70xe9xe6pe7r947e0kfwerphd3d8sntumx4vku49c7kgk45gkkrj6p68376csq3vsar95gaf6qldkycedjygedj9gedz9uyjj9hjcyt3kzm2p6w7szjh08etjatwex95vpp4437zwj8d4rvuxt6utf3w94vhhghmecw23vad9ywvv0k53qyww2ndhwhf80vrj03u6ntzaa5dksw8w6se6zey82l5xzjsu3p87w8h4rqsvmjc5dcxn67dgjwmdkh82n8dfzll4t3hqnjn5c7wns5kflt4lx5zwmzjew0eylw4c6l87kpf83qlnxwhvwm8qykresyxxeqakf07zcgx4cludafp07z0tqvvsndqdrm77840g6wnzkdsulncp8cxe0629l6df57el3qcwa3a08ltpyemldn9leht0e35qy4mt79lsxj82fcnulq7vzac9mu6snrw076wqj7mnxuytkjgndaduqcm3eevsdgr2hvluhms5550lh0lesdzxt77euemmuantj7efj8w3jfggs7zlnmc6ndam3c94yz9l4lgrckng04ehytl95tc3lxnt26k4dgumlm3886hf337utvljuflqhjq9h30lqsfph2sgathtxzaw3tte00zjhs502mka0m47clu79plhsv06g5y5hpl7dnnemudrut7grl7a02u4ql57l74aj34l8gf9t8wa2j75wchmvej0wcx7l0puhrxfstkmgp59rvnlc9sjdztsrsxpcksgx24ry28djty7lmr7rhu0t95vmht095hdlx840hpfu5v8ckda3hfwf9w3p0sydq2z58a4f74chlzmrlltnem88406djc04aartfjhdh6060l5enls6fc0cgfh42lgl4x8v7rm6xv0wr0mfrq70z2lm9ju6l94a2hawtvm05aa42mm8sacthkmxpx9tlmr6t3u8a8a3l88k73sylw65ufayh7742hcnlh3n3s5usq8dpdmwq27ppny';
const testOfferData2 =
    'offer1qqp83w76wzru6cmqvpsxygqqwc7hynr6hum6e0mnf72sn7uvvkpt68eyumkhelprk0adeg42nlelk2mpafrgx923m0l4lgr3d29khell6nhvqag9yx0jmn0nldlzvhp22psmlv2zv89tmjka2625qfgnrz4qh6hvkg92lz7kj6l480p273kd6lhfaelec2m70qels3g2fxzl7mcjacqdhswqczc50utf586umj9lj69uglnf44dt2k5wdlacnnat5cclw9k0ewylsteqzecerumxgtp72kqdg0845h0lx09j86ehy3wtfvhfd4hy3z5vh82h9fc2r3zecue7cp3xndp4s2dqg3jmyw36myw36myxs6cytcfd9tf4qgh0v9s5m5aep48ww0jl92sajvtycj8ttzuvu5vmj9ecd8hc7jzs26m0wn0mjq64jc66tc7csudprs2u54xlwavjwac8909ed8kp6mgmaruza9rn59jvw4mgyx99ejq0ua0rtk8qphfsu73a0nt7rgn7ymj6njnm4v2a6fe626lnqhe7f5ulm0j2fxvtheh45axh6n8lrezpm8ulwtqwrcaw4vjap5srds5d3h8lxml3wu8vuql060h2ngkdx9k0dlxrz9k3jvlf7uruur07jfrnerjym4vky0kyppwxlut5g844t5a0nrw9hudm0456h8d45h46xhhlnq3m55xgkdanhave90pz0tyl7entzvr53qh6hlqwmld23cszhlacr9vhwdndpvavz2ula7678chdhz7t8pjf7c83epx6lchjp49klt0set9jr0lzlzz0wec6ce2ad97nkhans457x3d95sz378gh9h6k2e6ha3028v8w6sr2qevyrgy079csdg3yqt0mhuq9s7d8xtutpx9v2h3rh43r9u3jhdukxlhd5z49mq230nwwacm02u3qycvqefc8xjqvnllq26ny0kk5lw9jad03dgr5cwd7t8mg4gaptwvh04yzd0edrrlwljl9qxatyj0lnekffkwsw0sed0ktajtkgcdmvtfuy6lxe4t9h9fw84j94dz94suks0djls9sr4kmlr9ktardktaraktaraktdraktw95t7tzshy60fe4rfldkcua2va45tl75wxujw2xjra67zje8awhu6sp6v2t9mlyja7hnfulmcpy7yrkde7a3evkqmdlkz6vue8z8nu8cq0hq50mtjwd3um9cjfmxwm5sw6f20h4ks8rwy8fj34qgtal7z7y2ewdnnxv9y7wh9dukjmcer7nk92uwda8t86807a9538lw4tr8mrs5609zpkfvd9fpdq9gysucd5tde34sz6cwzph2yypkpmfplj7lhktjh4w8azhm5lw44vekreweth2y59dkdemkvrlh3shtel9e3srkjx9pqlrlupyyngwfpdcu29r3p43dls8shpcyaazkfd0c8elfmgdsglq4agljdpp66mwfmcvehf93d5nxm7z55lwulea75rd9va2nnwu5zft0chkjeudd970577j5w3r0ccx8zapv8rexv9eu5e0x9vlnq42smu0e384qkk8cpl4lxh0254lhw5vd8e6lh8z0xaqkqphpe3avwjn2vd';
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

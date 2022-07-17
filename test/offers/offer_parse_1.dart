// ignore_for_file: unused_local_variable

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/test.dart';

const testOfferData =
    'offer1qqp83w76wzru6cmqvpsxygqqd3za7dt9hetnam2uuc7u860au4qzjp533dfgzsjnl8em5hcx4gv30s75cxp8tdy7rwk7w3hth8gh5m45ncd7s7swtnkz6296wus2nh08etj42wex9kvfp443wzw6xd3ruuxrmu0fpv9adhhghees023vdd9v0vg0x53g9w22n0hwkf80urj8su7nmqaa5dks79wj3e6zex82l5zzwj6waprhayvzzvst3jhl8776f36rayjh0tnkw79zdyad8egvc6djwykvja8lcu0jepxxjydqzg3krjar9nwgnh46t48ulfp80368hurdwl508r8493j4uh560aphah86mlxrnecrz84yqd57ap04qtvkt0c7atuhlh0dhmur0y8tpzq6dsyf8k9adfl9f64z8w8adm268trltd7tk6a4tkmt9lyuvk7f7xez3unmnl039fk7d466u0hg6flqvp4w2f5a030k9r6l2u8w02psmh4s4px9kn6c93as0z7pwlsn3r2ex85ncm7h88mgndmultckfp0k99y4x3kmn7dplrglgkcck84ely3h6mcytp4sxfz3la0mp6u3v0f0h0tplkwhh2jvmpnjcylvl5srzml8uv0en408ze2lm8xltlumlrd9glwn9q9pqxkd56uwvhvldsu9mxazln7elw6n9tn6h32vutlkry350nx4hhxf2x205m7k7cma7xzj0kq74rdwdlczlllwu7v4klpadnkw25a2zulda785mjtmmh2gutd22f7dfsdyenmpgkrcl7mll0aqhqu4xk6j6c7xk64ghpgt9r7zak63a9kvedlz3hyemgal8p0ap6850cpsnkcwddlv4xh00ujl0303lr80h8aewufk6weem8v00ph06zucldfnssxxu486ja48q4daxhuh3uv7k78cn2u8dlvn0jgm03hccng686mwr08r46770l3f6582jn4qxtcl0ueltdmmvtel3c92ha4suhffzu44r5l7v0cqsqqkqlt9jtauuls';
const testOfferData2 =
    'offer1qqp83w76wzru6cmqvpsxygqqd3za7dt9hetnam2uuc7u860au4qzjp533dfgzsjnl8em5hcx4gv30s75cxp8tdy7rwk7w3hth8gh5m45ncd7s7swtnkz6296wus2nh08etj42wex9kvfp443wzw6xd3ruuxrmu0fpv9adhhghees023vdd9v0vg0x53g9w22n0hwkf80urj8su7nmqaa5dks79wj3e6zex82l5zzwj6waprhayvzzvst3jhl8776f36rayjh0tnkw79zdyad8egvc6djwykvja8lcu0jepxxjydqjtn9h8xz6d8s3mzf8ral8amjf6jcqrhw7lltj6snuurx2hrymsgtr5840ue708q0gj5q8ktc5fl5rd2cdmzmh0677eakl0c0ucuuqgn2kqs5cchh4tu4r2vtac794dmtaywd0hewm0h9vmd0h5jpkme9cl969j8004lyhxr6kl2mn74qf0a3jx9cf2j4697m502d0saeavxnv7xr5gex60tpk8kp6tqxm7z7xdrxckj080zaulvz0hhja8rex9w65ujy6xtd0a48udr7znzju7hyu68lf0g3vzksmyzyl4lurtj83ey7laux74m7a2fjvx0mzn9s77puf0ya3alkg45ltd202um70ljl7d5kre6ukqyxq6cx4qk3mhr04cstf7cr6594lhlstf22tf89crlyta8ha0z9wl4p27dd5gd4zs5t7kx0cdgkn6uplaxxgsr23jhxlupxkvdaqq80je22ld84l2sshttdjvaraxvxxma9mn3l64snte2taermqu8dxmw2va6n22aduc7wfksjk80y95zujhkal2799awylhyu6peuqmyknzhkn529g5yj7lv3ad4zjtr8je9muymj0p0r50e9y72ukk02m0mgm4dfjk0xe5a8lpkhcea8kakw7eprfax46969nutv0run6mycjml80jl0g9cqpdcvnwqf3prtk';
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

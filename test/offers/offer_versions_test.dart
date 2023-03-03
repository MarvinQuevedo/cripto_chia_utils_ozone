// ignore_for_file: unused_local_variable

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/test.dart';

const testOffer2 =
    'offer1qqr83wcuu2rykcmqvpsxvgqqa6wdw7l95dk68vl9mr2dkvl98r6g76an3qez5ppgyh00jfdqw4uy5w2vrk7f6wj6lw8adl4rkhlk3mflttacl4h7lur64as8zlhqhn8h04883476dz7x6mny6jzdcga33n4s8n884cxcekcemz6mk3jk4v925trha2kuwcv0k59xl377mx32g5h2c52wfycczdlns04vgl4cx77f6d8xs4f3m23zpghmeuyfzkwqucw8z7fkdd9a2ud33xtjlh6uuthljc9wvfrzg8at6xjq996yn00x9gyjskxpmyaw0mvrz5wp63e704hmvu02e554hlnxgua0lfz4tz7356aettllxuejc4pzggwu33hm3t3d8u5wtq48e78uh4vy7wl8u962dtz03cclcqjat3epwt06fekaaer85fe67kjxlhymj6dt2j0s03aw7ddtudavfys5mmh3lhpl9y3kzwqsmxyj4jsqa4zke3c9a2g8xeuv8z4rtu357ky7n3azrfly6wv7jq094le2yhv2hzum8faln6dh3f4jm3u2ugzr332empyp7rdynw7y2jlt7prtdkqzfallp08wl0lhxmrx05fat0h27z3mfaak7ta3x2whm6wec28gkuu7mll6x78el8lndpsh27tq5vqqxhv0chcsvpc6r2frhn0jpc8wr8z7442j9lttee60n0aweh48w584d4fu708svr0pmtl4lgpewx6l34p0ut960d003hwr2ulnnkm2te5dcltdlrd529ulfgjgwh3pkupgr89rr9sgmg7dve0mvye8m4n497wc8pckkzvzclhc0lguwfwtds0ns2fvhkej96886xy5kamwlw0wf7h700r0kym0me6kkk5tlv0jmlppl2cn2a5ycmmddl2ha7m203lj5mlxa79c6hctl6lh5lflkdjw94mjaykfuctfnsrg078ums9q9v6hua66cjlw008hn6cj83dkahlstm34hmrj4aqkn68yhdzlvzklx5mxr0t3v5lrkkft6z29atev6y6ux7p8m4949p7vrqnaquuh02pj4mtlcu8r663fk2t370udhw2rdu74mxrse78f2l7d7yladhylhm087k4ht2420mdk7z72sg9hturj9r5kdpdm00wc8rn472k86vku4852vu78st8487kghafaer3te6wvhnvn52e9ytzhscanqpr865mwn6vycw';
const testOffer1 =
    'offer1qqz83wcsltt6wcmqvrsxzgqqr277t08njw6pa3cft4cre2t4w7n7dwc0xwtze6dknzvlk6j3f63dw9yc8fupxm95vgd6mkzx9wmdrzndk33phtwclc84p3gx98wp0x80lww0pt4469udhhxg4qymj3mzr8ts0xx0t5d33denkp4h0rdv2c24fxv8kmnsgh2rnestvxznc09n8tjgwp7tgeyawq666vfknkznljlg5g9tf25q6ek6xu79vqxfyk2s7lzz67xm2g2m2cyrww0mfyeleweastff9l6asllkezs7nk0j7lnqpv7sq2t58jk2tjwkz27tuwzlw6faunva074cmwuhw3wqak3jjtmd2e0k6wllh7zkr345qc3pfq4vjjczkhjndfd8mz0mlzlzh72206e9jdvpe0nu3a5uh8930xkv62uj3eauc32zr0f5ly5ctgsntaytwp9mr54l2hynktavzllh6prahrwdml5q8kef9jl3applge56cr88k4nxpqehxjy9fx0l4lhdtzjewe8rjua92h459j0e67mech6umdmmvu7euc3hdrwp6wh206lune48cck7g0ylmhfez9s26rvs2n7hlsdwg78ynmlhsm6h0m4fxfselv2vkrmc839unk8h7ezknad4fatn0el7tl6k7xae2rcertqg597umg2eudw8m2uf00tdl69v8leyvcn2alm6gs6a2wyzmds084zaz880lxc437px50ymlu933d5gn27f6h3nvxajfyl7320wlvd8m6k32akuvu2emahne2ttfr0xe3q9tahlz7j2nhl9vqgkfzh6cr6umrwdvhlvx7xnazahur6w8wkl5akpw007dplmcrsnj6mkjmd7g8l6e3de4tf0exk65dl5l7unkn4jg7ew009tdled8fekj58g50mzyum3vh8ewe6u4wtf2l35c5hkpfyn0wdwmn6ar3da6mj507pw2qpev4ec5f4gffvt35kfhh7clt6m6nfca60j8d8nk78k490rf2djt6m57dvakw7d6ut5kaw7t8ajl7dkuprmhm8wuu0myasag39p0dhlzuwtpang3qcluypwk46wrmvdna26dt76tpcmp7needdmw4c0zudkjpdtsp7ef99l78c2dxg0l5ag88a00rjusddrfpcg4rkxsen5jj2vxvhhj8xmjlnhhn3h8uhjt4auu6evrlyauu267nfhupan236zymel7fvk883yalalqy3cdy0hmhaluygkx074vnjjm70x29650wrckt6h9lh8emkpc3w8s4flkxm7ku852w2k7sgfts8ry8xhxal9zad2th5usyvug4rvelr7kskt0llj6d2qza2rrv0mk9wx4x4g6qg0k6wndevekrtlxnxejwhhk4tx6chd5f0lw9fl9me8nvwc7phkcectwh0wthu08yt6kxpv84trtaqhnp4fjp9hepx9esednyhwpvnt6zjanyfu7v02478raeum4x7al8knf0h6q49a5uynx6amclssufhr55etw8ske744r5l9y53kvnhad5ujsl2y0fulwujtnektvdcxphrafdvns44hutrn3zatllv3nhqjegatjdahl0df490llnjzmhwfw2a5cek74xdzc5ngwlydym4ywwxdqhmuwhtn368mpxxet2e2fqal7wa6psudrl26wlk24kwvmlakddhyxlxx5jlz9ps77xpj6sj0r28y7yyelk4znw0lmmkn0jvtexyfjjunckzcypdlpp4g2ah0mgnrezllwh6kzhwwjmrfl6mx30ujf00h09z5e7ur0dqu0fc3zce3fdpl3zxen0lvmd3tw8u6cxkj0203elmw8h7f2a2typzlj5rx3hcv2wkkv7ax7jdg3xrpp5aze2fsrgeafrse6hza8uhrvd6z0kkvmjl4xtlstnmrn5emdt3gu0acq29r6f878ha3a07ywlfelyuzhs5swgmet7yh8pzd4e64n9n56u4z3eup7t3gwln7wykupxrp4cfme7nlsnzuc4knxa8mkfh0dxk4693fhe467r2m6uh2wyla7d876v944han4m7cqjqcntuhmkt46985fj5n47wlx8u5lqnycjxv3gums73p8n7g4cuae7phs2ej7fdutzs73zvevt4cv6gf4fxtlgnt3q5u6t4ead4gmvyc59pea7v766juact06juynnk5g0zrh300dmmu42zhx27xww89mqe2txrk0sa7a9law7plhg6den4ey4ugnwaagakl9n98zcqs9kavpl9mvw5mlkjzwrd7e67mccg3vvudqknnapsapmwn52wh62jddu9jc7lljhl4kmaztzk9gsemut409yc8elpk3rlm07846q7tn8eh627l7tepydny954nx60x9xcetu0hz4e9uemdcnl336uy8ttt2uzvhnv2zkdkn69cmdw9jwutgvslrn6ntwll32hwga38l8568hutptwu0jtklr5yejmujgdqnqgldlmndkzvtnz6lv9mhnc9h3lv77m2clr08vl5hmh4l3z7dh77fwf06wq4yxm4eu3lk4h0z0a0uah6nurvdwwzwlmawt8hyv3kv94vjdc95u6mam4wkk7047ed04jltn00y47n4k7x9qanmhejklmm6jh2a83stucadwhsm9wgvndxwvx3dl0rnj24yvtp880ejt9ejwkdxenw4u8kxl0eyp90afa46kpfnnchmja3dv8q7s7884alx4cc2s4eawjqg4j9qgqr9y2mkqcze7f2';

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
    final offer = Offer.fromBench32(testOffer1);
    final offer2 = Offer.fromBench32(testOffer2);

    print("offer ID = ${offer.id}   ");
    print("Is old = ${offer.old}");
    offer.toSpendBundle().coinSpends.forEach((element) {});

    print("----------");

    print("offer V2 ID = ${offer2.id}   ");
    print("Is old = ${offer2.old}");
    offer2.toSpendBundle().coinSpends.forEach((element) {});

    print("----------");
  }

  test('Parse Offer', () async {
    testParseOfferFile();
  });
}
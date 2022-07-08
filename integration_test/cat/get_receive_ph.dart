import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/test.dart';

final puzzleRevealHEx =
    '0xffff80ffff01ffff3cffa0645a84a987c09e47959a2312052bd214229640235fa6535d4ac1ec9a2730a41580ffff33ffa015e64951334bda18046f42f861dae0a288f656629fc6329fcb24eadc29f4c913ff8203e88080ff8080ffffa02d3b8711f2c0d8f2bd781844d764dbe8b3b17fe2038e58ac92d6ad119b16ef67ffa0dd5657437e2dd29441676f6c8d4266d2f95433c86eb91e0be3d773043ecd8587ff8360216080ffa0cf793374cf635de7590ec33969817a6c2f2955d34e94981eb568624395f758f0ffffa01a734b2ae56907dae9fe85da1d9bade257f88fbc2e9948330d1407b3b88ced2fffa00027cd6d248ea52a6b77fb23a3a827185bc38c9048327364bcf1bcc1ef91860dff8203e880ffffa01a734b2ae56907dae9fe85da1d9bade257f88fbc2e9948330d1407b3b88ced2fffa0426ee909d614446fa2b6a7bc9bd3d8a585e03f10ff9775c5a25e4bd47bc55dcdff8203e880ff80ff8080';
final puzzleRevealHEx2 =
    'ffffffa04226e62cf7981882d8262e2dcdbc5a1b847a50bfcaf9446d7bfeb6c4eee8f7bfffffa02917cba3bedcdecb680dfc97e098502575121c7d48a2ab5d5d0913ea93e99669ff8203e8ffffa02917cba3bedcdecb680dfc97e098502575121c7d48a2ab5d5d0913ea93e9966980808080ffffa09c9ead89422a1d047e519c28ead504fef0fb0355295692848977ac998beae44effa06ed786bd83e93ccb7a8b394ef5cec0c485f97e65bdcec44bbfb46e743045dc63ff830f028a80ffa0e06e393130bba4d1e1d5d209bb930694ef9e089deddf21913d5549c023cafe3bffffa071475fa5b3041b85285ed6082913bc33a4fca1847754b0c6b78cb9d59a1662d1ffa0be005954a4f8f876d68adc8eff0e5c4e9eec7507423ec6bb42d3dea9a553740cff8203e880ffffa071475fa5b3041b85285ed6082913bc33a4fca1847754b0c6b78cb9d59a1662d1ffa0bae24162efbd568f89bc7a340798a6118df0189eb9e3f8697bcea27af99f8f79ff8203e880ff80ff8080';
final puzzleRevealHEx3 =
    'ff80ff80ffa0de6b3aeb866362449ac46bce24f9c340e989399fb81237fea9c58b21a8af5330ffffa0715f08ccc1fe31fd726661a20fea86bbe467a2261ef602f0bc18badb5bff6057ffa05f194cf98cb9209c8c8817aee0a1c0fbdb011a09aa5b74699b0d2392a7015e0aff830fa00080ffffa0715f08ccc1fe31fd726661a20fea86bbe467a2261ef602f0bc18badb5bff6057ffa09d72291b29ec40ca0a0f0d2843dc8af1cff132ad1d0d3ce07a4727c406f9ff50ff830fa00080ff80ff8080';

Future<void> main() async {
  test('NFT uncurried test', () async {
    final toFind =
        Address("xch1zhnyj5fnf0dpspr0gtuxrkhq52y0v4nznlrr987tyn4dc205eyfstsqtrj").toPuzzlehash();
    final toFind2 =
        Address("xch1gfhwjzwkz3zxlg4k577fh57c5kz7q0csl7tht3dzte9ag779thxs2cwpgr").toPuzzlehash();
    final puzzleReveal = Program.deserializeHex(puzzleRevealHEx);
    final uncurred = puzzleReveal.toList().first.rest().first().toList()[2].rest().first().atom;
    print(uncurred);

    try {
      final toFind =
          Address("txch1ht3yzch0h4tglzdu0g6q0x9xzxxlqxy7h83ls6tme63847vl3aussy886w").toPuzzlehash();
      final toFind2 =
          Address("txch19ytuhga7mn0vk6qdljt7pxzsy463y8rafz32kh2apyf74ylfje5sdd5csy").toPuzzlehash();
      final puzzleReveal = Program.deserializeHex(puzzleRevealHEx2);
      final first = puzzleReveal.toList().first.first().rest().first();
      final temp = puzzleReveal.toList().first.toList().first.toList()[1].toList();
      final uncurred = puzzleReveal.toList().first.rest().first().toList()[2].rest().first().atom;
      print(uncurred);
    } catch (e) {}
    try {
      final toFind =
          Address("txch1n4ezjxefa3qv5zs0p55y8hy2788lzv4dr5xnecr6gunugphelagqdjwewp").toPuzzlehash();
      final toFind2 =
          Address("txch1heptx67wm9r835ugdd07qk7frecxahzfrrrfrd0z7kznz78q2nws7ukzlr").toPuzzlehash();
      final puzzleReveal = Program.deserializeHex(puzzleRevealHEx3);
      final index = puzzleRevealHEx3.indexOf(toFind2.toHex());
      final temp = puzzleReveal.toList();
      final uncurred = puzzleReveal.toList().first.rest().first().toList()[2].rest().first().atom;
      print(uncurred);
    } catch (e) {}
  });
}

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/test.dart';

Future<void> main() async {
  final offer = Offer.fromBench32(
      "offer1qqzh3wcuu2rykcmqvpsxygqqemhmlaekcenaz02ma6hs5w600dhjlvfjn477nkwz369h88kll73h37fefnwk3qqnz8s0lle0xz6m5e3g28v4llhrfaelmhcmuclnun6lyl3jtkl897at2h7md7g3xvrh94st7yksd7l4lt3cvka8968va8kghveajdhw08xsuz6890w99nmdfh0k074ms37epvrtqd2p4ajrunk77e605rna8576kd89j08k4q4zkl0tnj3e2aqv8cljpms7k3vvxah5s77gunzx0lu4pavvl7djvfcu0h4cjarllaay8thh4a43f5d357uvkr5yxxhjrwwjsxva9run7wj3xgzzwj3qd9a5rlf250s06ae086u80x5ndhfe6f8hm4ruufl5g7vvfzjmm488avd9vml07p2jzvw8auq90zk3te6kedxwnnn7afgjudjna780nph8fv6wk469gax9mu87gw5eye6qc2qmgmlege4sutd0kwezht366k7kajw9v4lyhns7k3wsndg2h8cp38v759xsyxyancvma5enuqzt7cypal70qvhljqjhvrsxldl0kd3suk6mxj4wt2txevhws7qh7t8nu3pmqlz3ltl5q7jxf9y5rvv4hel9ycj6v4fx5ejxf6f8z5j7wfz4vh47f95mz6tpj95evu2w0frxdf43d9tgn2t3s9uhvkjws9chvlnwv4mx2mj949ckawtf4f0xvs26k909ukjfw9yhu5tz0249unnxt6m8u4r2dxc64yvp0agmuhn6vcddq6gepwhze6xm73ktwhktsgzk5j7ldc98ketkv69atf54k4r72rxn500j7kpaullllfju5zday68x5mwdfykyjnzfy39a4n30c09qjvs28w2dc4u6pgwqugfppx2tmzvmqc876lj7mfa7argjchlmu0n7vpj4m5l82ekhk66ckf7cnjm4awfu70f02m3vvhdw30qeftfpm8fhrwwnwglqnml68umxcnrpxl0xe5sxth736khj44a0v2gqu5dlhlsvg7d820u3vh6m5s4hum37z32xedlfn6ap54xetlvkxlp4u2e4clkm3q0dqlqa7r77k8kef2n3tzuhtu4efh33tunms92tzyun50e48gln298x5lld8wt0g3urgpav4jy4jq0y8juq85dj66cd6vgzxeuv8rka47pjd6ktemfm87dgdkmlk6uxlzxgct5dlvkumasul5tal9g72lvzagta8f2f7n6yl3et7q8t9883qk9fmxqy4lf8r34l796ce9c062ssx3frukxz0tslp0unxdeajl5u0ljv77w28v5glctnl20ndvxtgqp5xcq8qwdk7gqxdnyx6qdpu9gys4sqw6cs32syq74lmlc9eah2w83ayxak8cue5c2nl0f87vnm0vz6f88n7e065mh2vs88vewkxj2cdmwf5v5ng4jh5s7um0aqqxw3uv760kec8az367vklnuvmj5ua0tmv6757hy96z7cax7waa0v7nm6wthu8hgj7lx654kxxcdecz307v3fxutpekpju8tluntjp3wth05mjltugnhq9ev93uk7gx276cpezlmmy0v6cy02wqq53kmlj33rudy");
  final assetId = offer.driverDict.keys.first;
  final constructor = offer.driverDict[assetId]!;
  final spectedPh =
      Bytes.fromHex("8be21252ac937eba4b46b5cbaa2da4855948686d17dc8f706acb3f2a29773de8");
  print(assetId.toHex());
  test('constructPuzzle with singleton info', () async {
    final settlementPh = OuterPuzzleDriver.constructPuzzle(
      constructor: offer.driverDict[assetId]!,
      innerPuzzle: offer.old ? OFFER_MOD_V1 : OFFER_MOD,
    ).hash();
    expect(settlementPh.toHex(), spectedPh.toHex());
  });
}

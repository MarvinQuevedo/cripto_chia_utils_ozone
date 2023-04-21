import 'package:chia_crypto_utils/chia_crypto_utils.dart';

import 'package:test/test.dart';

const spectedMetadataPuzzleHash =
    "7cbad8199fc4f5cb6f44c88de7ca20c07be7a28c09b11ff9da4bb9988c09a945";
const spectedPuzzleForOwnershipLayerHash =
    "f5fb52927eaef26e4b5977dcb8574b5fed24d99ce2af8b7dccf679125cfc8b6a";
const spectedPuzzleForTransferHash =
    "e9e755532f80627d5aeed8bc49fa4335bc8f4d409d16bf29dc4e68859a398684";
const spectedFullhash = "c8109361adf2cd32c07587312052ddbc8bf61eb4644fd6351e1cf1f814f272fb";
const solutionProgramHash = "0a8c55bdb3469e3cefbc32f44e0eb94bb9cc79b0b233f9446226d550c463cb01";
const solutionSingletonHash = "6f3366dde8f47e162b79cf95444158f44cdb5342e678f6df8277815c80c854d4";
const solutionSingletonHash2 = "0926ea4d51965585194d8eee5693c65e384ae3820a88e6e644526f1ed0087c6c";
const solutionOwterProgramHash = "8238fa19e27bb63cf6663356aeb04847bf7b79158b799b8c329493f46ce6c5a6";
const ownershipLayerTransferSolutionHash =
    "b8e85e13914851c8969030ced4dd64d4f2967dd2b6e70804523ae0d8d1f0e093";

Future<void> main() async {
  final masterSk =
      PrivateKey.fromHex("0befcabff4a664461cc8f190cdd51c05621eb2837c71a1362df5b465a674ecfb");

  final pubKey = masterSkToWalletSk(masterSk, 0).getG1();

  final puzzle = getPuzzleFromPk(pubKey);
  final puzzleHash = puzzle.hash();
  final parentName =
      Bytes.fromHex("7cbad8199fc4f5cb6f44c88de7ca20c07be7a28c09b11ff9da4bb9988c09a945");

  test('Metadata Layer puzzle', () async {
    final metadata = Program.list([]);
    final updaterHash = metadata.hash();

    final puzzleMetadataLayer = puzzleForMetadataLayer(
      innerPuzzle: puzzle,
      metadata: metadata,
      metadataUpdaterHash: updaterHash,
    );
    print("puzzleMetadataLayer");
    expect(puzzleMetadataLayer.hash().toHex(), spectedMetadataPuzzleHash);

    final solutionProgram = solutionForMetadataLayer(amount: 125, innerSolution: Program.list([]));
    print("soutionForMetadataLayerProgram");
    expect(solutionProgram.hash().toHex(), solutionProgramHash);
  });

  test('Ownership Layer puzzle', () async {
    final _puzzleForOwnershipLayer = puzzleForOwnershipLayer(
      innerPuzzle: puzzle,
      currentOwner: puzzleHash,
      transferProgram: Program.list([]),
    );
    print("_puzzleForOwnershipLayer");
    expect(_puzzleForOwnershipLayer.hash().toHex(), spectedPuzzleForOwnershipLayerHash);

    final solutionProgram = solutionForOwnershipLayer(innerSolution: puzzle);
    print("ownerSolution");
    expect(solutionProgram.hash().toHex(), solutionOwterProgramHash);
  });

  test('Singleton Layer puzzle', () async {
    final solutionProgram1 = solutionForSingleton(
      innerSolution: Program.list([]),
      amount: 500,
      lineageProof: LineageProof(
        parentName: Puzzlehash(parentName),
        innerPuzzleHash: puzzleHash,
        amount: 502,
      ),
    );
    print("singletonSolution1");
    expect(solutionProgram1.hash().toHex(), solutionSingletonHash);

    final solutionProgram2 = solutionForSingleton(
      innerSolution: Program.list([]),
      amount: 500,
      lineageProof:
          LineageProof(parentName: Puzzlehash(parentName), amount: 502, innerPuzzleHash: null),
    );
    print("singletonSolution2");
    expect(solutionProgram2.hash().toHex(), solutionSingletonHash2);
  });

  test('Transfer Layer puzzle', () async {
    final _puzzleForTransferProgram = puzzleForTransferProgram(
        launcherId: puzzleHash, percentage: 5, royaltyPuzzleHash: puzzleHash);
    print("puzzleForTransferProgram");
    expect(_puzzleForTransferProgram.hash().toHex(), spectedPuzzleForTransferHash);

    final negativeProgram = Program.fromInt(-10);
    print("negativeProgram");
    print(negativeProgram);
  });
  test('OwnershipLayerTransferSolution', () async {
    final solution = NftService.createOwnershipLayerTransferSolution(
        newDid: puzzleHash,
        newDidInnerHash: puzzleHash,
        newPuzzleHash: puzzleHash,
        tradePricesList: [
          [105, 165]
        ]);
    print("puzzleForTransferProgram");
    expect(solution.hash().toHex(), ownershipLayerTransferSolutionHash);
  });
  test('Program At rrf', () async {
    final p1 = Program.list([
      Program.fromInt(10),
      Program.fromInt(20),
      Program.fromInt(30),
      Program.list([Program.fromInt(15), Program.fromInt(17)]),
      Program.fromInt(40),
      Program.fromInt(50)
    ]);
    final p2 = Program.list([
      Program.fromInt(20),
      Program.fromInt(30),
      Program.list([Program.fromInt(15), Program.fromInt(17)]),
      Program.fromInt(40),
      Program.fromInt(50)
    ]);
    final p22 = Program.deserialize(p1.serialize());
    print("Original");
    print(p1);

    print("Expected");
    print(p2);

    print("Result");

    print(p22.filterAt("r"));
    expect(p2, p22.filterAt("r"));
    expect(
        Program.fromInt(17),
        Program.list([
          Program.fromInt(10),
          Program.fromInt(20),
          Program.fromInt(30),
          Program.list([Program.fromInt(15), Program.fromInt(17)]),
          Program.fromInt(40),
          Program.fromInt(50)
        ]).filterAt("rrrfrf"));
    expect(Program.fromInt(0), Program.list([]));
  });
  final launcherId =
      Bytes.fromHex('c8109361adf2cd32c07587312052ddbc8bf61eb4644fd6351e1cf1f814f272fb');
  final eveFullPuz = NftService.createFullPuzzle(
    singletonId: launcherId,
    metadata: Program.list([]),
    metadataUpdaterHash: NFT_METADATA_UPDATER_HASH,
    innerPuzzle: Program.fromInt(1),
  );
  final announcementMessage = Program.list([
    Program.fromBytes(eveFullPuz.hash()),
    Program.fromInt(1),
    Program.list([]),
  ]).hash();
  final assertCoinAnnouncement = AssertCoinAnnouncementCondition(
    launcherId,
    announcementMessage,
  );
  print(assertCoinAnnouncement);

  final genesisLauncherSolution = Program.list([
    Program.fromBytes(eveFullPuz.hash()),
    Program.fromInt(1),
    Program.list([]),
  ]);
  print("genesisLauncherSolution");
  print(genesisLauncherSolution.hash());
  print("finish");

  final offer = Offer.fromBench32(
      "offer1qqr83wcuu2rykcmqvpsxygqqemhmlaekcenaz02ma6hs5w600dhjlvfjn477nkwz369h88kll73h37fefnwk3qqnz8s0lle0zr0r87ulcye7xmv8jdmxf8vw8znljhpfym4yhjk6t8s47f7h0wem4lcy9gu4dulwcr5mavxct8aj8refx7lk9z667vj4pl0mrgfn6uv9y49f8866lahkxyll96mcxqtv3aa4c4dahxh9pzntfmhfyqla7alpaatchwsw6st5vnsf9z4rl7uwxthvz935cjggf974pw8lme566wz070gvg2v9wwfv7xgaad9tsk9drwfsrrf7gev0cgvdlxxua9yve620c8ua9yvcyve9jz6tmgr7j4glpl4mzu0acw7dexmwjn5jl0hz8ecnlg35cck944hz007c2gellluzw0myrhknhnffdnw2276uk7eul9yu4s5tfda6u0tvhr52rxm6u72e8n5z7u0549fuqvfqafraevm45umg0xwe2ht36k57ua2t9ch0xkmj76sw6j4g2hygt3lglsxx6ykqar7veuyanuqj07q9pd7w0puhlxrjevtnxrv00kahsy56l824wt2myeynw5lselrrnyn3lqh930f07pcjxf9y5z524h60tycj6v4fx53n6w4eyyat9ffyhn2npde8xnw2f2eyky6n3t9z4z7te3xh9y4242f89rzjev9ryjsj20xmynwd9veay2lnpfx0gvst6290tukjf29yhu5tztf48atjxtem9a2d3sk02zhj62qkajjc2r2w837acqd9pgusxk9mhdzv8t68pt7cnkjdad6k2eyeudc797hehl0l0afja5p33y682nzkw9lpa5p4f5u5px6jdpn9xnnxwf49uud2teq55xkgkt3re5psvdcsnzxve4vtp7hs72khyhmhddd4t8t2um2dmgy4wj5ak44yyllsmgmcm0qh7uvzmdquaj6c5z2waxnaa8wgl4u88e5njndfvm4na0x3gtpjhgh7ak3t0l7cz7rawp7qutu4l9ahnla2y3an0nkcl8umrd28t775n9wah43wnes88hn6uhevcj7hhwc3f24rxdmjs7t8wnnxua8x36q8hl50emwpzx607jvmnqu504r400a2tjlc5sf6gn7laqsnu7w5ae2m03kerthch8u4q593mkn8h6n22pjm0779vlc5luxc7j74u6ylyeah09wttwhzhaukedldncwq6jak7huhy2tzyun5sek8fpnv9rxfpld8w0nkcs0s39nadkulpxyaads3nqjad42n707xy5u0wdmc3447eyvj0tpw07qqecszxw6qajrewqr6yeddvxakwptv7zrxn33ad03w8x6hmu9j4krnd0k4927c7rfwlu6w9q79t4l7htuwmn38rwla6w46dfrvdsg6mxp38q3h0kwnur6kdgm2q5hlluhe3yx4rflk8saah7fn5henc7kf6l8amyyuwqmxkhrxwa0dv0n6k6mt8079lvrp8thlg2uuvtdmjrtu67l9qam6hxj74n32c8ystmzt458v7jwals7phmpj6rypfkxpcrnphzqprl69ksrggstfy9uqn57gy2jp5cfk8hrll0lsh4jgaukd7ehhjxplmzxe49627cc9pvk8yll2hk77qxxmcr72e3eddqujejew6jgllxk6nzmaegd6azhur70d9ul5cvf502s32xveym7l9c6eahgqmpslgk8ytluja0ua6v73vpnvp0248sxzzt5axudcu79d0zspsea9mahw8dk2lhu54yghca05lyr8997dgtnentg66a49ktgaknf8d50fvwhnqqqpsacksvveux7y");
  print(offer.driverDict);
  print(offer.requestedPayments);
  print(offer.getRequestedAmounts());
  print(offer.getOfferedAmounts());
  print("-----------------");
  final nftForNftOffer = Offer.fromBench32(
      "offer1qqzh3wcuu2ryhmwudd2pxec6qrs2c4k3d2742tqz4m2kmsgtqmyp66j9a6tsqzgfq8fpvcvjfjfvjfpnyxf5ctn6efwmgk8362a9g9pz2fw9pqdzkht95n0f5f2zchn29knj3g44gr245zjash2kt95qa8v4928utpare8kf3ljvl9l0008nhum7n9uauwdp2q5px2y009zlmm0ukh8h27ydaf4xaahdxmuw4nkd6w8dv4wa90upjna0aal5u98rrrm7kaf298kh7l8pgp9rk20dcsfjam2ru7mrt0vjyc78na2ztd4784xfk4tjfcvllne4c6jpzg3ljp0lze570ct4ykzrta86dtn57hv3esp9d2wq0hmc8n2m5axt5dln7gn6nwwzjn5dftpdwwkn7agezerly5md7faj3m2qmklr0l2hvxtr8724v5tu5c7thm7we4v2ga9lmmlxg8a0a7yuqzjw70aahclh3sjm45cjtzfc97lxe4t2nufs7c3jycs8nylx27tykx24h5lteeyfm043catpypkgq5406a30ahk7zfqxa95qjrpzypfvymgvqp44rgxs847rqeq2ds7drr8xd2p9z695gngrwxk4yruq9jvvjd3tz4nyfjaqgfdrj3j9u3ayerl2qqz5s42rprkvmuhnvdfmtzrzyq52tdtschf9jts7er7s7ap7cah49fafvlwglj0mvhhrv62gvd852nhmuccg9jxjp3zzxxwldp2p3zsvsjf628jcfgmxujafyy5cscpq254e8kchcvgrk4rp0tamk3nf3hkh5lvwtdd0gn9pgygj3hx05wkywhhy23pdm4ck93l6lch5r5n577mcft4ky3fg0jc6namkthmm9grh6e8valluq08f929y7s05kllvwldfhxxwwuwwnl4hhzceaffhwmrqf8rwmgkmpdyu89a7ejxph4d4d8nm543p7a83n07prdj4ktml8xl2y9an7e80uuclzyryaan6e3lfel5l6r8d0h6lkmue4v4jjmh3nmt6cr08st82p8rlukufn7sw65ymq4d44k0pus7rrnaa3vxm22egwshk2z00s8s27yna7ljes5x7mtmu6slv0wt9ukkfmu77m262ac6z66nwpl8cv5nmv2cmljl75xnzh6qc9adjs7tnrt95ncxxyxer4xxaxyax0luh2gm50sggfdvkvz0el05p8k2j38ycmzetp3aakqpmsnhlatf87pxeptqe22ttku8qcj0sufjm5n8x2f09e8m9dtmy4tn6hqw8xmf79h0j4cymemha3cdlc70v03cwk2hanagdzjhxg9gfaehckak00hlf69j9vekhkl7s7yjck9nsa9hjlj7elaf80l9u3636af30mt0f799430m5e6waezke02szarvkl0rmp20um4fa227dlmvhyn3errz8jzx009pntefejz8yt4mzae75zex2wkznzqjmxcjkxjem07mmlzrnp4a7w5uvj7pyuwx4t0n7rv0vj78re9uzw8vcqh5gcgyqsd2qf4rmu0c3zytzn4fptxcs95xqurlkx04ucctfhms3sv6u9sesdx6csq5ngrhr7zjtqhcvv993n3npxg565vgcrpeffj2k9rv84xjv44zdj25rzf3ys69cfxhazqgcye364krvqhfkppqe7g6r2dq2sacksas9y3k27w6k6zsqsry6955y44vck5gq96qp4f2g6xnymmm27778d8upz2qw3xzpvspvvte8t0jjxd5fyshxtpgac6uxysc3g8qkc3tsf623xj9x8qf43anvlvqmy0x2ntl77mfwuevvpkqnt9kxu0nx0uep6y3vlkaf00hzg9t2f6agvrseuwy2jj5qjhs6vpqp9asu266pnn5pqyq0f9z8m7p7vcw287lqzgyn0jy8h7pz7eqznz9yrkzjs7j54r33e5xr2qayd9qm6sddxp5yq99yk0vzd9x9gz2sqmsyyqwk9q5cxjyxt93qrgkjup0gnfg4xef8ftp0d3jcww2kgnyzsds3rfs2cy65e3xyuxsvv2r98r4zkepycm4spqecser9xqf3ucc2dkphecchm35ssz8fsz9pfrnph9jxzacttsgkjcdgeemfydsef34yk9pdgmyccafhygazaqdtj8avgyuggnfu9sg3999p69462y5rrxt2dxfqrr2dy9z2kh9yyn7rnqtzvzcxqyryf9axs9fz2z3rdt2ggkyvdy3j0q4sck8n2qcjt7juprlfrwyv39z65wqjh5c6n9y2yns0q5elcwyjrzvj3kky55ymps8ghzct3zyvmae7ccf030au7ve2yuan2e4thfkjj4lq3xn3a8km0rr7t2k8rn3d6kea24p3ck76mvc5tet7ekt8ls2t29fahly0znsh9duysd2szft0kmawpwvtfuuj49hytzfxx3llc5nrn9hymql53mpcrsneyccfjf35wvg8jf3u0rtrla8m05wkeedwzu7vusrlt6d5tkke80nwfz9kgdr0a7eedlfjwlq3ruf3dtpdrgtptyf7arkykx8dy7n2lajxvu8znt70hza2ym5w4h9taw07tcf49z9k5mp77rp7y0d8j0weht23gan2gas70kuj03lgjdun0e74ewmc4z3mgan44razngtl98zm9c0935z6kgyk3f9xwdh5fhje7a7494t8yzz7xas0yjkrw0l28u5zjk9larj79x5eu4fjywj6le0fkkfanlalrcgd2avqzmvm2uxyve3hcnqcqpewelkg20sgwa6vy7hvg6swff60zv9rv84hxzwq4jm8hlw725hu79mmm5x65efykh6fs9ueq7qlxlyru4cqv9w66h3rdzumueg77h96y5lm0gjd2teaqwwc64d446v7uarnnfzt7eaf5vx80my2lwmlfzu9mutgv35tjumqw79yznwq80n7nrru7d0ynhvrdtau0rj4lxlku75pn9q0n5dt9hm0w0hfh64m77a5xlv8zsm54z3h3td2l6mxhd6zamzd8970dsuddwnvamskrlvrahexxtn99kls3jyzt97mj29luz7vpgzuwf2tjay");
  print(nftForNftOffer.driverDict);
  print(nftForNftOffer.requestedPayments);
  print(nftForNftOffer.getRequestedAmounts());
  print(nftForNftOffer.getOfferedAmounts());
  print("-----------------");
  final nftForCatOffer = Offer.fromBench32(
      "offer1qqr83wcuu2rykcmqvpsxygqqtrw8ywqh8gatlc0daevwkmt3ann55amxu8lzdnlfmlfr7v6v9c8njr6nqah60rkkl63mtlmga5l447u06ml28d0ll7q64lwpshas9umanufaadfkrfhekxcex5slwjpvu0aqpuaedvp7xasxwmk6ayw442pz4kl37ex9dn08ughqhd4lhdhyhmle5040p3hutwcaden9fdmfl4waw7gp2kj43jmz3z8glce5yeqkwp9vv67eveyml6j6jfavtcpfwl579z60wlhu4h03umkurhllhp9xmqgfd7q3zlmv6zj7qr5xdk4e76kvtls9wx95vtzeyevtkm53gk6y8r04659hl9lmx3qkqvg75spkken27hwzj8r4dsltwm4w3sa6kdm7y4uk9ahf7f4uk2uw3awelfyhxrp543m3mx8vh5hwnm960g0cryqcxme6ldchd7chn926e4v70287nkks8k5gs9rny0yygltshr9wzuqv0l8g0gqe3cystyhsqjwmp049wxg9a7lhhuwphhfecmymacjtnme7wgl2z07zy3tde6nk729j6d0nluhssej6mrkt2ht278fcjrmt3new8mfxukywn0rtu6upu5t0cgkhad6c0rqlkra9f20qzzg862lw2xad8x6tenk246uw548hhgj309le95uhh5rky44qmutlwj2s9mgjcr5z4p0phd9qr88qzuk0p8gltmnplvkyemqkphm0mur2d0rk2my4tjujfht06v8s3ajeulqgjch54lclfryjs2ff9zmd9460ffx2knz2e4xy5tfdee955j7dxrxu5n2w45crrjet4txzsv6dxuh5kvwtfvkye2ejeaxrgjf3e98zkjfd93x5uv34ey52a4xt93yzh4ktfv4jjtkf9a9ycn74e0yuej7kxueg5nedepxdv27gf0lhlsq05jzrykusp5z85drrs9aehl0azkrmkyh0fyzlsmx7e0n4n5mel2gv3r0h8yhfdue0zalenv8vlll6vh9qpafknmkr4n30e08lql72n6z9jzy5q0ekuhgrfpnjx2f48uu2206s55kjgztpteupuczckj6qv3hvdqkn5m9u8cenmn0hf7xeefzlf0y0uk4p0y0xve7hrm9lj7gumknehdlcp8yhkxswr49u5anlj4yr33n427h9k4vpm4f5druvla0pja0vwlhlydvmll7as5jujl6amelw4zc7ehet20m7deh9p40d2dnhvm2mhdug9nteaw2ukve0thhuv5h73uht2swfu635km2xjldpqux0llg62dkyccfhm9k6gr9tagatta26uh79yqw6ylnlcxylxn487gkmadjg2l7dclpg4rvxa5eaw56csvjc8xrdvlc7tker9wnyvhgz7k0eflnhac5z94m47046jt68fsvzhpea8acgsh59uu6dhne48dk8nqnmu7mt522sj96ytyf7x97cwqdtdtp4dsmerqsdmmgt8uka6mmkdcsjk78jdfqed7gv57pk8hvlva0p7v36llu2gscymxx3xpf54nym5xrh6nupzlecep4knwd3pgu09r20llctzm4m6ehjmvt3pen3vnlq8hjnh7lpd040f7t4624c67mlhrkz3nyjr20lza20c68gmc65t583w04lrqx7zqh8hcc0fjwhjd0v2lkphf7m84gwudszhvxrgjqxwcctq7gxvfqgvfchzzdplptyq3sxwu7pl87l0hkxlqkt5e7tl42kremfalkj244xkvhn6k7cw9cuaulm0u2z70c8r9x4qywg9nal7zlvx6rqjes7xet639jmyr2rxa7k346xv3wrhupt2twlmxn3d2nxt4asmja0j0nmqk3utr783gmtxthejja0923j04ylhma0axh94gdm4r9jsxyal90w7vh2m76m6932cut4g0xy67e3ve000763rde3vnwc9lnd58m8vxmzfs8h780syrk4a8r7l358fp8tyajj0z0xzljq0hwh8n50td8ml8tkkqqsqg8aw9yq0jm465");
  print(nftForCatOffer.driverDict);
  print(nftForCatOffer.requestedPayments);
  print(nftForCatOffer.getRequestedAmounts());
  print(nftForCatOffer.getOfferedAmounts());
  print("test");
}

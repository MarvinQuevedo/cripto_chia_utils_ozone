// ignore_for_file: unused_local_variable

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/test.dart';

const testOfferData =
    'offer1qqp83w76wzru6cmqvpsxygqqwc7hynr6hum6e0mnf72sn7uvvkpt68eyumkhelprk0adeg42nlelk2mpafrgx923m0l4lgr3d29khell6nhvqag9yx0jmn0nldlzvhp22psmlv2zv89tmjka2625qfdhcn7m0lkm64atv38hydmhz6dtd20v3n42thmhxhu8e4tvnjutwf7l806fhqpkc3766nackt44794qwnpehevldz4r59deja75sf4l95v0am7tu5qm4vjfl70xe9xe6pe7r947e0kfwerphd3d8sntumx4vku49c7kgk45gkkrj6p68376csq3vsar95gaf6qldkycedjygedj9gedz9uyjj9hjcyt3kzm2p6w7szjh08etjatwex95vpp4437zwj8d4rvuxt6utf3w94vhhghmecw23vad9ywvv0k53qyww2ndhwhf80vrj03u6ntzaa5dksw8w6se6zey82l5xzjsu3p87w8h4rqsvmjc5dcxn67dgjwmdkh82n8dfzll4t3hqnjn5c7wns5kflt4lx5zwmzjew0eylw4c6l87kpf83qlnxwhvwm8qykresyxxeqakf07zcgx4cludafp07z0tqvvsndqdrm77840g6wnzkdsulncp8cxe0629l6df57el3qcwa3a08ltpyemldn9leht0e35qy4mt79lsxj82fcnulq7vzac9mu6snrw076wqj7mnxuytkjgndaduqcm3eevsdgr2hvluhms5550lh0lesdzxt77euemmuantj7efj8w3jfggs7zlnmc6ndam3c94yz9l4lgrckng04ehytl95tc3lxnt26k4dgumlm3886hf337utvljuflqhjq9h30lqsfph2sgathtxzaw3tte00zjhs502mka0m47clu79plhsv06g5y5hpl7dnnemudrut7grl7a02u4ql57l74aj34l8gf9t8wa2j75wchmvej0wcx7l0puhrxfstkmgp59rvnlc9sjdztsrsxpcksgx24ry28djty7lmr7rhu0t95vmht095hdlx840hpfu5v8ckda3hfwf9w3p0sydq2z58a4f74chlzmrlltnem88406djc04aartfjhdh6060l5enls6fc0cgfh42lgl4x8v7rm6xv0wr0mfrq70z2lm9ju6l94a2hawtvm05aa42mm8sacthkmxpx9tlmr6t3u8a8a3l88k73sylw65ufayh7742hcnlh3n3s5usq8dpdmwq27ppny';
const testOfferData2 =
    'offer1qqp83w76wzru6cmqvpsxygqqwc7hynr6hum6e0mnf72sn7uvvkpt68eyumkhelprk0adeg42nlelk2mpafrgx923m0l4lgr3d29khell6nhvqag9yx0jmn0nldlzvhp22psmlv2zv89tmjka2625qfgnrz4qh6hvkg92lz7kj6l480p273kd6lhfaelec2m70qels3g2fxzl7mcjacqdhswqczc50utf586umj9lj69uglnf44dt2k5wdlacnnat5cclw9k0ewylsteqzecerumxgtp72kqdg0845h0lx09j86ehy3wtfvhfd4hy3z5vh82h9fc2r3zecue7cp3xndp4s2dqg3jmyw36myw36myxs6cytcfd9tf4qgh0v9s5m5aep48ww0jl92sajvtycj8ttzuvu5vmj9ecd8hc7jzs26m0wn0mjq64jc66tc7csudprs2u54xlwavjwac8909ed8kp6mgmaruza9rn59jvw4mgyx99ejq0ua0rtk8qphfsu73a0nt7rgn7ymj6njnm4v2a6fe626lnqhe7f5ulm0j2fxvtheh45axh6n8lrezpm8ulwtqwrcaw4vjap5srds5d3h8lxml3wu8vuql060h2ngkdx9k0dlxrz9k3jvlf7uruur07jfrnerjym4vky0kyppwxlut5g844t5a0nrw9hudm0456h8d45h46xhhlnq3m55xgkdanhave90pz0tyl7entzvr53qh6hlqwmld23cszhlacr9vhwdndpvavz2ula7678chdhz7t8pjf7c83epx6lchjp49klt0set9jr0lzlzz0wec6ce2ad97nkhans457x3d95sz378gh9h6k2e6ha3028v8w6sr2qevyrgy079csdg3yqt0mhuq9s7d8xtutpx9v2h3rh43r9u3jhdukxlhd5z49mq230nwwacm02u3qycvqefc8xjqvnllq26ny0kk5lw9jad03dgr5cwd7t8mg4gaptwvh04yzd0edrrlwljl9qxatyj0lnekffkwsw0sed0ktajtkgcdmvtfuy6lxe4t9h9fw84j94dz94suks0djls9sr4kmlr9ktardktaraktaraktdraktw95t7tzshy60fe4rfldkcua2va45tl75wxujw2xjra67zje8awhu6sp6v2t9mlyja7hnfulmcpy7yrkde7a3evkqmdlkz6vue8z8nu8cq0hq50mtjwd3um9cjfmxwm5sw6f20h4ks8rwy8fj34qgtal7z7y2ewdnnxv9y7wh9dukjmcer7nk92uwda8t86807a9538lw4tr8mrs5609zpkfvd9fpdq9gysucd5tde34sz6cwzph2yypkpmfplj7lhktjh4w8azhm5lw44vekreweth2y59dkdemkvrlh3shtel9e3srkjx9pqlrlupyyngwfpdcu29r3p43dls8shpcyaazkfd0c8elfmgdsglq4agljdpp66mwfmcvehf93d5nxm7z55lwulea75rd9va2nnwu5zft0chkjeudd970577j5w3r0ccx8zapv8rexv9eu5e0x9vlnq42smu0e384qkk8cpl4lxh0254lhw5vd8e6lh8z0xaqkqphpe3avwjn2vd';
const testNFTOfferData3 =
    'offer1qqph3wlykhv8jcmqvpsxygqqwc7hynr6hum6e0mnf72sn7uvvkpt68eyumkhelprk0adeg42nlelk2mpafsyjlm5pqpj3dkq0l0mj6uhreyk28qfnsvxk2cht53vavx6g0hfnfa0j0shzy7k4fwup2n0g9ntvuju7tpapp2zzuws67a8fctvhkdu59n5agh49h87ydlwqemm9m87kac547q494szqs3feqs6czf8ahn8je6fl6u6m37v097ah8lc7pr6c4hhvhj04ank8q6gd9p8m4d94jaak47kjk77k7uwlrrkklt8ck0jdnmvzjxt0ht3xdeduky946c034ryv7q3xcaq3q6uvjxsas5vpmpqe02prpyd5hjshl9zs78lmk9slm5auejdkap8e97l0y0np873zf43uftt0y6ldj5enlmls9fu4jvjzk8ejhddeeasdfny88ylhtta922ehht9ys28dvty6w7q7pchhnl4p2hyrxg8qg8dtwldrxjre046emy24d88tt6mwfcenhujkvrk646z44pzu0zxsalx3ycqg6rhaph06q8n3sf0trsrk0aueslkfzvas0qmaha7p4x8nmdvj24evfvm4nakrcqlev70jypvt720u0lqj9g4y5jsdjj67hu5tzhf08jejfge54z6n3dff8yl27ff54azj7wfl2l0ndv9f95ezavf5k5kn2f2l8uh2cffl95ejdd2e8umnzv6086ljk0e02jhjztsadpmvwqm32jgpst5x4wnma0vaj2m4wnkcz7m45a9twr9r8eldu3dekrxrn6msxxhjuplphfyx6e2ecpntmutfdstt6yz0awaulh23v0vmu448alxumjs6hk4xemkd4dmk7yze4u7h9wtxvh4mm7x2f9gernj5yjgd5234mg4ztszamun7wk2g4kre5t8js949asath765uha9grwjy84lv95a8rh822klud4gkaw9elxgdqu2a5ma656ksv5c89rrdz76m5x350gdrgkq8edstrptlt6zv9nudw7j9wmrm7v07rd04u927kv404ndrklmdl0vvznjzc4xsnp3m4s0cxvk55vzqnk8j6ccdm02fkcuqxuksj7py0kmrvlk0qytczfktahvjv8suw07ekgms9nh9t476dvek6nwmmdj5v6y9latfsgq7krtyu6d74qk2cnrdg2nlllzuktj588w5625h96ltppwm7xz5n4tfe0k9y9lgaguj0lhlp3dlaathh8lutjsp2eaphn9r808dnlmklyvg6thx74u0z0pua026lm4g8n57fc2t7nrlkr95zqptvvrsxxrxyqz879tfqxsgq3jgfcqlgjsg4yrfsnv0w8l7llpdwdlnmlu8qj48mnthezw0ltfn3u84vmlcltwzju0l36vaprevymkanmtzrwm0dmm0ne5kvcw8tearx8euw90jjte57vj0n8exe4hc48gf0svj9266u2k097n8w806yxums682gnzh0nmy5cd3vkm0tjh0wl69w4j7l4eyh0frcwayweyl9a9ah3wtqaf809mjramzch8m3djecsa6edknh6lvsah4cq09a88xss5j642';
const testNFTOfferData4 =
    'offer1qqph3wlykhv8jcmqvpsxygqqwc7hynr6hum6e0mnf72sn7uvvkpt68eyumkhelprk0adeg42nlelk2mpafsyjlm5pqpj3dkq0l0mj6uhreyk28qfnsvxk2cht53vavx6g0hfnfa0j0shzy7k4fwup2n0gx5f87h424ekallhz9nf77fx8a4h9gaam5mla6cvhlvcgnly97essalumlrd9gmwr8qyppzjjpp4sy6wmtxl8n5jl3e4hrue70atv0l3ux843t0we0y0tm0dwp5qc220h26mf9nmd0aa9d4udaca7x0dd6klnvhym8kg8yvklwhzwmj6eggmt4slr2xceupzd36pqp4eeqdpmpqerkzpj75rxzgtf0dq0624ru87hvt3lhpmehymd62wjta7ugl8z0azxnrzckkkufalmpfr8lllq2nefye99v0r8w66nhmscnxfw2f0wklm2s4r0w7tfq5wcckf5eu37r3w0rl6z4xfxvswzsx6ka72xdv8jmt4nkg427w75h4hun3r90e9vu8a4t5yt2z4c7yvpm7aqfsp3s806rxl5y0hpqjlkrq8wlncn9lusy3mq7phm0marwv09kjey4tj6jekt8mu8spljeulyg2chc506l7qyw36ff9qmp99l0egk9wz70dnyj3nf2d58z6jswfl4ujrtt6y9uun747lx7c6stpn97crfdfvx5j470e045jrutfny764s0ehxye570al9glj74d0yqh366rhccp8z4v3rqhgd24xh77eeyah2e8aj94ktd665uxtxtnwme2mngxu884hqgdl8cr7r2jg04j5nsrk4hshjlqx45g9l7atelw5zu7e4ett0l7deh9q4td60nhvm2m8dugyn0eav2uhva0t4h5d5k2ps809gfysegartj36xhqymneh7ay530v83gk09qt6fmpmhta9te0625xdyg027utecw80ws4dlcnt3d6vtn7ds7pg4mfkm4f40qegsw2kx69a4ngargk36x3vz0j6qjxjh7h4yct8c64uywak9huelux2ltct4avf2lt868d0km7lcu98y932dpxrphrpl5vfdfgcy98vd943smk75ndscydedpduzgld5x3lv7qchsynvnm7myswpuulanvshythv2htas6enda8ankt8ge5g0l25ng3pevxkf34ma2pw43xx6s99lll9av89gwwad59fwt57kzjlh5v9d825njlv2gmu3j3eyll07trmmm2h0w0luh4qz4j6r0kgxxlwl804d7fc458vdatc7y7re6l44l82s08funskhax8lvxtgypzjcg8qvdxvgqx052kkqdqspzysnsp7eyq32cynp8c6u0lahlzaxvu7j5yaenmatrl00z0dakevmwunegxllrmt0nsfrwuhdwhvqehxzrvyvhdy2y0l3af6v8wl66lm7njherlmnn9ps9dyvll4zlarhg5rrzxpslnwxhxh438kl6xempwq4kakawjvta7umsrtrl67n39jlw8uyylrz9xr9kshpta7c932a80e8mmeywel85d5pl0avs6vwzrnhz0wnfwkdkjhx85rgqxnkh9cqvdfng0';

const dexieOffer =
    "offer1qqr83wcuu2ryhmwm0yu9flwlqlcyry5stk3y9dsj5gkdzck23rjtd3aqexd8mjfwmvc8v2dzzrf9sgkfhejjwkapfzfeql2ydq5yd9898npugullaelud4w4wd0u7l0l3clml4l8lf7vu7w0n3e4a0khrsyqgssry8caw5fm3za69y360zrxdqdmhnk49xvt43jx94mcft5fhfyf5y2eadcnnd6kpcxmpqwqp5pxv2xr8emflx8ufxkl0prha3av9yl4kw82j907e0424lmjxyw6p22cfykcvhkd4r3pvmjfcy5v2xe7ywxm67c8m6sv60x375w2xya3q42jn7q6q5uxc7jzp3yc6rl2tdnev27f66kezgere265hdmz292v8xngk8uzhdccg5asmlxtyg55lqcz48qla6385rsm9u5ujlv4fnfhxmjk7f5s6pymua479zc76njstqnk3fam2m3k9nqxzsucq7vlzgf9wypqxfm65hxd8us2shtnuu0dx3vr37072z4reg0yegsaf4zdm4aeeysv5tjyzttu9q5uh7va6scge089em4chza3dvq5puywppq3nawd3ctnlunsfu3auqcpfv8dckrd86wt9e5gfq7v2j0apc9vsuckq0hh0pyjt5ukxxz5ww3qglks23pv5f9y4xyrw6a2tekc23uln2h887fmzqzsgse7vy0rzmrkcnx7fdxfeme3t2vktzjvta4fv6utey62rcgm66xx0z8t0vpyg9xf65rz45ayqu7tm2l43av93euxwc9j4p6d4md5pstflay7h3trlatvgm4t7axyterkf5eg6q9xqs5swn94nps0404uuhujphlt3rlpagk6d3wayanqjfvtwffg57fflnscthe8jadvnmg2fw0033fa53ukuvf50andz0xl8nkz78w084jejlexmvh3k0leq047lsp6ppaexm6xkkll2x477yyxvc30xhqjy6r26kzewalxt4n6hzc2ks2z7umgkyr87njwulnr7ay03j47p5ngklsh7l3sj7tcfgnq44cs8xvlqa9mey6a7nfcagljf6u7q354l8pa7rwj6sfwa9hg9gh8hz09y6w6uxu950kv3g6w3epa44qzwdwzagek49xzmcf6uhj5qypnnj5eg7xakpn0gku4ud8e24z76jwwnu6ezee6yex0g62658te0hxwe9f63g9jdn5sankt2vxz6nl298ztfr4pmgu7mwa3s29a3y94t6jaekygd9qwuf667zxahneyrauracra6ra6ra607half7s0hle77ahaehx36g6lx33ng8lzwjslar550kf4yty09499rljxshpd6uy2lap7yrj0nv7vae0p74s890j0sqw3ta7g3n64n9w9830c3fsc8g2wsngpw3vh3asn78c40alvplvm07ltn5fc878kh3tze5rnyygk07nqv0nsal7cnjmnryjsd5v26kz4xpwek4u7rsl3rkflkcevzhhn5r9f0hhalcdch86mlhkq3a586qzdat0cdrfdtnfxt6eap8w4e4zwnzjtx3wrh7vzss40p8snq66lnxtzw2mpwst7uzkxxcmfprcq9phrzsh9dyqfmczecwf5lh630ut6u60jl9q60e6mmj8ykuavx0ctyvuk92hrj3jhp92hyqz6mqjdqlulnqtaj8am350h66tuhz3ats6x5xuc3fsml72hdwqfw843tutmp7sg6n5w6nrl7g0aq0c6tueed0k9egxks0a78ky5dp7xew6a3cr68dpvc9jwx7l4q0f737yvhv42vkategjaffmex33w9lw043wm959udqf3kq4qzjshuqr6hr9jze7k90jkf9cm3nwjen8w25mdnv7c2ajhzzr6zyhe7nurfkzrkr56znrsqdpfjqgkwmd860mgu73aq30cscazwzw6cty52txxx54mh9p0fg6v7vkxgj9e4lvw6g82sauu7cnfau366y0v526sdtuhgakn7ffhuy33epa92l30kx9uz0vzye5ffzj0sppzz9zz9zzyzzyjqy3h6eqzgm59pwqy3hq27k0c8398633acrgn2rmvcxktu6fuc3aykdtyecvaq7scn8hv9g7ar370gag2ek27uejhd67fcnar4aqw90flcgsjp9cds8sjp86ghwsrw086207th7t5typ329fd55aj6mtj4el79mj688ctdf0psvlq386r8x7h2hzwlg0qu9uzryck92utc8q9xr85c2wm0k64fyhzks4ahrwm530syjupssqkgp0r7hrn0pxlc9ur8fajuc8kna2jhk6dmy7vkmjm0kspw38srpn0hgn75u3qa5w90qvvfrxf63z7l20xxa3x4e828u4zsfau0450neqrl65wp9saaklwc744z8fmjv5df48ed7vqfgmgds8x5d73k58zq646pxe5sggtgzfky9n36emr5tvc3wa7qv3pem8kze80xjgxftkhcv8ms7agg3ql8u980w3jwteq3xwavsmswg2khv6t4yvnsk85amy70vmu2l2nj9lfueahx86w2m0zerph58exqqfjt6dmhngltc2f20rgss28ycncdptx780wt2ejq58lrthxw9jzj30edhmltsvjpl2ql2qlgqlfqlfqlfxlnlhp7g8alculfzeawrdhjduja95vyaayjt2cpvu7xn269d68krxk36cs93y944dx9ef9ng05eql28kugex5vhnh9qfjt734lqre2a37mmus2c80tn5cq7jddkwptfe8k8lmak9fkta2wtk7gz2kdhrk5587ec5gfq3qt57ugfjjr3x4yt9mrtj78l35c3qzhelqv3j6a528t5qd50fex6q2c5d7zsvu338wzt2qpn93pn2y70hptt2kgqsr48nfq8zn22lv099dmrqskul3agnfxgextx0rtjmkm7jq7uplx232cqpyelkkzzyjm8ukvmr6g3ngdvswx5wm8fgcp9svfp7hnay2j9nu2x5k0gdaelrzdtwnq9j6yunxjs4m7k2h5ywpnmmjl0prp53zqdgzfn8kw0v8dksevhm2qunar54kltqa3nglv8cm76a8gfwu6t5tr8v9j5407twfhdz3ltwk7wyrw2csc097w8xx58tmf222js0ygfrnv8c7vcvqdasw5vrremwg07ks5tpu0hrm5ph59aehf794yg67p5lwurpfhy45p3atnrc0xe0lgvrff2tk3sp49pp9pr9pz9pz4pzsmdwspfd7zq4qzjm59lt8ezckku0nwv0np58jl44qja4pfgcag449xxdnawdctm8zyvpfvtw86va86a6ue9l4nk4dd9kkhft2x9mg0mgs5y9g6rkuh5tm4fe3agnd42yva85f83t0kpjl68nt0h887e44487ufk2a0ledlkgqskrfs2n5552u4w57cxxnknjfc0z39pzukh334zp0mdkyzxmuslz33x3uajcpx4zzjksk98yfu00e8zvd05ggkufr3g4j2l2wddtaptg7mf0kvjf0fxr9lwk6jujm45y8a6x3t62yy04jdaqxwlagenk4y7qgjltte03x2qu40uh58dn55vqjgy9z0css0n9dl9xwc4w77rk0ldgvhkm42ksk3g08rwdc5xj3lf2ruxnh3pp53zgvcqfn9k20u8dkna2aht6zdee8k6jf7c0qr6netxtsu0tl9uamufk7m2663l2y7dyllnun84063e2xnfmt6ccprcgw7wm2yhlnht6nn7jzmc8nhlmsy07ukpal0zyexykug37vflvxehe9xdaflam3c2u5ff5kvhrjranc3j9c02kpg0t5zdw98pp9pr9pz9pz4pz4qz3qjnlnm53vvsk5d8tthr83ehttx3tyqzg4nd970vhx7q92e0s5ervaxx2ur4ylj7nsupkqx6797jvy4mj5vkeqr07r3gke7rw2t8vtq8wgvc2202ytlv7umv548lc6s0yslz9wl8ddk8n78pcz9pvp0zxjlss62jxxkj3nc7f4tq2g4h09gcdavdazftseawq6ud84rm42ct9uw9pz57kex9lnlgju2n2ps2vhd7u57a8pajaw448sl29dal9eykvnt07775c2pjdw6a899en76482l9pn5c3daqeyyceysmnlgu3sz3mlsa6plncdkh7nc3ce62p6amka2uuqnu5wkuq0q240zslv9gqvlxzzcgz98qrj94fhllg4jsfzyq6synxtvdd8ezaptmzqh9gc4aj7tjrehk2nng5mm7qp2vv6v6hdpc7f73f08an3rk0ay77u29n5suxzw35wmfxs0nmwk93h4qmu8fd9gud73hjeu4qe9ef09vwn5k8xkqe2dht77uafemy8cwcuxegrdgetynlvy5xzfqk0dv79t8vc5cs03afn5sdfqffggfggegg3gckxn25y2t0ss9gq5kap0me6gx9958pl9hpf8e5f7jyyg49q87jwtj3kt4h9dxkg7eflwy8rpwyrn3mppq8gz9e0wuwatgmnr3gt696nltx9ptkuh52s2znqu37d5fcu8cw87jp52rxwq40eae3hd89q29ymc2elqf6jc6q3gcm75g2zwh3n4vl675fgx6nrmhtqpkmd0z4vt0lmz80xc906ygtfhsn6cs5z3rzszr6lpwmqsz3m6ykvulpteyh9j5243qd5cjsjkarmu0kmszef8asnpfc2v9vaw6wgnwaue4ah008epuj3w0v3tugh0pzwst2azux0gevquzjq8aaz32jtnl26r3zun6g2rkzwgwsdpaagmukxj742ka8hpafv9w7gcu9z98wsf2pw0hljcwqetq28vve8wk23x6pedw67pg77at26rats54j087dafqtcfcdygzrzqjv3dnnmpmd55t0gs8nw2ypzhzcg499dn76q3wkhnrtfm74z0s44f5wktccxl9n0adj6euq6e549k0a8dry636p4xas0u7rpnt0vs85sj4856rvwg4cc5gtrv377r43hr9smc635rgtj0yfrhwtln0sa9ufcpzfwx43kgmf6n4wtm9sph23qz3qjsqjsssss3ss3q33tlpu2xxrummkyjlwret48xcn6hmn2tap9wr25pqn223lttj8zxplpas7dvax83sf5levg7yvrjcwa9whxf7dluxxe2tew0yp5cfj25datrc6t0ve5d8k88ndz52awwvatvldnmg5arhayp8awhzjcvhnqatlv3p3ffrscamyk7yydh80hlekg9l4t74hyf4hdnqmueh7nm2ncatxrmk48kvd3sx2jq8scj2pd7xe4lfs2eslt2x5haw5t63l4ldr57sql6xfc460255temag8u6cddup2dt7ca5lywlm3thn9e2xya6xgh9mfxvytzjeqpdpfveknugwzhgflksyyqeql268p7j7ytlvcxw5gt9zkx0turs8vpuwyv8y09a8zrlxlkl2ryflzdj7zxn2gm7j8wkhrv2h9myg2s890mgwuw0x9m8sraut0jc9f6x24fxcph8we5ma8swt8tz3pl309mxw7xmvlmmkz3kp64cnemmavf7sf3gq8fqlfqlfqlfqleqlsmdvs0mdkzqhltl5l0qdr3gdlx6cp72tsp79fwhchjaxm6d05t4msk7slay53pqlqdj8wr78c4lawlgjm4xqy8ceksmlnn5l93hj40d6y0erw0z9l800m5lr4fn5eeegcc27dem224ml8naq3ydav6e00l8p20s9lfs75dhlsk5xc57ldp4fad2fmaj8nw27p3ptecr2rhr9ymgn8kf6kr30uwyum5vqq5hvsprzv75crvx6n98t37tw553cltvcjlans2ket4klrwrwdgds00amxu2g3p9c2auwew9w8mhvxh2q303slfecnktl8gyqwnefelth5fqys6k7ynf5jta94tteuv6z633ml39a4uhauylxnfn0y09rjxpp3ayvfa7yzttgg6qr7c4a4dvvpnqfg7jgpxnwapdv5avqsdv4p4u799359ynttl6vudkzgy3z7kygeg7xvgmpvtqlttvrqghm4cyhx2wzrxtrwptknjnzc3gc9cw72vdqjqns6g0xxyqngjygp4pqsz0md753p62pq38ss45ad0l7uudqpr5yt5yt5yf5yf5qfn04jqyahg2zuqfmwq4adlexykwqp57avjal6u7xsgpfyfhefr86h7rpl67u6ldsef582rt78rpdf36tt06l5fdxregpfslf97adft94gujyx2vs26wv4gpwp05t8dgj8f46ky5u6l6t5fn87rdzgelmt06wjr6ps6ps6qs7qsuqcak6csvwnv9dwqqaxc2652psl73uwnvclctfvdff6828dsjja30ggxw4mgh0aq6ewwlx2yutmc2m86qa0jwuuueu9h89xvqmuawkzpcqk8nl29ydvcfm2tu607uzspq9pjtuu47uzd7pytfedecg2qg6cnu7mez7xvxxflrfzrguzsfhy8m8yvsvjdryrvs2d0av4f6u45uvmfrvn9fur9vxhydtzds2x03t0x4x3uxhul5y6tw2y363jrzjuap69275l6dymjwsm47hnh";

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

  test('parseDexieOffer', () async {
    final analized = await TradeManagerService().analizeOffer(
        fee: 0,
        targetPuzzleHash: Puzzlehash.zeros(),
        changePuzzlehash: Puzzlehash.zeros(),
        offer: Offer.fromBench32(dexieOffer));
    expect(analized!, isNotNull);
  });

  void testParseOfferFile() {
    final offer = Offer.fromBench32(testOfferData);

    print("offer ID = ${offer.id}   ");
    offer.toSpendBundle().coinSpends.forEach((element) {
      print(element.toHex());
    });

    print("----------");

    print(offer.bundle.coinSpends.first.solution.toSource());

    final nftOffer3 = Offer.fromBench32(testNFTOfferData3);
    print(nftOffer3.id);
    final nftOffer4 = Offer.fromBench32(testNFTOfferData4);
    print(nftOffer4.id);
  }

  test('Parse Offer', () async {
    testParseOfferFile();
  });
}

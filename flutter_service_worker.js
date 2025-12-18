'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"index.html": "f5b36ea7c4d7cf84405116411f80a5c6",
"/": "f5b36ea7c4d7cf84405116411f80a5c6",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"assets/fonts/MaterialIcons-Regular.otf": "afaad9495e1b9450c74236738315b958",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/AssetManifest.bin.json": "69a99f98c8b1fb8111c5fb961769fcd8",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/AssetManifest.json": "2efbb41d7877d10aac9d091f58ccd7b9",
"assets/AssetManifest.bin": "693635b5258fe5f1cda720cf224f158c",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/NOTICES": "a8ec6b05a82dccbc255492665cc73271",
"manifest.json": "dc1be4513cd6a65d7eb84e0bed515b94",
"flutter.js": "888483df48293866f9f41d3d9274a779",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"canvaskit/canvaskit.wasm": "07b9f5853202304d3b0749d9306573cc",
"canvaskit/canvaskit.js.symbols": "58832fbed59e00d2190aa295c4d70360",
"canvaskit/skwasm.wasm": "264db41426307cfc7fa44b95a7772109",
"canvaskit/canvaskit.js": "140ccb7d34d0a55065fbd422b843add6",
"canvaskit/skwasm_heavy.wasm": "8034ad26ba2485dab2fd49bdd786837b",
"canvaskit/skwasm_heavy.js.symbols": "3c01ec03b5de6d62c34e17014d1decd3",
"canvaskit/skwasm.js": "1ef3ea3a0fec4569e5d531da25f34095",
"canvaskit/skwasm_heavy.js": "413f5b2b2d9345f37de148e2544f584f",
"canvaskit/chromium/canvaskit.wasm": "24c77e750a7fa6d474198905249ff506",
"canvaskit/chromium/canvaskit.js.symbols": "193deaca1a1424049326d4a91ad1d88d",
"canvaskit/chromium/canvaskit.js": "5e27aae346eee469027c80af0751d53d",
"canvaskit/skwasm.js.symbols": "0088242d10d7e7d6d2649d1fe1bda7c1",
"flutter_bootstrap.js": "d9578356dbd61426e631eec0f2e502e3",
"version.json": "797939af3b0c8c2e29b601e6a2d38939",
".git/info/exclude": "036208b4a1ab4a235d75c181e685e5a3",
".git/description": "a0a7c3fff21f2aea3cfa1d0316dd816c",
".git/logs/HEAD": "aaf0dc11ba736976753b6831e5d2495b",
".git/logs/refs/heads/master": "aaf0dc11ba736976753b6831e5d2495b",
".git/logs/refs/remotes/origin/gh-pages": "682aa2d462a7b25bdd9a17a4a242909b",
".git/config": "554fbe72bd1dc1f31000fb2c3ae459cb",
".git/objects/ef/e440363b8c9797f39dcee717c31478030909e7": "925dd6b4bb130eb93d5c6c8dee934121",
".git/objects/47/6365d04cd3146906f5611b8b1f7101d84db3ed": "3377ef49cd7388e02bb17816b6799521",
".git/objects/b9/2a0d854da9a8f73216c4a0ef07a0f0a44e4373": "f62d1eb7f51165e2a6d2ef1921f976f3",
".git/objects/b9/3307b6c08bfc3bfd3d8fa24c66e829422af4ad": "83fa07e5a568e8f904f2e897d23493ba",
".git/objects/60/10a64c880f9531747770e60105e80330cf4902": "16bc2ba0a7da84abb3a3705d85b6f24a",
".git/objects/60/eb78658a9e004c2bc37941ce64938b32b58865": "93aa32c00e93b1293c824a24376c62a0",
".git/objects/60/1150aaaa1fbd375e4e6023e6d86190f13833d9": "7ae89e7d6654310d34cdda4d2debd9c3",
".git/objects/80/730733e0b7783e9b36ecb78b1e961e9b1816a3": "ee858920291f21510150bfcf202cdf41",
".git/objects/0c/46a63ff613ac4e6c4c20191c5d9489f0b8ebe0": "db847ad23c022dd39705d10b30f07338",
".git/objects/0c/aa7b61a7f6e6822ab9303bf3b0c7a43ce2fec5": "0ae52365c99286bfc07e6c3a0efd4df9",
".git/objects/78/7b3a9f457540237fe92424f71c6335a0370b17": "d6a00d5e0f977974a829d11f8cd64943",
".git/objects/8d/20ef72c82a30e1d1feb536005a54c70ae5ddcf": "787db59b224a832edf9e9ab0596e5aa1",
".git/objects/77/865822d4cf1412c3730ec6fcdcf177ced51e03": "6d41825259f0e9259005b5d3ecc020d5",
".git/objects/85/06709871aef1b2137246697178b9b310aa850c": "96db94f22a753fcc9179659c72bccf14",
".git/objects/9e/5c02ee290ed7016aaf8cb7f23a579e12e6dee1": "db183a60f37b4d23a8ada83e7f2a9b8f",
".git/objects/9e/3b4630b3b8461ff43c272714e00bb47942263e": "accf36d08c0545fa02199021e5902d52",
".git/objects/bc/dea820296ae0ae4e81cdf547e091b2ec50e086": "c9ec540193f9cab5577bcf0bf3001e9f",
".git/objects/bc/4eb38368e811249011f3e98542332826433d21": "627ff310482e60700eed7d1988f4a52f",
".git/objects/bc/4d9b9fec7ed8bc74362c373d55a092e0f39563": "b360a4f34bb954018cee6666072610c8",
".git/objects/bc/93db0f0f2c4a41009b84e4c5350153e23307ef": "6bd87f5d68775cab943124ffa572e9e7",
".git/objects/31/82cf92d21e2dbac68410aaf9d054bdcda4a1e9": "27e0446068c60ac699b6ff6e445917df",
".git/objects/31/360e55a17a04e76c4bb704a3f9407aa4fa8a1c": "fbb47254b5d7d36868e0ad0cde1f08c9",
".git/objects/31/0468c4995060c78ed8068d52f9ab35870ab248": "27be60b1d59c4a2c894e2d569dae2ce7",
".git/objects/31/7907a2436eb6f409ed383e7048a3bf75526bdb": "4d4beaac9aacbc4043afb87d7be9474a",
".git/objects/d7/f19d704708d20e92cee52f9d548d31720fb814": "1ced1cee3f5ce1ecec604cea58791f06",
".git/objects/d7/7cfefdbe249b8bf90ce8244ed8fc1732fe8f73": "9c0876641083076714600718b0dab097",
".git/objects/73/c2ef62de309dbd4712a02f55129e2a8012f371": "48e1db57ac8a77232859ab15c7fb96d7",
".git/objects/73/c7dd1f12770fab289925767a6c15ba28ce64a5": "43a218697c6182400676b9517f4fd47a",
".git/objects/54/5bc658337afc35adea032385b2358dc83e1a79": "009623c25850b2bc3fc4be458597028a",
".git/objects/4b/92edfef6ec56fb2ac3fc8ba0d315516005d935": "65116cba89708ec45e4055fb630801aa",
".git/objects/4b/b520d6b044e18417d54e42b3ab3a60e043dec9": "63a2f4f99fd4f8696caa5d13df368f87",
".git/objects/cb/e7a3f54383100a803899f2e594736fa4af4a5c": "2e18c667937c5c4a3d06ecab21098147",
".git/objects/cb/d43f5a054019fd28bad42f9cf1d95cd49e4c88": "80dc62e6ebba1ff4fa5e1a59cc30b071",
".git/objects/05/4a757a1770b97b7e566a2b6de107a3cfbfc5d2": "539c461b6d4c2a35b4f99f58a9ed74af",
".git/objects/d5/fbe08b1681fb76822a951c0562932ce27bee18": "421c13cf77d9becbf2a95d4035a65188",
".git/objects/d5/f1aa3edca7b31466dca11b1e57b9bb0e3f1e6f": "ec7c4b3a55d204e1c42d1954f7e1592a",
".git/objects/d5/c9c91b2a901591b2c17152e23ba42ae31ecc0c": "690d454067a4be8a5da74c44f0b236ea",
".git/objects/d5/fb5c08ea1450c9d9c1411b7dd919640c7479b3": "61d2283ad36a6b375712ac0a02deca19",
".git/objects/d5/a2f1ecaeff49f651d79e05b8e8807920c3c5bf": "dc95de045c32a98fc16a15b30d118ed8",
".git/objects/48/37466f7715cf36562191d80764dd06237cdfab": "c660f0d54806cb029b0f5667c78f7e04",
".git/objects/fe/1f69c48a9766b03724fbb6cc68ab218daf36a2": "26cb68fe089bb1074af1036543d7c27a",
".git/objects/fe/4ad73827a3a2f88f7378d6f7d4acac3cc11087": "9a516bb146ec636e570c88b1a318fd9c",
".git/objects/fe/3b987e61ed346808d9aa023ce3073530ad7426": "dc7db10bf25046b27091222383ede515",
".git/objects/ad/a9bdad875c8749565c01171ac32da00a61b731": "d19b6bc142141edda2315606b86da6b3",
".git/objects/ad/4650e21f7dbf40294bac7fcb129f11738a2403": "1736ae2583ed90085c8c886a0f084246",
".git/objects/28/159c8c833511f9438a41378730a5621cc922ec": "1a25e4fb89516cd4de5146008e05c62d",
".git/objects/95/54d2353aa65094059fb60a9be44ba75874083c": "a3f0d2e274d31dd70ebe2b2786202ffc",
".git/objects/95/6800d9a0848df193513a75c6bb5ce69d1290a0": "e2a3c3ed9e54fbec8aef082a55801f6b",
".git/objects/f8/e882d748ae0517a58a67d41a746495d611671b": "b41ded3989078572ae6d1c674c7e29ca",
".git/objects/f8/43895669d861939f92c2c4dd94f942f3e5d9ea": "f453d82c115c2ded43d790e2aaaace12",
".git/objects/6c/1f61a3031d6dfec2b750ad8b1652187a69025e": "bc43ed4a3ba83ce8774658f3444719ef",
".git/objects/6c/9c7b6a4595097d33efbad0bd0020a2b6c83fd2": "9c2da6e29c9d6342e0dfb05e382f3e73",
".git/objects/6c/0833cf1dc78387050a7c3667f1004f742f627e": "25791006adc5056403ac410b2b8b0aeb",
".git/objects/69/dd618354fa4dade8a26e0fd18f5e87dd079236": "8cc17911af57a5f6dc0b9ee255bb1a93",
".git/objects/b5/1c30b371d1975ac34426369168dd1bad12d3fc": "0f6c4247dcee55fcf324334faa83312a",
".git/objects/fa/1ce77bb061294c1d5d94cb6cd285e82b93355c": "65414ee38c32ca78aa7c93041de8691b",
".git/objects/fa/8da42286c39a3cad36f8c9f41655963a880df1": "32d6b670abe4cafc1b25440783ae117e",
".git/objects/fa/d53ed178b275f60b1b03b0d81d68e504764228": "5e9cf16b005f5206dea33448bf343d30",
".git/objects/dd/85bdec91c22bf5a3349ddc2b61625118b58c46": "f4e2aa25c76f018407c92944df67c0e2",
".git/objects/dd/3c7ae21bb04ecfd379df792d706151b7e8fb36": "a5088bcc4a658d5cc0d0a5d804e8f2f4",
".git/objects/64/f704c9284614a6f77290d755e4364e96e900df": "e2e2b58aa1be71c1ddc0c66ebb76697f",
".git/objects/13/a3d29ef78326dfc49dc4c74e196665436095f3": "5f92c6d9ab8f6155cd102f38d3d390bb",
".git/objects/13/beadb92fbf9d88c84b4892e6eb3f842b814457": "a50cee750145428b86dc2b603ca49a00",
".git/objects/13/c4bfc76e5ce95202e9a1698a7b6ad711a677fa": "70ce7fd37871bbbd84c9bbdf46f69089",
".git/objects/34/63df6e5a610cb812dc371c4da726602ed95204": "b0461f4827c2397bf3ef58363d58459b",
".git/objects/ec/4f3132b02a946e643e04468922ba454b694b44": "97c9048e558d8b4ce667e311c91b124a",
".git/objects/ec/ef24c7476bacb67886af74f21a7aeded4df958": "4a98c765d82eddee62174f31b967612d",
".git/objects/ec/30b40097f9ffd6d37236b7661f9952eb6d37e9": "d673dd8cbbc848c39e5f00bd528efa42",
".git/objects/3d/02482afa0b3e70e5ef1ff3666fc967f606e197": "def8ff08bee569558e43f237cdcc8a2b",
".git/objects/3d/ad064e5df1a3bf90eea22fb9d59d1d0fe7968a": "50117b69400535cb31821cd53b2caeb9",
".git/objects/86/039b036d3e3c4d71b630b3055f695355d75ae6": "23843fca0e5d33b64ce5d66a26388cbf",
".git/objects/f2/04823a42f2d890f945f70d88b8e2d921c6ae26": "6b47f314ffc35cf6a1ced3208ecc857d",
".git/objects/c6/0c1ce4acd680851d8308dcdcea67e3d40c9fa7": "a473fd906565d1e39dda5964e2996633",
".git/objects/97/416ca78426f7473ba8aa89745571756c18900c": "e2a105bb04c311aca1c9978f8ba9b7ca",
".git/objects/1f/e026d839cf1c6910b5c000e7f62812db4cef02": "3114c4f490a2677c6a1aa1025b95f4d2",
".git/objects/1f/5c82da951017bda78947a0371e7c2b0820c95f": "53b9a8175c4d4d2428829332ac936225",
".git/objects/53/bc796167458d42ecb995b990927adba6b3e97a": "4dd178e57622528fc4fa5f295f5c8a9c",
".git/objects/fd/78eb65d2e73255f9523639e776b75309350d72": "dc8ef5456b1cc4b2f73e35435a9b43d6",
".git/objects/22/b15fd4240287ff1165d3967d251b0e355d5d96": "fc6412914a1dcc50a2f563ccbc9205f4",
".git/objects/22/f4bc1d22be54b7eed0ede1ef1bc9865603ab3d": "e4dc355dec80fe008af8fa0baf9a3446",
".git/objects/b2/629ec9132a2f89c489d782f3044ac08d8d78fd": "eb964c842aed4987e34335854aca18dd",
".git/objects/d2/ba54c282dc1f1abb3d0d0dc655981c2d71e0bf": "ac2613102ab92b64e102782d7a250d69",
".git/objects/d2/38e9394557a123e670b6e14ed598dd2f2e19b5": "18282d6689e5286fb8f0ed54df4d031b",
".git/objects/eb/6cc137d329218ade89e04d3e4bdbf8c92068e9": "8472e33d380e3efcb3df55677c148684",
".git/objects/eb/9b4d76e525556d5d89141648c724331630325d": "37c0954235cbe27c4d93e74fe9a578ef",
".git/objects/b0/23e9f9db9d006afacc6c1618aa24b4414f221f": "f4a71c24c8bf3ba8e8796a306128a9da",
".git/objects/a2/c3ea28662cc570df57cd35e2a2a1bd0bf7fb76": "5bd55a205537919796590ab72015a250",
".git/objects/a2/a212f0c627790bf3c20cf12f5aad3425c0bdfc": "1c5b29ee9c5c25f363cbdf2e9276bb29",
".git/objects/a2/68e81e91e10ec13babf12a22efc04fa1eb8f34": "09900a2748feb29e87db0da7bec23f01",
".git/objects/40/e4eeff26a2268ddaf49e466d90b955532b5c0a": "06ac6806a2628ce8903cdf963cec83f0",
".git/objects/40/3c32943b9f3c658f36f2324a3ce9391909dbff": "1df2b57ae1bfff37a9dfa8da50f90da7",
".git/objects/40/e6f6788e13398bd4cb8d6c767fe55b3969ffd5": "9daa383a68e9a602c3bed77b777c62bf",
".git/objects/18/26b92a6b24e982e6d3c776dcf7aaf8d8618dd6": "bd898475f7d55b9edd889eab873e6892",
".git/objects/18/b9806f40cd7ee857770d16431b29a19d05b3d2": "6778ba8c883f8efe67ad2bccda9cbae2",
".git/objects/c7/8b657d9e989a8d95b9465646d27e29f0a252cf": "1fa7bf892b3ae9c8d11b10e2684b374a",
".git/objects/cf/af472224624aa9c778036bf93f8ab1e518ab23": "c4047ebacc194132c6d9886d87e191cf",
".git/objects/57/329bd8d495b9173f2ee1323ddc553d5a8eba0a": "3c011420e516b5aa1a9e4ed8afc8300f",
".git/objects/57/fe10308ed8913f11dd6b89a85deed446aa83ff": "e1c35efc0bda8ef71dea32fe449ad16f",
".git/objects/5a/12ef2d7a49a1a6b0733085267bae2199e0ff8a": "fc92e2026d5c4dc825ec24e1380b6d21",
".git/objects/5a/502a1391118f8bdde4a58e116eb0f58024f375": "74fe16daaa98b76158f092ce4540f243",
".git/objects/45/debc0a3f9e22a947e982047c5e99a61382c6b6": "9a683aecd40c3f7244bce516db51b794",
".git/objects/1c/a3aa6c5bcbb6116e786b7fcbae4121ed8210f2": "f34ab1b32e4aee14d360b91671c3ad32",
".git/objects/1c/4d84085f6edc0dfb4a64eb8397c058265734e2": "40f820dc1d51ca77baa255f9ca8ec298",
".git/objects/14/9edd223317f31d6d1dc5763c214d9dd3fc5361": "ff4af519fc6078248ff63fcb6caf3399",
".git/objects/8f/3691cccfce09e3021f0a05c81d02243a5d0ce1": "1bcc445f070fc3e349504c1ddb457b8a",
".git/objects/8f/e7af5a3e840b75b70e59c3ffda1b58e84a5a1c": "e3695ae5742d7e56a9c696f82745288d",
".git/objects/4d/bf9da7bcce5387354fe394985b98ebae39df43": "534c022f4a0845274cbd61ff6c9c9c33",
".git/objects/4d/5e97d1de49d7d05712f2c5df2d13e99439d01f": "e7ad6c10d961e0dfe269e6c7e8905260",
".git/objects/43/2d5b409ffeb87ec646b9c4f1b5767b0be958f9": "cab943dc245b91675c0ad52f09196db6",
".git/objects/43/451bab7fc49cfa02b8a08dea9068a33038029e": "6135b5c63980180c65bf8a3e57e7eb4c",
".git/objects/d0/c836d03874a2ec65aaaeabbffd43cf9c28ed71": "66e89b55e0209ce2c01f64e9c0de9b92",
".git/objects/d0/8f753bc1d77cdf5940f4827df7645003ff92a8": "25bf3ba16324315b0934a59c17ce1558",
".git/objects/b4/f873f3a7fccd74403db2f2d3d7f11d37906e3d": "967ee0c6532a8255f5d062312bd238f0",
".git/objects/02/245dc62333d660e15881147c58b983530b3755": "fd82bff27e6c2a944cb12cd849be02db",
".git/objects/02/1d4f3579879a4ac147edbbd8ac2d91e2bc7323": "9e9721befbee4797263ad5370cd904ff",
".git/objects/b8/942c2c1fee962df2c8718111476cc968b4ad54": "25aec9554493f37f4077f927b136aeaa",
".git/objects/b8/db424d6ca9ad35dab4be927a16481094296d43": "960381106d1b5a5d62fe4e000a4507f7",
".git/objects/2b/f04fe876fb5ccc14fd1fe44688be223eb9a825": "e4812ba0c9487fc2992d31035ba1588a",
".git/objects/5e/6b073f9b2f8c27ea2beda27f519fe0cbd99d00": "1d905c3fb32bb9ebf41ede16fb794f6d",
".git/objects/7f/e3d97810bebe5804d3f2707876907d636ba3e5": "bd6d2834431a4db9108a0eb876ebe0f0",
".git/objects/7f/1ecd3cae0d668925463646edfe30ebece398c4": "83717eab124362e33131c1891d26d624",
".git/objects/c4/2300964ab34d43d39cdffd9642bbb736f2c431": "0dccaf23c3c2cd8af7f95c1b490ad801",
".git/objects/c4/016f7d68c0d70816a0c784867168ffa8f419e1": "fdf8b8a8484741e7a3a558ed9d22f21d",
".git/objects/5c/df8365e4c535d9631462e290dad271945b2ff6": "16b7d2f36ad2fd3de57f80a557a36da1",
".git/objects/4f/fbe6ec4693664cb4ff395edf3d949bd4607391": "2beb9ca6c799e0ff64e0ad79f9e55e69",
".git/objects/2f/519a78f7fff73d7adf68b39d853cf8ec5c5cd4": "4449d6433a97717b49237a0b6fb73946",
".git/objects/cd/286ff38399f661c5cf7968b8f37427ad72826d": "e2d4ed75ad512fce5c7b253d9642fb24",
".git/objects/cd/86da712e65184104ea5d8eb108f1c282e6b6ee": "121914aa4bcf37a0a1ba31ae1f9db049",
".git/objects/87/1f740354a285eac7199da0f87a5af058c627a4": "33ed680956d02793699525369982d9f8",
".git/objects/fb/10ad419f3b0699088fdf52617705849b062024": "11f08cccdb7111f344fc404beeb4dcfe",
".git/objects/f7/86969755bcbd5b95419dc80b72e3629cccfb32": "f0b8c4c52ca410dca5a9aa45a3561f2c",
".git/objects/c3/36bbc519575cc4ffd1dbde356eecb1ccec5f2b": "a5ca23071c005ec055c9eadb6a6b2738",
".git/objects/c3/f76f3830b4382079f5832db0deae407cfaf00d": "f99d7944ad4d7b5d5c3a709d65d5a2c4",
".git/objects/29/ac9f2b1f132d48bce44038b2a1c1542e032c3b": "7d2b468101e11c09b8f4df2592dff84a",
".git/objects/29/f22f56f0c9903bf90b2a78ef505b36d89a9725": "e85914d97d264694217ae7558d414e81",
".git/objects/6b/3c2516e121478c6f58dcd0e4be8f2b084d9162": "18afaf12515884253368dcc5e569ed52",
".git/objects/6b/9862a1351012dc0f337c9ee5067ed3dbfbb439": "85896cd5fba127825eb58df13dfac82b",
".git/objects/6b/313dc691fb19a79ab5404ef01e86f1808900b3": "c05b35d1e9ac5c76451f266ef9391b65",
".git/objects/6b/6016ec6d130855ffd7ab836a27e32ae51ad2b5": "c8b50100446afc86b36f8d5062f3d20c",
".git/objects/3b/5c9695aecfa2ee1e5ed5d2b13d74469862df67": "b051cb1b13bb8d3a31b289eea90cb268",
".git/objects/b1/7241a431532432b5d7f1d2567ccdd286ba5126": "6334c4409dd2fdb9b0134efd4e66580b",
".git/objects/3c/856c456557069813fb73cf222acd9eac8d1403": "e01850a97991c64a5e07ed142a09f144",
".git/objects/3c/f9ba84f11bdfb59fbd36e20704db13ccd5c011": "3fe39563fa7e9f122097853292a98c0b",
".git/objects/3c/00089ee2bd80da86b3d97a69a4324d367dbe16": "4c629a336e0ef6c5cfd44135c4fd6497",
".git/objects/a1/0e6a9ed543780431e5156ef992cc62669e3869": "2dbfeafc14bd91048ceebd89fbd39852",
".git/objects/2c/cbd2301be725960e6ff0461f822649e25109a1": "31bc4d1963723f12e6253428ea268988",
".git/objects/a5/9bf972b4b0d3fc7c18ba3a8e6cd6fda4cebfe4": "2fd7490075e3b5ddd0fc9937aafc6ae8",
".git/objects/a5/58b511f412df673ce3b81956a26a8be8d7fac9": "94a97ecd248d571ab74f62efaf72cafa",
".git/objects/d8/da8b44a6eee923c956e422bbaf88db0a3193a8": "1366fa998c4c534396588392d92bbe35",
".git/objects/d8/669bfde26d66e88dc4338f8faee2c1026efa85": "78c89f76774e7423cf321e2b9adb7841",
".git/objects/56/794005785ffa306fbe320731afd311265dfe69": "a2b815a625ad841fbcee829b824a6f0f",
".git/objects/56/dc2e8557284fd7cf7c8a843686222af5983408": "7ab59488d89d2be4d0baecf6f95b6596",
".git/objects/56/39da0163d172d7ecfff1f858c831180ed1494b": "3494d9b6b6659b6ca47513c7190230ee",
".git/objects/56/68510e24bc5ddfe033fbaf52ef30db3b32d211": "6bfde38b322ccc7bf6ec9e8075b79dc0",
".git/objects/75/bb26b9c6b30d86678be24de519ddb253379ea0": "dd860f88e510331be8513c033ed90218",
".git/objects/75/ee4e44ca0dcf57e28d03b5459a3cb186c8fdae": "142c11ee5584d5f894afe57498855a0b",
".git/objects/d6/9c56691fbdb0b7efa65097c7cc1edac12a6d3e": "868ce37a3a78b0606713733248a2f579",
".git/objects/c0/efa4a9017f834ba6579904e3eff9029cee87f9": "b6109bfdff715e5b213ef9de34e23bf4",
".git/objects/c0/0fd533ad8ea5ddcbef61dbfb30650e8b81cc36": "88eb8e1e9509b8f32047285710662d0a",
".git/objects/c0/6d8637e9774638f7713e84d761d0a2c075e8ab": "58a160b71edcc5cecef4da17f4d37a98",
".git/objects/7a/6c1911dddaea52e2dbffc15e45e428ec9a9915": "f1dee6885dc6f71f357a8e825bda0286",
".git/objects/7a/706fec01dbc6239a4375f4e80e79d206044d80": "33acb8ec93405b5e365acca625c29d2c",
".git/objects/7a/82e2e6e17b8651cfc968638c3a2eef7886aa51": "b4e12d890d6309a4a40bae441207b040",
".git/objects/91/9eeeba642b45202047160383e6afe872a2727f": "2e8ee9cfdbb2a8d3433ba2452bd69e09",
".git/objects/41/8948f2e94983b984d3a2016e74a910e409fe33": "7abcb568f76246070a0a7d71cf8c1d36",
".git/objects/e0/bd5e7b4cbb664aada5dc851a71a7da6084fca2": "dbf62c1e7df56762adee0e7d78ba8991",
".git/objects/e0/c05243111b5e33ae230876232c2a60b6f2fd0b": "ab15621ed6e508f2edc2813e30a99508",
".git/objects/4e/ff8ebf14662a978e5f3fa57b85d38dcfbb9602": "6b6573ca394b786e3ab4c818346e9fb7",
".git/objects/ca/3bba02c77c467ef18cffe2d4c857e003ad6d5d": "316e3d817e75cf7b1fd9b0226c088a43",
".git/objects/ca/47db82dc1c7f0680228d8f4bdb57073bdb8835": "c0c5ec80e956b848c61e06bbca627a6f",
".git/objects/f4/ec42fc1ded25943696db93d72997af85f19339": "50665fc42b5bd06e562578f1840e0120",
".git/objects/b7/1ad47f75a6724c81cf8992a89a4494bacb5e89": "e5cfd75f2dd2cc652b5832ae09bca6d3",
".git/objects/b7/49bfef07473333cf1dd31e9eed89862a5d52aa": "36b4020dca303986cad10924774fb5dc",
".git/objects/b7/2aaa95af7296f624a934d277fef9a2dcc18cd5": "9d7fae28edeae45ca524b64150dfb50b",
".git/objects/2d/a542f1574d8618bdc806b471b3b7a0569ce938": "2436d1607c334932aefc7489956f3364",
".git/objects/2d/7f650e3b4e853cf334129a7b9b57cd7a13ef30": "00d20f1762d24c2184cb588f30753803",
".git/objects/2d/f0118cc19fa5cb94973c7f472fe62bc7f1126d": "84993070661121b829a74bcf5ca7af4a",
".git/objects/2d/a2610d19536178b608f28e9c454247fc09b8a4": "dff7040315bb3058c3f86e3b3e893601",
".git/objects/0d/89272217e334e5738f856e939f6a4b8e78d07a": "e962bd0cb33a09aa4bb7c894c92db34d",
".git/objects/0d/2af6fcd9a4ecf62207b8a783ff240333523f96": "2521aa38aea8e7ed8297a8c187c34523",
".git/objects/d4/258f0f19a818d68cc55c4988f0a3a69e021bec": "af67ecb95092756df1e5ccd48baab37b",
".git/objects/d4/3532a2348cc9c26053ddb5802f0e5d4b8abc05": "3dad9b209346b1723bb2cc68e7e42a44",
".git/objects/d4/041d8239ddb72e91919dc1bb0719106844ac94": "511768b61cc70aeed4ea7be0e488654b",
".git/objects/db/2d25d3e7ac81a3a5b5604f87e62dabe75d775c": "d324c349f20577b22452a29d2f458bd1",
".git/objects/21/94d212974db683e417145c2799cd58fe9a5c45": "a59e9e17f8be8b5c93f5c042188dd8f5",
".git/objects/f0/0f28397fdc31428078887729651b56f2b4ac37": "14db9b5e0c43d76fad1a3d8c47825b19",
".git/objects/f0/13196a4cb6e250de463436896063b835566658": "154847084058811a017179d31cb2e836",
".git/objects/f0/e969c7b0646e8f482fb08252a6e061b05f1592": "0575a3a775992bed90edfe61bebf77cf",
".git/objects/af/a3938719aa5f522227f1942cc7ec059973e8d3": "3722ad40b298b6fb8ea793b161150c28",
".git/objects/ee/71e44cba81f4e5e2378c04ea6d36eb69f13634": "9ca8c99d17532ab84141f505febe48f8",
".git/objects/ee/3c8c5c929f3b40e87689778d1ea4fc57561c5f": "bc7571784bb83663e716cd0683c7c56e",
".git/objects/68/4ffecc253a4578bafe0ced833e202fdb78c250": "bb1015341c4ddd4628411203beda34c7",
".git/objects/68/151c72fc7f8ef5622d743f9506ce2dea7423c4": "84d165b9345b653858985c938a89a933",
".git/objects/68/aec60d5501feca87cb7b8c7908c6cb8be66bf0": "062c6069cd8d653a2b0a1bb917643895",
".git/objects/e1/92daf007056d067227c3ef364e84e158f505d3": "a651ef6394696d39b35276e39b60feb8",
".git/objects/e1/4caa875089d76a530f63c97013307195b615b9": "d1b63cccedc54354554904e6e002bbb2",
".git/objects/e1/0e9cf895b3313294f77c27025890136f0932a0": "df27344ea5a87550a53aeb4eadc854b1",
".git/objects/e1/920658446c5fa4505c7647141fe4465efde0aa": "c60a763bd6fd88506c7e8d5cb3968dcc",
".git/objects/61/82604663cdfd79b8ea1c754ca02db1c52c53c8": "9e4fc575965aba1e9883d7a9a470ddc1",
".git/objects/10/cacc3957562ee06ec20735587bf339d448f8be": "23a29549080823ec048221b15f41acd1",
".git/objects/10/a3e789b86b566a51cc3be056681f2125567bc0": "a62ea2ad8d13d74deb605ee27200682a",
".git/objects/71/7875e45b5d969eece3fe3dbacfeeefc3e40825": "ec564229cdd7a92744c6495359021917",
".git/objects/71/0b37574172b8ea423af7f788467288239d95d9": "ef31306e93b8e5c5c8b9084b6a804b98",
".git/objects/b3/5a00a34425e84d79c0441333684597c1a1dc4b": "136800af625993c927f3628ce7e7b734",
".git/objects/b3/be783e6a5fcfd2859818c622335fbaa5baacb4": "e853fdc569034c2e0d2ee1a2e49375e1",
".git/objects/24/db59cb003cffbe3ae02d46dbca888dae3bfffc": "a310504aaf356bd115ae5c1ab54aa2bc",
".git/objects/c9/bfb8fdfc50b97d18f5fee5e3cf03f44d2e5610": "63553006ab065f89a62d349d3b72fea9",
".git/objects/c2/31e95bdebfcbdd02204f93f78fdb374fd665fe": "bef37098943f84f18f7367df195dc10a",
".git/objects/46/34e14ee7b6f4a47159db5a1e03e3afe5a54803": "7c10c259434138858c43feae4e14d036",
".git/objects/46/94cbe2620c6b5f3b97917912787c95fccf3c5c": "4b219d50339baab6e279166dcbb2cceb",
".git/objects/46/1b3262297415cf79a778cc9459549041eaee57": "c8018582f5ac4002e74e59d9c0294334",
".git/objects/46/4ab5882a2234c39b1a4dbad5feba0954478155": "2e52a767dc04391de7b4d0beb32e7fc4",
".git/objects/46/7a4654f0426db7677e539f2e6416f417e353ea": "3c800e10436e4e825dba68e95878ef52",
".git/objects/94/4cc29bfd8abc70850f5379d608bac92ac3a32a": "0617306e1f67149215679636da01ccf3",
".git/objects/94/9c34db180b3e2c1c383f67336e49a346e25c8e": "7fc2a24232a3514343d87ac0d6a1ff6a",
".git/objects/09/1c158a894995c6fe2f12fa5c05da8d8d9955a2": "99d58465503aaee3a37db688152b51a8",
".git/objects/09/257b4f121b95e68626e9f0f258da87faa5845c": "66345ad231517fbee0ee0a430a2887b1",
".git/objects/8e/4b7065c95be601af94e25cc9462104623cc062": "daff1a0faed53f77a4438e3cfd905f89",
".git/objects/35/95f468526c0227bf67d26e8765ed47fdae177f": "7a02adf47b9efb0a066114e0240e795d",
".git/objects/35/708d700b1e19622364847ec340a1bd0aa60e76": "ddfd66c652e9ef7fba706295792ee908",
".git/objects/35/88787decdcf18ab795f8675959313c28bdb577": "a76833bc8fca0db5f5e6a166f96e06e6",
".git/objects/35/75973a8ec49c39d42446edf18a05b52639cb19": "e08992fcec2769b7af833ce36ff50273",
".git/objects/8a/46e1198f1f655902810925c877932396906179": "bd6cf73bfed8b333d4812514df2693b0",
".git/objects/8a/aa46ac1ae21512746f852a42ba87e4165dfdd1": "1d8820d345e38b30de033aa4b5a23e7b",
".git/objects/8a/9261ba4b91bf41f1f698f2ce6027bb145edd9f": "63f62ebfdd44f6d364acc6eeea3db556",
".git/objects/8a/886483f393c3e1ffc79766f23426bad07440d6": "73ea6a43a2072fcdcceba33ac710def0",
".git/objects/8a/a5fbe7a1630211a5d9540eb347ea289863af4e": "0b538a70a5c5f0338edaaf002d939e9e",
".git/objects/62/f7357a7ca721f8523c52ec35d19860ba73aecb": "2d9f10d6efa345e9089a9037dd56fe29",
".git/objects/62/1f37c4bd930ca80d277f783f980beaedba53e6": "c673b706542cad5b02621472278793eb",
".git/objects/62/862cd8d3495fc0bf5fa70aca51dbfe7b047c37": "ef89eaae3ab90b0974c6e9753e2e546a",
".git/objects/f9/b815473a27579747c16204e91290cfcc41dcaa": "290f3e63f222b551b9c248761ff8a701",
".git/objects/f9/962ab6579c182ed5f0b14ef1075bc8708e1c95": "b6ebb18e6a3013a35a1ffe08c33bfd64",
".git/objects/a9/b6579281d8f18857bfc5544b00ab2839fed153": "53cb469dcac13d564e1d9c37052b80e0",
".git/objects/e9/94225c71c957162e2dcc06abe8295e482f93a2": "2eed33506ed70a5848a0b06f5b754f2c",
".git/objects/e9/b8454c1b679162be49fd0020fe63d4e938fea6": "1f7710a736b8e7c83eba4776e7cd8b74",
".git/objects/8b/1aabdfb968523e25863071a6df73b0959a83c3": "72d24c249f13868b17c56f17e31ad522",
".git/objects/03/eaddffb9c0e55fb7b5f9b378d9134d8d75dd37": "87850ce0a3dd72f458581004b58ac0d6",
".git/objects/03/4c91126563cea015b6b5b3652e5aeb76b3cf10": "c73dd68fabc169e43c5bad41456ebfb8",
".git/objects/03/d1e31b0f9b12da3c242ae24681ee9668a2e009": "a31df6a7a1223369d2042516150f6626",
".git/objects/03/83b3e4aa0687f94873c88735e8afc4f5b7d175": "74d6d6ce62f7e7ce77d76326cad6cb23",
".git/objects/ed/b55d4deb8363b6afa65df71d1f9fd8c7787f22": "886ebb77561ff26a755e09883903891d",
".git/objects/98/0d49437042d93ffa850a60d02cef584a35a85c": "8e18e4c1b6c83800103ff097cc222444",
".git/objects/98/d466a981d489bb8af86c8a11f534db4a714bc7": "f29e0fc1fc846e3cf5a9249bdc4eabdc",
".git/objects/79/e6bf33d656049c2cd2244af1c9656d001eba0d": "3cc45908d55e488db59c772f3c52d432",
".git/objects/65/2c20c0c3079d974b49fd0cd1b0a993ea6e3ffb": "8e26ea390d970127513e113e3ede1c15",
".git/objects/65/04c26460c5b7b003679938cda77459cea7a3e1": "219e77bb3a998f8653ffaf095bc69a40",
".git/objects/65/2c71b5a02086f36726fc4486b2c912902a4a25": "52da660e2a37b88bbad402093761fc83",
".git/objects/65/9675f08d5d05b5aee63412fbbdb8b774d0b55c": "2815e756d9139355e30163a683cda96f",
".git/objects/f5/72b90ef57ee79b82dd846c6871359a7cb10404": "e68f5265f0bb82d792ff536dcb99d803",
".git/objects/f5/fa98896af41e369ae7f61b1c57e57f0af26514": "d84ba7c9df5ce3c9cb03c5b97109438b",
".git/objects/a7/4cadf34902d65a947f734f8f9054ce3e7c45fa": "c9d6332fd3631db2ca1096c0a5a0f422",
".git/objects/a7/2c2de4760784158736602586039d905b73810a": "3e81357eb51ca44ffe0ccd906a3e812f",
".git/objects/a7/c60a5460b8364ed277cde223336ce2dbc6115f": "e061d606fa1adf7905b6624047a54e97",
".git/objects/a7/680152085d7c7d98ab1c0a6afeb575a4a20629": "fc2226f1538420433ada393ea23c1853",
".git/objects/52/e9da3ba23dbd7e6df449533570217f066792fd": "002940f218d757b0b2f13549a1c63690",
".git/objects/f3/532f0441d6102683f4eab494a897b609ebf5ff": "3b606656c6e2217c3785d9a0b1f44566",
".git/objects/50/09d271a9d8db3eb4f93131407be90e766c527f": "0acd41902b304f491721dd8097b723b2",
".git/objects/66/116f510cbd1deb0bf0d1cc671158861b377384": "6b26638f30f76b967162d25962cf4d63",
".git/objects/66/1bd75fa41f83963c3e20d5c955cc5a24026b54": "31fe840176a957f903fa0ee19dd9acd0",
".git/objects/20/3a3ff5cc524ede7e585dff54454bd63a1b0f36": "4b23a88a964550066839c18c1b5c461e",
".git/objects/0e/500045204edeeb1bd1e2f3f8ecd9c986410534": "aee0c5bbb74f1573e3761f6fc0002dac",
".git/objects/b6/b8806f5f9d33389d53c2868e6ea1aca7445229": "b14016efdbcda10804235f3a45562bbf",
".git/objects/51/6233364da7533eb47df35e5e0093891fe48b6d": "7ebbe3c5a6e630208f28037ec0add16b",
".git/objects/51/a39c1afae9d298c9b5dd80c62fca2c299c6c8b": "2ad437f4582a41ce935e440ef85e93a1",
".git/objects/3e/b8549dced6df13178a8fa4e836d2b3002c21a0": "a7956b5afbdd9cb886285e27c6228954",
".git/objects/90/231026edc98c59bd547fef27379c4f72eec0cb": "a2cab5d74bd9f701bfc8484c12200f65",
".git/objects/90/7bc1b86683de917f91dbc75495afeac34f9c29": "ffaa36ebe5163ea803834b76aebd0aea",
".git/objects/4a/e3e3946f4605763df18829f2621350146fdebd": "bec828b0e87bbb3dfe004f2a06446c30",
".git/objects/67/769e3235d9ad52011cf2ded73e40bf7b6a0763": "0c1a7a7f64357858eb7644191d5cd6d9",
".git/objects/67/673a9cc049ec379235983d9b755abb059df478": "d0316f0336b472d58504776c96aa3884",
".git/objects/67/0d345a837e0649eb5c95adab7b24fcf2241239": "63b75711ee0b5d1020518b3d463016a0",
".git/objects/bf/2a072d68724df2e7675e960fd2f9ae2b84a1b3": "530580474f35d7502c5f301a05354e41",
".git/objects/bf/f32a2db0872a6bff7ab13ee11951beaff3cd53": "7754a85df0dbf16edf97eb0ab8c8cb66",
".git/objects/bf/b22a029e97c27c9020230e6092656d14f95752": "d836ab3b1db3a93e83f7bedf586b0bda",
".git/objects/aa/c55e1d93edf76e50cca47875506122d3928467": "6939f51173be062c4694e092acdc3dde",
".git/objects/aa/d9c1661222212f3227beaadf41e7a37376ca8f": "266bfc8f0cb9b7c2c9a8adeadce3a22a",
".git/objects/63/805fef6e9520b16e281766fbccd04d882c253c": "7457bb0a67d173ef0ee66ba105a28131",
".git/objects/63/5d984eb07a1c7e83fa7746f43ac8c25c35ead5": "9d744f9a2b4b2bfd12a9d9c15c931feb",
".git/objects/83/510dad2885cf71d679db268d3521f8ed72d115": "68662d7bfacead9a52ff1e76bb4bd12b",
".git/objects/83/d63e0407926419b997a32535f10e50649e02e6": "3d01f3f48edd23b0a81166800ae20353",
".git/objects/58/3655675f0b2244bdf7326308d1a1bbd0084b87": "4662c109f6e869080fdb9b9df5340e12",
".git/objects/58/f792e2ce82dbb6ac47b2d16f5ec984fac7ee18": "e2d183825db8d19a69523a491a20c44a",
".git/objects/58/6992893a02168a1b202f9af7bcff0e429bb742": "795f8c3261aef4bc77f213311f0df576",
".git/objects/58/fab80a6b37bf474b03dcc244a3a9f231737dd1": "5998d37b85f7c0cb1b57a9c9fb5e6e40",
".git/objects/58/4bc0334c845ef2bab8f3ccf9b68f89fa41c158": "3abf007766ea1a66579956ad3c6ce819",
".git/objects/2e/e2ba9bacb16b032f3c46718b0a42bac21fcd94": "5800c8577f97862d55ba3ca9e8f3d2f3",
".git/objects/da/89b6edcdc1d16c4f94e47a9169fd5798007a28": "05eb2a250a10ca02911b805270fd17ba",
".git/objects/da/8b20418180ce1d0440476d84549357a7b7199b": "8727cae7eb4b292dfc5f5987476b47f7",
".git/objects/da/27bab342422f84a5b32ab5679cf86c6a89a60d": "a87fa29898b9c590d94508c550556ad4",
".git/objects/9b/3ef5f169177a64f91eafe11e52b58c60db3df2": "91d370e4f73d42e0a622f3e44af9e7b1",
".git/objects/e2/42054a7ce8a7d3164d396c90c4902824fc4fe6": "61b9f26ff0293b76347c80c69a7117d7",
".git/objects/e2/872c1f109eb0bdeddb2b9a5888b78b6a3b19d1": "a8064c48f4e0e2d256b45ae33531c0f4",
".git/objects/ff/a62fdfe6faec0230ff3637cb8b615098b17c2e": "12666f868507b9ff5b26ceec6102bb63",
".git/objects/ff/d9728578e98e2ff96075e982c8706eb7967450": "6a1b3c47df05e5d2298970ec719d7336",
".git/objects/88/cfd48dff1169879ba46840804b412fe02fefd6": "e42aaae6a4cbfbc9f6326f1fa9e3380c",
".git/objects/26/3c945ff342dfb0240abbe0592b9018571d9c86": "64325a5a2e0358c5d58e5b35c4346bf6",
".git/objects/26/7847a1081b539ad48b7dc8d6605d42224c5616": "ec4fad730de3b6370474628f6b433ec1",
".git/objects/26/a99cb4c2e04dfc88722f26800303af0f17b677": "025f0be4cf66876324e42070e3974aae",
".git/objects/1a/b093134a6c0b6f5da4606bc25eec23b2610779": "6dc52954b33d1c1e58e219478e670d8d",
".git/objects/1a/2e5e781195350ee245f1eea0f1cbd18d045b4b": "0fe144d8d84e4a37404a49f4c99863c2",
".git/objects/5d/62c1f7816c6d5875908a769080586373448111": "ad5075546bd62a2f3e7ab34d26a56af1",
".git/objects/16/afe6f291fa29c8aadf4ffa51b57f95c62bcb89": "3bb8fed3affb7f59bbca47937b58cd0f",
".git/objects/16/14aa376c5f6bad9f6dd09f9c1e002010e079d7": "f7edd2a62398d6188655369f59a1d03c",
".git/objects/16/e0cb394585ea5756b1f646a6ff4efd139b8abb": "ca1548e6a37fda0a6d92c8294b624bf6",
".git/objects/27/c7fd4eea13d50aa272dce62f2c506b532b88de": "95203cd3f7b54edc478042ed882de427",
".git/objects/ba/a41de36d7b7f4dadf06e7bff1fd7e10b14c415": "a341d72a381f1882727933fdd24af123",
".git/objects/7c/3181f0f832502b41f6d82d47ccf0ab350cf1db": "5a77eb772815fd6aa406bf2e2c6a52ea",
".git/objects/c8/5b0f1440d89ade779eb2e5a7c0f6a3e8f5409a": "92b24e64cc87149a3a4f96078a96f4f9",
".git/objects/de/0be65e746913fe67d8963569703ab0d179684f": "fdd1a7ebec5db996d5b59a1ccb870dc6",
".git/objects/de/474dffe701858df63d2be7bc36347f9e6d0ffb": "e082220ef59b33b411e4a84ff2a38a65",
".git/objects/5f/c6cce97eb485a2c86638f3580171245a288878": "a3b7443697a8bdffa8f09240ca639c6c",
".git/objects/84/84e6b0a66fcec8714df7e6260e62991d534189": "95d54d9b0ded65d2c312fc466b8f9071",
".git/objects/e3/19eddb57a0bc045900ed9e74c666fe0b59cceb": "16f49a13b4e63a1985c860836eb921b0",
".git/objects/e3/e9ee754c75ae07cc3d19f9b8c1e656cc4946a1": "14066365125dcce5aec8eb1454f0d127",
".git/objects/e3/d58e852fdd01f4c49c9631e53fa6c658574c2a": "e68ffc9cfb2b0f931dbfa21e95ba3e10",
".git/objects/cc/2a1a617a63a74b624e1d8cca943ff53e20b4ce": "a32f89e87fdcdc5fd867e1ec5514634b",
".git/objects/82/8a8c8bcebd3ce04e1693d81fe5a3632fe20a72": "49bd801321e09a875272737322eda1ba",
".git/objects/82/0ad1c2eb0bfeb0c7b558652bdba12e18a508df": "f6081cdddd0936bd4d36adbea8125e40",
".git/objects/06/27c346cbc4c8708a9d53f52cda1821579f6ef9": "65f85fc9271d7da3cc4c811d8b1aa7d2",
".git/objects/6d/1590013d8c61589fafea0ce4cb2939c17cc7aa": "fc6e882a2787eb1f8a1682d0a69a6131",
".git/objects/6d/81e0e0dc73735c93a275d2e51427c66c18b7ee": "8f906e269a8cf8be4202096ac90541b4",
".git/objects/a6/c26b7c886f4d3e1d92c6331afa59e896e68379": "0c5a86a628b5f1eaa8976981a2c0423d",
".git/objects/30/6d27e1bd144d15fe50b322fd917763fa5c3d87": "0b9854b4c0ed999cf6018b5f9a80880c",
".git/objects/ae/63722b4f6de2473e160289ced09b5e08405b6c": "4b00da4c91aa4ec961ea06e57d8e479a",
".git/objects/7d/af9f95c25fde98df27ba4ba28b17a50bc1057b": "463f34c9aec494f5bd34f31c5bb015d1",
".git/objects/7d/0451d2984eaab7fcc0a63ae7077729680135f0": "7d50ec16eff82e967a33c683d5e5ad90",
".git/objects/e6/38d38043cf654ccdd4971ce70e3480e72835dc": "406f61ab15e05cf3c88c4249c068fe5b",
".git/objects/17/904e1dc833453cb9eaf33f67644150bf45779f": "0b2da95092fca8049615d8f8c7dc2b9b",
".git/objects/17/5b20ce0f62d382bf7b11bc559eb6bc8b492c08": "30c741f05e159ee6d7e10d252c9ee638",
".git/objects/15/bc9eff5a9607f50626da220b6e90cd3a62c0a6": "9378af8c511b291f336f192394e98252",
".git/objects/15/5bcbaa124e2e4668a9794c056684ed1e760405": "e4b15b185bc9a7b59566c5988a53dfe5",
".git/objects/ab/6e469e36a084d9849cc693e43938ddae61fc56": "1086ba1a82852b2c507636e37dc12263",
".git/objects/ab/daf8172935b6385824f161718c325d377432f4": "18cee9b55c95f9bbc42b6eada497e8c2",
".git/objects/6e/1c4e8abd8d48b0fb6df581beaef2b61a2f4df3": "a331443ca40544b89bf4994bb32efac7",
".git/objects/a3/4397a3f1afc817bd56fcd79bc3247c7fd95b19": "7c41ea07016eed08a8f77d22bb5f44c6",
".git/objects/a3/9ef40e043222e0769417318210feb0753ce00f": "a5fd136ea43451a5c238210ceb758466",
".git/objects/42/7558d379130641595e5b668c797eebb0651604": "3f55eb436ea2068b1dd8f1410395cd83",
".git/objects/76/def71f978546082c24f785886a821e4c2cc2aa": "741dad4c4bdf9f2d16500d725e5478ed",
".git/objects/44/dad1ee0f21470c6aa9acdc636e2742a6f7dc45": "1ea488d8480d43bca2c72cc50276ed26",
".git/objects/44/2e117f65cdef4cf3ebb4a39353ad18be052adc": "30a27bd4075a0ddfc905077982eb34b8",
".git/objects/81/8eb6483cd1453ff935de2fb6d6b472e6ed009a": "2492ed5295301a54a16eeb3642055964",
".git/objects/bd/dad80c1d906a67573750f603147a2a3525d9fc": "9476dce292cc0a4258ba47e9630f6b03",
".git/objects/93/4475707c9d0502095174fe57df5ff499a8d783": "402ae65acee52979d5f4ebff5409296c",
".git/objects/0f/58f81a8115269bc6221402136599cf10dacb49": "0cb37d28d96be7a54dfd53e1436132cc",
".git/hooks/update.sample": "647ae13c682f7827c22f5fc08a03674e",
".git/hooks/sendemail-validate.sample": "4d67df3a8d5c98cb8565c07e42be0b04",
".git/hooks/fsmonitor-watchman.sample": "a0b2633a2c8e97501610bd3f73da66fc",
".git/hooks/pre-applypatch.sample": "054f9ffb8bfe04a599751cc757226dda",
".git/hooks/pre-push.sample": "2c642152299a94e05ea26eae11993b13",
".git/hooks/push-to-checkout.sample": "c7ab00c7784efeadad3ae9b228d4b4db",
".git/hooks/commit-msg.sample": "579a3c1e12a1e74a98169175fb913012",
".git/hooks/pre-receive.sample": "2ad18ec82c20af7b5926ed9cea6aeedd",
".git/hooks/pre-rebase.sample": "56e45f2bcbc8226d2b4200f7c46371bf",
".git/hooks/applypatch-msg.sample": "ce562e08d8098926a3862fc6e7905199",
".git/hooks/pre-commit.sample": "305eadbbcd6f6d2567e033ad12aabbc4",
".git/hooks/post-update.sample": "2b7ea5cee3c49ff53d41e00785eb974c",
".git/hooks/prepare-commit-msg.sample": "2b5c047bdb474555e1787db32b2d2fc5",
".git/hooks/pre-merge-commit.sample": "39cb268e2a85d436b9eb6f47614c3cbc",
".git/HEAD": "4cf2d64e44205fe628ddd534e1151b58",
".git/COMMIT_EDITMSG": "c21c39f3a94d7e1fe9f0c61f62f7567a",
".git/index": "9861ea15c0f2be6672a3f477c81d4510",
".git/refs/heads/master": "237afd4861f584798cfb0d08b4caea52",
".git/refs/remotes/origin/gh-pages": "237afd4861f584798cfb0d08b4caea52",
"main.dart.js": "c043c5e51f82699bf779ad204b2e2158"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}

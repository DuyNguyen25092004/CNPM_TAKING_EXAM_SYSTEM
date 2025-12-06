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
"assets/fonts/MaterialIcons-Regular.otf": "1adc13d1857cfcdf55b56ccb2c189cdc",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/AssetManifest.bin.json": "69a99f98c8b1fb8111c5fb961769fcd8",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/AssetManifest.json": "2efbb41d7877d10aac9d091f58ccd7b9",
"assets/AssetManifest.bin": "693635b5258fe5f1cda720cf224f158c",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/NOTICES": "b5a06f6e244f735b457a518b35ecad7a",
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
"flutter_bootstrap.js": "98f038bfa9888809abbccf69e0b3f864",
"version.json": "797939af3b0c8c2e29b601e6a2d38939",
".git/info/exclude": "036208b4a1ab4a235d75c181e685e5a3",
".git/description": "a0a7c3fff21f2aea3cfa1d0316dd816c",
".git/logs/HEAD": "6005966ba0ca056ec6597188dcad7ecc",
".git/logs/refs/heads/master": "6005966ba0ca056ec6597188dcad7ecc",
".git/logs/refs/remotes/origin/gh-pages": "2e65d60249f73fe6093776de75f383a3",
".git/config": "554fbe72bd1dc1f31000fb2c3ae459cb",
".git/objects/b9/2a0d854da9a8f73216c4a0ef07a0f0a44e4373": "f62d1eb7f51165e2a6d2ef1921f976f3",
".git/objects/60/10a64c880f9531747770e60105e80330cf4902": "16bc2ba0a7da84abb3a3705d85b6f24a",
".git/objects/0c/46a63ff613ac4e6c4c20191c5d9489f0b8ebe0": "db847ad23c022dd39705d10b30f07338",
".git/objects/9e/3b4630b3b8461ff43c272714e00bb47942263e": "accf36d08c0545fa02199021e5902d52",
".git/objects/d7/7cfefdbe249b8bf90ce8244ed8fc1732fe8f73": "9c0876641083076714600718b0dab097",
".git/objects/d5/f1aa3edca7b31466dca11b1e57b9bb0e3f1e6f": "ec7c4b3a55d204e1c42d1954f7e1592a",
".git/objects/d5/a2f1ecaeff49f651d79e05b8e8807920c3c5bf": "dc95de045c32a98fc16a15b30d118ed8",
".git/objects/48/37466f7715cf36562191d80764dd06237cdfab": "c660f0d54806cb029b0f5667c78f7e04",
".git/objects/fe/4ad73827a3a2f88f7378d6f7d4acac3cc11087": "9a516bb146ec636e570c88b1a318fd9c",
".git/objects/fe/3b987e61ed346808d9aa023ce3073530ad7426": "dc7db10bf25046b27091222383ede515",
".git/objects/6c/9c7b6a4595097d33efbad0bd0020a2b6c83fd2": "9c2da6e29c9d6342e0dfb05e382f3e73",
".git/objects/69/dd618354fa4dade8a26e0fd18f5e87dd079236": "8cc17911af57a5f6dc0b9ee255bb1a93",
".git/objects/fa/8da42286c39a3cad36f8c9f41655963a880df1": "32d6b670abe4cafc1b25440783ae117e",
".git/objects/f2/04823a42f2d890f945f70d88b8e2d921c6ae26": "6b47f314ffc35cf6a1ced3208ecc857d",
".git/objects/22/f4bc1d22be54b7eed0ede1ef1bc9865603ab3d": "e4dc355dec80fe008af8fa0baf9a3446",
".git/objects/eb/9b4d76e525556d5d89141648c724331630325d": "37c0954235cbe27c4d93e74fe9a578ef",
".git/objects/8f/3691cccfce09e3021f0a05c81d02243a5d0ce1": "1bcc445f070fc3e349504c1ddb457b8a",
".git/objects/8f/e7af5a3e840b75b70e59c3ffda1b58e84a5a1c": "e3695ae5742d7e56a9c696f82745288d",
".git/objects/4d/bf9da7bcce5387354fe394985b98ebae39df43": "534c022f4a0845274cbd61ff6c9c9c33",
".git/objects/4d/5e97d1de49d7d05712f2c5df2d13e99439d01f": "e7ad6c10d961e0dfe269e6c7e8905260",
".git/objects/43/2d5b409ffeb87ec646b9c4f1b5767b0be958f9": "cab943dc245b91675c0ad52f09196db6",
".git/objects/02/1d4f3579879a4ac147edbbd8ac2d91e2bc7323": "9e9721befbee4797263ad5370cd904ff",
".git/objects/c4/2300964ab34d43d39cdffd9642bbb736f2c431": "0dccaf23c3c2cd8af7f95c1b490ad801",
".git/objects/c4/016f7d68c0d70816a0c784867168ffa8f419e1": "fdf8b8a8484741e7a3a558ed9d22f21d",
".git/objects/4f/fbe6ec4693664cb4ff395edf3d949bd4607391": "2beb9ca6c799e0ff64e0ad79f9e55e69",
".git/objects/c3/36bbc519575cc4ffd1dbde356eecb1ccec5f2b": "a5ca23071c005ec055c9eadb6a6b2738",
".git/objects/29/f22f56f0c9903bf90b2a78ef505b36d89a9725": "e85914d97d264694217ae7558d414e81",
".git/objects/6b/9862a1351012dc0f337c9ee5067ed3dbfbb439": "85896cd5fba127825eb58df13dfac82b",
".git/objects/6b/6016ec6d130855ffd7ab836a27e32ae51ad2b5": "c8b50100446afc86b36f8d5062f3d20c",
".git/objects/3c/f9ba84f11bdfb59fbd36e20704db13ccd5c011": "3fe39563fa7e9f122097853292a98c0b",
".git/objects/75/ee4e44ca0dcf57e28d03b5459a3cb186c8fdae": "142c11ee5584d5f894afe57498855a0b",
".git/objects/d6/9c56691fbdb0b7efa65097c7cc1edac12a6d3e": "868ce37a3a78b0606713733248a2f579",
".git/objects/c0/0fd533ad8ea5ddcbef61dbfb30650e8b81cc36": "88eb8e1e9509b8f32047285710662d0a",
".git/objects/c0/6d8637e9774638f7713e84d761d0a2c075e8ab": "58a160b71edcc5cecef4da17f4d37a98",
".git/objects/7a/6c1911dddaea52e2dbffc15e45e428ec9a9915": "f1dee6885dc6f71f357a8e825bda0286",
".git/objects/7a/706fec01dbc6239a4375f4e80e79d206044d80": "33acb8ec93405b5e365acca625c29d2c",
".git/objects/ca/3bba02c77c467ef18cffe2d4c857e003ad6d5d": "316e3d817e75cf7b1fd9b0226c088a43",
".git/objects/b7/49bfef07473333cf1dd31e9eed89862a5d52aa": "36b4020dca303986cad10924774fb5dc",
".git/objects/0d/89272217e334e5738f856e939f6a4b8e78d07a": "e962bd0cb33a09aa4bb7c894c92db34d",
".git/objects/d4/3532a2348cc9c26053ddb5802f0e5d4b8abc05": "3dad9b209346b1723bb2cc68e7e42a44",
".git/objects/d4/041d8239ddb72e91919dc1bb0719106844ac94": "511768b61cc70aeed4ea7be0e488654b",
".git/objects/f0/0f28397fdc31428078887729651b56f2b4ac37": "14db9b5e0c43d76fad1a3d8c47825b19",
".git/objects/f0/13196a4cb6e250de463436896063b835566658": "154847084058811a017179d31cb2e836",
".git/objects/46/34e14ee7b6f4a47159db5a1e03e3afe5a54803": "7c10c259434138858c43feae4e14d036",
".git/objects/46/94cbe2620c6b5f3b97917912787c95fccf3c5c": "4b219d50339baab6e279166dcbb2cceb",
".git/objects/46/4ab5882a2234c39b1a4dbad5feba0954478155": "2e52a767dc04391de7b4d0beb32e7fc4",
".git/objects/09/1c158a894995c6fe2f12fa5c05da8d8d9955a2": "99d58465503aaee3a37db688152b51a8",
".git/objects/8a/aa46ac1ae21512746f852a42ba87e4165dfdd1": "1d8820d345e38b30de033aa4b5a23e7b",
".git/objects/8a/886483f393c3e1ffc79766f23426bad07440d6": "73ea6a43a2072fcdcceba33ac710def0",
".git/objects/62/862cd8d3495fc0bf5fa70aca51dbfe7b047c37": "ef89eaae3ab90b0974c6e9753e2e546a",
".git/objects/f9/b815473a27579747c16204e91290cfcc41dcaa": "290f3e63f222b551b9c248761ff8a701",
".git/objects/e9/94225c71c957162e2dcc06abe8295e482f93a2": "2eed33506ed70a5848a0b06f5b754f2c",
".git/objects/03/eaddffb9c0e55fb7b5f9b378d9134d8d75dd37": "87850ce0a3dd72f458581004b58ac0d6",
".git/objects/ed/b55d4deb8363b6afa65df71d1f9fd8c7787f22": "886ebb77561ff26a755e09883903891d",
".git/objects/98/0d49437042d93ffa850a60d02cef584a35a85c": "8e18e4c1b6c83800103ff097cc222444",
".git/objects/79/e6bf33d656049c2cd2244af1c9656d001eba0d": "3cc45908d55e488db59c772f3c52d432",
".git/objects/65/04c26460c5b7b003679938cda77459cea7a3e1": "219e77bb3a998f8653ffaf095bc69a40",
".git/objects/f5/72b90ef57ee79b82dd846c6871359a7cb10404": "e68f5265f0bb82d792ff536dcb99d803",
".git/objects/a7/c60a5460b8364ed277cde223336ce2dbc6115f": "e061d606fa1adf7905b6624047a54e97",
".git/objects/20/3a3ff5cc524ede7e585dff54454bd63a1b0f36": "4b23a88a964550066839c18c1b5c461e",
".git/objects/b6/b8806f5f9d33389d53c2868e6ea1aca7445229": "b14016efdbcda10804235f3a45562bbf",
".git/objects/51/6233364da7533eb47df35e5e0093891fe48b6d": "7ebbe3c5a6e630208f28037ec0add16b",
".git/objects/90/231026edc98c59bd547fef27379c4f72eec0cb": "a2cab5d74bd9f701bfc8484c12200f65",
".git/objects/2e/e2ba9bacb16b032f3c46718b0a42bac21fcd94": "5800c8577f97862d55ba3ca9e8f3d2f3",
".git/objects/9b/3ef5f169177a64f91eafe11e52b58c60db3df2": "91d370e4f73d42e0a622f3e44af9e7b1",
".git/objects/e2/872c1f109eb0bdeddb2b9a5888b78b6a3b19d1": "a8064c48f4e0e2d256b45ae33531c0f4",
".git/objects/88/cfd48dff1169879ba46840804b412fe02fefd6": "e42aaae6a4cbfbc9f6326f1fa9e3380c",
".git/objects/5f/c6cce97eb485a2c86638f3580171245a288878": "a3b7443697a8bdffa8f09240ca639c6c",
".git/objects/e3/e9ee754c75ae07cc3d19f9b8c1e656cc4946a1": "14066365125dcce5aec8eb1454f0d127",
".git/objects/6d/81e0e0dc73735c93a275d2e51427c66c18b7ee": "8f906e269a8cf8be4202096ac90541b4",
".git/objects/ae/63722b4f6de2473e160289ced09b5e08405b6c": "4b00da4c91aa4ec961ea06e57d8e479a",
".git/objects/93/4475707c9d0502095174fe57df5ff499a8d783": "402ae65acee52979d5f4ebff5409296c",
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
".git/COMMIT_EDITMSG": "6d620612ba963f136032775e1e05b38e",
".git/index": "e1bd6c0c8efd20ebf8c0832841eb390c",
".git/refs/heads/master": "bcf6491aed96fdb977e3e81ed0372761",
".git/refs/remotes/origin/gh-pages": "bcf6491aed96fdb977e3e81ed0372761",
"main.dart.js": "ad2a9636fb7aca7490507deb2f95f4fd"};
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

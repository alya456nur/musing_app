import 'package:cloud_firestore/cloud_firestore.dart';

void addSongs() async {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  CollectionReference songs = firestore.collection('SONGS');

  List<Map<String, dynamic>> songData = [
    {
      "Title": "Alan Walker - Faded",
      "Image": "https://firebasestorage.googleapis.com/v0/b/musing-7f04b.appspot.com/o/songImage%2FIMG_20240702_113523_798.jpg?alt=media&token=1689c5eb-0d4c-490d-9729-3416b84b14cc",
      "Song": "https://firebasestorage.googleapis.com/v0/b/musing-7f04b.appspot.com/o/Songs%2FAlan%20Walker%20-%20Faded.mp3?alt=media&token=209229b7-713f-45a9-8e46-c50df96b85e9",
      "Artist": "Alan Walker",
      "Genre": "Electronic",
      "Language": "English",
      "Number of views": 0,
      "Number of likes": 0
    },
    {
      "Title": "Alan Walker - The Spectre",
      "Image": "https://firebasestorage.googleapis.com/v0/b/musing-7f04b.appspot.com/o/songImage%2FIMG_20240702_113524_266.jpg?alt=media&token=c746932b-9e13-49a2-962b-271006345939",
      "Song": "https://firebasestorage.googleapis.com/v0/b/musing-7f04b.appspot.com/o/Songs%2FAlan%20Walker%20-%20The%20Spectre.mp3?alt=media&token=87708dba-121a-4d06-89e5-7b26716fda7b",
      "Artist": "Alan Walker",
      "Genre": "Electronic",
      "Language": "English",
      "Number of views": 0,
      "Number of likes": 0
    },
    {
      "Title": "Alan Walker, K-391 & Emelie Hollow - Lily",
      "Image": "https://firebasestorage.googleapis.com/v0/b/musing-7f04b.appspot.com/o/songImage%2FIMG_20240702_113523_572.jpg?alt=media&token=0252d22f-26fa-4d89-afd0-8efe53ff8f3e",
      "Song": "https://firebasestorage.googleapis.com/v0/b/musing-7f04b.appspot.com/o/Songs%2FAlan%20Walker%2C%20K-391%20%26%20Emelie%20Hollow%20-%20Lily%20(Lyrics).mp3?alt=media&token=61e64866-0c0c-4780-9000-87191d6c733f",
      "Artist": "Alan Walker, K-391 & Emelie Hollow",
      "Genre": "Electronic",
      "Language": "English",
      "Number of views": 0,
      "Number of likes": 0
    },
    {
      "Title": "Alan Walker, Sabrina Carpenter & Farruko  - On My Way",
      "Image": "https://firebasestorage.googleapis.com/v0/b/musing-7f04b.appspot.com/o/songImage%2FIMG_20240702_113523_501.jpg?alt=media&token=db4e3248-7a39-47af-8d35-3e24739a2c65",
      "Song": "https://firebasestorage.googleapis.com/v0/b/musing-7f04b.appspot.com/o/Songs%2FAlan%20Walker%2C%20Sabrina%20Carpenter%20%26%20Farruko%20%20-%20On%20My%20Way.mp3?alt=media&token=1fb15b03-008b-4373-ab3c-fa4e69cddb62",
      "Artist": "Alan Walker, Sabrina Carpenter & Farruko",
      "Genre": "Electropop",
      "Language": "English",
      "Number of views": 0,
      "Number of likes": 0
    },
    {
      "Title": "Ava Max - Kings & Queens",
      "Image": "https://firebasestorage.googleapis.com/v0/b/musing-7f04b.appspot.com/o/songImage%2FIMG_20240702_113523_989.jpg?alt=media&token=fd736ecc-48ce-48b6-af4e-32065bc6f4d0",
      "Song": "https://firebasestorage.googleapis.com/v0/b/musing-7f04b.appspot.com/o/Songs%2FAva%20Max%20-%20Kings%20%26%20Queens%20%5BOfficial%20Visualizer%5D.mp3?alt=media&token=62347c4d-c8e2-46cf-8b21-656b905db312",
      "Artist": "Ava Max",
      "Genre": "Pop",
      "Language": "English",
      "Number of views": 0,
      "Number of likes": 0
    },
    {
      "Title": "Ava Max - So Am I",
      "Image": "https://firebasestorage.googleapis.com/v0/b/musing-7f04b.appspot.com/o/songImage%2FIMG_20240702_113523_814.jpg?alt=media&token=e6a8e280-8b8f-4f50-8b51-c1385fc6c498",
      "Song": "https://firebasestorage.googleapis.com/v0/b/musing-7f04b.appspot.com/o/Songs%2FAva%20Max%20-%20So%20Am%20I%20%5BOfficial%20Music%20Video%5D.mp3?alt=media&token=3352bc1c-8226-4f22-aea1-e814f06a2847",
      "Artist": "Ava Max",
      "Genre": "Pop",
      "Language": "English",
      "Number of views": 0,
      "Number of likes": 0
    },
    {
      "Title": "Christina Perri - A Thousand Years",
      "Image": "https://firebasestorage.googleapis.com/v0/b/musing-7f04b.appspot.com/o/songImage%2FIMG_20240702_113524_001.jpg?alt=media&token=895e58f3-7435-4ae8-822f-52f26df5fe5f",
      "Song": "https://firebasestorage.googleapis.com/v0/b/musing-7f04b.appspot.com/o/Songs%2FChristina%20Perri%20-%20A%20Thousand%20Years%20%5BOfficial%20Music%20Video%5D.mp3?alt=media&token=deb802e3-457e-4a9d-b4ad-a0c8aa4112b1",
      "Artist": "Christina Perri",
      "Genre": "Pop",
      "Language": "English",
      "Number of views": 0,
      "Number of likes": 0
    },
    {
      "Title": "Dirgahayu - Dato' Siti Nurhaliza & Faizal Tahir (OST Lara Aishah)",
      "Image": "https://firebasestorage.googleapis.com/v0/b/musing-7f04b.appspot.com/o/songImage%2FIMG_20240702_113523_831.jpg?alt=media&token=bdd6e0bb-e9ce-4b05-a950-e3ebe8f96ee1",
      "Song": "https://firebasestorage.googleapis.com/v0/b/musing-7f04b.appspot.com/o/Songs%2FDirgahayu%20(Official%20Music%20Video)%20-%20Dato'%20Siti%20Nurhaliza%20%26%20Faizal%20Tahir%20(OST%20Lara%20Aishah).mp3?alt=media&token=17c13aa8-1683-4da7-abce-4c2f55df9ead",
      "Artist": "Dato' Siti Nurhaliza & Faizal Tahir",
      "Genre": "Pop",
      "Language": "Malay",
      "Number of views": 0,
      "Number of likes": 0
    },
    {
      "Title": "ES!! Yumemiru Architecture (夢見るアーキテクチャ) - Mika Kagehira [KANROMENG]",
      "Image": "https://firebasestorage.googleapis.com/v0/b/musing-7f04b.appspot.com/o/songImage%2FIMG_20240702_113523_750.jpg?alt=media&token=2191439d-20e7-4072-be1e-4a21a014c2a3",
      "Song": "https://firebasestorage.googleapis.com/v0/b/musing-7f04b.appspot.com/o/Songs%2FES!!%20Yumemiru%20Architecture%20(%E5%A4%A2%E8%A6%8B%E3%82%8B%E3%82%A2%E3%83%BC%E3%82%AD%E3%83%86%E3%82%AF%E3%83%81%E3%83%A3)%20-%20Mika%20Kagehira%20%5BKANROMENG%5D.mp3?alt=media&token=c577f64f-cef4-4094-b1be-8e987f3b4322",
      "Artist": "Mika Kagehira",
      "Genre": "Pop",
      "Language": "Japanese",
      "Number of views": 0,
      "Number of likes": 0
    },
    {
      "Title": "Ellie Goulding - Love Me Like You Do",
      "Image": "https://firebasestorage.googleapis.com/v0/b/musing-7f04b.appspot.com/o/songImage%2FIMG_20240702_113530_194.jpg?alt=media&token=47843f7c-f10f-4bab-ba46-b14e27af919b",
      "Song": "https://firebasestorage.googleapis.com/v0/b/musing-7f04b.appspot.com/o/Songs%2FEllie%20Goulding%20-%20Love%20Me%20Like%20You%20Do%20(Lyrics).mp3?alt=media&token=00206178-b7aa-4119-92ac-6c4d9297186c",
      "Artist": "Ellie Goulding",
      "Genre": "Electropop",
      "Language": "English",
      "Number of views": 0,
      "Number of likes": 0
    },
    {
      "Title": "Faizal Tahir - Assalamualaikum",
      "Image": "",
      "Song": "https://firebasestorage.googleapis.com/v0/b/musing-7f04b.appspot.com/o/Songs%2FFaizal%20Tahir%20-%20Assalamualaikum%20(Official%20Music%20Video).mp3?alt=media&token=1f1624c4-456e-4946-b0ff-6eba3efc833c",
      "Artist": "Faizal Tahir",
      "Genre": "pop",
      "Language": "Malay",
      "Number of views": 0,
      "Number of likes": 0
    },
    {
      "Title": "Faizal Tahir - Ragaman",
      "Image": "https://firebasestorage.googleapis.com/v0/b/musing-7f04b.appspot.com/o/songImage%2FIMG_20240702_113530_459.jpg?alt=media&token=22a7314b-947e-4946-80af-e8d4782f41b7",
      "Song": "https://firebasestorage.googleapis.com/v0/b/musing-7f04b.appspot.com/o/Songs%2FFaizal%20Tahir%20-%20Ragaman%20(Video%20Musik%20Rasmi)%20%20Dikuasakan%20oleh%20BIJAK%20TRIVIA.mp3?alt=media&token=1ba46643-25ab-4230-a6bd-1c30ce589e47",
      "Artist": "Faizal Tahir",
      "Genre": "Pop",
      "Language": "Malay",
      "Number of views": 0,
      "Number of likes": 0
    },
    {
      "Title": "GUMIKINGKanaria",
      "Image": "https://firebasestorage.googleapis.com/v0/b/musing-7f04b.appspot.com/o/songImage%2FIMG_20240702_113530_752.jpg?alt=media&token=e532743a-1b82-4709-a138-275f3cfbc91f",
      "Song": "https://firebasestorage.googleapis.com/v0/b/musing-7f04b.appspot.com/o/Songs%2FGUMIKINGKanaria.mp3?alt=media&token=2de81ba2-d9ac-423b-8eaa-b645092151c0",
      "Artist": "Kanaria",
      "Genre": "J-Pop",
      "Language": "Japanese",
      "Number of views": 0,
      "Number of likes": 0
    },
    {
      "Title": "Imagine Dragons - Believer",
      "Image": "gs://musing-7f04b.appspot.com/songImage/IMG_20240702_113529_869.jpg",
      "Song": "gs://musing-7f04b.appspot.com/Songs/Imagine Dragons - Believer (Lyrics).mp3",
      "Artist": "Imagine Dragons",
      "Genre": "Pop",
      "Language": "English",
      "Number of views": 0,
      "Number of likes": 0
    },
    {
      "Title": "MVRoyal ScandalREVOLVER  luz",
      "Image": "gs://musing-7f04b.appspot.com/songImage/IMG_20240702_113530_136.jpg",
      "Song": "gs://musing-7f04b.appspot.com/Songs/MVRoyal ScandalREVOLVER  luz.mp3",
      "Artist": "Luz",
      "Genre": "J-Pop",
      "Language": "Japanese",
      "Number of views": 0,
      "Number of likes": 0
    },
    {
      "Title": "MVダーリンブルー  luzすりぃ",
      "Image": "gs://musing-7f04b.appspot.com/songImage/IMG_20240702_113530_026.jpg",
      "Song": "gs://musing-7f04b.appspot.com/Songs/MVダーリンブルー  luzすりぃ.mp3",
      "Artist": "Luz",
      "Genre": "J-Pop",
      "Language": "Japanese",
      "Number of views": 0,
      "Number of likes": 0
    },
    {
      "Title": "Porter Robinson & Madeon - Shelter",
      "Image": "gs://musing-7f04b.appspot.com/songImage/IMG_20240702_113530_001.jpg",
      "Song": "gs://musing-7f04b.appspot.com/Songs/Shelter.mp3",
      "Artist": "Porter Robinson & Madeon",
      "Genre": "Pop",
      "Language": "English",
      "Number of views": 0,
      "Number of likes": 0
    },
    {
      "Title": "Readymade",
      "Image": "gs://musing-7f04b.appspot.com/songImage/IMG_20240702_113530_041.jpg",
      "Song": "gs://musing-7f04b.appspot.com/Songs/Readymade.mp3",
      "Artist": "Ado",
      "Genre": "J-Pop",
      "Language": "Japanese",
      "Number of views": 0,
      "Number of likes": 0
    },
    {
      "Title": "Rockabye (feat. Sean Paul & Anne-Marie)",
      "Image": "gs://musing-7f04b.appspot.com/songImage/IMG_20240702_113530_175.jpg",
      "Song": "gs://musing-7f04b.appspot.com/Songs/Rockabye (feat. Sean Paul & Anne-Marie).mp3",
      "Artist": "Clean Bandit",
      "Genre": "Pop",
      "Language": "English",
      "Number of views": 0,
      "Number of likes": 0
    },
    {
      "Title": "Taylor Swift - Look What You Made Me Do",
      "Image": "gs://musing-7f04b.appspot.com/songImage/artworks-LS5Lp2aubtdcyQm5-StKfXQ-t500x500.jpg",
      "Song": "gs://musing-7f04b.appspot.com/Songs/Taylor Swift - Look What You Made Me Do.mp3",
      "Artist": "Taylor Swift",
      "Genre": "Pop",
      "Language": "English",
      "Number of views": 0,
      "Number of likes": 0
    },
    {
      "Title": "Shinitai-chan (English Cover)【JubyPhonic】シニタイちゃん (feat. Master Andross)",
      "Image": "gs://musing-7f04b.appspot.com/songImage/maxresdefault.jpg",
      "Song": "gs://musing-7f04b.appspot.com/Songs/noname.mp3",
      "Artist": "JubyPhonic",
      "Genre": "Pop",
      "Language": "English",
      "Number of views": 0,
      "Number of likes": 0
    },
    {
      "Title": "キルマー歌ってみた宮下遊",
      "Image": "gs://musing-7f04b.appspot.com/songImage/IMG_20240702_113530_297.jpg",
      "Song": "gs://musing-7f04b.appspot.com/Songs/キルマー歌ってみた宮下遊.mp3",
      "Artist": "Kilmer",
      "Genre": "J-Pop",
      "Language": "Japanese",
      "Number of views": 0,
      "Number of likes": 0
    },
    {
      "Title": "ベルコメン  香椎モイミ feat. 鏡音レン",
      "Image": "gs://musing-7f04b.appspot.com/songImage/IMG_20240702_113534_934.jpg",
      "Song": "gs://musing-7f04b.appspot.com/Songs/ベルコメン  香椎モイミ feat. 鏡音レン.mp3",
      "Artist": "Kashii Moimi",
      "Genre": "J-Pop",
      "Language": "Japanese",
      "Number of views": 0,
      "Number of likes": 0
    },
    {
      "Title": "ラブカ? ver.luzCOVER",
      "Image": "gs://musing-7f04b.appspot.com/songImage/IMG_20240702_113535_445.jpg",
      "Song": "gs://musing-7f04b.appspot.com/Songs/ラブカ ver.luzCOVER.mp3",
      "Artist": "Luz",
      "Genre": "J-Pop",
      "Language": "Japanese",
      "Number of views": 0,
      "Number of likes": 0
    },
    {
      "Title": "ロウワー ver.luzCOVER",
      "Image": "gs://musing-7f04b.appspot.com/songImage/IMG_20240702_113535_234.jpg",
      "Song": "gs://musing-7f04b.appspot.com/Songs/ロウワー ver.luzCOVER.mp3",
      "Artist": "Luz",
      "Genre": "J-Pop",
      "Language": "Japanese",
      "Number of views": 0,
      "Number of likes": 0
    },
    {
      "Title": "學貓叫",
      "Image": "gs://musing-7f04b.appspot.com/songImage/IMG_20240702_113535_075.jpg",
      "Song": "gs://musing-7f04b.appspot.com/Songs/學貓叫.mp3",
      "Artist": "群星",
      "Genre": "C-Pop",
      "Language": "Chinese",
      "Number of views": 0,
      "Number of likes": 0
    },
    {
      "Title": "毒林檎とシンデレラ ver.luzCOVER",
      "Image": "gs://musing-7f04b.appspot.com/songImage/IMG_20240702_113535_213.jpg",
      "Song": "gs://musing-7f04b.appspot.com/Songs/毒林檎とシンデレラ ver.luzCOVER.mp3",
      "Artist": "Luz",
      "Genre": "J-Pop",
      "Language": "Japanese",
      "Number of views": 0,
      "Number of likes": 0
    },
    {
      "Title": "漆黒 - Shikkoku",
      "Image": "gs://musing-7f04b.appspot.com/songImage/IMG_20240702_113535_137.jpg",
      "Song": "gs://musing-7f04b.appspot.com/Songs/漆黒.mp3",
      "Artist": "Maiko Fujita",
      "Genre": "J-Pop",
      "Language": "Japanese",
      "Number of views": 0,
      "Number of likes": 0
    },
    {
      "Title": "神っぽいな ver.luzCOVER",
      "Image": "gs://musing-7f04b.appspot.com/songImage/IMG_20240702_113535_734.jpg",
      "Song": "gs://musing-7f04b.appspot.com/Songs/神っぽいな ver.luzCOVER.mp3",
      "Artist": "Luz",
      "Genre": "J-Pop",
      "Language": "Japanese",
      "Number of views": 0,
      "Number of likes": 0
    },
  ];

  for (var song in songData) {
    await songs.add(song);
  }
}
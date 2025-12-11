---
layout: post
title: "SSH Trafiğini Çözümleyelim 4 - Bellekte Anahtar Avı"
description: "SSH Trafiğini Çözümleyelim 4 - Bellekte Anahtar Avı"
date: 2025-12-04T07:00:00-07:00
tags: ssh nodejs openssl memory forensics aes
---


Bu yazı serisi şu ana kadar 4 bölümden oluşmaktadır, diğer bölümlere aşağıdaki linklerden ulaşılabilir. Yazı içeriğinde geçen kodlara
[bu linkten](https://github.com/caltuntas/ssh-decryption) ulaşabilirsiniz.

1. [SSH Trafiğini Çözümleyelim 1 - Patch](https://www.cihataltuntas.com/2025/02/04/decrypt-ssh-traffic-1)
   - Bu yazıda, genel olarak SSH protokolünün yapısı ve şifreleme için
     kullanılan anahtar değişim algoritmalarının nasıl çalıştığı inceliyoruz.
     Ardından var olan bir SSH kütüphanesinin kodu değiştirilerek ele geçirilen
     şifreleme anahtarlarını kendi yazdığımız kod ile kaydedilmiş bir trafiği
     çözümlemek için kullanıyoruz.
2. [SSH Trafiğini Çözümleyelim 2 - Wireshark](https://www.cihataltuntas.com/2025/04/10/decrypt-ssh-traffic-2) 
   - Bu yazıda, Wireshark kullanarak trafiği çözümlemek istediğimizde
     karşılaştığımız sorunu hata ayıklaması yaparak tespit ediyoruz, sonrasında
     da Wireshark kodunu düzelterek, trafiği Wireshark üzerinde de
     çözümlüyoruz.
3. [SSH Trafiğini Çözümleyelim 3 - Private Key](https://www.cihataltuntas.com/2025/11/22/decrypt-ssh-traffic-3) 
   - Bu yazıda, Private Key nedir, eğer ele geçirebilirsek trafiği başka
     herhangi bir değer kullanmadan çözümleyebilir miyiz diye inceleme yapıyoruz.
4. [SSH Trafiğini Çözümleyelim 4 - Bellekte Anahtar Avı](https://www.cihataltuntas.com/2025-12-04-decrypt-ssh-traffic-4) (Bu yazı)
   - Bu yazıda, diğer başlıklarda yapılanın aksine, kullandığımız kütüphanede
     herhangi bir değişiklik yapmadan, trafiği çözmemiz için gerekli
     anahtarları bellekten bulmaya çalışıyoruz.


Önceki yazılarda hatırlarsanız, SSH nasıl çalışır, trafik nasıl şifrelenir gibi konulara değindikten sonra trafiği çözmek için günün sonunda ya bütün gerekli 
şifreleme anahtarlarını kodun içinde değişiklik yaparak yazdırdık ya da özel anahtarı yine kodu değiştirerek elde edip sonrasında diğer anahtarları ondan türeterek
trafiği çözümledik. Bu zamana kadar yaptıklarımız bize biraz SSH protokolü, biraz şifreleme, anahtar değişimi gibi konular öğretti ama hep kaçak güreştiğimizi kabul etmem lazım.
Kodu değiştirerek şifreleri ekrana yazdırdıktan sonra trafiği çözmek kolay, peki bunu hiç kod değiştiremeden şifreleri birisinin bize söylemesini gerek duymadan yapabilir miyiz?
Bu yazıda işin zor kısmı için kolları sıvayıp daha önce incelediğimiz SSH kütüphanesi ile oluşturulmuş canlı olarak çalışan, bir oturumun şifreleme anahtarlarını bellekten kendimiz
bularak trafiği çözümlemeye çalışacağız. Bu tarz bellekten kanıt bulmak, veri çıkarmak [Memory Forensics](https://en.wikipedia.org/wiki/Memory_forensics) başlığı altında inceleniyor ve genellikle [Volatility](https://github.com/volatilityfoundation/volatility) gibi bu işe özel araçlarla daha kolay yapılabiliyor. 
Fakat ben bu konuyu daha derinlemesine öğrenmek için bu tarz bir araç kullanmadım ve yaparken hem zorlandım, hem çok fazla şey öğrendim hem de inanılmaz keyif aldım, umarım siz de aynı şekilde okurken keyif alırsınız, hadi başlayalım.

## Şifreleme Anahtarları Nerede? 

SSH ile bir uzak sunucuya bağlantı kurduğumuzda aslında arka planda bir program çalıştırmış oluyoruz ve gelen giden trafik o program tarafından çözümlenip bizim ekranımızda beliriyor.
Önceki yazılardan anlamış olduğumuz gibi, biz dışarıdan bakanlar olarak trafiği ele geçirsek de içeriğini anlayamıyoruz fakat o program kendi içeriğinde tuttuğu şifreleme anahtarları ile
trafiği çözümleyip biz kullanıcılara anlamlı bilgiler gösterebiliyor. Bu da bize, programın şifreleme anahtarlarını vermese de kendi içeriğinde bunları bir yerde tutup sürekli kullandığını
gösteriyor, aksi durumda kendisi de trafiği çözümleyemezdi zaten. Biz de bu varsayımı kullanıp program bu bilgileri bellekte ya da diskte nerede tutuyorsa oradan ele geçirip trafiği çözümlemeye çalışacağız.

Diskte tutmak çok anlamlı değil, hem kötü niyetli kişilerin disk üzerinden bu bilgileri ele geçirmesi çok kolay olur, hem de performans olarak sürekli şifrelenmiş veri alış verişi sırasında diske erişmek 
oldukça yavaş olacağı için geriye tek seçenek kalıyor `bellek`, yani çok büyük ihtimalle şifreleme anahtarları çalışan programın belleğinde tutuluyor, o zaman aramaya başlayalım.

Benim planım şu şekilde,

1. SSH bağlantısı yapan bir kod geliştir.
2. Bağlantı sırasında şifreleme anahtarlarını ekrana yazdır.
3. Bağlantıyı açık bırak.
4. Başka bir program ile SSH bağlantısı yapan programın belleğini oku.
5. Bellekte ekrana yazdırdığın şifreleme anahtarlarını ara.

Eğer bu adımlar sonrasında bellekte şifreleme anahtarlarını bulabilirsek, şifrelerin bellekte saklandığı tezini doğrulamış oluruz ve stratejimizi ona göre hazırlayıp ilerleyebiliriz.

## SSH Bağlantısı Yapalım

Önceki yazılarda bağlantıyı genelde kısa süreli bir `ls -lah` komutu çalıştırıp çıkacak şekilde hazırlamıştık fakat bu sefer bellek analizi yapabilmek için biraz daha uzun süreli açık kalması gerekiyor
bundan dolayı, klasik bir SSH client gibi bağlantı açan ve `ssh2`  kütüphanesini kullanan kodu [bu şekilde](https://github.com/caltuntas/ssh-decryption/blob/main/client.js) oluşturduk. Kodu buraya 
koymadım çünkü interaktif bir SSH oturumu açmaktan çok fazla bir esprisi yok, o yüzden linkten detaylarına bakabilirsiniz. Kodun bahsetmeye değecek en önemli kısmı bence aşağıdaki algoritmaları ayarladığımız bölüm

```
const algorithms = {
	cipher: [
	  'aes128-ctr',
	],
	hmac: [
	  'hmac-sha2-256',
	],
  };
```

Bu kısımda SSH bağlantısının belirli algoritmalar üzerinden yapılmasını istiyoruz, eğer bunu boş bırakırsak sunucu ve istemci farklı bir algoritma da seçebilir, bu da bizim
hem trafiği çözümleme kodunu hem de bellekte anahtarların bulunmasına kadar bütün her şeyi etkiler, bundan dolayı ilk yazıdan itibaren aynı şifreleme algoritması olan `aes128-ctr`'ı burada da kullanıyoruz.

Config ve secret değerlerini ekrana yazdırması için oluşturduğumuz `patch` uygulanmış kodu aşağıdaki gibi çalıştırdım.

```
> node client.js testuser@192.168.1.110 "testpassword"                                                                                                                                                            
...
...
Private Key :  302e020100300506032b656e0422042018f89dc8d1969faf7f5591d3231540028bccda47cc0e7530dcbb2e2e6fc3c263
Handshake: (local) computeSecret: 5ae3bfdd0ab389a97eb087630b036795becb7f32f45df07ad4c27bf37ca3d603
Verifying signature ...
Verified signature
SECRET: 000000205ae3bfdd0ab389a97eb087630b036795becb7f32f45df07ad4c27bf37ca3d603
------config------
{"inbound":{"seqno":3,"decipherInfo":{"sslName":"aes-128-ctr","blockLen":16,"keyLen":16,"ivLen":16,"authLen":0,"discardLen":0,"stream":true},"decipherIV":{"type":"Buffer","data":[216,202,100,22,211,215,90,170,215,60,6,39,220,103,111,241]},"decipherKey":{"type":"Buffer","data":[197,172,134,44,188,88,40,30,146,89,151,190,72,6,126,232]},"macInfo":{"sslName":"sha256","len":32,"actualLen":32,"isETM":false},"macKey":{"type":"Buffer","data":[251,97,80,55,31,137,183,180,54,47,130,116,17,131,185,164,78,42,12,151,216,115,62,150,142,50,47,237,253,108,181,34]}},"outbound":{"seqno":3,"cipherInfo":{"sslName":"aes-128-ctr","blockLen":16,"keyLen":16,"ivLen":16,"authLen":0,"discardLen":0,"stream":true},"cipherIV":{"type":"Buffer","data":[111,178,55,78,44,50,149,116,178,91,157,229,20,114,204,101]},"cipherKey":{"type":"Buffer","data":[68,8,24,54,141,197,22,166,120,166,61,98,77,47,146,26]},"macInfo":{"sslName":"sha256","len":32,"actualLen":32,"isETM":false},"macKey":{"type":"Buffer","data":[135,125,115,155,89,79,230,20,65,111,65,113,114,189,147,91,118,43,79,219,247,173,62,87,99,123,187,149,29,50,154,196]}}}
Handshake completed
...
...
```

Yukarıdaki gibi oturum başlatan ve açık bırakan kodu çalıştırdık ve ekranda doğrulama için kullanacağımız **Private Key, SECRET, config** gibi değerleri görebildik.

## Bellekte Ne Arıyoruz?

Öncelikle yukarıdaki çıktıdan gördük ki, bellekte arayabileceğimiz Private Key, SECRET ve config bir kaç farklı değer bulunuyor. Bir önceki yazımızda `Private Key` değerini 
alarak trafiği çözdüğümüz için en mantıklı onu aramak gibi düşünebiliriz fakat maalesef onu arasak da bulamayacağız, sebebi SSH bağlantısını yapan [kütüphanenin](https://github.com/mscdex/ssh2/blob/844f1edfc41589737671f96a4f4e76afdf46abd4/lib/protocol/kex.js#L983) aşağıdaki kod satırlarında gizli

```
...
// Cleanup/reset various state
this._public = null;
this._dh = null;
this._kexinit = this._protocol._kexinit = undefined;
this._remoteKexinit = undefined;
this._identRaw = undefined;
this._remoteIdentRaw = undefined;
this._hostKey = undefined;
this._dhData = undefined;
this._sig = undefined;
...
```

SSH kütüphanesi, `config` nesnesini ve içinde bulunan gerekli tüm şifreleme anahtarlarını oluşturduktan sonra, yukarıdaki işlemi yaparak, `this._dh = null;` ile Diffie-Hellman algoritmasını
oluşturan nesneyi ve dolaylı olarak içinde tutulan değerleri yani `Private, Public Key` değerlerini temizlemiş oluyor. Nodejs garbage collector çalıştığında ilgili değerleri bellekten temizlendiği
için bu işlemi Private Key üzerinden yapmamız mümkün değil. Teoride eğer GC çalışmadan programın belleğine erişip değeri okursanız bu mümkün ama saniyeler ile yarışmanız gerekiyor, bu hem 
gereksiz bir çaba olacak ve hem de iyi ve garanti bir yöntem olduğundan bunu bahsettiğim sebeplerden dolayı eliyoruz.

Zaten biraz düşünürsek hangi değerleri bellekten aramanın daha mantıklı olduğunu hemen bulabiliriz,  önceki yazılarda incelediğimizde SSH protokolünün `KEX` anahtar değişim sürecinin tek amacı
oturum boyunca kullanacağı şifreleme anahtarlarının üretilmesi, Private Key, Shared Secret aslında bunları üretmek için kullandığımız ara değerler ama KEX sürecinin sonunda oluşturduğumuz nihai 
çıktılar aslında `config` içinde bulunan `Client->Server` ya da `Server->Client` haberleşmede kullanılan şifreleme anahtarları(AES, MAC, IV). Bunları bellekten silme şansı da yok çünkü yeni bir anahtar değişim 
süreci başlayana kadar trafiği programın kendisinin de çözümlemesi için aynı anahtarları kullanmak zorunda.

Ne aradığımıza karar verdiğimize göre ekrana yazılan `config` nesnesinin içeriğini hex değerlere dönüştürerek aşağıya koyalım ve arama işlemimiz daha kolay hale gelsin.
Bu nesne `json` formatında ve anahtarlar `Buffer` olarak tutulduğu ve integer olarak ekrana yazıldığı için önce ekrana yazılan config satırını `config.json` dosyasına kaydettim. Ardından `jq` ile hex değerlere aşağıdaki gibi çevirdim.

```
> pbpaste > config.json
> cat config.json | jq -r '
    "dec:\(.inbound.decipherKey.data | join(","))",
    "enc:\(.outbound.cipherKey.data | join(","))",
    "decIv:\(.inbound.decipherIV.data | join(","))",
    "encIv:\(.outbound.cipherIV.data | join(","))"
  ' | while IFS=":" read -r key val; do
    echo "Key: $key, Value: $val"
    for num in ${(s:,:)val}; do
      printf "%02x" $num
    done
    echo
  done
  
  
Key: dec, Value: 197,172,134,44,188,88,40,30,146,89,151,190,72,6,126,232
c5ac862cbc58281e925997be48067ee8
Key: enc, Value: 68,8,24,54,141,197,22,166,120,166,61,98,77,47,146,26
440818368dc516a678a63d624d2f921a
Key: decIv, Value: 216,202,100,22,211,215,90,170,215,60,6,39,220,103,111,241
d8ca6416d3d75aaad73c0627dc676ff1
Key: encIv, Value: 111,178,55,78,44,50,149,116,178,91,157,229,20,114,204,101
6fb2374e2c329574b25b9de51472cc65
```

Aramamız gereken değerler, AES encryption, decryption ve bunlar için kullanılan `IV` değerlerini yukarıda hex olarak gördük, 
bunları daha sonra ekrana yazdırmadan kendimiz bulacağız fakat tezimizi kanıtlayana kadar böyle kalsın. Trafiği çözümlemek için bu değerlerin
hepsini bulmamız gerekecek ama ben bir tanesini seçip tezimi doğrulamaya çalışacağım, şifreleme anahtarı olan `440818368dc516a678a63d624d2f921a` değerini bulmaya çalışacağım.


## Nerede Arıyoruz? 

Yukarıda ne arayacağımıza karar verdik peki bunu nerede arayacağız biraz onun üzerinde düşünelim. Başta ne demiştik SSH bağlantısını kuran da aslında diğer programlar gibi bir `process`. 
Onun belleğine erişebilirsek aradığımız değeri orada bulmaya çalışabiliriz, peki belleğe nasıl erişebiliriz? 

Linux tabanlı işletim sistemlerinde ek bir yazılım geliştirmeye ihtiyaç duymadan programın belleğine [procfs yöntemi](https://en.wikipedia.org/wiki/Procfs) ile ulaşabiliriz.
Yukarıda `node client.js ...` ile SSH bağlantısını oluşturmuştuk, procfs aracılığı ile belleğe biraz göz atalım tabi öncesinde `pid` değerini bulmamız gerekiyor.

```
> pgrep node
32162
```

Pid değerini aldıktan sonra procfs ile bellek bölgelerine göz atalım

```
> cat /proc/32162/maps

...
...
55903c57b000-55903c57f000 r-xp 00001000 fe:01 4886091                    /usr/bin/node
55903c57f000-55903c580000 r--p 00005000 fe:01 4886091                    /usr/bin/node
55903c580000-55903c581000 r--p 00005000 fe:01 4886091                    /usr/bin/node
55903c581000-55903c582000 rw-p 00006000 fe:01 4886091                    /usr/bin/node
55904cd5d000-55904d000000 rw-p 00000000 00:00 0                          [heap]
7f56a8000000-7f5728000000 ---p 00000000 00:00 0
7f5728000000-7f5729000000 rw-p 00000000 00:00 0
...
...
```

Liste oldukça uzun kısaltarak yukarıya ekledim, burada Linux işletim sisteminde nasıl tutulduğuna değinmeyeceğim, ama özetle 
bellekte programın kullandığı kütüphaneler, programın kendisi, çalışan kod hepsi belleğin çeşitli bölgelerinde tutuluyor ve bu liste onu gösteriyor diyebiliriz.

Burada biraz temel programlama bilgisi kullanarak bir tahmin yapacağım, şifreleme anahtarları çalışma zamanı yani `runtime` sırasında oluşturulan değerler olduğu için,
bunların belleğin `heap` bölgesinde olmasını bekliyorum. Eğer bunlar `compile-time` sırasında belirlenen hard-coded sabit değerler olsaydı bunları farklı bir yerde aramam gerekirdi.

```
> cat /proc/32162/maps | grep  'heap'
55904cd5d000-55904d000000 rw-p 00000000 00:00 0                          [heap]
```

Yukarıda belleğin heap bölgesinin başlangıç ve bitiş adreslerini bulduk, yani değerleri arayacağımız yer belirlendi, şimdi aramaya başlayalım.

## Şifreleme Anahtarlarını Arayalım

Arama işlemini yapmak için, aslında daha modern araçlar olsa da, önce GDB gibi bir araç kullanmadan bunu el ile yapmayı denemek istiyorum.

Belleğin heap bölgesinde arama yapacağımızı söylemiştik, bu bölgenin başlangıç ve bitiş adresleri de elimizde, o yüzden belleğin bu bölgesini meşhur `dd` [disk destroyer](https://en.wikipedia.org/wiki/Dd_(Unix)) komutu ile `heap.dump` adında bir
dosyaya kaydetmek istiyorum.

```
> sudo dd if=/proc/32162/mem bs=4096 skip=$((0x55904cd5d000/ 4096)) count=$(((0x55904d000000-0x55904cd5d000)/4096)) > mem.dump
  xxd -p heap.dump | tr -d '\n' | grep -ci '440818368dc516a678a63d624d2f921a'
  1
```

Dd komutunda belki açıklamaya değer `/proc/32162/mem` kısmı olabilir, `/proc/32162/maps` ile programın belleğin hangi bölgelerini kullandığını yani bir nevi haritasını aldık, gerçek anlamda
belleği okuma işlemini ise `/proc/pid/mem` ile yapıyoruz. Diğer dd detayı ise `heap` başlangıç adresine kadar olan kısmı `skip` ile atlıyoruz, sonrasında ise o bölgenin boyutu kadar `count` ile okuma işlemi
gerçekleştiriyoruz.

Kaydettikten sonra `xxd` ile hex formatına çevirip sonrasında grep ile arama yaptık arama sonucunda `1` bulunan sayı olarak ekranda gözüktü, yani bellekte aradığımız anahtar değerini bulduk ve tezimizi doğruladık.

## IV Değerlerini Arayalım

Önceki yazılardan hatırlarsanız eğer, trafiği çözerken sadece şifreleme anahtarı değil ayrıca IV yani [initialization vector](https://en.wikipedia.org/wiki/Initialization_vector) değerini de kullanmamız gerekiyordu. 
Bu kullanılan şifreleme algoritması modunun(Aes Ctr) gerektirdiği bir durum, o yüzden bellekte IV değerlerini de bulmamız gerekiyor. Daha önce yaptığımız işlemin benzerini ekrana
yazdırdığımız IV değeri için de yapıyorum ve bellekte daha önce kaydettiğim `heap` dosyasında o değeri aşağıdaki gibi arıyorum.

```
> xxd -p heap.dump | tr -d '\n' | grep -ci '6fb2374e2c329574b25b9de51472cc65'
0
```

Maalesef aradığımız değeri bulamadık, peki neden? Bu kısım beni en çok uğraştıran ve hatta sonrasında olayı iyice anlamak için sıfırdan Aes-Ctr şifreleme algoritması geliştirmeme yol açan kısım.
Çok detaya şimdilik girmeden, IV değerinin son 2 karakterini silip tekrar aynı bellek dump dosyasında arama yaptım

```
> xxd -p heap.dump | tr -d '\n' | grep -ci '6fb2374e2c329574b25b9de51472cc'
1
```

Evet sonuç bu sefer pozitif, tam aradığımız IV değeri olmasa da son 2 değeri haricinde aynı IV değerini bellekte bulabildik. Bunun detaylı sebebine yani neden ilk ekranda yazan IV değerini bulamadığımız konusuna daha sonra değineceğiz.

## Eğlenceli Kısım

Buraya kadar tezimizi doğruladık, trafiği çözmemiz için gerekli materyal bellekte bulunuyor diye düşündük, bunları da doğrulamak için ekrana yazdırarak bellekte aradık ve değerleri bulabildik. 
Şimdi işin eğlenceli kısmına geldi, bu değerleri ekrana yazdırmadan bellekten nasıl bulabiliriz? Yani içeride bir Aes key var ise onun değerini bilmeden bellekten bulup çıkarmak istiyoruz. 

Bunu yapabilmek için, tabi Aes algoritması nasıl çalışıyor bilmemiz lazım, en iyi öğrenme yöntemi hep dediğim gibi kolları sıvayıp kendimizin geliştirmesi ki, ben de böyle yaptım ve temel Aes şifreleme algoritması ve yaygın kullanılan
modlarının bazılarını kendim geliştirdim, [buradan](https://github.com/caltuntas/aes) kaynak koduna erişebilirsiniz.

### AES Temelleri

Aes şifreleme algoritmasının detaylarını
[buradan](https://en.wikipedia.org/wiki/Advanced_Encryption_Standard) öğrenebilirsiniz ama ben yine de bizim işimizle ilgili olan kısmını şöyle açıklamaya çalışayım.
Aes şifreleme algoritması 128 bit bloklar üzerinde işlem yapıyor, bu şu anlama
geliyor. Örneğin şifreleme için verdiğiniz uzun bir metin var, Bunu 128 bitlik
bloklara ayırıyor ve ardından, her blok şifreleme anahtar uzunluğuna göre (128,192,256)
ilgili bloğu 10,12 ya da 14 defa şifreleme işleminden geçiriyor. 

Bu blok şifreleme işlemini yaparken de, güvenlik açısından her turda ana şifreleme anahtarından türemiş farklı bir anahtar kullanıyor ve bunlar `round key` olarak adlandırıyor.
Genelde Aes şifreleme yapan kütüphaneler performans nedeniyle bu `round key` hesaplama işini her blok için ayrı ayrı yapmaktansa bir defa hesaplayıp bellekte saklıyor, çünkü diğer bloklar için de
aynı tur anahtarlarını kullanacak ve bunu tekrar hesaplamaya çalışırsa büyük boyutlu bir metni şifrelemek oldukça fazla CPU kaynağı tüketecek ve performansı kötü etkileyecek.

### Bellekte Round Key Arıyoruz

Geliştirdiğim AES algoritmasına hesaplanan round key değerlerini ekrana yazdırması için bir özellik ekledim. Amacım bellekte bu tarz tur anahtarlarını da bulup bulamayacağımızı test etmek, çünkü ekrana yazdırmadan
AES anahtarı bulma stratejim tamamen buna bağlı. Yeni bir SSH oturumu açtım sonrasında ekrana yazılan AES anahtarlarından birisi olan `242ab0824289a9084e85f1c7727e2b02` alıp kendi yazdığım AES algoritmasına parametre olarak aşağıdaki gibi verdim.

```
aes > ./aes 242ab0824289a9084e85f1c7727e2b02
round[0] key=242ab0824289a9084e85f1c7727e2b02
round[1] key=d6dbc7c294526ecadad79f0da8a9b40f
round[2] key=0756b1009304dfca49d340c7e17af4c8
round[3] key=d9e959f84aed8632033ec6f5e244323d
round[4] key=caca7e608027f85283193ea7615d0c9a
round[5] key=9634c68f16133edd950a007af4570ce0
round[6] key=edca2730fbd919ed6ed319979a841577
round[7] key=f293d288094acb656799d2f2fd1dc785
round[8] key=d65545dcdf1f8eb9b8865c4b459b9bce
round[9] key=d941ceb2065e400bbed81c40fb43878e
round[10] key=f556d7bdf30897b64dd08bf6b6930c78
```

Daha önce yaptığımız gibi belleğin heap bölgesini dosyaya kaydettim ve ana anahtar ve bu tur anahtarlarını tek tek arıyorum.

```
> xxd -p mem.dump | tr -d '\n' | grep -ci '242ab0824289a9084e85f1c7727e2b02'
1
> xxd -p mem.dump | tr -d '\n' | grep -ci 'd6dbc7c294526ecadad79f0da8a9b40f'
1
> xxd -p mem.dump | tr -d '\n' | grep -ci '0756b1009304dfca49d340c7e17af4c8'
1
> xxd -p mem.dump | tr -d '\n' | grep -ci 'd9e959f84aed8632033ec6f5e244323d'
1
...
```

Tahmin ettiğimiz gibi, `round key`  değerleri bir defa hesaplanıp bellekte heap bölgesinde saklanıyor, bu bilgi bizim için oldukça önemli çünkü bunu
kullanarak bellekten nasıl AES anahtarı çıkarabiliriz bunun algoritmasını çıkaracağız.

### Algoritmayı Oluşturalım

Algoritmayı oluşturmadan önce, round key değerlerinin bellekte hangi adreste tutulduğunu doğrulamak istedim bunun için, GDB ile ilgili programa bağlanıp round-key değerlerini
belirli formata çevirdikten sonra [GDB Enhanced Features](https://github.com/hugsy/gef) eklentisinin sağladığı `grep` komutu ile arama yapıp, bellekte nerede tutulduklarına bakıyorum.

```
> gdp -p 32162
...
...
gef➤  grep '\\x24\\x2a\\xb0\\x82\\x42\\x89\\xa9\\x08\\x4e\\x85\\xf1\\xc7\\x72\\x7e\\x2b'
[+] Searching '\x24\x2a\xb0\x82\x42\x89\xa9\x08\x4e\x85\xf1\xc7\x72\x7e\x2b' in memory
[+] In '[heap]'(0x55d61a621000-0x55d61a8bb000), permission=rw-
  0x55d61a703c60 - 0x55d61a703c9c  →   "\x24\x2a\xb0\x82\x42\x89\xa9\x08\x4e\x85\xf1\xc7\x72\x7e\x2b[...]"
gef➤  grep '\\xd6\\xdb\\xc7\\xc2\\x94\\x52\\x6e\\xca\\xda\\xd7\\x9f\\x0d\\xa8\\xa9\\xb4\\x0f'
[+] Searching '\xd6\xdb\xc7\xc2\x94\x52\x6e\xca\xda\xd7\x9f\x0d\xa8\xa9\xb4\x0f' in memory
[+] In '[heap]'(0x55d61a621000-0x55d61a8bb000), permission=rw-
  0x55d61a703c70 - 0x55d61a703cb0  →   "\xd6\xdb\xc7\xc2\x94\x52\x6e\xca\xda\xd7\x9f\x0d\xa8\xa9\xb4\x0f[...]"
gef➤  grep '\\x07\\x56\\xb1\\x00\\x93\\x04\\xdf\\xca\\x49\\xd3\\x40\\xc7\\xe1\\x7a\\xf4\\xc8'
[+] Searching '\x07\x56\xb1\x00\x93\x04\xdf\xca\x49\xd3\x40\xc7\xe1\x7a\xf4\xc8' in memory
[+] In '[heap]'(0x55d61a621000-0x55d61a8bb000), permission=rw-
  0x55d61a703c80 - 0x55d61a703cc0  →   "\x07\x56\xb1\x00\x93\x04\xdf\xca\x49\xd3\x40\xc7\xe1\x7a\xf4\xc8[...]"
```

Yukarıdaki çıktıdan zaten daha önce tespit ettiğimiz şeyi görüyoruz fakat ek olarak bellekte hangi adreste tutuldukları da elimizde var, baştan sonra tutuldukları adresler aşağıdaki gibi

```
0x55d61a703c60 - 0x55d61a703c9c  →   "242ab0824289a9084e85f1c7727e2b (şifreleme anahtarı)"
0x55d61a703c70 - 0x55d61a703cb0  →   "d6dbc7c294526ecadad79f0da8a9b40f (round key 1)"
0x55d61a703c80 - 0x55d61a703cc0  →   "0756b1009304dfca49d340c7e17af4c8 (round key 2)"
...
```

Bu da bize şifreleme anahtarı ve ondan türeyen round-key değerlerinin bellekte art arda tutulduğunu gösteriyor, bunu adreslerin başlangıç değerlerinden son bölümlerinden(..60,..70,..80) anlayabiliyoruz.
Bu bilgiyi kullanarak şöyle bir algoritma oluşturabiliriz.

1. Belleğin ilk adresini başlangıç olarak al
2. 128 bit(16 byte) oku (şifreleme ve round-key boyutu)
3. Aldığın bu değeri AES anahtarı gibi düşün ve round-key değerini hesapla
4. Bir sonraki 128 bit(16 byte) değeri oku
5. Hesapladığın round-key değeri ile karşılaştır, yanlış ile bellekten ilk seçtiğin adresi 1 byte, arttır ve yeni aday anahtar ile başa dön.
6. Eğer karşılaştırdığın değer aynı ise, bir sonraki round-key hesabını yap ve onu da sonraki 128 bitlik değer ile karşılaştır
7. Bu işlemi 10 defa yapıp her defasında hesapladığın round-key ile bellekte bulunan 128 bitlik değer aynı ise, tebrikler şifreleme anahtarını buldun.

Temel algoritma genellikle [sliding window](https://www.geeksforgeeks.org/dsa/window-sliding-technique/) olarak adlandırılıyor, tabi bizim burada yapacağımız, round-key hesaplaması doğrulaması gibi
farklılıklar içeriyor. Algoritma şöyle çalışacak diyebiliriz.

```
Bellek:
[00|10|25|A1|7C|99|FF|3B|8D|C4|65|77|23|88|09|AE|01|02|03|04|05|EE|F5|...]

Window Size = 16 bytes
-------------------------------------------------------

Aday Anahtar: 0 [00|10|25|A1|7C|99|FF|3B|8D|C4|65|77|23|88|09|AE]
Aday Anahtar: 1    [10|25|A1|7C|99|FF|3B|8D|C4|65|77|23|88|09|AE|01]
Aday Anahtar: 2       [25|A1|7C|99|FF|3B|8D|C4|65|77|23|88|09|AE|01|02]
Aday Anahtar: 3          [A1|7C|99|FF|3B|8D|C4|65|77|23|88|09|AE|01|02|03]
```

Her aday anahtar seçimi sonrası yukarıda bahsettiğim, o anahtar için round-key hesaplanıp sonraki 16 byte ile karşılaştıracak doğru olması durumunda ise, aynı karşılaştırma 
10 defa yapılacak, hepsi doğru ise bu aday anahtarı artık gerçek anahtar olarak değerlendireceğiz, değil ise yeni bir aday anahtarı yukarıdaki gibi seçip devam edecek.

Yazı oldukça uzadı ama en azından algoritmayı oluşturabildik. Bir sonraki bölümde algoritmayı koda dönüştürüp, trafiği çözümlemede önümüze çıkacak diğer konularla devam edelim.

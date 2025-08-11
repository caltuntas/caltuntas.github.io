---
layout: post
title: "SSH Trafiğini Çözümleyelim 1 - Patch"
description: "SSH Trafiğini Çözümleyelim 1 -  Patch"
date: 2025-02-04T07:00:00-07:00
tags: ssh
---

Bu yazı serisi şu ana kadar 2 bölümden oluşmaktadır, diğer bölümlere aşağıdaki linklerden ulaşılabilir. Yazı içeriğinde geçen kodlara
[bu linkten](https://github.com/caltuntas/ssh-decryption) ulaşabilirsiniz.

1. [SSH Trafiğini Çözümleyelim 1 - Patch](https://www.cihataltuntas.com/2025/02/04/decrypt-ssh-traffic-1) (Bu yazı)
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
 
Yine garip ama sürekli yapılacaklar listemde üst sıralarda yer alan bir konu ile birlikteyiz. 
SSH benim günlük hayatımda belki de benim en fazla kullandığım protokollerden birisi, diğeri de sanırım 
internet erişimi için sıklıkla kullandığım TLS olsa gerek.

Tabi bir de yaptığımız iş gereği uzak sunuculara, sistemlere, network cihazlarına SSH protokolü ile erişim yaptığımızdan,
bir problem olduğunda cihaz ile aramızda veri alışverişini açık olarak görebilmek oldukça hayati olabiliyor. Bu yüzden 
SSH trafiğini incelerken, onu çözümlemek için ne tarz bir yol izledim, neler yaptım hem kendime not olsun, hem de başkaları da
yararlanabilir diye burada toparlamak gibi bir planım var. 


## Şifrelenmiş Veri Trafiği

SSH bağlantısı yaptığımızda oluşan trafiği dinleyip ardından kullanıcı, şifre gibi bilgilerin yanında ne almış ne vermiş gibi bilgileri açık şekilde görebilsek güzel olurdu değil mi? 
Sorun çözme açısından büyük kolaylık olacağı kesin ama veri güvenliği anlamında felaket olacağı kesin.  
Bu yüzden SSH ile uzak bir sisteme bağlandığınız sırada Wireshark ile trafiği dinlerseniz aşağıdaki gibi bir resimle karşılaşacaksınız.

![Capture 1](/img/sshdecrypt/wireshark-ssh-1.png)

Yeşil kısımlara dikkat edin, kritik olan her türlü veri trafiği yeşil ile işaretlenen yerlerde meydana geliyor, öncesinde bu şifrelenmiş kanalık oluşturmak için
istemci ve sunucu arasında bazı verilerin iletilmesi gerekiyor.

## Forward Secrecy

Sizi kriptografi dünyasının altın çocuğu, [Forward Secrecy](https://en.wikipedia.org/wiki/Forward_secrecy)(İleri Gizlilik) ile tanıştırayım. Eskiden bana 
sihir gibi gelen bir kavram olduğunu itiraf etmem gerekiyor. Yukarıdaki örnek üzerinden gidersek,
birbirini hiç tanımayan, istemci ve sunucu arasında yapılan trafiğin tüm detaylarını dinleyen biri olarak nasıl oluyor da,
daha sonradan bu trafik kaydını çözümleyemiyorum, gönderilen ve alınan verileri göremiyorum, çok ilginç değil mi? 

Sadece bununla da kalmayıp, sunucu ve istemci üzerinde bulunan **Private Key** anahtarlarını ele geçirseniz bile bu trafiği çözemeyeceğinizi söylesem 
herhalde daha da şaşırırsınız. En azından ben baya şaşırmıştım çünkü, sunucuda bulunan bir şekilde, şifre, özel anahtar gibi bir veriyi alırsam,
bütün trafiği rahatça görebilirim sanıyordum, ta ki bunu deneyip göremediğimi anlayıncaya kadar. Test etmesi çok basit, bilgisayarınızda 2 adet Linux sanal sunucu ayağa kaldırıp,
**SSH** kurulumu yapıp tüm trafiği **Wireshark** ya da benzeri bir araç ile dinleyin sonra da sunucularda bulunan özel anahtarları kullanarak kaydettiğiniz bu trafiği çözmeye çalışın,
olmadığını göreceksiniz. 

Forward Secrecy kavram olarak nedir, detayları nelerdir yukarıdaki linkten kolayca öğrenebilirsiniz çok detayına girmeyeceğim ama en temel olarak,
önüne geçmeye çalıştığı şey özetle şöyle diyebiliriz. Örnek sizin tüm SSH veri trafiğinizi dinleyen kötü niyetli olan bir kullanıcı olduğunu düşünün, bu kullanıcı bugün elinde yok ama,
yarın sizin sunucunuzun üzerinde bulunan Private Key değerini, dosyasını ele geçirirse geçmişte dinlediği tüm haberleşmenizi çözebilecek ayrıca gelecekte de yapılacak trafiği dinlerse, isterse gerçek zamanlı çözüp,
kritik verilerinizi ele geçirebilecektir. 

İşte Forward secrecy bunu engelliyor, geçmişte ve gelecekte bulunan tüm veri trafiği farklı anahtarlar ile şifrelenerek yapıldığı için
bir oturumla alakalı bir anahtar ele geçirilse bile sadece o oturumlar çözümlenebilir, diğer oturumlarda nasıl bir veri trafiği olmuş görülemez.

## Sihirli Kelimemiz: Diffie–Hellman

Bana çok sihirli gelen bu güvenlik mekanizması SSH ve daha birçok protokolün güvenliğinde kullanılan ve aslında çok basit olan bir matematiğe dayanan [Diffie-Hellman](https://en.wikipedia.org/wiki/Diffie%E2%80%93Hellman_key_exchange) algoritması ile
sağlanıyor. Detayları ile ilgili, yüzlerce hatta binlerde yazı, kitap, video bulabilirsiniz ama kendim kalemi kağıdı elime alıp yaptığım hesaplamayı buraya da koymak istiyorum, ileride unutursam kolayca hatırlarım.

![Capture 2](/img/sshdecrypt/dh-formula.jpeg)

Normalde bu kadar küçük numaralar kullanılmıyor tabi gerçek dünyada, fakat daha küçük numaralar kullansak da formül aynı ve değişmiyor. Amacımız istemci ve sunucu olarak ortak bir paylaşılan şifreleme anahtarına 
güvenilir olmayan ve her gönderdiğimiz verinin izlenebildiği bir ortamda ulaşabilmek. Kriptografide genelde **Alice,Bob, Eve** kullanılsa da ben bizim senaryomuzda kullandığımız sunucu ve istemci olarak formülün bileşenlerini açıklayacağım.

| Parametre | Açıklama                                                        |
|-----------|-----------------------------------------------------------------|
| p         | büyük bir asal sayı, prime, herkese açık                        |
| g         | p değerine göre göre asal kök, generator, herkese açık          |
| a         | istemcinin seçtiği gizli bir sayı, client private key           |
| b         | sunucunun seçtiği gizli bir sayı, server private key            |
| A         | istemcinin hesapladığı herkese açık bir sayı, client public key |
| B         | sunucunun hesapladığı herkese açık bir sayı, server public key  |
| S         | şifreleme anahtarı, secret key                                  |

Şimdi yukarıdaki formüle göre özetlersek, öncelikle Diffie-Hellman algoritmasına göre, istemci ve sunucu tarafından bilinen `p` ve `q` değerleri kullanılıyor.
Ardından algoritmanın kurallarına göre, hem sunucu hem de istemci, gizli birer sayı seçiyor, ardından kağıt üzerimde yaptığım gibi aslında matematiğin sihri ile aynı şifreleme anahtarına ulaşabiliyorlar.
Arada trafiği dinleyen biri olsa bile şifreleme anahtarını bulması mümkün değil, çünkü gizli anahtarlar dışında diğer tüm veri açık olsa da, onu oluşturan çarpanların bulunması çok zor bir matematik problemi olduğundan
trafiği dinleyen birisi bu matematik formülünü kısa sürede çözmeyeceği için güvenli bir şekilde haberleşebiliyoruz.

Bu değerlerin seçimi tabi belirli kriterlere bağlı, benim yukarıda yaptığım gibi yaparsanız, şifreleme anahtarınızın kırılması çok büyük olasılık. Bu yüzden gerçek dünyada p ve q değerleri nasıl seçiliyor diye 
[RFC-3526](https://datatracker.ietf.org/doc/html/rfc3526) dokümanına göz atabilirsiniz. Mesela dokümanda belirtilen standartlara göre kullanılması gereken bazı gerçek `p` ve `q` değerleri aşağıdaki gibi gözüküyor.

```
   The prime is: 2^1536 - 2^1472 - 1 + 2^64 * { [2^1406 pi] + 741804 }

   Its hexadecimal value is:

      FFFFFFFF FFFFFFFF C90FDAA2 2168C234 C4C6628B 80DC1CD1
      29024E08 8A67CC74 020BBEA6 3B139B22 514A0879 8E3404DD
      EF9519B3 CD3A431B 302B0A6D F25F1437 4FE1356D 6D51C245
      E485B576 625E7EC6 F44C42E9 A637ED6B 0BFF5CB6 F406B7ED
      EE386BFB 5A899FA5 AE9F2411 7C4B1FE6 49286651 ECE45B3D
      C2007CB8 A163BF05 98DA4836 1C55D39A 69163FA8 FD24CF5F
      83655D23 DCA3AD96 1C62F356 208552BB 9ED52907 7096966D
      670C354E 4ABC9804 F1746C08 CA237327 FFFFFFFF FFFFFFFF

   The generator is: 2.
```

Diffie-Hellman algoritmasının detayları ile ilgili daha sonra yazı yazma planım var, oldukça basit fakat dikkat edilmesi gereken önemli noktalar var, önce kendim bir deneme geliştirmesi yapıp ardından detayları ileride yazmayı planlıyorum.
Şimdilik genel hatlarıyla ne işe yaradığını ve nasıl ortak bir şifreleme anahtarına ulaştığını bilmek yeterli.

## SSH Anahtar Değişimi Simülasyonu

Diffie-Hellman algoritması modern programlama  dillerinin neredeyse hepsinde, ya standart kütüphanenin bir parçası olarak ya da ayrı bir bağımlılık olarak mevcut. Ama yine de çok basit bir örnek ile
nasıl sunucu ve istemci aynı şifreleme anahtarına sahip oluyor kod üzerinden görüp uygulamak istedim. NodeJs seçmemin özel bir sebebi var, daha sonra bahsedeceğim.

```
const crypto = require('crypto');

const prime = Buffer.from([179]);
const generator = Buffer.from([2]);

console.log('prime=' + prime.toString('hex'));
console.log('generator=' + generator.toString('hex'));

const clientDH = crypto.createDiffieHellman(prime, generator);
clientDH.generateKeys();
const clientPub = clientDH.getPublicKey();
console.log('client getPublicKey=' + clientPub.toString('hex'));
const clientPrv = clientDH.getPrivateKey();
console.log('client getPrivateKey=' + clientPrv.toString('hex'));

const serverDH = crypto.createDiffieHellman(prime, generator);
serverDH.generateKeys();
const serverPub = serverDH.getPublicKey();
console.log('server getPublicKey=' + serverPub.toString('hex'));
const serverPrv = serverDH.getPrivateKey();
console.log('server getPrivateKey=' + serverPrv.toString('hex'));

const serverSecret = serverDH.computeSecret(clientPub);
console.log('server Shared Secret=' + serverSecret.toString('hex'));
const clientSecret = clientDH.computeSecret(serverPub);
console.log('client Shared Secret=' + clientSecret.toString('hex'));
```

Çalıştırdığınızda aşağıdaki gibi ortak şifreleme anahtarına ve bunu oluştururken seçilen özel ve genel anahtarları da çıktıda görebilirsiniz.

```
ssh-kex-simulation > node dh.js
prime=b3
generator=02
client getPublicKey=93
client getPrivateKey=5e
server getPublicKey=1d
server getPrivateKey=76
server Shared Secret=4c
client Shared Secret=4c
```

## Şifreleme Anahtarını Bulalım

Buraya kadar olan kısmında biraz işin teorisinden, biraz da basit bir pratiği üzerinden nasıl çalıştığını anlattım, bundan sonra tabi gerçek anlamda bir SSH trafiğini
dinleyip çözümlemek kaldı. Bunun için daha önce kullandığım, bir NodeJs ile yazılmış [SSH2](https://github.com/mscdex/ssh2/) kütüphanesi vardı onu kullanmak istedim. 
Yukarıda bahsettiğim gibi, o anda kullanılan özel anahtar ya da, şifreleme anahtarını bilmiyorsanız sonradan çözümleme şansınız yok, benim de amacım zaten dışarıdan bunu ele geçirip trafiği çözümlemek değil.

Amacım, benim kontrolümde olan bir sunucu ve istemci üzerinde tamamen protokol mesajlarının detaylarını görebilmek, bu yüzden ilk planım daha önce kullandığım bu kütüphanede ufak bir değişiklik ile acaba bunu yapabilir miyim idi.
Hatta bu yüzden proje için bir talepte de bulundum, ama maalesef reddedildi. Talep detaylarını da [buradan](https://github.com/mscdex/ssh2/issues/1319) görebilirsiniz, aradan neredeyse 2 yıl geçmiş.
Proje sahibi kısaca bana `mevcut debug özelliği, çoğu durum için yeterli, eklemeyi düşünmüyorum` diye cevap verdi. Aslında orada ben zaten kodu açıp inceledim hatta bazı değişiklikler yapmıştım en azından bana yön gösterir diye soru da sormuştum ama ne özellik olarak
eklendi ne de arkadaş bir yön gösterdi. 

Tabi açık kaynak projelerinde böyle durumlar için şikayet etmiyoruz, peki ne
yapıyoruz? Kodu açıp inceleyip, öğrenip kendimiz geliştirebiliyoruz, kısacası
kolları sıvayıp kendim yapmaya karar verdim, belki PR atıp projeye dahil de
ettirebilirim kabul edilirse ileride.

Kodu incelemeye başlayalım ama , binlerce satır olan koda balıklama dalıp incelemenin çok faydalı olmuyor bunu daha önce yapmıştım zaten ve kendim işin içinden çıkamadığım için github üzerinden o talebi oluşturmuştum. Bu sefer daha 
düzenli bir yol izlemeye karar verdim. Öncelikle ne kadar sıkıcı gelse de, bu şifreleme detaylarının anlatıldığı [SSH Transport Layer](https://datatracker.ietf.org/doc/html/rfc4253) RFC dokümanını incelemekle başladım.

Olay sadece Diffie-Hellman ile bitse çok basit olurdu, onu oluştururken SSH protokolü özelinde bir çok farklı yöntem kullanılıyor o yüzden protokol detaylarını bilmeden ne kodu anlamak ne de değiştirmek mümkün olmadı. Protokolü anladıktan sonra
*Kex* yani key exchange ile ilgili, kodu incelemeye başladım ve [kex.js](https://github.com/mscdex/ssh2/blob/master/lib/protocol/kex.js) içinde ki aşağıdaki satırlar dikkatimi çekti.

```
...
const pubKey = this.convertPublicKey(this._dhData);
let secret = this.computeSecret(this._dhData);
...
```

Yukarıda `computeSecret` ilk örnekten hatırladıysanız dikkatinizi çekmiş olması lazım. İlk örneği NodeJs ile yapmamın sebebi buydu, DH algoritmasının nasıl kullanıldığını anlarsam, bu kütüphane içinde de kolayca bulabilirim diye düşünmüştüm
öyle de oldu. Bu satırlardan sonra kod içerisinde yukarıda görüldüğü gibi `computeSecret` ile bir anahtar oluşturuyor, sonra yine aynı dosyasının içinde protokol kurallarına göre, gelen ve giden trafiği şifrelemek ve imzalamak için, kullanacağı tüm bilgileri aşağıdaki 
nesne içinde topluyor.

```
...
const config = {
  inbound: {
    onPayload: this._protocol._onPayload,
    seqno: this._protocol._decipher.inSeqno,
    decipherInfo: (!isServer ? scCipherInfo : csCipherInfo),
    decipherIV: (!isServer ? scIV : csIV),
    decipherKey: (!isServer ? scKey : csKey),
    macInfo: (!isServer ? scMacInfo : csMacInfo),
    macKey: (!isServer ? scMacKey : csMacKey),
  },
  outbound: {
    onWrite: this._protocol._onWrite,
    seqno: this._protocol._cipher.outSeqno,
    cipherInfo: (isServer ? scCipherInfo : csCipherInfo),
    cipherIV: (isServer ? scIV : csIV),
    cipherKey: (isServer ? scKey : csKey),
    macInfo: (isServer ? scMacInfo : csMacInfo),
    macKey: (isServer ? scMacKey : csMacKey),
  },
};
//trafiği çözümlemek için gerekli tüm bilgileri debug loga yaz
if (this._protocol._debug) {
  this._protocol._debug('------config------');
  this._protocol._debug(JSON.stringify(config));
}
...
```

## Trafik Oluşturup Şifreleme Anahtarlarını Alalım

Trafik analizi için kullanacağımız kütüphanede gerekli kod değişikliklerini yaptık, çalıştırdığımızda bize gerekli anahtarları terminale artık yazarak yardım edecek. Bunun için
ilgili kütüphaneyi kullanarak kendi sunucuma istek atacak basit bir kod hazırladım.

```
const { Client } = require('ssh2');

const algorithms = {
	kex: [
	  'diffie-hellman-group1-sha1',
	],
	cipher: [
	  'aes128-ctr',
	],
	hmac: [
	  'hmac-sha2-256',
	],
};

const options = {};
options.algorithms = algorithms;

const conn = new Client(options);
conn.on('ready', () => {
	conn.exec('cd /tmp && ls -lah', { pty: false }, (err, stream) => {
		if (err) throw err;
		stream.on('close', function close(code, signal) {
			console.log('Stream :: close :: code: ' + code + ', signal: ' + signal);
			conn.end();
		});
		stream.on('data', function out(data) {
			console.log('STDOUT: ' + data);
		});
		stream.stderr.on('data', function err(data) {
			console.log('STDERR: ' + data);
		});
	})})
	.connect({
		host: process.env.HOST,
		port: 22,
		algorithms: algorithms,
		username: process.env.USERNAME,
		password: process.env.PASSWORD,
		debug: function(msg) {
			console.log(msg);
		},
	});
```

Kod sunucuya bağlanıp, `ls -lah` komutunu çalıştırıp çıktıyı ekrana yazıyor. Ayrıca özellikle sadece belirli `cipher,kex,hmac` algoritmalarını kullandım çünkü çözümleme yapan kodun içinde de kullanılan algoritmaya göre ilgili
fonksiyonların kullanılması gerekiyor basit olması açısından bunu yapmak istemedim. 

Tabi bunu yapmadan önce, koda benim hazırladığım değişikliğin eklenmesi gerekiyor, çünkü orijinal 
kütüphanede şifreleme anahtarlarını dışarıya yazan bir kod yok, bu yüzden bir `patch` hazırladım. Kütüphaneyi yükler yüklemez ilgili patch dosyasını çalıştırıp benim eklediğim şekilde
değiştirilmesini sağlıyorum ve bunun sonunda çalıştırdığımızda aşağıdaki gibi ilgili `SECRET` ve `config` değerlerini ekrana yazıyor.

```
...
Verifying signature ...
Verified signature
SECRET: 000000805ad9c4f50808a252e02c365ea449f93ff366eb1bdda64bdb13b0ed76d50bbe41f6938c0d5ad5884aff95b044a050482185f9c3d558401692fbfc5c9a2f9d8b365f5c5c40e35414583691186b1be4209b82248728f6c2e8c2dc3a73912c2f4035e1f22cf4fb1ead1073171a00618189c942a366fd28f527aee2dff5df5dfb589c
------config------
{
  "inbound": {
    "seqno": 3,
    "decipherInfo": {
      "sslName": "aes-128-ctr",
      "blockLen": 16,
      "keyLen": 16,
      "ivLen": 16,
      "authLen": 0,
      "discardLen": 0,
      "stream": true
    },
    "decipherIV": {
      "type": "Buffer",
      "data": [ 206, 209, 71, 129, 132, 66, 204, 207, 226, 37, 237, 200, 165, 57, 231, 228 ]
    },
    "decipherKey": {
      "type": "Buffer",
      "data": [ 243, 53, 4, 88, 139, 25, 99, 60, 37, 75, 240, 159, 212, 107, 164, 118 ]
    },
    "macInfo": {
      "sslName": "sha256",
      "len": 32,
      "actualLen": 32,
      "isETM": false
    },
    "macKey": {
      "type": "Buffer",
      "data": [ 203, 150, 77, 9, 107, 154, 231, 26, 126, 19, 3, 222, 161, 99, 125, 253, 22, 210, 50, 106, 63, 79, 142, 221, 101, 53, 138, 100, 238, 114, 176, 12 ]
    }
  },
  "outbound": {
    "seqno": 3,
    "cipherInfo": {
      "sslName": "aes-128-ctr",
      "blockLen": 16,
      "keyLen": 16,
      "ivLen": 16,
      "authLen": 0,
      "discardLen": 0,
      "stream": true
    },
    "cipherIV": {
      "type": "Buffer",
      "data": [ 9, 35, 172, 131, 83, 213, 205, 242, 226, 152, 211, 64, 73, 212, 142, 61 ]
    },
    "cipherKey": {
      "type": "Buffer",
      "data": [ 5, 144, 50, 120, 95, 72, 29, 21, 147, 38, 252, 15, 41, 56, 36, 143 ]
    },
    "macInfo": {
      "sslName": "sha256",
      "len": 32,
      "actualLen": 32,
      "isETM": false
    },
    "macKey": {
      "type": "Buffer",
      "data": [ 182, 228, 123, 29, 79, 154, 189, 118, 250, 109, 74, 80, 214, 252, 254, 9, 29, 116, 139, 167, 156, 250, 236, 107, 95, 102, 35, 30, 12, 178, 48, 235 ]
    }
  }
}
Handshake completed
...
```

## Tüm Malzemeler Hazır, SSH Trafiğini Çözümleyelim

Yukarıdaki kodu çalıştırdıktan sonra artık ilgili şifreleme anahtarlarını içeren çıktıyı config.json olarak kaydedip, artık gerçekten trafiği çözümleme işlemine geçebiliriz.
Bunu yaparken trafiği `tcpdump` gibi bir araçlar dinleyip `pcap` formatında kaydetmek gerekecek. Bu tarz detaylara çok değinmiyorum, kaynak kodların linki içerisinde zaten görebilirsiniz.

```
const pcap = require("pcap");
const crypto = require("crypto");
const config = require("./config.json");

const pcapFile = "./ssh.pcap";
const MESSAGE = {
...
...
};

const pcapSession = pcap.createOfflineSession(pcapFile, "tcp");

const ivCS = Buffer.from(config.outbound.cipherIV);
const keyCS = Buffer.from(config.outbound.cipherKey);
const ivSC = Buffer.from(config.inbound.decipherIV);
const keySC = Buffer.from(config.inbound.decipherKey);
const decipherCS = crypto.createDecipheriv("aes-128-ctr", keyCS, ivCS);
const decipherSC = crypto.createDecipheriv("aes-128-ctr", keySC, ivSC);
let newKeysSent = false;
let packet_number =0;
let clientAddress;
let serverAddress;
pcapSession.on("packet", (rawPacket) => {
  const packet = pcap.decode.packet(rawPacket);
  if (packet.payload.ethertype!==2048)
    return;
  console.log(packet.link_type);
  console.log('packet:', JSON.stringify(packet));
  if (packet_number == 0) {
    clientAddress = packet.payload.payload.saddr.toString();
    serverAddress = packet.payload.payload.daddr.toString();
  }
  packet_number++;
  const tcp = packet.payload.payload.payload;
  const direction = packet.payload.payload.saddr.toString() === clientAddress ? 'CS':'SC';

  if (tcp && tcp.data && (tcp.sport === 22 || tcp.dport === 22)) {
    const sshData = tcp.data ? tcp.data.toString("utf-8") : "";
    if (sshData.startsWith("SSH-")) {
      console.log("SSH Protocol Version Exchange:");
      console.log(sshData.trim());
    } else if (tcp.data) {
      let packet_len, padding_len, msg_code;
      if (newKeysSent === false) {
        packet_len = tcp.data.subarray(0, 4).readInt32BE(0);
        padding_len = tcp.data[4];
        msg_code = tcp.data[5];
      } else {
        let decryptedPacket;
        let encryptedPacket = tcp.data.subarray(0,tcp.data.length-32);
        let mac = tcp.data.subarray(tcp.data.length-32);
        if(direction === 'CS') {
            decryptedPacket = decipherCS.update(encryptedPacket);
        } else if (direction === 'SC') {
            decryptedPacket = decipherSC.update(encryptedPacket);
        }
        console.log(`Entire Packet, ${direction} :`, tcp.data.toString("hex"));
        console.log(`Encrypted SSH Packet, ${direction} :`, encryptedPacket.toString("hex"));
        console.log(`MAC, ${direction} :`,mac.toString('hex'));
        packet_len = decryptedPacket.subarray(0, 4).readInt32BE(0);
        padding_len = decryptedPacket[4];
        const payload_len = packet_len - padding_len -1;
        const payload = decryptedPacket.subarray(5,payload_len+5).toString('hex');
        msg_code = decryptedPacket[5];
        const msg_name = Object.keys(MESSAGE).find(key => MESSAGE[key] === msg_code);
        console.log("Decrypted Packet :", decryptedPacket.toString("hex"));
        console.log(`packet length=${packet_len}`);
        console.log(`message code=${msg_name}`);
        if (msg_code === MESSAGE.USERAUTH_REQUEST) {
          //https://datatracker.ietf.org/doc/html/rfc4252#section-8
          const username_len_start = 6;
          const username_len_end = username_len_start + 4;
          const username_len = decryptedPacket.subarray(username_len_start,username_len_end).readInt32BE();
          const username_start = username_len_end;
          const username_end = username_start + username_len + 1;
          const username = decryptedPacket.subarray(username_start,username_end).toString();
          const service_name_len_start = username_end-1;
          const service_name_len_end = username_end + 4;
          const service_name_len = decryptedPacket.subarray(service_name_len_start, service_name_len_end).readInt32BE();
          const service_name_start = service_name_len_end -1;
          const service_name_end = service_name_start + service_name_len -1;
          const service_name = decryptedPacket.subarray(service_name_start, service_name_end + 1).toString();
          const method_len_start = service_name_end + 1;
          const method_len_end = method_len_start + 4;
          const method_len = decryptedPacket.subarray(method_len_start, method_len_end).readInt32BE();
          const method_start = method_len_end ;
          const method_end = method_start + method_len;
          const method = decryptedPacket.subarray(method_start, method_end).toString();
          if (method === "password") {
            const pass_len_start = method_end + 1;
            const pass_len_end = pass_len_start + 4;
            const pass_len = decryptedPacket.subarray(pass_len_start, pass_len_end).readInt32BE();
            const pass_start = pass_len_end;
            const pass_end = pass_start + pass_len;
            const pass = decryptedPacket.subarray(pass_start, pass_end).toString();
            console.log('Username : ' + username);
            console.log('Password : ' + pass);
          }
        }
      }
      if (msg_code == 21) {
        newKeysSent = true;
      }
    }
  }
});

pcapSession.on("error", (err) => {
  console.error("Error:", err.message);
});

pcapSession.on("complete", () => {
  console.log("Finished reading pcap file.");
});
```

Yukarıdaki kodda önemli olan ufak tefek noktalara değinelim. Pcap dosyasını okurken, paketin sunucudan cevap olarak mı gelen paket yoksa istemcinin gönderdiği paket mi olduğunu anlamak gerekiyor, sonrasında ilgili şifreleme anahtarının kullanılması gerekiyor.
Bunun için ilk bağlantı istemci tarafından oluşturulduğundan onun IP adresini bir yere kaydedip sonra bu şekilde ayrım yaptım.

Diğer nokta ise, SSH trafiği protokol özellikleri sebebiyle random veri ile, padding işlemi yapılıyor ve pakete bunlar ekleniyor. RFC içinde bunları detayları var ama özetle header yapısı aşağıdaki gibi, kod içinde de benzer mantıkla
başlığı parçalara ayırıp ilgili SSH mesajlarını yakalamaya çalışıyoruz.

```
+----------------+----------------+---------------------+----------------+----------------+
| Packet Length  | Padding Length |       Payload       |    Padding     |      MAC       |
|    (4 bytes)   |    (1 byte)    |     (Variable)      |                |   (Optional)   |
+----------------+----------------+---------------------+----------------+----------------+
```

Ardından mesaj tipini de `payload` içinden çıkarıyoruz, çünkü payload alanı da aşağıdaki gibi bir yapıya sahip.

```
+----------------+-------------------------+----------------------+
| Message Type   |   Message-Specific Data |   Optional Fields    |
|   (1 byte)     |    (Variable Length)    |  (Variable Length)   |
+----------------+-------------------------+----------------------+
```

Özellikle şifreyi göstermek için USERAUTH_REQUEST SSH mesajını decode ettim, tek tek alanları anlatmak yazıda hem uzun hem de gereksiz olacak ama yukarıdaki gözüken `Message` tipine göre içinde farklı mesajların farklı formatları olabiliyor.
Kodun bu kısmını daha detaylı anlamak için [RFC-4252 Password Authentication](https://datatracker.ietf.org/doc/html/rfc4252#section-8) kısmına bakabilirsiniz.

## Test

Kodun genel mantığını anlattıktan sonra artık tek yapmamız gereken çalıştırmak, bunu yaptığımızda da parametre olarak verilen bir sunucuya bağlantı oluşturuyor, ardından bu bağlantının trafiğini `tcpdump` ile kaydediyor,
en sonunda da trafiği daha önce aldığımız şifreleme anahtarları ile çözüp sonrasında SSH protokol mesajlarına ayırdıktan sonra istediğimizi elde ediyoruz.

```
docker build -t sshdecrypt .
docker run --rm -e USERNAME=testuser -e PASSWORD="abcdef" -e HOST=172.16.33.4  sshdecrypt
```

Çalıştırmak için, kaynak kodu kendi ortamınıza klonlayıp yukarıdaki gibi önce Docker imajı oluşturup ardından çalıştırabilirsiniz.


```
...
Entire Packet, CS : 56db68cff63b2a16c0633b64df7f02fcf33480dd7926606b91900bf9ad1aefb0e59be292eed73e1e241bbb1b39ebb04b457e6f90a7b6c7e2c8966271fb94457906f0a8ffc5a4f50c586f0ae161aab81817f33d9703c07aaf4b10b4b3022fc2a5
Encrypted SSH Packet, CS : 56db68cff63b2a16c0633b64df7f02fcf33480dd7926606b91900bf9ad1aefb0e59be292eed73e1e241bbb1b39ebb04b457e6f90a7b6c7e2c8966271fb944579
MAC, CS : 06f0a8ffc5a4f50c586f0ae161aab81817f33d9703c07aaf4b10b4b3022fc2a5
Decrypted Packet : 0000003c05320000000874657374757365720000000e7373682d636f6e6e656374696f6e0000000870617373776f72640000000006616263646566e1a25d6490
packet length=60
message code=USERAUTH_REQUEST
Username : testuser
Password : abcdef
...
```

Diğer tüm mesaj kodlarını çözümlüyoruz, ama özellikle ilginç olabilecek kullanıcı adı ve şifre gönderilen paketi çözüp değerlerini görmek istedim ve gerçekten görebildim, kısacası mutlu sona ulaştık diyebilirim.
Kod için herhangi bir düzenleme yapmadım önceliğim çalışması ve aradığım veriyi çözümlemesiydi, vakit bulunca üzerinden geçip iyileştirme yapabilirim. 

## Sonuç

Tabi buraya kadar amacıma ulaştım diyebilirim ama ilk çıkış noktam aslında `decryption` ve `decoding` kodunu aslında kendim yazmak yerine bunu `Wireshark` üzerinden görmekti. Henüz ona ulaşamadık, bir sonraki yazıda,
bu tarz kod ile çözümleme yapmak yerine bunu Wireshark üzerinden nasıl halledebiliriz ona değinelim. 

Ayrıca, kütüphane kodunu değiştirip şifreleme anahtarlarını almak biraz hile yapmak gibi gelse de ilk aşamada bence iyi bir adımdı, ama en son aşamada, bunu hiç kod değiştirmeden, yani biraz **Memory forensics** ile yapabilir miyim ona bakmaya çalışacağım.
Yani daha derinlere dalacağız gibi sıkı durun.

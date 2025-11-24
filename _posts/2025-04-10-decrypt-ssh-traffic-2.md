---
layout: post
title: "SSH Trafiğini Çözümleyelim 2 - Wireshark"
description: "SSH Trafiğini Çözümleyelim 2 - Wireshark"
date: 2025-04-10T07:00:00-07:00
tags: ssh,nodejs,wireshark
---

Bu yazı serisi şu ana kadar 2 bölümden oluşmaktadır, diğer bölümlere aşağıdaki linklerden ulaşılabilir. Yazı içeriğinde geçen kodlara
[bu linkten](https://github.com/caltuntas/ssh-decryption) ulaşabilirsiniz.

1. [SSH Trafiğini Çözümleyelim 1 - Patch](https://www.cihataltuntas.com/2025/02/04/decrypt-ssh-traffic-1)
   - Bu yazıda, genel olarak SSH protokolünün yapısı ve şifreleme için
     kullanılan anahtar değişim algoritmalarının nasıl çalıştığı inceliyoruz.
     Ardından var olan bir SSH kütüphanesinin kodu değiştirilerek ele geçirilen
     şifreleme anahtarlarını kendi yazdığımız kod ile kaydedilmiş bir trafiği
     çözümlemek için kullanıyoruz.
2. [SSH Trafiğini Çözümleyelim 2 - Wireshark](https://www.cihataltuntas.com/2025/04/10/decrypt-ssh-traffic-2) (Bu yazı)
   - Bu yazıda, Wireshark kullanarak trafiği çözümlemek istediğimizde
     karşılaştığımız sorunu hata ayıklaması yaparak tespit ediyoruz, sonrasında
     da Wireshark kodunu düzelterek, trafiği Wireshark üzerinde de
     çözümlüyoruz.
 

SSH trafiğini çözümleme yolculuğumuzda, [bir önceki](https://www.cihataltuntas.com/2025/02/04/decrypt-ssh-traffic-1.html) yazımızda
ilk olarak `Wireshark` ile trafiği çözümlemeye çalışmış fakat başarılı olamamış ardından kendi geliştirdiğimiz NodeJs
kodu ile trafiği çözümleyip gönderilen kullanıcı ve şifre bilgilerini alabilmiştik. Tabi bunu yaparken biraz kaçak güreşip,
pratikte elimizde gizli ya da paylaşılan anahtar bilgileri olmadan trafiği çözümleme mümkün olmadığından, kullandığımız SSH kütüphanesi üzerinde bazı değişiklikler yapıp
gizli, paylaşılan anahtar ve diğer tüm gerekli bilgileri ekrana yazdırmış ardından da geliştirdiğimiz kod içinde bunları kullanarak trafiği çözümleyip aradığımız bilgileri yakalamıştık.
 
 
Her seferinde bu tarz kod ile trafiği çözümlemek çok pratik olmadığından bu yazıda, Wireshark ile neden bilgileri göremedik ya da görmek için neler yapmamız lazım onu inceleyelim.

Öncelikle bir önceki yazıdan SSH trafiğini yakalayıp Wireshark ile açtığımızda nasıl görünüyor onu hatırlayalım.

![Capture 1](/img/sshdecrypt/wireshark-ssh-enc.png)

Resimde görüldüğü üzere, ilk SSH protokol el sıkışması için kullanılan ilk 4-5 paket dışında diğer tüm paketler `encrypted` olarak işaretlenmiş içlerini açtığınızda da anlamlı bir veri görmek mümkün değil.
Zaten şifrelenmiş bir trafik olduğundan bunun Wireshark tarafından otomatik olarak çözülmesini de beklemiyoruz, mutlaka ona gizli ya da paylaşılan anahtar değerini bir şekilde vermemiz gerekiyor ki trafiği çözümleyebilsin.

Wireshark SSH [dökümanına](https://wiki.wireshark.org/SSH) baktığımızda aşağıdaki gibi ifade karşımıza çıkıyor.

> The SSH dissector in Wireshark is functional, dissecting most of the
connection setup packets which are not encrypted.  Unlike the TLS dissector, no
code has been written to decrypt encrypted SSH packets/payload (yet). This is
also not possible unless the shared secret (from the Diffie-Hellman key
exchange) is extracted from the SSH server or client (see, as an example of a
mechanism to extract internal information of that sort, the "SSLKEYLOGFILE"
method in TLS). Work on SSH2 decryption is tracked at
https://bugs.wireshark.org/bugzilla/show_bug.cgi?id=16054

Döküman pek açıklayıcı diyemem, ama biraz ipucu vermiş, tahmin ettiğimiz gibi paylaşılan anahtarı TLS çözümleme benzeri bir yöntem ile 
verirseniz çözülebilir diye ifade etmiş. Daha önce TLS çözümleme için Wireshark kullandığımdan oradaki yöntemin nasıl çalıştığını biliyordum, benzer şekilde
SSH protokol ayarlarına girince aşağıdaki gibi bahsettiği anahtarı verebileceğimiz bir alan görebiliyoruz.

![Capture 1](/img/sshdecrypt/wireshark-ssh-pref.png)

Güzel, en azından anahtarı nasıl verebiliriz bunu bulduk, fakat bu dosyaya girebileceğimiz verinin formatı hala bilinmiyor, bunun için maalesef bir doküman bulamadığımdan en güzel doküman yani kaynak koda başvurmak zorunda kaldım.

Kaynak kod içinde SSH paketinden sorumlu olan [bu koda](https://gitlab.com/wireshark/wireshark/-/blob/master/epan/dissectors/packet-ssh.c) bakıp biraz incelediğimizde,
`keylog` dosyası ile ilgilenen fonksiyonu `ssh_keylog_read_file` görebiliyoruz. Bu fonksiyonun içinde geliştiren arkadaş sağolsun yorum satırı olarak ne beklendiğini aşağıdaki gibi belirtmiş.

```
 /* File format: each line follows the format "<cookie> <type> <key>".
  * <cookie> is the hex-encoded (client or server) 16 bytes cookie
  * (32 characters) found in the SSH_MSG_KEXINIT of the endpoint whose
  * private random is disclosed.
  * <type> is either SHARED_SECRET or PRIVATE_KEY depending on the
  * type of key provided. PRIVAT_KEY is only supported for DH,
  * DH group exchange, and ECDH (including Curve25519) key exchanges.
  * <key> is the private random number that is used to generate the DH
  * negotiation (length depends on algorithm). In RFC4253 it is called
  * x for the client and y for the server.
  * For openssh and DH group exchange, it can be retrieved using
  * DH_get0_key(kex->dh, NULL, &server_random)
  * for groupN in file kexdh.c function kex_dh_compute_key
  * for custom group in file kexgexs.c function input_kex_dh_gex_init
  * For openssh and curve25519, it can be found in function kex_c25519_enc
  * in variable server_key. One may also provide the shared secret
  * directly if <type> is set to SHARED_SECRET.
  *
  * Example:
  *  90d886612f9c35903db5bb30d11f23c2 PRIVATE_KEY DEF830C22F6C927E31972FFB20B46C96D0A5F2D5E7BE5A3A8804D6BFC431619ED10AF589EEDFF4750DEA00EFD7AFDB814B6F3528729692B1F2482041521AE9DC
  */
```

Tam aradığımız bilgi diyebiliriz, gizli ya da özel anahtarı bu formatta hazırlayıp bir dosyaya koyup ayarlar ekranından ilgili dosyayı belirtmemiz gerekiyor.
Tabi önce bir SSH oturumu oluşturup, gizli ve özel anahtar değerlerini yakalamamız lazım, önceki yazıdan hatırlarsanız bu işi yaparken ilgili anahtar değerlerini ekrana yazan bir `patch` hazırlamıştık.
SSH oturumu içinde bir Linux sunucuya bağlanıp basit bir `ls` komutu çalıştıran kod da hazırlamıştık. Kodumuz aşağıdaki gibiydi.

```
const { Client } = require('ssh2');

const algorithms = {
	kex: [ 'diffie-hellman-group1-sha1' ],
	cipher: [ 'aes128-ctr' ],
	hmac: [ 'hmac-sha2-256' ],
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
		host: process.env.TARGET_HOST,
		port: 22,
		algorithms: algorithms,
		username: process.env.TARGET_USERNAME,
		password: process.env.TARGET_PASSWORD,
		debug: function(msg) {
			console.log(msg);
		},
	});
```

## Test

Yukarıdaki kodu çalıştırınca ilk sorunumuz ortaya aşağıdaki gibi çıktı, en azından benim kendi local ortamımda. Farklı bir SSH versiyonunda konfigürasyonunda daha farklı sonuçlar almak mümkün bunu birazdan açıklayacağım.

```
...
Handshake: (local) KEX method: diffie-hellman-group1-sha1
Handshake: (remote) KEX method: curve25519-sha256,curve25519-sha256@libssh.org,ecdh-sha2-nistp256,ecdh-sha2-nistp384,ecdh-sha2-nistp521,diffie-hellman-group-exchange-sha256,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512,diffie-hellman-group14-sha256
Handshake: No matching key exchange algorithm
...
...
Error: Handshake failed: no matching key exchange algorithm
```

Ben bu testi evdeki Debian 11 sunucuya bağlanmaya çalışarak test ettim, yukarıdaki mesajları biraz daha yakından okursak hata sebebini anlayabiliriz. SSH el sıkışma sürecinde `local` yani yukarıdaki kod parçası
`KEX` algoritması olarak `diffie-hellman-group1-sha1` önermiş ama `remote` yani Debian sunucumuz `curve25519-sha256` ile başlayarak farklı bir çok algoritma önermiş ama aralarında bizim istemci olarak kullanmak istediğimiz
`diffie-hellman-group1-sha1` algoritması bulunmuyor. Bu nedenle **no matching key exchange algorithm** hatasını almışız.

Biraz araştırınca hatanın sebebinin [burada](https://www.openssh.com/legacy.html) açıklandığı görebiliriz.

```
Unable to negotiate with legacyhost: no matching key exchange method found.
Their offer: diffie-hellman-group1-sha1
```
> In this case, the client and server were unable to agree on the key exchange
> algorithm. The server offered only a single method
> diffie-hellman-group1-sha1. OpenSSH supports this method, but does not enable
> it by default because it is weak and within theoretical range of the
> so-called Logjam attack.

Kısaca güvenlik açısından zayıf ve ataklara maruz kalabilecek bu algoritma yeni
versiyon SSH sunucularda `disable` olarak geliyor. Bunu tekrar aktif etme
yöntemini ilgili sayfada açıklamış, şimdilik burayı geçip şuanda desteklenen ve
sunucu tarafından önerilen algoritmalardan biri olan
`diffie-hellman-group16-sha512` biri ile yola devam edelim.

## Algoritma Değişimi

Algoritmayı aşağıdaki kısımdaki gibi önerilenlerden biri yapıp tekrar deniyorum.

```
const algorithms = {
	kex: [ 'diffie-hellman-group16-sha512' ],
	cipher: [ 'aes128-ctr' ],
	hmac: [ 'hmac-sha2-256' ],
  };
```

Kodu çalıştırdıktan sonra bu sefer bir hata almadık sunucudan başarılı şekilde cevabı alabildik. Ekranda da trafik çözümlemesi için Wireshark `keylog` dosyası için aradığımız değerler çıktı.

```
...
...
Handshake: (local) randomFillSync: 8ee195701163311362f4c0c8ccae7c55
..
...
SECRET: 000002006b61880c960d953382077c4f695cda7187e31aed23a28679fff4e81f7242939401ec18cf607e02c6601e4947fe3eecc0d5d66b12b00da50a7ca481b53a521d9b11b358943b1e04884933194d0bffdfc5f894ee414072b1cd9e35c3785ff57a507c748101877930bc29bb9cc135deccbb0e85d365cff4fda25eae411b6fc91eaef2826397a990a93504f9d418a601ecaa5c285f221a0399a8217aa4c923f5c91f51ad81633b8601ab680b4423f459c89f3790fa6a075d6f0478519d3ab9ddd1ef2316cee47d4708d1bd3e3207675adc9bf1d71368fe59e358f8f430da4ffc8794da39b572f03fae56526bf98173ebc775ba6a754545a6790fe3c66ad77fef49c33b96c9bb8a7538dfd5e5eb3cd432a5cd98a78f0d1f9f943117ec2526f01d1ea27f992c70b1a40dead1789a03c6c542bdddc4e843041759e2cc502c2171b8dba713a78bc30afc85ed0b3e99699407fb8794187772154edd68217bd8f73684d7e4a62ebe750030919cb3d8644d85c9347baee12f1e589edea2ed6a0d1e0cf8737577a3b255899ffd7c72d5a7d4b51b2a6cd1597f9b68c7ea41b95ba8b5e475892bb6bdba8ae6878f72e5b1ba7e628de2b318c353d592d5c12fd1a520d4a1e794376e63e86e1d41162f83fc06cf72ca7c3222206cc1264f2ec5b4819aafd0e442bee4dde92eb46e9f96fcc3d2151615376a72df47baa9850634df69450a16c10c86
...
...
```

SSH [Transport Layer](https://datatracker.ietf.org/doc/html/rfc4253#section-7.1) dokümanına bakarsak orada bu değerlerden `cookie` olanın özellikleri belirtilmiş.

```
...
byte         SSH_MSG_KEXINIT
byte[16]     cookie (random bytes)
...
```

> The 'cookie' MUST be a random value generated by the sender.  Its purpose is
> to make it impossible for either side to fully determine the keys and the
> session identifier.

Yukarıda yakaladığımız `randomFillSync` değeri aslında tam olarak bunu yapıyor, yani `cookie` değerini bulduk. Bu değeri ayrıca Wireshark üzerinden yakaladığımız paketlerin içinde de görebiliriz. 

![Capture 1](/img/sshdecrypt/wireshark-cookie.png)

Diğer `SECRET` olarak yakaladığımız değer de paylaşılan anahtar fakat burada bizim ekrana yazdırdığımız değer ile Wireshark'ın beklediği değer arasında ufak bir fark var, ekranda yazılan 
değer `length+value` olarak encode edilmiş Wireshark sadece `value` kısmını beklediği için başındaki 4 byte yer kaplayan `00000200` değerini çıkarıp kalanı onun istediği formatta `keylog` dosyası olarak kaydediyoruz
ve dosya içeriği aşağıdaki gibi oluyor.

```
8ee195701163311362f4c0c8ccae7c55 SHARED_SECRET 6b61880c960d953382077c4f695cda7187e31aed23a28679fff4e81f7242939401ec18cf607e02c6601e4947fe3eecc0d5d66b12b00da50a7ca481b53a521d9b11b358943b1e04884933194d0bffdfc5f894ee414072b1cd9e35c3785ff57a507c748101877930bc29bb9cc135deccbb0e85d365cff4fda25eae411b6fc91eaef2826397a990a93504f9d418a601ecaa5c285f221a0399a8217aa4c923f5c91f51ad81633b8601ab680b4423f459c89f3790fa6a075d6f0478519d3ab9ddd1ef2316cee47d4708d1bd3e3207675adc9bf1d71368fe59e358f8f430da4ffc8794da39b572f03fae56526bf98173ebc775ba6a754545a6790fe3c66ad77fef49c33b96c9bb8a7538dfd5e5eb3cd432a5cd98a78f0d1f9f943117ec2526f01d1ea27f992c70b1a40dead1789a03c6c542bdddc4e843041759e2cc502c2171b8dba713a78bc30afc85ed0b3e99699407fb8794187772154edd68217bd8f73684d7e4a62ebe750030919cb3d8644d85c9347baee12f1e589edea2ed6a0d1e0cf8737577a3b255899ffd7c72d5a7d4b51b2a6cd1597f9b68c7ea41b95ba8b5e475892bb6bdba8ae6878f72e5b1ba7e628de2b318c353d592d5c12fd1a520d4a1e794376e63e86e1d41162f83fc06cf72ca7c3222206cc1264f2ec5b4819aafd0e442bee4dde92eb46e9f96fcc3d2151615376a72df47baa9850634df69450a16c10c86
```

Wireshark üzerinden ayarlar menüsüne girerek tekrar oluşturduğumuz key dosyasını ve çözümleme yaparken oluşturacağı `debug` çıktısını kaydedeceği dosyayı giriyoruz.

![Capture 1](/img/sshdecrypt/wireshark-ssh-pref-key.png)

Wireshark restart edildikten sonra kaydettiğim paketi tekrar açıyorum, ama maalesef hala aynı şekilde bütün paketler `encrypted` olarak gözükmeye devam ediyor.

![Capture 1](/img/sshdecrypt/wireshark-ssh-enc1.png)

Evet buraya kadar her şey güzeldi fakat bundan sonra saç baş yolduran kısmı başlıyor, beklediğimiz gibi olmadı, bütün adımları uygun yaptım istediği değerleri bulup sağladım derken değişen bir şey olmadı ayrıca debug çıktıları
açılmasına rağmen neden çözümleme yapamadığına dair bir log da üretmedi. Wireshark SSH [koduna](https://gitlab.com/wireshark/wireshark/-/blob/master/epan/dissectors/packet-ssh.c) baktığımda oldukça fazla log cümlesi görüyorum,
fakat Wireshark'ı loglama seviyesi `debug, noisy` olarak başlatsam bile bu logların herhangi biri ne dosyada ne de ekranda gözükmüyor. En azından aşağıdaki satırların birine düşmesi kesin diye düşünüp böyle loglar bekliyordum.

```
static void
ssh_keylog_process_line(const char *line)
{
    ws_noisy("ssh: process line: %s", line);
    ...
    ...
```

## Wireshark Derliyoruz

Biraz dokümanları biraz da kodu kurcaladıktan sonra [burada](https://www.wireshark.org/docs/wsdg_html_chunked/ChSrcDebug.html) şöyle bir ifade ile karşılaştım.

> Full debug logs can be invaluable to investigate any issues with the code. By
> default debug level logs are only enabled with Debug build type. You can
> enable full debug logs and extra debugging code by configuring the
> ENABLE_DEBUG CMake option. This in turn will define the macro symbol WS_DEBUG
> and enable the full range of debugging code in Wireshark.

Yani o kodda gördüğümüz `ws_noisy` ya da `ws_debug` sadece `DEBUG` build yapıldığında aktif oluyor, en azından ben başka bir yöntem bulamadım ve derleme işlemi için [bu dokümana](https://www.wireshark.org/docs/wsdg_html_chunked/ChapterSetup.html#ChSetupUNIX)
bakarak bağımlılıkları yüklemeye başladım.

Herhalde C programlama dilini çok sevsem de projeleri derlemesi en nefret ettiğim yanlarından biri kabul ediyorum, modern diller gibi size otomatik bir paket yönetimi sağlamıyor
ve bu aşamada oldukça uğraşabiliyorsunuz ki bende de öyle oldu. Özellikle `QT` kütüphane bağımlılıklarını sağlamak baya uğraştırdı, çok fazla hata çıktı o yüzden sadece komut satırında çalışan versiyonu olan
`Tshark` aracını derlemeye karar verdim. Arayüz ile değil de komut satırından SSH trafiğini verip yine aynı şeyi yaptırıyorsunuz, aslında GUI versiyonu da aynı kodu çağırıyor, CLI versiyonu da bundan dolayı işi daha fazla uzatmamak için CLI versiyonu ile devam etme
kararı aldım. Gerekli bağımlılıklar, hatalar ve benzeri sorunları hallettikten sonra gün sonunda ve bu şekilde `DEBUG` derleme işlemi yapabildim.

```
cmake -DCMAKE_BUILD_TYPE=Debug -DBUILD_wireshark=OFF ../
```

Ardından aşağıdaki gibi komut satırından tekrar çalıştırıyoruz ve sonuçları inceliyoruz.

```
caltuntas@debian11:~/Projects/wireshark/build/run$ ./tshark  --log-level=noisy -o ssh.debug_file:./sshdebug.log -o ssh.keylog_file:/home/caltuntas/keys-dh-g16-512.txt -r /home/caltuntas/ssh-dh-g16.pcapng

 ** (tshark:51929) 01:51:38.173775 [packet-ssh NOISY] epan/dissectors/packet-ssh.c:947 -- ssh_dissect_ssh2(): ....ssh_dissect_ssh2[S]: frame_key_start=8, pinfo->num=14, frame_key_end=0, offset=0, frame_key_end_offset=0
 ** (tshark:51929) 01:51:38.199013 [packet-ssh NOISY] epan/dissectors/packet-ssh.c:2110 -- ssh_keylog_process_line(): ssh: process line: 8ee195701163311362f4c0c8ccae7c55 SHARED_SECRET 6b61880c960d953382077c4f695cda7187e31aed23a28679fff4e81f7242939401ec18cf607e02c6601e4947fe3eecc0d5d66b12b00da50a7ca481b53a521d9b11b358943b1e04884933194d0bffdfc5f894ee414072b1cd9e35c3785ff57a507c748101877930bc29bb9cc135deccbb0e85d365cff4fda25eae411b6fc91eaef2826397a990a93504f9d418a601ecaa5c285f221a0399a8217aa4c923f5c91f51ad81633b8601ab680b4423f459c89f3790fa6a075d6f0478519d3ab9ddd1ef2316cee47d4708d1bd3e3207675adc9bf1d71368fe59e358f8f430da4ffc8794da39b572f03fae56
 ** (tshark:51929) 01:51:38.199448 [packet-ssh NOISY] epan/dissectors/packet-ssh.c:2110 -- ssh_keylog_process_line(): ssh: process line: 526bf98173ebc775ba6a754545a6790fe3c66ad77fef49c33b96c9bb8a7538dfd5e5eb3cd432a5cd98a78f0d1f9f943117ec2526f01d1ea27f992c70b1a40dead1789a03c6c542bdddc4e843041759e2cc502c2171b8dba713a78bc30afc85ed0b3e99699407fb8794187772154edd68217bd8f73684d7e4a62ebe750030919cb3d8644d85c9347baee12f1e589edea2ed6a0d1e0cf8737577a3b255899ffd7c72d5a7d4b51b2a6cd1597f9b68c7ea41b95ba8b5e475892bb6bdba8ae6878f72e5b1ba7e628de2b318c353d592d5c12fd1a520d4a1e794376e63e86e1d41162f83fc06cf72ca7c3222206cc1264f2ec5b4819aafd0e442bee4dde92eb46e9f9
 ** (tshark:51929) 01:51:38.199849 [packet-ssh DEBUG] epan/dissectors/packet-ssh.c:2128 -- ssh_keylog_process_line(): ssh keylog: invalid format
 ** (tshark:51929) 01:51:38.199951 [packet-ssh NOISY] epan/dissectors/packet-ssh.c:2110 -- ssh_keylog_process_line(): ssh: process line: 6fcc3d2151615376a72df47baa9850634df69450a16c10c86
 ** (tshark:51929) 01:51:38.200208 [packet-ssh DEBUG] epan/dissectors/packet-ssh.c:2128 -- ssh_keylog_process_line(): ssh keylog: invalid format
```

Sonuçlarda ilk bakışta dikkatinizi çekti mi bilmem ama, `process line` log mesajı 3 defa yazılmış ve biraz dikkatli bakınca aslında bizim tek satırda olan `cookie SHARED_SECRET key` için verdiğimiz bilgileri 3 satıra bölmüş gibi gözüküyor.

## Wireshark Bug Fix

Wireshark log mesajlarını takip edersek yukarıdaki log mesajının nasıl yazdırıldığını koda bakarak kolayca anlayabiliriz, `ssh_keylog_read_file` içerisinde her satır için `ssh_keylog_process_line` fonksiyonu çağrılmış.
Sorun biz tek satır bilgi girmemize rağmen neden 3 defa bu işlemi yapmış onu bulmamız gerekiyor. Kod içine biraz daha dikkatli bakarsak sorunun nerede olduğunu bence anlayabiliriz. İlgili fonksiyonun içeriği aşağıda görülebilir.

```
static void
ssh_keylog_read_file(void)
//...
//...
//...
for (;;) {
    char buf[512];
    buf[0] = 0;

    if (!fgets(buf, sizeof(buf), ssh_keylog_file)) {
        if (ferror(ssh_keylog_file)) {
            ws_debug("Error while reading %s, closing it.", pref_keylog_file);
            ssh_keylog_reset();
            g_hash_table_remove_all(ssh_master_key_map);
        }
        break;
    }

    size_t len = strlen(buf);
    while(len>0 && (buf[len-1]=='\r' || buf[len-1]=='\n')){len-=1;buf[len]=0;}

    ssh_keylog_process_line(buf);
}
```


Yukarıdaki satırlarda `char buf[512]` dikkatinizi çekti mi bilmiyorum ama sorun burada yatıyor. Bizim oluşturduğumuz dosyada `keylog` dosyasında hatırlarsanız, `cookie SHARED_SECRET key`  formatında bir veri bulunuyordu.
Şimdi ufak bir hesaplama yaparsak 

- cookie = 32 karakter
- SHARED_SECRET = 13 karakter
- key = 1024 karakter
- boşluklar + yeni satır= 3 karakter
- Toplam = 1072

Bu hesaplama aslında neden `512` karakterlik bir buffer yeterli değil onu gösteriyor. Demek ki ilgili buffer değerini arttırırsak sorunu düzeltebiliriz. Tabi arttırırken kaça çıkarmak lazım onu düşünmemiz lazım, 
burada algoritmaya göre sabit bir buffer değeri vermek yerine dinamik olarak da hesaplanabilir ama daha kompleks bir çözüm olacağı için şimdilik ondan uzak duruyorum. 

Aşağıda benim testi yaptığım sunucu üzerinde kullanılan, `KEX` algoritmalarının listesini görebilirsiniz.

```
caltuntas@debian11:~ ssh -Q kex
diffie-hellman-group1-sha1
diffie-hellman-group14-sha1
diffie-hellman-group14-sha256
diffie-hellman-group16-sha512
diffie-hellman-group18-sha512
diffie-hellman-group-exchange-sha1
diffie-hellman-group-exchange-sha256
ecdh-sha2-nistp256
ecdh-sha2-nistp384
ecdh-sha2-nistp521
curve25519-sha256
curve25519-sha256@libssh.org
sntrup4591761x25519-sha512@tinyssh.org
```

Listede görüldüğü gibi algoritmalar tarafından üretilen anahtarların hepsi `hash` işleminden geçirilip ortaya çıkıyor, hash algoritması olarak da, `sha1,sha2,sha256,sha512` yani maksimum 512 byte yani 1024 karakter uzunluğunda olabilir gözüküyor.
Diğer `cookie` gibi şeyleri de içerdiğinden 1024 vermek mantıklı olmaz, bu sebeple 1100 rakamı işimizi görse de, ben diğer kullanılabilecek algoritmaları kontrol etmediğimden olası bir duruma karşı **2048** vermeyi mantılı buluyorum.

Özetle `char buf[512];` yerine `char buf[2048];` gibi basit bir değişiklik yapıp kodu tekrar derleyip `tshark` ile deniyorum. 

```
caltuntas@debian11:~/Projects/wireshark/build/run$ ./tshark -V -o ssh.debug_file:./sshdebug.log -o ssh.keylog_file:/home/caltuntas/keys-dh-g16-512.txt -r /home/caltuntas/ssh-dh-g16.pcapng
...
...
** (tshark:54010) 15:20:52.539820 [packet-ssh NOISY] epan/dissectors/packet-ssh.c:3339 -- ssh_decrypt_packet(): Getting raw bytes of length 64
** (tshark:54010) 15:20:52.540179 [packet-ssh NOISY] epan/dissectors/packet-ssh.c:3416 -- ssh_decrypt_packet(): MAC OK
...
...
SSH Protocol
    SSH Version 2 (encryption:aes128-ctr mac:hmac-sha2-256 compression:none)
        Packet Length: 76
        Padding Length: 13
        Message: User Authentication (generic)
            Message Code: User Authentication Request (50)
            User Name length: 9
            User Name: testusername
            Service Name length: 14
            Service Name: ssh-connection
            Method Name length: 8
            Method Name: password
            Change password: False
            Password length: 13
            Password: testpassword
            Payload: 320000000963616c74756e7461730000000e7370682d636f6e6e651374696f6e000a0008706173737c6f7264000000000d7361746e75746c612a32303232
        Padding String: e55ac62dfd281f98c9aaf48d68
        MAC: 7b9a04b10ba7c9f984354410fb5e9349c9b255226bc75bd6635c9b29c1399244 [correct]
        [MAC Status: Good]
        [Sequence number: 5]
    [Direction: client-to-server]
...
...
```

Yukarıda paketleri çözebildiği ve `User Name` ve `Password` olarak gönderilen değerleri de açık olarak artık görebiliyoruz yani fix işe yaramış. Sorunu çözmeden önce aynı paket şu şekilde gözüküyordu.

```
...
...
** (tshark:54005) 15:19:35.684498 [packet-ssh NOISY] epan/dissectors/packet-ssh.c:3339 -- ssh_decrypt_packet(): Getting raw bytes of length 128
** (tshark:54005) 15:19:35.684594 [packet-ssh DEBUG] epan/dissectors/packet-ssh.c:3361 -- ssh_decrypt_packet(): ssh: unreasonable message length 1997047085/92
...
...
SSH Protocol
    SSH Version 2 (encryption:aes128-ctr mac:hmac-sha2-256 compression:none)
        Packet Length (encrypted): 89bf5b74
        Encrypted Packet: 13616c8ddfe4a3f034fb3bbc655f32dff594f19e04bc20496d77b97758348be0cdd678f8bcfbae3515e8fee4b4fe1681ef9da4ff533ebd28d305ca14970c185bd91389f90ad62ffdba5320d1
        MAC: 7b9a04b10ba7c9f984354410fb5e9349c9b255226bc75bd6635c9b29c1399244
    [Direction: client-to-server]
```

## Wireshark GUI

Uzun uğraşlar sonucunda, zar zor da olsa hatayı bulup, düzeltip Wireshark arayüz olmasa da onun CLI aracı ile trafiği çözümlemeyi başardık. Tabi iyi bir açık kaynak topluluğu vatandaşı olarak, sadece
sorunları iletip, yeni özellik istemekle yetinmeyip sorunu tespit edip biz de katkıda bulunuyoruz. Bunun için bir [issue](https://gitlab.com/wireshark/wireshark/-/issues/20332) oluşturdum, çözümü de önerdim, farklı bir görüş varsa duymak istedim değilde 
yukarıda yaptığım değişikliği **PR** olarak iletmeyi düşünüyorum yakında.

Ama hala çözümlenmiş trafiği Wireshark ara yüzünde göremediğim için eksik hissettiğimden, ama MacOS ortamında derlemek için bağımlılıklarla boğuşacak enerjim de kalmadığından şöyle bir fikir geldi aklıma.
Neden 512 karakteri geçmeyecek bir KEX algoritması kullanmıyorum? Hatırlarsanız, desteklenmeyen algoritma hatası almıştık ilk başlarda, `diffie-hellman-group1-sha1` algoritması bulunsa da güvenlik sebebiyle `disabled` 
olarak geliyordu.

Eğer bu algoritmayı sunucuda aktif hale getirirsek toplam karakter uzunluğu SHA1 olduğundan 256 karakter olacak ve diğer `cookie` gibi alanlarla da olsa 512 karakteri geçmeyecek. Bende denemeye değer, Debian üzerinde bunu aktif hale getirmek için
aşağıdaki satırları `/etc/ssh/sshd_config` dosyasına ekleyerek o algoritmayı tekrar aktif hale getirebiliriz.

```
...
#Legacy changes
KexAlgorithms +diffie-hellman-group1-sha1
```

Sonrasında tekrar bir SSH trafiği oluşturacak kodun eski halini çalıştırıyorum.

```
...
...
Handshake: (local) randomFillSync: fb22cb9bb3693944ea0d0c5d870fef11
..
...
SECRET: 6cb634341dd916bbd8508e6b035cb361068eb8abd0e174f0dd930c2557bca7bb1692f6967469d985c78eea2fc0a7e92ae3e99082d2938002a576da7b944fb89a154ff3b81d4faf40a4c3bb2e6b994528f931d0f4ccf6e955ce29cc03ade69477f0b48653887be97337d0fbe7ab029f2653a918e0e9bb44de4a9cb365ce4abfb1
...
...
```

Yukarıdaki çıktıdan aldığım bu değerleri daha önce yaptığım gibi `keylog` dosyası içine aşağıdaki gibi yerleştirdim.

```
fb22cb9bb3693944ea0d0c5d870fef11 SHARED_SECRET 6cb634341dd916bbd8508e6b035cb361068eb8abd0e174f0dd930c2557bca7bb1692f6967469d985c78eea2fc0a7e92ae3e99082d2938002a576da7b944fb89a154ff3b81d4faf40a4c3bb2e6b994528f931d0f4ccf6e955ce29cc03ade69477f0b48653887be97337d0fbe7ab029f2653a918e0e9bb44de4a9cb365ce4abfb1
```

![Capture 1](/img/sshdecrypt/wireshark-ssh-dec.png)

Evet sonunda Wireshark GUI üzerinde de istediğimiz sonucu aldık, son resme bakacak olursanız eskisinden farklı olarak, 1 numara olarak işaretlediğim kısımda eskiden olmayan, SSH paket tipleri gözüküyor, 2 ve 3 numarası kısımlarda ise
trafiğinden içinden daha önceki yazıda yaptığımıza bender `Username` ve `Password` bilgilerini net bir şekilde görebiliyoruz.

## Sırada Ne Var?

Şuana kadar genelde biraz kaçak güreştik, kullandığımız kütüphanenin kodunu değiştirerek, hesaplanmış olan `shared key` değerini kullanarak Wireshark üzerinde bunu çözümledik. 
Paylaşılan anahtar aslında istemci ve sunucu tarafından gizli tutulan `private key` ve sonrasında açık olarak paylaşılan tüm bilgilerin hesaplanması sonucunda ortaya çıkıyor.
Biraz kolayına kaçıp kütüphanenin hesapladığı değeri aldık kullandık.Bir sonraki yazıda, elimizde sadece özel anahtar değeri olursa, yani hep dediğimiz özel anahtarı ele geçiren trafiği çözümler iddiasını ispatlamaya çalışacağız.

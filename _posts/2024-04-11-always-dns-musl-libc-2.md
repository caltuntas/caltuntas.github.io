---
layout: post
title: "Sorun Her Zaman DNS - Musl Libc TCP Sorunu"
description: "Sorun Her Zaman DNS - Musl Libc TCP Sorunu"
mermaid: true
date: 2024-04-11T07:00:00-07:00
tags: dns musl linux
---

Geçenlerde [bu yazımızda](https://www.cihataltuntas.com/2023/12/10/always-dns-musl-libc.html) özellikle docker container sistemlerde
yaygın olarak kullanılan Linux dağıtımı olan `Alpine` dağıtımında varsayılan sistem C kütüphanesi olarak 
kullanılan `Musl` kütüphanesini, DNS ile ilgili bazı konularda nasıl davranıyor diye incelemiştik. 

Bu yazıda biraz DNS protokolünü, biraz da yine `Musl` ve `Alpine` hangi konularda bize sorun çıkarabilir bunları inceleyelim.
Tabi burada asıl amacımız, üzerinde uygulama çalıştırdığınız container ve sistem kütüphanesi geliştirdiğimiz sistemin davranışını farkında olmasanız da
etkilediği için, hangi konularda dikkatli olmamız gerekiyor önceden bilip hazırlıklı olmak.

## Sorunumuz

Diyelim ki uygulamamızı, büyük bir kubernetes ya da docker swarm cluster içinde container/pod olarak deploy ettik. 
Bu uygulama da diğer iç ya da dış servislerle haberleşmek için önce isim çözümlemesi yapacak ve aşağıdaki gibi bir istek gönderecek.

Kullandığımız dış servisi aslında hem local ortamımızda hem de test ortamında kontrol etmiştik, çözümleme düzgün yapılıyordu. 

```
cihataltuntas@local% ping toomany.ddstreet.org
PING toomany.ddstreet.org (10.254.200.220): 56 data bytes
..
--- toomany.ddstreet.org ping statistics ---
2 packets transmitted, 0 packets received, 100.0% packet loss

cihataltuntas@local % docker run --dns=8.8.8.8 alpine:3.18 ping toomany.ddstreet.org
PING toomany.ddstreet.org (10.254.200.239): 56 data bytes
..
--- toomany.ddstreet.org ping statistics ---
2 packets transmitted, 0 packets received, 100% packet loss
```

Yukarıdaki çıktılardan görüldüğü gibi direk local bilgisayarımdan ve bir de sonra versiyon `Alpine` container üzerinden
aynı adrese ping isteği gönderdim, ikisi de başarılı. Peki aynı isteği mesela, çok yakın zamana kadar aktif kullanılan bizim de production 
ortamlarda kullandığımız `Alpine 3.17` versiyonuna gönderelim bakalım ne oluyor?

```
cihataltuntas@local% docker run --dns=8.8.8.8 alpine:3.17 ping toomany.ddstreet.org
ping: bad address 'toomany.ddstreet.org'
```

İlginç bir şekilde aslında DNS server olarak bir sorun olmamasına rağmen, özellikle google dns sunucularını belirttim, 
adres de doğru olmasına rağmen `3.17` versiyonunda hatalı adres olarak çıktı verdi.

## DNS ve TCP İlişkisi

Uzun süre DNS protokolünün `UDP` ile çalıştığını sanırdık, ta ki bir sorun yaşayıp her zaman öyle olmadığını öğrenene kadar.
Bende son zamanlara kadar TCP ile bir ilişkisinin olmadığını sanıyordum fakat durum öyle değilmiş. Bir DNS sorgusu yaptığınızda
eğer dönen cevap belirli bir boyutun (512 byte) üzerinde ise, [RFC-5966](https://datatracker.ietf.org/doc/rfc5966/)
protokol standartları gereği geri kalan iletişim TCP üzerinden devam etmek zorunda.

Dönen cevap içinde aslında bu bir `flag` olarak istemciye iletiliyor ve bunu gören istemci bu sefer TCP üzerinden aynı isteği tekrar yapıyor.
Ne demek istediğimi yukarıdaki isteği tekrar gönderip, Wireshark üzerinden dönen cevabı inceleyerek anlatmaya çalışayım.

```
cihataltuntas@local% nslookup toomany.ddstreet.org
;; Truncated, retrying in TCP mode.
Server:         172.16.33.1
Address:        172.16.33.1#53

Non-authoritative answer:
Name:   toomany.ddstreet.org
Address: 10.254.200.233
Name:   toomany.ddstreet.org
Address: 10.254.200.216
Name:   toomany.ddstreet.org
Address: 10.254.200.221
Name:   toomany.ddstreet.org
Address: 10.254.200.218
Name:   toomany.ddstreet.org
Address: 10.254.200.227
Name:   toomany.ddstreet.org
Address: 10.254.200.215
Name:   toomany.ddstreet.org
Address: 10.254.200.210
Name:   toomany.ddstreet.org
Address: 10.254.200.209
Name:   toomany.ddstreet.org
Address: 10.254.200.206
Name:   toomany.ddstreet.org
Address: 10.254.200.205
Name:   toomany.ddstreet.org
Address: 10.254.200.230
Name:   toomany.ddstreet.org
Address: 10.254.200.225
...
...
```

Bu isteği `nslookup` ile kendi ortamımdan yaptım , ilk dikkatinizi çeken şey muhtemelen
çok fazla çözümleme yapmak istediğimiz adresin çok fazla IP adresine sahip olması. Sonucu bir de
paket trafiğine bakarak değerlendirelim.

![Capture 1](/img/musldns2/dnstcp.png)

Görüldüğü gibi ilk istekler UDP üzerinden gönderilmiş fakat sonrasında sunucudan gelen cevapta gözüken `truncated` değeri görülünce,
DNS sorgulaması yapan program, iletişimi TCP üzerinden tekrar açıp tekrar sorgulama yapıp cevap almış. 

## Alpine 3.17 ve Öncesindeki Sorun

Yukarıda protokolün hangi durumda UDP hangi durumda TCP ile haberleştiğini gördük, işte bu da aslında `3.17` 
versiyonunda çalışmamasının asıl sebebi. Çok yakın zamana kadar `Musl Libc` DNS over TCP kısmını desteklemiyordu, bundan dolayı
Alpine dağıtımında sistem kütüphanesinin DNS çözümlemesini kullanan her program, ya da kendi yazdığınız kod bu tarz bir durumda hata veriyordu. 

Bu destek çok yakın zamana kadar hem Musl hem de Alpine üzerinde yoktu, geçen sene [Alpine 3.18](https://alpinelinux.org/posts/Alpine-3.18.0-released.html) ile
birlikte bu sorun çözülmüş oldu, fakat eski sürümlerde devam ettiği için sorunu yaşamamak için yeni bir sürüm Alpine kullanmanız gerekiyor.

Aynı sorunu eski versiyon Alpine üzerinden gönderdiğimizde nasıl bir paket trafiği oluyor bir de onu inceleyelim.

```
cihataltuntas@local% docker run --dns=8.8.8.8 alpine:3.17 ping toomany.ddstreet.org
ping: bad address 'toomany.ddstreet.org'
```

![Capture 2](/img/musldns2/dnsudp.png)

Paket trafiğinden de görüldüğü gibi `truncated` cevabı yani 512 byte değerinden büyük bir değer dönüldüğünü belirten bayrak 1 olarak gönderilmesine
rağmen o versiyonda kullanılan sistem kütüphanesi bunu dikkate almadığı için, TCP geçişi yapılmıyor ve çözümleme başarısız oluyor.

## Nslookup Garipliği

Son olarak bu testleri yaparken genelde sistem kütüphanesinin DNS çözümleme mekanizmasını kullandığını bildiğim `ping, getent` kullanıyordum.
Genelde `nslookup, dig` gibi bu işe özel olarak yazılmış araçlar sistem kütüphanesini kullanmayıp kendi çözümlemesini kendileri yapabiliyor. 
Yani eski versiyon bir alpine bile olsa, `bind-tools` paketi içinde gelen `nslookup` aracını kursanız `Musl` TCP desteği olmasa bile
kendi işini kendi yaptığı için sorun olmayacak, ama tabi bu yazdığınız kodun çalışacağı anlamına gelmiyor çünkü çoğunlukla sistem kütüphanesini kullanacaklar.

```
cihataltuntas@local% docker run -it --dns=8.8.8.8  alpine:3.17 sh
/ # apk add bind-tools
fetch https://dl-cdn.alpinelinux.org/alpine/v3.17/main/x86_64/APKINDEX.tar.gz
fetch https://dl-cdn.alpinelinux.org/alpine/v3.17/community/x86_64/APKINDEX.tar.gz
(1/13) Installing fstrm (0.6.1-r1)
...
...
Executing busybox-1.35.0-r29.trigger
OK: 14 MiB in 28 packages
/ # nslookup toomany.ddstreet.org
;; Truncated, retrying in TCP mode.
Server:         8.8.8.8
Address:        8.8.8.8#53

Non-authoritative answer:
Name:   toomany.ddstreet.org
Address: 10.254.200.206
Name:   toomany.ddstreet.org
Address: 10.254.200.230
Name:   toomany.ddstreet.org
Address: 10.254.200.236
Name:   toomany.ddstreet.org
Address: 10.254.200.219
Name:   toomany.ddstreet.org
...
```

Yukarıda eski versiyon üzerine bu paket ile gelen `nslookup` kurulumu yaptım, `ping` ile çözemediği adresi bu sefer çözdü, ama bu zaten beklediğim bir 
durumdu takıldığım nokta son versiyon `Alpine` üzerinde ping ile çalışırken, varsayılan olarak yüklü gelen `nslookup` ile çalışmaması beni şaşırttı.
Benim düşünceme göre ping sistem kütüphanesini kullanıyorsa o da aynısı kullanmalı ve TCP geçişi yapıp çözebilmeliydi ama öyle olmadı.

```
cihataltuntas@local% docker run --dns=8.8.8.8  alpine:latest nslookup toomany.ddstreet.org && ping toomany.ddstreet.org
Server:         8.8.8.8
Address:        8.8.8.8:53

Non-authoritative answer:

Non-authoritative answer:

PING toomany.ddstreet.org (10.254.200.236): 56 data bytes
```

## Sorun İçinde Sorun

Yukarıda son versiyon üzerinde gelen nslookup ile sorgulama yaptığımda boş cevap geldiğini görüyorsunuz aslında aynı sistem üzerinde ping ile 
yapıldığında IP çözülebiliyor.

```
cihataltuntas@local% docker run -it --dns=8.8.8.8  alpine:latest sh
/ # nslookup
BusyBox v1.36.1 (2023-11-07 18:53:09 UTC) multi-call binary.
Usage: nslookup [-type=QUERY_TYPE] [-debug] HOST [DNS_SERVER]
...

/ # ping
BusyBox v1.36.1 (2023-11-07 18:53:09 UTC) multi-call binary.
Usage: ping [OPTIONS] HOST
...
```

Versiyonlarını kontrol ettim, ikisi de `BusyBox` kullanıyor. BusyBox özellikle gömülü ya da küçük boyuta sahip olması istenen sistemler için
`Userland` yani çekirdek de değil de kullanıcı tarafında çalışan, `ls,mv,cp...` gibi bildiğiniz klasik araçların tek bir `binary` içinde toplanmış hali diyebiliriz.
Bunu aşağıda gibi de anlayabilirsiniz.

```
cihataltuntas@local% docker run --dns=8.8.8.8  alpine:latest ls -lah /usr/bin/
total 200K
drwxr-xr-x    2 root     root        4.0K Jan 26 17:53 .
drwxr-xr-x    7 root     root        4.0K Jan 26 17:53 ..
lrwxrwxrwx    1 root     root          12 Jan 26 17:53 [ -> /bin/busybox
lrwxrwxrwx    1 root     root          12 Jan 26 17:53 [[ -> /bin/busybox
lrwxrwxrwx    1 root     root          12 Jan 26 17:53 awk -> /bin/busybox
lrwxrwxrwx    1 root     root          12 Jan 26 17:53 basename -> /bin/busybox
lrwxrwxrwx    1 root     root          12 Jan 26 17:53 bc -> /bin/busybox
lrwxrwxrwx    1 root     root          12 Jan 26 17:53 beep -> /bin/busybox
lrwxrwxrwx    1 root     root          12 Jan 26 17:53 blkdiscard -> /bin/busybox
....
....
```

Bütün araçlar aslında tek bir programa sembolik link oluşturulmuş, aslında bunlar ayrı programlar değil tek bir `busybox` programının 
parçası. Kafa karıştırıcı olan ise, eğer varsayılan ping ve nslookup aynı programın parçası ise ve bu program da `musl libc` kullanması
için derlendiyse neden biri çözerken diğeri çözemiyor?

Sorunu anlamak için `Busybox` [kaynak kodunda](https://github.com/mirror/busybox/blob/master/networking/nslookup.c#L949) `nslookup` kısmına bakayım dedim. Orada üstlerde bulunan yorum satırları dikkatimi çekti hemen.

```
//config:config FEATURE_NSLOOKUP_BIG
//config: bool "Use internal resolver code instead of libc"
//config: depends on NSLOOKUP
//config: default y
```

Yorumda gördüğüme şaşırdım diyebilirim, kendi internal resolver mantığını kullan ve kullanma diye iki seçenek var ve varsayılan 
olarak kendi mantığını kullanıyor yani, sistem kütüphanesinden konfigürasyon yapılmadıysa bu konuda destek almıyor. Belki bu konfigürasyon
Alpine tarafında yapılmıştır dedim ve [buradan](https://github.com/alpinelinux/aports/blob/12c930c0007978cf36e0b59573b06ad55f7bf19f/main/busybox/busyboxconfig#L959) kontrol ettim.
Tahmin ettiğiniz gibi maalesef Alpine da bu değer `CONFIG_FEATURE_NSLOOKUP_BIG=y` olarak verilmiş bu da BusyBox nslookup kendi
çözümleme kodunu işletiyor anlamına geliyor. 

Bu bana bir tutarsızlık gibi geldi, en azından ping içinde kendi çözümleme yapmayıp sistem çözümlemesi kullanıyorsa, BusyBox içinde gelen
basit nslookup aracının da aynısını yapmasın beklerdim, en kötü Alpine bu şekilde build etse daha doğru olurdu diye düşünüyorum farklı bir durumu gözden kaçırmıyorsam.

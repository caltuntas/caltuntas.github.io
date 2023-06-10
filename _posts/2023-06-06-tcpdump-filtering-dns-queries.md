---
layout: post
title: "Gelin Tcpdump ile DNS sorgularını filtreleyelim"
description: "Gelin Tcpdump ile DNS sorgularını filtreleyelim"
date: 2023-06-06T07:00:00-07:00
tags: tcpdump udp dns
---

`Tcpdump` kaç defa hayatımı kurtardı sayısını hatırlamıyorum. Daha çok klasik
port, host ya da protokol üzerinden trafik kontrolü için kullanıyorum ama geçenlerde
karşılaştığım bir sorun sebebiyle daha ileri seviye filtreleme kullanmak zorunda kaldım.
Biraz da faydalı olacağını düşündüğüm ve egzersiz olsun diye izlediğim adımları paylaşmak istedim. 

## Sorunumuz neydi?
Canlı ortamda bizim sistemimizden ortamındaki sunucuların bazılarına ulaşamadığını 
gördüm, sunuculara ulaşmamız için `DNS` sunucusundan isim ile çözümleme yapması gerekiyor.
Bu yüzden `DNS` sunucusuna `hostname` bilgisinden `IPv4` çözmek için atılan `A` tipi sorguları analiz etmem gerekti. 

`Tshark` ya da `Wireshark` gibi araçlarla aynı iş daha kolay yapılabilir ama unutmayın canlı ortamda çalışan bir 
sistem var ve elimizde olan minimum araçla, yeni talep, yükleme değişiklik yapmadan
problemi tespit etmemiz lazım. Bu sunucuda yüklü olan bu işe en uygun araç `tcpdump` ile
işe koyulalım.

## Birinci deneme
DNS bildiğiniz gibi UDP protokolü üzerinden çalışıyor ve varsayılan olarak 53 portunu 
kullanıyor. Öncelikle ilgilendiğim network arayüzü üzerinden geçen DNS trafiğine bakmak
için aşağıdaki gibi bir filtre kullandım.

```
tcpdump -ln -i ens160 'udp port 53'
```

```
10:10:28.000080 IP 192.168.100.169.62567 > 192.168.100.20.53: 21950+ SRV? _ldap._tcp.Default-First-Site-Name._sites.server.local. (73)
10:10:28.008770 IP 192.168.100.30.52098 > 192.168.100.20.53: 23304+ AAAA? hooks.slack.com.server.local. (47)
10:10:28.008770 IP 192.168.100.30.38794 > 192.168.100.20.53: 3665+ A? hooks.slack.com.server.local. (47)
10:10:28.158962 IP 192.168.100.32.43673 > 192.168.100.20.53: 9534+ A? arbiter1. (26)
10:10:28.230193 IP 192.168.100.22.61610 > 192.168.100.20.53: 24725+ A? au.download.windowsupdate.com. (47)
10:10:28.230454 IP 192.168.100.22.61610 > 192.168.100.21.53: 24725+ A? au.download.windowsupdate.com. (47)
10:10:28.702316 IP 192.168.100.21.57615 > 192.168.100.20.53: 40774+ SOA? server.local. (31)
10:10:28.954151 IP 192.168.100.133.58060 > 192.168.100.20.53: 37885+ AAAA? hooks.slack.com. (33)
10:10:28.954392 IP 192.168.100.133.54569 > 192.168.100.20.53: 19301+ A? hooks.slack.com. (33)
10:10:29.153919 IP 192.168.100.21.56348 > 192.168.100.20.53: 38375+ A? download.windowsupdate.com. (44)
10:10:29.415216 IP 192.168.100.21.54360 > 13.107.236.205.53: 19731 [1au] A? download.windowsupdate.com. (55)
10:10:29.454522 IP 13.107.236.205.53 > 192.168.100.21.54360: 19731*- 1/0/1 CNAME wu-fg-shim.trafficmanager.net. (98)
10:10:29.455627 IP 192.168.100.21.53126 > 192.168.100.20.53: 55492+ A? wu-fg-shim.trafficmanager.NET. (47)
10:10:29.600610 IP 192.168.100.33.53418 > 192.168.100.20.53: 52069+ A? arbiter1. (26)
10:10:29.703074 IP 192.168.100.21.57615 > 192.168.100.20.53: 40774+ SOA? server.local. (31)

```

Bu filtre sonucunda 53 portu üzerinden geçen tüm trafiği yukarıdaki gibi görebiliyoruz fakat
görüldüğü gibi bulmak istediğimiz kayıtlar dışında `SRV,AAAA,CNAME..` gibi tüm DNS mesajlarını görüyoruz. 
Fakat bizim istediğimiz sadece hangi adresler için `Type A DNS Query` sorgularının yapıldığını tespit etmek. 

## UDP Paket Yapısı

Bunu yapmak için daha ileri seviye bir filtre yazmak  dolayısıyla protokol detaylarına bakmamız gerekir.
İlk olarak bilmemiz gereken DNS UDP üzerinde çalışan bir protokol ve bunu dikkate alarak bahsettiğimiz tipte DNS sorgularını nasıl bulabiliriz
bulmaya çalışalım. DNS protokol başlık yapısı aşağıda görülebilir. 


```
 0                   1                   2                   3
 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
-----------------------------------------------------------------
|          Source Port          |        Destination Port       |
-----------------------------------------------------------------
|             Length            |            Checksum           |
-----------------------------------------------------------------
|                                                               |
|                             Data                              |
|                                                               |
-----------------------------------------------------------------
```

`Data` kısmının üstündeki satırlar protokol başlığını gösteriyor. Başlığı incelediğimizde `8 byte` uzunluğunda olduğunu ve içerdiği alanları görebiliyoruz. 
`DNS` paketleri ise `Data` kısmının içerisinde geliyor, bu yüzden `DNS` paket yapısına da bakmamız gerekiyor. 

## DNS Paket Yapısı

```
 0                   1
 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5
---------------------------------
|             ID                |
---------------------------------
|           Flags               |
---------------------------------
|           QDCOUNT             |
---------------------------------
|           ANCOUNT             |
---------------------------------
|           NSCOUNT             |
---------------------------------
|           ARCOUNT             |
---------------------------------
```

DNS paketinin yapısına baktığımızda her biri `2 byte` yer tutan 6 alan görüyoruz. Bu paket UDP paketi içinde `Data` kısmında gönderilmiş olacak.
Bizim bulmamız gereken iki kısım var, birincisi `Flags` alanı içeriğinden sadece `Query` tipinde olan paketleri bulmamız lazım. 
Daha iyi gözümüzde canlansın diye, DNS trafiği bulunan bir `pcap` dosyasını `Wireshark` üzerinde inceleyelim.

![Wireshark DNS Packet](/img/tcpdumpdns/dns-wireshark.png)

## İkinci Deneme

Yukarıdaki resim bizim bulmak istediğimiz `Type A DNS Query` ve resme baktığımızda `ID` alanının hemen altında olan `Flags` içinde
hangi `bit` değerinin `1` olarak gönderildiğini görebiliyoruz. Yanda da `Flags` alanının gönderilmiş değerinin `0x0100` olduğu görülüyor.

O zaman şöyle yapabiliriz, UDP paket başlığı `8 byte` yer kaplıyor demiştik, üstüne `2 byte` DNS paketindeki `ID` alanı geldi, hemen sonrasında
gelen `Flags` alanı aslında `udp[10]` içinde bulunması gerekiyor (dizi 0 ile başlıyor). Buradan şöyle bir filtre yazarak ilgili paketleri bulabiliriz
diye düşünüyorum. 

```
tcpdump -ln -i ens160 'udp port 53 and udp[10] & 0x80 = 0'
tcpdump -ln -i ens160 'udp port 53 and udp[10] = 0x1'
tcpdump -ln -i ens160 'udp port 53 and udp[10] = 1'
```

Yukarıdaki filtrelerin hepsi aynı kapıya çıkıyor. `& 0x80 = 0` nereden geldi diye sorulabilir, hemen açıklayalım. Tcpdump ile istersek `bit flag` karşılaştırması yaparak
için aslında dolaylı yoldan oradaki değerin `0x0100` olduğunu kontrol edebiliriz. Yukarıdaki filtrelerden herhangi birini denediğimizde sonuç aşağıdaki gibi oluyor

```
08:50:00.092381 IP 192.168.100.61.4045 > 208.91.112.52.53: 43+ A? strict.bing.com. (33)
08:50:00.280419 IP 192.168.100.111.52874 > 192.168.100.20.53: 5935+ SRV? _ldap._tcp.Default-First-Site-Name._sites.dc._msdcs.server.local. (83)
08:50:04.723430 IP 192.168.100.33.55386 > 192.168.100.20.53: 64594+ A? arbiter1. (26)
08:50:04.913121 IP 192.168.100.33.58165 > 192.168.100.20.53: 5767+ [1au] A? mongo03. (36)
08:50:04.913177 IP 192.168.100.33.53484 > 192.168.100.20.53: 54515+ [1au] AAAA? mongo03. (36)
08:50:04.914712 IP 192.168.100.33.44411 > 192.168.100.20.53: 44196+ [1au] A? mongo03. (36)
08:50:04.916585 IP 192.168.100.33.50264 > 192.168.100.20.53: 59818+ [1au] AAAA? arbiter1. (37)
08:50:04.916739 IP 192.168.100.33.36527 > 192.168.100.20.53: 52768+ [1au] A? arbiter1. (37)
08:50:04.918118 IP 192.168.100.33.36505 > 192.168.100.20.53: 1722+ [1au] A? arbiter1. (37)
08:50:04.918399 IP 192.168.100.33.59246 > 192.168.100.20.53: 19402+ [1au] AAAA? arbiter1. (37)
08:50:04.919751 IP 192.168.100.33.40935 > 192.168.100.20.53: 8112+ [1au] A? arbiter1.server.local. (51)
08:50:05.027957 IP 192.168.100.32.36793 > 192.168.100.20.53: 39115+ A? arbiter1. (26)
08:50:05.042618 IP 192.168.100.61.4045 > 208.91.112.52.53: 49402+ A? swscan.apple.com. (34)
```

Yukarıdaki paketlere baktığımızda ilk aşamada karşımıza çıkan DNS sorgu cevaplarının gittiğini görüyoruz ama hala listede
`AAAA, SRV` gibi DNS sorgu istekleri görülüyor. Bunlardan kurtulmak için filtreyi son defa revize etmeye çalışalım. 

## Son Deneme ve Başarı

DNS paket başlığının yapısını incelediğimizde, ilgili sorgu tipinin paketinin en sondan iki önceki `2 byte` içinde tutulduğunu görebiliyoruz.
Aşağıdaki resimden daha iyi anlaşılabilir. 

![Wireshark DNS Packet](/img/tcpdumpdns/dns-wireshark-type-a.png)

Yani yapmak bulmak istediğimiz filtreleme kabaca şu şekilde olması gerekiyor. 
```
udp[paketuzunlugu-4:2] = 0x0001
```

> `[a:b]` notasyonu a numaralı bytedan başlayarak `b` kadar byte al demek.

Yukarıdan hatırlayacak olursanız UDP paket uzunluğu kendi başlığı içerisinde `2 byte` olarak `4:2` arasında tutuluyor.
Bu bilgiyi kullanarak tekrar filtreyi tekrar revize edelim.

```
tcpdump -ln -i ens160 'udp port 53  and udp[10] & 0x80 = 0 and udp[(udp[4:2]-4):2] =  0x0001'
```
  
```
09:37:26.521212 IP 192.168.100.32.50375 > 192.168.100.20.53: 57051+ A? arbiter1. (26)
09:37:26.522193 IP 192.168.100.32.35151 > 192.168.100.20.53: 56503+ A? arbiter1.server.local. (40)
09:37:26.523585 IP 192.168.100.32.34443 > 192.168.100.20.53: 53150+ A? arbiter1. (26)
09:37:26.524553 IP 192.168.100.32.40833 > 192.168.100.20.53: 53150+ A? arbiter1. (26)
09:37:26.525578 IP 192.168.100.32.46435 > 192.168.100.20.53: 51829+ A? arbiter1.server.local. (40)
09:37:26.727766 IP 192.168.100.33.60701 > 192.168.100.20.53: 60216+ A? arbiter1. (26)
09:37:26.729244 IP 192.168.100.33.48042 > 192.168.100.20.53: 60216+ A? arbiter1. (26)
09:37:26.730305 IP 192.168.100.33.35631 > 192.168.100.20.53: 58112+ A? arbiter1.server.local. (40)
09:37:27.087333 IP 192.168.100.32.48370 > 192.168.100.20.53: 25327+ A? arbiter1. (26)
09:37:27.088618 IP 192.168.100.32.37493 > 192.168.100.20.53: 25327+ A? arbiter1. (26)
09:37:27.089651 IP 192.168.100.32.50450 > 192.168.100.20.53: 21119+ A? arbiter1.server.local. (40)
```

Biraz zahmetli oldu ama görüldüğü gibi işe yaradı ve sadece A tipi DNS sorgularını filtreledik. 

## Daha Basit Bir Yöntem

Yukarıda kullandığımız yöntem ilgili paketleri direk `tcpdump` filtreleriyle bulmaktı. Bunun yerine tabi
aşağıdaki gibi klasik `unix` araçlarından `awk` kullanarak basit bir işlemle de işimizi tamamlayabilirdik. 

```
tcpdump -ln -i ens160 "udp port 53" | awk '/A\?/{adr = $(NF-1); if(!d[adr]) { print adr; d[adr]=1; fflush(stdout) } }'
```

Aslında yaptığımız tüm sonuçları `tcpdump` üzerinden alıp ilgilendiklerimizi `awk` ile filtrelemek. Basit senaryolar
için bu tarz bir yöntem kullanılabilir fakat `tcpdump` filtreleri arka planda [BPF](https://en.wikipedia.org/wiki/Berkeley_Packet_Filter) kullandığı ve
burada `kernel` seviyesinde bir filtreleme olduğu için performans konusunda oldukça farklılık olacaktır. 

## Bonus

Hangi adres için kaç tane DNS sorgusu atılmış canlı olarak güncellenen şekilde görmek için aşağıdaki `awk` scriptini hazırladım.

```
tcpdump -ln -i ens160 'udp port 53  and udp[10] & 0x80 = 0 and udp[(udp[4:2]-4):2] =  0x0001' | awk '
{
	adr=$(NF-1);
	dict[adr]++;
	system("clear")
	system("tput cup 0 0")
	for (key in dict)
	 print dict[key] " : " key
}
'
```

```
6 : swscan.apple.com.
12 : mongo03.
1 : play.google.com.
3 : autoupdate.opera.com.
1 : strict.bing.com.
208 : arbiter1.server.local.
1 : remote-host.server.local.
482 : arbiter1.
2 : remote-host.
1 : settings-win.data.microsoft.com.
1 : wpad.server.local.
```


Çalıştırdığımızda aşağıdakine benzer sonuçları görebilirsiniz. Gerisi hayal gücünüze kalmış


#### Referanslar

- [Fundamentals of Computer Networking Project : Simple DNS Client](https://mislove.org/teaching/cs4700/spring11/handouts/project1-primer.pdf)
- [Tcpdump advanced filters](https://blog.wains.be/2007/2007-10-01-tcpdump-advanced-filters/)

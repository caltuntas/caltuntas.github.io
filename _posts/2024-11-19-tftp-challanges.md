---
layout: post
title: "Protokol Günlükleri - TFTP ve Gariplikleri"
description: "Protokol Günlükleri - TFTP ve Gariplikleri"
date: 2024-11-19T07:00:00-07:00
tags: tftp linux docker
---

Muhtemelen, FTP, SFTP gibi dosya transfer protokollerini burayı okuyan herkes duymuştur diye düşünüyorum ama onlara nazaran TFTP protokolü genelde 
çok daha az bilinen ve biraz da tuhaf bir protokol. Genelde bunu pratikte kendim yapmasam da, [PXE Boot](https://en.wikipedia.org/wiki/Preboot_Execution_Environment) 
yani network üzerinden cihazları boot etmek için kullanılan basit ama davranışı nedeniyle biraz da zor bir protokol.

Basit bir protokol olduğu için benim evde kullandığım **NAS** ya da network cihazları gibi farklı 
gömülü sistemlerde bir kuruluma ihtiyaç olmadan kurulu gelebiliyor. Benim de ihtiyacım daha çok böyle bir cihazdan TFTP kurulu olduğu için dosya
transferi yapabilmek ve mümkün ise bunu otomasyona çevirebilmekti.

## Gerekli Araçlar

İşe koyulmadan gerekli araçları hazırlamaya başlamak ve kafamda olan senaryoyu test etmek istiyorum. TFTP client/server mimarisinde çalışan
bir protokol, bu yüzden öncelikle bir adet TFTP sunucu ve istemciye ihtiyacım var. Sunucu olarak sıfırdan kurulum yapma ya da buna özel bir sunucu 
kurma düşüncem olmadığından en iyi aday, docker üzerinde çalışan bir hafif TFTP sunucusu.

Docker teknolojisinin en sevdiğim yanlarından biri de bu aslında, kurulum, paket yükleme kaldırma işleriyle uğraşmadan çok hızlı bir şekilde 
istediğiniz şeyi çalışır hale getirebiliyorsunuz. Ufak bir arama yaptıktan sonra önüme çıkan, [buradan](https://github.com/wastrachan/docker-tftpd) görece olarak daha güncel bir docker image bulabildim.

İlgili linkten nasıl çalıştırılabileceğini alabilirsiniz, ben ufak bir değişiklik yaptım, TFTP sunucusundan sadece dosya almak değil aynı zamanda da dosya yüklemek istiyorum o yüzden `--create` 
parametresini de kullandım.

```
docker run -v "$(pwd)/tftpdata:/data" \
           --name tftpd --rm -p 69:69/udp \
           -e PUID=$(id -u) -e PGID=$(id -g) \
           wastrachan/tftpd:latest \
           /usr/sbin/in.tftpd -L -v -s -u tftpd --create /data
```

Diğer taraftan aynı makine üzerinden test yapmak istemediğimden farklı bir IP adresine sahip bir ubuntu sunucuya ise `apt install tftp-hpa -y` ile kurulumu yaptım içinde istemci geldiği için,
istemciyi oradan kullanmayı planlıyorum.

## İlk Test Sonuçları
  
Hazırlıklar tamam, şimdi docker yüklü olan farklı bir ortamda dosyaların tutulacağı bir klasör oluşturup ardından yukarıdaki komut ile ayağa kaldırıyorum

```
user@server:# echo "remote file content" > ./tftpdata/deneme.txt
user@server:# docker run -v "$(pwd)/tftpdata:/data" \
                        --name tftpd --rm -p 69:69/udp \
                        -e PUID=$(id -u) -e PGID=$(id -g) \
                        wastrachan/tftpd:latest \
                        /usr/sbin/in.tftpd -L -v -s -u tftpd --create /data

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Starting tftpd with UID 0 and GID 0...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Diğer taraftan TFTP istemci kurulu olan sunucudan ise ilk testimi yapıyorum.

```
user@client:~# tftp 192.168.100.30 69
tftp> get deneme.txt
Transfer timed out.
```

## Sorun Tespiti

Yukarıdaki gibi sunucuyu ayağa kaldırıp test ettiğimde aldığım cevap sadece timeout oldu, buraya kadar normal karşılanabilir fakat en azından log görmeyi bekliyordum.
Zaman aşımı ile ilgili problemde sunucu tarafında herhangi bir log görmediğim için ilk aklıma gelen acaba güvenlik duvarı ya da network ile ilgili bir sorun olabileceği ve paketlerin sunucu tarafına gelmediği oldu.
Bunu gözlemlemek için sunucu tarafında **tcpdump** ile paket kaydı alıp **Wireshark** ile inceledim ve paketlerin aslında sunucu tarafına ulaştığını aşağıdaki gibi görebilirsiniz.

![Capture 1](/img/tftp-challanges/tftpdump1.png)

Dikkatimi çeken aslında sunucu tarafı da cevap göndermiş, hatta aynı cevabı muhtemelen onay almadığı için birkaç defa göndermiş ama bir şekilde istemci tarafı bunu alamamış.

## Loglar Nerede ?

Loglar; acemilik yılları ne kadar gereksiz olduklarını ve neden kullandıklarını düşünerek, ustalık ise onlardan sürekli faydalanıp, sürekli hayat kurtarmalarını görerek geçer.

Bir sorunun tespitinde ister kendi geliştirdiğim, ister farklı bir araç olsun, ilk kontrol ettiğim yer loglar olur ve sorun tespitinde yeri doldurulamaz bir araç olduğunu düşünürüm.
Yukarıda tabi dosya kopyalama işleminin başarısız olmasına rağmen TFTP server tarafında herhangi bir log görememek işi biraz zorlaştırdı, aslında parametre olarak `-v` yani `versobe` mod ile çalışmasına rağmen
herhangi bir çıktı üretmemesine şaşırdım diyebilirim.

Logların neden gelmediğini ya da neden gelen cevabın zaman aşımına uğradığını en hızlı şekilde anlayabilmek `strace` aracı ise sistem çağrılarını incelemeye çalışalım.

```
user@server:# docker ps|grep tftp
e015eb5ea549   wastrachan/tftpd:latest            "/docker-entrypoint.…"   29 seconds ago   Up 28 seconds          0.0.0.0:69->69/udp                 tftpd
user@server:# docker exec -it --privileged e015eb5ea549 sh
/ #  ps -ef
PID   USER     TIME  COMMAND
    1 root      0:00 /usr/sbin/in.tftpd -L -v -s -u tftpd --create /data
   10 root      0:00 sh
   17 root      0:00 ps -ef
/ # strace -f -p 1
...
[pid    28] connect(3, {sa_family=AF_UNIX, sun_path="/dev/log"}, 12) = -1 ENOENT (No such file or directory)
[pid    28] open("deneme.txt", O_RDONLY|O_LARGEFILE) = 6
[pid    28] fstat(6, {st_mode=S_IFREG|0777, st_size=17, ...}) = 0
...
```

Yukarıdaki sistem çağrılarında `connect` olan satır dikkatimi çekti, orada aslında `/dev/log` bağlantısı yapmaya çalışmış fakat yapamamış. Gerçekten kontrol ettiğimde orada
böyle bir dosya olmadığını görebiliyorum peki neden buraya yazmaya çalışıyor? Bunu da aslında biraz bağlantı tipinden biraz da genel **Unix** türevi sistemlerin mantığından çıkarabiliriz. `AF_UNIX` 
olarak gördüğümüz bağlantı tipi aslında klasik bir dosya değil, bir [Unix Socket](https://en.wikipedia.org/wiki/Unix_domain_socket), ve C kütüphanesinde [syslog](https://www.man7.org/linux/man-pages/man3/syslog.3.html)
mesajlarını yazmak için kullanılan yer. 

Daha detaylı bir inceleme yapmak isteyenler kaynak koda da [bu adresten](https://www.kernel.org/pub/software/network/tftp/tftp-hpa/) indirip göz atabilir ve TFTP sunucusunun loglama yönteminin syslog üzerinden olduğunu görebilir.

## Syslog Mesajlarını Yakalayalım

Sıradan bir Linux sunucusu olsa üzerinde zaten systemd ya da farklı bir syslog daemon yüklü gelirdi ama bu bir container ortamı olduğu için kurulu gelmemiş. Bunu kurup ayarlamasını yapmakla uğraşmaktansa 
hızlı bir çözüm olarak ilgili, sokete bağlanıp mesaj olarak neler geliyor görmek istedim. Bunun için çok sevdiğim ve hayat kurtaran diğer araçlardan olan [socat](http://www.dest-unreach.org/socat/) kullanmaya karar verdim.

```
/ #   socat UNIX-RECVFROM:/dev/log,fork STDOUT
2024/11/20 12:07:55 socat[44] W address is opened in read-write mode but only supports write-only
<29>Nov 20 12:07:55 in.tftpd[43]: RRQ from 192.168.100.33 filename deneme.txt
2024/11/20 12:08:00 socat[46] W address is opened in read-write mode but only supports write-only
<29>Nov 20 12:08:00 in.tftpd[45]: RRQ from 192.168.100.33 filename deneme.txt
2024/11/20 12:08:05 socat[48] W address is opened in read-write mode but only supports write-only
<29>Nov 20 12:08:05 in.tftpd[47]: RRQ from 192.168.100.33 filename deneme.txt
2024/11/20 12:08:10 socat[50] W address is opened in read-write mode but only supports write-only
<29>Nov 20 12:08:10 in.tftpd[49]: RRQ from 192.168.100.33 filename deneme.txt
2024/11/20 12:08:15 socat[52] W address is opened in read-write mode but only supports write-only
<29>Nov 20 12:08:15 in.tftpd[51]: RRQ from 192.168.100.33 filename deneme.txt
```

Yukarıda basit olarak `socat` aracı ile UNIX-RECVFROM kullanarak `/dev/log` tarafına gelen tüm istekleri yakalayıp `STDOUT` yani terminale yazdırdık ve bu şekilde logları görmeye başladık.
Fakat **tftpd** loglarında (socat için gelenleri yok sayabilirsiniz) aslında trafiği analiz ettiğimizde gördüğümüzden fazlasını görmedik diyebiliriz. 

## Deneme Yanılma

Loglarda ilgili dosya talebini aldığını yazıyor, Wireshark paket analizinde de aslında dosyayı gönderdiğini yukarıda görmüştük, bu noktada farklı bir deneme yapmak istedim ve istemci tarafında güvenlik duvarını kapattım.

```
user@client:~# ufw disable
Firewall stopped and disabled on system startup
user@client:~# tftp 192.168.100.30 69
tftp> get deneme.txt
Received 18 bytes in 0.1 seconds
```

Beklemediğim şekilde çalıştı. Eğer bir sunucuya istemci olarak istek atabiliyorsam, yani server tarafına erişimde güvenlik duvar engeli yoksa, sunucu aynı kanal üzerinden dönüş yaptığı için zaten bununla karşılaşmamam gerekiyordu. 
İstemci tarafında bunu yapmayı gerektirmesi pek alışılmış bir durum değil.

## Sunucu İstemci İletişiminin Temelleri

Eğer bir istemci, sunucuya network üzerinden bir paket gönderiyorsa, istemcinin kaynak portu, sunucunun IP adresi ve hedef portu gibi bilgilerle bu paket işletim sistemi tarafından gönderiliyor. Genellikle eğer bu istek için sunucu tarafı bir cevap 
göndermek istiyorsa bunu, istemcinin kaynak portunu kullanarak yapıyor. Çok fazla detay olmasına rağmen işletim sistemleri kullanılan protokole göre UDP/TCP bu açılan bağlantıları tutuyor ve sunucudan genel cevap daha önce 
açtığı bir bağlantı sonucu geldiyse onu kabul edip işlemeye başlıyor.


![Capture 2](/img/tftp-challanges/tftpdump2.png)

Yukarıda görüldüğü gibi, ilk istemci **41102** portunu kullanarak sunucunun standart **69** TFTP portuna istek göndermiş. Normalde sunucunun bu isteğe `69-->41102` olarak yapması gerekirken, sunucu bunun yerine **33437** portunu kullanmış.
Tabi durum böyle olunca aslında zaten eski iletişimin bir parçası deyip izin vermesi gerekirken, sunucudan istemci yönüne yeni bir bağlantı isteği olarak algılayıp engellemiş. Güvenlik duvarı kayıtlarını kontrol ettiğimizde de engellenmiş olduğunu görebiliyoruz.
Tabi bu senaryo ilk başta aklıma gelmediği için biraz uğraştırdı diyebiliriz. 


```
user@client:~# dmesg |grep -i ufw
[1631380.402041] [UFW BLOCK] IN=ens160 OUT= MAC=00:0c:29:a9:6b:29:00:0c:29:52:d6:b6:08:00 SRC=192.168.100.30 DST=192.168.100.33 LEN=50 TOS=0x00 PREC=0x00 TTL=63 ID=46477 PROTO=UDP SPT=45965 DPT=53958 LEN=30
[1631381.403837] [UFW BLOCK] IN=ens160 OUT= MAC=00:0c:29:a9:6b:29:00:0c:29:52:d6:b6:08:00 SRC=192.168.100.30 DST=192.168.100.33 LEN=50 TOS=0x00 PREC=0x00 TTL=63 ID=46478 PROTO=UDP SPT=45965 DPT=53958 LEN=30
[1631383.404338] [UFW BLOCK] IN=ens160 OUT= MAC=00:0c:29:a9:6b:29:00:0c:29:52:d6:b6:08:00 SRC=192.168.100.30 DST=192.168.100.33 LEN=50 TOS=0x00 PREC=0x00 TTL=63 ID=46479 PROTO=UDP SPT=45965 DPT=53958 LEN=30
```

Biraz TFTP [protokolünü](https://en.wikipedia.org/wiki/Trivial_File_Transfer_Protocol) incelediğinizde aslında bunun beklenen şekilde çalıştığını ve bu şekilde bir yapısı olduğunu görebilirsiniz.
Bunu bir grafik ile özetlersek, genellikle protokoller aşağıdaki gibi iletişimde bulunurken

![Capture 3](/img/tftp-challanges/traditional-flow.svg)

TFTP protokolü ise alışılmışın dışında bu şekilde bir iletişim sağlıyor.

![Capture 4](/img/tftp-challanges/tftp-flow.svg)

Özetle işletim sistemi, daha önce açtığı bağlantının kaynak ve hedef port bilgilerini tutuyor ve gönderilen paketlerde aynı iletişimin bir parçası olduğunu anlamak için
client tarafından çıkan paketlerin kaynak portu ne ise, sunucunun ilk hedef portu üzerinden client tarafına cevap dönmesini bekliyor, bu olmayınca yeni bir bağlantı isteği gibi algılayıp,
client tarafında bu porta dışarıdan direk erişim izni olmadığından engelleniyor.

## Komple Güvenlik Duvarını Kapatmak Çözüm Mü?

En azından sorunun ne olduğunu belirlesek de bunu bu şekilde komple güvenlik duvarını istemci tarafında kapatmak mantıklı değil. Biraz araştırdığımızda aslında TFTP için bu bilinen bir durum olduğundan
çözüm olarak birkaç netfilter kernel modülü [yazılmış](https://wiki.nftables.org/wiki-nftables/index.php/Conntrack_helpers), onu yükleyip tekrar deneyelim bakalım sorunumuz çözülecek mi.

```
user@client:# modprobe nf_nat_tftp
user@client:# modprobe nf_conntrack_tftp
user@client:# sysctl net/netfilter/nf_conntrack_helper=1
net.netfilter.nf_conntrack_helper = 1
user@client:# ufw enable
Command may disrupt existing ssh connections. Proceed with operation (y|n)? y
Firewall is active and enabled on system startup
user@client:# modprobe nf_conntrack_tftp
user@client:# tftp 192.168.100.30 69
tftp> get deneme.txt
Received 18 bytes in 0.0 seconds
tftp>
```

## Sonuç

TFTP protokolün nasıl çalıştığını bilmek aslında sorunun çözümüne yardımcı oldu, bildiğim kadarıyla bunun gibi çalışan birkaç farklı protokol daha bulunuyor. 
Neden aynı port üzerinden değil de farklı bir port üzerinden dönüş yaptığı ise farklı bir araştırma konusu, muhtemelen protokolün tasarlandığı tarihte buna özel bir kısıt ya da bir sebep mutlaka vardır,
öğrenip ileride bir güncelleme yapmayı planlıyorum.

## Bonus

Syslog mesajlarını göstermek için `socat` kullanmıştım fakat sonrasında `busybox` araçlarının olduğu container sistemlerde bunun yerine bir araç olduğunu öğrendim, herhangi bir paket eklemeden 
kurulu olarak geliyor ve, yukarıdaki `socat` komutu yerine aşağıdaki gibi bir komutla syslog mesajlarını dinleyip terminale yazdırabilirsiniz.

```
busybox syslogd -n -O - -S -s 200 -b 5 -m 20
```

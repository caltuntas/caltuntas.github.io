---
layout: post
title: "SSH Reverse Tunnel - Pratik Bir Kullanım Senaryosu"
description: "SSH Reverse Tunnel - Pratik Bir Kullanım Senaryosu"
date: 2023-05-17T07:00:00-07:00
tags: ssh
---

Bu hafta potansiyel bir müşterimizle POC oturumu gerçekleştirdik. Oturum sırasında güvenlik duvarı kısıtlamaları senaryomuza engel
olduğu için bunu SSH Reverse Tunnel yöntemi ile aştık. Günlük hayatta SSH ile port yönlendirme oldukça sık kullandığım bir yöntemlerden birisi.
Reverse Tunnel yöntemine ise bugüne kadar pratikte ihtiyacım olmamıştı bu yüzden oldukça işime yarayan tabiri caizse günü kurtaran
bu yöntemi ve benim sorunumu nasıl çözdüğünü paylaşmak istedim. Mutlaka işinize yarayacağını düşünüyorum.

Ürünümüz kullanıcı ağ ortamına kurulup konfigürasyonları yapıldıktan sonra hedef sistemlere gerekli protokoller üzerinden
erişim gerçekleştirip işlemlerini tamamlıyor. Fakat POC ortamında aşağıdaki gibi bir durumla karşılaştık.

![not accessable diagram](http://www.plantuml.com/plantuml/proxy?cache=no&src=https://raw.githubusercontent.com/caltuntas/caltuntas.github.io/main/diagrams/ssh-tunnel1.puml)

Gerekli güvenlik duvarı kurallarının çoğu düzgün ayarlanmış fakat bir sunucu için gerekli kural unutulmuş. Bu sebeple 
ilgili sunucuya 22 portu üzerinden gitmeye çalıştığımızda erişim engeline takıldık ve POC ilerleyemedi. Ama resimde gösterdiğim gibi
test için bize yardımcı olan müşterimiz bu iki ortama da gerekli portlardan erişebiliyor. 

Tam süreç tıkandı derken aklıma SSH Reverse Tunnel kullanımı ile sorunu geçici de olsa çözebileceğimiz aklıma geldi. 
SSH Reverse Tunnel kısaca uzak bilgisayarın erişemediği fakat SSH tünelin açıldığı ortamın eriştiği bir kaynağa bir tünel oluşturarak
ikisinin bu tünel içinden güvenli şekilde haberleşmesini sağlıyor. Yani bu yöntemi kullanarak ilgili kaynağa erişimi tünel üzerinden
aşağıdaki gibi sağlayacağız.

![tunnel diagram](http://www.plantuml.com/plantuml/proxy?cache=no&src=https://raw.githubusercontent.com/caltuntas/caltuntas.github.io/main/diagrams/ssh-tunnel2.puml)

Gelin bunu benzer bir senaryoda uygulayalım ve laboratuvar ortamımızda bulunan uygulama sunucusunu evimde bulunan NAS sunucusu ile haberleştirelim.
Normalde ikisi tamamen birbirinden habersiz erişim mümkün değil. Bunun için aşağıdaki komutla SSH ters tünel oluşturuyorum. Ben MacOS üzerinde çalıştığım için
OpenSSH kullanıyorum fakat bunu Windows üzerinde Putty ile de yapabilirsiniz, sadece komut yerine arayüzden ilgili ayarları yapmanız gerekecek.

```
[mypc] ssh -N -R localhost:22234:172.16.33.234:22 root@192.168.100.30 -vvv
```

Ev sunucusu 172.16.33.234 IP adresine sahip, laboratuvar ortamındaki sunucu 192.168.100.30 adresine sahip. Laboratuvar ortamındaki
sunucunun, kendi üzerinden `localhost:22234` adresi ile evimdeki sunucunun `22` portuna bağlanmasını istiyorum. 

`-N` parametresini sadece tünel oluştursun bunu normal SSH erişimi için kullanmayacağımı belirtmek için kullanıyorum.
`-R` parametresi ters tünel için kullanılıyor, `-vvv` ise mümkün olduğunca bana fazla bilgi versin diye `verbose` seviyesini arttırmak için
kullanılıyor.
 

![ssh tunnel command](/img/sshtunnel/ssh-tunnel-command.png)

Görüldüğü gibi tünel başarıyla oluşturuldu fakat bu aşamada henüz benim bilgisayarım üzerinden evdeki sunuya bağlantı yapılmış değil onu bu şekilde görebiliyorum.
Aşağıdaki komutu kendi bilgisayarımda çalıştırdığımda bana boş çıktı veriyor

```
[mypc] lsof -i @172.16.33.234:22
```

Uzak sunucuda dinlenilen portları kontrol ettiğimde ise aşağıdaki gibi `sshd` işleminin verdiğimiz portu dinlemeye başladığını görebiliyoruz

```
[remoteserver] ss -tulpn | grep 22234
tcp    LISTEN     0      128    127.0.0.1:22234                 *:*                   users:(("sshd",pid=25562,fd=9))
tcp    LISTEN     0      128       [::1]:22234              [::]:*                   users:(("sshd",pid=25562,fd=8))
```

Şimdi aynı uzak sunucu üzerinden evdeki sunucuma bağlanmak için aşağıdaki gibi ssh bağlantısı kuruyorum.

```
[remoteserver] ssh username@localhost:22234
```

Ardından şifre girdiğimde evdeki sunucuma bağlantı yapabildim. Dikkat edin evdeki kişisel bilgisayarım üzerinden bu bağlantıyı yapmamama rağmen
evdeki sunucu üzerindeki bağlantıları aşağıdaki gibi kontrol ettiğimde bağlantımın kişisel bilgisayarım üzerinden açılan tünel üzerinden yapıldığını görebiliyorum.

```
[nasserver] netstat -ant | grep 172.16.33.89
tcp        0     36 172.16.33.234:22        172.16.33.89:59815      ESTABLISHED
```

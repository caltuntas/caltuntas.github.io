---
layout: post
title: "Shell Hileleri - Vim ile Özel Karakterler"
description: "Shell Hileleri - Vim ile Özel Karakterler"
mermaid: false
date: 2024-03-23T07:00:00-07:00
tags: shell vim linux
---

Versiyon güncellemeleri, hata tespiti ya da bakım kapsamında yapılan işler gereği, müşteri ortamlarında bulunan
geliştirdiğimiz ürünün bulunduğu sunuculara bağlanabiliyoruz. Genellikle bu işlemleri müşteri ile birlikte
uzaktan bağlantı ile yapıyoruz, ama çok nadir olsa da bu işlemleri fiziksel olarak ilgili sunucunun
olduğu veri merkezinde de yaptığımız oluyor.

Toplantılar genellikle `Teams, Zoom, AnyDesk` gibi uzak masaüstü yönetim ve haberleşme araçları üzerinden 
yapılıyor. Bunlardan en sevdiğim `AnyDesk` diyebilirim, çünkü bağlantı sonrasında eğer uzaktan kontrol izini
verilirse en sorunsuz ve hızlı çalışanı. Genellikle klavye ile kendi bilgisayarınızda hangi harfi yazmaya 
çalışıyorsanız karşı taraf da aynı harfi alıyor. Fakat `AnyDesk` tarafında yakın zamanda ortaya çıkan güvenlik
[bulgusu](https://anydesk.com/en/public-statement-2-2-2024), daha önce kullanan herkesi korkutmuş durumda artık kimse `AnyDesk` üzerinden bağlantı vermek istemiyor.

Elimizde kalan diğer seçeneklerden `Teams` ya da `Zoom` ile toplantı yapıyorsak ve uzak kontrol verildiyse sıkıntılı dakikalar bizi bekliyor.
Genelde toplantı şu şekilde ilerliyor.

> ... bey/hanım ben basıyorum ama farklı bir karakter çıkarıyor lütfen {,\|,[ tuşuna basabilir misiniz?

Böyle olunca tabi 10 dakika sürecek şeyi 30 dakikada ancak bitirebiliyorsunuz. Diyelim ki bir hata nedeniyle
log kayıtlarında bir inceleme yapmak istiyorsunuz ve sistem docker üzerinde çalışıyor. Aşağıdaki gibi 
bir `one-liner` yardımıyla şuanda aktif ya da kapanmış olan tüm `container` kümesi içinde hata kayıtlarına bakacaksınız.

```
user@server:~# for c in $(docker ps -a -q); do docker logs "$c" 2>&1 | grep "error:"; done
```

`AnyDesk` ile çalışırsanız ne mutlu, direk karşı tarafta genelde sorun çıkmadan yukarıdaki scripti uzak sunucu
üzerinde yazabilirsiniz, hatta kendi bilgisayarınızda yazıp uzak sunucuya `copy-paste` yapabilirsiniz. Ama `Teams, Zoom` 
ikilisinden birine denk gelirseniz, genelde `copy-paste` çalışmıyor ya da kurum politikası tarafından engellenmiş,
geriye tek seçenek uzak sunucuda bunu kendinizin yazması kalıyor. 

Yukarıdaki gibi basit bir scripti hatta bazen daha da basitlerini yazmaya kalkarsanız `shell` scriptlerin vazgeçilmezi
olan `|,{,},&,[,],-,*,/` gibi karakterlerden mutlaka birisini kullanmak zorunda kalıyorsunuz. Bu karakterlerden birini yazacak tuşa kendi
bilgisayarınızda bastığınızda da karşı tarafta bazen alakasız farklı karakterler bazen de hiç olmayan `æß∂ƒğ∑` gibi karakterler çıkabiliyor.
Sonra toplantı yukarıda bahsettiğim dialog şeklinde inanılmaz verimsiz bir şekilde ilerliyor. 

Artık bu durum iyice canımı sıkmaya başlayınca elimizdeki araçları ve tabi ki kadim dostumuz `vim`'i  kullanarak aşağıdaki gibi 
çözüm ürettim.

`Bash, Zsh` gibi shell ortamları bize normalde komutları yazdığınız satırın dışında bunları geçerli editör ile yazmanıza da olanak sağlıyor.
[ctrl-x, ctrl-e](https://www.gnu.org/software/bash/manual/html_node/Miscellaneous-Commands.html#index-edit_002dand_002dexecute_002dcommand-_0028C_002dx-C_002de_0029) kısayolu
ya da [fc](https://en.wikipedia.org/wiki/Fc_(Unix)) komutu ile yazmak istediğiniz kod için size bir editör açılıyor ve orada istediğiniz şekilde 
yazıp kaydedip kapattıktan sonra yazdığınız şey otomatik olarak çalıştırılıyor.

Peki shell satırında değil de editör üzerinde yazmak ne değiştirecek sorusu akla gelebilir, eğer editor `vim` ise çok şey değiştirebilir.
Tabi öncelikle yukarıda bahsettiğim kısayolların editör olarak vim kullanmasını sağlamamız lazım bunun için kullandığımız shell ortamının
baktığı ortam değişkenini ayarlamak gerekiyor. 

```
user@server:~# EDITOR=vim
```

Ardından ister `ctrl-x, ctrl-e` isterseniz `fc` ile komut yazmak için Vim
ortamına geçebilirsiniz. Sonrasında Vim `insert mode` içinde bize `ascii`
tablosundaki sayı karşılığını kullanarak karakter girmemizi sağlıyor.
Detaylar için vim içinde `:h i_CTRL-V_digit` yazdığınızda aşağıdaki açıklama geliyor.

```
With CTRL-V the decimal, octal or hexadecimal value of a character can be
entered directly.  This way you can enter any character, except a line break
(<NL>, value 10).  There are five ways to enter the character value:

first char	mode	     max nr of chars   max value ~
(none)		decimal		   3		255
o or O		octal		   3		377	 (255)
x or X		hexadecimal	   2		ff	 (255)
u		hexadecimal	   4		ffff	 (65535)
U		hexadecimal	   8		7fffffff (2147483647)
```

Yani [ASCII](https://en.wikipedia.org/wiki/ASCII) tablosuna bakarak önce `insert mode` sonra `ctrl-v decimal` değer karşılığını girerek istediğimiz karakterleri yazdırabiliyoruz.

| Decimal | Char | Decimal | Char |
|---------|------|---------|------|
| 33      | !    | 59      | ;    | 
| 34      | "    | 60      | <    | 
| 35      | #    | 61      | =    | 
| 36      | $    | 62      | >    | 
| 37      | %    | 63      | ?    | 
| 38      | &    | 91      | [    | 
| 39      | '    | 92      | \    | 
| 40      | (    | 93      | ]    | 
| 41      | )    | 94      | ^    | 
| 42      | *    | 95      | _    | 
| 43      | +    | 123     | {    | 
| 44      | ,    | 124     | \|   | 
| 45      | -    | 125     | }    | 
| 46      | .    | 126     | ~    | 
| 47      | /    | 64      | @    | 
| 58      | :    | 96      | `    | 


Aşağıda nasıl olduğunu örnek üzerinde çalışırken görebilirsiniz. İlk olarak `ctrl-x, ctrl-e` sonra da `fc`
ile benzer işlemi yapıyorum. Her iki örnekte de `|` karakterini yukarıda bahsettiğim vim yöntemi ile yani 
insert mode içerisinde `ctrl-v 124` ile yapıyorum. 

![server1](https://github.com/caltuntas/caltuntas.github.io/assets/35517929/fb329ab2-ff86-49fe-b34e-a73db0db2d1c)


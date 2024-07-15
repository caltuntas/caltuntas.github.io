---
layout: post
title: "Bit Operasyonları ve Ascii Tablosu"
description: "Bit Operasyonları ve Ascii Tablosu"
mermaid: false
date: 2024-06-20T07:00:00-07:00
tags: c programming encoding bitwise
---

__GOTO Conferences__ konuşmalarını bugüne kadar bizzat katılamasam da fırsat buldukça beğenerek takip etmeye çalışıyorum.
Geçenlerde sanırım çok fazla __shell, terminal, linux__ gibi konularla ilgilendiğim için YouTube karşıma [Plain Text](https://youtu.be/4mRxIgu9R70?si=YfeGG3HwoMxchelO)
adlı videoyu çıkarttı. 

Konuşmanın ilk kısmında genelde herkesin aşina olduğu __ASCII__ tablosu ve onun nasıl ilginç özelliklere sahip olduğundan
bahsetti. Ascii tablosunu uzun süre kullanan bir olarak, bahsettiği şeylerden özellikle harflerin `binary` karşılıklarında
büyük harf, küçük harf gibi ilişkileri ilk defa öğrendim diyebilirim. Neredeyse 50 yıl öncesinde tasarlanmış olan 
bir karakter sisteminin içinde bulunan bu küçük dokunuşlar beni şaşırttı diyebilirim. Adamlar yılları öncesinde neleri düşünmüş
diye içimden geçirmedim değil. Özetle videoyu izlemenizi tavsiye ederim, konuyu fazla dağıtmadan bu yazının ana odağına dönelim.


Diğer sevdiğim, konulardan biri ise, fırsat buldukça, özellikle uzun uçak yolculuklarında, kodlama egzersizleri çözmek. 
Bazen öğrenmek istediğim yeni diller, bazen eski egzotik programlama dilleri, bazen de pasını atmak istediğim ve eski kullandığım
diller ile ilgili bunu yapmaya çalışıyorum. Bunun için farklı bir çok platform var ama en sevdiğim [https://exercism.org/](https://exercism.org/)  diyebilirim.

Bu platform üzerinde test odaklı bir alıştırma mantığı mevcut, size belirli bir problem için problemin detaylarını anlatan bir beni oku dosyası ve
içinde testler veriyor, siz testleri geçtikten sonra kodu platforma gönderip son olarak da orada test edilip bütün senaryoları geçtiğini görüp
isterseniz başkaları ile çözümünüzü paylaşabiliyorsunuz ya da diğer çözümlere göz atabiliyorsunuz.

Bu platform üzerinde bir süredir pasını atmak istediğim C programlama dili egzersizlerini çözüyorum, tam olarak ilk bahsettiğim videoyu izledikten kısa bir süre sonra
egzersizlerin birinde videoda bahsedilen ASCII yapısını kullanabileceğim [Rotational Cipher](https://exercism.org/tracks/c/exercises/rotational-cipher) adlı egzersiz ile karşılaştım.

Egzersizde basit olarak rotasyon tabanlı bir `cipher` metodu yazmanız isteniyor, yukarıdaki linkten detaylarına ulaşabilirsiniz. 
Örnek olarak `omg` ifadesi `ROT5` anahtarı kullanılarak, yani her karakter, büyük küçük hali aynı kalmak şartıyla 5 karakter sonraki karakter 
karşılığı ile değiştiriliyor ve `trl` haline geliyor. 

Basit mantıkla aşağıdaki gibi bir kod yazdım ve ilgi testleri geçti, bu arada basit çözüm ve yaklaşım yazılım işlerinde büyük çoğunlukla 
daha iyidir diyebilirim.

```
#include "rotational_cipher.h"

char *rotate(const char *text, int rotation_key)
{
  char *newtext = malloc(strlen (text) + 1);
  for (size_t i =0; i<strlen(newtext); i++)
  {
    unsigned char chr = newtext[i];
    if (chr >= 'a' && chr <='z')
      newtext[i] = 'a' + (chr - 'a' + rotation_key) % 26;
    if (chr >= 'A' && chr <='Z')
      newtext[i] = 'A' + (chr - 'A' + rotation_key) % 26;
  }
  return newtext;
}
```

Burada belki bilmeyen olursa açıklamam gereken bir kaç ufak nokta olabilir. Öncelikle ASCII tablosunda, `a-z` ile `A-Z` hemen peş peşe gelmiyor, 
yani büyük `Z` harfinden sonra gelen `[\` gibi karakterler var. bu yüzden rotasyon yaparken, `Z` harfinden hemen sonra tekrar `A` dönmesi için 
düz mantık toplama yapamıyoruz çünkü devam eden karakter `A` ile başlamıyor. [Bu linkten](https://www.ascii-code.com/) ASCII tablosunun detaylarını görebilirsiniz, ama konumuz ile
ilgili olan kısmını aşağıya yine de kopyaladım.


| Decimal | Char | Binary   |
|---------|------|----------|
| 65      | A    | 01000001 |
| 66      | B    | 01000010 |
| 67      | C    | 01000011 |
| ..      | ..   | ..       |
| ..      | ..   | ..       |
| 95      | _    | 01011111 |
| 96      | `    | 01011111 |
| 97      | a    | 01100001 |
| 98      | b    | 01100010 |
| 99      | c    | 01100011 |
| ..      | ..   | ..       |
| ..      | ..   | ..       |


Yukarıdaki fonksiyonun yaptığı da aslında basit olarak, verilen yazıyı karakter karakter dolaşarak, eğer ilgili karakter
`a-z` aralığında ise, rotasyon miktarı kadar arttırıp, yerine gelmesi gereken karakteri buluyor, ardından modül 26 yaparak başa dönme durumunu hesaplıyor,
sonrasında ise de yukarıda bahsettiğim gibi tekrar küçük/büyük karakter durumunu korumak için başta küçük harf ise `a` harfi ile tekrar toplama yaparak işlemi sonlandırarak rotasyon edilmiş halini buluyor.

Diğer nokta ise, harflerin toplama, çıkarma ya da karşılaştırma da kullanılması C dilinin
sağladığı bir özellik, C dilinde karakter aslında karşılık geldiği bir sayı gibi
yorumlanıyor, yani `A` ASCII karakter kümesinde `65` olduğu için her türlü matematiksel işlemde bu şekilde kullanabiliyorsunuz.

Aynı işlemin büyük harf durumunu da yukarıda bahsettiğim hemen sonrasında gelmediği için ayrı bir blok içinde yapıyoruz, anlatmaya değer farklı bir detay yok aslında.

Büyük ve küçük harf rotasyon işlemleri çok benzer bu mantığa göre, ben de ilk videoda bahsedilen ASCII tablosunun karakteristik özelliklerini kullanarak içine de biraz `Bit Hacking`
katarak bunu daha kısa ya da farklı bir şekilde yapabilir miyim diye kafa kordum diyebilirim. 

Yukarıdaki ASCII tablosuna bakacak olursanız, benim yıllardır görmediğim ve ilgili video ile fark ettiğim bir konuya dikkatinizi çekeyim. İlgili harflerin `binary` karşılıklarına dikkat ederseniz
`A` harfi `01000001` olarak bellekte tutulurken, `a` ise `01100001` olarak tutuluyor. Alt alta koyduğunuzda farkı daha iyi görebileceksiniz.

- 01000001
- 01100001 

Sadece, beşinci bit farklı, büyük harfler için ilgili bit `0` iken küçük harfler için `1` değerine sahip, ASCII tablosunda bütün harfler için aynı durum geçerli,
bu da bize bit operasyonları kullanarak, büyük küçük harf dönüşümü, rotasyon vs işlemleri yapmaya olanak sağlıyor. 

## Bit Manipülasyonları ve ASCII

Yukarıda binary olarak verdiğimiz `A` harfini örnek olarak `a` harfine dönüştürmek istersek 5 numaralı bit değerini 0 yerine 1 yapmamız yeterli. Bu işlem __Bit Toggling__ olarak adlandırılıyor
ve genelde `XOR` mantıksal operatörü kullanılarak aşağıdaki gibi yapılıyor.

```
x = x ^ (1 << nth)
```

`XOR` operatörü iki bit değeri birbirinden farklı ise `1` aynı ise `0` değerini sonuç olarak veriyor.

Bu ASCII yapısı gereği olduğundan farklı dillerde de aynı sonucu verecektir. Örnek aşağıda bunu kullanan basit bir Javascript kodunu görebilirsiniz.

```
user@computer# node
Welcome to Node.js v16.14.0.
Type ".help" for more information.
> String.fromCharCode('A'.charCodeAt(0) ^ (1 << 5))
'a'
```

Bizim örneğimize geri dönecek olursak , tam olarak büyük küçük harf değişimi yapmasak da yukarıdakine benzer bir mantığı örnekte de kullanabiliriz.
Yapmamız gereken, eğer elimizdeki rotasyon yapacağımız harf küçük ya da büyük ise onun bu durumunu koruyup rotasyon miktarı kadar ileride olan diğer harf ile değiştirmek.
Buna göre aşağıdaki gibi bir kod yazabiliriz.

```
#include "rotational_cipher.h"

char *rotate(const char *text, int shift_key)
{
  char *newtext = malloc(strlen (text) + 1);
  if (newtext == NULL) return NULL;
  strcpy(newtext, text);
  for (size_t i =0; i<strlen(newtext); i++)
  {
    unsigned char chr = newtext[i];
    if (isalpha(chr)){
      unsigned char base = (chr & 1 << 5) + 'A';
      newtext[i] = base + (chr - base + shift_key) % 26;
    }
  }
  return newtext;
}
```

Asıl önemli ifade `(chr & 1 << 5) + 'A';` desek yanlış olmaz. Bu ifade kısaca şunu yapıyor, mantıksal `AND` ifadesi kullanarak aslında elimizde olan karakter değerini 
5 numaralı bit değeri (binary 00100000 , decimal 32) ile işleme sokuyoruz ve ardından `A` yani 65 ile topluyoruz. 

Bu şekilde eğer küçük harf gelirse hatırlarsanız küçük harflerin ASCII tablosundaki 
binary değerlerinin 5 numaralı bit değeri `1` olduğundan elimizde, `karakterin kendi değeri + 32 + 65` gibi bir değer kalıyor bu da küçük harf durumunun korunmasını sağlıyor.
Büyük harf değeri olduğunda ise 5 numaralı bit değeri 0 olacağından yukarıdaki `AND` operasyonu 0 üretecek ve elimizde `karakterin kendi değeri + 0 + 65` kalacak bu da büyük harf durumunu korumamızı
sağlayacak.

Basit bir bit hacking yöntemi ile `if` yapısından kurtulmuş olduk, tabi bunun ne kadar iyi olduğu tartışılır gerçek dünyada buna benzer bir koda sahip olmaktansa basit bir `if-else`
daha anlaşılabilir olacaktır fakat bilgisayarın çalışma mantığında önemli yer tutan ikili/binary sistemi bilmek faydalı diye düşünüyorum, özellikle network programlama yaparsanız bit operasyonlarını
sık sık kullanmak zorunda kalacaksınız. 

## Yukarıdaki Çözümün Sorunları

Karmaşıklık dışında yukarıdaki yaklaşımın gerçek dünyada sorun çıkarabilecek bir çok sıkıntısı bulunuyor. Gerçek dünyada keşke karakter kodlama ASCII kadar basit olsaydı diye düşünüyorum.
Windows/Linux/Unix sistemler arasında dosya taşıdıysanız satır sonu problemleri, encoding problemleri gibi sorunlarla mutlaka uğraşmışsınızdır. 

### ASCII Tablosunda Bulunmayan Karakterler

Karşımıza ilk çıkan sorun gerçek dünyada sadece ASCII kullanılmıyor hatta neredeyse hiç kullanılmıyor diyebiliriz. Çoğunlukla günümüzde ASCII uyumlu ama ondan çok daha geniş karakter kümesini destekleyen 
`UTF` ya da `ISO` gibi karakter setleri kullanılıyor. Bu tarz karakter kümelerinde ASCII uyumlu olsa da, bu uyumluluk sadece 26 karakter için geçerli, mesela Türkçe bir karakteri bu mantıkla küçük harfe çevirmeye kalkarsanız 
işe yaramadığını göreceksiniz.

```
#include <stdio.h>
#include <ctype.h>
#include <string.h>

int main()
{
  char str[] = "ABCŞ";
  for (int i=0; i<strlen(str); i++)
  {
    printf("char[%d]=%c\n",i,(str[i] ^ 1 << 5));
        
  }
  return 0;
}
```

Yukarıdaki kodu derleyip çalıştırdığınızda aşağıdaki gibi çıktı göreceksiniz.

```
char[0]=a
char[1]=b
char[2]=c
char[3]=
char[4]=
```

ASCII tablosunda olan karakterleri düzgün şekilde küçük harfe çevirmesine rağmen, Türkçe `Ş` karakteri yerine iki tane boşluk koydu ve tek karakter olmasına rağmen iki farklı karakter gibi algıladı.
[Bu linkten](https://bidb.marmara.edu.tr/en/use-of-turkish-and-special-characters) görebileceğiniz gibi `Ş` karakteri aslında 2 byte şekilde ifade edilen ve `UTF-8` tablosunda `C59E` değerine sahip olan bir karakter.
Bu yüzden yaptığımız bit operasyonu küçük harfi ile ilgili olmayan alakasız bir bir değeri değiştiriyor ve işe yaramıyor. Kaldı ki, C gibi bir programlama dilinde, bu tarz `UTF-8` gibi karakterler üzerinde işlem yapmanız için
tamamen farklı bir yöntem kullanmanız gerekiyor. Konuyu çok dağıtmamak için bu kısmı atlıyorum. Özetle ASCII tablosu dışındaki karakterler için bu yöntem çalışmıyor.

### ASCII Uyumlu Olmayan Karakter Setleri

Tabi ağırlıklı olarak modern uygulamalarda sadece ASCII kullanılmasa da, kullanılan karakter setleri büyük çoğunlukla ASCII uyumlu yani eski tabloda olan değerler aynı şekilde kullanılıyor yeni karakterler ise farklı değerlere sahip oluyor.
Fakat dünya sadece ASCII karakter kümesinden ya da onun ile uyumlu karakter kümelerinden oluşmuyor. Düşük bir ihtimal olsa da örnek olarak C ile yazdığınız programı hala IBM Mainframe, Unix sistemlerde çalıştırmanız mümkün.
Bunu yaptığınızda ise orada ASCII ile uyumlu olmayan [EBCDIC](https://en.wikipedia.org/wiki/EBCDIC) karakter kodlama yönteminin kullanıldığını görebilirsiniz. 

Örnek olarak `A` karakteri ASCII ya da ASCII uyumlu bir karakter kodlama sisteminde `65` değerine sahipken EBCDIC [içinde](http://www.simotime.com/asc2ebc1.htm) bu değer tamamen farklı `C1` değerine sahip. Yani benzer bir kodu yazıp 
EBCDIC ile çalışan bir sisteme koyarsak düzgün sonuç vermeyecek. Örnek olarak yukarıdaki örneği biraz değiştirip daha da basitleştirelim.

```
#include <stdio.h>

int main()
{
  char str[] = "ABC";
  for (int i=0; i<3; i++)
  {
    printf("char is %c\n",str[i] ^ 1 << 5);
  }
  return 0;
}
```

İçinde herhangi bir Türkçe karakter bulunmuyor, bunu normal şekilde derleyip çalıştırdığımızda aşağıdaki sonucu doğru şekilde verip harflerin küçük harf karşılıklarına gelen karakter kodlarını yazıyor.

```
user@computer# gcc -g main.c
user@computer# ./a.out
char is a
char is b
char is c
```

Aynı kodu sanki bir IBM Mainframe üzerinde çalışacakmış gibi EBCDIC karakter seti kullanacak şekilde derleyerek çalıştıralım. Bunu yaparken sanallaştırma ortamında IBM sistemlerin imajını yükleyip
çalıştırmak mümkün olsa da biraz kolaya kaçıp derleyicinin, bunu simule edecek parametresi olan aşağıdaki parametresini kullandım.

```
-fexec-charset=charset
Set the execution character set, used for string and character constants. The default is UTF-8. charset can be any encoding supported by the system's iconv library routine.
```

```
user@computer# gcc -g -fexec-charset=EBCDIC-US main.c
user@computer# ./a.out
@@l@@l@@l
```

Kodu derledikten sonra iki farklı derleme işleminin içinde gömülü olan karakter değerlerinden emin olmak istedim ve aşağıdaki karşılaştırmayı yaptım

```
user@computer# vimdiff <(xxd mainascii.out) <(xxd mainebcd.out)
00001140: 4142 4300 c745 fc00 0000 00eb 278b 45fc  ABC..E......'.E.                                                           
00001140: c1c2 c300 c745 fc00 0000 00eb 278b 45fc  .....E......'.E.
```

Varsayılan değerleri kullanan derlemede dikkat ederseniz ABC yerine ASCII tablosunda karşılık gelen HEX değerleri(41,42,43) binary içine koymuş.
EBCDIC kullanan derlemede ise, EBCDIC tablosunda karşılık gelen değerleri (C1,C2,C3) koymuş.

ASCII tablosunda olan `ABC` karakterlerini bit operasyonları ile küçük harfe dönüştürmeye çalışmak gördüğünüz gibi pek işe yaramadı ve anlamlı bir sonuç üretmedi, çünkü ilgili harflerin değerleri tamamen farklı.
Çözmeye çalıştığımız egzersiz için bize ASCII ile çalışacağını ön koşul olarak vermişti, ve bit operasyonlarını kullanarak çözmek hoş oldu, fakat gerçek bir projede gördüğünüz gibi, 
Encoding dünyası birçok tuzakla dolu ve oldukça karmaşık bir konu diyebiliriz. Fakat yazılım geliştirenlerin encoding konusunda mutlaka temel seviyede bilgisi olmasının oldukça faydalı olduğunu düşünüyorum.

#### Referanslar

- [The Absolute Minimum Every Software Developer Must Know About Unicode in 2023](https://tonsky.me/blog/unicode/)

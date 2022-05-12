---
layout: post
title: "Test Driven Development"
description: "Test Driven Development"
date: 2007-09-27T07:00:00-07:00
tags: tdd
---

Evet o kadar Test Driven Development dedik durduk üzerimizden üşengeçliğimizi
atıp sonunda nedir ne değildir yazalım dedik. Zaman elverdiği müddetçe Test
Driven Development hakkında yazı dizisi hazırlamayı düşünüyorum. Elimden
geldiği kadar bol örnekli tutmaya çalışacağım ayrıca ufak birde proje
geliştirip yazı dizisini sonlandırırsak ne mutlu bize.

Yazı dizimizin ilk bölümünde(şuanda okuduğunuz) Test Driven Development(TDD)
nedir ne değildir kısaca bir giriş yapalım, edebiyat kısmını hızlıca geçip
örneklerle devam edelim istiyorum.

## Test Driven Development Nedir?
Test Driven Development diğer adlarıyla Test First Development, Test Driven
Design olarak anılmaktadır. İlk olarak Extreme Programming (XP) yazılım
sürecinin oluşturucusu üstad Kent Beck tarafından ortaya atılmıştır.Extreme
programming(XP) ve günümüzdeki birçok Agile(çevik) modern yazılım geliştirme
süreçlerinin kodlama bakımından bel kemiğini oluşturmaktadır.

Test Driven Development’ın dışarıdan adını ilk duyduğunuzda geliştirdiğiniz
yazılımı test etme ile ya da yazılım ekibindeki Tester arkadaşlarla alakalı
olduğunu düşünebilirsiniz fakat gerçekte geliştirilmiş yazılımı test etmekten
ziyade onu geliştirirken kullanılan yöntemidir. Kısaca tanımlarsak kodu
yazmadan önce testlerini yazıyoruz ardından bu testleri geçecek kodu
yazıyoruz.TDD bu şekilde devam eden bir yazılım geliştirme yöntemidir.Bu
testleri kim yazacak? Tabi ki kodu geliştiren yazılımcılar yani biz.

Test Driven Development yöntemiyle kodlama yaparken genelde şu şekilde bir yol
izlenmekdir.

1. Tek satır kod yazmadan kodun testini yaz.
2. Testi çalıştır ve testin geçemediğini (kırmızı çubuğu) gör.
3. Testi geçecek en basit kodu yaz. Ve tüm testlerin geçtiğini ( Ah yeşil çubuk :) ) gör.
4. Kodu düzenle (Refactoring)
5. Tekrar başa dön.

Gördüğünüz gibi çok basit bir mantıkla kodumuzu geliştiriyoruz. Fakat basit
gibi görünsede kodun kalitesi, geliştirme hızı, okunabilirliği açısından
oldukça önemli kalite artışı sağlıyor. Bence en önemli özelliklerinden biriside
Refactoring için sağladığı kolaylık.Testi yazılmış kodu gönül rahatlığıyla
acaba bunu şöyle yapsam neresi patlar diye düşünmeden değiştirebiliyorsunuz ve
herhangi bir yerde hata yaptıysanız testler size bu hatanın nerede olduğunu
anında belirtiyor. Debug kullanmadan yazılım geliştirmenin rahatlığını
yaşıyorsunuz. Ayrıca debug ekranında breakpoint aramaktan her değişiklikte
acaba hata çıktımı,çalışıyormu diye bütün programı yeniden çalıştırıp
denemekten kurtulduğunuz için inanması zor gelsede geliştirme hızınız oldukça
artıyor.

Mesela kendimden örnek vereyim. Bir kere şöyle geriye dönüp TDD kullanmadan
geliştirdiğim kodun kalitesine,okunabilirliğine hata oranına bakıyorum şuanda
TDD kullanarak geliştirdiğim kodun yanına bile yaklaşamaz. Ayrıca toplam
yazılım geliştirme süreme bakıyorum neredeyse %50 oranında arttı diyebilirim.
Ayrıca Test Driven Development size gerçek Object Oriented Programming zevkini
yaşatıyor diyebilirim. Meşhur Design Patterns kitabının yazarı olan Eric
Gamma’nın Test Infected yazısında belirttiği gibi bir kere bulaştımı eski kod
yazma stilinize asla geri dönüş yapamıyorsunuz.

Şimdi bu kadar şeyi test yazarak nasıl yapacağınızı merak ediyor olabilirsiniz.
Bunu görmek için kendinizin deneyip tecrübe etmesi gerekir fakat kısaca şunu
söyleyebilirim Test Driven Development sizi basit, kullanıcının gözünden, diğer
sınıflara bağımlılığı az olan, kodun sorumlulukları ayrılmış, tekrar içermeyen
kod yazmaya zorluyor. Bunlarda kodun kalitesi açısından oldukça önemli
faktörler o yüzden sizde denedikçe ne kadar verimliliğinizin, yazdığınız kod
kalitenizin arttırdığını göreceksiniz.

Tabi TDD tek başına sihirli deynek değil. Sadece TDD size mükemmel bir yazılım
geliştirme süreci sağlamayacaktır.Fakat iyi oturtulmuş bir yazılım sürecinde
Continuous Integration(Sürekli Birleştirme), Integration Tests(Entegrasyon
Testleri), Acceptance Test(Kabul Testleri) ile birlikte kullanıldığında
projenizin üzerindeki gerçek kalite etkisini daha da belirgin
göreceksiniz.Merak etmeyin bunların ne olduğunu bilmeseniz ya da kullanmasanız
bile TDD’nin birçok yararını göreceksiniz.

Öncelikle yukarıda bahsettiğimiz testler Unit Test olarak
adlandırılmaktadır.Bundan başka Integration, Acceptance,Database vb.. teslerde
bulunmaktadır onlarada zaman elverdikçe değineceğiz. İlk olarak biz temel olan
Unit Testleri yazmaya başlayacağız. Yani yazılımın en küçük birimlerini test
eden kısımlara denir. Genelde yazacağımız her metod için bir ya da daha fazla
test metodu yazarız.Bu nedenle TDD kullanılarak geliştirilen bir projede test
kodunun ürün kodundan fazla ya da hemen hemen aynı olması beklenir.

Unit Testleri yazmamızı ve kontrol etmemizi kolaylaştıracak bir çok Framework
geliştirilmiş.Bizde bu araçlardan bize uygun olanını kullanacağız. Nereseyse
her dil için bir xUnit(JUnit,NUnit,DUnit,CppUnit…. ) framework bulunmaktadır.

Ben örnekleri Java’da geliştireceğim için Unit Test framework olarak JUnit 4.1
kullanacağım sizde hangi dili kullanıyorsanız ona uygun frameworku internetten
kolaylıkla indirebilirsiniz. Hepsinin temelinde aynı mantık olduğu için bu
yazıda yazıdaki küçük örneği hepsinde uygulayabilirsiniz. Ayrıca ben IDE olarak
IntelliJ kullanıyorum neredeyse tüm Java IDE’lerinde Unit Test entegrasyonu
bulunmaktadır yani JUnit kurulumu için fazla uğraşmanıza gerek
kalmayacaktır.Lafı fazla uzatmadan hemen işe koyulalım ve örneğimize
başlayalım.

### Örnek

Örneğimizde verilen listedeki en büyük sayıyı bulan küçük bir kod geliştirmek
istiyoruz. öncelikle bu metodumuzun neler yapması gerektiğini biraz düşündükten
sonra aklımıza gelen şeyleri yapılacaklar olarak kayıt bir kenara not ediyoruz.
mesela benim şuanda aklıma gelenler.

* 4,5,6 verdiğimiz zaman bize en büyük olarak 6 bulmalı
* 3,7,5 verdiğimiz zamanda 7 bulmalı
* -4,-7,-9 verdiğimiz zaman bize -4 bulmalı

Evet şuanda yapılacaklar olarak aklımıza gelenler bunlar ilk olarak en basitini
seçip işe başlıyoruz. Mesela ilk maddeyi seçip test kodumuzu yazmaya
başlayalım. İlk olarak Bunun için yeni bir Test sınıfı ve o maddeyi test edecek
bir test metodu oluşturuyoruz. Dikkat edin daha tek bir satır gerçek kod
yazmadan bu test sınıfını ve test metodlarını oluşturuyoruz burası önemli. Bunu
neden böyle yaptığımıza daha sonra değineceğim.

```
public class EnBuyukBulucuTest {

    @Test
    public void EnBuyukBul(){
        int[] sayilar =new int[3];
        sayilar[0] =4;
        sayilar[0] =5;
        sayilar[0] =6;

        assertEquals(6,EnBuyukBulucu.enBuyukSayi(sayilar));
    }
}
```

Şimdi compile edelim. Bu kodu compile etmeye çalıştığımızda bize hata verip
böyle bir sınıf olmadığını söyleyecek. Hemen aşağıdaki gibi EnBuyukBulucu
adında bir sınıf oluşturuyoruz ve içine boş bir static metod olarak enBuyukSayi
metodunu yazıyoruz.

```
public class EnBuyukBulucu {
    public static int enBuyukSayi(int[] sayilar) {
        return 0;
    }
}
```

Evet kodumuzu yazdık tekrar derledik artık compiler bize hata vermedi, ardından
testimizi çalıştırıyoruz. Bunu IntelliJ IDE yardımıyla yapıyorum ve aşağıdaki
gibi bir ekran görüyorum. Testlerin IDE’den nasıl çalıştırıldığı hakkında
kullandığınız IDE için kolaylıkla bilgi edinebilirsiniz burada değinmeyeceğim.

![Result](/img/testdriven/test1.jpg)

Evet testi yazdık, compile etmesi için gerekli olan kodu yazdık, şimdi testi
geçecek en basit kodu yazacağız.

```
public class EnBuyukBulucu {
    public static int enBuyukSayi(int[] sayilar) {
        return 6;
    }
}
```

Biraz şaşırmış olabilirsiniz fakat gerçekten yeşil çubuğu ne kadar kısa sürede
görebilirsek o kadar faydamıza o yüzden testi geçecek en basit kod şuanda 6
geriye döndürmek olduğu için onu yazıp testimizi tekrar çalıştırdığımızda
aşağıdaki gibi bir ekran görüyoruz.TDD kod geliştirirken en mutlu olacağınız
anlardan biri tüm testlerin geçip etrafı yeşil çubuklarla gördüğünüz an
olacaktır işte o anlardan biri :) 

![Result](/img/testdriven/test2.jpg)

* 4,5,6 verdiğimiz zaman bize en büyük olarak 6 bulmalı
* 3,7,5 verdiğimiz zamanda 7 bulmalı
* -4,-7,-9 verdiğimiz zaman bize -4 bulmalı

Geçtiğimiz testleri yukarıdaki gibi tek tek kara listeden siliyoruz. Bu arada
testlerin isimlerini test ettiği özelliğe göre değiştiriyorum. İlk testin adını
BuyukSondaOldugundaEnBuyukBul olarak değiştirdim.Sıra listedeki ikinci
testimizi yazmaya geldi. Aşağıdaki gibi testi yazıyoruz.

```
   @Test
    public void BuyukOrtadaOldugundaEnBuyukBul(){
        assertEquals(7,EnBuyukBulucu.enBuyukSayi(new int[]{3,7,5}));
    }
```

Testi çalıştırdığımızda kırmızı çubuğu görüyoruz ve aşağıdaki gibi bir hata
mesajı alıyoruz.


java.lang.AssertionError: expected:<7> but was
    at org.junit.Assert.fail(Assert.java:69)
    at org.junit.Assert.failNotEquals(Assert.java:314)
//.............

Artık burada return 6 gibi bir üçkağıt yapamadığımız için biraz gerçek kod
yazmanın vakti geldi. Testleri geçmek için tekrar iş başına koyuluyoruz. Bu iki
testi geçmek için benim aklıma ilk gelen en basit kodu aşağıdaki gibi yazdım.

```
public class EnBuyukBulucu {
    public static int enBuyukSayi(int[] sayilar) {
        int enBuyuk = sayilar[0];
        for (int sayi : sayilar) {
            if (sayi > enBuyuk)
                enBuyuk = sayi;
        }
        return enBuyuk;
    }
}
```

Tekrar iki testi birden çalıştırdım aşağıda gözüktüğü gibi iki testi geçip
yeşil çubuğu gördüm. (Bu arada ikide bir yeşil çubuk deyip duruyorum.Reklamdaki
gibi Yakalayın yeşil ışığı hesaplı parlak bulaşığı gibi oldu :) )

![Result](/img/testdriven/test4.jpg)

Yapılacaklar listemizi tekrar gözden geçirip test ettiğimiz özellikleri
çiziyoruz.Bu arada aklıma yeni testler geliyor ve onlarıda listeye eklemek
istiyorum.

* 4,5,6 verdiğimiz zaman bize en büyük olarak 6 bulmalı
* 3,7,5 verdiğimiz zamanda 7 bulmalı
* -4,-7,-9 verdiğimiz zaman bize-4 bulmalı
* Sınıf elemanlı liste verdiğimiz zaman hata fırlatmalı
* Null verdiğimiz zaman hata fırlatmalı

Evet listedeki hoşuma giden diğer test edilecek olan 3. özelliği seçiyorum ve
tekrar test yazmaya başlıyorum.

```
@Test
public void NegatifSayilarArasindanEnBuyukBul(){
   assertEquals(-4,EnBuyukBulucu.enBuyukSayi(new int[]{-4,-7,-9}));
}
```

Evet testi yazdım tüm kodu tekrar derleyip tüm testleri çalıştırıyorum. Ve tüm
testleri tekrar başarıyla geçtiğini görüyorum ve tabi aman ne güzel deyip
sevinmeden edemiyorum. Bu arada listeyi unutmayıp test ettiğim özelliği çizip
yeni test senaryoları ekliyorum.

* 4,5,6 verdiğimiz zaman bize en büyük olarak 6 bulmalı
* 3,7,5 verdiğimiz zamanda 7 bulmalı
* -4,-7,-9 verdiğimiz zaman bize-4 bulmalı
* Sınıf elemanlı liste verdiğimiz zaman hata fırlatmalı
* Null verdiğimiz zaman hata fırlatmalı
* -4,0,-9 verdiğimiz zaman 0 bulmalı

Şimdi test etmek için yukarıdaki listeden 5. maddeyi seçtim ve test kodunu
yazıyorum ve testi çalıştırıyorum..

```
@Test
    public void NegatifSayilarVeSifirArasindanEnBuyukBul(){
        assertEquals(0,EnBuyukBulucu.enBuyukSayi(new int[]{-4,0,-9}));
    }
```

Ve bütün testlerin geçtiğini tekrar görüyorum listeyi tekrar gözden geçirelim.

* 4,5,6 verdiğimiz zaman bize en büyük olarak 6 bulmalı
* 3,7,5 verdiğimiz zamanda 7 bulmalı
* -4,-7,-9 verdiğimiz zaman bize-4 bulmalı
* Sınıf elemanlı liste verdiğimiz zaman hata fırlatmalı
* Null verdiğimiz zaman hata fırlatmalı
* -4,0,-9 verdiğimiz zaman 0 bulmalı

Yukarıdaki listeden tekrar gözüme kestirdiğim bir testi yani 4. sıradaki testi
seçip yazmaya başlıyorum aşağıdaki gibi test kodumu yazdım.

```
@Test(expected = IllegalArgumentException.class)
    public void BosSayiListesindeHataFirlat(){
        assertEquals(0,EnBuyukBulucu.enBuyukSayi(new int[]{}));
    }
```

Ve testi çalıştırdığımda aşağıdaki gibi hata mesajı alıyorum ve testi
geçemiyorum.


java.lang.Exception: Unexpected exception, expected java.lang.illegalargumentexception but
was java.lang.arrayindexoutofboundsexception
at org.junit.internal.runners.TestMethodRunner.runUnprotected(TestMethodRunner.java:91)
at org.junit.internal.runners.BeforeAndAfterRunner.runProtected(BeforeAndAfterRunner.java:34)
//..................

Bu testi geçmek için kodumuzu tekrar düzenleyip aşağıdaki gibi değiştiriyorum.

```
public class EnBuyukBulucu {
    public static int enBuyukSayi(int[] sayilar) {
        if(sayilar.length==0)
            throw new IllegalArgumentException("Geçersiz sayı listesi!");
        int enBuyuk = sayilar[0];
        for (int sayi : sayilar) {
            if (sayi > enBuyuk)
                enBuyuk = sayi;
        }
        return enBuyuk;
    }
}
```

Derleyip tekrar bütün testleri çalıştırıyorum ve testleri geçip yeşil çubuğu
tekrar görüyorum. Listeme tekrar döndüm test ettiğim özelliğe çizik atıyorum.

* 4,5,6 verdiğimiz zaman bize en büyük olarak 6 bulmalı
* 3,7,5 verdiğimiz zamanda 7 bulmalı
* -4,-7,-9 verdiğimiz zaman bize-4 bulmalı
* Sınıf elemanlı liste verdiğimiz zaman hata fırlatmalı
* Null verdiğimiz zaman hata fırlatmalı
* -4,0,-9 verdiğimiz zaman 0 bulmalı

Kalan maddelerden 5. sırada olan Null içeren maddeyi seçiyorum ve tekrar
testini yazmaya başlıyorum.Ve aşağıdaki gibi test kodumu yazdım.

```
@Test(expected = IllegalArgumentException.class)
    public void NullListedeHataFirlat(){
        assertEquals(0,EnBuyukBulucu.enBuyukSayi(null));
    }
```

Çalıştırdığında aşağıdaki ekrandaki gibi testi geçemediğini ve çıkan hatayı
görüyorsunuz.

![Result](/img/testdriven/test5.jpg)


java.lang.Exception: Unexpected exception, expected java.lang.illegalargumentexception but
was java.lang.nullpointerexception
at org.junit.internal.runners.TestMethodRunner.runUnprotected(TestMethodRunner.java:91)
at org.junit.internal.runners.BeforeAndAfterRunner.runProtected(BeforeAndAfterRunner.java:34)
//......

Yukarıdaki hataya bakacak olursanız JUnit bize IllegalArgumentException
hatasını beklediğimizi fakat NullPointerException hatası fırlatıldığını
söylüyor. Biz kodumuzun zaten Null değerine karşı hata atmasını istemiştik
fakat neden testin başına NullPointerException olarak değiştirmedik?Öyle
yapsaydık aslında bu testi hiç kod yazmadan geçmiş olurduk. Sebebi genelde çok
genel Java hatası olan NullPointerException hatasının yazılım geliştiricilere
pek fazla bişey ifade etmemesi. Düşünsenize programı ürün olarak çıkardınız ve
ekranda hata detayında detaylı bir hata mesajı görmekmi daha iyi olur yoksa
NullPointerException mı?O yüzden hata fırlattığımızda anlamlı programcılar için
sorunun çözümüne yardımcı hatalar fırlatmaya özen göstermeliyiz. Lafı fazla
uzatmadan bu testide geçecek kodu aşağıdaki gibi yazıyoruz.

```
public class EnBuyukBulucu {
    public static int enBuyukSayi(int[] sayilar) {
        if(sayilar==null || sayilar.length==0)
            throw new IllegalArgumentException("Geçersiz sayı listesi!");

        int enBuyuk = sayilar[0];
        for (int sayi : sayilar) {
            if (sayi > enBuyuk)
                enBuyuk = sayi;
        }
        return enBuyuk;
    }
}
```

Evet kodumuzu derledik ve bütün testleri tekrar çalıştırdık ve hepsinin
geçtiğini görüyoruz.Listeyi tekrar gözden geçiriyoruz ve tamamladığımızı
görüyoruz.

* 4,5,6 verdiğimiz zaman bize en büyük olarak 6 bulmalı
* 3,7,5 verdiğimiz zamanda 7 bulmalı
* -4,-7,-9 verdiğimiz zaman bize-4 bulmalı
* Sınıf elemanlı liste verdiğimiz zaman hata fırlatmalı
* Null verdiğimiz zaman hata fırlatmalı
* -4,0,-9 verdiğimiz zaman 0 bulmalı

Aslında aklıma birkaç test edilecek durum daha geliyor fakat bu kadar testin
giriş yazısı için yeterli olduğunu düşünüyorum.Sizde yazdığınız testlerde bütün
durumları test ettiğinizi düşünüyorsanız bu şekilde bırakabilirsiniz. Başka bir
yazıda neleri test etmeliyiz hakkında birkaç şey yazmayı planlıyorum.

Küçük bir örnek olsada Test Driven Development pratiği açısından küçük
adımlarla nasıl kod geliştirildiğine baktık. Burada küçük adımlar olması
gerçekten önemli büyük adımlar ile birkaç özelliği birden test etmeye
çalıştığınızda kontrolü kaybedip bol bol insanın sinirini bozan kırmızı
çubuklar görebiliyorsunuz o yüzden küçük küçük testler yazmaya önem gösterin.
TDD hakkında giriş yazımız umarım faydalı olmuştur.

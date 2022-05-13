---
layout: post
title: "Refactoring : Decompose Conditional"
description: "Refactoring : Decompose Conditional"
date: 2007-07-23T07:00:00-07:00
tags: refactoring
---

Merhaba bu makalede sizlere nesneye yönelik yazılım tasarımının temel
prensiplerinden olan Dependency Inversion Principle(DIP) hakkında bilgi verip
ufak bir örnekler anlatmaya çalışacağım.Türkçe olarak ifade etmeye çalışırsak
buna bağımlılığın ters çevrilmesi diyebiliriz.

Klasik prosedürel programlamada stilinde geliştirilen yazılımlarda genellikle
üst seviyeli modüller, sınıflar vb.. alt seviyeli modüllere bağımlıdır. Bunun
en önemli dezavantajlarından biriside alt seviyeli modüller ya da sınıflar daha
sık değişebilir ve de bu değişimden de üst seviyeli modüller etkilenir. Bu
değişimin sonucunda üst seviyeli modüllerde kod içerisinde değişiklik yapmak ve
zincirmele olarak tüm modülleri derleyip yayınlamak gerekir. Sonuçta ufak
değişikliklerden bile en üst seviyeye kadar etkilenebilen yönetilmesi zor bir
model oluşur. Bu tarz modeller modüler olarak tekrar kullanılabilir gözüksede
üst seviyeden alt seviyeye kadar bağımlılık zinciri olduğu için tekrar
kullanmak istediğimiz modülle birlikte diğer modülleri de dahil etmemiz
gerekir.Bu da bize gerçek anlamda bir tekrar kullanılabilirlik sağlamaz çünkü
gerçek anlamda birbirinden soyutlanmış modüller yoktur. Malesef günümüzde
modern birçok nesneye yönelik programlama dilinde dahi bu şekilde yazılım
geliştirilmektedir çünkü kullandığımız programlama dilinin nesneye yönelik
olması bizim nesneye yönelik yazılım geliştireceğimiz anlamına gelmez. Aşağıda
örnek olarak prosedürel yöntem ve Dependency Inversion Principle(DIP) yöntemi
ile tasarlanmış modelleri görebiliriz.

![Classical](/img/dependencyinversion/procedurallayers-21.jpg)
![Inverted](/img/dependencyinversion/diplayer-41.jpg) 

Yazılım geliştirmede genellikle Tekrar Kullanılabilirlik ve Esneklik terimleri
sıkça duyarız. Peki gerçekten bu terimler bize ne ifade eder? Tekrar
kullanılabilir ve esnek yazılımları nasıl geliştirebiliriz ?Bu gibi soruların
cevabı profosyonel yazılım geliştirmede oldukça önemlidir. Önce bağımlılık ve
tekrar kullanılabilirlik ile başlayalım.

Bağımlılık teriminide kısaca özetlersek bir sınıfın başka bir sınıfa bağımlı
olması yani bir sınıfın çalışması için başka bir sınıfa ihtiyaç duymasıdır diye
açıklayabiliriz Yandaki şekilde gördüğümüz gibi üst seviyeli bir katman alt
seviyeli katmanı (sınıfları,arayüzler… olabilir ) kullandığı için burada üst
seviyeli katmanımız alt seviyeli katmana bağımlı diyebiliriz. Tekrar
kullanılabilirlik terimine gelince; ilk olarak bir sınıfın yazılıp projenin
çeşitli yerlerinde kullanılması aklımıza gelir fakat gerçek anlamda tekrar
kullanım yazdığımız bir kod, üst seviyeli bir kütüphane diğer projelerde koduna
dokunulmadan kullanılabiliyosa bunu tekrar kullanılabilir modül ya da yazılım
olarak tanımlayabiliriz. Bunuda iyi tasarlanmamış yazılımlarda sınıfların
birbirine olan bağımlılığı yüzünden genellikle yapamayız.

İşte bu noktada daha esnek ve yeniden kullanılabilir modüller geliştirebilmek
için uygulanması gereken önemli bir yazılım prensibi olan Dependency Inversion
Principle(DIP)(Bağımlılığın Ters çevrilmesi) devreye giriyor. Bu yöntemi kısaca
açıklarsak;

Üst seviyeli modüller,sınıflar vb.. alt seviyeli sınıflar, modüllere bağımlı
olmamalıdır. Alt seviyeli modüller üst seviyeli modüllere(modüllerin
arayüzlerine) bağımlı olmalıdır. Buna kısaca Dependency Inversion (bağımlılığın
ters çevrilmesi) deriz.

Bunu da şekilde gördüğümüz gibi üst seviyeli bir modül kendi arayüzünü
tanımlayarak bu arayüzü kullanır. Bu arayüz abstract ya da interface sınıflar
olabilir. Ardından alt seviyeli modüller üst seviyeli modülün arayüzünü
uygular. Böylece üst seviyeli modülümüz alt seviyeli detaylarla ilgilenmeden
onlardanki değişimlerden etkilenmeden kullanılabilir. Üst seviyeli modülümüz
bir arayüze bağımlı olduğu için ve arayüzde genellikle değişmeyeceği için
arayüzü gerçekleyen (implemention) sınıflar değişse dahi aynı kalacaktır.
Günümüzdeki frameworklerin tasarlanmasında kullanılan temel prensiplerden biri
budur.

Bu kadar laf kalabalığından sonra biraz sıkılmış olabilirsiniz.Ufak bir örnekle
sıkıntınızı alıp işe koyulalım:) Örnek senaryomuz şöyle olsun:

Geliştirdiğimiz bir yazılımda işyerimizle alakalı kayıtları işliyoruz.
Programımızın işyerindeki çalışanlara ait çeşitli formatlarda rapor sunması
gerekiyor. Şuanda bizden istenen excel ve word formatından raporları sunması.
Fakat ileride değişik türden formatta raporlarıda kolaylıkla sunması kesinlikle
istenecektir. Unutmayın müşteri istekleri bitmez:) Bu işlemleri yaptığımız bir
çalışan raporları sayfamız var. Bu sayfadan herhangi bir çalışanı seçip onla
alakalı çeşitli formattaki raporları alabiliyoruz. Bu isteklere göre
tasarladığımız sınıflarımızın UML diyagramını aşağıda görebiliriz.

![DIP2](/img/dependencyinversion/dependency-2.jpg)

Yukarıdaki şekilde de gördüğümüz gibi Calisan rapor forumumuz CalisanRaporFormu
sınıfı üst seviliyeli bir işi yapan sınıftır. CalisanWordRaporu ve
CalisanExcelRaporu ise bu üst seviyeli işlemin nasıl yapılacağını değişik
şekillerde uygulayan alt seviyeli detaylarla ilgilenen sınıflardır.
CalisanRaporFormu bu sınıfları direkt olarak kullanır. Yani CalisanRaporFormu
sınıfı alt seviyeli sınıflara direk olarak bağımlıdır onlarda meydana gelecek
değişimlerden etkilenecek ve tekrar derlenmek zorunda kalacaktır. Bu şekilde
tasarlanmış yazılımlığımızın kodları kabaca aşağıdaki gibi olur. Kodlara
baktığımızda ilk olarak if else yapısı dikkatinizi çekmiştir. Genellikle
kodunuzda buna benzer kısımları görürseniz büyük ihtimalle refactoring(yeniden
biçimlendirme) yapmanızda fayda vardır. İyi şekilde tasarlanmış yazılımlarda
genellikle if-else ve switch-case cümleleri kodun içinde fazla bulunmaz. Bunu
da aklımızda bulundurmamızda fayda var. Aşağıda buna örnek bir dizi sınıf
tasarımı verilmiştir.


```
public class CalisanRaporFormu {
        private List calisanlar;
        private Calisan seciliCalisan;
        private CalisanWordRaporu wordRaporu =new CalisanWordRaporu();
        private CalisanExcelRaporu excelRaporu =new CalisanExcelRaporu();

        public CalisanRaporFormu(){ }

        public void SeciliCalisanaAitRapor()
        {
                if(raporTipi=="Word")
                        wordRaporu.RaporOlustur(seciliCalisan);
                else if(raporTipi=="Word")
                        excelRaporu.RaporOlustur(seciliCalisan);
        }
}

public class Calisan {
        private string adi;
        private int maas;
        private string soyadi;
        private int mesaiSaati;
        public Sirket m_Sirket;

        public Calisan(){ }

        public int MesaiUcretiHesapla(){ }

        public string adi{
                get{return adi;}
                set{adi = value;}
         }

         public int maas{
                get{return maas;}
                set{maas = value;
         }
}

public class CalisanWordRaporu {
      public CalisanWordRaporu(){

      }

       public void RaporOlustur(Calisan calisan){
            //raporlama ile alakalı kodlar....
      }
}

public class CalisanExcelRaporu {
      public CalisanExcelRaporu(){

      }

       public void RaporOlustur(Calisan calisan){
            //raporlama ile alakalı kodlar....
      }
}
```

Yukarıdaki kodlar senoryamuzdaki bizden istenenleri gerçekleştiriyor.
Müşterimide yazılımı teslim ettik herşey gayet güzel çalışıyor. Fakat beklenen
kara gün geldi müşteri yeni isteklerle karşımıza çıktı:) Bunlardan senaryomuzda
biraz da olsa bahsetmiştik.Bunlardan birtanesi senaryomuzda bizden istenen
değişik formatta rapor çıktısı sunmasıydı ve müşteri bizden Pdf formatındaki
raporları da sisteme eklememizi söyledi. Fakat bundan sonra yapılacak
değişimler için önümüze birkaç problem çıkıyor. Yeni bir çalışan rapor
formatını sisteme nasıl ekleriz? Bunun için eski kodlarımızın içini didiklemeye
başladık ve bu işlemin CalisanRaporFormu sınıfı içinde yapıldığını gördük.
Hemen kolları sıvadık başladık yeni rapor formatını sistemimize eklemeye.Sonra
bütün kodlarımızı tekrar derleyip yeni halini müşterimize gönderdik.Değişin
CalisanRaporFormu sınıfımız ve yeni eklenen Pdf raporu sınıfımız aşağıdaki
şekilde olacaktır.

```
public class CalisanRaporFormu {
        private List calisanlar;
        private Calisan seciliCalisan;
        private CalisanWordRaporu wordRaporu =new CalisanWordRaporu();
        private CalisanExcelRaporu excelRaporu =new CalisanExcelRaporu();

        private CalisanPdfRaporu pdfRaporu =new CalisanPdfRaporu();

        public CalisanRaporFormu(){ }

        public void SeciliCalisanaAitRapor()
        {
                if(raporTipi=="Word")
                        wordRaporu.RaporOlustur(seciliCalisan);
                else if(raporTipi=="Word")
                        excelRaporu.RaporOlustur(seciliCalisan);
                else if(raporTipi=="Pdf")
                        pdfRaporu.RaporOlustur(seciliCalisan);
        }
}

public class CalisanPdfRaporu {
      public CalisanPdfRaporu(){

      }

       public void RaporOlustur(Calisan calisan){
            //raporlama ile alakalı kodlar....
      }
}
```

Yukarıda gördüğümüz gibi ufak bir değişiklik sistemin birçok yerinde değişiklik
yapmamızı mecbur kılıyor ve bütün projeyi derleyip tekrar yayınlamamızı
gerektiriyor. Kaldı ki müşterinin istekleri hiç bitmeyeceği için:) her yeni
rapor formatında ya da programın değişik yerlerinde bu şekilde istekler için
tekrar aynı işlemleri yapmak zorunda kalacağız en azından yukarıdaki gibi
if-else cümleleri kodumuzu istila edecek bu da yazılımın yönetimini,
yayınlanmasını, değişiklik eklemeyi ve yeniden kullanımız zorlaştıracak.
Sistemimizi birde Dependency Inversion prensibine göre baştan tasarlayalım ve
ardından bize sağladığı avantajlara bakalalım. Bunu yapmak için baştada
bahsettiğimiz gibi bağımlılığı ters çevireceğiz. Yani CalisanRaporFormu
sınıfımız alt raporlama sınıflarına bağımlı olmayacak kendi arayüzünü
tanımlayacak ve yapacağı işlemlerde onu kullanacak. Ardından alt seviye
sınıflar bu arayüzü uygulayarak CalisanRaporFormu sınıfımızın arayüzüne bağımlı
olacak. Yeniden tasarlanmış sınıflarımızın UML diyagramı ve kodları aşağıdaki
gibi olur.

![DIP2Again](/img/dependencyinversion/dipyeniden-2.jpg)

```
public class CalisanPdfRaporu : ICalisanRaporu{
      public CalisanPdfRaporu(){

      }

       public void RaporOlustur(Calisan calisan){
            //raporlama ile alakalı kodlar....
      }
}

public class CalisanExcelRaporu : ICalisanRaporu{
      public CalisanExcelRaporu(){

      }

       public void RaporOlustur(Calisan calisan){
            //raporlama ile alakalı kodlar....
      }
}

public class CalisanWordRaporu : ICalisanRaporu{
      public CalisanWordRaporu(){

      }

       public void RaporOlustur(Calisan calisan){
            //raporlama ile alakalı kodlar....
      }
}

public class CalisanRaporFormu {
        private List calisanlar;
        private Calisan seciliCalisan;
        private ICalisanRaporu calisanRaporu;

        public CalisanRaporFormu(ICalisanRaporu calisanRaporu)
       {
               this.calisanRaporu = calisanRaporu;
       }

        public void SeciliCalisanaAitRapor()
        {
                this.calisanRaporu.RaporOlustur(seciliCalisan);
        }
}
```

Yukarıda yeni şekilde tasarladığımız kodlarda da gördüğümüz gibi artık üst
seviyeli bir sınıfımız olan CalisanRaporFormu sınıfımız alt seviyeli
sınıflardan olan CalisanPdfRaporu vb.. sınıflara bağımlı değildir, sadece kendi
arayüzünü tanımlamış ve işlemlerinde bu arayüzü kullanmıştır. Alt seviyeli
sınıflar ise CalisanRaporFormu arayüzü olan ICalisanRaporu arayüzünü
CalisanRaporFormu sınıfına, onun kullandığı arayüze bağımlı olmuşlardır. Bu
şekilde bağımlılığı ters çevirmiş olduk.Yukarıdaki kodları gördüğünüzde
aklınıza CalisanRaporFormu sınıfının hangi rapor formatı ile çalışacağını
nerden bileceği gelebilir. Bunu gördüğünüz gibi CalisanRaporFormu yapıcısında
hangi rapor formatı ile çalıştığını alıyor. Genelde bu tür işlemler herbiri
ayrı bir makale konusu olan Factory Tasarım Kalıbı ve Inversion Of Control
(IoC) denilen tekniklerle yapılır. Şuanda kafanız o kısımda karışmasın diye
deyinmek istemedim ayrı bir makalede bu konulara deyinmeye çalışacağım. Yeni
şekilde tasarlanan kodun avantajlarına bakarsak gördüğümüz gibi
CalisanRaporFormu artık kendi arayüzü uygulayan hangi tür rapor olursa olsun
kod içinde hiçbir değişiklik yapmadan kullanabileceğiz. Tabi kodun içindeki
if-else ifadeleri kalktığı için kodunda sadeleştiğini görüyoruz. Ayrıca bundan
sonraki yeni rapor türleri için CalisanRaporFormu sınıfını tekrar derlemek
zorunda değiliz çünkü bu sınıf ICalisanRaporu arayüzünü kullanıyor ve bu arayüz
değişmedikçe tekrar dermemize gerek kalmayacak. Müşteriye sadece yeni
eklediğimiz rapor formatı sınıflarını vermemiz yeterli olacaktır. Artık
CalisanRaporFormu bizim için ayrı bir modül oldu. Değişik projelerde onun
arayüzünü uygulayan herhangi bir sınıfla rahatlıkla çalışabilir. Tabi onu
kütüphane yapıp aynı namespace içine ICalisanRaporu arayüzünüde eklemeyi
unutmayalım. Paket yapımızda aşağıdaki gibi olur. Artık müşteride bulunan
CalisanRaporu paketi(kütüphane,dll) yeni rapor formatı ekleme işlemleri için
değişmeyecektir. Sadece RaporFormarlari paketine yeni rapor formatını ekleyerek
tekrar derleyip müşteriye vermemiz yeterli olacaktır.

![DIPPackage](/img/dependencyinversion/dippackage-2.jpg)

Gördüğünüz gibi ufak bir örnekle de olsa önemli bir tasarım prensibinin bize
sağladığı avantajları oldukça önemli. Yeniden kullanılabilir modüller ve
framework’ler tasarlamanın temel prensiplerinden biri olan bu tasarım prenbini
ufak bir örnekler inceledik umarım sizler için faydalı olmuştur. Tekrar
görüşmek dileğiyle…

---
layout: post
title: "TDD : Mocks, Stubs and Two Smoking Barrels"
description: "TDD : Mocks, Stubs and Two Smoking Barrels"
date: 2008-09-21T07:58:29+00:00
tags: general
---

İçerik

  * [Giriş](##Giriş)
  * [Test Etmesi Zor Olan Kodlar](##Test-Edilmesi-Zor-Olan-Kodlar)
  * [Senaryo : Mail Raporu Oluşturma](##Senaryo-:-Mail-Raporu-Oluşturma)
  * [Single Responsibility Prensibinin Uygulanması](##Single-Responsibility-Prensibinin-Uygulanması)
  * [Dependency Inversion Prensibinin Uygulanması](##Dependency-Inversion-Prensibinin-Uygulanması)
  * [Stub Nesneler ile Test Edilmesi](##Stub-Nesneler-ile-Test-Edilmesi)
  * [El ile Yazılmış Mock Nesneler İle Test Edilmesi](##El-ile-Yazılmış-Mock-Nesneler-İle-Test-Edilmesi)
  * [Framework Kullanılarak Oluşturulan Mock Nesneler İle Test](##Framework-Kullanılarak-Oluşturulan-Mock-Nesneler-İle-Test)

## Giriş
Başlık ne alaka demeyin Test Driven Development’da Mock ve Stub nesnelerin adı
bana her zaman çok beğendiğim Lock, Stock and Two Smoking Barrels filminin
adını hatırlatmıştır. Bu arada filmin biraz reklamını yapayım :)

“Test Driven Development nedir, ne değildir?”in temel felsefesine daha önceden
bu yazıda değinmiştik. Şimdi biraz daha derinlere inip gerçek hayatta TDD ile
geliştirdiğimiz yazılımlarda önümüze çıkan problemlere ve onlara nasıl çözüm
bulduğumuza bakalım.

Bildiğiniz gibi Unit Test; bir unit’i -genellikle bu bir sınıfdır- test
ortamında oluşturup o nesnenin çeşitli metodlarını çağırıp, çeşitli alanlarını
değiştirip… kısacası üzerinde işlem yaptıktan sonra ortaya çıkan sonuçların
beklediğimiz gibi gerçekleşip gerçekleşmediğni sınadığımız bir test çeşididir.
Aşağıda çok basit bir unit test görüyorsunuz.

```
[TestFixture]
public class CalculatorTest
{
    [Test]
    public void AddTest()
    {
      Assert.AreEqual(5,Calculator.Add(3, 2));
    }
}

class Calculator
{
  public static double Add(double a, int b)
  {
    return a + b;
  }
}
```

## Test Edilmesi Zor Olan Kodlar

Malesef ne gerçek kodlar bu kadar basit olabiliyor ne de onları test etmek bu
kadar kolay olabiliyor. Çünkü gerçek projelerde işin içine Database,Network,Web
Servisleri,Dosyalar… gibi birçok dış etken giriyor.Takdir edersinizki object
oriented programming, nesnelerin bir araya gelip işbirliği içinde çalışmaları,
birbirlerine mesaj gönderip almalarıyla işlevini yerine getirebiliyor. Bu
nesneleri test etmek için de test ortamında onların iletişim halinde olduğu
diğer nesneleride test ortamına sokmak gerekiyor. Çünkü nesne onlar olmadan
çalışmıyor.Fakat bazı nesneleri hem test ortamında oluşturmak zor hem de bu
nesnelerin test ortamında istediğimiz gibi davranmasını sağlamak zor.

Bu yüzden bu nesnelerin hem testlerini yazmak, hem de gerçekleyen kodlarını
yazmak yukarıdaki gibi basit olmuyor. Bu arada basit olmuyor dediysem gözünüz
korkmasın yine basit fakat Assert.AreEquels‘den daha fazlasını yapmak gerekiyor
yani kısaca biraz daha uğraştırıcı diyebilirim. Mesela gerçek projelerdeki bir
metod aşağıdaki gibi olabiliyor.

```
public void ProcessMessage()
{
  IPEndPoint ip = new IPEndPoint(IPAddress.Parse("127.0.0.1"), 9999);

  Socket server = new Socket(AddressFamily.InterNetwork, SocketType.Stream, ProtocolType.Tcp);

  try
  {
    server.Connect(ip);
  }
  catch (SocketException e)
  {
    Console.WriteLine("Unable to connect to server.");
    return;
  }

  byte[] data = new byte[1024];
  int receivedDataLength = server.Receive(data);
  string message = Encoding.ASCII.GetString(data, 0, receivedDataLength);

  server.Shutdown(SocketShutdown.Both);
  server.Close();

  if(message.Contains("VC"))
  {
    //mesaja göre işlem yap ardından veritabanına kaydet
  }
}
```

Peki bu metodu test etmek neden zor? Cevap basit çünkü burda bahsi geçen
Database,Network,Web Servisleri gibi ortamların çoğu bizim kontrolümüz
dışında.Ayrıca yukarıdaki kodlama kötü bir yazım çünkü mesaj okuma ve onu
işleme gibi iki ayrı sorumluluğu yerine getiriyor. Test ortamında istediğimiz
zaman onlardan beklediğimiz sonucu elde edemeyebiliyoruz.Mesela yukarıdaki kod
bloğu için “VC” içeren mesaj geldiğinde doğru işlemlerin yapılıp yapılmadığını
test etmek istediğimizi farzedelim.Ne gibi zorluklarla karşılaşırız? Öncelikle
en büyük problem imiz network’ün kontrolünün elimizde olmayışı.Elimizde
networkden “VC” mesajının geleceğine dair bir garanti yok.Bu eksikliği şu
şekilde giderebiliriz:”Biz testi çalıştırırken eş zamanlı olarak bir
arkadaşımızın ayrı bir bilgisayardan bize bir program ile “VC” mesajı
göndermesini sağlayabiliriz”.Herhalde bunu arkadaşınızın her test için kabul
edeceğini düşünmüyorsunuz.Diğer seçeneğimiz ise test ortamında bu metodu test
etmeden önce kod ile bir “Socket Client” oluşturup o mesajı gönderilmesini
sağlamak olabilir.Bu kısmi bir çözüm olarak görülse de yapacağımız her test
için socket oluşturmak,socket kapatmak için kod yazmak oldukça zahmetli bir iş.

Bu tarz test ortamında oluşturulması zor sınıfları Test Doubles dediğimiz
teknikler ile test edebiliyoruz. Şimdi de “Mock” ve “Stub nesneler” ile bu
şekilde test edilmesi zor olan sınıfları nasıl test edebileceğimize
bakacağız.Her zamanki gibi bir örnekle başlayalım:

## Senaryo : Mail Raporu Oluşturma

Bizden bir mail sunucusundaki belirli bir inbox’a bağlanıp oradaki maillerin
kaçının okunup kaçının okunmadığını bulan bir program yazmamız isteniyor. Bu
arada inbox bağlantısı için bize kullanıcı adı ve şifre verilmiş, bu bilgileri
kullanarak inbox bağlantısını kuruyoruz ve mailleri okuduktan sonra bağlantıyı
kapatıyoruz.

Tabi her zamanki gibi Test First Development yapıyoruz.Yukarıdaki gibi bir
senaryo için nasıl testler yazabiliriz?Öncelikle metodumuzun doğru çalışıp
çalışmadığını anlamak için bir test yazmamız lazım ardından da testi geçecek
kodu yazmamız lazım.Testlerde kontrol etmek istediğimiz durumlar aşağıda
sıralanmıştır:

 1. Kullanıcı adı şifre ile mail sunucusuna bağlanmadan önce bağlantı açılmış
    mı?
 2. Mailler alınıp okunmuş/okunmamış mail sayıları düzgün hesaplanmış mı?
 3. Bağlantı kapatılmış mı?.

Bu testlerin sonucunun istediğimiz gibi olup olmadığını nasıl kontrol ederiz?
Mesela şöyle bir test ve altındaki gibi de testi geçecek kodu yazdığımızı
vasaryalım.

```
[Test]
public void MailRaporuOlustur()
{
  MailRaporuOlusturucu mailRaporuOlusturucu =new MailRaporuOlusturucu ();
  MailRaporu rapor = mailRaporuOlusturucu.RaporOlustur();
  Assert.AreEqual(153,rapor.OkunmusMailSayisi);
  Assert.AreEqual(5,rapor.OkunmamisMailSayisi);
}

public class MailRaporuOlusturucu
{
  public const string KULLANICI_ADI = "Cihat";
  public const string SIFRE = "1111";
  public MailRaporu RaporOlustur()
  {
    //Sunucuya kullanıcı adı şifre kullanarak bağlantı açma
    //Gerçek mail sunucusuna bağlanıp mailler alınıyor sayılarını hesaplıyor
    //Bağlantıyı kapatılıyor
    return new MailRaporu(okunmusMailSayisi,OkunmamisMailSayisi);
  }
}
```

Şimdi yukarıdaki testin ve kodun problemleri neler onlara bakalım.

Öncelikle test içinde okunmuş mail sayısının 153 okunmamış mail sayısınında 5
olduğunu varsayıyoruz. Peki bunun bir garantisini verebilirmiyiz?Ya
bağlandığımız gerçek mail kutusunda 200 tane okunmuş mail varsa ya hiç
okunmamış mail yoksa?Bu yüzden bu metodu doğru test edemiyoruz çünkü gerçek
mail sunucusu kontrolümüz altında değil hatta belki testin çalıştığı anda
ortada bir mail sunucusu bile yok.

İkinci problemimiz; mailler alınmadan önce doğru kullanıcı adı şifre
kullanılarak bağlantı açılıp açılmadığını kontrol edemiyoruz. Bu metodumuzun
çalışmasının şartlarından biri.

Üçüncü problemimiz mailler alındıktan sonra bağlantının kapatılıp
kapatılmadığını test ortamında kontrol edemiyoruz.Bu da metodumuzun çalışması
için gerekli şartlardan biri.

Aslında burada kod ile alakalı yanlış bir kullanımı da testimizi düzgün bir
şekilde gerçekleştiremediğimizde farkedebiliyoruz:Metodumuz çok fazla iş
yapıyor. Hem mail server’a bağlanıp mail okuyor hem de okunmuş ve okunmamış
mail sayılarını hesaplayarak rapor hazırlıyor. Aslında metodumuz Single
Responsibility Prensibine ve Dependency Inversion Prensibine uymuyor bu yüzden
de test edilmesi oldukça zor.

## Single Responsibility Prensibinin Uygulanması

Biraz refactoring yapıyoruz.Öncelikle kodun Single Responsibility prensibine
uyması için sorumluklarını farklı sınıflara ayıralım. Aşağıdaki gibi kodu ve
testi tekrar yazalım.

```
[Test]
public void MailRaporuOlustur()
{
  MailRaporuOlusturucu mailRaporuOlusturucu = new MailRaporuOlusturucu(new MailOkuyucu());
  MailRaporu rapor = mailRaporuOlusturucu.RaporOlustur();
  Assert.AreEqual(153,rapor.OkunmusMailSayisi);
  Assert.AreEqual(5,rapor.OkunmamisMailSayisi);
}

public class MailRaporuOlusturucu
{
  private readonly MailOkuyucu mailOkuyucu;
  public const string KULLANICI_ADI = "Cihat";
  public const string SIFRE = "1111";

  public MailRaporuOlusturucu(MailOkuyucu mailOkuyucu)
  {
    this.mailOkuyucu = mailOkuyucu;
  }

  public MailRaporu RaporOlustur()
  {
    int okunmusMailSayisi = 0, OkunmamisMailSayisi = 0;
    mailOkuyucu.Baglan(KULLANICI_ADI,SIFRE);
    IList<Mail> mailListesi = mailOkuyucu.ButunMailleriGetir();
    mailOkuyucu.BaglantiyiKapat();
    for (int i = 0; i < mailListesi.Count; i++)
    {
      Mail mail = mailListesi[i];
      if (mail.Okunmus)
        okunmusMailSayisi++;
      else
        OkunmamisMailSayisi++;
    }
    return new MailRaporu(okunmusMailSayisi, OkunmamisMailSayisi);
  }
}
public class MailOkuyucu
{
  public void Baglan(string kullaniciAdi, string sifre)
  {
    //mail sunucusuna kullanıcı adı şifre kullanarak bağlanıyor.
  }

  public IList<Mail> ButunMailleriGetir()
  {
    List<Mail> mails = new List<Mail>();
    //Gerçek mail sunucusuna bağlanıp mail sayılarını hesaplıyor
    //....
    return mails;
  }

  public void BaglantiyiKapat()
  {
    //bağlantı kapatılıyor
  }
}
```

Evet kod yavaş yavaş adama benzemeye başladı :) Kodu sorumluluklarına göre
farklı sınıflara ayırdık artık herkes kendi işini yapıyor. Şimdi tekrar
düşünelim en üstteki MailSayisi testimiz çalışacak mı?Hayır çünkü sınıflar
değişti fakat MailOkuyucu sınıfının ButunMailleriGetir metodu çağırıldığında
yine gerçek sunucuya bağlandığı için testimiz yine başarısız olacaktır.Ayrıca
bağlantı açıldı mı,kapandı mı bunu test edemiyoruz yani hala düzgün test
edemiyoruz.

## Dependency Inversion Prensibinin Uygulanması

Bunun için ikinci aşama olarak Dependency Inversion prensibine uygun hale
getireceğiz.
Hatırlamak için tekrarlayalım:”Yüksek seviyeli sınıflar alt seviyeli sınıflara
bağımlı olmamalıdır”. Aralarındaki arayüzlere(interface ya da abstract
sınıflar)  bağımlı olmalıdır. Bu yüzden kodumuzu biraz daha değiştirip
aşağıdaki hale getiriyoruz.

```
[Test]
public void MailRaporuOlustur()
{
  MailRaporuOlusturucu mailRaporuOlusturucu = new MailRaporuOlusturucu(new MailOkuyucu());
  MailRaporu rapor = mailRaporuOlusturucu.RaporOlustur();
  Assert.AreEqual(153,rapor.OkunmusMailSayisi);
  Assert.AreEqual(5,rapor.OkunmamisMailSayisi);

}

public class MailRaporuOlusturucu
{
  private readonly IMailOkuyucu mailOkuyucu;
  public const string KULLANICI_ADI = "Cihat";
  public const string SIFRE = "1111";

  public MailRaporuOlusturucu(IMailOkuyucu mailOkuyucu)
  {
    this.mailOkuyucu = mailOkuyucu;
  }

  public MailRaporu RaporOlustur()
  {
    int okunmusMailSayisi = 0, OkunmamisMailSayisi = 0;
    mailOkuyucu.Baglan(KULLANICI_ADI,SIFRE);
    IList<Mail> mailListesi = mailOkuyucu.ButunMailleriGetir();
    mailOkuyucu.BaglantiyiKapat();
    for (int i = 0; i < mailListesi.Count; i++)
    {
      Mail mail = mailListesi[i];
      if (mail.Okunmus)
        okunmusMailSayisi++;
      else
        OkunmamisMailSayisi++;
    }
    return new MailRaporu(okunmusMailSayisi, OkunmamisMailSayisi);
  }
}

public interface IMailOkuyucu
{
  void Baglan(string kullaniciAdi, string sifre);
  IList<Mail> ButunMailleriGetir();
  void BaglantiyiKapat();
}

public class MailOkuyucu : IMailOkuyucu
{
  public void Baglan(string kullaniciAdi, string sifre)
  {
    //mail sunucusuna kullanıcı adı şifre kullanarak bağlanıyor.
  }

  public IList<Mail> ButunMailleriGetir()
  {
    List<Mail> mails = new List<Mail>();
    //Gerçek mail sunucusuna bağlanıp mail sayılarını hesaplıyor
    //....
    return mails;
  }

  public void BaglantiyiKapat()
  {
    //bağlantı kapatılıyor
  }
}
```

Şimdi yukarıda gördüğünüz gibi artık MailRaporuOlusturucu sınıfı gerçek sınıfa
değil de bir interface’e bağlı.O arayüzü uygulayan(implementation) herhangi bir
sınıfı sisteme verdiğimizde kodumuz çalışmaya devam edecektir.Tasarım olarak
gayet iyi bir noktaya geldik. Fakat hala test edemiyoruz çünkü dikkat edin test
metodunun içinde MailRaporuOlusturucu sınıfının yapıcısına(constructor)
IMailOkuyucu arayüzünü uygulayan gerçek MailOkuyucu sınıfını verdiğimiz için
aynen gerçek sunucuya bağlanmaya devam edecek testimiz yine bize istemediğimiz
sonuçları vermeye devam edecek. Ayrıca hala bağlantı açılıp kapandımı
testlerimizde kontrol edemiyoruz.

## Stub Nesneler ile Test Edilmesi

Şimdi kodumuzu buraya kadar iyileştirdikten sonra test edebilmemiz aslında
kolaylaştı bunun için uygulayabileceğimiz ilk tekniklerden biri Stub nesneler
kullanmak. Şimdi Stub nedir kısaca şöyle açıklayalım: Yukarıdaki
MailRaporuOlusturucu sınıfının yapıcısına test amaçlı aynı interface’i
uygulayan bir sınıf oluşturup veriyoruz ve bu sınıf üzerinden istediğimiz
sonuçları döndürüyoruz. Şimdi Stub nesne kullanarak aşağıdaki testimizi tekrar
yazalım.

```
class MailOkuyucuStub:IMailOkuyucu
{
  private List<Mail> mailListesi = new List<Mail>();
  public string BaglanilanSifre { get; set; }
  public string BaglanilanKullaniciAdi { get; set; }
  public bool BaglantiKapatildi { get; set; }

  public List<Mail> MailListesi
  {
    get { return mailListesi; }
  }

  public void Baglan(string kullaniciAdi, string sifre)
  {
    BaglanilanKullaniciAdi = kullaniciAdi;
    BaglanilanSifre = sifre;
  }


  public IList<Mail> ButunMailleriGetir()
  {
    return mailListesi;
  }

  public void BaglantiyiKapat()
  {
    BaglantiKapatildi = true;
  }
}

[TestFixture]
public class MailRaporuOlusturucuTest
{
    [Test]
    public void MailCount()
    {
      MailOkuyucuStub okuyucuStub =new MailOkuyucuStub();
      for(int i=0;i<153;i++)
      {
        Mail mail = new Mail();
        mail.Okunmus = true;
        okuyucuStub.MailListesi.Add(mail);
      }

      for(int i=0;i<5;i++)
      {
        Mail mail = new Mail();
        mail.Okunmus = false;
        okuyucuStub.MailListesi.Add(mail);
      }


      MailRaporuOlusturucu mailRaporuOlusturucu = new MailRaporuOlusturucu(okuyucuStub);
      MailRaporu rapor = mailRaporuOlusturucu.RaporOlustur();
      Assert.AreEqual(153, rapor.OkunmusMailSayisi);
      Assert.AreEqual(5, rapor.OkunmamisMailSayisi);
      Assert.AreEqual(MailRaporuOlusturucu.KULLANICI_ADI,okuyucuStub.BaglanilanKullaniciAdi);
      Assert.AreEqual(MailRaporuOlusturucu.SIFRE,okuyucuStub.BaglanilanSifre);
      Assert.AreEqual(true,okuyucuStub.BaglantiKapatildi);
    }
}
```

Gördüğünüz gibi test ortamında aynı arayüzü uygulayan test amaçlı bir Stub
nesne oluşturduk.Bu nesneye test esnasında 153 adet okunmuş mail,5 tane de
okunmamış mail ekledik. Artık kontrol gerçek mail sunucusunun elinde değil
bizim elimizde.Böylece istediğimiz sayıda mail dödürebiliyoruz.Ayrıca Stub
nesnesi içinde bağlanmak için gelen kullanıcı adı ve şifreyi tutarak test
esnasında düzgün parametrelerin gelip gelmediğini kontrol ettik.Bağlantıyı
kapatan metodun çağırılıp çağrılmadığını da bu teknikle stub içinde saklayıp
test sırasında kontrol ettik.Bağlantı kapatma metodu çağırılmışmı onu da bu
teknikle stub içinde saklatıp test sırasında kontrol ettik.

## El ile Yazılmış Mock Nesneler İle Test Edilmesi

Şimdi aynı testleri Mock Objects tekniği kullanarak test edelim. Öncelikle Mock
Objects nedir kısaca anlatalım. Mock nesneler test sırasında aynı Stublar gibi
nesnelerin bizim istediğimiz değerleri döndürülmesini ve doğru metodlar doğru
parametreler ile çağırılmış mı onu kontrol eder.Fakat test ediliş şekilleri
farklıdır.Mock objelere çağırılmasını beklediği metodları ve parametreleri
veririz ardından düzgün çağırılmışmı mock objelerin kendisi kontrol eder. Stub
nesneler kullandığımızda hatırlayın bunu Assert.AreEquels metodları ile
kendimiz yapıyorduk. Mock objeler ise bunu kendi içlerinde kontrol ederler.

Tabi elle yazmak oldukça zahmetli bir iş şuana kadar hiç el ile mock yazmadım
fakat herhangi bir mock object framework kullanmaya başlamadan önce el ile
kendi yaptığımız mock nesneler ile bunun nasıl yapıldığını görmeniz bu
frameworklerin nasıl işlediğini ve neler yaptığınızı anlamanız açısından iyi
olacaktır.
 
```
class MockMailOkuyucu:IMailOkuyucu
{
  private string beklenenKullaniciAdi;
  private string beklenenSifre;
  private bool baglantiKapatildi;
  private bool beklenenBaglantiKapatildi;
  public List<Mail> MailListesi = new List<Mail>();

  public void BeklenenBaglan(string kullaniciAdi, string sifre)
  {
    beklenenKullaniciAdi = kullaniciAdi;
    beklenenSifre = sifre;
  }

  public void BaglantiKapatildiCagirilmaliMi(bool deger)
  {
    beklenenBaglantiKapatildi = deger;
  }


  public void Baglan(string kullaniciAdi, string sifre)
  {
    Assert.AreEqual(beklenenKullaniciAdi, kullaniciAdi);
    Assert.AreEqual(beklenenSifre, sifre);
  }

  public IList<Mail> ButunMailleriGetir()
  {
    return MailListesi;
  }

  public void BaglantiyiKapat()
  {
    baglantiKapatildi = true;
  }

  public void KontrolEt()
  {
    Assert.AreEqual(beklenenBaglantiKapatildi,baglantiKapatildi);
  }
}

[TestFixture]
public class MailRaporuOlusturucuMockTest
{
    [Test]
    public void MailCount()
    {
      MockMailOkuyucu mockMailOkuyucu = new MockMailOkuyucu();
      for (int i = 0; i < 153; i++)

      {
        Mail mail = new Mail();
        mail.Okunmus = true;
        mockMailOkuyucu.MailListesi.Add(mail);
      }

      for (int i = 0; i < 5; i++)
      {
        Mail mail = new Mail();
        mail.Okunmus = false;
        mockMailOkuyucu.MailListesi.Add(mail);
      }
      mockMailOkuyucu.BeklenenBaglan(MailRaporuOlusturucu.KULLANICI_ADI,MailRaporuOlusturucu.SIFRE);
      mockMailOkuyucu.BaglantiKapatildiCagirilmaliMi(true);

      MailRaporuOlusturucu mailRaporuOlusturucu = new MailRaporuOlusturucu(mockMailOkuyucu);
      MailRaporu rapor = mailRaporuOlusturucu.RaporOlustur();
      Assert.AreEqual(153, rapor.OkunmusMailSayisi);
      Assert.AreEqual(5, rapor.OkunmamisMailSayisi);
      mockMailOkuyucu.KontrolEt();
    }
}
```
Yukarıda Stub ile yazdığımız aynı testi el ile yazdığımız mock ile aynı şekilde
test ettik. Dikkat edin Mock objeye Baglan metodunun hangi parametreler ile
çağırılması gerektiğini söyledik ardından kapat çağırılmalı mı onu söyledik ve
en sonunda bunun mock objenin kendi KontrolEt metodu ile kontrol ettik.Aslında
Mock Objects Frameworklerin yaptığıda bu sınıfları çalışma anında bizim kod
yazmamıza gerek kalmadan otomatik olarak oluşturmak.

## Framework Kullanılarak Oluşturulan Mock Nesneler İle Test

En sona kaldı fakat kendi adıma en çok kullandığım yöntem olan Mock object
framework ile kullanarak aynı testi tekrar yazıyoruz.Bu arada birsürü bu tarz
mock nesneler oluşturan hem Java hem .NET için framework mevcut.Ben .NET için
aşağıda kullandığım Rhino Mocks kütüphanesini kullanıyorum.Java içinde aşağı
yukarı aynı yapıda olan EasyMock kullanıyorum.

```
[Test]
public void MailCountMockFramework()
{
  IList<Mail> mailListesi = new List<Mail>();

  for (int i = 0; i < 153; i++)
  {
    Mail mail = new Mail();
    mail.Okunmus = true;
    mailListesi.Add(mail);
  }

  for (int i = 0; i < 5; i++)
  {
    Mail mail = new Mail();
    mail.Okunmus = false;
    mailListesi.Add(mail);
  }

  MockRepository mockRepository =new MockRepository();
  IMailOkuyucu mockMailOkuyucu = mockRepository.StrictMock<IMailOkuyucu>();

  mockMailOkuyucu.Baglan(MailRaporuOlusturucu.KULLANICI_ADI, MailRaporuOlusturucu.SIFRE);
  mockMailOkuyucu.BaglantiyiKapat();
  Expect.Call(mockMailOkuyucu.ButunMailleriGetir()).Return(mailListesi);
  mockRepository.ReplayAll();


  MailRaporuOlusturucu mailRaporuOlusturucu = new MailRaporuOlusturucu(mockMailOkuyucu);
  MailRaporu rapor = mailRaporuOlusturucu.RaporOlustur();
  Assert.AreEqual(153, rapor.OkunmusMailSayisi);
  Assert.AreEqual(5, rapor.OkunmamisMailSayisi);
  mockRepository.VerifyAll();
}
```

Gördüğünüz gibi artık el ile yaptığımız mock nesnesini framework bizim için
oluşturdu. Bunu çalışma anında proxy nesneler oluşturarak bizim el ile
yazdığımız mock nesnesine benzer nesneler oluşturarak yapıyor. Zaten test
sırasında gördüğünüz gibi mockRepository.ReplayAll(); satırına kadar hangi
metodların hangi parametreler ile çalışması gerektiğini söyledik. Ardından
Expect.Call(mockMailOkuyucu.ButunMailleriGetir()).Return(mailListesi); satırı
ile de ButunMailleriGetir metodu çağırıldığında hangi listenin dönmesi
gerektiğini Frameworke söyledik. ReplayAll() metodu ile Framework bizim
beklediğimiz ve dönmesi gerektiğimiz şeyleri hafızasına aldı ardından
mockRepository.VerifyAll(); satırında daha önceden hafızasına aldığı şartların
yerine getirilip getirilmediğini kontrol ediyor.

Test etmesi zor olan kısımları Mock ve Stub nesneler ile nasıl test
edebildiğimizi gördük.Aslında burada Test Driven Development’ın en güzel
yanlarından biri ortaya çıkıyor. Burda Mocks ve Stubs nedir örnek olsun diye
kodu önce test edilemeyen şekliyle yazdım. Fakat normalde TDD uygularken önce
test kodu yazdığınız için tasarımınız Single Responsibility ve Dependency
Inversion prensibine uymak zorunda kalıyor. Bu yüzden sizi daha düzgün tasarımı
olan gerçek sınıflara değilde arayüzlere bağımlı olan kod yazmanıza zorluyor.
Bunlarda nesneye yönelik programlama için oldukça önemli kavramlar.Ayrıca diğer
güzel yanı dikkat ederseniz gerçek mail sunucusuna bağlantı yapan kodu yazmadan
rapor oluşturan kodu yazdım. Yani kodu yazmak için alt seviyeli
database,network.. gibi şeylerin hazır olmasınada gerek kalmıyor.

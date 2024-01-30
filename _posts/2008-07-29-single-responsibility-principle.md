---
layout: post
title: "Single Responsibility Principle(SRP)"
description: "Single Responsibility Principle(SRP)"
date: 2008-07-29T07:00:00-07:00
tags: principles
---

Evet lütfen kemerlerinizi bağlayın koltuklarınıza sıkı sıkı yapışın nesneye
yönelik programlamanın özüne doğru yolculuğa çıktık.Ufak çaplı sarsıntı
yaşayabilirsiniz.Verdiğimiz rahatsızlıktan dolayı özür dileriz. :)

Şimdi bu kadar abarttığıma bakmayın ama konunun önemini belirmek için böyle bir
giriş yaptım.Nesneye yönelik programlamanın,tasarımın en temel  ve yazılım
tasarımının en önemli prensiplerinden olan Single-Responsibility Principle
(SRP) hakkında bilgi verip ufak bir örnekle incelemeye çalışacağız.

Nesneye yönelik programlamanın hatta genel programlama mantığının temelinde
yatan metodları nesneleri düşünelim.Neden kullandığımız dillerde bu tarz
yapılar mevcut?Yönetimi kolaylaştırmak için.Amaç farklı işleri yapan kavramları
birbirinden metodlar, sınıflar kullanarak yönetilmesini kolaylaştırmak için
birbirinden ayırmak.Nesneye yönelik programlamada bunu nesneler kullanarak,
prosedürel programlamada ise fonksiyonlar fonksiyon modülleri kullanarak
yapıyoruz.Ama temel mantık aynı farklı işleri farklı farklı sınıflar, metodlar,
katmanlar, kütüphaneler içine koyarak ayırıyoruz.

Tabi bazen farklı farklı işleri gidip aynı sınıf,metod ya da modül içine
koyabiliyoruz(biri bizi durdursun).Hatta çoğu zaman bunu bu şekilde yapıyoruz
diyebilirim.Etrafta yüzlerce binlerce satırlık sınıflar, metodlar görmemizin
sebebi de bu. Tabi böyle yapınca sınıfın kodunu aşağıya doğru çekince en son
satıra ulaşmak 10 saniye alıyor neredeyse. Mesela gördüğüm bir sınıf yaklaşık
5000 satırdı aşağıya çekmem bile baya süre alıyordu malesef.

Bertrand Meyer Object-Oriented Software Construction kitabında
sınıfların,fonksiyonların,modüllerin nasıl olması gerektiğini aşağıdaki
cümleyle çok güzel özetlemiş.

> A class has a single responsibility: it does it all, does it well, and does
it only. Classes, interfaces, functions, etc. all become large and bloated when
they’re trying to do too many things.

Aslında Single-Responsibility Principle (SRP) tamamen yukarıdaki sözle
özetlenebilir. Bir sınıf,fonksiyon vs.. sadece tek bir sorumluluğu yerine
getirmelidir  ve yerine getirdiği sorumluluğu iyi yapmalıdır.Birden fazla
sorumluluk yerine getirmeye çalıştığı zaman aşırı büyür ve karmaşıklaşır.

Bu prensip aslında yazılım dünyasında uzun zamandır bilinen temel kavramlardan
biridir. Kısaca bu prensibi şöyle açıklayabiliriz, kodumuzda, tasarladığımız
modüllerde kullandığımız sınıflar,uygulamadaki katmanlarımız,modüllerimiz
sadece tek bir sorumluluğunu yerine getirmelidir. Yani sınıfın,modülün sadece
kendi ile alakalı işleri yapmasıdır diyebiliriz. Çünkü birden fazla sorumluluğu
yerine getiren sınıfların,modüllerin değişmesi için birden fazla neden vardır.
Kendi ile alakalı şeyleri yapmayan sınıfların modüllerin aşağıdaki gibi
dezavantajları vardır.

Anlaması zordur Tekrar kullanılabilmesi zordur. Yönetilmesi zordur. Hassas ve
sürekli olarak diğer değişikliklerden etkilenen yapıdadır.
Modüller açısından bu prensibi inceleyelim.Katmanlı mimari modüler tasarım
modül vb.. kavramlar da aslında bu tasarım prensibinin uygulanmasının bir
sonucudur.Örnek olarak 3 katmanlı bir yapıda tasarlanmış bir uygulamada klasik
olarak Sunum(Presentation Layer), İş(Business Layer) ve Veri(Data Layer)
katmanları bulunsun. Adlarından da anlayabileceğimiz gibi her katman kendine
ait sorumlulukları yerine getirir. Biri(Data Layer) veritabanı ile ilgilenirken
diğeri(Business Layer) iş kurallarıyla alakalı sorumlulukları yerine getirir.
Bir diğeride(Presentation Layer) bilgilerin kullanıcılara sunulması
sorumluluğunu yerine getirir. Bu şekilde tasarımın en önemli faydalarından
biride bir katmandaki değişikliğin diğer katmanları etkilememesi ve iyi
tasarlanmış katmanların tekrar başka uygulamalarda kullanılabilmesidir. Çünkü
her katman sadece kendi ile alakalı tek bir sorumluluğu yerine getirir. Böylece
değişmesi için tek bir sebep vardır.Bu da o katmandaki ihtiyaçların değişmesi.
Örnek olarak sunum katmanındaki bir değişim veri katmanını etkilemez çünkü
ikisi de birbirinden bağımsız ayrı sorumlulukları yerine getirirler.Tabi bu
sözde anlatması kolay fakat gerçekleştirmesi bir o kadar zor bir kavramdır.

Sınıflar için baktığımızda bu prensip anlatması ve anlaşılması en kolay fakat
uygulamaya gelince en çok zorlandığımız prensiplerden biridir.Mesela benim 5000
satırlık işçi için sınıfım işciler ile alakalı iş mantığını yönetmekle sorumlu
diyebilirim.Ama bu yönetme içinde veritabanı ile iletişim,import,export
özellikleri,iş mantığını,cache yönetimi…. gibi bir sürü ayrı sorumluluğu yerine
getiriyor yani birden fazla işi yapıyor ama ben olaya öyle bakmıyorum.Bu yüzden
sorumluluk kavramını tam anlamıyla doğru şekilde uygulamak zaman ve deneyim
isteyen bir süreçtir. Bunun bazı sebeplerinden biride sorumluluk kavramının
karıştırılabilmesi, biraz bulanık bir kavram olmasından da kaynaklanmaktadır.

Mesela bir sınıf için baktığımızda sorumluluk nedir ? Genelde sorumluluk
denince sınıfın bir methodu akla gelir fakat gerçekte birden fazla method bir
sorumluluğu yerine getiriyor olabilir. Bence sorumluluğun en güzel özeti bir
sınıfın değişmesi için bir sebep olarak tanımlayabiliriz. Yani bir
sınıfın,metodun.. değişmesi için birden fazla neden varsa o sınıfın birden
fazla sorumluluğu yerine getirdiğini söyleyebiliriz.Mesela yukarıda bahsettiğim
işçi sınıfı için söyleyecek olursak bu sınıf veritabanına erişim mantığı
değiştiğinde değişebilir, ayrıca değişik bir import seçeneği sunmak
istediğimizde yine sınıfı değiştirmek gerekir,yeni bir cache algoritması
eklemek istediğimizde doğal olarak tekrar bu sınıfı değiştirmek zorunda
kalacağız. Bu da bize sınıfın değişmesi için birçok sebep verdi demekki bu
sınıfın çok fazla sorumluluğu var onun sırtındaki yükü biraz azaltmamız lazım.

Örneklerin genelde gerçek hayattan olmasına özen göstermeye çalışıyorum. O
yüzden daha önceden üzerinde çalıştığım kodun küçük bir kısmını değiştirerek
incelemek için aşağıya yazıyorum.

```
class Contact
{
  private int _contactID;

  public int ContactID
  {
    get { return _contactID; }
    set { _contactID = value; }
  }

  private string _name;

  public string Name
  {
    get { return _name; }
    set { _name = value; }
  }

  private string _number;

  public string Number
  {
    get { return _number; }
    set { _number = value; }
  }

  private ContactType _type;

  public string Type
  {
    get { return _type; }
    set { _type = value; }
  }

  public int ImportExcel(File file)
  {
    CantactDao contactDao = null;
    List<Contact> contactList = null;
    int contactCount = 0;
    try
    {
      contactDao = new ContactDao();
      tr =
      contactDao.BeginTransaction(System.Data.IsolationLevel.ReadUncommitted);
      contactList = contactDao.GetContactsFromExcel(file);
      if (contactList != null && contactList.Count > 0)
      {
        for (int i = 0; i < contactList.Count; i++)
        {
          contactList[i].Type = ContactType.Friend;
          contactList[i].Save();
        }
        contactDao.CommitTransaction(tr);
        contactCount = contactList.Count;
      }
    }
    catch (Exception ex)
    {
      contactDao.RollbackTransaction(tr);
    }
    return contactCount;
  }

  public int Save()
  {
    ContactDao contactDao = null;
    try
    {
      contactDao = daoFactory.GetContactDao();
      tr = contactDao.BeginTransaction();
      contactDao.Insert(this);
      contactDao.CommitTransaction(tr);
    }
    catch (Exception ex)
    {
      contactDao.RollbackTransaction(tr);
    }
    return this.ContactID;
  }
}

class ContactDao
{
  public void Insert(Contact contact)
  {
    //veritabanı erişim kodları ile veritabanına Contact sınıfının eklenmesi
  }

  public void Update(Contact contact)
  {
    //veritabanı erişim kodları ile Contact sınıfının güncellenmesi
  }

  public void Delete(Contact contact)
  {
    //veritabanı erişim kodları ile sınıfın veritabanından silinmesi
  }

  public Contact GetByID(int contactID)
  {
    //veritabanı erişim kodları ile sınıfın veritabanından alınması
  }

  public List<Contact> GetContactsFromExcel(File file)
  {
    Contact contact = null;
    List<Contact> contactList = null;
    System.Data.OleDb.OleDbConnection connection = null;
    System.Data.OleDb.OleDbCommand selectCommand = null;
    try
    {
      string connectionString = @"Provider=Microsoft.Jet.OLEDB.4.0;Data
      Source=" + File.FilePath + ";Extended Properties=Excel 8.0";
      string selectQuery = "SELECT * FROM [Contacts$]";
      connection = new System.Data.OleDb.OleDbConnection();
      connection.ConnectionString = connectionString;
      connection.Open();
      selectCommand = new System.Data.OleDb.OleDbCommand(selectQuery, connection);
      System.Data.OleDb.OleDbDataReader dataReader =
      selectCommand.ExecuteReader();
      if (dataReader != null && dataReader.HasRows)
      {
        contactList = new List<Contact>();
        while (dataReader.Read())
        {
          contact = new Contact();
          contact.Name = dataReader["Name"];
          contact.Number = dataReader["Number"];
          //....diğer alanların alınması ve kontrolü
          contactList.Add(contact);
        }
      }
    }
    catch (Exception ex)
    {
      throw ex;
    }
    return contactList;
  }
}
```

Şimdi yukarıdaki kodun yapısını biraz inceleyelim. Bir SMS programımız var SMS
programının özelliklerinden biri dışarıdan excel içindeki kişi listesini
programımıza import edebiliyoruz.Genelde çoğu programda bu tarz özellikleri
sizde kullanmıştırsınız.Kodda gördüğünüz gibi bir adet Contact sınıfımız var bu
sınıf programımızda kullandığımız kişileri temsil ediyor.Bu sınıfın metodlarına
bakarsak gördüğünüz gibi bir adet excel dosyasından import eden ImportExcel
metodumuz var. Ayrıca veritabanına bilgileri kayıt eden bir adet Save metodumuz
var.Yani ActiveRecord tasarım kalıbını uygulayarak kendini veritabanına kayıt
ediyor. ContactDao adında DAO(Data Access Object) tasarım kalıbını uygulayan
bir adet sınıfımız var.Bu sınıfımızda Contact sınıfımızı veritabanına
ekleme,güncelleme, silme ve Excel dosyasından veri alma işlemini yapıyor.
Şimdide UML olarak static sınıf diyagramına bakalım.

![Design 1](/img/srp/classdiagram1.jpeg)

Yukarıdaki Uml diyagramını çizmemin tek amacı görsel olarak sınıflar arasındaki
ilişkileri görmek kodu okumaktan daha kolay olmasıdır. Şimdi yukarıdaki
diyagram yardımıyla sınıfları daha yakından incelemeye başlayalım.Öncelikle
sınıfların birbirine olan bağımlılığına(Dependency) bakalım. Etrafta uçuşan
okları görüyorsunuz görüntü pek iç açıcı değil açıkçası. Contact sınıfımız
üzerindeki ImportExcel metodu sayesinde File sınıfına bağımlı. Ayrıca Save
metodunu kullandığında da Transaction oluşturduğu ve CantactDao sınıfının
metodunu çağırdığı için bu sınıfa ve ADO.NET sınıflarına da bağımlı.

Öncelikle kötülüklerin anası olan bağımlılık neden bu kadar kötü kısaca
bahsedelim. :) Bağımlılığı fazla olan sınıfları yeniden kullanmanız (Reuse) çok
zordur. Çünkü kullanmak istediğiniz sınıf diğer  birçok sınıfa bağımlıdır
onunla birlikte diğer sınıflarıda projede dahil etmeniz gerekir. Tabi bu da o
kadar kolay değildir.Çünkü diğer sınıflarında birçok diğer sınıfa bağımlı
olduğu düşünürsek küçük bir sınıfı yeniden kullanmak istediğinizde bütün
projeyi diğer projeye dahil etmeniz gerekir. Diğer bir kötü yanı bağımlı olduğu
sınıflarda meydana gelen hataların o sınıfı kolaylıkla etkilemesidir. Bu konuda
daha geniş bilgi için Dependency Inversion prensibine bakabilirsiniz.Ayrıca
gördüğünüz gibi Contact sınıfı,ContactDao sınıfı kendi ile alakalı olmayan
metodlar ile gittikçe büyüyor. Sınıfların büyüdükçe yönetilmesinin çok zor
olduğunu biliyorsunuz. Benim gibi 5000 satırlık kodun içinde değişiklik
yapmanın hatanın ne olduğunu bulmanın nasıl bir kabul olduğunu bilirsiniz.

Şimdi bu kadar şeyden bahsettik bunların Single Responsibility Principle ile
alakasının ne olduğunu merak etmiş olabilirsiniz haklı olarak. Kısaca burada ki
bağımlılığın sınıfların gittikçe büyümesinin sebebi sınıfların birden çok
sorumluluğunun olmasıdır. Contact sınıfımız hem sistemimizde bir kavramı temsil
ederken hemde onu sisteme import etme işlemini yapıyor. Ayrıca ContactDao
sınıfımız hem veritabanı ile alakalı Insert,Update… gibi işlemleri yaparken
ayrıca Excel dosyasından kayıtları okuma işlemini yapıyor. Bu sınıfın değişmesi
için birçok neden sıralayabiliriz.Import mantığımız değişir, Contact sınıfını
değiştiririz. İş mantığımız değişir, Contact sınıfını değiştiririz. Excel
dosyasından okuma mantığımız değişir, ContactDao sınıfımız değişir.Kullanılan
teknolojiyi ADO.NET yerine başka birşey kullanmak isteriz iki sınıfımızda
değişmek zorunda kalır.Yani değişime karşı sınıflarımız oldukça kırılgan
yapıdalar.

Şimdi fazla sorumluluğu olan sınıfların yüklerini biraz hafifletelim. Bunu
yapmak için bütün yapılan sorumlulukları liste halinde yazalım.Bu listeyi
sorumlulukları atamada kullanacağız.

Kişilerin sistemnde temsil edilmesi (Contact sınıfı) Kişilerin veritabanı ile
alakalı işlerin yapılması (ContactDao sınıfı) Kişilerin import edilerek sisteme
kayıt edilmesi (Contact sınıfı) Excel dosyasından satırların okunarak kişi
nesnesine çevrilmesi (ContactDao sınıfı)
Gördüğünüz gibi 4 tane sorumluluk 2 tane sınıf arasında paylaştırılmış. Biz
kodumuzu değiştirerek her sorumluluğu tek bir sınıfa atayacağız yani Single
Responsibility prensibini uygulayacağız. Bunun için öncelikle bu sorumluluklara
iyi birer isim bulmaya çalışalım. Dikkat edin bunu sezgi yoluyla yapıyorum.

Öncelikle kişilerin sistemde temsil edilmesi Contact sınıf bu aynen kalacak.
Kişilerin veritabanı ile alakalı işlerinin yapılması zaten bu işi yapan
sınıfımız var ContactDao adı üzerinde Data Access Object Kişilerin import
edilmesi buna ContactImporter diyelim Kişilerin Excel dosyasından okunması buna
da ContactExcelReader olsun.
Sınıflarımızın adlarını belirledikten sonra fazla sorumluluğu olan sınıflardan
kodların yeni sınıflara taşınması işlemi var. Bu işlemi yaparken tabiki
kes-yapıştır yapmanızı tavsiye etmiyorum. Birçok istenmeyen hata ile
karşılaşabilirsiniz. Bunu Refactoring, ve Unit Testing desteğiyle en güvenli
şekilde yapabilirsiniz. Konumuzu fazla dağıtmamak için değinmiyorum amacımız
Single Responsibility Prensibini açıklamak.O yüzden benim şuanda kes-yapıştır
yapmama fazla aldırmayın.Lafı fazla uzatmadan yeni kodlarımızı aşağıya yazalım.

```
internal class Contact
{
  private int _contactID;

  public int ContactID
  {
    get { return _contactID; }
    set { _contactID = value; }
  }

  private string _name;

  public string Name
  {
    get { return _name; }
    set { _name = value; }
  }

  private string _number;

  public string Number
  {
    get { return _number; }
    set { _number = value; }
  }

  private ContactType _type;

  public string Type
  {
    get { return _type; }
    set { _type = value; }
  }
}

class ContactImporter
{
  private ContactDao contactDao = new ContactDao();
  private CntactExcelReader contactReader = new ContactExcelReader();

  public int ImportFromExcel(File file)
  {
    List<Contact> contactList = null;
    int contactCount = 0;
    try
    {
      tr =
      contactDao.BeginTransaction(System.Data.IsolationLevel.ReadUncommitted);
      contactList = contonctReader.GetContactsFromExcel(file);

      if (contactList != null && contactList.Count > 0)
      {
        for (int i = 0; i < contactList.Count; i++)
        {
          contactList[i].Type = ContactType.Friend;
          contactList[i].Save();
        }

        contactDao.CommitTransaction(tr);
        contactCount = contactList.Count;
      }
    }
    catch (Exception ex)
    {
      contactDao.RollbackTransaction(tr);
    }
    return contactCount;
  }
}

class ContactDao
{
  public int Save(Contact contact)
  {
    try
    {
      Transaction tr = this.BeginTransaction();
      this.Insert(contact);
      this.CommitTransaction(tr);
    }
    catch (Exception ex)
    {
      this.RollbackTransaction(tr);
    }

    return contact.ContactID;
  }

  public void Insert(Contact contact)
  {
    //veritabanı erişim kodları ile veritabanına Contact sınıfının eklenmesi
  }

  public void Update(Contact contact)
  {
    //veritabanı erişim kodları ile Contact sınıfının güncellenmesi
  }

  public void Delete(Contact contact)
  {
    //veritabanı erişim kodları ile sınıfın veritabanından silinmesi
  }

  public Contact GetByID(int contactID)
  {
    //veritabanı erişim kodları ile sınıfın veritabanından alınması
  }
}

class ContactExcelReader
{
  private GetContactsFromExcel(File file)
  {
    Contact contact = null;
    IList<Contact> contactList = null;
    System.Data.OleDb.OleDbConnection connection = null;
    System.Data.OleDb.OleDbCommand selectCommand = null;

    try
    {
      string connectionString = @"Provider = Microsoft.Jet.OLEDB.4.0; Data
      Source =" + File.FilePath +
        ";Extended Properties = Excel 8.0";

      string selectQuery = "SELECT*FROM[Contacts$]";

      connection = new System.Data.OleDb.OleDbConnection();
      connection.ConnectionString = connectionString;
      connection.Open();
      selectCommand = new System.Data.OleDb.OleDbCommand(selectQuery,
      connection);
      System.Data.OleDb.OleDbDataReader dataReader =
      selectCommand.ExecuteReader();
      if (dataReader != null && dataReader.HasRows)
      {
        contactList = new List<Contact>();

        while (dataReader.Read())
        {
          contact = new Contact();
          contact.Name = dataReader["Name"];
          contact.Number = dataReader["Number"];
          //....diğer alanların alınması ve kontrolü
          contactList.Add(contact);
        }
      }
    }
    catch (Exception ex)
    {
      throw ex;
    }

    return contactList;
  }
}
```

Yeni sınıflarımıza bir de UML diyagramı ile bakalım.

![Design 2](/img/srp/classdiagram2.jpeg)

Şimdi yukarıda ki diyagram yadımıyla kodumuzun son haline bakalım. Gördüğünüz
gibi artık Contact sınıfımız ne File,ContactDao gibi sınıflara ne de herhangi
bir ADO.NET teknolojisine bağımlı.Fazla sorumluluğu üzerinden alınca diğer
sınıflardan bağımsız hale geldi. Diğer sınıflara baktığımızda sadece kendi
işlerini yapan ve gereksiz bağımlılıklardan kurtulmuş sınıflar
var.ContactExcelReader sadece Excel dosyasından Contact okuma işini
yapıyor,ContactImporter liste halinde verilen kişileri veritabanına import
ediyor. ContactDao sadece veritabanı ile alakalı işlemleri yapıyor.Artık
sınıfların değişmesi için tek sebep var. Kodun anlaşılması ve yönetilebilmesi
daha kolay.

Single Responsibility prensibini her zaman uygulamak çok faydalı olmayabilir.
Mesela çok küçük bir projede uygulamak sınıf sayısını arttırdığı için sistem
daha komplex olur.Mesela yukarıda ActiveRecord tasarım kalıbını uygulayan Save
metodunu gidip ContactDao sınıfı üzerine taşıdık.Fakat bu tasarım kalıbı küçük
çaplı, iş mantığının yoğun olmadığı çoğu projede başarı kullanılabiliyor.Ama
çoğu durumda uygulamanız için  bu prensibi uygulamak uygulamanın yönetimi
bakımı hata oranı için oldukça önemli rol taşıyor.

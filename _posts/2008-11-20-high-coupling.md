---
layout: post
title: "Ortak Düşmanımız : Bağımlılık (Dependency,High Coupling)"
description: "Ortak Düşmanımız : Bağımlılık (Dependency,High Coupling)"
date: 2008-11-20T07:00:00-07:00
tags: principles
---

![domino1](/img/highcoupling/domino1_3.jpg)

Bu yazımızda yazılım geliştirirken karşımıza çıkan en büyük problemlerden biri
olan bağımlılık (Dependency,Coupling) konularına değineceğim. Neden az olanı
makbüldür onu anlatmaya çalışacağım.

Yazılım geliştirirken gerçek dünyadaki gibi bağımlılık (Dependency,Coupling)
başımıza çoğu zaman dert açıyor.Bağlanılması zararlı bir şeye bağlandınızmı
nasıl ondan kurtulmak onsuz birşey yapmak imkansız oluyorsa aynısı yazılım
geliştirirkende geçerli oluyor. Yazılımda bağımlılığı tanımyacak olursak iki
metodun,sınıfın,modülün bir işi gerçekleştirmek için birbirine ihtiyaç
duymaları kısacası birbirlerini kullanmalarıdır diyebiliriz.

Peki bağımlılığın ne gibi zararları var neden düşman ilan ettik birazda ondan
bahsedelim. Öncelikle iki sınıfın birbirine bağımlı olmasının en büyük
problemlerinden biri herhangi birindeki değişikliğin diğerini etkilemesidir
bunu yandaki domino taşlarına benzetebilirsiniz. Herhangi bir yerden taşın
birini düşürdüğünüz zaman birbiri ardına olan bütün taşlar devrilmeye başlar.
Aynı şekilde geliştirdiğimiz yazılımda sınıflar,modüller… arasındaki bağımlılık
ne kadar fazla ise domino taşı gibi herhangi birinde meydana çıkan
hataların,değişikliklerin bağımlı olan diğer sınıfları etkileme olasılığı o
kadar artıyor.

Üstadlardan Robert Martin amcamızın internet üzerinde dinlediğim The Principles
Of Agile Design konferansında nesneye yönelik tasarım(Object Oriented Design)
nedir diye izleyicilere bir soru yöneltiyordu. İzleyiciler “Gerçek dünyayı
modelleme”,”Kavramların ayrılması” .. gibi değişik cevaplar verdi. Fakat Robert
Martin kısa ve öz olarak nesneye yönelik tasarımı şu şekilde özetledi
“Bağımlılığı yönetmek(managing dependency)”. Gerçekten çok yerinde bir tespit
nesneye yönelik tasarımın başarısı için uygulamada bağımlılığın iyi yönetilmesi
ve mümkün olduğunca az olması gerekiyor. 

Aslında bağımlılığı hem kod üzerinde, hemde projeler üzerinde izlemek ve
anlamak çok kolay. Bunun için JDepend,NDepend gibi birçok gelişmiş olsada basit
olarak bağımlılığı ölçmek için iki yöntem kullanabilirsiniz. Mesela aşağıdaki
gibi bir koda bakalım ve nelere bağımlı gözden geçirelim.

```
private void tbiMesajiGonder_Click(object sender, System.EventArgs e)
{
  Database.VeriTabani clsDatabase=new SMSNET.Database.VeriTabani();
  string strSQLTel="SELECT ID,Adi+' '+Soyadi AS AdSoyadi,GSM FROM Kisiler WHERE ID IN ("+strMesajGonderilecekIDs+")";
  DataTable dtTel=clsDatabase.GetDataTable("Telefon",strSQLTel);
  PosterClass clsPosterClass=new PosterClass();
  string strSQLParametre="SELECT * FROM Parametreler WHERE ID IN (1,2,3,4) ORDER BY ID";
  DataTable dtParametreler=clsDatabase.GetDataTable("Parametreler",strSQLParametre);

  string strFirmCode="",strUserName="",strPassword="",strOriginator="";
  string strErrDefinition="";
  int iErrCode=0;
  string strMSGID="";

  if(dtParametreler.Rows.Count==4)
  {
    strFirmCode=dtParametreler.Rows[0]["Degeri"].ToString();
    strUserName=dtParametreler.Rows[1]["Degeri"].ToString();
    strPassword=dtParametreler.Rows[2]["Degeri"].ToString();
    strOriginator=dtParametreler.Rows[3]["Degeri"].ToString();
  }
  else
  {
    MessageBox.Show("Sistem SMS gönderebilmek için gerekli parametrelere ulaşamadı. Lütfen Sistem Tanımlarınızı kontrol ediniz...");
  }

  int k=0;

  for(int i=0;i<dtTel.Rows.Count;i++)
  {
    if(dtTel.Rows[i]["GSM"].ToString()!=""&&dtTel.Rows[i]["GSM"].ToString()!=null)
    {
      clsPosterClass.AddToSmsBasket(tbSMSMesaji.Text,dtTel.Rows[i]["GSM"].ToString());
      k++;
      if(k>100)
      {
        strMSGID=clsPosterClass.sendSms(strFirmCode,strUserName,strPassword,strOriginator,null,ref iErrCode,ref strErrDefinition);
        clsPosterClass.ClearSmsBasket();
      }
    }
  }
  strMSGID=clsPosterClass.sendSms(strFirmCode,strUserName,strPassword,strOriginator,null,ref iErrCode,ref strErrDefinition);
  clsPosterClass.ClearSmsBasket();
}
```

Şimdi yukarıdaki kod baktığımızda pek de iyi şeyler görmediğimiz belli oluyor
galiba. Kodu yaklaşık 4 sene önce ben yazmama rağmen pek birşey anlamıyorum
açıkcası :) Muhakkak yukarıdaki kodda birsürü problem var fakat diğer
problemlerinde büyük oranda sebebi olan en büyük problemlerden birisi kodun
birçok sınıfa bağımlı olması(High Coupling).

Şimdi kodun nelere bağımlı olduğuna bakalım.Dediğim gibi bunu anlamanın çok
basit bir yolu var bu da kodun çalışması için gerekli olan
modüllerin,sınıfların, metodların sayılması. Bunu yapabilmek için öncelikle
kodun Import kısmına bakmanızı tavsiye ederim. Import kısmında olan modüllere
zaten direk olarak bağımlıdır. Projeler arasındaki bağımlılığı ölçmek içinde
referans verdiği Dll,Jar gibi kütüphaneleri sayarak anlayabilirsiniz.Sınıflara
olan bağımlılığıda o sınıf çıktığında kod çalışmaya devam edecek mi oradan
anlayabilirsiniz.

  * Yukarıdaki koda baktığımızda ilk satırlarda Database nesnesi üzerinden SMS
    atılacak kişilerin SQL ile alındığını görüyorsunuz.Kodumuz Database’e
    bağımlı.
  * DataTable nesnesi üzerinden Telefonlar alınıyor. Kodumuz DataTable
    nesnesine yani arkaplanda olan ADO.NET teknolojisine bağımlı
  * 3. parti PosterClass nesnesi üzerinden SMS gönderimi yapılıyor. Yani
    PorterClass nesnesine ve bunu satın aldığımız firmaya bağımlıyız.

Şimdi bu bağımlılığın yol açtığı problemler neler onlara bakalım.

  * SMS sistemimiz sadece veritabanı üzerinden çalışacak. Mesela oldukça yaygın
    olan XML üzerinden aldığımız kayıtlara SMS göndermek istediğimizde bunu
    kodu değiştirmeden yapamayacağız.
  * Kodumuz DataTable yani Microsoft’ın sık sık değiştirmeyi sevdiği veri
    erişim katmanı olan ADO.NET alt yapısına bağlı. Mesela LINQ to SQL işimizi
    baya kolaylaştırırdı fakat onuda kodumuzu değiştirmeden kullanamayacağız.
  * Bir firmadan satın aldığımız PosterClass üzerinden SMS gönderiyoruz. Bunda
    bir problem yok fakat yarın birgün firma bu kütüphaneye destek vermediğinde
    ya da daha iyi alternatifler çıktığında yine değişik alternatifleri
    kullanmak hiçde kolay olmayacak.

Yukarıdaki kodda modüller, sınıflar arasındaki bağımlılığı gördük. Fakat
bağımlılık bu kadarla bitmiyor açıkcası. Birazda daha sinsi olan
metodlar,alanlar üzerindeki bağımlılığa bakalım. Aşağıdaki kodu inceleyelim

```
public class Field
{
  private string name;
  private bool allowNulls;
  private bool isPrimaryKey;
  public string DataType { get; set; }

  public Field(string name, string dataType)
  {
    this.name = name;
    DataType = dataType;
    IsPrimaryKey = false;
    AllowNulls = true;
  }

  public bool IsPrimaryKey
  {
    get { return isPrimaryKey; }
    set {isPrimaryKey = value;}
  }

  public string Name
  {
    get { return name; }
    set { name = value; }
  }


  public bool AllowNulls
  {
    get { return allowNulls; }
    set { allowNulls = value; }
  }
}

class Program
{
  public void SaveFields()
  {
    IList<Field> fields=new List<Field>();
    for (int i = 0; i < fields.Count; i++)
    {
      Field field = fields[i];
      string sqlString = GetFieldAsSQLString(field);
      //....
    }
  }

  public string GetFieldAsSQLString(Field field)
  {
    string sqlString = field.Name + " " + field.DataType;
    if (field.IsPrimaryKey)
      sqlString += " PRIMARY KEY";
    if (field.AllowNulls)
      sqlString += " NULL";
    else
      sqlString += " NOT NULL";
    return sqlString;
  }
}
```

Yukarıdaki koda baktığımızda ilk başta çok fazla problem görmeyebilirsiniz
fakat Field sınıfının içerisindeki alanların kodun çoğu yerinde bu şekilde
kullanıldığında kodumuz bu sefer de Field sınıfının alanlarına bağımlı oluyor.
Mesela GetFieldAsSQLString metoduna baktığımızda Field sınıfının alanları
üzerinde bazı işlemler yapıp bir string oluşturuyor. Şunu düşünün DataType
alanı artık string olarak değilde bir sınıf olarak tutacağımızı düşünün.
Kodumuzun çoğu yeri GetFieldAsSQLString metodu gibi Field sınıfının alanlarını
bu şekilde kullanıyorsa DataType alanını değiştirdiğimizde birçok yerde hata
verecek ve kodun çoğu değişmek zorunda kalacak.

Kısaca bağımlılığın zararlarını sıralayacak olursak :

  * Üzerinde çalışan yazılım geliştiricilerin,özellikle benim gibi şuanda
    şanssız kesimden olan yani kodu kendi yazmayıp yönetmek zorunda olanların
    sistemin bütününü anlamak zorunda olmalarıdır. Çünkü bütün
    sınıflar,modüller birbirine bağımlıdır.
  * Yapmak zorunda olduğunuz değişikliklerin birçok sınıfı etkilemesi
    dolayısıyla daha uzun sürmesi vede ne kadar süreceğinin tahmin edilememesi.
    Herhalde ne demek istediğimi anladınız. Proje yöneticiniz gelip size bu
    değişiklik ne kadar sürer dediğinde çoğu zaman “Biryerde bir problem
    çıkmazsa şu kadar sürer..” dediğinizi hatırlıyorsunuzdur.Çoğu zamanda eğer
    bağımlılık fazla ise biryerde birşeyler çıkıp işinizi uzatacığına emin olun
    :)
  * Değişen teknolojiye adaptasyon,farklı alternatifler arasında geçiş hiçte
    kolay olmayacaktır. Çünkü kodun heryeri o teknolojiye bulaşmış durumdadır.

Nesnelerin birbirleri ile iletişim halinde görevlerini yerine getirmelerinden
dolayı sıfır bağımlılık genelde mümkün olmasada bağımlılığın az olması çoğu
durumda daha makbüldür.Bu yüzden bağımlılığı iyi bir şekilde yönetmek hem
kalite yönünden,hemde zaman bakımından bize oldukça kazanç sağlayacaktır.

Peki bunları niye yazdım? :) Aşırı bağımlılığın çoğu durumda kötü olduğunu size
ispatlayabilmek için :) Umarım sizinde kafanıza yatmıştır. Yukarıdaki kodların
bağımlılığı azaltılmış şekilde nasıl yazarıza şuanda değinmeyeceğim çünkü 
yazdığım ve yazacağım birçok konu bununla alakalı aslında. Dependency
Inversion,Dependency Injection… birçoğunun adını duymuştursunuz. Bundan sonraki
birkaç yazımda bağımlılığı azaltan, kodun kalitesini arttıran işlerimizi
kolaylaştıran birkaç yönteme değineceğim.O yüzden bu kodlar işimize yarıyacak
gibi :)

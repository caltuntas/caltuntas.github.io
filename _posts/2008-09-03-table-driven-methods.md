---
layout: post
title: "Refactoring : Table Driven Methods"
description: "Refactoring : Table Driven Methods"
date: 2008-09-03T07:00:00-07:00
tags: refactoring
---

Değerli arkadaşım Yahya ile ASP.MVC frameworkü pratik olarak öğrenmek için
MyMovieCollection adında open-source bir proje geliştiriyoruz. Film koleksiyonu
yapmayı sevdiğim için ancak böyle bir proje aklıma geldi. :) Proje basit olarak
kullanıcıların filmlerini saklamasını,düzenlemesini .. gibi işlemleri sağlıyor.
Geçen gün projede yaptığım basit bir  refactoring if-else, switch-case
yapılarından kurtulmak için oldukça güzel bir yöntem olduğu için buraya da
yazmak istedim.

Projede her filme kullanıcılar tarafından belirli bir puan
verilebiliyor.Listeden seçilen elemana göre Filmlerde verilen puanın düştüğü
belirli bir puan aralığına göre “İyi,Kötü,Çok iyi ” tarzı sınıflanıyorlar.
Mesela 0-2 arası çok kötü 2-4 arası kötü gibi.Şimdi sınıfı aşağıya yazıp
inceleyelim.

```
public class PointScale
{
  public const string ALL = "Lütfen Seçiniz";
  public const string VERYBAD = "Çok Kötü";
  public const string BAD = "Kötü";
  public const string NOTBAD = "Fena Sayılmaz";
  public const string GOOD = "İyi";
  public const string EXCELLENT = "Çok iyi";

  private readonly double minPoint;
  private readonly double maxPoint;
  private readonly string scaleName;
  private readonly int scaleID;

  public PointScale(double minPoint, double maxPoint, string scaleName, int scaleID)
  {
    this.minPoint = minPoint;
    this.maxPoint = maxPoint;
    this.scaleName = scaleName;
    this.scaleID = scaleID;
  }

  public static PointScale ParseScale(int scale)
  {
    switch (scale)
    {
      case 1:
        return new PointScale(0, 1.99, VERYBAD, 1);
      case 2:
        return new PointScale(2, 3.99, BAD, 2);
      case 3:
        return new PointScale(4, 5.99, NOTBAD, 3);
      case 4:
        return new PointScale(6, 7.99, GOOD, 4);
      case 5:
        return new PointScale(8, 10, EXCELLENT, 5);
      default:
        return new PointScale(0, 10, ALL, 0);
    }
  }

  public virtual double MinPoint
  {
    get { return minPoint; }
  }

  public virtual double MaxPoint
  {
    get { return maxPoint; }
  }

  public virtual string ScaleName
  {
    get { return scaleName; }
  }

  public virtual int ScaleID
  {
    get { return scaleID; }
  }       
}
```

Şimdi yukarıdaki sınıfın ParseScale metoduna bakmanızı istiyorum.Kullanıcı bu
metodu çağırarak bir numara veriyor ve bu numaraya karşılık gelen PointScale
nesnesi geri dönüyor. Gördüğünüz gibi metod içinde birçok switch-case yapısı
mevcut.Şimdi bu switch-case yapılarından nasıl kurtulabiliriz biraz düşünün.
Hemen akla gelmesede çok güzel ve basit bir yöntemle bu tarz koşullu yapılardan
kolaylıkla kurtulabiliriz. Yeni halini yazalım ve incelemeye devam edelim.

```

public class PointScale
{
  public const string ALL = "Lütfen Seçiniz";
  public const string VERYBAD = "Çok Kötü";
  public const string BAD = "Kötü";
  public const string NOTBAD = "Fena Sayılmaz";
  public const string GOOD = "İyi";
  public const string EXCELLENT = "Çok iyi";

  private static readonly IDictionary<int, PointScale> intToPointScale 
    = new Dictionary<int, PointScale>()
    {
      {0,new PointScale(0,10,ALL,0)},
        {1,new PointScale(0, 1.99, VERYBAD, 1)},
        {2,new PointScale(2, 3.99, BAD, 2)},
        {3,new PointScale(4,5.99,NOTBAD,3)},
        {4,new PointScale(6,7.99,GOOD,4)},
        {5,new PointScale(8,10,EXCELLENT,5)}
    };
  private readonly double minPoint;
  private readonly double maxPoint;
  private readonly string scaleName;
  private readonly int scaleID;

  public PointScale(double minPoint, double maxPoint, string scaleName, int scaleID)
  {
    this.minPoint = minPoint;
    this.maxPoint = maxPoint;
    this.scaleName = scaleName;
    this.scaleID = scaleID;
  }

  public static PointScale ParseScale(int scale)
  {
    if (intToPointScale.ContainsKey(scale))
      return intToPointScale[scale];

    return new PointScale(0, 10, ALL, 0);
  }

  public virtual double MinPoint
  {
    get { return minPoint; }
  }

  public virtual double MaxPoint
  {
    get { return maxPoint; }
  }

  public virtual string ScaleName
  {
    get { return scaleName; }
  }

  public virtual int ScaleID
  {
    get { return scaleID; }
  }        
}
```
Yukarıdaki ParseScale metoduna baktığımızda switch-case yapılarının ortadan
kalktığını görüyoruz. Bunu basit olarak verilen numaraya karşılık gelecek olan
PointScale nesnelerini tablo mantığı ile bir IDictionary intToPointScale
nesnesinde eşleştirerek yapıyoruz. Ardından metod içinde verilen numaraya
karşılık gelen nesne switch-case,if-else kontrolü yapmadan return
intToPointScale[scale]; sayesinde geri dönülüyor. Bu şekilde uygulama oldukça
esnek hale geldi. Dictionary içinde sakladığımız nesneleri istersek dışarıdan
bir XML, yada Veritabanından alabiliriz ve herhangi bir if-else eklemek zorunda
kalmayız. Bu tarz Tablo mantığı ile çalışan metodlara Table Driven Methods
deniliyor. Çoğu durumda oldukça faydalı olabiliyor.

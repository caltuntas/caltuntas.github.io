---
layout: post
title: "Eski Kodu Test Etmek : Subclass and Override"
description: "Eski Kodu Test Etmek : Subclass and Override"
date: 2010-03-16T07:00:00-07:00
tags: testing
---

Eğer sıfırdan başlamış bir projede(Green Field) başından beri çalışan şanslı insanlardan değilseniz mutlaka sizden daha önce ve şuanda şirkette olmayan birisinin yazdığı anlaşılamaz kodu değiştirmek zorunda kalmıştırsınız. Benimde başıma sık sık gelen bu tarz durumlarda insan biraz kendini Rus-Ruleti oynar konumunda bulabiliyor. Bir yandan şeytan kodu değiştirip riski göze almanızı söylerken, bir yandan içinizden gelen ses hata yapmamanız için tekrar tekrar kodu kontrol edip hata yapmadığınızdan emin olmanızı söylüyor.

Bu tarz durumlarda eğer değiştireceğiniz kod uygulama açısından kritik bir kod ise onun için Unit Test yazıp kodun şuandaki durumunu test altına alıp ardından değiştirip bir şeyleri bozup bozmadığınızı bu testler ile kontrol etmek gidilmesi gereken en güvenilir yollardan birisi. Tabi bu yöntemde o kadar kolay olmayabiliyor bende her zaman yaptığımı söyleyemem . Dediğim gibi kodu değiştirmek eğer kritik önem taşıyorsa ve risk içeriyorsa elimden geldiğince testle ile kendimi sağlama alıp bu şekilde devam etmeye çalışıyorum.

Bu tarz bir durumda kodu test altına almanın her zaman kolay olmadığını yukarıda belirtmiştim. Çünkü genelde eski kodlar Bağımlılığı oldukça yüksek, testlerden yoksun kodlar olduğu için test altına almak istediğinizde beklemediğiniz engellerle karşılaşabiliyorsunuz.

Aşağıdaki gibi daha önceden yazılmış bizim için kritik önem arzeden ve değiştirmemiz gereken bir kodumuz olduğunu düşünün.


```cs
public class PriceCalculator
{
  private Database database;

  public PriceCalculator()
  {
    database =new Database();
  }

  public double CalculateShippingCost(Order order)
  {
    if(order.Total>100)
    {
      return order.Total*GetGoldenOrderTotalRatio();
    }

    if(order.Total> && order.Total<100)
    {
      return order.Total*GetBronzeOrderTotalRatio();
    }

    return order.Total*GetNormalOrderTotalRatio();
  }

  private double GetGoldenOrderTotalRatio()
  {
    return (double)database.ExecuteScalar("SELECT Ratio FROM OrderShippingRatio WHERE Type='Golden'");
  }

  private double GetBronzeOrderTotalRatio()
  {
    return (double)database.ExecuteScalar("SELECT Ratio FROM OrderShippingRatio WHERE Type='Bronze'");
  }

  private double GetNormalOrderTotalRatio()
  {
    return (double)database.ExecuteScalar("SELECT Ratio FROM OrderShippingRatio WHERE Type='Normal'");
  }
}
``` 

Yukarıdaki gördüğünüz sınıfın bizim için verilen siperişin ulaştırma maliyetini hesaplayan bir sınıf olduğunu düşünün. Burada gördüğünüz gibi siperiş tutarı eğer 100’den büyük ise belirli bir oranda altın indirim yaparak hesaplıyor, 50 ile 100 arasındaysa belirli oranda bronz indirim yapıp hesaplıyor. Bizden yapmamız istenen bu mantığı değiştirip 50 ile 100 aralığı olan bronz indirim mantığını sipariş tutarı 80 ile 100 arasına çekmek.

Burada kodun çok basit olduğunu unutun ve gerçekten çok daha karmaşık hesaplamaların olduğu bir metodu değiştirmek istediğinizi düşünün. Bunu yapmadan önce dediğim gibi bu konu test altına almak oldukça güvenilir yoldan ilerlemenizi sağlayacaktır. Bu yüzden bende öyle yapıp yukarıdaki kod için aşağıdaki gibi testimi yazmaya başlıyorum.

```cs
[TestFixture]
public class PriceCalculatorTest
{
  [Test]
  public void CalculateGoldenOrderShippingCost()
  {
    PriceCalculator calculator =new PriceCalculator();
    Order goldenOrder =new Order();
    goldenOrder.Total = 200;

    Assert.AreEqual(10, calculator.CalculateShippingCost(goldenOrder));
  }

  [Test]
  public void CalculateBronzeOrderShippingCost()
  {
    PriceCalculator calculator = new PriceCalculator();
    Order bronze = new Order();
    bronze.Total = 90;

    Assert.AreEqual(9, calculator.CalculateShippingCost(bronze));
  }

  [Test]
  public void CalculateNormalOrderShippingCost()
  {
    PriceCalculator calculator = new PriceCalculator();
    Order normal = new Order();
    normal.Total = 50;

    Assert.AreEqual(7, calculator.CalculateShippingCost(normal));
  }
}
``` 

Yukarıdaki testlerde 3 durumu da test içerisine alacak test kodunu yazdım. Eğer sipariş tutarı 200 ise nakliye oranının %5 olduğunu düşünüp sonucun 10 olması gerektiğini söylüyorum. Eğer tutarı 90 olan bronz sipariş nakliye oranının %10 ise sonucun 9 olması gerektiğini yazıyorum. Ve son olarak da tutar 50 için nakliye oranı %14 ise sonucun 7 olduğunu test eden kodu yazıyorum. Testleri çalıştırdığımda aşağıdaki gibi bir Unit Test hatası karşıma çıkıyor

```
PriceCalculatorTest.CalculateNormalOrderShippingCost : …AssertionException: Expected: 7 But was: 950.0d
``` 

Sebebine baktığımda ise Database üzerinde kayıtlı olan oranların farklı olduğu görüyorum. Bu yüzden beklediğim sonuçlar çıkmıyor. Burada gidip database içerisinden test için değerleri değiştirmek pek mantıklı olmaz.Test kodunu database’deki değerlere göre değiştirmek de pek doğru değil çünkü testimin database’den bağımsız olmasını istiyorum. Başkasının ben farkında olmadan farklı bir değer girdiğinde testlerimin fail etmesini istemiyorum. Yani kısacası burada kısmen gerçek anlamda kontrolün testlerde olmasını her hangi bir dış etkenden etkilenmemesini istiyorum. Daha önceden yazılmış eski kod için bunu yapmanın yollarından biri Subclass and Override verilen teknik. Bunu ilk defa Working Effectively With Legacy Code kitabından öğrenmiştim.  

Bizim burada kontrol etmek istediğimiz aslında kodun biraz kötü yazılmış olmasında kaynaklanan PriceCalculator sınıfının içerisindeki GetGoldenOrderTotalRatio tarzı metodlar. Çünkü bu metodlar direk olarak Database üzerinde sorgu çalıştırarak testlerimizde kontrolün bizden database tarafındaki değerlere geçmesine sebep oluyor. Eğer bunları kontrol altına alırsak testlerimizde istediğimiz sonuçları elde edebiliriz.

Subclass and Override tekniğini basit olarak test için kontrol etmeniz gereken metodu override ederek test ortamında istediğiniz değerleri dönmesini sağlamak oldukça basit ve faydalı bir yöntem. Bu tekniği kullanarak PriceCalculator sınıfımı aşağıdaki gibi değiştiriyorum.

```cs
public class PriceCalculator
{
  //Diğer kodlar.....

  protected virtual double GetGoldenOrderTotalRatio()
  {
    return (double)database.ExecuteScalar("SELECT Ratio FROM OrderShippingRatio WHERE Type='Golden'");
  }

  protected virtual double GetBronzeOrderTotalRatio()
  {
    return (double)database.ExecuteScalar("SELECT Ratio FROM OrderShippingRatio WHERE Type='Bronze'");
  }

  protected virtual double GetNormalOrderTotalRatio()
  {
    return (double)database.ExecuteScalar("SELECT Ratio FROM OrderShippingRatio WHERE Type='Normal'");
  }
}
``` 

Gördüğünüz gibi private olaran metodlar protected virtual olarak değiştirdim. Böylece başka bir sınıfı bu sınıftan türetip bu metodları override edebilirim ve istediğim değerleri döndürebilirim. Bu da testlerimde bu metodların database’e çağrı yapmadan benim istediğim değerleri döndürmemi sağlar kısacası kontrol tekrar testlere geçer.Bu arada eğer yukarıdaki kod bir Java kodu olsaydı
Java’nın sevdiğim bir özelliği olan metodlar default olarak virtual olduğu için sadece protected yapmam yeterli olacaktı.Test kodlarımı da aşağıdaki gibi değiştiriyorum.

```cs
[TestFixture]
public class PriceCalculatorTest
{
  class TestingPriceCalculator : PriceCalculator
  {
    protected override double GetGoldenOrderTotalRatio()
    {
      return 0.05;
    }

    protected override double GetBronzeOrderTotalRatio()
    {
      return 0.1;
    }

    protected override double GetNormalOrderTotalRatio()
    {
      return 0.12;
    }
  }

  [Test]
  public void CalculateGoldenOrderShippingCost()
  {
    PriceCalculator calculator =new TestingPriceCalculator();
    Order goldenOrder =new Order();
    goldenOrder.Total = 200;

    Assert.AreEqual(10, calculator.CalculateShippingCost(goldenOrder));
  }

  [Test]
  public void CalculateBronzeOrderShippingCost()
  {
    PriceCalculator calculator = new TestingPriceCalculator();
    Order bronze = new Order();
    bronze.Total = 90;

    Assert.AreEqual(9, calculator.CalculateShippingCost(bronze));
  }

  [Test]
  public void CalculateNormalOrderShippingCost()
  {
    PriceCalculator calculator = new TestingPriceCalculator();
    Order normal = new Order();
    normal.Total = 50;

    Assert.AreEqual(6, calculator.CalculateShippingCost(normal));
  }
}
``` 

Yukarıdaki test kodlarında gördüğünüz gibi TestingPriceCalculator adından PriceCalculator’dan türeyen bir sınıf oluşturdum ve virtual metodları override ederek istediğim değerlerin dönmesini sağladım. Normalde PriceCalculator olarak test edilen yerleride bu sınıfla değiştirdiğimde test kodlarının istediğim şekilde çalıştığını görüyorum ve testleri çalıştırdığımda geçtiğini görüyorum.

Gördüğünüz gibi varolan kodda çok küçük değişiklikler yaparak kodu Unit test altına aldık. Bu değişiklikler benimde hoşuma gitmesede eski kodlarda kodu test edebilmek için bu tarz değişiklikler yapmak zorunda kalabiliyoruz. Bu kodu başka şekillerde de test edebilirdik bu teknik onlardan sadece biri. Eski kodu test ederken zaman, yapabileceğiniz değişikliklerin kapsamı gibi etkenler oldukça önemlidir. Bu yüzden elinizdeki araçlardan size en uygun olanını seçmek faydanıza olacaktır.

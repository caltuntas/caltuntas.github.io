---
layout: post
title: "Abstract nedir, ne zaman kullanılır?"
description: "Abstract nedir, ne zaman kullanılır?"
date: 2008-06-02T07:00:00-07:00
tags: oop
---

Abstract sınıflar içerisinde normal yani içi dolu metodların,değişkenlerin ve
interface’lerdeki gibi abstract (boş) metodların tanımlanabildiği yapılardır.Bu
sınıflar new kelimesi ile oluşturulamazlar.

Hemen uygulamaya geçelim örnek olarak arabalarla alakalı geliştirdiğimiz bir
uygulamamız olsun. Sistemimizde bulunan çeşitli marka arabalara ait bazı
özellikleri ekranda göstersin. Arabaların ağırlık,renk,model gibi ortak
özellikleri ve cant kalınlığı,devir sayısı gibi kendilerine has özellikleri
mevcut. Bunu ifade eden aşağıdaki gibi kodumuzu yazalım.

```
class Araba{
  private int agirlik;
  private String renk;
  private String model;

  public int getAgirlik() {
    return agirlik;
  }
  public void setAgirlik(int agirlik) {
    this.agirlik = agirlik;
  }
  public String getRenk() {
    return renk;
  }
  public void setRenk(String renk) {
    this.renk = renk;
  }
  public String getModel() {
    return model;
  }
  public void setModel(String model) {
    this.model = model;
  }
}

class Mercedes extends Araba{
  private int cantKalinligi;

  public int getCantKalinligi() {
    return cantKalinligi;
  }
  public void setCantKalinligi(int cantKalinligi) {
    this.cantKalinligi = cantKalinligi;
  }
}

class Ford extends Araba{
  private int devirSayisi;

  public int getDevirSayisi() {
    return devirSayisi;
  }
  public void setDevirSayisi(int devirSayisi) {
    this.devirSayisi = devirSayisi;
  }
}

class KullaniciEkrani{
  public void goster(Araba[] arabalar){
    for (int i = 0; i < arabalar.length; i++) {
      Araba araba = arabalar[i];
      System.out.println("Agirlik : "+araba.getAgirlik());
      System.out.println("Model : "+araba.getModel());
      System.out.println("Renk : "+araba.getRenk());
    }
  }
}

class AnaProgram{
  public static void main(String[] args) {
    Araba ford =new Ford();
    ford.setAgirlik(1000);
    ford.setModel("Fiesta");
    ford.setRenk("Gri");
    Araba mercedes=new Mercedes();
    mercedes.setAgirlik(2000);
    mercedes.setModel("E200");
    mercedes.setRenk("Siyah");

    Araba arabalar[]=new Araba[]{mercedes,ford};
    KullaniciEkrani ekran =new KullaniciEkrani();
    ekran.goster(arabalar);
  }
}
```
Yukarıdaki kodda gördüğünüz gibi Polymorphism sayesinde KullaniciEkrani sınıfı
arabaların markalarından habersiz hepsini gösterebiliyor. Araba sınıfından
türeyen her sınıf KullaniciEkrani sınıfında gösterilebiliyor.Buraya kadar gayet
güzel. Şimdi müşteri bizden bu ekranda araçların saatte kaç litre benzin
yaktıklarını da göstermemizi istedi.Fakat burada şöyle bir problem var her
marka arabanın kaç litre benzin yaktığı kendi ağırlığına göre farklı
hesaplanıyor.Araba sınıfına saatte yaktığı litre diye değişken eklesek
olmayacak çünkü Mercedes bunu hesaplamak için farklı katsayı ile çarpıyor Ford
farklı sayı ile çarpıyor.İşte bu noktada yardımımıza Abstract kavramı yetişiyor
ve kodumuzu şöyle değiştiriyoruz.

```
abstract class Araba{
  private int agirlik;
  private String renk;
  private String model;

  public int getAgirlik() {
    return agirlik;
  }
  public void setAgirlik(int agirlik) {
    this.agirlik = agirlik;
  }
  public String getRenk() {
    return renk;
  }
  public void setRenk(String renk) {
    this.renk = renk;
  }
  public String getModel() {
    return model;
  }
  public void setModel(String model) {
    this.model = model;
  }

  public abstract int saateYaktigiBenzinLitresi();
}

class Mercedes extends Araba{
  private int cantKalinligi;

  public int getCantKalinligi() {
    return cantKalinligi;
  }
  public void setCantKalinligi(int cantKalinligi) {
    this.cantKalinligi = cantKalinligi;
  }

  public int saateYaktigiBenzinLitresi() {
    return getAgirlik()*2;
  }
}

class Ford extends Araba{
  private int devirSayisi;

  public int getDevirSayisi() {
    return devirSayisi;
  }
  public void setDevirSayisi(int devirSayisi) {
    this.devirSayisi = devirSayisi;
  }

  public int saateYaktigiBenzinLitresi() {
    return getAgirlik()*1;
  }
}

class KullaniciEkrani{
  public void goster(Araba[] arabalar){
    for (int i = 0; i < arabalar.length; i++) {
      Araba araba = arabalar[i];
      System.out.println("Agirlik : "+araba.getAgirlik());
      System.out.println("Model : "+araba.getModel());
      System.out.println("Renk : "+araba.getRenk());
      System.out.println("Yaktigi Lt. Benzin : "+araba.saateYaktigiBenzinLitresi());
    }
  }
}

class AnaProgram{
  public static void main(String[] args) {
    Araba ford =new Ford();
    ford.setAgirlik(1000);
    ford.setModel("Fiesta");
    ford.setRenk("Gri");
    Araba mercedes=new Mercedes();
    mercedes.setAgirlik(2000);
    mercedes.setModel("E200");
    mercedes.setRenk("Siyah");

    Araba arabalar[]=new Araba[]{mercedes,ford};
    KullaniciEkrani ekran =new KullaniciEkrani();
    ekran.goster(arabalar);
  }
}
```

Gördüğünüz gibi yukarıdaki kodda Araba sınıfına public abstract int
saateYaktigiBenzinLitresi(); adında bir soyut metod ekledik. Bir sınıfın
abstract metod bulundurabilmesi için Abstract bir sınıf olması gerekir. İkinci
olarak Araba sınıfını abstract olarak değiştirdik. Bunu yapmamızın sebebi Araba
sınıfı tarafından bu hesaplama işleminin nasıl yapılacağının bilinmemesidir.
Yani bu hesaplamayı kendi yapmayıp kendinden türeyen sınıfların yapmasını şart
koşmuştur. Bu hesaplamayı gördüğünüz gibi her marka araba sınıfı kendi
katsayılarına göre kendi içinde yapıyor. Yukarıda Mercedes ve Ford sınıflarında
saateYaktigiBenzinLitresi() metodunun nasıl farklı şekillerde yazıldığını
gördünüz.Bu sayede KullaniciEkrani sınıfında Araba sınıfındaki
saateYaktigiBenzinLitresi() metodunu çağırdığında her marka araba için kendi
içlerinde yazdıkları saateYaktigiBenzinLitresi() metodu çalışacaktır.

Dikkat ederseniz uygulamamızada new kelimesi ile Araba nesnelerini zaten
oluşturmuyorduk. Bizim oluşturduğumuz nesneler new Merceses,Ford gibi
nesnelerdi.O yüzden Araba sınıfını normal sınıf tanımlamak tasarım bakımından
zaten anlamsız.Burada Araba sınıfı kodun diğer kısımlarından Mercedes ve Ford
gibi belirgin sınıfları soyutlamak ve sınıflarındaki ortak
özellikleri(agirlik,renk,model) kodu tekrar yazmamak için oluşturulmuş bir
soyut sınıf.Kod olarak baktığımızda KullaniciEkrani sınıfı Mercedes ve Ford
sınıflarından habersiz sadece Araba sınıfını biliyor.

Gördüğünüz gibi Abstract sınıflar daha çok nesneler arasındaki ortak
özelliklerin veya metodların bir üst sınıfta toplanarak kod tekrarını önlemek
ve kodu diğer sınıflardan soyutlayarak değişimin etkisini en alt düzeye
indirmektir.

Aklınızda bulunsun herhangi bir sınıfı Abstract bir sınıftan türetmek
istediğinizde genel olarak dikkat etmeniz gereken durum aralarında IS-A
özelliği olmasıdır.Yani Mercedes bir Arabadır, Ford bir Arabadır diyebiliriz.

Kısaca özetleyecek olursak Abstract sınıflar aralarında IS-A(..dır,..dir)
ilişkisi olan sınıflardaki ortak özelliklerin ve metodların soyut üst sınıfda
toplanması ondan sonra uygulamada bu soyut sınıfın kullanılarak uygulamanın
diğer sınıflarından habersiz halde çalışmasını sağlamaktır. Nesneye yönelik
tasarımda uygulamayı iyi soyutlamalar üzerine kurmak oldukça önemlidir.
Uygulamada soyutlama oluşturmak için kullanılan önemli kavramlardan olan
Abstract sınıfları küçük bir örnekle inceledik. Yakında diğer soyutlama
mekanizması olan Interface kavramına değineceğiz. Tekrar görüşmek üzere…

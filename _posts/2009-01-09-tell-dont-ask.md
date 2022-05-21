---
layout: post
title: "Tell Don’t Ask Principle"
description: "Tell Don’t Ask Principle"
date: 2009-01-09T07:00:00-07:00
tags: principles
---

![Ring](/img/telldontask/oneRing.jpg) Herşey prosedürel programlamayla başladı.
Bazılarımız büyük programlar yazdı, bazılarımız ise küçük birer hesap makinası
yaparak kıyısından geçiverdi :) Ama hepimiz prosedürel programlamayı çok
sevdik. Programlarımızı yazarken güzel güzel yapılar(struct,record),veri
tipleri(int,double,char…) kullanırdık, yapılarımızı,verilerimizi metodlarımıza
parametre olarak gönderirdik onlarda gereken işi güzelce yapardı.Tabi sonradan
yazdığımız programlar 100.000 satırlar boyutuna ulaşmaya başlayınca o masum
masum kod dosyalarımızın üst tarafında tanımlı yapılar bize düşman görünmeye,
en az 5 tane parametre alan fonksiyonlarımız da yönetilmeme ye ve pekde hoş
gözükmemeye başladı. Ardından kulaklarımıza Mordor diyarından şu nağmeler
gelmeye başladı. (Yüzüklerin efendisini çok sevdiğim belli oluyor herhalde:) )

> One Object to rule them all, One Object to find them,
>
> One Object to bring them all and in the Class bind them

Nağmelerde, hepsini ; yani veri ve fonksiyonları bir araya getirecek, ondan
sonra onları Class(sınıf) içerisinde birleştirecek bir güç olan nesneden
bahsediyordu. Hepimiz bu nağmelerin içerisinde olan nesnelerin büyüsüne kapıldık
ve o aşamadan sonra kendimizi Object Oriented rüzgarının önünde buluverdik. 
Artık hepimiz bu gücü kullanıp daha yönetilebilir, okunabilir, esnek yazılımlar
geliştirmek için can atıyorduk. Fakat prosedürel programlamayı o kadar çok
sevmiştik ki eski alışkanlıklarımızdan bir türlü vazgeçemiyorduk. İlk aşklar
unutulmaz derler herhalde ondan olsa gerek :) Artık benim PObject Oriented
olarak adlandırdığım nesneler ile prosedürel programlama yapıyorduk.

Her ikisinin sevdiğimiz özelliklerini kullanıp güzel güzel programlar yazmaya
başlamıştık. Verileri bu sefer struct,record gibi yapılar içerisine değilde
sınıflar içerisine koymaya başladık.Fonksiyonlarımızıda uygun bir yer
bulabiliyorsak oraya değilse sağa,sola yerleştiriyorduk. Fakat yine işler
projeler büyüdükçe çığırından çıkmaya başladı. Projeler büyüdükçe,
değişiklikler yapılmaya başladıkça işler oldukça zahmetli olmaya başladı. Küçük
bir talepteki değişiklik uygulamanın birçok yerinde değişiklik yapmamızı
gerektiriyor ve bu değişiklik sonucunda ortaya çıkan hatalarla baş edememeye
başlıyorduk. Aslında biraz da kafamız karışmıştı. Nağmelerde duyduğumuz o güçlü
nesneye yönelik programlama aslında pekde güçlü olmadığını düşünüyorduk.

Kaptırmışım kendimi yüzüklerin efendisi falan araya girince hikayeyi fazla
uzattım kusura bakmayın :) Aslında problem bu noktada geliştirdiğimiz
uygulamada iş mantığının nesnelerin içinde değilde uygulamanın geneli içine
dağılmış olması. Yani en temel nesneye yönelik programlama prensibi verilerin
ve verileri işleyen metodların bir arada bulunması gerçekleşmediğinden dolayı
uygulama geneline artan Bağımlılık(Dependency,High Coupling) sorunlarının yol
açtığı problemlerdir.

Bu sorunların önüne geçebilmek ve sınıflara sorumluluğu daha düzgün atayıp, iş
mantığını gerçekten olması gereken yere koymak için kullanılan prensiplerden
biride Tell Don’t Ask Principle yani “Sorma, söyle” prensibidir.

> Procedural code gets information then makes decisions. Object-oriented code
> tells objects to do things.
>
> — Alec Sharp

Alec Sharp’ın dediği gibi prosedürel kod veriyi alır ve o veri üzerinden
kararlar verir. Object oriented kod ise nesnelere yapmaları gereken şeyleri
söyler. Bunu meşhur gazeteci çocuk, cüzdan problemi üzerinde örneklerle
inceleyelim. İlk olarak nerede okumuştum hatırlamıyorum ama bu prensibi
anlamama kod ve kavramsal olarak oldukça yardımcı olmuştu. Aynı örnek üzerinden
devam edelim.

## Örnek

Gazeteci arkadaşımız her sabah bisikletine atlayıp ev ev dolaşıp gazete
dağıtıyor. Haftalıkta müşterilerinden gazete paralarını topluyor.Para
toplayacağı müşterilerin listesi elinde alıp kapı kapı dolaşıyor ve ücretleri
alıyor. Ardından topladığı hasılatı patronuna teslim ediyor.İlk olarak
programımızı şu şekilde yazalım.

```cs
public class Cuzdan {
  private double para;

  Cuzdan(double para) {
    this.para =para;
  }

  public double getPara() {
    return para;
  }

  public void setPara(double para) {
    this.para = para;
  }
}

public class Gazeteci {
  private double hasilat =0;
  public void odemeAl(Musteri musteri,double miktar){
    if(musteri.getCuzdan().getPara()<miktar){
      throw new RuntimeException("Cüzdanki para yeterli değil.");
    }else{
      musteri.getCuzdan().setPara(musteri.getCuzdan().getPara()-miktar);
      hasilat +=miktar;
    }
  }

  public double getHasilat() {
    return hasilat;
  }
}

public class Musteri {
  private String adi;
  private Cuzdan cuzdan;

  public Musteri(String adi,double para) {
    this.cuzdan =new Cuzdan(para);
    this.adi =adi;
  }

  public Cuzdan getCuzdan() {
    return cuzdan;
  }

  public String getAdi() {
    return adi;
  }
}

public class Main {
  public static void main(String[] args) {
    Musteri ahmetAmca =new Musteri("Ahmet",100);
    Musteri bakkalMehmet =new Musteri("Mehmet",50);
    Musteri kasapAli =new Musteri("Ali",80);

    List<Musteri> musteriler =new ArrayList<Musteri>();
    musteriler.add(ahmetAmca);
    musteriler.add(bakkalMehmet);
    musteriler.add(kasapAli);

    Gazeteci cihat =new Gazeteci();

    for(int i=0; i<musteriler.size(); i++){
      Musteri musteri =musteriler.get(i);
      try{
        cihat.odemeAl(musteri, 60);
      }
      catch(Exception ex){
        System.out.println("Tahsilat yapılamadı! Müşteri adı : "+musteri.getAdi());
      }
    }
    System.out.println("Toplanan hasılat miktarı : "+cihat.getHasilat());
  }
}
```

Prosedürel stili o kadar çok seviyoruz ki muhtemelen yukarıdaki kodda pek bir
problem göremeyeceğiz.Yanılmıyorum değilmi?Çünkü ilk başlarda bu tarz kodlar
bana süper Object Oriented kodlar gibi geliyordu ve açıkçası biri bana o zaman
bu kodda problem var dese gülerdim :)

Probleme teknik olarak değilde gerçek hayat problemi olarak bakalım. Evinize
gelen gazeteciye cüzdanınızı verip içerisinden ne kadar lazımsa al kardeş
dermisiniz? Eğer öyleyse sizin gazeteciniz olmayı isterdim :) Çoğumuzun
cüzdanını vermeyeceğini düşünüyorum açıkcası.Gazeteciye “kardeş ne kadar lazım
söyle” diye sorup ona göre parayı cüzdanımızdan çıkarıp öyle veririz. Bu
koddaki problemde bu. Gazeteciye aslında cüzdan nesnesi ile cüzdanımızı
veriyoruz gazeteci önce bi içerisine bakıyor gerekli para varmı ardından varsa
içerisinden gereken parayı alıyor.

Tell Don’t Ask(sorma, söyle) presibinin belirttiği gibi aslında biz burada
Musteri ve Cuzdan nesnelerine surekli sorular soruyoruz ve ardından sorduğumuz
soruların cevabına göre bazı işlemleri o nesneler yerine biz yapıyoruz.
Musteriye sordugumuz soru getCuzdan(), Cuzdan nesnesine sordugumuz soru ise
getMiktar() metodları.Bu yüzden Musteri nesnesinin iç yapısını öğrenmiş
oluyoruz.Mesela müşterinin parayı cüzdanında taşıdığını biliyoruz. Ya müşteri
bize parasını evdeki kasasından vermek isterse?Gazeteciye tutup “Al kasayı
kardeş içerisinden ne kadar lazımsa o kadar al ” mı diyeceğiz? :) Dolayısıyla
nesneler arasındaki bağımlılık(coupling) artıyor. Uygulamada bu şekilde müşteri
nesnesinin içerisindeki alanlara soru sorup ona göre karar verip çeşitli işlem
yaptıran sınıflar ne kadar artarsa müşterinin iç yapısını değiştirmemiz o kadar
zorlaşıyor. Örnek olarak müşterinin artık parayı Cüzdan’dan değilde kredi
kartından vereceğini düşünelim. Hangi sınıfları değiştirmemiz gerekir onlara
bakalım.

Şimdi yeni sınıfımız Kredi kartına göre sınıflarımızın düzeltilmiş halini
yazalım. Bakalım bir sınıfdaki değişiklik yüzünden kaç sınıfı değiştirmek
zorunda kalacağız.Ana sınıf değişmediği için onu yazmıyorum. Diğer değişen
sınıfları yeni halleri ile aşağıya yazıyorum.

```cs
public class Gazeteci {
  private double hasilat =0;
  public void odemeAl(Musteri musteri,double miktar){
    if(musteri.getKrediKarti().getLimit()<miktar){
      throw new RuntimeException("Cüzdanki para yeterli değil.");
    }else{
      musteri.getKrediKarti().setLimit(musteri.getKrediKarti().getLimit()-miktar);
      hasilat +=miktar;
    }
  }

  public double getHasilat() {
    return hasilat;
  }
}

public class Musteri {
  private String adi;
  private KrediKarti krediKarti;

  public Musteri(String adi,double para) {
    this.krediKarti =new KrediKarti();
    this.adi =adi;
  }

  public KrediKarti getKrediKarti() {
    return krediKarti;
  }

  public String getAdi() {
    return adi;
  }
}

public class KrediKarti {
  private double limit =1000;

  KrediKarti() {

  }

  public double getLimit() {
    return limit;
  }

  public void setLimit(double limit) {
    this.limit = limit;
  }
}
```

Gördüğünüz gibi Main sınıfı hariç bütün sınıfları basit bir değişiklik yüzünden
değiştirmek zorunda kaldık. Burada aslında sadece Müşteri yani cüzdana sahip
sınıfın etkilenmesi gerekirdi fakat prosedürel stilde sürekli nesnelerin iç
yapısını sorgulayarak ona karar veren kodumuz yüzünden Gazeteci sınıfıda bu
değişiklikten etkilendi.

Peki bu problemi nasıl düzeltebiliriz ? Tell Don’t Ask yani işimizi nesnelere
soru sorararak değilde onlara ne yapması gerektiğini söyleyerek yapabiliriz.
Aslında bu yeni birşey değil OOP’nin en temel kuralını kullanıyor alıyor yani
Encapsulation. Nesnelerin iç yapısını çok fazla dışarı açtığımızda kendi
üzerine düşen işleri başkaları yaptığında bu tarz problemler kaçınılmaz. Bu
küçük bir örnek belki çok fazla problem olmaz fakat büyük bir uygulamada bu
tarz iç yapısını dışarı açan bir nesnede değişiklik olduğunu düşünün? Belkide
yüzlerce sınıfı değiştirmek,hatalarını düzeltmek,test etmek zorunda
kalacaksınız. Şimdi bu kodu Tell Don’t ask prensibine uygun olarak aşağıdaki
gibi yazalım.

```cs
public class Cuzdan {
  private double para;

  Cuzdan(double para) {
    this.para =para;
  }

  double cek(double fiyat) {
    if(fiyat>para)
      throw new RuntimeException("Cüzdanki para yeterli değil!");
    else{
      para =para-fiyat;
      return fiyat;
    }
  }
}

public class Musteri {
  private String adi;
  private Cuzdan cuzdan;

  public Musteri(String adi,double para) {
    this.cuzdan =new Cuzdan(para);
    this.adi =adi;
  }

  public double odemeYap(double fiyat){
    return cuzdan.ver(fiyat);
  }

  public String getAdi() {
    return adi;
  }
}

public class Gazeteci {
  private double hasilat =0;
  public void odemeAl(Musteri musteri,double miktar){
    hasilat +=musteri.odemeYap(miktar);
  }

  public double getHasilat() {
    return hasilat;
  }
}
```

Şimdi Tell Don’t Ask prensibine göre ile yazılmış yeni kodumuzu inceleyelim.
Gazeteci sınıfına bakın artık müşterinin ne cüzdnından haberi var nede kredi
kartından. Ona sadece yapması gereken şeyi söylüyor : “Bana şu kadar ödeme
yap”. Müşteri nesneside aynı şeyi yapıyor cüzdana bana şu kadar para ver diyor.
Ardından cüzdan da kendi içerisinde olan parayı istenen miktarla
karşılaştırıyor ve ona göre veri parayı veriyor. Yani herkes yapması gereken
işi yapıyor. Artık cüzdan nesnesi içerisinde sadece veri bulunan bir aptal
sınıf yada Anemic Domain Model değil, onu nasıl işleyeceğini bilen bir sınıf.

Şimdi bu yapıda yazılmış bir kod üzerinde Cuzdan yerine paramızı kredi kartı
üzerinden ödemek için değişmesi gereken sınıfları tekrar yazalım.

```cs
public class Musteri {
  private String adi;
  private KrediKarti krediKarti;

  public Musteri(String adi,double para) {
    this.krediKarti =new KrediKarti();
    this.adi =adi;
  }

  public double odemeYap(double fiyat){
    return krediKarti.cek(fiyat);
  }

  public String getAdi() {
    return adi;
  }
}

public class KrediKarti {
  private double limit =1000;

  KrediKarti() {

  }

  double cek(double fiyat) {
    if(fiyat>limit)
      throw new RuntimeException("Limit yeterli değil!");
    else{
      limit =limit-fiyat;
      return fiyat;
    }
  }
}

public class Gazeteci {
  private double hasilat =0;
  public void odemeAl(Musteri musteri,double miktar){
    hasilat +=musteri.odemeYap(miktar);
  }

  public double getHasilat() {
    return hasilat;
  }
}
```

Gazeteci sınıfında yukarıda gördüğünüz gibi hiçbir değişiklik yapmadık. Yani
sadece iç yapısını değiştirdiğimiz sınıflar etkilendi. O da müşteri sınıfı ama
diğer şekilde hem gazeteci hemde müşteri sınıfı etkileniyordu.

Tabi bunun dışında gördüğünüz gibi kodun okunulabilirliği ve yönetimi oldukça
kolaylaştı. Çünkü herkes kendi sorumluluğunu yerine getiriyor, nesneler kendi
içerisindeki veriler üzerinde işlem yapıyor. Bu şekilde uygulamada değişiklik
sadece gereken yerde yapılmış oluyor. Ama diğer şekilde iş mantığı uygulamanın
bütün yerine dağılmış olduğu için değişiklik sonucunda birsürü yerde değişiklik
yapmamız gerekiyor. Buda hata riskini ve değişim maliyetini oldukça arttırıyor.

İlk başlarda bu prensibi okuduğumda oldukça şaşırmıştım ve açıkçası nesneye
yönelik programlamanın en temel ilkesini o zaman anlamıştım. Veri ve veri
üzerinde işlem yapan metodların bir arada olması. Prosedürel mantığa o kadar
alışmışızki nesneye yönelik bir programlama dilinde onun etkisinden hala
kurtulamıyoruz. Bu prensip anlaması ve alışması belkide en zor temel nesneye
yönelik programlama prensiplerinden birisi. Ben bile hala bazı yerlerde
içgüdüsel olarak nesnelere soru sorup bazı işleri yaptırmaktan kendimi
alıkoyamıyorum. Ama sürekli kodu gözden geçirip “Acaba bu işi bu sınıf mı
yapmalı?, Bu işin ait olduğu yer burası mı?” diye sorgularsanız sorumluluğun
gerçekten ait olduğu yeri belirleyebilirsiniz. Eğer nesnelerinizde sadece
getter,setter(java) yada property(C#) bulunuyorsa nesnelerinizden
şüphelenmenizin ve tekrar gözden geçirmenizin vakti gelmiştir.

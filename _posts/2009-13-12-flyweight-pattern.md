---
layout: post
title: "Flyweight Pattern ile Performans Optimizasyonu"
description: "Flyweight Pattern ile Performans Optimizasyonu"
date: 2009-13-12T07:00:00-07:00
tags: patterns
---

Uzun süredir yeni iş, yeni projeler,yine üşengeçlik :) derken bir türlü yazmaya fırsat bulamıyordum sezonu yeniden açtığımızın haberini vermek benim için oldukça sevindirici, umarım sizin içinde öyle olur. Bundan sonra tekrar sık sık yazmaya çalışacağım.

Geçenlerde çalıştığım bir projede sürüm öncesi geliştirdiğimiz yazılımın fazla bellek kullandığını gözlemledik. Daha sonra sorunun nedenini bulmak için Profiler ile bellek kullanımına baktığımızda bazı nesnelerin bellekte çok fazla sayıda olduğunu gördük. Aslında baktığımızda normal bir durumdu çünkü gerçekten o nesnelerin oluşturulması gerekiyordu. Temel olarak bazı işlemleri yapmamız için gerekli nesneleri oluşturan bir sınıfımız vardı.Projede yaptığımız işlem gerçekten çok fazla nesne gerektiriyordu, dolayısıyla bellekte çok fazla nesne oluşturuluyordu.

Profiler sonuçlarını dikkatlice incelediğimizde bir sınıfın nesnenin diğerlerinden çok daha fazla oluşturulduğunu ve bellekte en çok yeri bu nesnenin yer kapladığını gördük. Bu nesnenin adına Key diyelim. Kodun aşağıdaki gibi olduğunu düşünün. Key sınıfı nesnelerimize kategorilerini belirtmek için atanan bir sınıf ve aldığı değerler Golden, Silver, Bronz (Altın,Gümüş, Bronz) şeklindedir. Ve ilk oluşturulduktan sonra dikkat ederseniz değerleri değiştirilemezler. Yani Immutable bir nesnedir.


```
public class Key {
  private int id;
  private String code;
  private boolean removable;

  public Key(String code, boolean removable) {
    this.code = code;
    this.removable = removable;
  }

  public String getCode() {
    return code;
  }

  public boolean isRemovable() {
    return removable;
  }

  @Override
    public String toString() {
      return "Code : " + code + ", Removable : " + removable;
    }
}
public class BusinessObject {
  private Key key;
  private String name;
  private int number;

  public BusinessObject(Key key, String name, int number) {
    this.key = key;
    this.name = name;
    this.number = number;
  }

  public Key getKey() {
    return key;
  }

  public String getName() {
    return name;
  }

  public int getNumber() {
    return number;
  }
}
public class ObjectCreator {
  public List createObjects(){
    List businessObjects=new ArrayList();
    for (int i=0;i<500000;i++){
      if(isGolden(i)){
        Key goldenKey =new Key("Golden",true);
        BusinessObject bo =new BusinessObject(goldenKey, "Name : "+i, i);
        businessObjects.add(bo);
      }else if(isSilver(i)){
        Key silverKey =new Key("Silver",true);
        BusinessObject bo =new BusinessObject(silverKey, "Name : "+i, i);
        businessObjects.add(bo);
      }else if(isBronze(i)){
        Key bronzeKey =new Key("Bronze",true);
        BusinessObject bo =new BusinessObject(bronzeKey, "Name : "+i, i);
        businessObjects.add(bo);
      }else{
        Key emptyKey =new Key("",false);
        BusinessObject bo =new BusinessObject(emptyKey, "Name : "+i, i);
        businessObjects.add(bo);
      }
    }
    return businessObjects;
  }

  private boolean isBronze(int i) {
    return (i % 7) == 0;
  }

  private boolean isGolden(int i) {
    return (i % 3) == 0;
  }

  private boolean isSilver(int i) {
    return (i % 5) == 0;
  }
}
public class Main {
  public static void main(String[] args) {
    ObjectCreator objectCreator =new ObjectCreator();
    List businessObjects =objectCreator.createObjects();
  }
}
```
Yukarıdaki kodda gördüğünüz gibi, Processor sınıfı BusinessObject nesnelerimizi oluşturuyor. Bunu yaparken belirli kriterlere göre hangi Key sınıfının oluşturulacağını belirleyip BusinessObject sınıfına atama yapıyor. Yukarıda çok fazla nesne oluşturmayı temsil etmek için 1'den 500.000'e kadar bir döngü içerisinde bu nesneleri oluşturdum.Yukarıdaki kodu Profiler çalıştırarak bellek kullanımını gözlemlediğimde aşağıdaki gibi bir sonuç çıkıyor karşıma.



![](/img/flyweight/profilerresults1.jpg)

Yukarıdaki grafikte gördüğünüz gibi 500.000 adet Key nesnesi oluşturulmuş ve bu oluşturulmuş nesneler bellekte yaklaşık olarak 1.2 mb yer kaplamaktadır. Gerçekte projede kullanılan nesne Key nesnesinden çok daha büyük olduğu için kapladığı bellek miktarı çok daha fazlaydı. Şimdi bu problemi Flyweight Pattern kullanarak nasıl çözdük, kullanılan bellek miktarını nasıl düşürdük ona geçelim.

Flyweight Pattern genellikle bellek performans optimizasyonunda kullanılan basit bir Design Pattern’dır. Gereksiz performans optimizasyonu için neler düşündüğümü daha önceden bu yazıda belirtmiştim.Bu yüzden gerçekten gerekmedikçe yapılmasını tavsiye etmem dolayısıyla bunu tasarım kalıbını kullanırken aklınızın bir köşesinde tutmaya çalışın.

Peki Flyweight Pattern nasıl bellek kullanımını optimize eder? Bunu uygulamada aynı özellikleri taşıyan nesneleri ya da nesnelerin parçalarını tekrar tekrar oluşturmak yerine onlardan birer tane oluşturup paylaşarak yapar.Genellikle paylaşılması gereken nesneleri bir defa oluşturur Cache ya da static bir Dictionary,HashMap tarzı bir nesnede saklar ve istendiğinde daha önceden oluşturulmuş nesneyi kullanıcıya verir.

Yani yukarıdaki örneği düşünecek olursak,BusinessObject nesnemiz 500.000 defa oluşturulmak zorunda çünkü herbiri farklı ve farklı şeyleri temsil ediyor fakat Key nesnemiz aslında uygulamamızda 4 adet değer ile oluşturuluyor. Bunlar Golden,Silver,Bronze ve boş olanı temsil eden Empty değerleri. Fakat biz bu nesneyi yukarıdaki kodda ve grafikte gördüğünüz gibi 500.000 defa oluşturuyoruz. Dolayısıyla bellekte 500.000 adet kadar yer kaplıyor. Flyweight Pattern kullanarak tekrar tekrar aynı değerleri içeren Key nesnelerimizden sadece gerektiği kadar oluşturacağız yani 4 adet. Bunu da aşağıdaki şekilde yapabiliriz.

Öncelikle yukarıdaki koda biraz Refactoring yapalım. İlk olarak  Processor sınıfı içerisinde nesneleri oluşturan kodu bu asıl amacı bu işi yapmak olan bir Factory sınıfına taşıyalım. Yani KeyFactory adında bir sınıfa Key nesneleri oluşturulması sorumluluğunu yükleyelim.

```
public class KeyFactory {
  private static Map keyMap = new HashMap();

  public static Key create(int i) {
    if (isGolden(i)) {
      if (keyMap.containsKey("Golden")) {
        return keyMap.get("Golden");
      } else {
        Key goldenKey = new Key("Golden", true);
        keyMap.put("Golden", goldenKey);
        return goldenKey;
      }

    } else if (isSilver(i)) {
      if (keyMap.containsKey("Silver")) {
        return keyMap.get("Silver");
      } else {
        Key silverKey = new Key("Silver", true);
        keyMap.put("Silver", silverKey);
        return silverKey;
      }
    } else if (isBronze(i)) {
      if (keyMap.containsKey("Bronze")) {
        return keyMap.get("Bronze");
      } else {
        Key bronzeKey = new Key("Bronze", true);
        keyMap.put("Bronze", bronzeKey);
        return bronzeKey;
      }
    } else {
      if (keyMap.containsKey("Empty")) {
        return keyMap.get("Empty");
      } else {
        Key emptyKey = new Key("", true);
        keyMap.put("Empty", emptyKey);
        return emptyKey;
      }
    }
  }

  private static boolean isBronze(int i) {
    return (i % 7) == 0;
  }

  private static boolean isGolden(int i) {
    return (i % 3) == 0;
  }

  private static boolean isSilver(int i) {
    return (i % 5) == 0;
  }
}
public class ObjectCreator {
  public List createObjects(){
    List businessObjects=new ArrayList();
    for (int i=0;i<500000;i++){
      BusinessObject bo =new BusinessObject(KeyFactory.create(i), "Name : "+i, i);
      businessObjects.add(bo);
    }
    return businessObjects;
  }
}
```
KeyFactory sınıfına bakacak olursanız. Nesneyi oluşturmadan önce bunun bahsettiğimiz gibi HashMap içerisinde olup olmadığını kontrol ediyoruz eğer var ise yeni bir tane oluşturmadan varolanı veriyoruz, eğer yok ise yeni bir tane oluşturup HashMap içerisine daha sonraki istekler için saklıyoruz.Dolayısıyla uygulamamız boyunca sadece 4 tane nesne oluşturmuş oluyoruz.Yukarıdaki gibi kodumuzu değiştirdikten sonra Profiler sonuçlarına tekrar bakalım.

![](/img/flyweight/profilerresults2.jpg)

Gördüğünüz gibi bellekte sadece 4 adet Key nesnesi bulunuyor ve bellekte sadece 24 byte yer kaplıyor. Yaptığımız değişiklik ile oldukça iyi bellek kullanımı optimizasyonu yapmış olduk. Flyweight Pattern genellikle Factory ya da daha önceden bahsettiğim Creation Method tarzı tasarım kalıpları ile birlikte kullanılır. Aklınızın köşesinde bulunmasında fayda var gerektiğinde oldukça faydalı olabiliyor…..

---
layout: post
title: "Interface nedir,ne zaman kullanılır?"
description: "Interface nedir,ne zaman kullanılır?"
date: 2008-06-10T07:00:00-07:00
tags: oop
---

Interface içinde sadece kendisinden türeyen sınıfların içini doldurmak zorunda
olduğu içi boş metod tanımlarının yapıldığı bir yapıdır. Kısacası kendisini
kullanacak sınıflar için bir yerine getirmeleri gereken metodları belirten bir
kontrat gibidir. Java ve C# dillerinde aşağıdaki gibi kullanılır.

```
interface Rapor{
    public void hazirla(Fatura fatura);
}
```

Bu interface kendinden türeyen tüm sınıfların public void hazirla(Fatura
fatura) adında bir metoda sahip olmalarını zorunlu kılar aksi taktirde
derleyici hata verecektir. Aşağıdaki gibi bir sınıfın bu interface’i nasıl
uyguladığını gösteren koda bakalım.


```
class PdfRapor implements Rapor{
    public void hazirla(Fatura fatura) {
        //Faturayı pdf formatında hazırlayan kodlar
    }
}
```

Gördüğünüz gibi interface’den türeyen sınıflar bu şekilde interface’in
belirttiği kurallara uyup içindeki metodları kendileri yazmak
zorundadır.Kısacası interface’ler sınıfların yapabildiği şeyleri belirten
kontratlardır diyebiliriz. Aklımıza gelmişken interface’lerin diğer
özelliklerini de yazalım.

Interface’ler de Abstract sınıflar gibi new ile oluşturulamazlar İçi dolu metod
bulunduramazlar public static final değişkenler dışında herhangi bir değişken
bulunduramazlar Bir sınıf birden fazla interface’den türeyebilir Şimdi asıl
önemli soruya geldik. Az önceki durumda neden interface kullandık?Aslında bunun
sebebi tamamen bizden geliştirmemiz istenen yazılımın özelliklerine bağlı.
"Yukarıdaki gibi bir kod yazmamızın ne gereği var?, Direk PdfRapor sınıfını
interface’den türetmeden yazamazmıydık?" gibi sorular aklınıza gelmiş olabilir.
Evet yazabilirdik tabi, fakat yazmamamızın sebebini şöyle açıklayalım.Öncelikle
daha önceden müşteri ile konuştuğumuzda bizden şöyle bir talepte bulunmuştu:
"Geliştireceğiniz yazılımda ben faturalarımı Pdf,Word,Excel formatlarında
hazırlayabilmek istiyorum. Ayrıca ileride belki yeni formatlarda da sizden
fatura isteyebilirim" diye daha önceden bizle konuşmuştu.Durum böyle olduğu
için daha önceden Dependency Inversion makalesinde yazdığım gibi kodumuzun
değişikliklerden etkilenmemesi, içinde bolca if-else yapılarının olmaması ve
daha esnek olması için değişen kısmı bir interface kullanarak kodumuzdan
soyutladık.Kodun içinde sadece aşağıdaki gibi interface kullanıldığı için
ileride eklenecek yeni rapor formatlarından da etkilenmeyecektir.

```
class FaturaRaporFormu {
        private List calisanlar;
        private Fatura seciliFatura;
        private Rapor rapor;

        public FaturaRaporFormu(Rapor rapor){
               this.rapor = rapor;
       }

        public void FaturayaAitRapor(){
                this.rapor.hazirla(seciliFatura);
        }
}
```

Ayrıca interface ya da abstract sınıfların en büyük güzelliklerinden biride
Polymorphism diyebiliriz. Interface ya da Abstract sınıfları kodun herhangi bir
yerinde bir metoda parametre ya da metodun dönüş değeri,bir değişken, bir dizi
tanımlamasında… gibi yerlerde kullanabiliriz. Ve bu kullanılan yerlerde
Abstract ya da Interface’den türeyen herhangi bir sınıfı bu metoda,değişkene
parametre olarak gönderdiğimizde ya da değişkene atadığımızda kod aynen
çalışmaya devam edecek Java,C# dilleri Interface ya da Abstract sınıftan
türeyen bütün alt sınıflara aynı şekilde tavranacaktır.

Gördüğünüz gibi interface kullanmak kodun esnekleğini arttırıyor. Fakat
geliştirdiğimiz yazılımda ileride değişmeyecek bir kavramı sırf esneklik olsun
diye interface kullanarak soyutlamakda kodu daha anlaşılması zor ve karmaşık
hale getirecektir.Unutmayın yazılımın ve kodun basit ve sadece müşterinin
ihtiyaçlarını karşılayanı makbuldür.Basitlik yazılım geliştirirken daima
aklımızın bir köşesinde bulunmalı. Bu yüzden eğer müşteri bizden tek tip rapor
isteseydi bu sefer interface kullanmamıza gerek kalmazdı.

Kısaca özetlersek Interface geliştirdiğimiz yazılımda aynı kavramın birden
farklı şekilde uygulandığında bu kavramı soyutlayarak kodun
esnekliğini,okunulabilirliğini arttırmak ve değişimin etkisini en aza indirmek
için kullanılan yapılardır.Genelde Interface’den türeyen sınıflar arasında
CAN-DO(yapabilir) ilişkisi vardır.Yukarıda neden kullanmamız gerektiğini umarım
anlatabilmişimdir.

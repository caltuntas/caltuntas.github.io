---
layout: post
title: "Refactoring : Replace Magic Number with Symbolic Constant"
description: "Refactoring : Replace Magic Number with Symbolic Constant"
date: 2008-08-06T07:00:00-07:00
tags: javascript
---


```
public class Siparis
{
    private int siparisDurumu=0;
 
    public void SiparisEt()
    {
        if (siparisDurumu == 1)
        {
            //sipariş işlemlerini başlat
        }
    }
}
``` 
Pek kullanmaya gerek duymam dediğim Refactoring yöntemlerinden [Replace Magic Literal](https://refactoring.com/catalog/replaceMagicLiteral.html) tekniğini kullanmak zorunda kaldımya pes diyorum yani. Şimdi biri bana gelsin yukarıdaki kodun ne yaptığını anlatsın. Bunu anlamak için veritabanına girip sipariş durumu tablosunu bulup ardından 1 sayısının karşılığı olan anlamı bulmak zorunda kalıyorum. Tabi birsürü zaman kaybı israf. Ayrıca her defasında kodu okuduğumda acaba 1 neydi 2 neydi diye hafızamı zorlamak zorundayım hafızamda pek kuvvetli olmadığı için sürekli hatada yapabiliyorum. Tabi size gösterdiğim kod örneği çok basitleştirilmiş hali birde bunun onlarca sayıdan oluştuğunu düşünün tam anlamıyla işler arap saçına dönmeye başlıyor.

Bu tarz sihirli numaraları(Magic Numbers) lütfen kodun içine gömmeyelim.Hem okuması zor, hemde sabit değişken değiştiğinde başımıza birsürü dert açıyor.Yukarıdaki durumu düşünün sipariş kabulu 1 değilde artık 111 ile temsil etmek istiyoruz ne yapacağız?Gidip tek tek 1 geçen yerleri 111 e çevirmek zorunda kalıyoruz işin yoksa uğraş. Çok zor değil o sihirli numara yerine sabit bir değişken kullanacağız. 21. yüzyılda yaşıyoruz programlama dillerimiz oldukça gelişmiş,bize bu tarz olanakları kolaylıkla sunuyorlar.Kodumuzu aşağıdaki gibi değiştirelim.

```
public class Siparis
{
    private int siparisDurumu = 0;
 
    private const int KABUL_EDILMEDI = 0;
    private const int KABUL_EDILDI = 1;
 
    public void SiparisEt()
    {
        if (siparisDurumu == KABUL_EDILDI)
        {
            //sipariş işlemlerini başlat
        }
    }
}
``` 

Gördüğünüz gibi alt tarafı bir sembolit sabit yazarak kodun okunulabilirliğini,anlaşılabilirliğini ne kadar arttırdık. Ayrıca kod üzerinde daha sonradan çalışacak olan benim gibi developer arkadaşlarımızın arkamızdan bizim kulaklarımızı çınlatmasını da önlemiş olduk.

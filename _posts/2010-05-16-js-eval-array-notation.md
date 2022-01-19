---
layout: post
title: "JavaScript'in Balyozu Eval ve Array Notasyonu"
description: "JavaScript'in Balyozu Eval ve Array Notasyonu"
date: 2010-05-16T07:00:00-07:00
tags: javascript
---

![](/img/evalevil/balyoz_thumb.jpg)
<img align="left" width="343" height="257" src="/img/evalevil/balyoz_thumb.jpg">
Javascript programlama dili içerisinde eval fonksiyonu genellikle dinamik kod çalıştırmak için kullanılıyor. Örnek olarak server tarafından dönen bir JSON formatındaki nesneyi eval fonksiyonu ile Javascript nesnesine kolaylıkla dönüştürebiliriz.

Bunun dışında Javascript kodlarına baktığımda içerisinde eval gördüğüm yerlerin çoğunda kullanım yanlışlığı var ve bunun sebebi Javascript dilini iyi bilmemekten kaynaklanıyor. Eval’in yanlış kullanımına dair sıkça gördüğüm durumlardan bir tanesi şöyle oluyor.Örneğin bir nesnenin bir özelliğinde formu kayıt ederken çalıştırılacak fonksiyon ismi tutuluyor.


```
var form ={
    name :'Save',
    url : '/Form/Save',
    validation_function :'validateForm':
}
function save(form,element){
    eval(form.validate_function+'(element)');
    //....diger islemler
}
``` 

Yukarıdaki kodda formu kayıt ederken nesnenin özelliği olan hangi validasyon fonksiyonuna gireciğini kullanıp bu fonksiyonu çalıştırmak.Bu fonksiyon her nesne için farkı olabileceği için burada sabit bir fonksiyon çağıramıyoruz. Yani yapmak istediğimiz aslında dinamik olarak belirlenen bir fonksiyonu çalıştırmak bunu da yukarıdaki gibi eval kullanarak kodu çalıştırdığımızda Script Engine dinamik kodu tekrar derleyip belleğe yükledikten sonra çalıştırmaktadır. Bu da performans bakımından oldukça masraflı bir işlemdir.Kısacası balyoz ile sinek öldürmek diyebiliriz yani:) Bu yüzden gerçekten gerekmedikçe eval funksiyonundan kaçınmak Javascript performansı için oldukça faydalı olacaktır.

Peki yukarıdaki kodu eval kullanmadan nasıl yazabilirdik? Çok basit Javascript dilinde aşağıdaki iki ifade aynı şeyi yapar.

```
nesne.method();
nesne['method']();
```

Javascript içerisindeki fonksiyonlara yada nesnenin özelliklerine “.(dot)” notasyonu dışında “[](array)” notasyonu ile de ulaşabilirsiniz. Bunun dışında bilmemiz gereken birşey daha var; tanımlanan bütün fonksiyonlar global window nesnesine aitdir.Yani aşağıdaki 3 satır kod da aynı şeyi yapar


```
function taklaAt(){
    //takla at...
}
 
//aynı seyi yapan satirlar
taklaAt();
window.taklaAt();
window[taklaAt]();
```

Bu bilgileri de öğrendikten sonra ilk kodumuzu aşağıdaki gibi yazabiliriz.

```
var form ={
    name :'Save',
    url : '/Form/Save',
    validation_function :'validateForm':
}
function save(form,element){
    window[validation_function](element);
    //....diger islemler
}
```

Yukarıda ne yaptık? Window nesnesine ait olan dinamik fonksiyonumuzu array yani [] ile çağırdık.Javascript gibi performansın gerçekten önemli olduğu bir dilde yukarıdaki yaptığımız işlem oldukça iyi performans kazancı sağlayacaktır. Ayrıca debug ederken eval ile çağırılan fonksiyonların debug edilmesi normallerine göre daha zor olduğu için eval kullandığınız heryeri gözden geçirmenizde fayda olabilir.

Boşuna [Eval is Evil](https://docs.microsoft.com/en-us/archive/blogs/ericlippert/eval-is-evil-part-one) dememişler :)

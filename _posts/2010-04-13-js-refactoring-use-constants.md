---
layout: post
title: "Javascript Refactoring:Use Constants"
description: "Javascript Refactoring:Use Constants"
date: 2010-04-13T07:00:00-07:00
tags: javascript
---

Javascript kodlarına bakarsanız etrafta bolca string göreceğinizden eminim. En azından benim eski Javascript kodlarım böyleydi.[Daha önceden](https://www.cihataltuntas.com/2008/08/06/replace-magic-number.html) Java, C# gibi static typed dillerde bunların önüne nasıl geçebileceğimizden bahsetmiştik. Javascript dilinde Constant kavramı olmasa da Object Literal notasyonu kullanarak sabit değişkenler tanımlayabiliriz. Aşağıdaki masum Javascript fonksiyonlarını görüyorsunuz.


```
function createStatusImage(movie) {
    var img = document.createElement("img");
    if (movie.avaliable)
        img.src = '/Content/Images/watched.gif';
    else
        img.src = '/Content/Images/unwatched.gif';
 
    return img;
};
 
function makePlanned(img) {
    img.src = img.src = '/Content/Images/planned.gif';
}
``` 

Yukarıdaki kodlar ne kadar masum görünse de, her tarafta string tanımı olduğu için kodda eğer resim yani “Content/Images” dizinini değiştirmek istediğinizde kodun 3 yerinde bu değişikliği yapmak zorundasınız. Bunun yerine Object Litaral ile bir konfigürasyon nesnesi oluşturup kodumuzu aşağıdaki gibi refactor edersek daha okunaklı ve değiştirmesi daha kolay olacaktır.

``` 
var ImageConfig = {
    IMAGE_PATH: '/Content/Images/',
    WATCHED_IMAGE: 'watched.gif',
    UNWATCHED_IMAGE: 'unwatched.gif',
    PLANNED_IMAGE: 'planned.gif'
}
 
function createStatusImage(movie) {
    var img = document.createElement("img");
    if (movie.avaliable)
        img.src = ImageConfig.IMAGE_PATH + ImageConfig.WATCHED_IMAGE;
    else
        img.src = ImageConfig.IMAGE_PATH + ImageConfig.UNWATCHED_IMAGE;
 
    return img;
};
 
function makePlanned(img) {
    img.src = img.src = ImageConfig.IMAGE_PATH + ImageConfig.PLANNED_IMAGE;
}
``` 

Yukarıdaki tanımlama gerçek anlamda oluşturulduktan sonra değiştirilemiyen “constant” ya da “final” değişkenler sunmasa da fantazi olsun diye birisi ImageConfig nesnesi içeriğini değiştirmez ise bu amaçla kullanılabilir.Bu yüzden eğer takım olarak ortak Javascript dosyaları üzerinde değişiklik yapıyorsanız [Coding Conversions](https://en.wikipedia.org/wiki/Coding_conventions) belirlemeniz faydanıza olacaktır. Sizi bilmiyorum ama ben son halini daha çok sevdim :)

---
layout: post
title: "Vifm ile Çoklu Dosya İsmi Değiştirme"
description: "Vifm ile Çoklu Dosya İsmi Değiştirme"
date: 2023-05-24T07:00:00-07:00
tags: vifm
---

Terminal uygulamalarını çok severim, tabi bu sevgi çoğunlukla terminal
uygulaması olduklarından dolayı değil, bana fayda sağladıklarından dolayı. Hele
bu tarz uygulamalar hızlı çalışıyor ve diğer araçlarla saatlerce yaptığım işi
saniyelere indiriyorsa bayılırım.  

Terminal bazlı dosya yöneticilerinden bir süredir
[nnn](https://github.com/jarun/nnn) kullanıyordum. Oldukça hızlı olmasına
rağmen klavye kısa yollarını hatırlamakta zorlandığımı fark ettim. Farklı bir
araç araştırırken [vifm](https://github.com/vifm/vifm) ile karşılaştım. Adından
da anlaşılacağı gibi `Vim` mantığı ile geliştirilmiş bir dosya yöneticisi.Bende
uzun süredir __Vim__ kullanıcısı olduğu için genel kullanım mantığını anlamak
zaten kısa sürdü.

Ama gerçekten sevmeye geçenlerde hünerlerini görmeye başladığımda başladım
diyebilirim.  Evdeki NAS sunucusunda arşiv dosyalarında düzenleme belirli bir
isim standardı uygulamak istedim. Bütün dosyalar öncelikle küçük harf olsun,
sonra örnek boşluk karakteri yerine `-` olsun gibi. Bunun için bir `bash`
script yazılabilir tabi ama pratiklik açısından `Vifm` yöntemi çok hoşuma
gitti. 

![video](https://user-images.githubusercontent.com/35517929/240868537-1a3e4d32-a54f-44ad-a081-7ccb87b9ebee.gif)

Videoda görüldüğü gibi öncelikle ismini değiştirmek istediğimiz tüm dosyaları
aynı `Vim`'deki gibi `CTRL+V G` ile seçiyoruz. Ardından yine `Vim` benzeri `cw`
ile değiştirme işlemini başlatıyoruz. Sonrasında bize standart `Vim` penceresi
getiriyor. Gelen ekranda `ggguG` çalıştırınca tüm dosya isimleri küçük harfe
geçiyor ve son olarak `:wq` ile kaydedip çıkıyoruz ve tüm dosya isimleri
değişmiş oluyor.

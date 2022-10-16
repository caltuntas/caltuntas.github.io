---
layout: post
title: "Neden Vim? Bölüm 1 - Performans"
description: "Neden Vim kullanıyorum. Bölüm 1 performans karşılaştırması"
date: 2022-10-16T07:00:00-07:00
tags: vim
---

Geçenlerde sosyal medya üzerinde VsCode ile ilgili bir konuda şaka maksatlı Vim reklamı bırakmıştım.
Gelen birkaç tepkiden bunun bazı arkadaşları kızdırdığını fark ettim ve böyle bir yazı serisi hazırlama
kararı aldım. Burada yazacaklarım tamamen kendi kişisel görüşlerim ve tecrübem olup bana katılmamakta 
tamamen özgür olduğunuzu belirtmek isterim.

### Biraz Geçmiş
 
Vim ile tanışıklığım 2010 yılına dayanıyor, neredeyse yazılım mühendisi olarak başladığım 
profesyonel iş hayatına başlayışımdan 5 sene sonra. Yıllar önce bu tanışıklık ile ilgili eski blogumda
bir yazı yazmıştım. Tabi Vim ile tanıştıktan sonra, diğer bütün kullandığım IDE, Editor gibi araçlar ile aniden ilişkiyi
kesmedim. 2010 yılından sonra da o veya bu şekilde Vim ile birlikte farklı birçok Editor ve IDE kullandım.

Bugüne kadar kullandığım IDE ya da Editor araçları aşağıdaki gibidir

- Turbo C /Pascal
- Delphi
- Dreamweaver
- IntelliJ
- Eclipse
- Netbeans
- Notepad++
- Visual Studio
- VsCode

Başlamadan şunu belirteyim, araçları amaçlarla karıştırmaya karşı olan biriyim. Vim de benim için bir araç,
Eclipse, IntelliJ, VsCode, Visual Studio gibi ortamları yıllarca kullanan biri olarak birçok farklı açıdan 
çok iyi olanaklar sunduklarını biliyorum. Yazılım sebebi benim kullandığım Editor seninkini döver değil
sadece kendimce kullanma sebeplerim ve bana göre diğer ortamlara göre sunduğu artılar diyebilirim.

### Sene 2022 Sen Hala Vim?

Şuanda bu yazıyı Vim kullanarak yazıyorum, aktif olarak geliştirme yaptığım projelerde IDE/Editor olarak sadece Vim kullanıyorum ve bunları
yaparken de oldukça üretken ve verimli bir şekilde yaptığıma inanıyorum. Yani Vim kullanmamın sebebi elit bir geliştirici gibi hissettirmesi,
beni daha iyi bir mühendis ya da insan yaptığına inanmam kesinlikle değil. Kesinlikle kendi açımdan fayda odaklı ve pragmatik olarak bakıyorum.
Ama şunu ifade edebilirim ki, 2022 yılında Vim kullanmak bir nostalji değil çünkü Vim hiç olmadığı kadar daha güçlü. Bunda VsCode'un da katkısı 
çok büyük. 

Microsoft ve VsCode sayesinde gelişen [LSP(Language Server)](https://en.wikipedia.org/wiki/Language_Server_Protocol) ve [DAP(Debug Adapter)](https://microsoft.github.io/debug-adapter-protocol/) protokolleri
sayesinde artık geliştiriciler tarafından çok sevilen ama uzun yıllar eksikliğini hissettirdiği autocomplete, debugging gibi özelliklere
sahip oldu. Dolayısıyla artık debug yapmak için başka bir IDE ya da Debugger(jdb,gdp,delve...) kullanmadan direk Vim içinden bu işlemleri 
yapabiliyorsunuz, auto-complete vb. gibi sayısız özelliğe sahip olabiliyorsunuz. 

Lafı fazla uzatmadan kendi kişisel kullanım sebeplerimi ayrı başlıklar altında listeleyeceğim ve önce kendi adıma en önemli önceliklerden 
biriyle başlamak istiyorum. 

### Performans Karşılaştırması

Sizi bilmem ama benim en sevmediğim şeylerden birisi, geliştirme sırasında tam odaklanmışken, üretken durumda iken, IDE/Editor gibi
araçların yavaşlanması, kitlenmesi, cevap veremez olması. Ve bunu Eclipse, Visual Studio, VsCode ile çok fazla yaşadım. Aynı anda
birden fazla proje açamadığım günleri aklıma geldi şimdi,  gözümden bir damla yaş süzüldü diyebilirim.

Performans açısından kendi bilgisayarımda gerçek hayatta üzerinde çalıştığım projeyi hem VsCode hem de Vim ile açıp çalışır hale getirdikten sonra
kullandıkları Memory ve CPU gibi değerleri ölçtüm.

#### Test Ortamım

- MacBook Pro 2017
- Intel(R) Core(TM) i5-6287U CPU @ 3.10GHz
- 16 GB Memory
- 256GB SSD
- MacOS	12.6
- Zsh
- VsCode 1.72
- Vim 9.0



#### Ölçüm Araçları

Değerlendirmeyi yapmak için aşağıda yazdığım scripti kullandım. Script anlık olarak 
bellek ve işlemci oranını yazıyor. Anlık değerler değişse de çok fazla sapma meydana gelmiyor.
Genel olarak 4-5 defa yazıya koyduğum ölçümler benim bilgisayarımda ortalamayı yansıtıyor.

Ayrıca benzer ölçüm aşağı yukarı aynı şekilde, top, htop, Activity Monitor ya da daha gelişmiş araçlarla da yapılabilir.
Genellikle terminalde çalışan, ek kurulum gerektirmeyen, scriptable ve basit yaklaşımları sevdiğim için bunu
özellikle bu yöntemle yaptım diyebilirim. 


```bash
ps x -o rss,%cpu,command | \
grep "vim" | \
grep -v "grep\|tmux" |  \
awk '
    BEGIN {printf("%s   %s     %s\n" ,"Memory","Cpu", "Command" )} 
     { 
       mem=int($1/1024); 
       cpu=$2
       total+=mem; 
       $1="";
       $2="";
       printf("%3s MB  %4s   %.100s\n", mem,cpu,$0); 
     } 
     END { print"total:" total "MB" }
    '
```

Hem VsCode hem de Vim kullanarak Editor dışında birçok eklenti ile birçok ek özellik katabiliyorsunuz.
Yani özetle eklentiler bu iki aracın da bel kemiğini oluşturuyor diyebilirim. Birinci adımda
fikir vermesi açısından iki Editör'üde eklenti olmadan başlatıp ne kadar bellek tükettiklerini karşılaştıralım.


#### Eklentisiz - VsCode

Aşağıdaki komut ile eklentileri dışarıda bırakarak kendi bilgisayarımda olan NodeJS backend projesini 
açıyorum.

```
code api -n --disable-extensions
```

Bu aşamada projeyi çalıştırmadığım, sadece açıp bıraktığım için Memory kullanımını aldım ve değerler aşağıdaki gibi çıktı.

![VsCode Without Extentions](/img/vim1/vscode-single-clean.png)

VsCode bildiğiniz gibi Electron ve NodeJs tabanlı bir Editor ve yukarı bundan dolayı birden fazla
process kullandığını görebiliyorsunuz. Bunların toplamı 815MB bellekte yer kaplamış. 

#### Eklentisiz - Vim

Yine ilk adıma benzer şekilde aşağıdaki komut ile eklentileri dışarıda bırakarak kendi bilgisayarımda olan NodeJS backend projesini 
açıyorum.

```
vim --clean api/*
```

![Vim Without Extentions](/img/vim1/vim-single-clean.png)

Vim ise sadece 10MB kullanmış. 

#### Eklentiler - VsCode

Bu aşamada çalıştığım projelerden Frontend(Angular) ve Backend(NodeJS) projelerini eklentilerle birlikte açıyorum, 5-10 dosya açıyorum ve iki
projeyi de VsCode terminal içinden çalıştırıyorum. Yani debug yapmıyorum sadece ayağa kaldırıyorum. Ayrıca ilk aşamada dahil etmediğim CPU kullanım değerlerini
de ekran görüntüsüne ekliyorum.

Not: VsCode içinde sadece NodeJs ve Angular projeleri için önerdiği eklentiler yüklü


![VsCode With Extentions](/img/vim1/vscode-two-running-cpu.png)

VsCode yaklaşık olarak 1.9GB bellek ve ortalama %20-30 arasında değişen CPU kullanmış.

#### Eklentiler - Vim

Aynı iki projeyi, aynı şekilde 5-10 dosya ile Vim aracılığıyla açıyorum. Sonra benzer şekilde Vim'in kendi terminali üzerinden çalışır hale getiriyorum.
Burada Vim için kullandığım eklenti [Coc](https://github.com/neoclide/coc.nvim) normalde diğer eklentilere göre oldukça hantal sayılabilir ve NodeJs tabanlı.
Eğer NeoVim kullanırsanız LSP içine dahil edildiği için LSP ek bir eklentiye de ihtiyaç durmuyorsunuz.

![Vim With Extentions](/img/vim1/vim-two-running-cpu1.png)

Vim yaklaşık olarak 129MB bellek ve ortalama %0-1 arasında değişen CPU kullanmış.

#### Büyük Dosyalar - VsCode

Mutlaka büyük boyutlu kod ya da log dosyası açma ihtiyacınız olmuştur. Kullandığınız Editor'un bu tarz dosyaları açabilmesi, içinde arama yapmanız, incelemeniz gerekebilir. 
Bunu test etmek için 500 MB civarında boyutu olan gerçek hayatta incelemek zorunda kaldığım büyük boyutlu log dosyalarından birini VsCode ile eklentileri kapatarak açtım. Kullandığı bellek miktarı aşağıdaki gibi 

![VsCode With Large Files](/img/vim1/vscode-large-file.png)

VsCode dosya boyutu kadar ek bellek kullanır diye tahmin ediyordum. Normalde eklentisiz yukarıda 800-900MB ile açıldığı için aynı şekilde üstüne dosya boyutu eklenerek 1600MB-1700MB arasında bir bellek tüketti

#### Büyük Dosyalar - Vim

Aynı dosyayı Vim ile açtım

![Vim With Large Files](/img/vim1/vim-large-file.png)

Vim neredeyse sadece dosya boyutu kadar bellek tüketti. Tabi bu da normalde 10MB kullanan Vim için beklediğim bir şeydi.

#### Başlama Süreleri - VsCode

Hızlıca proje açıp kapamanın gerektiğinde az kullanılan bir projenin hızlıca açılıp incelenmesinin önemli olduğunu düşünüyorum. En azından benim sık
yaptığım aktivitelerden. Bunu test etmek için VsCode'u aşağıdaki parametre ile açtığınızda başlaması için ne kadar süreyi mili-saniye olarak harcadığını görebiliyorsunuz.

```
code web --prof-startup
```

Çıkan sonuç aşağıdaki gibi, benim hissettiğim de ortalama 4-5 saniye civarındaydı benzer sonuçlar VsCode'da üretti

![VsCode Startup](/img/vim1/vscode-startup.png)

#### Başlama Süreleri - Vim

Benzer şekilde Vim ile başlama süresini ölçmek için nerede hangi vakti harcadığını görmek istiyorsanız aşağıdaki gibi çalıştırıp başlatabilirsiniz.

```
vim --startuptime
```

![Vim Startup](/img/vim1/vim-startup.png)

Vim için çıkan değerler dokümanda belirtildiği gibi mikro-saniye, çıkan profile dosyası uzun olduğu için hepsini koyamadım ama başlangıç süresi
yarım saniyenin bile altında ve hissedilen de aynı şekilde çok hızlı başladığı.

Yukarıdaki kriterler dışında performans olarak önemli gördüğüm, tepkime sürelerini ölçmek ile uğraşmadım ama kodun içinde gezinirken fonksiyonlar, bölümler, dosyalar arasında
gezinirken verdiği tepki de kullanıcı tecrübesi olarak önemli diye düşünüyorum. Bu konuda da tahmin edebileceğiniz gibi Vim daha hızlı olacaktır.

### Sonuç

Sonuç olarak tahmin çoğu kişinin tahmin edebileceği gibi Vim ile VsCode arasında performans olarak dağlar kadar fark var diyebiliriz.
Peki performans bu kadar önemli mi? Benim için önemli ve diğer bazı geliştirici arkadaşlar için de önemli olabileceğini düşünüyorum.

Kendi açımdan normalde dağıtık bir mimaride geliştirdiğimiz uygulamada farklı
dillerde geliştirilen 5-6 tane ana alt proje var ve bu projeleri aynı anda
açmak zorunda kalıyoruz. Örneğin benim bilgisayarımda 4 tanesi(2 NodeJs
JavaScript ES6, 1 Angular TypeScript, 1 Golang) sürekli açık.  Bunları VsCode
ile açmayı deneyip aynı anda çalıştırdığım zaman Macbook üzerinde yumurta
pişirebiliyorum :) Fakat Vim ile herhangi bir performans darboğazı olmadan çok
az bellek tüketerek bunu yapabiliyorum.  Aynı şekilde yukarıda bahsettiğim,
büyük log dosyalarını incelemek, projeleri hızlı açıp kapatabilmek benim için
önemli maddeler ama herkes için olmayabilir. 

Bir sonraki yazıda benim için diğer önemli olan maddelerden bahsetmeye çalışacağım. Şimdilik bu kadar.

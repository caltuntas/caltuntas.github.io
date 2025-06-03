---
layout: post
title: "I Hate Regular Expressions - 2"
description: "I Hate Regular Expressions - 2"
date: 2025-05-17T07:00:00-07:00
tags: regex
---
 
![Capture 1](/img/hateregex/hateregex.png)

Bu yazı serisi şu ana kadar 2 bölümden oluşmaktadır, diğer bölümlere aşağıdaki linklerden ulaşılabilir. Yazı içeriğinde geçen kodlara
[bu linkten](https://gist.github.com/caltuntas/c09ddd9e4297a0235924f65e6f72a4f6) ulaşabilirsiniz.

1. [I Hate Regular Expressions - 1](https://www.cihataltuntas.com/2025/04/14/i-hate-regex-1) 
   - Bu yazıda, string içeriği değiştirmede dikkatli olmadan kullanılan Regular
     Expression yönteminin ne tarz sorunlara yol açabileceğini ve alternatif
     Olarak neler yapabileceğimizi inceliyoruz.
2. [I Hate Regular Expressions - 2](https://www.cihataltuntas.com/2025/05/17/i-hate-regex-2) (Bu yazı)
   - Bu yazıda, Regular Expression kullanırken başıma gelen ve dikkatli olunmaz ise 
     çok fazla kişinin başına gelebilecek geliştirdiğiniz sistemin cevap veremeyebilecek duruma
     gelmesine sebep olabilecek performans sorunlarına değiniyoruz.

Geçen yazıda basit string arama ve değiştirme işlemlerinde RegEx kullanırken ne tarz sorunlar olabileceğinden örneklerle bahsedip
sonrasında daha kritik ve çok daha fazla karşılaşılabilecek sorunlardan biri olan performans problemlerini konuşacağız demiştik, hadi başlayalım.

### Kazık 2

Benim bile yıllar boyunca RegEx kullanıp sonrasında kafayı taşa vurup farkında olduğum dikkat edilmesi gereken konulardan biri de, Regular Expression kullanırken 
performans konusunda oldukça dikkatli olunması gerektiği. Konuyu uzatmadan direk canlı ortamda yaşadığım bir problemi burada oluşturup sonrasında arkasında yatan sebeplere değinelim.

Yediğimiz kazıklarda ikinci bölümdeyiz, aşağıdaki gibi bir konfigürasyon dosyamız var, formatı muhtemelen fark edeceksiniz JSON formatına benzerse de aslında değil.

```
parent {
    type {
        subtype TestSubType {
            element TestElement {
                attributes {
                    name testname;
                    description testdescription;
                    count 1234;
                    value testvalue;
                }
                owner person1;
            }
        }
        subtype TestSubType2 {
            element TestElement2 {
                attributes {
                    name testname2;
                    description testdescription2;
                    count 2;
                    value 2
                }
                owner unknown;
            }
        }
    }
}
```

Bu konfigürasyon dosyasında ya da çıktısında aradığımız belirli bir `pattern` var. Aradığınız şey de `parent` altında `type` altında `attribute` altında `value` değeri `testvalue` olan ve owner alanı `person1` değerine sahip olan bir değer olsun. 
Eğer bu değer varsa aradığınızı bulmuş olacaksınız kodunuz ona göre davranacak yok ise farklı bir senaryo işleteceksiniz. Yani aradığımız `pattern`  biraz şuna benzeyecek diyebiliriz, `parent->type->subtype->element->attributes->value==testvalue->owner==person` 

Hemen aklımıza süper bir fikir geldi, ve bu işi en basitçe `Regular Expressin` kullanarak çözebiliriz dedik, ne de olsa elimizde bir JSON dosyası yok, bu kadar basit bir iş için de yeni bir `parser` yazacak değiliz. 
Aşağıdaki gibi bir kod yazdık, Javascript kullandık, farklı diller de kullanabilirdik konu genel olarak dilden bağımsız ona çok takılmayalım şimdilik.

```
const fs = require('fs');

const args = process.argv.slice(2);
if (args.length < 1) {
    console.log('missing arguments');
    process.exit(1);
}
const configFile = args[0];
const config = fs.readFileSync(configFile, 'utf8');

const regex = /parent {[\s\S]*type.*[\s\S]*subtype.*[\s\S]*element.*[\s\S]*attributes.*[\s\S]*value testvalue.*[\s\S]*owner person1/;
const match = config.match(regex);
console.log("Match:", match);
```

Kodu açıklamaya gerek duyulmayacak kadar basit diye düşünüyorum. Konfigürasyonu okuduk, sonrasında `RegEx` oluşturup aradığımız şeyin orada olup olmadığını kontrol ediyoruz basitçe, çalıştırıp sonuca bakalım.

```
code > /usr/bin/time -al node validate-config.js settings1.conf
Match: [
  'parent {\n' +
    '    type {\n' +
    '        subtype TestSubType {\n' +
    '            element TestElement {\n' +
    '                attributes {\n' +
    '                    name testname;\n' +
    '                    description testdescription;\n' +
    '                    count 1234;\n' +
    '                    value testvalue;\n' +
    '                }\n' +
    '                owner person1',
  index: 0,
  input: 'parent {\n' +
    '    type {\n' +
    '        subtype TestSubType {\n' +
    '            element TestElement {\n' +
    '                attributes {\n' +
    '                    name testname;\n' +
    '                    description testdescription;\n' +
    '                    count 1234;\n' +
    '                    value testvalue;\n' +
    '                }\n' +
    '                owner person1;\n' +
    '            }\n' +
    '        }\n' +
    '        subtype TestSubType2 {\n' +
    '            element TestElement2 {\n' +
    '                attributes {\n' +
    '                    name testname2;\n' +
    '                    description testdescription2;\n' +
    '                    count 2;\n' +
    '                    value 2\n' +
    '                }\n' +
    '                owner unknown;\n' +
    '            }\n' +
    '        }\n' +
    '    }\n' +
    '}\n',
  groups: undefined
]
        0.14 real         0.10 user         0.02 sys
            23429120  maximum resident set size
                   0  average shared memory size
                   0  average unshared data size
                   0  average unshared stack size
                6135  page reclaims
                   3  page faults
                   0  swaps
                   0  block input operations
                   0  block output operations
                   0  messages sent
                   0  messages received
                   0  signals received
                   3  voluntary context switches
                 199  involuntary context switches
           507784527  instructions retired
           338288340  cycles elapsed
             9248768  peak memory footprint
code >
```

Her şey harika, kodu yazdık, yaygın olarak kullanılan konfigürasyon dosyası içeriği ile test ettik hatasız bir şekilde `0.14` saniye gibi hızlı bir sürede çalıştı ve aradığımız şeyi buldu ve ekrana yazdı.
Tabi kodumuz canlı bir sistemde, bizim kafamızda olan en temel senaryoyu içeren konfigürasyon dosyasın dışında farklı girdiler ile test edilene kadar...

Farklı dosyalar işin içine girince işler karışmaya başlayabilir sıkı durun. Kodu bir de şöyle bir dosya ile test edelim bakalım neler olacak.

```
parent {
    type {
        subtype TestSubType {
            element TestElement {
                attributes {
                    name testname;
                    description testdescription;
                    count 1234;
                    value testvalue;
                }
                owner person1;
            }
        }
        subtype TestSubType1 {
            element TestElement1 {
                attributes {
                    name testname1;
                    description testdescription1;
                    count 1;
                    value 1
                }
                owner person2;
            }
        }
        subtype TestSubType2 {
            element TestElement2 {
                attributes {
                    name testname2;
                    description testdescription2;
                    count 2;
                    value 2
                }
                owner unknown;
            }
        }
        subtype TestSubType3 {
            element TestElement3 {
                attributes {
                    name testname3;
                    description testdescription3;
                    count 3;
                    value 3
                }
                owner unknown;
            }
        }
        subtype TestSubType3 {
            element TestElement4 {
                attributes {
                    name testname4;
                    description testdescription4;
                    count 4;
                    value 4
                }
                owner unknown;
            }
        }
        subtype TestSubType4 {
            element TestElement5 {
                attributes {
                    name testname5;
                    description testdescription5;
                    count 5;
                    value 5
                }
                owner unknown;
            }
        }
        subtype TestSubType5 {
            element TestElement6 {
                attributes {
                    name testname6;
                    description testdescription6;
                    count 6;
                    value 6
                }
                owner unknown;
            }
        }
        subtype TestSubType6 {
            element TestElement7 {
                attributes {
                    name testname7;
                    description testdescription7;
                    count 7;
                    value 7
                }
                owner unknown;
            }
        }
        subtype TestSubType7 {
            element TestElement8 {
                attributes {
                    name testname8;
                    description testdescription8;
                    count 8;
                    value 8
                }
                owner unknown;
            }
        }
        subtype TestSubType8 {
            element TestElement9 {
                attributes {
                    name testname9;
                    description testdescription9;
                    count 9;
                    value 9
                }
                owner unknown;
            }
        }
        subtype TestSubType9 {
            element TestElement10 {
                attributes {
                    name testname10;
                    description testdescription10;
                    count 10;
                    value 10
                }
                owner unknown;
            }
        }
        subtype TestSubType10 {
            element TestElement11 {
                attributes {
                    name testname11;
                    description testdescription11;
                    count 11;
                    value 11
                }
                owner unknown;
            }
        }
    }
}
```

Yukarıdaki konfigürasyon dosyası ile test edelim bakalım neler olacak

```
code > /usr/bin/time -al node validate-config.js settings2.conf
Match: [
  'parent {\n' +
    '    type {\n' +
    '        subtype TestSubType {\n' +
    '            element TestElement {\n' +
    '                attributes {\n' +
    '                    name testname;\n' +
    '                    description testdescription;\n' +
    '                    count 1234;\n' +
    '                    value testvalue;\n' +
    '                }\n' +
    '                owner person1',
  index: 0,
  input: 'parent {\n' +
    '    type {\n' +
    '        subtype TestSubType {\n' +
    '            element TestElement {\n' +
    '                attributes {\n' +
    '                    name testname;\n' +
    '                    description testdescription;\n' +
    '                    count 1234;\n' +
    '                    value testvalue;\n' +
    '                }\n' +
    '                owner person1;\n' +
    '            }\n' +
    '        }\n' +
    ....
    ....
    ....
  groups: undefined
]
       18.96 real        18.81 user         0.04 sys
            23609344  maximum resident set size
                   0  average shared memory size
                   0  average unshared data size
                   0  average unshared stack size
                6185  page reclaims
                   0  page faults
                   0  swaps
                   0  block input operations
                   0  block output operations
                   0  messages sent
                   0  messages received
                   0  signals received
                   7  voluntary context switches
                4728  involuntary context switches
        154144862698  instructions retired
         64223225741  cycles elapsed
             9379840  peak memory footprint
```

Eğer kodu kendi ortamınızda denerseniz zaten direk farkı hissedeceksiniz ama yukarıdaki çıktıdan da göründüğü gibi, ikinci konfigürasyon dosyasında 10 adet fazladan bizim aramadığımız farklı tipte konfigürasyonlar olduğunda
toplam süre neredeyse 20 saniyeye çıktı yani ilk versiyondan 100 katından daha yavaş çalıştı.

Eğer testinizi kendi ortamınızda yapmak istemiyorsanız muhtemelen çoğunuzun bildiği `regex101` sitesini ve yukarıdaki ilk örneğin orada çalışan versiyonunu [bu linkten](https://regex101.com/r/7C7Wvo/1) deneyebilirsiniz.

![Capture 2](/img/hateregex/regex101-backtrack.png)

Kodu JavaScript ile yazsak da RegEx motoru olarak sitedeki örneği `PCRE2` bıraktım çünkü `Debugger` kısmı JavaScript için mevcut değil ve özellikle yukarıdaki resimde görüldüğü gibi 100.000 den fazla deneme yapıp sonunda bize meşhur
`Catastrophic backtracking` hatasını verdiğini görmenizi istedim. RegEx motorunu JavaScript yaparsanız çalışıp bu size sonuç gösterecek ama bu işlemi yapmak için yüzlerce hatta binlerce defa deneme yaptığı gerçeğini değiştirmeyecek.
Zaten daha uzun konfigürasyon dosyası verdiğimizde sürenin logaritmik olarak 20 saniyeye çıkmasının sebebi de aranan şeyi bulmak için deneme sayılarının çok daha fazla artmasından kaynaklanıyor.

Bu sorun canlı ortamda bu konfigürasyonun çok benzeri ve çok daha uzunu ile
başıma geldiği için sistem bunu 20 saniyede de bitiremiyordu ve sorunun ana
sebebini bulmak için günler harcadık diyebilirim. İşin kötü tarafı bu sorun
NodeJs ve JavaScript diline özel değil, diğer bir çok programlama dili bu tarz
bir durumda aynı sorunla karşılaşıyor.  Burada NodeJs tarafında ek olarak işi
daha da kötü hale getiren başımızın belası [Event Loop](https://nodejs.org/en/learn/asynchronous-work/event-loop-timers-and-nexttick)
bir işlem tarafından meşgul edildiğinde sistem cevap veremez hale geliyor.

### Kazık 2 - Temel Sebep

Sorunun sebebi NodeJs ve benzer diğer programlama dillerinde `Regular Expression` motorunun nasıl geliştirildiği ve yapısı ile alakalı ve çözümü de her durumda o kadar basit değil. JavaScript, C#, Perl.. gibi programlama dillerinde
RegEx kütüphaneleri genellikle [Backtracking](https://en.wikipedia.org/wiki/Backtracking) algoritmasını içerecek şekilde geliştiriliyor. Bu da bir anlamda, aranan şeyi bulmak için `Brute Force` yöntemi yerine biraz daha akıllı olarak tüm olasılıkları denemeye dayanan
bir algoritma. 

Böyle olunca bu tarz programlama dili ortamlarında kullandığınız RegEx pattern, size verilen yani içinde arama yapacağınız girdi çok fazla önem ifade ediyor. Yani bu tarz dillerde düzgün yazılmamış bir RegEx sisteminizi kitleyecek,
cevap veremeyecek hale getirmesi oldukça olası, bu tarz ataklara `ReDos` atakları deniyor, NodeJs özelinde [bu linkten](https://nodejs.org/en/learn/asynchronous-work/dont-block-the-event-loop#blocking-the-event-loop-redos) örnekleri ile birlikte
inceleyebilirsiniz. 

Yıllar önce programcıların kutsal bilgi kaynağı `stackoverflow.com` dahi aynı sebepten dolayı çökmüştü detaylara [buradan](https://adtmag.com/blogs/dev-watch/2016/07/stack-overflow-crash.aspx) göz atabilirsiniz.

### Kazık 2 - Alternatif 1

Kullandığımız RegEx pattern çok düşünülmeden, performans etkisi göz ardı edilerek yazılmış onu biraz daha optimize ederek daha iyi sonuçlar alabiliriz diye düşünüyorum. Eski pattern çok fazla `greedy` yani bulabildiğin kadar bul tarzı `.*` ifadeleri
kullandığından çok fazla kontrol yapıyordu bunu azaltmak için kodu şu şekilde değiştirip tekrar deneyelim.

```
const fs = require('fs');

const args = process.argv.slice(2);
if (args.length < 1) {
    console.log('missing arguments');
    process.exit(1);
}
const configFile = args[0];
const config = fs.readFileSync(configFile, 'utf8');

const regex = /parent\s*\{\s*type\s*\{[^{}]*subtype\s+TestSubType\s*\{[^{}]*element\s+TestElement\s*\{[^{}]*attributes\s*\{[^{}]*value\s+testvalue[^{}]*\}[^{}]*owner\s+person1/;
const match = config.match(regex);
console.log("Match:", match);
```

Kodu tekrar çalıştıralım bakalım ne kadar sürecek.

```
code > /usr/bin/time -al node validate-config-alt-1.js settings2.conf
Match: [
  'parent {\n' +
    '    type {\n' +
    '        subtype TestSubType {\n' +
    '            element TestElement {\n' +
    '                attributes {\n' +
    '                    name testname;\n' +
    '                    description testdescription;\n' +
    '                    count 1234;\n' +
    '                    value testvalue;\n' +
    '                }\n' +
    '                owner person1',
  index: 0,
  input: 'parent {\n' +
    '    type {\n' +
    '        subtype TestSubType {\n' +
    '            element TestElement {\n' +
    '                attributes {\n' +
    '                    name testname;\n' +
    '                    description testdescription;\n' +
    '                    count 1234;\n' +
    '                    value testvalue;\n' +
    '                }\n' +
    '                owner person1;\n' +
    '            }\n' +
    '        }\n' +
    ...
    ...
    ...
    '    }\n' +
    '}\n',
  groups: undefined
]
        0.16 real         0.05 user         0.02 sys
            23588864  maximum resident set size
                   0  average shared memory size
                   0  average unshared data size
                   0  average unshared stack size
                6175  page reclaims
                   3  page faults
                   0  swaps
                   0  block input operations
                   0  block output operations
                   0  messages sent
                   0  messages received
                   0  signals received
                  13  voluntary context switches
                 127  involuntary context switches
           252044844  instructions retired
           217955836  cycles elapsed
             9351168  peak memory footprint
```

20 saniye süren konfigürasyon ile çalıştırmama rağmen `0.16` saniye gibi bir sürede tamamladı işlemi. Aynı şeyi `regex101` üzerinden görmek isterseniz [buradan](https://regex101.com/r/Rvltc9/1) test edebilirsiniz.
Ama ekran görüntüsünden anlaşılacağı gibi kullanılan pattern içerisinde gelen her şeyi eşleştir yerine `{}` karakterleri dışında her şeyi eşleştir diyerek aradığını bulmak için yaptığı deneme sayısını çok aza indirmiş ve böylece süreyi kısaltmış olduk.

![Capture 2](/img/hateregex/regex101-backtrack-opt.png)

### Kazık 2 - Alternatif 2

Peki kullanılan RegEx pattern ilk olduğu gibi, hiç optimize edilmeden tüm her şeyi bulacak şekilde kalsın ama yine de hızlı çalışsın dersek ne yapabiliriz? Hatırlarsanız bunun çok yavaş çalışmasının sebebi kullanılan RegEx motorunun yapısından ve kullanılan
algoritmalardan kaynaklanıyor demiştik, o zaman biz de motoru değiştirerek sorunu çözebiliriz, nasıl fikir?

Kodun ilk halini, alıp aşağıdaki gibi farklı bir RegEx motoru ile değiştirerek çalıştırıyoruz.

```
const fs = require('fs');
var RE2 = require("re2");

const args = process.argv.slice(2);
if (args.length < 1) {
    console.log('missing arguments');
    process.exit(1);
}
const configFile = args[0];
const config = fs.readFileSync(configFile, 'utf8');

const regex = /parent {[\s\S]*type.*[\s\S]*subtype.*[\s\S]*element.*[\s\S]*attributes.*[\s\S]*value testvalue.*[\s\S]*owner person1/;
var re = new RE2(regex);
const match = config.match(re);
console.log("Match:", match);
```

Kodu aşağıdaki gibi çalıştırdığımızda sonuç ne olacak bakalım.

```
hate-regex > /usr/bin/time -al node validate-config-alt-2.js settings2.conf
Match: [
  'parent {\n' +
    '    type {\n' +
    '        subtype TestSubType {\n' +
    '            element TestElement {\n' +
    '                attributes {\n' +
    '                    name testname;\n' +
    '                    description testdescription;\n' +
    '                    count 1234;\n' +
    '                    value testvalue;\n' +
    '                }\n' +
    '                owner person1',
  index: 0,
  input: 'parent {\n' +
    '    type {\n' +
    '        subtype TestSubType {\n' +
    '            element TestElement {\n' +
    '                attributes {\n' +
    '                    name testname;\n' +
    '                    description testdescription;\n' +
    '                    count 1234;\n' +
    '                    value testvalue;\n' +
    '                }\n' +
    '                owner person1;\n' +
    '            }\n' +
    '        }\n' +
    ...
    ...
    ...
    '    }\n' +
    '}\n',
  groups: undefined
]
        0.09 real         0.06 user         0.02 sys
            24272896  maximum resident set size
                   0  average shared memory size
                   0  average unshared data size
                   0  average unshared stack size
                6357  page reclaims
                   0  page faults
                   0  swaps
                   0  block input operations
                   0  block output operations
                   0  messages sent
                   0  messages received
                   0  signals received
                   7  voluntary context switches
                 152  involuntary context switches
           265322523  instructions retired
           219898560  cycles elapsed
             9580544  peak memory footprint
```

İlk kullandığımız pattern üzerinden herhangi bir değişiklik yapmadan, büyük
konfigürasyon dosyası ile çalıştığında bile `0.09` saniyede çalışmış, yani
NodeJs tarafında kullanılan varsayın RegEx motorunun 200 katı daha hızlı
çalışmış. 

Yukarıdaki örneğin hızlı çalışmasının ana sebebi farklı bir algoritma ile geliştirilmiş ile kullanılan [RE2](https://github.com/uhop/node-re2) motor kullanması, tabi 
neden NodeJs core kütüphanesinin bunu kullanmadığı gibi bir soru sorabilirsiniz, bunun da bazı sebepleri var ama başka bir yazı konusu olduğu için şimdilik geçiyorum.

### Kazık 2 - Alternatif 3

Buradaki alternatif önerim için aşağıya bir kod koymayacağım çünkü bazen `Regular Expressin` kullanmamak da çözümün ta kendisi olabiliyor, bir önceki yazıda da yöntem olarak buna değinmiştim.
Aslında bu tarz bir durumda eğer bunu işimin gereği olarak sık sık kontrol etmem gereken bir şey olarak görür isem, yukarıdaki konfigürasyon formatı için yazılmış bir `parser` kullanmak ve onun üzerinden
bu kontrolü yapmak çok daha iyi bir çözüm olacaktır. Bir nevi JSON formatında bir konfigürasyon dosyasında bulunan spesifik bir değeri `RegEx` ile de kullanarak kontrol edebilirim ama, tavsiyem burada
düzgün bir JSON parser kullanıp ilgili değeri programlama dilinde kontrol etmek olacaktır.

Parser genelde bu formata ve işe özel yazıldığı ve optimize edildiği için hem daha az hata olacaktır hem de daha hızlı çalışabilir.

### Ders

Belki çoğu kişi RegEx kullanırken performans etkisini, hatta basit bir `pattern` aramanın bütün sistemi cevap veremez hale getireceğini hiç düşünmeden kullanıyor ama görüldüğü gibi 
kullandığımız `pattern` bize gelen beklemediğimiz bir `input` oldukça fazla önem arz ediyor. Bu yüzden geliştirdiğimiz sistemlerde `RegEx` kullanırken, bu yanlarını da bilmeli, en kötü senaryoya göre test etmeli,
hatta kullandığımız programlama dilinin de ne tarz bir `RegEx` algoritması kullandığını bilmemiz gerekiyor ki bu tarz hataları yapmayalım. Bu hataları canlı sistemlerde bulmak oldukça zor ve can sıkıcı olabiliyor.

### Sırada Ne Var?

Vakit bulabilirsem, neden NodeJs RegEx motorunda yavaş çalıştığını, kullanılan algoritmanın etkisini, diğer dillerde durumun nasıl olduğunu bir örnek yaparak başka bir yazıda açıklamaya anlatmaya çalışacağım.
En eğlenceli kısmı bu olacak sanırım, öğrendiklerimizi pekiştirmek için ufak bir `RegEx` motoru yapabiliriz.



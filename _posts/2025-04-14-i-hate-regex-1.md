---
layout: post
title: "I Hate Regular Expressions - 1"
description: "I Hate Regular Expressions - 1"
date: 2025-04-14T07:00:00-07:00
tags: regex
---

![Capture 1](/img/hateregex/hateregex.png)

Bu yazı serisi şu ana kadar 1 bölümden oluşmaktadır, diğer bölümlere aşağıdaki linklerden ulaşılabilir. Yazı içeriğinde geçen kodlara
[bu linkten](https://gist.github.com/caltuntas/c09ddd9e4297a0235924f65e6f72a4f6) ulaşabilirsiniz.

1. [I Hate Regular Expressions - 1](https://www.cihataltuntas.com/2025/04/14/i-hate-regex-1) (Bu Yazı)
   - Bu yazıda, string içeriği değiştirmede dikkatli olmadan kullanılan Regular
     Expression yönteminin ne tarz sorunlara yol açabileceğini ve alternatif
     olarak neler yapabileceğimizi inceliyoruz.
  
Hani insanın parmağının ucuna batan ufak bir diken ya da kıymık gibi bir şey olur da çıkaramadığınızda canınızı sıkar ve
hayat kalitenizi düşürür ya, benim için bu yazıyı yazmak öyle hissettiriyor. Yazdığım gün parmağımdan çıkarmış gibi rahatlayacağım
çünkü gelecekteki kendime ve bunu okuyacaklara bir uyarı niteliğinde olacak, ve neden ve hangi durumlarda `Regular Expression` kullanmamaları gerektiğini anlatmaya çalışacağım.

İnsan tecrübe etmeden sanırım bir kavramı anladığını düşünse de  gerçek anlamda deneyimleyip artısını eksisini görmeden tam olarak kavrayamıyor, `Regular Expression` kullanımı da
benim için böyle bir konuydu. Neredeyse 16 sene önce, 2009 yılında [I love Regular Expressions](https://www.cihataltuntas.com/2009/03/16/i-love-regex.html) yazımda ona olan
sevgimi kaleme dökmüştüm ve bana kolaylık sağlayan bir kullanım durumunu anlatmıştım. Yıllar içinde de kullanım oranım artarak pik yaptı, nerede bir `string` arama, değiştirme
eşleştirme problemi olsa, elimde olan çekici yani `RexEx` kullanarak kafasına vurup geçiyordum. 

Sonrasında ise RegEx sayesinde yediğim kazıkların boyu pardon tecrübem artınca kullanmadan önce defalarca düşün, alternatif ara, eğer gerçekten mecbursan çok iyi test ederek karar ver seviyesine geldi.

>> Some people, when confronted with a problem, think “I know, I'll use regular expressions.”  Now they have two problems.
>> 
>> Jamie Zawinski
 
Jamie herhalde ben daha `Regular Expression` ifadesinin adını bile duymadan 90'lı yılların sonunda ne güzel ifade etmiş, yukarıdaki alıntıyı o yüzden hep çok sevmişimdir. Tarihçesini merak edenler [buraya](https://regex.info/blog/2006-09-15/247)
bakabilirler.

Bu arada yukarıdaki resmi RegEx çok seven ve ondan dolayı [bu
siteyi](https://ihateregex.io/) hazırlayan arkadaşın sitesinden aldım.  Uzun
bir giriş yaptıktan sonra sıra geldi yediğim bazı kazıkları örnekler ile
anlatmaya ki aynı hataları tekrar yapmayalım. Tabi geri dönüp bakınca burada
anlatması ve kaçınılması basit gibi gözüküyor, fakat canlı ortamda saatlerini
ve günlerinizi bu tarz hataları bulmakla geçirebiliyorsunuz.

### Kazık 1

Herhalde 10 sene önce NodeJs kullanarak şöyle bir kod yazmışım, tabi bu kod bu kadar izole çalışmıyor yüz binlerce satır kod ile birlikte
belirli durumlara göre canlı ortamda tetikleniyor gibi düşünün.

```
const placeHolderPattern = /#{(\w+)}/;
const allPlaceHoldersPattern = new RegExp(placeHolderPattern, 'g');
const args = process.argv.slice(2);

if (args.length < 2) {
  console.log('missing arguments');
  process.exit(1);
}

const replacements = [
  { name: 'placeholder1', value: args[0] },
  { name: 'placeholder2', value: args[1] },
];

let output = 'some text template #{placeholder1} and #{placeholder2} and some more text #{placeholder1}';
let matches;

do {
  console.log('after replacement output=' + output);
  matches = allPlaceHoldersPattern.exec(output);
  if (matches) {
    const placeHolder = matches[1];
    const replacement = replacements.find(r => r.name === placeHolder);
    
    if (!replacement) {
      throw new Error(`Replacement for ${placeHolder} place holder does not exist.`);
    }
    
    output = output.replace(placeHolderPattern, replacement.value || '');
    allPlaceHoldersPattern.lastIndex = 0;
  }
} while (matches);

console.log(output);
```

Oldukça basit bir kod değil mi? Genel formatlama, kontroller gibi şeylere takılmayıp biraz kodu bir AI aracına sormadan inceleyin derim bakalım
sorunu bulabilecek misiniz?

Genel olarak kodun yapmaya çalıştığı şeyi şu şekilde anlatayım. Elimizde aşağıdaki gibi bir şablon var diye düşünün, bu bir e-mail şablonu ya da farklı amaçla kullanılacak bir şey olabilir.

```
some text template #{placeholder1} and #{placeholder2} and some more text #{placeholder1}
```

Yukarıdaki `#{}` içinde olan değerler aslında değiştirilecek alanlar, kullanıcıdan gelen ya da sistem tarafından hesaplanan değerler çalışma sırasında bu yeri tutan `placeholder1 ve placeholder2` değerleri ile değiştirilip,
sonrasında bu belki kullanıcıya gösterme, mail atma ya da sistemde saklama amacıyla kullanılıyor. Aslında çok sıradan bir senaryo gibi.

Kodu şu şekilde çalıştıralım ve birkaç girdi ile ürettiği çıktıya bakalım, o zamana kadar siz de sorunu belki çoktan tespit etmiş olursunuz.

```
code > node code/regex-replace.js test1 test2
after replacement output=some text template #{placeholder1} and #{placeholder2} and some more text #{placeholder1}
after replacement output=some text template test1 and #{placeholder2} and some more text #{placeholder1}
after replacement output=some text template test1 and test2 and some more text #{placeholder1}
after replacement output=some text template test1 and test2 and some more text test1
some text template test1 and test2 and some more text test1
```

Üretilen çıktı da aslında kodun ne yaptığını gösteriyor, yer tutucu olarak kullandığımız `placeholder` değerlerinin hepsini değiştirmek için bir `do-while` döngüsü içinde
her eşleşmede sıfırlama yapıp bir sonrakini değiştiriyor. Javascript dokümanına bakınca aşağıdaki gibi açıklamış

```
... the replacement can be a string or a function called for each match. If pattern is a string, only the first occurrence will be replaced. The original string is left unchanged.
```

Şimdi bazı arkadaşların neden `replaceAll` kullanmadınız, ne gerek var kulağı tersten göstermeye dediğini duyar gibiyim, sebebi [replaceAll](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/replaceAll) 
fonksiyonu **Node** ortamında 2020 yılında versiyon **15** sonrasında geldi, bu kod geliştirildiğinde öyle bir fonksiyonumuz yoktu maalesef. Dikiz aynasından bakınca
farklı alternatifler mutlaka bulunabilir ama o tarihte bir nevi kendi **replaceAll** fonksiyonumuzu yazmışız diyebilirim. Mutlaka kod daha iyi yazılabilirdi, hatta asıl soruna odaklandıktan sonra
nasıl yazabilirdik onlara da değinmeye çalışacağım fakat şimdilik fazla uzatmadan soruna odaklanalım.

Sorunu kendi başınıza bulduysanız tebrikler, canlı ortamında sorunu yaşayıp tatsız bir hata ayıklama süreci sonucunda ancak tespit edebilmiştim. Ama benim gibi bulamayanlar için kodu bir de aşağıdaki gibi çağırıp neler olduğuna bakalım.

```
code > node code/regex-replace.js test1 '668%X6g$&8kNUkpZVvb'
after replacement output=some text template #{placeholder1} and #{placeholder2} and some more text #{placeholder1}
after replacement output=some text template test1 and #{placeholder2} and some more text #{placeholder1}
after replacement output=some text template test1 and 668%X6g#{placeholder2}8kNUkpZVvb and some more text #{placeholder1}
after replacement output=some text template test1 and 668%X6g668%X6g#{placeholder2}8kNUkpZVvb8kNUkpZVvb and some more text #{placeholder1}
after replacement output=some text template test1 and 668%X6g668%X6g668%X6g#{placeholder2}8kNUkpZVvb8kNUkpZVvb8kNUkpZVvb and some more text #{placeholder1}
after replacement output=some text template test1 and 668%X6g668%X6g668%X6g668%X6g#{placeholder2}8kNUkpZVvb8kNUkpZVvb8kNUkpZVvb8kNUkpZVvb and some more text #{placeholder1}
after replacement output=some text template test1 and 668%X6g668%X6g668%X6g668%X6g668%X6g#{placeholder2}8kNUkpZVvb8kNUkpZVvb8kNUkpZVvb8kNUkpZVvb8kNUkpZVvb and some more text #{placeholder1}
after replacement output=some text template test1 and 668%X6g668%X6g668%X6g668%X6g668%X6g668%X6g#{placeholder2}8kNUkpZVvb8kNUkpZVvb8kNUkpZVvb8kNUkpZVvb8kNUkpZVvb8kNUkpZVvb and some more text #{placeholder1}
after replacement output=some text template test1 and 668%X6g668%X6g668%X6g668%X6g668%X6g668%X6g668%X6g#{placeholder2}8kNUkpZVvb8kNUkpZVvb8kNUkpZVvb8kNUkpZVvb8kNUkpZVvb8kNUkpZVvb8kNUkpZVvb and some more text #{placeholder1}
after replacement output=some text template test1 and 668%X6g668%X6g668%X6g668%X6g668%X6g668%X6g668%X6g668%X6g#{placeholder2}8kNUkpZVvb8kNUkpZVvb8kNUkpZVvb8kNUkpZVvb8kNUkpZVvb8kNUkpZVvb8kNUkpZVvb8kNUkpZVvb and some more text #{placeholder1}
after replacement output=some text template test1 and 668%X6g668%X6g668%X6g668%X6g668%X6g668%X6g668%X6g668%X6g668%X6g#{placeholder2}8kNUkpZVvb8kNUkpZVvb8kNUkpZVvb8kNUkpZVvb8kNUkpZVvb8kNUkpZVvb8kNUkpZVvb8kNUkpZVvb8kNUkpZVvb and some more text #{placeholder1}
...
...
```

Kendi ortamınızda denerken bir eliniz Control+C tuşunda olsun aksi durumda hızlıca sonsuza doğru kayan yazıları görünce başınız dönebilir. Peki kodu patlatan `668%X6g$&8kNUkpZVvb` parametresinin sorunu nedir?
Mozilla dokümanına bakarsanız, benim gözden kaçırdığım, hiç aklıma da gelmeyen [bu kısma](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/replace#specifying_a_string_as_the_replacement)
göz atabilirsiniz.

```
$&  Inserts the matched substring.
...
...
$n and $<Name> are only available if the pattern argument is a RegExp object. If the pattern is a string, or if the corresponding capturing group isn't present in the regex, then the pattern will be replaced as a literal
```

Sistem `$&` karakterlerini gördüğünde onları RegEx için özel karakterler olarak algılayıp, yerlerine eşleşen yani **match** olan ifadeyi yerleştiriyor. Yani biz ilk değiştirmesi gereken ve eşleşen `#{placeholder2}` yerine `668%X6g$&8kNUkpZVvb` 
koymasını beklerken, bizim kontrolümüz dışında gelen değer içerisindeki özel karakterler yüzünden oraya `668%X6g#{placeholder2}8kNUkpZVvb` koyuyor ve değişim işi hiç bitmediğinden dolayı bu sonsuza kadar devam ediyor, geçmiş olsun ve canlı 
sistemde sorunu bulmakla uğraşacak arkadaşa da kolay gelsin diyelim.

### Kazık 1 - Alternatif 1

Hatalarımızdan ders çıkarıp kodu bugün nasıl yazardık ya da bu sorunla uğraşmamak için nasıl yazmalıydık onlara değinelim.

```
const placeHolderPattern = /#{(\w+)}/g;
const args = process.argv.slice(2);

if (args.length < 2) {
  console.log('missing arguments');
  process.exit(1);
}

const replacements = [
  { name: 'placeholder1', value: args[0] },
  { name: 'placeholder2', value: args[1] },
];

function replacer(match, placeHolderName) { 
  const replacement = replacements.find(r => r.name === placeHolderName);
  if (!replacement) {
    throw new Error(`Replacement for ${placeHolder} place holder does not exist.`);
  }
  return replacement.value || '';
} 

let output = 'some text template #{placeholder1} and #{placeholder2} and some more text #{placeholder1}';
output = output.replace(placeHolderPattern, replacer);
console.log(output);
```

Daha önce çok dikkate almadığımız ama eğer, RegEx pattern yerine bir fonksiyon gönderirseniz her eşleşme için bu fonksiyon çağrılıp dönen değer ile değiştirilir yazıyordu, yukarıdaki kod parçasında bu yöntemi kullandık. Çalıştıralım ve sonucu görelim.

```
code > node code/regex-replace-alt-1.js test1 '668%X6g$&8kNUkpZVvb'
some text template test1 and 668%X6g$&8kNUkpZVvb and some more text test1
```

### Kazık 1 - Alternatif 2

Sonuç düzgün çalıştı, bu sefer özel karakter olsa da, bir sorun olmadı çünkü bu yöntem ile onları dikkate almıyor. Peki başka ne yapabilirdik? Günümüzde olsak bunu **replaceAll** kullanarak daha da kolay yazabilirdik diye düşünüyorum, deneyelim.

```
const args = process.argv.slice(2);

if (args.length < 2) {
  console.log('missing arguments');
  process.exit(1);
}

const replacements = [
  { name: 'placeholder1', value: args[0] },
  { name: 'placeholder2', value: args[1] },
];

let output = 'some text template #{placeholder1} and #{placeholder2} and some more text #{placeholder1}';
replacements.forEach((item) => {
  output = output.replaceAll(`#{${item.name}}`, item.value || '');
}
);

console.log(output);
```

Bu sefer elimizde, yeni NodeJs versiyonu var ve **replaceAll** işimizi daha da kolaylaştırdı. Regex kullanmaya bile gerek kalmadı, basit mantık elimizde değiştirilmesi gereken tüm değerlerin üzerinden geçip
**replaceAll** ile değiştirme işlemini yapıyoruz. Tekrar deneyelim ve çalıştığını görelim.

```
code > node code/regex-replace-alt-2.js test1 '668%X6g$&8kNUkpZVvb'
some text template test1 and 668%X6g$&8kNUkpZVvb and some more text test1
```


### Kazık 1 - Alternatif 3

Peki geçmişe gidip tekrar yazacak olsam elimde **replaceAll** olmasaydı ne yapardım? Hiç RegEx falan uğraşmadan bildiğimiz döngü içerisinde her değiştirilmesi gereken
değeri değiştirip kalmayana kadar devam ederdim. Yani kod aşağıdaki gibi olurdu.

```
const args = process.argv.slice(2);

if (args.length < 2) {
  console.log('missing arguments');
  process.exit(1);
}

const replacements = [
  { name: 'placeholder1', value: args[0] },
  { name: 'placeholder2', value: args[1] },
];

let output = 'some text template #{placeholder1} and #{placeholder2} and some more text #{placeholder1}';
replacements.forEach((item) => {
  const placeholder = `#{${item.name}}`;
  while (output.includes(placeholder)) {
    output = output.replace(placeholder, ()=>item.value || '');
  }
}
);

console.log(output);
```

Denediğimizde yine düzgün çalıştı. 

```
code > node code/regex-replace-alt-3.js test1 '668%X6g$&8kNUkpZVvb'
some text template test1 and 668%X6g$&8kNUkpZVvb and some more text test1
```


Burada sinir bozucu olan şey, varsayılan olarak ben A değerini B değeri ile
değiştirmek istediğinizde RegEx kullanmasanız bile Javascript değiştirilmesi
gereken B içerisinde eğer özel bir karakter görürse, bunları yine yorumlamaya
çalışıyor.  Aşağıdaki çıktıya dikkat edin, herhangi bir RegEx kullanmadım

```
code > node --eval 'console.log("deneme cihat yanilma".replace("cihat", "aaa$&bbb"));'
deneme aaacihatbbb yanilma
```

Bunun sebebi replacement olarak `$&` gördüğünde yine bunu özel karakter olarak yorumluyor. Bunu önüne geçmek istiyorsanız ya `$` karakterlerini escape etmeniz gerekiyor ya da yukarıda ve aşağıda yaptığım gibi replacement değerini 
fonksiyon olarak vermeniz gerekiyor.

```
code > node --eval 'console.log("deneme cihat yanilma".replace("cihat", ()=>"aaa$&bbb"));'
deneme aaa$&bbb yanilma
```

### Ders

Kendi adıma yukarıdaki yaşadığım problemden çıkardığım dersi özetleyecek olur isem, RegEx kullanmadan önce bunu standart `string` işlemleri ile yapabiliyor muyum 
ona bakarım, hatta standart RegEx kullanmadan bazen bir kaç satır data fazla kod yazmak bile RegEx kullanmaktan uzun vadede daha avantajlı olabilir. Kısacası gerçekten ihtiyaç olduğunda,
artılarını eksilerini değerlendirerek kullanmak, hatta mümkünse daha basit çözümler varsa onlarla ilerlemeyi tavsiye ederim. 

Başlık biraz `Clickbait` gibi durabilir, tabi gerçekte herhangi bir teknolojiden nefret etmek ya da ona aşık olmak gibi bir yaklaşım pek mantılı değil fakat yıllar önceki eski yazıma ithafen 
böyle bir başlık seçmeyi istedim. 

RegEx sebebiyle yediğimiz kazıklar tabi bitmedi, bu yazı biraz uzun olduğu için burada bitirelim. Sonraki yazıda farklı bir probleme değineceğim, hatta çoğu kişinin farkında olmadan 
çok fazla karşılaştığı bir sorun olduğunu düşünüyorum. 

---
layout: post
title: "I Love Regular Expressions"
description: "I Love Regular Expressions"
date: 2009-03-16T07:00:00-07:00
tags: regex
---

![Capture 1](/img/iloveregex/ilove2.jpg)

Evet gerçekten Regular Expressions’ı seviyorum. Aslında sevgim tamamen
duygusal diyebiliriz. Bende bu duyguları oluşturan; nefret ettiğim string,text
arama,değiştirme gibi işlemleri benim için çok basitleştirmesi. Dedim ya tamamen
duygusal :)

Çok süper Regular Expressions bilmiyorum fakat gün geçtikçe ne kadar kullanışlı
olabildiğini gördüğüm için sürekli sevgim sürekli artıyor diyebilirim. Regular
Expressions’ı neden çok seviyorum günlük yaşadığım bir problemle sizlere de
anlatmaya çalışayım.

Geliştirilen bir Java projesinde Hibernate üzerinden gerçekleştirilen
işlemlerin SQL kodunu görmek istiyorduk. Hibernate sağ olsun bu konuda bize çok
yardımcı oldu. Öncelikle Hibernate’den SQL loglarını alabilmek için baya
uğraştık diyebilirim. Öncelikle bize sadece SQL cümlelerini verdi ve
parametreler yerine log dosyarına “?” işareti koyarak oldukça kalbimizi kırdı.
Ardından uzun süren log konfigürasyon araştırmamız sonucunda “?” işaretleri
gelen yerlerde olması gereken parametreleri de yazdırabildik. Hibernate Log
çıktısı aşağıdaki gibiydi.

```
11:35:55,656 DEBUG [SQL]  update TABLE set Date=?, ID=?, USERNAME=?, =?, Name=?
11:35:55,656 DEBUG [TimestampType]  binding '2009-03-11 11:35:54' to parameter: 1
11:35:55,656 DEBUG [StringType]  binding 34456 to parameter: 2
11:35:55,656 DEBUG [StringType]  binding 'GM' to parameter: 3
11:36:07,890 DEBUG [SQL]  delete from TABLE where ID=?
11:36:07,890 DEBUG [StringType]  binding 332244 to parameter: 1
```
 
Bu cümlelerde bizim aşağıdaki gibi SQL cümlelerini çıkarmamız gerekiyordu.

```
update TABLE set Date='2009-03-11 11:35:54', ID=34456, USERNAME='GM'
delete from TABLE where ID=332244
```
Yukarıdaki her SQL log bloku sınıflara ayıran bir sınıf ve de bu SQL
bloklarındaki logları ayrıştırıp parametre değerlerini içeren SQL cümlesini
oluşturan bir sınıf yazmak gerekiyordu. Bu sınıf basit olarak “?” işaretleri
yerine parametreleri koyacaktı. Bunu 1. soru işareti yerine “binding” ve “to
parameter: 1” kelimeleri arasında bulunan değeri koyacak 2. “?” işareti yerine
“binding” ve “to parameter: 2” kelimeleri arasındaki değerleri koyarak devam
edip bize SQL cümlesini hazırlayacaktı. Bunun için verilen indeksteki(1.,2…) “?”
işareti yerine gelmesi gereken değeri bulan bir metodu aşağıdaki gibi yazdım.

```
private String getParameterValue(int parameterIndex){
    final String bindingKeyword = "binding";
    final String parameterKeyword = "to parameter: " + parameterIndex;
 
    String[] lines =log.split("\n");
     
    for(String line:lines){
        if(line.contains(parameterKeyword)){
            int bindingIndex =line.indexOf(bindingKeyword);
     
            int parameterToIndex=line.indexOf(parameterKeyword);
            String parameter=line.substring(bindingIndex+bindingKeyword.length(), parameterToIndex);
            return parameter.trim();
        }
    }
    return "";        
}
```

Yukarıda yöntem önce Log String’i satırlara ayırıyor ardından her satır
içerisinde “binding” ve “to parameter: 1” kelimelerinin bulunduğu index
değerlerini alıyor. Ardından bu index değerleri kullanarak iki index değeri
arasında bulunan "?" işareti yerine gelmesi gereken değeri çıkarıyor. Yani
hepimizin oldukça sık kullandığı klasik String işlemleri.Bu metodu Regular
Expressions kullanarak birde aşağıdaki gibi yazalım.

```
private String getParameterValue(int parameterIndex){
    String regex = "(?<=binding).*(?=to parameter: " + parameterIndex + ")";
    Pattern pattern = Pattern.compile(regex);
    Matcher matcher = pattern.matcher(log);
 
    if (matcher.find()) {
        return matcher.group().trim();
    }
    return "";
}
```

Evet Regular Expression Pattern’ımız sayesinde ne Index,Substring.. işlemleri
ile uğraşmak zorunda kalıyoruz nede log dosyasını satırlara ayırma
işlemleriyle. Basit bir RegEx ifadesi ile aradığımız değeri bütün text
içerisinden kolayca çıkarabiliyoruz. Yapmanız gereken tek şey uygun RegEx
pattern’ı hazırlamak ve ardından matcher.find() ile kendinizi RegEx’in ellerine
bırakıyorsunuz :)

Buraya kadar basit olan kısmıydı birde tüm dosyayı okuyup SQL bloklarını az
önce bahsettiğim SQL’i oluşturacak sınıfa parse eden Parser sınıfımız var.
Burada RegEx’in gücünü daha iyi görebileceksiniz.Tüm dosyayı okuyup SQL log
bloklarını ayıran metodumuz Regular Expression kullanmadan aşağıdaki gibiydi.

```
public ArrayList<sqllog> parse() {
    try {
         
        String line;
        boolean statementFound = false;
        StringBuilder stringBuilder = new StringBuilder();
        while ((line = reader.readLine()) != null) {
            if (statementFound == true && isSqlStatement(line)) {
                sqlStatements.add(stringBuilder.toString());
                stringBuilder.delete(0, stringBuilder.length());
                statementFound = false;
            }
 
            if (statementFound == false && isSqlStatement(line)) {
                statementFound = true;
            }
 
            if (statementFound) {
                stringBuilder.append(line + "\n");
            }
 
        }
 
        if (statementFound == true) {
            sqlStatements.add(stringBuilder.toString());
            stringBuilder.delete(0, stringBuilder.length());
            statementFound = false;
        }
 
        reader.close();
    } catch (IOException e) {
        System.out.println("Exception " + e.getMessage());
    }
    return getSqlLogs();
}
```


Yukarıdaki kod log dosyasında SQL bloklarını ayırarak SqlLog sınıflarını
oluşturuyor. Tabi bunu yaparken satırların alakasız birçok log arasında
satırların SQL içerip içermediğini kontrol ediyor. Eğer bulunduysa diğer SQL
satırı içeren satıra kadar alıp SqlLog sınıfını oluşturuyor. Bu kodu Regular
Expressions kullanarak aşağıdaki gibi tekrar yazalım.

```
public ArrayList<sqllog> parse() {
    try {
        Pattern pattern =
        Pattern.compile("(?s)((insert)|(update)|(delete)).+?(?=SQL)|((insert)|(update)|(delete)).*\\b");
        Matcher matcher = pattern.matcher(fromFile(file));
 
        while (matcher.find()) {
            String log = matcher.group();
            sqlLogs.add(new SqlLog(log));                
        }
    } catch (IOException e) {
    }
 
    return sqlLogs;
}
```


Yukarıdaki RegEx pattern ile insert,update,delete içeren tüm SQL bloklarını
çıkarabiliyoruz. Geçici değişkenler yok birçok if-else kontrolü yok, daha az
kod, hayat daha güzel…. Beni anladınız umarım. Bu yüzden Regular
Expressions’ı gerçekten seviyorum. :).Regular Expressions öğrenmeden önce bende
uzun süre gerek var mı diye düşünüp kararsız kalmıştım. Fakat gerçekten
öğrenmeye değer…

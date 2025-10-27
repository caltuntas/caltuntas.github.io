---
layout: post
title: "Endian Tedirginliği"
description: "Endian Tedirginliği"
date: 2025-10-24T07:00:00-07:00
tags: c,endianness
---
 
Kariyerimin ilk yıllarında daha çok Java, .NET gibi platformlarda kurumsal
uygulamalar tasarladığım için, tahmin edebileceğiniz gibi geliştirdiğimiz
yazılımların çok büyük oranı kullanıcıdan masa üstü ya da web tarayıcıda
çalışan uygulamalarla girdi alıp, bunu işledikten sonra veri tabanına yazıp
sonra da kullanıcıya sonuçları okumaktan, farklı bir şey yapmıyordu. 

Kulağa oldukça sıkıcı geliyor değil mi? Maalesef günümüzde masa üstü programların da neredeyse ortadan kalkmasıyla
herhalde %95 gibi bir oranda herkes web uygulaması geliştiriyor. Bu yüzden burada değineceğim konu bu alanlarda çalışan çoğu kişi için 
pratikte çok anlamlı olmayabilir fakat bilgisayarların nasıl çalıştığı ve alt seviye işleyiş konusunda oldukça faydalı olacaktır.

Tabi, kendi açımdan hep kafamın köşesinde duran bu konuyu pratik bir örnekle uygulayıp hem daha da pekiştirmek hem de anlatmak açısında güzel bir fırsat olduğu
için daha fazla uzatmadan başlayalım.

Eğer network programlama yapıyorsanız, binary dosya okuma yazma, ya da alt
seviye bir programlama diliyle bit byte gibi veri tipleri ile uğraşıyorsanız, karşınıza çıkabilecek ve öğrenmeniz
gereken kavramlardan birisi [Endian-ness](https://en.wikipedia.org/wiki/Endianness) kavramıdır.

## Tedirginlik

Son yıllarda network programlama ve biraz daha alt seviye işlerle uğraştığım için yazdığım kodun farklı bir Endian mimarisinde çalışan sistemde 
nasıl davranacağına dair hep bir tedirginlik olmuştur. Bir süredir x86 CPU kullanan Mac üzerinde işleri yaptığım için 
geliştirdiğim kod Little-Endian mimari ile uyumlu, bildiğim kadarı ile de gömülü cihazlar(MIPS,etc.) ve bazı main-frame mimariler dışında
çoğunluk Little-Endian yapısında çalışıyor ama örnek olarak network üzerinden bilgi alışverişi yapan bir yazılım geliştirdik, aklıma gelen ilk sorulardan biri
acaba Big-Endian bir sistemde gönderdiğimiz ya da oradan aldığımız veri doğru yorumlanacak mı?

Diğer bir sorun, yazdığımız kodu bu sistemlerde çalıştırmak zorunda kalabiliriz, örnek Go ile yazdığımız bir kod
[burada](https://go.dev/wiki/MinimumRequirements#architectures) görülebildiği gibi bir çok farklı Big-Endian CPU mimarisinde de çalışabilir.
Go ya da farklı diller bu mimarilerde çalışmayı desteklese de, yazdığınız kodun da Endian farklılığını gözeterek geliştirilmesi gerekiyor, aksi durumda beklenmedik
hatalar ile karşılaşabilirsiniz. Bugün de bunlardan biri hakkında örnek yapacağız tabi öncelikle Endian kavramını biraz daha netleştirelim.

## Birkaç Cümlede Endian 

Wikipedia sayfası oldukça detaylı anlatmış ama ben kendi yorumumu yapıp şöyle
bir özetle Endian kavramını açıklamak istiyorum.

Şimdi elimizde 1234567890 gibi bellekte 4 byte(32 bit) yer kaplayan bir sayı
olsun. Bu sayının hex karşılığı aşağıdaki gibi olacak.

```
> printf "%X\n" 1234567890 | xxd -r -p  | xxd -i |tr ',' ' '
  0x49  0x96  0x02  0xd2
```
Aynı sayıyı ikili sistemde göstermek istersek de aşağıdaki gibi gözükecek.
```
> printf "%X\n" 1234567890 | xxd -r -p | xxd -b -i | tr ',' ' '
  0b01001001  0b10010110  0b00000010  0b11010010
```

Peki bu sayıyı elimizdeki bellek adreslerine nasıl yerleştirebilirim? 

Little Endian sistemlerde yani daha yaygın olarak kullanılan x86, Arm gibi mimarilerde ve büyük ihtimalle sizin de kullandığınız kişisel bilgisayarınızda 
en düşük değere sahip byte `0xd2` en düşük bellek adresinde `00000000` tutulacak.

| Adres    | Değer |
|----------|-------|
| 00000000 | 0xd2  |
| 00000001 | 0x02  |
| 00000002 | 0x96  |
| 00000003 | 0x49  |

Big Endian sistemlerde yani MIPS, Spark gibi mimarilerde ise en düşük değer `0xd2` en yüksek bellek adresinde aşağıdaki gibi tutulacak.

| Adres    | Değer |
|----------|-------|
| 00000000 | 0x49  |
| 00000001 | 0x96  |
| 00000002 | 0x02  |
| 00000003 | 0xd2  |


Kısaca Little Endian sistemler en yüksek değeri en
düşük bellek adresine yerleştirecek ve diğerleri ardından gelecek, Big Endian
sistemler ise tam tersi yani en yüksek değeri en yüksek bellek adresine
yerleştirip diğerlerini ardından sıralayacak. 

En çok kafa karıştıran diğer bir nokta ise Endian yapısı 1 byte içinde olan bit sırasını değiştirmez, yani `0x49` değeri yani `01001001`
her iki mimaride de bit değerleri aynı şekilde bellekte tutulur.

>> Endianness bit sırasını etkilemez, birde fazla byte içeren değerlerin bellek üzerinde yerleşimini etkiler

## Belleğe Bir Göz Atalım

### Little Endian Sistemde Bellek

Yukarıda bahsettiğimiz değeri bir C kodu içine koyup kendi bilgisayarımda
derledim. 

```
// ...
int main() {
  uint32_t val=1234567890;
  printf("value=%d",val);
  return 0;
}
```

Ardından LLDB ile debug yaparak, ilgili değerin tekil byte
değerlerinin bellekte nereye yerleştirildiğine göz attım sonuç aşağıdaki gibi
çıktı.

```
(lldb) f
frame #0: 0x0000000100003f97 a.out`main at main.c:7:3
   4    int main() {
   5      uint32_t val=1234567890;
   6      printf("value=%d",val);
-> 7      return 0;
   8    }
(lldb) p &val
(uint32_t *) $3 = 0x00007ff7bfefee18
(lldb) memory read --format hex --size 1 --num-per-line 1 --count 4 0x00007ff7bfefee18
0x7ff7bfefee18: 0xd2
0x7ff7bfefee19: 0x02
0x7ff7bfefee1a: 0x96
0x7ff7bfefee1b: 0x49
```

Önce 1234567890 değerinin bellekte adresini bulduk, ardından bu adresten başlayarak her satırda tek bir byte gösterecek şekilde 4 byte göstermesini istedik.
Little endian bir sistem olduğu için düşük bellek adresine `0x7ff7bfefee18` sayının en son byte değeri `0xd2`, yüksek bellek adresine `0x7ff7bfefee1b` ise en büyük `0x49`
değerini koydu.

### Big Endian Sistemde Bellek

Kodun Big Endian sistemde nasıl belleğe yerleştiğini görmek için en güzel
yöntem tahmin edebileceğiniz gibi biraz teorinin dışına çıkıp onu gerçekten bir
Big Endian sistemde derleyip test etmek Bunun için
[buradaki](https://courses.cs.washington.edu/courses/cse333/15wi/lec/ppc.html) adımları takip edip Qemu ile Big Endian bir Linux Debian ayağa kaldırabildim.

```
>lscpu
Architecture:          ppc
Byte Order:            Big Endian
CPU(s):                1
On-line CPU(s) list:   0
Thread(s) per core:    1
Core(s) per socket:    1
Socket(s):             1
Model:                 Power Macintosh
BogoMIPS:              33.21
L1d cache:             32K
L1i cache:             32K
```

Ayağa kalktıktan sonra Git, Gcc, Gdb gibi araçları tabi yüklemek gerekiyor
fakat eski bir sürüm olduğundan bunu yapmak için `/etc/apt/sources.list`
dosyasının içinde sadece `deb http://archive.debian.org/debian wheezy main`
satırını bırakırsanız bahsettiğim bütün paketleri yükleyebiliyorsunuz.

```
Breakpoint 1, main () at main.c:5
5	uint32_t val = 1234567890;
6	  return 0;
$1 = 1234567890
$2 = (uint32_t *) 0xbffffb58
0xbffffb58:	0x49
0xbffffb59:	0x96
0xbffffb5a:	0x02
0xbffffb5b:	0xd2
```

### Karşılaştırma

Debug oturumlarında incelediğimiz değerin belleğe yerleşimini karşılaştırdığımızda artık Endian defterini kapatabiliriz sanırım.

Little Endian
```
0x7ff7bfefee18: 0xd2
0x7ff7bfefee19: 0x02
0x7ff7bfefee1a: 0x96
0x7ff7bfefee1b: 0x49
```

Big Endian
```
0xbffffb58:	0x49
0xbffffb59:	0x96
0xbffffb5a:	0x02
0xbffffb5b:	0xd2
```

## Gerçek Dünyadan Bir Sorun

Bir süredir cryptography alanı ilgimi çekiyor, derinlemesine öğrenmenin en iyi
yolu önce temelleri öğrenmek sonra örnekle pekiştirmek olduğuna inandığım için
şifreleme algoritmalarından en yaygın olarak kullanılan AES algoritmasını
kütüphane olmadan C ile geliştirmek istedim. Merak edenler kaynak kodlarına [buradan](https://github.com/caltuntas/aes) erişebilir.

Algoritmanın [belirli](https://en.wikipedia.org/wiki/AES_key_schedule) genelde `word` tipinde verilerde işlemler yapıyor bu yüzden bazı aşamalarında `word->byte array` ya da `byte array->word`
dönüşümleri yapmanız gerekiyor.Aslında basit bir işlem ama acemice yazılan bir
dönüştürme fonksiyonu aşağıdaki gibi gözükebilir.

```
void convert_to_uint8_array(uint32_t word,uint8_t arr[4]) {
  uint8_t *ptr =(uint8_t*)&word;
  arr[0] = ptr[3];
  arr[1] = ptr[2];
  arr[2] = ptr[1];
  arr[3] = ptr[0];
}
```

Elimizde bir byte array var, 4 tanesi bir word olacağı için, bunu çevirmek için hedef veri tipi yani word olan
değişkenin adresini alıyoruz, ardından sırayla en büyük word bileşen değerini alıp en küçük array değerine atayıp devam ediyoruz.
Little endian sistemde bellekte nasıl durduğunu hatırlarsanız, neden 3,2,1,0 diye azalarak gittiğini anlayacaksınız.

Kodu böyle yazdık ve sonrasında kendi Little Endian sistemimizde test ettik diyelim.

```
aes > make test
gcc -g test-framework/unity.c aes.c test_aes.c -o test_aes.out
./test_aes.out
test_aes.c:283:test_rot_word:PASS
test_aes.c:284:test_sub_word:PASS
test_aes.c:285:test_rcon:PASS
test_aes.c:286:test_convert:PASS
test_aes.c:287:test_expand_key:PASS
test_aes.c:288:test_add_round_key:PASS
test_aes.c:289:test_sub_bytes:PASS
test_aes.c:290:test_inv_sub_bytes:PASS
test_aes.c:291:test_shift_rows:PASS
test_aes.c:292:test_inv_shift_rows:PASS
test_aes.c:293:test_mix_columns:PASS
test_aes.c:294:test_inv_mix_columns:PASS
test_aes.c:295:test_aes_enc:PASS
test_aes.c:296:test_add_round_key_10:PASS
test_aes.c:297:test_mul:PASS
test_aes.c:298:test_aes_dec:PASS

-----------------------
16 Tests 0 Failures 0 Ignored
OK
```

Bütün testler kendi sisteminizde geçti, peki aynı kodu Big Endian bir sistemde test ettiğimizde neler oluyor ona bakalım. Yukarıda oluşturduğumuz PowerPC sisteminde
aynı kodu test ettim sonuç aşağıdaki gibi oldu.

```
gcc -g -std=c99 test-framework/unity.c aes.c test_aes.c -o test_aes.out
./test_aes.out
test_aes.c:21:test_rot_word:FAIL: Expected 1338968380 Was -816890871
test_aes.c:29:test_sub_word:FAIL: Expected 32212106 Was -1971000575
test_aes.c:35:test_rcon:FAIL: Expected 15434890 Was -1954223359
test_aes.c:74:test_convert:FAIL: Element 0 Expected 0x09 Was 0x3C
test_aes.c:63:test_expand_key:FAIL: Element 0 Expected 0xA0 Was 0xFD
test_aes.c:288:test_add_round_key:PASS
test_aes.c:289:test_sub_bytes:PASS
test_aes.c:290:test_inv_sub_bytes:PASS
test_aes.c:291:test_shift_rows:PASS
test_aes.c:292:test_inv_shift_rows:PASS
test_aes.c:293:test_mix_columns:PASS
test_aes.c:294:test_inv_mix_columns:PASS
test_aes.c:196:test_aes_enc:FAIL: Element 0 Expected 0x39 Was 0x06
test_aes.c:296:test_add_round_key_10:PASS
test_aes.c:297:test_mul:PASS
test_aes.c:220:test_aes_dec:FAIL: Element 0 Expected 0x32 Was 0xCD

-----------------------
16 Tests 7 Failures 0 Ignored 
FAIL
```

Test sonuçlarına bakacak olursak, 7 tane case hata almış, ana algoritma da
çalışmamış. Çünkü en temel çevrim işlemi olduğundan bütün testler etkilenmiş
diyebiliriz.

## Çözüm

Peki yukarıdaki kodu Endian davranışından bağımsız olarak nasıl yazabiliriz? Alt seviye programlama ile uğraşan herkes 
bu ve benzeri bit hack işlemleri ile uğraşmıştır. Basit bir işlem olsa da, kafa karıştıran önemi bir noktası da var. 
Kodu aşağıdaki gibi yazıp iki sistemde de testleri çalıştırırsak bütün testlerin başarılı şekilde geçtiğini göreceksiniz.

```
void convert_to_uint8_array(uint32_t w,uint8_t arr[4]) {
  arr[0] = w >> 24;
  arr[1] = w >> 16;
  arr[2] = w >> 8;
  arr[3] = w >> 0;
}
```

Peki neden? Elimizde olan ilk değerimiz üzerinden gidelim `1234567890` sayısını ikili sisteme çevirince aşağıdaki gibi bir değer bulmuştuk.

```
01001001  10010110  00000010  11010010
```

İstediğimiz şey bu değerin her bir parçasını dizinin bir değerine atamak yani aşağıdakini yapmak.

``` 
arr[0]=0x49
arr[1]=0x96
arr[2]=0x02
arr[3]=0xd2
``` 

Bunu daha görünür kılmak için aşağıdaki gibi gösterelim.

```
arr[0]    arr[1]    arr[2]    arr[3]
--------  --------  --------  -------- 
01001001  10010110  00000010  11010010
--------  --------  --------  --------
0x49      0x96      0x02      0xd2
```

Yukarıdaki tabloya bakınca yapmamız gereken daha net görülebiliyor, elimizde 4 byte uzunluğundaki bir değerin her bir parçasını bir dizinin elamanına atıcaz,
eğer bu sayıyı `24` defa sağa kaydırırsak (sağa dediğime bakmayın önemli bir nokta var), ilk dizi elemanını elde etmiş oluruz.

```
w >> 24                        arr[0]
--------  --------  --------  --------     x         x         x
00000000  00000000  00000000  01001001  10010110  00000010  11010010
--------  --------  --------  --------
                                0x49      0x96      0x02      0xd2
                                
w >> 16                        arr[1]
--------  --------  --------  --------     x         x    
00000000  00000000  01001001  10010110  00000010  11010010
--------  --------  --------  --------
                      0x49      0x96      0x02      0xd2

w >> 8                         arr[2]
--------  --------  --------  --------     x     
00000000  01001001  10010110  00000010  11010010
--------  --------  --------  --------
            0x49      0x96      0x02      0xd2

w >> 0                         arr[3]
--------  --------  --------  --------
01001001  10010110  00000010  11010010
--------  --------  --------  --------
0x49      0x96      0x02      0xd2
```

Yukarıda görsel olarak bu bit kaydırma işlemlerinin nasıl çalıştığını gösterdim, şöyle bir sorunuz olursa bunu çok iyi anlayabilirim. Peki Little Endian ya da Big Endian sistemlerde
bellekte dizilim sırası farklı olduğuna göre, (sağdan sola, ya da soldan sağa) bu sağa kaydırma işlemi nasıl oluyor da her sistemde aynı çalışıyor? Aynı kafa karışıklığı bende de olmuştu, bu yüzden üstüne
basa basa buraya not alalım.


>> `>>,<<` gibi bit kaydırma işlemleri sayıları sağa ya da sola kaydırmaz,
çalıştığı işlemci mimarisine göre `>>` en küçük basamağın yerleştirildiği yöne
doğru kaydırır, `<<` ise en büyük basamağın yerleştirildiği yöne kaydırır.

Yani Big Endian sistemde en büyük basamak hangi tarafta ise o yöne, Little Endian sistemde hangi yönde ise o yöne kaydırma yapılır, özetle bit kaydırma operatörleri 
Endian bağımsız olarak çalışırlar.

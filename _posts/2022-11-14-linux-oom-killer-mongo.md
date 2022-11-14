---
layout: post
title: "Linux OOM Killer Son Kurban: MongoDB"
description: "Linux OOM Killer Son Kurban: MongoDB"
date: 2022-11-14T07:00:00-07:00
tags: linux mongodb
---

Linux sanal makina host üzerinde koşan Docker compose ya da swarm altyapısını kullanan bir projemiz var. 
Ürünün farklı modülleri farklı servisler altında container olarak çalışıyor. 
Veritabanı olarak kullandığımız **MongoDB** yine container olarak ayağa kalkıyor ve yaşamını sürdürüyor. 
Farklı deployment senaryolarından birinde MongoDB ve diğer servisler aynı docker node üzerinde çalışıyor.

### Problem

Geçenlerde ortamlarımızdan birinde **MongoDB** container'ın aniden durduğunu farkettik. Önce tabi logları kontrol
ettik fakat herhangi bir hata ya da uyarı logu gözükmüyordu. Problem tüm servisleri durdurup yeniden başlattığımızda 
birkaç gün çalışıp tekrar ediyordu. MongoDB üzerinde CPU/Memory/Loglar ve diğer değerler normal gözükmesine rağmen
tüm servisler çalışırkerken MongoDB duruyordu.

### Olay Yeri İnceleme

Docker loglarından birşey çıkmayınca Linux host ortamını incelemeye başladık. CPU/Memory değerlerini geçmişe 
dönük incelerken Monitoring aracımızda tam MongoDB'nin kapanmasına yakın zaman aralığında available/used memory değerlerinin
birleştiğini ve sonrasında MongoDB'nin kapandığını farkettik. Sorun aşağı yukarı belli olmuştu sorun sistemdeki 
mevcut belleğin tükenmesi nedeniyle kapanmasıydı fakat kapanmadan önce bile MongoDB Memory değerleri normal gözüküyordu. 

### Şüpheli ile İlk Temas

MongoDB bellek değerleri normal gözüktüğüne göre başka bir sebeple durduruluyordu. Bunun için yine monitoring sistemine
dönüp diğer servislerin ve host üzerindeki işlemlerin tükettiği değerleri kontrol ettik. O sırada herhangi bir işlem
fazla bellek tüketmiyordu fakat diğer bir docker container adı "large_memory" olsun, belleğin büyük çoğunluğunu tüketip
MongoDB'nin kapanmasına sebep oluyordu.

### Kanıtların Toplanması

Bütün belleği tüketen container ayakta kalırken neden sadece MongoDB kapanıyordu ve bunu kim tetikliyordu? 
Bunu tespit etmek için Linux host üzerinde kernel loglarını incelemeye başladık. **Dmesg** ile logları incelerken
ilgili zaman aralığına gittik ve aradığımız logu bulduk.

```
[2156113.520338] Out of memory: Kill process 24363 (mongod) score 52 or sacrifice child
[2156113.520726] Killed process 24363 (mongod), UID 999, total-vm:3079196kB, anon-rss:1292664kB, file-rss:0kB, shmem-rss:0kB
```

### Sebep

[Linux out of memory management](https://www.kernel.org/doc/gorman/html/understand/understand016.html) işlemcisi sistemi sürekli izleyip
bellek yetersizliği durumunda hesapladığı skora göre kendine bir kurban seçip bu işlemi sonlandırıyor. Kurbanın nasıl seçildiğine dair detayları
bağlantıdan ya da birçok farklı kaynaktan inceleyebilirsiniz fakat çok düz mantık en fazla kim bellek tüketiyorsa onu sonlandıralım mantığı ile çalışmıyor.
Sistemde eğer bellek yetersiz kaldıysa, o anda **oom_score** değerine göre en yüksek hangi işlem ise onu sonlandırıyor. Bu sebepten dolayı malesef veritabanımız
MongoDB işlemi **mongod** sonlanıyor, yani diğer container en fazla belleği tüketse bile, en fazla skora sahip olan **mongod** işlemi olduğu için o sonlanıyor.

### Olay Yeri Tatbikatı

Aynı senaryoyu test ortamında oluşturmak için kolları sıvadım. İlk olarak MongoDB'yi container olarak ayağa kaldırıp
sisteminde boşta olan bellek miktarını kontrol ettim. Aşağıdaki gibi bir resim ortaya çıktı

```
watch free -h
```

![free memory](./img/oom/free.png)

Ardından docker container içinde çalışan tüm işlemlerin **oom_score** değerlerini bulacak **oom.sh** aşağıdaki scripti hazırladım.

```
#!/bin/bash

printf "%-50s %8s %8s\n" "Image" "PID" "OOM_SCORE"
docker ps --format "{{.ID}} {{.Image}}" |
while read -r line; do
  id=$(echo "$line" | cut -d ' ' -f1)
  img=$(echo "$line" | cut -d ' ' -f2)
  topResult=$(docker top "$id" -o pid | grep -v "PID")

  for r in $topResult;
  do
    score=$(cat /proc/"$r"/oom_score)
    printf "%-50s %8s %8s\n" "$img" "$r" "$score"
  done
done | sort -k3 -n -r
```

Linux bir işlemin oom skorunu `/proc/pid/oom_score` altında tutuyor.
Yukarıdaki script çalıştığında o anda bulunan tüm docker containerlar içinde çalışan
tüm işlemleri azalan sıralı şekilde tüm container imajlarının adlarını ve yanlarında
OOM skor değerlerini yazacak.



Sıra geldi yük oluşturmaya yani bitene kadar bellek tüketmeye. **large_memory** container benzeri bir bellek kullanmak için aşağıdaki gibi
basit bir container oluşturdum. 

```
[host]#docker run --name large_memory -d -t bash
[host]#docker exec -it large_memory bash
[bash]for i in {1..12}; do cat /dev/zero | head -c 1000m | tail & done
```
![jobs](./img/oom/jobs.png)

Yukarıda container'ı interaktif modda ayağa kaldırıp **run** sonrasında kapanmasın diye ilk başta **-d -t** 
parametreleri ile çalıştırıyoruz. Ardından container içine girip **for** döngüsü ile her biri **1000MB** tüketecek
background job oluşturuyoruz.

```
cat /dev/zero | head -c 1000m | tail &
``` 

ile bellek tüketecek iş parçacığı oluşturuyoruz. Tail komutu son satıra gelene kadar tüm verileri belleğinde tuttuğu için
`cat /dev/zero` ile sürekli **null** gönderip `head -c 1000m` bunu 1000MB ile sınırlıyorum.

1000MB tüketen 12 tane işi özellikle oluşturdum çünkü bellekte 12GB civarı bir yer
var bunun hepsini tüketmek istiyorum. 1000MB olmasının sebebi ise, bu testi yaptığım anda **mongod** yaklaşık
1.3GB değer tüketiyordu, yük için oluşturduğum işlemler daha fazla bellek tüketirse OOM tarafından sonlandırılmasını istemiyorum.

### Tatbikat Bitiyor

Birkaç dakika sonra, oluşturduğumuz yeni container içindeki işler tüm belleği tüketiyor ve bellekte yer kalmıyor ve neredeyse MongoDB'nin 10 
katı bellek tüketiyor. 

![stats](./img/oom/stats.png)

Fakat  o sırada **oom.sh** scriptini çalıştırdığımızda aşağıda gördüğünüz gibi **mongod** en tepede yani bellek kalmadığında bir süre sonra sonlandırılacak işlem olarak gözüküyor.

![oom scores](./img/oom/oom_score.png)

Hemen sonrasında aynı gerçek ortamda yaşadığımız gibi test ortamında da MongoDB kapanıyor ve bekletiğimiz gibi kernel mesajlarında aynı uyarıyı alıyoruz.

![dmesg](./img/oom/dmesg.png)

### Sonuç

Senaryoyu test ortamında simule etmemizin mutluğunu yaşıyoruz. Gerçek ortamda
yaşadığımız problem,MongoDB ile alakalı olmamasına rağmen diğer bir container
içinde çok fazla küçük küçük **process** oluşturulup bunların toplamda fazla
bellek tüketmesi ve Linux OOM yönetimi tarafından sonlandırılmaya en uygun aday olarak **mongod** seçilip sonlandırılmasıydı.  

Bu sorunu kullandığımız bir kütüphane sebebiyle yaşadığımızı tespit ettik ve sorunu biraz farklı bir şekilde process'leri kendimiz
öldürerek aştık.

Bazen container içinde oluşan işlemler tamamen izole gibi düşünülse de, böyle bir durum yok. Aynı kernel üzerinde çalışıp 
aynı belleği paylaşıyorlar, dolayısıyla host işletim sistemi ile aradaki ilişkiyi iyi bilmek gerekiyor. Fırsat bulursam
host ile docker arasındaki ilişkiyi farklı açılardan değerlendirip buraya da yazmak istiyorum.

---
layout: post
title: "VMWare ESXi ve Linux Sunucu Arasındaki Disk Alanı Tutarsızlığı"
description: "VMWare ESXi ve Linux Sunucu Arasındaki Disk Alanı Tutarsızlığı"
date: 2025-04-06T07:00:00-07:00
tags: linux,vmware
---
 
Geçenlerde lab ortamında Linux sunucu üzerinde bir işlem yaparken, birden ilgili sunucuya erişimim kesildi.
SSH ile bağlandığım için sıradan bir bağlantı kopma sorunu olduğunu düşündürdü ama tekrar denediğimde de bağlantı kuramadım.

Linux sunucu sanallaştırma ortamı olarak VMWare ESXi üzerinde koştuğu için, ilk olarak orayı kontrol ettim ve hemen ilk girişte disk uyarısı
mesajı ile beni karşıladı, en azından az da olsa VMWare disk tarafından bir yer açıp Linux tarafına tekrar erişip disk dolduysa orada büyük temizliği yaparım diye düşündüm.

VMWare ESXi sunucuya girip ilgili Linux sunucuya karşılık gelen sanal makinayı bulduktan sonra disk boyutunu kontrol ettiğimde aşağıdaki gibi bir sonuç ortaya çıkıyordu.

```
[root@esxi:/vmfs/volumes/7849317b-fa83-44b9-8924-0fedcd6ef784/linuxserver] ls -lah *.vmdk
-rw-------    1 root     root      750.0G Apr  6 13:43 linuxserver-flat.vmdk
-rw-------    1 root     root         534 Mar 26 13:26 linuxserver.vmdk
```

Burada kadar normal bir görüntü var, çünkü sunucu disk konfigürasyonu olarak [thin provisioning](https://en.wikipedia.org/wiki/Thin_provisioning) kullanılarak kuruldu, 750GB yer ayrıldı.
Yani mantıksal olarak 750GB yer ayrıldı ama fiziksel olarak bu yeri gerçekten kullanmadığı durumda daha az disk tüketecektir. Bunu da aşağıdaki gibi görebiliriz.

```
[root@esxi:/vmfs/volumes/7849317b-fa83-44b9-8924-0fedcd6ef784/linuxserver] du -sh *.vmdk
186.0G  linuxserver-flat.vmdk
0       linuxserver.vmdk
```

Yukarıdaki kullanıma bakarsanız mantıksal olarak 750GB yer kaplayan disk
aslında ESXi üzerinde fiziksel olarak 186GB yer kaplamış. Fakat Linux tarafına
biraz yer boşalttıktan sonra giriş yapıp disk kontrolü yaptığımda aşağıdaki
gibi bir sonuç ortaya çıktı.

```
root@linuxserver:~# df -h --total
Filesystem                            Size  Used Avail Use% Mounted on
tmpfs                                 2.4G  1.5M  2.4G   1% /run
/dev/mapper/ubuntu--vg-root           501G   16G  460G   4% /
tmpfs                                  12G     0   12G   0% /dev/shm
tmpfs                                 5.0M     0  5.0M   0% /run/lock
/dev/mapper/ubuntu--vg-tmp            4.9G  136K  4.6G   1% /tmp
/dev/sda2                             2.0G  245M  1.6G  14% /boot
/dev/mapper/ubuntu--vg-var            147G   16G  124G  12% /var
/dev/mapper/ubuntu--vg-home           4.9G  6.2M  4.6G   1% /home
/dev/mapper/ubuntu--vg-var_tmp        4.9G   64K  4.6G   1% /var/tmp
/dev/mapper/ubuntu--vg-var_log        4.9G  547M  4.1G  12% /var/log
/dev/mapper/ubuntu--vg-var_log_audit   30G  1.9G   27G   7% /var/log/audit
localhost:/volume1                    501G   67G  414G  14% /opt/app/data
tmpfs                                 2.4G  4.0K  2.4G   1% /run/user/0
total                                 1.2T  101G  1.1T   9% -
```

Son satıra dikkat ederseniz 186GB olarak ESXi sunucu üzerinde yer kaplayan Linux sunucu aslında yaklaşık 101GB disk tüketiyor. 
Linux sunucu `thin provisioning` olarak ayarlandığında, mesela büyük bir dosya oluşturdunuz ama sonrada o dosyayı Linux üzerinden `rm` ile sildiniz,
bu silme işlemi sonunda Linux işletim sistemi gerçek disk üzerinde tutulan fiziksel dosyayı değil, ona olan bağlantıyı yani `pointer` adresini ortadan kaldırıyor.

Aslında gerçek anlamda üzerine veri yazılmadığı sürece dosyanın verileri fiziksel disk üzerinde tutulmaya devam ediyor, ve bu çalışma mantığı dosya kurtarma araçlarının nasıl çalıştığını da özetlemiş oluyor. Durum böyle olunca VMWare ESXi için,
dışarıdan bakan bir göz olarak disk üzerinde hala veriler var ve provision edilmiş olarak görülüyor ve yer kaplamaya devam ediyor.

Bundan dolayı Linux ve diğer işletim sistemleri üzerinden genellikle veriler silindikten sonra ilgili verilerin diskten de silinmesi ya da sıfırlanması için
çeşitli araçlar bulunuyor. Bunlardan bir tanesi [zerofree](https://manpages.ubuntu.com/manpages/focal/man8/zerofree.8.html) aracı. Bunu bizim ortamda dosya sistemi olarak
`extfs` kullanıldığından dolayı kullanıyorum, farklı dosya sistemleri için farklı araçlar da bulunuyor.

Zerofree çalıştırmak için dosya sistemini `read-only` olarak mount etmeniz gerekiyor bunun için de `recovery` ya da `emergency` mode ile sistemi açıp ardından
şu şekilde işlemi başlatabilirsiniz.

```
root@linuxserver:~# echo "u" > /proc/sysrq-trigger
mount /dev/mapper/ubuntu-vg-root / -o remount,ro
zerofree -v /dev/mapper/ubuntu-vg-root
```

İlk satırda bulunan [SysRq](https://www.kernel.org/doc/html/v4.10/admin-guide/sysrq.html) dosyasını `u` parametresi ile tetikleyerek bütün diskleri read-only olarak tekrar mount etmesi gerektiğini söylüyoruz işletim sistemine.
Ardından `zerofree` ile disk üzerinden silinmiş fakat hala fiziksel disk üzerinde bulunan verileri sıfırlıyoruz. 

Bu işlem disk boyutuna göre uzun sürebiliyor, sonrasında VM hala kapalı iken ESXi üzerinden tekrar disk alanını kazanmak için aşağıdaki işlemi başlatıyoruz.

```
[root@esxi:/vmfs/volumes/7849317b-fa83-44b9-8924-0fedcd6ef784/linuxserver] vmkfstools -K linuxserver.vmdk
vmfsDisk: 1, rdmDisk: 0, blockSize: 1048576
Hole Punching: 19% done.
```

Bu işlem bittiğinde tekrar ESXi üzerinde kapladığı yeri kontrol ettiğinizde muhtemelen kapladığı yerin aşağıdaki gibi Linux sunucuda raporlanan yer ile oldukça yaklaştığını göreceksiniz.

```
[root@esxi:/vmfs/volumes/7849317b-fa83-44b9-8924-0fedcd6ef784/linuxserver] du -sh *.vmdk
102.0G  linuxserver-flat.vmdk
0       linuxserver.vmdk
```

## Zerofree Ne Yapıyor?

Şöyle bir [kaynak koduna](https://github.com/haggaie/zerofree/blob/master/zerofree.c) göz atmak istedim, aslında yukarıdaki bahsettiğim mantığın işletim sistemi fonksiyonlarını yapıyor diyebiliriz.

```
empty = (unsigned char *)malloc(fs->blocksize);
//...
//...
if ( !dryrun ) {
  if (!discard) {
    ret = io_channel_write_blk(fs->io, blk, 1, empty);
    if ( ret ) {
      fprintf(stderr, "%s: error while writing block\n", argv[0]);
      return 1;
    }
  } else 
  //...
  //...
}
```

Önce dosya sisteminin blok boyutuna göre sıfırlamak için kullanacağı `empty` verisini oluşturuyor. Ardından bir döngü içeresinde
yukarıdaki gibi `io_channel_write_blk` silinmiş ama diskte hala bulunan blokları sıfırlıyor.

## Sırada Ne Var?

Bu yaptığımız işlem aslında dosyalama sistemlerinin ve işletim sistemlerinin temellerinde olan bir konu. Genelde **hole punching** olarak isimlendiriliyor.
Konu ile çok yakından ilgili olan ve arka planda yatan kavram aslında [Sparse File](https://en.wikipedia.org/wiki/Sparse_file) ve bu konuyu Linux üzerinde daha detaylı olarak farklı bir yazıda inceleme niyetim var.

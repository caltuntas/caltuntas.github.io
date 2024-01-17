---
layout: post
title: "Core Dump Stack Analizi 2 - El İle Çözümleme"
description: "Core Dump Stack Analizi 2 - El İle Çözümleme"
mermaid: true
date: 2024-01-13T07:00:00-07:00
tags: musl linux assembly gdb unwinding
---

Tavşan deliğinde bir alt kata inmek zorunda kaldık, önümüzde tamamen farklı bir tünel var, ama çözmek için mecburen giriş yapmak zorundayız. 
Bu bölümde çözüm üretebilmemiz için maalesef `x86-64, assembly, call conventions` gibi alt seviye kavramları bilmemiz gerekiyor. 

Bu yazı serisi 3 bölümden oluşmaktadır, diğer bölümlere aşağıdaki linklerden ulaşılabilir. Yazı içeriğinde geçen kodlara
[bu adresten](https://gist.github.com/caltuntas/b84eda2937acfcfef2097a192a9d5995) ulaşabilirsiniz.



## Bölümler
1. [Sorunu Anlamak](https://www.cihataltuntas.com/2024/01/13/stack-unwinding-1.html)
2. El İle Çözümleme (Bu yazı)
3. [Otomasyon](https://www.cihataltuntas.com/2024/01/13/stack-unwinding-3.html)

## El İle Çözümleme
1. [Nedir Bu Epilogue ve Prologue? ](#epilogue-prologue)
2. [Caller ve Callee Saved Registers](#caller-ve-callee-saved-registers)
3. [Optimizasyon Etkisi](#optimizasyon-etkisi)
4. [Frame Pointer Olmadan Çözümle](#frame-olmadan)
    1. [setjmp Frame Analizi](#setjmp)
    2. [raise Frame Analizi](#raise)
    3. [abort Frame Analizi](#abort)

## Nedir Bu Epilogue ve Prologue? {#epilogue-prologue}

GDB üzerinden aynı core-dump dosyasını yükleyip aşağıdaki gibi `disassemble` komutunu çalıştırınca bize, aşağıdaki gibi `assembly` komutlarını gösteriyor. 
Aşağıya sadece `sub` ve `mul` fonksiyonlarını görebilirsiniz.

```
(gdb) disassemble sub
Dump of assembler code for function sub:
   0x000056227738f208 <+0>:     push   rbp
   0x000056227738f209 <+1>:     mov    rbp,rsp
   0x000056227738f20c <+4>:     sub    rsp,0x20
   0x000056227738f210 <+8>:     mov    DWORD PTR [rbp-0x14],edi
   ...
   ...
   0x000056227738f251 <+73>:    leave
   0x000056227738f252 <+74>:    ret
End of assembler dump.
(gdb) disassemble mul
Dump of assembler code for function mul:
   0x000056227738f1c5 <+0>:     push   rbp
   0x000056227738f1c6 <+1>:     mov    rbp,rsp
   0x000056227738f1c9 <+4>:     sub    rsp,0x10
   0x000056227738f1cd <+8>:     mov    DWORD PTR [rbp-0x4],edi
   ...
   ... 
   0x000056227738f206 <+65>:    leave
   0x000056227738f207 <+66>:    ret
```

Yukarıdaki iki fonksiyonun ilk ve son iki satırı dikkatinizi çekmiştir, satırlar aynı şekilde başlıyor.

```
push   rbp
mov    rbp,rsp
...
...
leave
ret
```

Basitçe açıklamak gerekirse, kodunuz içerisinde her fonksiyon çağrısı yapıldığında, stack üzerinde bir [Call Frame](https://en.wikipedia.org/wiki/Call_stack) oluşur.
Bunun amacı her fonksiyonun kendi içinde kullandığı lokal değişkenleri tutmak, çalıştıktan sonra da onu çağıran fonksiyon adresine 
geri dönmek olarak özetlenebilir. Yani her fonksiyon çağrısı için bir `stack/call frame` oluşur, bunu oluşturmak için de, yukarıdaki gibi 
ilk başta standart bir `prologue` kodu, fonksiyon bittiğinde de `epilogue` assembly kodu konularak bir önceki fonksiyona dönüş sağlanır.

Fonksiyon çağrıları devam ettikçe stack aşağıdaki gibi gözükür.

![Stack](/img/unwind/stack.png) 

Bu adreslerdeki değerlere bakınca aslında bir, stack çözümleme bağlı liste veri yapısı oluşturmak kadar kolay. Her stack çerçevesi için
`rbp` değerini bul, sonra geriye doğru bunları birleştir ve çözümlemeyi bitir. 

## Caller ve Callee Saved Registers

Stack çözümleme yaparken x86-64 mimarisinde kullanılan çağrı standartlarını da bilmek gerekiyor. CPU üzerinde değerleri tutabileceğimiz sınırlı
sayıda `register` bulunuyor. Haliyle, bir fonksiyon içinde işlem yaparken bazı register değerleri kullanıldıktan sonra başka bir fonksiyon çağrılabilir.
Bu aşamada diğer fonksiyonun, ezebileceği ve kendi istediği gibi kullanabileceği register isimleri olduğu var. Ayrıca sizin değerlerini ezmeden, önce
kaydedip daha sonra bu değerleri ilk değerlerine döndürmeniz gereken register değerleri de bulunuyor.

`Callee-saved` yani çağrılan fonksiyonun koruması gereken register isimleri aşağıdaki gibi. Daha detaylı bilgiyi [buradan](https://web.stanford.edu/class/archive/cs/cs107/cs107.1174/guide_x86-64.html) 
ulaşabilirsiniz.


| Register | Convention                   |
|----------|------------------------------|
| rsp      | Stack pointer, callee-saved  |
| rbx      | Local variable, callee-saved |
| rbp      | Local variable, callee-saved |
| r12      | Local variable, callee-saved |
| r13      | Local variable, callee-saved |
| r14      | Local variable, callee-saved |
| r15      | Local variable, callee-saved |

## Optimizasyon Etkisi

İşimiz bu kadar kolay demek isterdim ama değil, çünkü optimizasyonlar işin içine girdiğinde standart `prologue` ve `epilogue` düşündüğümüz
gibi olmuyor. Örnek olarak -O1 optimizasyonlarını açıp örnek kodumuz tekrar derleyelim ve neler değişiyor bakalım.

```
/tmp # gcc -Wall -O1 main.c -o main3


/tmp # gdb -q main3
Reading symbols from main3...
(gdb) disassemble sub
Dump of assembler code for function sub:
   0x00000000000011fe <+0>:     push   %rbp
   0x00000000000011ff <+1>:     push   %rbx
   0x0000000000001200 <+2>:     sub    $0x8,%rsp
   ...
   ...
   0x000000000000122f <+49>:    pop    %rbx
   0x0000000000001230 <+50>:    pop    %rbp
   0x0000000000001231 <+51>:    ret
End of assembler dump.
(gdb) disassemble mul
Dump of assembler code for function mul:
   0x00000000000011c5 <+0>:     push   %rbp
   0x00000000000011c6 <+1>:     push   %rbx
   0x00000000000011c7 <+2>:     sub    $0x8,%rsp
   ...
   ...
   0x00000000000011f6 <+49>:    pop    %rbx
   0x00000000000011f7 <+50>:    pop    %rbp
   0x00000000000011f8 <+51>:    ret
   0x00000000000011f9 <+52>:    call   0x1030 <abort@plt>
End of assembler dump.


(gdb) break sub
Breakpoint 1 at 0x11fe

(gdb) run 15
Starting program: /tmp/main3 15
Number: 15
Adding numbers: 3,7

Breakpoint 1, 0x00005555555551fe in sub ()
(gdb) p $rbp
$1 = (void *) 0x7
(gdb)
```

Yukarıda önce ilk seviye optimizasyonları açıp tekrar derledik, ardından kodu disassemble ettik. İlk ve son iki satırlardaki değişikliği fark ettiniz diye düşünüyorum.
Klasik `prologue` ve `epilogue` komutları artık yok, hatta `rbp` değerinde stack base adresi değil de, başka değer tutulduğunu göstermek için `sub` metoduna `breakpoint`
koyup tekrar çalıştırdım ve tutulan değerin `0x7` yani bizim, `main` içerisinde gönderdiğimiz parametrelerden birisi.  Optimizasyonlar olmadan normalde `stack frame` 
adresini tutmak için kullanılan `rbp`, artık fonksiyona geçilen parametre değerini tutmak için kullanılmış. Bu optimizasyonun adı `fomit-frame-pointer` olarak geçiyor, 
aşağıda da giriş seviye optimizasyonlar da bile `enable` edildiğini görebilirsiniz. 

```
/tmp # gcc -Q -O2 --help=optimizers | grep frame
  -fomit-frame-pointer                  [enabled]
```

Bu optimizasyonun ana sebebi aslında performans artışı, `rbp` boşa çıkıp, parametre geçme gibi diğer amaçlarla kullanıldığında hem elimizde ekstra bir `register` oluyor,
hem de prologue ve epilogue işlemlerinde rbp değerini stack üzerine kaydedip geri almak için oluşturulan makine komutları ortadan kalkıyor. 
Sonuç olarak sadece bu optimizasyon sayesinde ortalama %10-15 performans artışı sağladığı raporlanıyor.

## Frame Pointer Olmadan Çözümle {#frame-olmadan}

Elimizdeki `rbp` base stack frame adresini göstermediğinde stack frame ortadan kalkmıyor aslında. Tamam `rbp` baz alınarak kolayca
frame adresi bulanamaz ama frame yine orada, sadece bu sefer `rsp` değerine göre bu hesaplama yapılabilir. 

Çalışan kodun `assembly` komutlarını görebiliyoruz, bu komutlardan hangisinin `rsp` diğerlerini değiştirdiğini de `assembly` koduna bakarak hesaplayabiliriz.
Bu hesaplama sonrasında o fonksiyon içinde stack nereden başlar, bir önceki fonksiyon adresi nerededir diye bulabiliriz, çünkü bunlar hala stack üzerinde tutulan
değerler.

### setjmp Frame Analizi {#setjmp}

İlk olarak bu adımdan, yani core dump alındığında bellekte çalışan, en alttaki stack frame fonksiyonundan başlayalım. Bunu çözümledikten sonra, adım adım bir üstte bulunan fonksiyon
çağrılarına giderek devam edeceğiz. 

Aşağıdaki gibi GDB'yi başlatarak `disassemble` diyerek kodu gördük.

```
/tmp # gdb -q main -c core-main.1496.e28334d67f07.1705227527
Reading symbols from main...
[New LWP 1496]
Core was generated by `./main 15'.
Program terminated with signal SIGABRT, Aborted.
#0  0x00007f1f223f8d07 in setjmp () from /lib/ld-musl-x86_64.so.1
(gdb) disassemble
Dump of assembler code for function setjmp:
   0x00007fe04dc70c91 <+0>:     mov    %rbx,(%rdi)
   0x00007fe04dc70c94 <+3>:     mov    %rbp,0x8(%rdi)
   0x00007fe04dc70c98 <+7>:     mov    %r12,0x10(%rdi)
   0x00007fe04dc70c9c <+11>:    mov    %r13,0x18(%rdi)
   0x00007fe04dc70ca0 <+15>:    mov    %r14,0x20(%rdi)
   0x00007fe04dc70ca4 <+19>:    mov    %r15,0x28(%rdi)
   0x00007fe04dc70ca8 <+23>:    lea    0x8(%rsp),%rdx
   0x00007fe04dc70cad <+28>:    mov    %rdx,0x30(%rdi)
   0x00007fe04dc70cb1 <+32>:    mov    (%rsp),%rdx
   0x00007fe04dc70cb5 <+36>:    mov    %rdx,0x38(%rdi)
   0x00007fe04dc70cb9 <+40>:    xor    %eax,%eax
   0x00007fe04dc70cbb <+42>:    ret
   0x00007fe04dc70cbc <+43>:    mov    %rdi,%rdx
   0x00007fe04dc70cbf <+46>:    mov    $0x8,%r10d
   0x00007fe04dc70cc5 <+52>:    lea    0x4aafc(%rip),%rsi        # 0x7fe04dcbb7c8
   0x00007fe04dc70ccc <+59>:    xor    %edi,%edi
   0x00007fe04dc70cce <+61>:    mov    $0xe,%eax
   0x00007fe04dc70cd3 <+66>:    syscall
   0x00007fe04dc70cd5 <+68>:    ret
   0x00007fe04dc70cd6 <+69>:    mov    %rdi,%rdx
   0x00007fe04dc70cd9 <+72>:    mov    $0x8,%r10d
   0x00007fe04dc70cdf <+78>:    lea    0x4aada(%rip),%rsi        # 0x7fe04dcbb7c0
   0x00007fe04dc70ce6 <+85>:    xor    %edi,%edi
   0x00007fe04dc70ce8 <+87>:    mov    $0xe,%eax
   0x00007fe04dc70ced <+92>:    syscall
   0x00007fe04dc70cef <+94>:    ret
   0x00007fe04dc70cf0 <+95>:    mov    %rdi,%rsi
   0x00007fe04dc70cf3 <+98>:    mov    $0x8,%r10d
   0x00007fe04dc70cf9 <+104>:   mov    $0xe,%eax
   0x00007fe04dc70cfe <+109>:   xor    %edx,%edx
   0x00007fe04dc70d00 <+111>:   mov    $0x2,%edi
   0x00007fe04dc70d05 <+116>:   syscall
=> 0x00007fe04dc70d07 <+118>:   ret
End of assembler dump.
```
 
Yukarıdaki kodu biraz incelersek, `rsp` değerini değiştiren `push,pop,add,sub` gibi assembly komutları bulunmuyor.
Bu da bize şunu gösteriyor, bu fonksiyon `call` ile çağrıldığına göre, bir önceki fonksiyon adresi stack üzerinde bulunuyor. Call
çağrısının aslında şu şekilde uzun olarak yazılabileceğini düşünebiliriz.

```
push return_address
jmp function_address
```

Yani `call` yaptığında bizim bir önceki fonksiyonda kaldığımız yer, stack içine `push` ile kaydedildi. Ondan sonra da stack değerini değiştiren bir
komut olmadığına göre demek ki bizim bir önceki fonksiyonun adresi şimdiki `rsp` değerinin gösterdiği adres değeri diyebiliriz. 
Ayrıca bir önceki fonksiyonda en son `rsp` değerini de, `rsp+8` olarak hesaplayabiliriz. GDB üzerinde yapalım işlemi ve sonuca bakalım. 

```
(gdb) info symbol *(void**)$rsp
raise + 64 in section .text of /lib/ld-musl-x86_64.so.1
```

Yukarıdaki komutlar ile stack üzerinde `rsp` gösterdiği yerin fonksiyon bilgisini aldık, ve `raise + 64` olduğunu öğrendik.
Return address değerimiz belirlendi, diğer değer stack frame adresini de, yukarıda konuştuk. Kodlar içinde stack pointer değerini
değiştiren bir şey olmadığından stack frame adresimiz `rsp` ile aynı. Çözümleme sonuçları aşağıdaki gibi oldu.


| No | Function   | Caller Return Address       | Caller Stack Pointer |
| -- | ---------- | ---------------             | ---------------      |
| 0  | setjmp     | \*(void\*\*)(rsp)           | rsp+8                |


### raise Frame Analizi {#raise}

İlk frame içinde, bir önceki bizi çağıran fonksiyonun `raise` olduğunu bulmuştuk. Şimdi bu fonksiyonu inceleyelim
ve stack frame adresini bulmaya çalışalım.

```
(gdb) disassemble raise
Dump of assembler code for function raise:
   0x00007fe04dc70e1c <+0>:     push   %rbp
   0x00007fe04dc70e1d <+1>:     push   %rbx
   0x00007fe04dc70e1e <+2>:     mov    %edi,%ebx
   0x00007fe04dc70e20 <+4>:     sub    $0x88,%rsp
   0x00007fe04dc70e27 <+11>:    mov    %rsp,%rbp
   0x00007fe04dc70e2a <+14>:    mov    %rbp,%rdi
   0x00007fe04dc70e2d <+17>:    call   0x7fe04dc70cd6 <setjmp+69>
   0x00007fe04dc70e32 <+22>:    movslq %ebx,%rsi
   0x00007fe04dc70e35 <+25>:    mov    %fs:0x0,%rax
   0x00007fe04dc70e3e <+34>:    movslq 0x30(%rax),%rdi
   0x00007fe04dc70e42 <+38>:    mov    $0xc8,%eax
   0x00007fe04dc70e47 <+43>:    syscall
   0x00007fe04dc70e49 <+45>:    mov    %rax,%rdi
   0x00007fe04dc70e4c <+48>:    call   0x7fe04dc45e45 <fetestexcept+6160>
   0x00007fe04dc70e51 <+53>:    mov    %rbp,%rdi
   0x00007fe04dc70e54 <+56>:    mov    %rax,%rbx
   0x00007fe04dc70e57 <+59>:    call   0x7fe04dc70cf0 <setjmp+95>
=> 0x00007fe04dc70e5c <+64>:    add    $0x88,%rsp
   0x00007fe04dc70e63 <+71>:    mov    %ebx,%eax
   0x00007fe04dc70e65 <+73>:    pop    %rbx
   0x00007fe04dc70e66 <+74>:    pop    %rbp
   0x00007fe04dc70e67 <+75>:    ret
End of assembler dump.
```

Yukarıdaki koda baktığımızda, stack değerini değiştiren `push,sub` gibi komutlar bulunuyor. Stack yüksek bellek adresinden
başlayıp, düşük bellek adresine doğru genişler. `sub` gibi komutlar ise, o stack frame içinde lokal değişkenlere yer açar.
İlk olarak 2 adet `push` işlemi yapılmış, sonra gördüğünüz gibi `0x88` boyutunda yer açılmış

```
(gdb) info symbol *(void**)($rsp+0x88+16)
abort + 14 in section .text of /lib/ld-musl-x86_64.so.1
```

Ayrıca optimize edilmiş bir kod olduğu için, ilk gördüğünüz push rbp, stack base pointer değerini kaydetmiyor. Fonksiyona 
parametre olarak geçilen argümanı kaydettiği için, o değeri stack base pointer değeri olarak alamıyoruz ve bu hesaplamaları kendimiz yapıyoruz.
Bu hesaplamadan sonra tablomuz aşağıdaki gibi oldu. 

| No | Function   | Caller Return Address       | Caller Stack Pointer |
| -- | ---------- | ---------------             | ---------------      |
| 0  | setjmp     | \*(void\*\*)(rsp)           | rsp+8                |
| 1  | raise      | \*(void\*\*)(rsp+0x88+16)   | rsp+0x88+16+8        |

### abort Frame Analizi {#abort}

Bir önceki adımda `raise` fonksiyonunu çağıran fonksiyonun `abort` olduğunu belirlemiştik, şimdi abort için stack nerede başlar nerede biter ve onu çağıran fonksiyonun
frame değerlerini çıkaralım.

```
(gdb) disassemble abort
Dump of assembler code for function abort:
   0x00007fe04dc43f9a <+0>:     sub    $0x38,%rsp
   0x00007fe04dc43f9e <+4>:     mov    $0x6,%edi
   0x00007fe04dc43fa3 <+9>:     call   0x7fe04dc70e1c <raise>
   0x00007fe04dc43fa8 <+14>:    xor    %edi,%edi
   0x00007fe04dc43faa <+16>:    call   0x7fe04dc70cbc <setjmp+43>
   0x00007fe04dc43faf <+21>:    lea    0x7e006(%rip),%rdi        # 0x7fe04dcc1fbc
   0x00007fe04dc43fb6 <+28>:    call   0x7fe04dc7c51f
   0x00007fe04dc43fbb <+33>:    mov    $0x8,%edx
   0x00007fe04dc43fc0 <+38>:    xor    %eax,%eax
   0x00007fe04dc43fc2 <+40>:    lea    0x10(%rsp),%rdi
   0x00007fe04dc43fc7 <+45>:    mov    %rdx,%rcx
   0x00007fe04dc43fca <+48>:    mov    $0x6,%r8d
   0x00007fe04dc43fd0 <+54>:    lea    0x10(%rsp),%rsi
   0x00007fe04dc43fd5 <+59>:    mov    $0x8,%r10d
   0x00007fe04dc43fdb <+65>:    rep stos %eax,%es:(%rdi)
   0x00007fe04dc43fdd <+67>:    mov    $0xd,%eax
   0x00007fe04dc43fe2 <+72>:    mov    %r8,%rdi
   0x00007fe04dc43fe5 <+75>:    mov    %rcx,%rdx
   0x00007fe04dc43fe8 <+78>:    syscall
   0x00007fe04dc43fea <+80>:    mov    %fs:0x0,%rax
   0x00007fe04dc43ff3 <+89>:    mov    %r8,%rsi
   0x00007fe04dc43ff6 <+92>:    movslq 0x30(%rax),%rdi
   0x00007fe04dc43ffa <+96>:    mov    $0xc8,%eax
   0x00007fe04dc43fff <+101>:   syscall
   0x00007fe04dc44001 <+103>:   mov    $0xe,%eax
   0x00007fe04dc44006 <+108>:   lea    0x8(%rsp),%rsi
   0x00007fe04dc4400b <+113>:   mov    $0x1,%edi
   0x00007fe04dc44010 <+118>:   movq   $0x20,0x8(%rsp)
   0x00007fe04dc44019 <+127>:   syscall
   0x00007fe04dc4401b <+129>:   hlt
   0x00007fe04dc4401c <+130>:   mov    $0x9,%edi
   0x00007fe04dc44021 <+135>:   call   0x7fe04dc70e1c <raise>
   0x00007fe04dc44026 <+140>:   mov    $0x7f,%edi
   0x00007fe04dc4402b <+145>:   call   0x7fe04dc43f84 <_Exit>
End of assembler dump.
```

`abort` metodunu incelediğimizde, stack üzerinde `0x38` kadar yer açmış, bunun dışında başka bir şey koymamış. Buna bakarak
bir önceki bizi çağıran fonksiyonun adresi, `rsp+0x38` adresinde diyebiliriz. Tabi bu değeri raise içinden hesaplayabiliriz, çünkü GDB
abort fonksiyonunu geçerli bir frame olarak görmediği için şöyle yapmamız gerekecek.

```
(gdb) frame 1
#1  0x00007fe04dc70e5c in raise () from /lib/ld-musl-x86_64.so.1
(gdb) info symbol *(void**)($rsp+0x88+16+8+0x38)
mul + 58 in section .text of /tmp/main
```

`rsp+0x88+16` bu değer zaten raise içinde abort fonksiyonun dönüş adres değeriydi, onun üzerine `+8` eklediğimizde `abort` içinde kaydedilmiş son `rsp` değerini bulduk
sonra da `abort` içinde `sub    $0x38,%rsp` komutundan dolayı `0x38` ekledik. Bu da bize bir önce bizi çağıran fonksiyonun adını `mul` olarak gösterdi. 
Tablomuzun son hali aşağıdaki gibi oldu.

| No | Function   | Caller Return Address       | Caller Stack Pointer |
| -- | ---------- | ---------------             | ---------------      |
| 0  | setjmp     | \*(void\*\*)(rsp)           | rsp                  |
| 1  | raise      | \*(void\*\*)(rsp+0x88+16)   | rsp+0x88+16+8        |
| 2  | abort      | \*(void\*\*)(rsp+0x38)      | rsp+0x38+8           |


Bu aşamadan sonra devam edip, kendi yazdığımız kodun fonksiyonlarına kadar çıkmak mümkün açıkçası. Ama GDB bundan sonra sorunlu yeri geçtikten sonra 
diğer stack frame bilgilerini kendisi çıkarabiliyor.
Bunu sürekli el ile yapmak tabi mümkün değil ama otomasyon haline getirmek için adım adım nasıl yapıldığını bilmek gerekiyordu.
Şimdi bir sonra ki bölümde bunu nasıl otomasyon haline getirebiliriz onu inceleyelim.  

#### Referanslar
- [Deep Wizardry: Stack Unwinding](https://blog.reverberate.org/2013/05/deep-wizardry-stack-unwinding.html)
- [Debugging in GDB: Create custom stack winders](https://developers.redhat.com/articles/2023/06/19/debugging-gdb-create-custom-stack-winders#)
- [Unwinding the stack the hard way](https://lesenechal.fr/en/linux/unwinding-the-stack-the-hard-way)
- [Getting the call stack without a frame pointer](https://yosefk.com/blog/getting-the-call-stack-without-a-frame-pointer.html)

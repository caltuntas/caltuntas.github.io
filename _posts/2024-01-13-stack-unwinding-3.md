---
layout: post
title: "Core Dump Stack Analizi 3 - Otomasyon"
description: "Core Dump Stack Analizi 3 - Otomasyon"
mermaid: true
date: 2024-01-13T07:00:00-07:00
tags: musl linux assembly gdb unwinding
---

Bu bölüme gelene kadar, sorunun ne olduğunu ve el yordamıyla da olsa nasıl çözebileceğimizi anlamıştık. Bu aşamadan sonra 
yaptığımız çözümlemeyi tekrar kullanılabilir hale getirmek için bir GDB eklentisi yazalım. Aksi durumda, böyle durumlarda sürekli assembly kodu üzerinden
stack adresi hesaplayıp frame çıkarmak, zihinsel sağlık açısından pek de faydalı olmayabilir. 

Bu yazı serisi 3 bölümden oluşmaktadır, diğer bölümlere aşağıdaki linklerden ulaşılabilir. Yazı içeriğinde geçen kodlara
[bu adresten](https://gist.github.com/caltuntas/b84eda2937acfcfef2097a192a9d5995) ulaşabilirsiniz.

## Bölümler
1. [Sorunu Anlamak](https://www.cihataltuntas.com/2024/01/13/stack-unwinding-1.html)
2. [El İle Çözümleme](https://www.cihataltuntas.com/2024/01/13/stack-unwinding-2.html)
3. Otomasyon (Bu yazı)

## Otomasyon
1. [Gdb Otomasyon Seçenekleri](#gdb-otomasyon)
2. [Musl Unwinder](#musl-unwinder)
3. [Test](#test)
4. [Kapanış](#kapanis)

## Gdb Otomasyon Seçenekleri {#gdb-otomasyon}

GDB bu tarz otomasyon gerektiren durumlar için `batch mode` ya da `GDB Script` denilen basit bir betik dil seçeneği sunuyor.
Ama daha önce `Python` desteği sunduğunu bilmiyordum. Oldukça gelişmiş bir [API](https://sourceware.org/gdb/current/onlinedocs/gdb.html/Python-API.html) desteği sunuyor.
Bunun sayesinde biz de debug sembolleri olmayan `musl-libc` stack frame çözümlemesi yapan bir eklenti yazalım.

## Musl Unwinder

Yazdığım eklenti aslında, bir önceki bölümde anlattığım adımları otomatik yapıyor, yani önce şuanda çalışan
kodun `musl` kütüphanesine ait bir frame olup olmadığı kontrol ediliyor. Eğer evet ise `disassemble` ediyor, 
kodun içinde geçen `push,sub` gibi değerleri sayıp stack frame içinde ne kadar yer açılmış onu buluyor. 
Bunu bulduktan sonra zaten bir önceki fonksiyonun `return address` değerine ulaşmış oluyoruz. 


```python
import re
import gdb
from gdb.unwinder import Unwinder


def debug(pc, current_rsp, offset, addr, frame_id, func):
    print('=============debug===========')
    print('{:<20}:{:<8}'.format('function',func))
    print('{:<20}:{:<8}'.format('pc', str(pc)))
    print('{:<20}:{:<8}'.format('current_rsp', str(current_rsp)))
    print('{:<20}:{:<8}'.format('offset', str(offset)))
    print('{:<20}:{:<8}'.format('return address', hex(addr)))
    print('{:<20}:{:<8}'.format('frame_id', str(frame_id)))

u64_ptr = gdb.lookup_type('unsigned long long').pointer()

class FrameID:
    def __init__(self, sp, pc):
        self.sp = sp
        self.pc = pc

    def __str__(self):
        return f'sp: {self.sp}, pc: {self.pc}'

class MuslUnwinder(Unwinder):
    def __init__(self):
        super().__init__("musl_unwinder")

    def is_musl_frame(self,pc):
        obj = gdb.execute("info symbol 0x%x" % pc, False, True)
        return "musl" in obj

    def dereference(self,adr):
        deref = gdb.parse_and_eval("0x%x" % adr).cast(u64_ptr).dereference()
        return deref

    def __call__(self, pending_frame):
        frame = pending_frame.level()
        pc = pending_frame.read_register("pc")
        if not self.is_musl_frame(pc):
            return None
        asm = gdb.execute("disassemble 0x%x" % pc, False, True)
        lines = asm.splitlines()
        func = None
        args_bytes = 0
        locals_bytes = 0
        rbp_bytes = 0

        for line in lines:
            m = re.match('Dump of assembler code for function (.*):', line)
            if m:
                func = m.group(1)
            elif re.match('.*push[ ]*%', line):
                args_bytes += 8 
                if "rbp" in line:
                    rbp_bytes += 8
            elif m := re.match('.*sub[ ]*\\$0x([A-Fa-f0-9]+),%rsp', line):
                locals_bytes = int(m.group(1), 16)
                break

        offset = locals_bytes + args_bytes
        current_rsp = pending_frame.read_register("rsp")
        current_rbp = pending_frame.read_register("rbp")
        rsp = current_rsp + offset + 8
        return_addr = self.dereference(current_rsp + offset)
        frame_id = FrameID(rsp, pc)

        unwind_info = pending_frame.create_unwind_info(frame_id)
        unwind_info.add_saved_register("rsp", rsp)
        unwind_info.add_saved_register("rip", return_addr)

        if rbp_bytes > 0:
            saved_rbp = self.dereference(current_rsp+locals_bytes+rbp_bytes)
            unwind_info.add_saved_register("rbp", saved_rbp)
        else:
            unwind_info.add_saved_register("rbp", current_rbp)

        if gdb.parameter("verbose"):
            debug(pc, current_rsp, offset, return_addr, frame_id, func)

        return unwind_info

gdb.execute('set disassembly-flavor att')
gdb.unwinder.register_unwinder(None, MuslUnwinder(), replace=True)
gdb.invalidate_cached_frames()
```
Hatırlarsanız `Caller ve Callee Saved Registers` başlığı altında bazı register
değerlerinin çağrılan fonksiyon tarafından korunması ve eski haline geri
döndürülmesi gerektiğini söylemiştik. Eğer kodun içinde `rbp`
değeri stack üzerine kaydedildiyse, onu da önceki frame için
`add_saved_register` olarak kaydediyoruz. Bunu eklemediğim zaman çözümleme bazı üst stack frame çözümlemeleri hata verebiliyor. 

Diğer kaydedilmesi gereken register değerleri için bir şey
yapmadım, muhtemelen bu kod başka bir kütüphane için kullanılırsa, eklemek ya da değiştirmek gerekebilir.

## Test

Evet artık sona doğru yaklaşıyoruz, yukarıdaki kodu `muslunwinder.py` olarak kaydetmiştim. 
Eski core dump dosyasını tekrar açıyorum, önce `unwinder` olmadan `backtrace` almaya çalıştım.

```
/tmp # gdb -q main -c core-main.2041.e28334d67f07.1705390818
Reading symbols from main...
[New LWP 2041]
Core was generated by `./main 15'.
Program terminated with signal SIGABRT, Aborted.
#0  0x00007fe04dc70d07 in setjmp () from /lib/ld-musl-x86_64.so.1
(gdb) bt
#0  0x00007fe04dc70d07 in setjmp () from /lib/ld-musl-x86_64.so.1
#1  0x00007fe04dc70e5c in raise () from /lib/ld-musl-x86_64.so.1
#2  0x0000003000000008 in ?? ()
#3  0x00007ffc5622a1b0 in ?? ()
#4  0x00007ffc5622a0f0 in ?? ()
#5  0x00007ffc5622a220 in ?? ()
#6  0x0000000000000005 in ?? ()
#7  0x0000000000000002 in ?? ()
#8  0x0000000000000000 in ?? ()
```

Şimdi eklentiyi yükleyip tekrar deneyelim. 

```
(gdb) source muslunwinder.py
(gdb) bt
#0  0x00007fe04dc70d07 in setjmp () from /lib/ld-musl-x86_64.so.1
#1  0x00007fe04dc70e5c in raise () from /lib/ld-musl-x86_64.so.1
#2  0x00007fe04dc43fa8 in abort () from /lib/ld-musl-x86_64.so.1
#3  0x000055904dae41ff in mul ()
#4  0x000055904dae4251 in sub ()
#5  0x000055904dae429e in add ()
#6  0x000055904dae42f3 in main ()
```

Şimdi bir de, kendi yazdığımız kod değil, ilk bölümde bahsettiğim __NodeJS__ dump dosyası üzerinde deneyelim.

```
/tmp # gdb /usr/local/bin/node -c core.f8f32091796c.node.1700129772.28 -q
Reading symbols from /usr/local/bin/node...
[New LWP 28]
[New LWP 30]
[New LWP 29]
[New LWP 33]
[New LWP 31]
[New LWP 32]
[New LWP 34]
Core was generated by `/usr/local/bin/node template.js'.
Program terminated with signal SIGABRT, Aborted.
#0  0x00007fa1a8f5a3f2 in setjmp () from /lib/ld-musl-x86_64.so.1
[Current thread is 1 (LWP 28)]
(gdb) bt
#0  0x00007fa1a8f5a3f2 in setjmp () from /lib/ld-musl-x86_64.so.1
#1  0x00007fa1a8f5a54d in raise () from /lib/ld-musl-x86_64.so.1
#2  0x00007fa1a8f5b9a9 in ?? () from /lib/ld-musl-x86_64.so.1
#3  0x00007fa1a8faae98 in ?? () from /lib/ld-musl-x86_64.so.1
#4  0x0000000000000000 in ?? ()


(gdb) source muslunwinder.py
(gdb) bt
#0  0x00007fa1a8f5a3f2 in setjmp () from /lib/ld-musl-x86_64.so.1
#1  0x00007fa1a8f5a54d in raise () from /lib/ld-musl-x86_64.so.1
#2  0x00007fa1a8f30f25 in abort () from /lib/ld-musl-x86_64.so.1
#3  0x00005641a6ef5e55 in node::Abort() ()
#4  0x00005641a6e00d27 in node::OnFatalError(char const*, char const*) ()
#5  0x00005641a70ed0e2 in v8::Utils::ReportOOMFailure(v8::internal::Isolate*, char const*, bool) ()
#6  0x00005641a70ed46f in v8::internal::V8::FatalProcessOutOfMemory(v8::internal::Isolate*, char const*, bool) ()
#7  0x00005641a72bf365 in v8::internal::Heap::FatalProcessOutOfMemory(char const*) ()
...
...
```

## Kapanış {#kapanis}

Evet gizemli `??` işaretleri yerine artık anlamlı fonksiyon isimleri görebiliyoruz, hem de debug sembollerini yüklemeden.
Tavşan deliğinde tünelin ucundaki ışık gözüktü. Bol hesaplamalı, saç baş yolmalı bir, yolculuk olsa da benim için oldukça 
eğlenceli ve öğretici oldu diyebilirim. 


#### Referanslar
- [Deep Wizardry: Stack Unwinding](https://blog.reverberate.org/2013/05/deep-wizardry-stack-unwinding.html)
- [Debugging in GDB: Create custom stack winders](https://developers.redhat.com/articles/2023/06/19/debugging-gdb-create-custom-stack-winders#)
- [Unwinding the stack the hard way](https://lesenechal.fr/en/linux/unwinding-the-stack-the-hard-way)
- [Getting the call stack without a frame pointer](https://yosefk.com/blog/getting-the-call-stack-without-a-frame-pointer.html)

---
layout: post
title: "Syslog Priority Matrix"
description: "Details of syslog message format and how to interpret syslog messages"
date: 2019-05-11T07:00:00-07:00
tags: syslog
---

TNBT (The next big thing) projemiz için çalışırken syslog mesajlarını parse etme ihtiyacı doğdu. Syslog mesajları UDP üzerinden default olarak 514 portu ile gönderiliyor ve gönderilen mesaj içeriğinde “Priority” alanı bulunuyor. Bu alandan gönderilen mesajın log seviyesini ve tipini bulmak için biraz protokolü araştırdım. Aslında oldukça basit bir protokol ve gönderilen “Priority” alanı genelde mesajın ilk kısmında “<44>” gibi bulunuyor. Burada 44 Priority oluyor ve onun hangi log seviyesi ve tipine karşılık geldiğini aşağıdaki matristen çıkabiliyorsunuz.

Protokolün detayına aşağıdan ulaşabilirsiniz

[RFC-5224](https://datatracker.ietf.org/doc/html/rfc5424#section-6.2.1)

Protokol detayını incelediğinizde görebileceğiniz gibi çeşitli loglama sistemlerinde yaygın olan aşağıdaki “severity” seviyeleri var.

| Numerical Code | Severity                                 |
| -------------- | ---------------------------------------- |
| 0              | Emergency: system is unusable            | 
| 1              | Alert: action must be taken immediately  |
| 2              | Critical: critical conditions            |
| 3              | Error: error conditions                  |
| 4              | Warning: warning conditions              |
| 5              | Notice: normal but significant condition |
| 6              | Informational: informational messages    |
| 7              | Debug: debug-level messages              |


Birde log mesajının tipini belirten facility seviyeleri bulunuyor.


| Numerical Code | Facility                                 |
| -------------- | ---------------------------------------- |
| 0              | kernel messages                          |
| 1              | user-level messages                      |
| 2              | mail system                              |
| 3              | system daemons                           |
| 4              | security/authorization messages          |
| 5              | messages generated internally by syslogd |
| 6              | line printer subsystem                   |
| 7              | network news subsystem                   |
| 8              | uUCP subsystem                           |
| 9              | clock daemon                             |
| 10             | security/authorization messages          |
| 11             | fTP daemon                               |
| 12             | nTP subsystem                            |
| 13             | log audit                                |
| 14             | log alert                                |
| 15             | clock daemon (note 2)                    |
| 16             | local use 0  (local0)                    |
| 17             | local use 1  (local1)                    |
| 18             | local use 2  (local2)                    |
| 19             | local use 3  (local3)                    |
| 20             | local use 4  (local4)                    |
| 21             | local use 5  (local5)                    |
| 22             | local use 6  (local6)                    |
| 23             | local use 7  (local7)                    |


![](/img/syslogpriority/syslog.png)

Yukarıda bahsedildiği gibi

```
Priority = Facility * 8 + Severity
``` 
şeklinde bulunuyor.

Bu formüle göre tüm matrisi hesaplarsak aşağıdaki gibi bir matris ortaya çıkıyor.

|            | emergency |    alert | critical|  error  | warning |  notice | info  |  debug |
| ---------- | --------- | -------- | ------- | ------- | ------- | ------- | ----- | ------ |
| kernel     |         0 |      1   |       2 |      3  |       4 |       5 |     6 |      7 |
| user       |         8 |      9   |      10 |     11  |      12 |      13 |    14 |     15 |
| mail       |        16 |     17   |      18 |     19  |      20 |      21 |    22 |     23 |
| system     |        24 |     25   |      26 |     27  |      28 |      29 |    30 |     31 |
| security   |        32 |     33   |      34 |     35  |      36 |      37 |    38 |     39 |
| syslog     |        40 |     41   |      42 |     43  |      44 |      45 |    46 |     47 |
| lpd        |        48 |     49   |      50 |     51  |      52 |      53 |    54 |     55 |
| nntp       |        56 |     57   |      58 |     59  |      60 |      61 |    62 |     63 |
| uucp       |        64 |     65   |      66 |     67  |      68 |      69 |    70 |     71 |
| time       |        72 |     73   |      74 |     75  |      76 |      77 |    78 |     79 |
| security   |        80 |     81   |      82 |     83  |      84 |      85 |    86 |     87 |
| ftpd       |        88 |     89   |      90 |     91  |      92 |      93 |    94 |     95 |
| ntpd       |        96 |     97   |      98 |     99  |     100 |     101 |   102 |    103 |
| logaudit   |       104 |    105   |     106 |    107  |     108 |     109 |   110 |    111 |
| logalert   |       112 |    113   |     114 |    115  |     116 |     117 |   118 |    119 |
| clock      |       120 |    121   |     122 |    123  |     124 |     125 |   126 |    127 |
| local0     |       128 |    129   |     130 |    131  |     132 |     133 |   134 |    135 |
| local1     |       136 |    137   |     138 |    139  |     140 |     141 |   142 |    143 |
| local2     |       144 |    145   |     146 |    147  |     148 |     149 |   150 |    151 |
| local3     |       152 |    153   |     154 |    155  |     156 |     157 |   158 |    159 |
| local4     |       160 |    161   |     162 |    163  |     164 |     165 |   166 |    167 |
| local5     |       168 |    169   |     170 |    171  |     172 |     173 |   174 |    175 |
| local6     |       176 |    177   |     178 |    179  |     180 |     181 |   182 |    183 |
| local7     |       184 |    185   |     186 |    187  |     188 |     189 |   190 |    191 |

Kenarda bulunsun belki işinize yarayabilir :)

---
layout: post
title: "Sıfırdan Regex Motoru - Bölüm 2: Backtracking"
description: "Sıfırdan Regex Motoru - Bölüm 2: Backtracking"
date: 2025-08-11T07:00:00-07:00
tags: regex,nfa,backtracking,golang
---
 
Bu yazı serisi şu ana kadar 2 bölümden oluşmaktadır, diğer bölümlere de hazır
oldukça aşağıdaki linklerden ulaşabileceksiniz. Yazı içeriğinde geçen kodlara
[bu linkten](https://github.com/caltuntas/regex-poc) erişebilirsiniz. 

1. [Sıfırdan Regex Motoru - Bölüm 1: Parsing](https://www.cihataltuntas.com/2025/07/25/regex-engine-1) 
   - Bu yazıda, çok kısa ne yapmak istediğimizden, nasıl yapabileceğimizden ve
     bize verilen regex ifadelerinin parse edilip istediğimiz veri yapısı
     içinde nasıl tutabileceğimizden bahsedeceğiz.
2. [Sıfırdan Regex Motoru - Bölüm 2: Backtracking Algoritması](https://www.cihataltuntas.com/2025/07/25/regex-engine-2) (Bu yazı)
   - Bu yazıda, Backtracking algoritması nasıl çalışır, recursive algoritmaya göre
     farkları nelerdir örnekler üzerinden karşılaştırarak anlamaya çalışacağız.
3. [Sıfırdan Regex Motoru - Bölüm 3: Backtracking Regex Motoru](https://www.cihataltuntas.com/#) 
4. [Sıfırdan Regex Motoru - Bölüm 4: NFA Regex Motoru](https://www.cihataltuntas.com/#) (hazır değil)

## Giriş 

Bir önceki yazıda regex motorumun temelini oluşturacak olan verilen regex
ifadesini bileşenlerine ayırıp sonrasında AST veri yapısına çevirecek gerekli
`parser` kodunu yazmıştık. Bu yazıda ise Java, .NET, Python gibi dillerde
kullanılan Regex motorunun temelini oluşturan `Backtracking` algoritmasının
nasıl çalıştığını ne avantaj sağladığını, hem klasik hem de onu kullanarak
geliştirdiğimiz örnekler üzerinden inceleyip karşılaştıracağız.

## Nedir Bu Backtracking?

[Backtracking](https://en.wikipedia.org/wiki/Backtracking) algoritması sadece regex motoru geliştirirken değil, farklı bir çok problemin
çözümünde kullanılan bir algoritma, bu yüzden bizim problemimiz dışında nedir, ne yapar, faydası nedir
anlamaya çalışalım.

Benim bu algoritma için kullandığım açıklama ve kendi özetim, `akıllı brute-force` diyebilirim.
Örnek üzerinden neden bunu böyle olduğunu anlamaya çalışalım.

## Adım Adım Backtracking

Backtracking algoritması direk Regex motoru geliştirirken kullanmaya başlamadan
önce nasıl çalıştığını, hangi problemi çözdüğünü bir örnek yaparak öğrenmenizi
şiddetle tavsiye ederim.  Bu yüzden ben pekiştirmek için konu ile alakalı basit bir
Backtracking problemi seçip adım adım önce geleneksel yöntem ile bu problemi
nasıl çözeriz onu uyguladım, ardından iyileştirerek çözüp en sonunda da
Backtracking kullanarak aynı problemi çözdüm. Bunu yaptıktan sonra Regex motoru
üzerinde neden kullanıldığı çok daha anlaşılır olacaktır.

### Problem : Word-Search

Backtracking algoritmasının temelini öğretmek için kullanılan basit problemlerden bir tanesi [Word Search](https://en.wikipedia.org/wiki/Word_search) problemi, bizim Regex motorumuz ile
çok benzerlik gösterdiği için özellikle bunu seçtim. Sonuçta biz de çeşitli regex yapılarına göre verilen bir text içerisinde aradığımız şeyi bulmaya çalışıyoruz, 
özetle Regex problemini çok daha basiti diyebiliriz.

Problem, verilen bir matris içerisinde çeşitli yönlerde(sağa,sola,yukarıya, aşağıya) birer birim hareket ederek aranılan kelimenin o matris içerisinde olup olmadığını söylemenizi bekliyor.

Örnek, aşağıdaki bir matris var ve içerisinde `GEEK` bulunuyor mu inceleyelim.

```
{'T', 'E', 'E'},
{'S', 'G', 'K'},
{'T', 'E', 'L'},
```

İnsan olarak hemen fark etmiş olacaksınız ki aradığımız ifade matris içinde bulunuyor ve aşağıdaki gibi görülebilir.

![Capture 1](/img/regexengine/matrix.svg)

Tabi iş bunu programa yaptırmaya gelince o kadar kolay olmadığını görüyoruz. Bunu herhangi bir yapay zeka aracına ya da binlerce çözülmüş, kodlanmış haline 
bakmadan önce elinize kalem kağıt alıp nasıl siz çözersiniz uğraşmanızı tavsiye ederim. 

Ben kalem kağıt ile önce kafamda çözdüğüm için koda aktarırken bunun daha kolay olduğunu söyleyebilirim.

### Çözüm 1 - Loop

Öncelikle başlangıç yerimiz önemli, bir matris olduğu için en amatör yöntemle 0,0 noktasında başlayıp bütün satır ve sütunları döngü içerisinde dolaşarak 
bütün 4 harf içeren kombinasyonları çıkaralım, en son aralığım kelimenin bu liste içerisinde olup olmadığına karar verelim.

Örnek ilerleyişimiz şöyle olabilir, diyelim ki, 

1. Adım `T=0,0` noktasından başladık, bir sonraki gideceğimiz harf `S=1,0` ya da `E=0,1` olabilir.
2. Adım `S=1,0` seçtik diyelim, bir sonraki gideceğimiz harf `T=2,0` ya da `G=1,1` olabilir.
3. Adım `T=2,0` seçtik diyelim, bir sonraki gideceğimiz sadece harf `E=2,1` olabilir
4. Son adımda aralığımız kelimenin harf sayısına `{0 0}{1 0}{2 0}{2 1}TSTE` ile ulaştık.

Peki önümüze birden fazla seçecek çıktığını fark ettiniz sanırım, peki seçmediklerimiz arasında olabilir mi aradığımız kelime? Bu sebeple
bütün kombinasyonları deneyerek ancak kesin karar verebiliriz. Sadece `T=0,0` konumundan başladığımızda aşağıdaki gibi farklı seçenekler var, bunların hepsini 
kod içerisinde gezmemiz lazım.
```
{0 0}{1 0}{2 0}{2 1}TSTE
{0 0}{1 0}{1 1}{0 1}TSGE
{0 0}{1 0}{1 1}{2 1}TSGE
{0 0}{1 0}{1 1}{1 2}TSGK
{0 0}{0 1}{1 1}{2 1}TEGE
{0 0}{0 1}{1 1}{1 0}TEGS
{0 0}{0 1}{1 1}{1 2}TEGK
{0 0}{0 1}{0 2}{1 2}TEEK
```

Buraya kadar kağıt üzerinde ne yapmaya çalıştığımızı anladık diye düşünüyorum bunu olabilecek en basit yöntemi ile koda çevirelim, bunu yaparken de işimizi kolaylaştırsın diye
aradığımız kelimenin hep sabit yani `GEEK` gibi 4 karakterden oluştuğunu var sayalım. Gerçekte farklı uzunluklarda olabilir, buna sonra değineceğiz.
Bu örneğin geliştirdiğimiz basit regex motoru ile direk bir bağlantısı olmasa da tutarlılık açısından aynı programlama dilini örnekler için de kullandım, yani `Go` ile aradığımız kelimeyi
verilen yukarıdaki matris içinde bulan kodun ilk versiyonu aşağıdaki gibi gözüküyor.


```
package main

import (
	"fmt"
	"slices"
)

type Location struct {
	Row    int
	Column int
}

func (loc Location) GetNeighbors() []Location {
	return []Location{{loc.Row - 1, loc.Column}, {loc.Row + 1, loc.Column}, {loc.Row, loc.Column - 1}, {loc.Row, loc.Column + 1}}
}

func isValid(grid [][]byte, currentLoc Location, locs ...Location) bool {
	rowCount := len(grid)
	colCount := len(grid[0])
	for _, loc := range locs {
		if currentLoc.Row == loc.Row && currentLoc.Column == loc.Column {
			return false
		}
	}
	return currentLoc.Row >= 0 && currentLoc.Column >= 0 && currentLoc.Row < rowCount && currentLoc.Column < colCount
}

func traverse(grid [][]byte, loc Location) []string {
	result := make([]string,0)
	p0 := loc
	for _, p1 := range p0.GetNeighbors() {
		if isValid(grid, p1, p0) {
			for _, p2 := range p1.GetNeighbors() {
				if isValid(grid, p2, p0, p1) {
					for _, p3 := range p2.GetNeighbors() {
						if isValid(grid, p3, p0, p1, p2) {
							fmt.Print(p0)
							fmt.Print(p1)
							fmt.Print(p2)
							fmt.Print(p3)
							str := []byte{
								grid[p0.Row][p0.Column],
								grid[p1.Row][p1.Column],
								grid[p2.Row][p2.Column],
								grid[p3.Row][p3.Column],
							}
							fmt.Println(string(str))
							result = append(result, string(str))
						}
					}
				}
			}
		}
	}
	return result
}

func find(grid [][]byte, word string) bool {
	allResults :=make([]string,0)
	rows := len(grid)
	for i := 0; i < rows; i++ {
		cols := len(grid[i])
		for j := 0; j < cols; j++ {
			fmt.Printf("Starting point is {%d,%d}=%c\n",i,j,grid[i][j])
			result := traverse(grid, Location{i, j})
			allResults = append(allResults, result...)
		}
	}
	return slices.Contains(allResults, word)
}

func main() {
	tests := []struct {
		grid   [][]byte
		word   string
		result bool
	}{
		{
			[][]byte{
				{'T', 'E', 'E'},
				{'S', 'G', 'K'},
				{'T', 'E', 'L'},
			},
			"GEEK",
			true,
		},
	}

	for i, c := range tests {
		res := find(c.grid, c.word)
		if res != c.result {
			fmt.Printf("test case failed %d\n", i)
		}
	}
}
```

Oldukça basit olduğunu düşünsem de, `traverse` fonksiyonunu incelemenizi öneririm.
Bir konumdan taramaya başladıktan sonra aradığımız kelime 4 harfli olduğu ve elimizde bulmamız gereken 3 harf daha kaldığı için, 
iç içe, 3 döngü içe tüm olasılıkları çıkartıyoruz ve sonuç olarak dönüyoruz. 

Ayrıca `GetNeighbors` içinde de bir konumdan aşağı, yukarı, sağ, sol yönlerinde gidebileceği komşularını listeleyip kodu basitleştiriyoruz diyebilirim.
Bu kodu ister derleyip isterseniz de `go run main.go` ile çalıştırırsanız aşağıdaki gibi tüm noktalardan başladığında gidilebilecek rotaları ve bulunan kelimeleri listeleyecek.

```
Starting point is {0,0}=T
{0 0}{1 0}{2 0}{2 1}TSTE
{0 0}{1 0}{1 1}{0 1}TSGE
{0 0}{1 0}{1 1}{2 1}TSGE
{0 0}{1 0}{1 1}{1 2}TSGK
{0 0}{0 1}{1 1}{2 1}TEGE
{0 0}{0 1}{1 1}{1 0}TEGS
{0 0}{0 1}{1 1}{1 2}TEGK
{0 0}{0 1}{0 2}{1 2}TEEK
Starting point is {0,1}=E
{0 1}{1 1}{2 1}{2 0}EGET
{0 1}{1 1}{2 1}{2 2}EGEL
{0 1}{1 1}{1 0}{0 0}EGST
{0 1}{1 1}{1 0}{2 0}EGST
{0 1}{1 1}{1 2}{0 2}EGKE
{0 1}{1 1}{1 2}{2 2}EGKL
{0 1}{0 0}{1 0}{2 0}ETST
{0 1}{0 0}{1 0}{1 1}ETSG
{0 1}{0 2}{1 2}{2 2}EEKL
{0 1}{0 2}{1 2}{1 1}EEKG
...
...
```

### Çözüm 2 - Recursion

![Capture 2](/img/regexengine/recursion.jpg)

Yukarıdaki döngü kullanan kodumuz, 4 kelime içeren kelimeleri arama yapabilse de, bundan daha farklı kelime uzunluklarını aramada başarısız olacaktır, bunun sebebi de
kullandığımız iç içe döngü sayısı. Eğer 5 harf içeren bir kelime aramak istiyorsanız, bunu döngü yöntemi ile yapmanın en basit yöntemi bir `if-else` ekleyip 
aranılan kelime karakter sayısı **5** ise iç içe 4 döngü koymanız gerekir. 

Tabi kelime sayısı 2,3,6 gibi durumlarda kod işin içinden çıkılamaz bir hal alacağı için yardımımıza `recursion` koşacak, kısacası hard-coded bir döngü yerine
`recursive` bir yapıda fonksiyon yazıp bütün uzunlukları kapsayacağız.

Koda geçmeden önce, backtracking ve recursion mantığını kavramak için kullanılan ve benim de kalem kağıtla ilk kullandığım yöntemlerden biri olan bir yöntemden bahsedeyim.
Bu tarz problemlerde aslında olasılıkları içeren bir ağaç yapısı yani [State space](https://en.wikipedia.org/wiki/State_space_(computer_science)) oluşturup onun üzerinde
geziyoruz gibi düşünebilirsiniz. 

Yukarıdaki örnek üzerinden hatırlarsanız `T` ile başlamamız durumunda gidebileceğimiz tüm konumları ve karşılık gelen ifadeleri çıkarmıştık onu ağaç gibi modellemek 
benim anlamama oldukça yardımcı olduğu için, koda bu ağacı `Graphviz` formatında oluşturan bir fonksiyon da ekledim.

![Capture 3](/img/regexengine/t.svg)

Bunları dedikten sonra aynı problemi `recursive` şekilde farklı uzunluklardaki kelimeler ile de arama yapabilecek kodu yazalım.

```
//..
//..

func traverse(grid [][]byte, loc Location, word string, path []Location, result *[][]Location) {
	if len(path) == len(word) {
		c := make([]Location, len(path))
		copy(c, path)
		*result = append(*result, c)
		return
	}
	for _, p1 := range loc.GetNeighbors() {
		if isValid(grid, p1, path...) {
			path = append(path, p1)
			traverse(grid, p1, word, path, result)
			path = path[:len(path)-1]
		}
	}
}

func pathToString(grid [][]byte, paths [][]Location) []string {
	result := make([]string, len(paths))
	for j, p := range paths {
		chars := make([]byte, len(p))
		for i, l := range p {
			chars[i] = grid[l.Row][l.Column]
		}
		result[j] = string(chars)
	}
	return result
}

func find(grid [][]byte, word string) bool {
	allResults := make([]string, 0)
	rows := len(grid)
	for i := 0; i < rows; i++ {
		cols := len(grid[i])
		for j := 0; j < cols; j++ {
			result := make([][]Location, 0)
			fmt.Println("******new root******")
			traverse(grid, Location{i, j}, word, []Location{{i, j}}, &result)
			str := pathToString(grid, result)
			allResults = append(allResults, str...)
		}
	}

	return slices.Contains(allResults, word)
}

//...
//...
```

Ekrana çarşaf kadar kodu özellikle koymayıp aynı kalan ve Graphviz ile görselleştirme ve debug için koyduğum bazı 
fonksiyonları kaldırdım. Yukarıda döngüde yaptığımız işin aynısını recursion kullanarak farklı uzunluklardaki kelimeler ile
yapabilen kodu görüyorsunuz.

Kodun çalıştırdıktan sonra diğer arama rotalarını da görsel ağaç yapısı olarak görmek isterseniz, çıktıdaki `digraph` kısımlarını alıp 
[bu link](https://magjac.com/graphviz-visual-editor/?dot=digraph%20G%20%7B%0A%20%20node%20%5Bshape%3Dcircle%5D%3B%0A%20%20E_01-%3ET_00_1%0A%20%20S_10_1-%3ET_20_2%0A%20%20E_21-%3EL_22%0A%20%20G_11-%3ES_10%0A%20%20S_10_1-%3EG_11_1%0A%20%20E_21-%3ET_20%0A%20%20G_11-%3EE_21%0A%20%20S_10-%3ET_00%0A%20%20G_11-%3EK_12%0A%20%20K_12-%3EL_22_1%0A%20%20E_01-%3EE_02_1%0A%20%20E_02_1-%3EK_12_1%0A%20%20E_01-%3EG_11%0A%20%20K_12-%3EE_02%0A%20%20T_00_1-%3ES_10_1%0A%20%20K_12_1-%3EL_22_2%0A%20%20K_12_1-%3EG_11_2%0A%20%20S_10-%3ET_20_1%0A%20%20L_22_2%20%5Blabel%3D%22L%22%5D%3B%0A%20%20E_01%20%5Blabel%3D%22E%22%5D%3B%0A%20%20K_12%20%5Blabel%3D%22K%22%5D%3B%0A%20%20E_02%20%5Blabel%3D%22E%22%5D%3B%0A%20%20T_00_1%20%5Blabel%3D%22T%22%5D%3B%0A%20%20E_02_1%20%5Blabel%3D%22E%22%5D%3B%0A%20%20E_21%20%5Blabel%3D%22E%22%5D%3B%0A%20%20S_10%20%5Blabel%3D%22S%22%5D%3B%0A%20%20T_00%20%5Blabel%3D%22T%22%5D%3B%0A%20%20T_20_1%20%5Blabel%3D%22T%22%5D%3B%0A%20%20L_22%20%5Blabel%3D%22L%22%5D%3B%0A%20%20S_10_1%20%5Blabel%3D%22S%22%5D%3B%0A%20%20T_20_2%20%5Blabel%3D%22T%22%5D%3B%0A%20%20K_12_1%20%5Blabel%3D%22K%22%5D%3B%0A%20%20G_11%20%5Blabel%3D%22G%22%5D%3B%0A%20%20T_20%20%5Blabel%3D%22T%22%5D%3B%0A%20%20L_22_1%20%5Blabel%3D%22L%22%5D%3B%0A%20%20G_11_1%20%5Blabel%3D%22G%22%5D%3B%0A%20%20G_11_2%20%5Blabel%3D%22G%22%5D%3B%0A%7D) gibi göz atabilirsiniz.

Recursion kullanan çözümde dikkat edilmesi gereken satır belki `path = path[:len(path)-1]` diyebilirim, bütün olasılıkları dolaşmak için
bunu yapmamız gerekiyor, genelde bu kısım `backtrack` ya da `undo` olarak adlandırılıyor ama tam anlamıyla değil, neden olmadığına ileride değineceğiz.
Ama bu satırda yapılanı şöyle özetleyebiliriz, örnek; şuanda path olarak `GEE` rotasında ilerliyorum, buradan gidebileceği tüm rotaları çıkardıktan sonra
`GE` ye geri dönüp oradan gidebileceğim, `GET`, `GETS` rotalarını da çıkarmak için yapıyoruz.

Recursive versiyonu çalıştırıp Graphviz görseline bakarsanız, aradığımız kelime `GEEK` bulunma senaryosunda hangi rotaları kontrol ettiğini aşağıdaki gibi görebilirsiniz.


![Capture 4](/img/regexengine/geek-recursive.svg)

### Çözüm 3 - Backtracking

Adım adım ilerleyerek sona doğru yaklaştık, sıra aynı problemi Backtracking yaklaşımı ile çözmeye geldi. [Backtracking](https://en.wikipedia.org/wiki/Backtracking) dediğimiz zaman aklımıza ilk gelmesi 
gereken şey recursion, fakat arada ufak farklılıklar var buna değineceğimizi belirtmiştik. Backtracking teknik yöntem olarak recursive fonksiyonları kullanıyor, fakat
bunu yaparken tüm olasılıkları çıkarıp gezmektense, bir rota belirli bir koşulu sağlamıyorsa onu baştan eleyip, sadece koşulları sağlayan olasılıklar üzerinde devam ediyor.

Tabi bunun en büyük avantajı performans oluyor, çünkü değerlendirdikleri olasılıklar arasında sayı olarak çok büyük fark oluyor, bu sebeple klasik recursive algoritmaya göre çok daha hızlı çalışıyor.

Önce kodu Backtracking yöntemine çevirmek için ne yaptım onu inceleyelim ardından performans ve çıktılarını değerlendiririz.

```
//...
//...

func traverse(grid [][]byte, loc Location, word string, path []Location, result *[][]Location) {
	if word[len(path)-1] != grid[loc.Row][loc.Column] {
		return
	}
	if len(path) == len(word) {
		c := make([]Location, len(path))
		copy(c, path)
		*result = append(*result, c)
		return
	}
	for _, p1 := range loc.GetNeighbors() {
		if isValid(grid, p1, path...) {
			path = append(path, p1)
			traverse(grid, p1, word, path, result)
			path = path[:len(path)-1]
		}
	}
}

//...
//...
```

Kodun diğer bütün fonksiyonları bir önceli ile aynı hatta `traverse` fonksiyonu bile neredeyse aynı fakat arada büyük bir performans farkı oluşturan aşağıdaki
satırlar bulunuyor.

```
if word[len(path)-1] != grid[loc.Row][loc.Column] {
	return
}
```

Basit olarak bu bize girdiğimiz rotanın aradığımız kelime ile uyumlu olup olmadığını adım adım kontrol ediyor, eğer değilse
rotadan erkenden çıkmamızı sağlıyor. Mesela aramaya `G` harfinden başladığımız durumda yukarıdaki başarılı sonucu bize vermek için
tüm ağacı dolaşmak yerine aşağıdaki ağacı dolaşıp doğru sonuca ulaşıyor.

![Capture 5](/img/regexengine/geek-backtrack.svg)

Bir önceki ağaç ile karşılaştıracak olursanız belirgin şekilde daha az rota gezerek sonuca ulaştığı görülebiliyor. Kırmızı okları
ben özellikle nerelerde backtrack yapıp, nasıl devam ettiğini göstermek için ekledim. Nasıl çalıştığını daha belirgin olarak gösterebildiğimi umuyorum.

## Performans Karşılaştırması

Yukarıda işleri basit tutmak ve gözle sonucu direk bulabilmemiz için harf matrisini oldukça küçük tuttum. Ama gerçek hayatta hem Regex motoruna verilen
girdiler çok daha uzun olduğu, hem de gerçek dünya senaryoları çok daha büyük veriler içerebildiği için Recursive ve Backtracking algoritmasını 
karşılaştırmak için daha büyük bir matris kullanalım.

```
{'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J'},
{'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K'},
{'C', 'D', 'E', 'F', 'A', 'H', 'I', 'J', 'K', 'L'},
{'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M'},
{'E', 'F', 'G', 'H', 'I', 'A', 'K', 'L', 'M', 'N'},
{'F', 'G', 'H', 'I', 'J', 'K', 'A', 'M', 'N', 'O'},
{'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'A', 'A'},
{'H', 'I', 'J', 'K', 'A', 'M', 'N', 'O', 'P', 'Q'},
{'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R'},
{'J', 'K', 'L', 'M', 'N', 'O', 'A', 'Q', 'R', 'S'},
{'A', 'B', 'C', 'D', 'E', 'A', 'G', 'H', 'I', 'J'},
{'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K'},
{'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L'},
{'D', 'E', 'F', 'A', 'H', 'I', 'J', 'K', 'A', 'M'},
{'E', 'F', 'A', 'H', 'I', 'J', 'A', 'L', 'M', 'N'},
{'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O'},
{'G', 'H', 'I', 'J', 'A', 'L', 'M', 'N', 'O', 'P'},
{'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q'},
{'I', 'J', 'K', 'A', 'M', 'N', 'O', 'P', 'Q', 'R'},
{'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S'},
```

Bu sefer **20x10** bir matris içerisinde `ABDEFGHMN` arayalım, dikkatinizi çekti ise özellikle aralara `A` harfi serpiştirdim ki
başlayabilecek birden fazla nokta olsun. Ayrıca gözle herhalde aradığımız şeyin burada olmadığı anlaşılmıştır.

Karşılaştırmayı bu sefer derleme `go build .` yaptıktan sonra yaptım ki CPU var ise eğer yapacağı optimizasyonları uygulasın ve
production ortamına benzer bir işlem olsun. Bir de performans karşılaştırmasını `go benchmark` aracı ile değil de klasik `time` komutu 
ile yaptım. Hangi fonksiyon ne kadar süre harcamış, ne kadar memory kullanmış gibi şeyler ile şimdilik ilgilenmiyorum, ana odağım toplamda ne kadar zaman aldığı.

```
recursion > go build .
recursion > /usr/bin/time -al ./wordsearchrecursive
        4.27 real         2.26 user         1.65 sys
            14462976  maximum resident set size
                   0  average shared memory size
                   0  average unshared data size
                   0  average unshared stack size
                3524  page reclaims
                 263  page faults
                   0  swaps
                   0  block input operations
                   0  block output operations
                   0  messages sent
                   0  messages received
                 356  signals received
                3365  voluntary context switches
               14264  involuntary context switches
         11981226538  instructions retired
         12442993821  cycles elapsed
            12054528  peak memory footprint
```

Recursive olan toplamda 5 saniyeye yakın bir sürede işlemi tamamladı, şimdi de Backtracking kullananı çalıştıralım.

```
backtrack > go build .
backtrack > /usr/bin/time -al ./wordsearchbacktrack
        0.05 real         0.00 user         0.00 sys
             2002944  maximum resident set size
                   0  average shared memory size
                   0  average unshared data size
                   0  average unshared stack size
                 516  page reclaims
                 214  page faults
                   0  swaps
                   0  block input operations
                   0  block output operations
                   0  messages sent
                   0  messages received
                  15  signals received
                   0  voluntary context switches
                 152  involuntary context switches
            20796342  instructions retired
            30271984  cycles elapsed
             1126400  peak memory footprint
```

Neredeyse 0 saniyede işini bitirdi, arada kaç kat hız farklı var artık hesaplamasını size bırakıyorum.

## Sonuç

Biz Regex motoru yazmayacak mıydık neden bu kadar Backtracking algoritmasını anlamak için uğraştık diyenler için şunu açıklayalım.
Backtracking mantığını anlamak günümüzde yaygın olarak kullanılan Regex motorlarını ve onlarda ortaya çıkabilecek performans sorunlarını anlamak 
ve çözmek için oldukça önemli. Çünkü temelinde bu algoritma kullanılıyor, ve büyük bir girdi ve düzgün yazılmamış bir regex pattern neden çok uzun süre alabilir hatta sisteminizi patlatabilir,
işin temelinde yatan kavramı anlayarak örneklerle gördük. 

Bundan sonrası bu algoritmayı kendi geliştirdiğimiz Regex motoruna uygulamak olacak. Bu yazıda onu da dahil etmeyi düşünüyordum ama geri dönüp bakınca oldukça uzun olmuş, devamı sonraki yazıya artık.

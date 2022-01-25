---
layout: post
title: "Refactoring : Decompose Conditional"
description: "Refactoring : Decompose Conditional"
date: 2007-07-23T07:00:00-07:00
tags: refactoring
---

Kodun okunulabilirdiğini arttıran en önemli Refactoring yöntemlerinden biride Decompose Conditional yani türkçeye çevirmeye çalışırsak Şartlı ifadeleri ayırma diyebiliriz.Küçük bir örnek üzerinde nasıl yapıldığını görürsek daha iyi anlaşılacağını umuyorum.Aşağıda daha önce uğraştığım verilen veritabanındaki tablolar için sınıf oluşturan programdan ufak bir sınıfın constructor metodunu görüyorsunuz.

```csharp 
private const int USER_TABLE_ATTRIBUTE = 0;
private TableDefs tableDefs; 
public MDBResolver(string mdbPath)
{
  this._mdbPath = mdbPath;
  DAO.DBEngineClass dbEng = new DAO.DBEngineClass();
  DAO.Database db = dbEng.OpenDatabase(this._mdbPath,false, false, "");
  tableDefs = db.TableDefs;
  ArrayList tables = new ArrayList();
  for(int tableIndex = 0; tableIndex < tableDefs.Count; tableIndex ++)
  {

    if (tableDefs[tableIndex].Attributes == USER_TABLE_ATTRIBUTE)
    {
      Table table ;
      string tableName=tableDefs[tableIndex].Name; 
      table= new Table(tableName,this.GetFields(tableDefs[tableIndex].Name));
      tables.Add(table);
    }
  }
  db.Close();

  this._tables = (Table[])tables.ToArray(typeof(Table));
}
//geriye kalan metodlar........
//....................
```

İlk gözüme çarpan yukarıdaki kodun okunulabilirliğinin kötü olduğu. Çünkü kodu okuduğumda bana konuşma dilindeki gibi ne yapmaya çalıştığını ifade edemiyor.Kodu iyice incelediğimde ne yapmaya çalıştığını anlıyorum. Verilen veritabanındaki tabloları alıp bir tableDefs nesnesine atıyor ardından bu nesne içindeki tabloları alıp eğer USER_TABLE ise bunu sınıfını oluşturacağı tablolar listesine atıyor.Çünkü işimize yaramayacak olan Sistem tablolarının sınıflarını üretmesini istemiyoruz.

Kırmızı satıra baktığımızda bir if kontrolü görüyoruz.Tablonun USER_TABLE olup olmadığını kontrol ediyor. O satırın içindeki parantezleri iyice okumadığımız zaman USER_TABLE kontrolü yaptığını anlayamıyoruz.Şimdi Refactoring yaparak kodumuzu aşağıdaki gibi değiştirelim.


```csharp 
private const int USER_TABLE_ATTRIBUTE = 0;
private TableDefs tableDefs;
public MDBResolver(string mdbPath)
{
  this._mdbPath = mdbPath;
  DAO.DBEngineClass dbEng = new DAO.DBEngineClass();
  DAO.Database db = dbEng.OpenDatabase(this._mdbPath,false, false, "");
  tableDefs = db.TableDefs;
  ArrayList tables = new ArrayList();
  for(int tableIndex = 0; tableIndex < this.tableDefs.Count; tableIndex ++)
  {

    if (isUserTable(tableIndex)) 
    {
      Table table ;
      string tableName=tableDefs[tableIndex].Name; 
      table= new Table(tableName,this.GetFields(tableDefs[tableIndex].Name));
      tables.Add(table);
    }
  }
  db.Close();

  this._tables = (Table[])tables.ToArray(typeof(Table));
}

private bool isUserTable(int tableIndex)
{
  return this.tableDefs[tableIndex].Attributes == USER_TABLE_ATTRIBUTE;
}

//geriye kalan metodlar........
//....................
```

Yukarıdaki yeşil satırda eski şartlı ifademizi nasıl değiştirdiğimizi gördünüz. Önceden if içinde bulunan ifadeyi ayrı bir metod olarak ayırdık.Yani şartlı ifadeyi ayrıştırdık.Kod artık okunduğunda gayet kolaylıkla anlaşılabilir hale geldi.Bu şekilde if-else şartlı kontrol yapıları içindeki anlaşılması zor olan kontrolleri ayrı bir metod içine alarak ayırmaya Decompose Conditional deniyor. Sonuçta tek satır içeren ufak bir metod ortaya çıktı gereksiz olarak görebilirsiniz fakat kodun okunulabilirdiği temizliği ilerisi için her zaman daha önemli. Kodun diğer kısımlarıda aslında Refactoring gerektiriyor bunun farkındayım amacım sadece Decompose Conditional olduğu için diğerlerini sizlere bırakıyorum…

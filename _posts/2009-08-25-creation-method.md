---
layout: post
title: "Object Creation Patterns : Creation Method"
description: "Object Creation Patterns : Creation Method"
date: 2009-08-25T18:08:26+00:00
tags: patterns
---
  
Uzun süredir yazamamanın verdiği rahatsızlığı üzerimden atmak üzere yeni yazı
serilerimize başladığımızı bildiririm.(Vatana millete hayırlı olsun :) ) Bu
satırları yazarken bile kendimi biraz daha rahatlamış hissettim. Yaklaşık belki
1 sene önce arkadaşım Sadullah’ın Factory Pattern ile alakalı yazı yazmamı
istediğini hatırlar gibiyim. Daha sonra başka arkadaşlarda yorumlarında bu
yönde istek belirttiler. Bu yüzden bende hem daha önceki sözümü geç de olsa
yerine getirmiş olayım, hemde diğer arkadaşlara faydalı birşeyler sunayım diye
bu konuda bildiklerimi sizlere anlatayım dedim. Bu yazı serisinde nesneleri
oluşturmada kullanılan işimize yarayabilecek , benim de sık sık kullandığım
yöntemlerden, pattern’lardan bahsedeceğim.

Biliyorsunuz nesneye yönelik bir dilde yazılım geliştirirken en çok
kullandığımız kalıp new ile nesne oluşturmaktır. Bazen bu şekilde nesneleri
oluşturmak her zaman en iyi yöntem olmayabiliyor.Bu yüzden nesneleri
oluştururken kullanılan çeşitli yöntemler mevcut, her birinin avantajı ve
dezavantajları var. Bu yazıda bunlardan ilk olarak bahsetmek istediğim Creation
Method yöntemi.

Çok basit ve bir o kadar da faydalı bulduğum Creation Method yönetime pattern
demek doğru olmaz sanırım. İlk olarak Effective Java kitabında Static Factory
Methods başlığı altında bu yöntemle karşılaşmıştım. Daha sonra da Refactoring
To Patterns kitabında aynı yöntemi Creation Methods olarak anlatıyordu. Factory
Pattern ile karışmaması için Creation Method ismini daha uygun bulduğumu
söyleyebilirim bu yüzden yazının bundan sonraki bölümünde Creation Method
olarak bahsedicem.

Creation Method yöntemini kullanarak basit olarak nesneleri oluştururken sık
sık kullanılan ve tekrar eden kodu, nesnenin üzerinde static metodlar içinde
toplayarak tekrar eden kodu önleyebilirsiniz.Örnek olarak bu durumu aşağıdaki
kodlar üzerinde inceleyelim.

```
private Attachment UploadFile(string filePath)
{
  //Diğer kodları kısa tutmak için yazmıyorum
  //……
  string outputFileName = "Fax_" + DateTime.Now.ToString("dd.MM.yyyy_hh_mm_ssss")
    + "." + extension;
  string outputFilePath = uploadFolder + "\" + outputFileName;
  outputFileStream = new FileStream(outputFilePath, FileMode.Create);

  int byteRead;
  do
  {
    byteRead = inputFileStream.ReadByte();
    if (byteRead != -1) outputFileStream.WriteByte((byte) byteRead);
  } while (byteRead != -1);

  Attachment attachment = new Attachment();
  attachment.AttachmentName = outputFileName;
  attachment.AttachmentPath = outputFilePath;
  attachment.AttachmentType = EnumAttachmentType.Image;
  attachment.MimeTypeIcon = Icons.Image;

  inputFileStream.Close();
  outputFileStream.Close();

  return attachment;
}
```

Projenin diğer bir kısmında ise aşağıdaki gibi kodlar bulunuyor

```
protected void OnFileUpload(RelatedFile relatedFile)
{
  Attachment attachment = new Attachment();
  attachment.AttachmentName = relatedFile.RelatedFileName;
  attachment.AttachmentPath = relatedFile.RelatedFilePath;
  attachment.AttachmentType = EnumAttachmentType.Word;
  attachment.MimeTypeIcon = Icons.Word;

  product.SaveAttachment(attachment);
}
//………
//…
protected void AddProduct()
{
  Attachment attachment = new Attachment();
  attachment.AttachmentName = "";
  attachment.AttachmentPath = "";
  attachment.MimeIconType =Icons.Empty

  product.Attachments.Add(attachment);
}
```

Yukarıda gördüğünüz kod parçaları projenin birçok yerinde bulunuyor.Dikkat
ederseniz farklı işlemler için Attachment yani eklenti nesnesini oluşturup
kullanıyoruz. Bu oluşturma sırasında AttachmentType, MimeTypeIcon (eklenti
tipi,dosya tipi ikonu) gibi özellikleri yapılan işleme göre atıyoruz.Bu nesneyi
oluşturma kodu uygulamanın birçok yerinde tekrar ediyor. Dolayısıyla oluşturma
sırasında her nesneye yeni bir özellik atamak istersek ya da varolan
özelliklerden birinin(örn. MimeTypeIcon) değişmesi istersek uygulamanın her
yerine dağılmış olan bu kodu tek tek düzenlemek zorunda kalırız. Öncelikle bu
tarz tekrarı önlemek için nesnemize aşağıdaki gibi uygun yapıcı metodları
ekleyebiliriz ve tekrarı önleyebiliriz.

```
protected void Metod()
{
  Attachment attachment = new Attachment
    (relatedFile.RelatedFileName,relatedFile.RelatedFilePath,EnumAttachmentType.Word,Icons.Word);

  //……

  Attachment attachment = new Attachment
    (outputFileName,outputFilePath,EnumAttachmentType.Image,Icons.Image);

  //……

  Attachment attachment = new Attachment(Icons.Empty);

}
```

Yukarıdaki gibi nesneye gerekli constructor metodlarını ekleyerek tekrarı
önlemiş olduk. Fakat burada da şöyle bir problem ortaya çıkıyor. Eğer
nesnenizde bu şekilde birden fazla constructor varsa dışarıdan bu sınıfları
kullanacak olan yazılımcıların ya da takım arkadaşlarımızın her yapıcı metoda
baktığında hangisini kullanacağı hakkında pek bir fikri olmamasıdır. Düşünün
elinizde oluşturmak istediğiniz nesneye ait 5 adet farklı yapıcı metodunuz var
hangisini kullanarak nesneyi oluşturmalısınız? Bu yapıcıların arasındaki fark
nedir? Direk olarak anlamak pek mümkün değil. Çünkü yapıcı metodların isimleri
Java, C# gibi dillerde nesne ismi ile aynı olmak zorunda bu da bize o yapıcı
metodların neyi yaptığı konusunda pek ipucu vermiyor.

Aynı kodu birde Creation Method kullanarak aşağıdaki gibi tekrar yazalım.

```
public class Attachment:BusinessBase
{
  //Diger kodlar……
  private static Attachment createAttachment(string filePath,string
      fileName,EnumAttachmentType type,MimeTypeIcon icon)
  {
    Attachment attachment =new Attachment();
    attachment.AttachmentName = fileName;
    attachment.AttachmentPath = filePath;
    attachment.AttachmentType = type;
    attachment.MimeTypeIcon = icon;
    return attachment;
  }

  public static Attachment createImage(string filePath,string fileName)
  {
    return createAttachment
      (filePath,fileName,EnumAttachmentType.Image,Icons.Image);
  }

  public static Attachment createWord(string filePath,string fileName)
  {
    return createAttachment(filePath,fileName,EnumAttachmentType.Word,Icons.Word);
  }

  public static Attachment createEmpty()
  {
    return createAttachment("","",null,Icons.Empty);
  }

  //……………
}
```

Yukarıdaki kodda gördüğünüz gibi nesnemiz üzerine aynı nesneyi oluşturan static
metodlar ekledik. Dolayısıyla nesnemizi oluşturan yerler bundan sonra aşağıdaki
gibi oluşturacaklar.

```
protected void Metod()
{
  Attachment attachment = Attachment.createWord
    (relatedFile.RelatedFileName,relatedFile.RelatedFilePath);

  //……

  Attachment attachment = Attachment.createImage(outputFileName,outputFilePath);

  //……

  Attachment attachment = Attachment.createEmpty();

}
```

Gördüğünüz gibi artık yukarıda gördüğünüz kod hem tekrardan arınmış oldu hemde
çok daha anlaşılır duruma geldi. Artık heryerde tekrar eden gereksiz oluşturma
kodları tek bir yerde toplandı.Dolayısıyla nesneyi oluşturma sırasında yeni bir
özellik eklemek istersek ya da varolan bir özelliği değiştirmek istersek bu
işlemi tek bir yerde yapacağız. Ayrıca birçok construstor olduğunda hangisinin
nasıl bir nesne oluşturacağı durumu ortadan kalktı. Nesnenin üzerindeki
createWord, createImage, createEmpty gibi metodlar çok daha anlaşılır ve ne
yaptığını ifade eden metodlar.Bu yüzden sınıfın kullanımı daha da kolaylaştı.

Gördüğünüz gibi Creation Method basit ama tekrarı önleyen, kullanım kolaylığını
ve okunulabilirliği arttıran oldukça etkili bir yöntem. Ben bu yöntemi
genellikle bu tarz basit durumlarda daha çok kullanıyorum. Eğer oluşturma
mantığı daha kompleks ve farklı nesneler işin içine giriyorsa ya da nesne
üzerindeki bu tarz Creation Method’ların sayısı gitgide artıyorsa Factory,
Abstract Factory Pattern’ları kullanabilirsiniz.Bunlarada serimizin diğer
yazılarında değinmek üzere sizleri kod ile başbaşa bırakıyorum….

---
layout: post
title: "Model View Presenter (MVP) Pattern"
description: "Model View Presenter (MVP) Pattern"
date: 2008-09-07T07:00:00-07:00
tags: patterns
---

Yine mimari olarak oldukça faydalalı olan tasarım kalıplarından birini örnekle
incelemeye devam edeceğiz. Bu yazıda Model View Controller (MVC) Pattern’ın bir
çeşidi olan Model View Presenter (MVP) Pattern nedir ne değildir bakıp
örneklerle inceleyeceğiz.

Örnekleri buradan indirebilirsiniz

- [AdresListesi Klasik(UI ile Business Logic iç içe )](/code/mvp/AdresListesiKlasik.rar)
- [AdresListesi MVP(UI ile Business Logic ayrılmış)](/code/mvp/AdresListesiMVP.rar)

Model View Controller,Model View Presenter,Presentation Model… gibi GUI ile
alakalı tasarım kalıplarının temel amacı kullanıcı arayüzü ile (UI) iş
mantığının birbirinden ayrılmasını sağlamaktır.Yani yine sihirli kelimeyi
tekrar edeceğim asıl amaç Separation of concerns . Herbiri bunu farklı şekilde
yapar fakat felsefe temelde aynıdır. Şimdi her zamanki gibi kötü örnekle
anlatmaya başlayalım. UI ile iş mantığının ayrılmamasının ne gibi problemi var?
Ne güzel butonlara basıp altlarına bütün iş mantığı kodumuzu yazıyoruz değil
mi? Bakalım problemler nelermiş…

Bunun için daha önceden DAO Pattern başlığı altında yazdığım yazıdaki örneği
kullanacağım.İçeride kullanılan DAO sınıfları nedir, ne işe yarar bilmiyorsanız
eski makaleyi okumanızda fayda var.  Burada küçük bir adres defteri uygulaması
yapmıştık. Adres defterimizde kişi ekleme,silme,güncelleme,listeleme işlemleri
yapıyorduk. Bu örnek için küçük programımızı biraz daha büyütelim ve daha
önceden eksik olan birkaç özellik ekleyelim. Daha önceden eksik olan
özelliklerden biri kişi eklerken herhangi bir validation kontrolü yapmamasıydı.
Mesela adı, soyadı gibi alanlar boş girilebiliyordu. Ayrıca aynı ad ve soyada
ait olan kişiler tekrar girilebiliyordu.Bu yüzden programa aşağıdaki gibi
özellikler ekleyelim.

- Ad,Soyad,Adres,Telefon gibi alanlar boş girildiğinde kayıt yapmayıp uyarı
  versin.
- Aynı ad ve soyada sahip başka biri varsa kayıt yapmayıp uyarı versin.

Programımıza bu özellikleri ekleyip kodumuzu aşağıdaki gibi yazalım.

```
public partial class AdresListesi : Form
{
  private readonly IKisiDAO kisiDao ;
  public AdresListesi(IKisiDAO dao)
  {
    kisiDao = dao;
    InitializeComponent();
  }

  private void btnKaydet_Click(object sender, EventArgs e)
  {
    if(txtAd.Text==string.Empty || txtSoyad.Text==string.Empty 
        || txtAdres.Text==string.Empty || txtTelefon.Text==string.Empty)
    {
      lblUyariMesaji.Visible = true;
      lblUyariMesaji.Text = "Bütün alanlar girilmeden kayıt edilemez!";
      return;
    }

    Kisi varOlanKisi = kisiDao.GetByName(txtAd.Text, txtSoyad.Text);
    if(varOlanKisi!=null)
    {
      lblUyariMesaji.Visible = true;
      lblUyariMesaji.Text = "Bu kişi listenizde mevcut tekrar kayıt edilemez!";
      return;
    }

    Kisi kisi = new Kisi(txtAd.Text, txtSoyad.Text, txtAdres.Text, txtTelefon.Text);
    kisiDao.Insert(kisi);
    LoadData();
  }

  private void LoadData()
  {
    dgKisiListesi.DataSource = kisiDao.GetAll();
  }

  private void AdresListesi_Load(object sender, EventArgs e)
  {
    LoadData();
  }

  private void Goster(Kisi kisi)
  {
    lblUyariMesaji.Visible = false;
    txtAd.Text = kisi.Ad;
    txtSoyad.Text = kisi.Soyad;
    txtAdres.Text = kisi.Adres;
    txtTelefon.Text = kisi.Telefon;
  }

  private void dgKisiListesi_Click(object sender, EventArgs e)
  {
    if (SeciliKisiID != 0)
    {
      Kisi kisi = kisiDao.GetByID(SeciliKisiID);
      Goster(kisi);
    }
  }

  private int SeciliKisiID
  {
    get
    {
      if (dgKisiListesi.CurrentRow != null)
        return Convert.ToInt16(dgKisiListesi.CurrentRow.Cells["KisiID"].Value);
      return 0;
    }
  }

  private void btnGuncelle_Click(object sender, EventArgs e)
  {
    Kisi kisi = new Kisi(SeciliKisiID, txtAd.Text, txtSoyad.Text, txtAdres.Text, txtTelefon.Text);
    kisiDao.Update(kisi);
    LoadData();
  }

  private void btnSil_Click(object sender, EventArgs e)
  {
    kisiDao.Delete(SeciliKisiID);
    LoadData();
  }
}
```

Çok basit bir uygulama olsa da özellikle yukarıda gördüğünüz kaydet
butonunun(btnKaydet_Click) altına yazılan koda bakmanızı istiyorum.Gördüğünüz
gibi iş mantığı(Business Logic) burada direk olarak butonun altında
kodladık.Hem UI ile alakalı kodlar hemde iş mantığı ile alakalı kodlar bir
arada.UI ile Business Logic arasında kesin bir ayrım yok iç içe geçmiş.Bu
şekilde çok basit uygulamalar dışında  geliştirdiğiniz yazılımın
yönetilmesi,bakımı gerçekten çok zor.Birde yukarıdaki yapının şekline bakalım

![Normal.jpeg](/img/mvp/Normal.jpeg)

Buna benzer daha önceden çalıştığım bir projede Java Swing ile geliştirilmiş
bir ekran(JFrame,.NET karşılığı Form diyebiliriz) yaklaşık olarak 3000
satırdı.Kodu değiştirmek,hata bulmak samanlıkta iğne aramaktan farksız değildi
açıkçası.MVP,MVC uyguladıktan sonra yani UI ile iş mantığı ayrıldığında Proje
sonlarına doğru aynı form yaklaşık olarak 200 satıra düşmüştü ve
değiştirilmesi,yeniden kullanılması oldukça kolaylaştırılmıştı.

Ayrıca bu şekilde iş mantığı UI altına gömüldüğünde aynı iş mantığını başka
yerlerde kullanmak çok zor.Bu iş mantığınızı başka biryere taşımak
istediğinizde yapabileceğiniz tek ve en kötü şey olan copy-paste yapmak
olacaktır. Tabi burada da UI ile iç içe olduğu için muhtemelen çalışmayacaktır.
Yani aynı mantığı gereken başka yerlerde tekrar tekrar yazmanız gerekecek. Tabi
sık sık değişin kullanıcı arayüzüne daha değinmedim.Kullanıcı arayüzünde
Winforms da bulunan butonu değilde kendi yazdığınız değişik efektlere sahip
butonunuzu kullanmak istiyorsunuz ne yapmanız lazım. Eski btnKaydet_Click
altındaki kodları kopyala,yeni butonu koy, kopyaladığın kodları yeni butonun
altına tekrar yaz…. gördüğünüz gibi birsürü problem var.

Şimdi bu tarz problemlerden kurtulmak için kullanılan design pattern’lardan
biri olan Model View Presenter’ı kullanalım bakalım neler değişecek. Öncelikle
kodu yazalım ardından detaylı şekilde inceleriz.

```
public partial class AdresListesi : Form,IViewAdresListesi
{
  private AdresListesiPresenter presenter ;

  public AdresListesi()
  {
    InitializeComponent();
  }

  private void btnKaydet_Click(object sender, EventArgs e)
  {
    presenter.Save();
  }

  private void AdresListesi_Load(object sender, EventArgs e)
  {
    presenter.Init();
  }

  private void dgKisiListesi_Click(object sender, EventArgs e)
  {
    lblUyariMesaji.Visible = false;
    presenter.Select();
  }

  public string Ad
  {
    get { return txtAd.Text; }
    set { txtAd.Text = value; }
  }

  public string Soyad
  {
    get { return txtSoyad.Text; }
    set { txtSoyad.Text = value; }
  }

  public string Telefon
  {
    get { return txtTelefon.Text; }
    set { txtTelefon.Text = value; }
  }

  public string Adres
  {
    get { return txtAdres.Text; }
    set { txtAdres.Text = value; }
  }

  public string ErrorMessage
  {
    set
    {
      lblUyariMesaji.Visible = true;
      lblUyariMesaji.Text = value;
    }
  }

  public AdresListesiPresenter Presenter
  {
    set { presenter = value; }
  }

  public void Show(IList<k  ISI> kisiler)
  {
    dgKisiListesi.DataSource = kisiler;
  }

  public int SeciliKisiID
  {
    get
    {
      if (dgKisiListesi.CurrentRow != null)  return Convert.ToInt16(dgKisiListesi.CurrentRow.Cells["KisiID"].Value);
      return 0;
    }
  }

  private void btnGuncelle_Click(object sender, EventArgs e)
  {
    presenter.Update();
  }

  private void btnSil_Click(object sender, EventArgs e)
  {
    presenter.Delete();
  }
}
```

```
public interface IViewAdresListesi
{
  string Ad { get; set; }
  string Soyad { get; set; }
  string Telefon { get; set; }
  string Adres { get; set; }
  string ErrorMessage {set; }
  int SeciliKisiID { get; }
  AdresListesiPresenter Presenter { set; }
  void Show(IList<Kisi> kisiler);
}

public class AdresListesiPresenter
{
  private readonly IViewAdresListesi view;
  private readonly IKisiDAO kisiDAO;

  public AdresListesiPresenter(IViewAdresListesi view, IKisiDAO kisiDAO)
  {
    this.view = view;
    this.kisiDAO = kisiDAO;
    view.Presenter = this;
  }

  public void Init()
  {
    UpdateView();
  }

  public void Save()
  {
    if(BosAlanVarmi())
    {
      view.ErrorMessage = "Bütün alanlar girilmeden kayıt edilemez!";
      return;
    }

    Kisi varOlanKisi = kisiDAO.GetByName(view.Ad,view.Soyad);
    if (varOlanKisi != null)
    {
      view.ErrorMessage = "Bu kişi listenizde mevcut tekrar kayıt edilemez!";
      return;
    }

    Kisi kisi = new Kisi(view.Ad, view.Soyad, view.Adres, view.Telefon);
    kisiDAO.Insert(kisi);
    UpdateView();
  }

  private bool BosAlanVarmi()
  {
    return view.Ad==string.Empty || view.Soyad==string.Empty 
      || view.Adres==string.Empty || view.Telefon==string.Empty;
  }

  public void Delete()
  {
    kisiDAO.Delete(view.SeciliKisiID);
    UpdateView();
  }

  public void Update()
  {
    Kisi kisi = new Kisi(view.SeciliKisiID, view.Ad, view.Soyad, view.Adres, view.Telefon);
    kisiDAO.Update(kisi);
    UpdateView();
  }

  public void Select()
  {
    if (view.SeciliKisiID == 0) return;
    Kisi kisi = kisiDAO.GetByID(view.SeciliKisiID);
    view.Ad=kisi.Ad;
    view.Soyad=kisi.Soyad;
    view.Adres=kisi.Adres;
    view.Telefon = kisi.Telefon;
  }

  private void UpdateView()
  {
    IList<k  ISI> kisiler = kisiDAO.GetAll();
    view.Show(kisiler);
  }
}
```

![ekranWin.jpeg](/img/mvp/ekranWin.jpeg)

Şimdi yukarıdaki koda bakacak olursanız View yani AdresListesi Windows Forms
sınıfının oldukça basitleştiğini göreceksiniz. Aslında sadece
AdresListesiPresenter sınıfının ilgili metodlarını çağırıyor ve kendi
alanlarını get,set ediyor diyebiliriz. Başka ne DAO ne de Business Logic ile
alakalı hiçbirşey bilmiyor.İş mantığı ile alakalı kodlar Presenter sınıfına
taşındığı için View ile alakalı olmayan bütün kodlardan kurtulmuş olduk. Yani
herkes kendi sorumluluğunu yerine getiriyor. AdresListesiPresenter sınıfına
bakacak olursanız View ile Model yani iş mantığı sınıflarımızın koordinasyonunu
kontrol ediyor. Sınıf diyagramına bakalım.

![AdresListesiMVP.jpeg](/img/mvp/AdresListesiMVP.jpeg)

Şimdi bunu nasıl yapıyoruz ondan bahsedelim. Öncelikle AdresListesiPresenter
Presenter altında tamamen ayrı bir modülde bulunuyor ve UI teknolojilerinden
tamamen bağımsız. İçerisinde sadece ihtiyaç duyduğu IViewAdresListesi interface
sınıfı bulunuyor.Bu interface üzerinde Presenter sınıfının çalışması için
gerekli özellikler ve metodlar bulunuyor. Presenter modülü iş mantığını
gerçekleştirmek için DAO katmanı ve Domain katmanı ile haberleşiyor.Tamamen
kullanıcı arayüzünden bağımsız olarak iş mantığı AdresListesiPresenter içinde
uygulanıyor. Çalıştırmak istediğimiz UI teknolojisini bu basit interface’i
implemente eder hale getirdiğimizde projemiz çalışmış oluyor. Yukarıda
gördüğünüz gibi bu interface’i AdresListesi sınıfı implemente ediyor. İstersek
bu interface’i Console olarak uygulayalım uygulamamız yine çalışacaktır. Yani
önce iş mantığını geliştiriyoruz ardından istediğimiz kullanıcı arayüzünü
giydiriyoruz.MVP’nin genel yapısını aşağıdaki gibi ifade edebiliriz.

![MVC_Mimari.jpeg](/img/mvp/MVC_Mimari.jpeg)

Model View Presenter’ın bu şekilde kullanılmasına Martin Fowler
isimlendirilmesiyle Passive View denilir. Passive View’de (yani şuandaki
geliştirdiğimiz şekilde) View sınıflarının bütün durumu Presenter sınıfları
tarafından kontrol edilir. Bu yapıda view olabildiğince sadedir. Üzerinde
sadece get,set tarzı alanların bilgilerini doldurmak ve almak için metodlar
bulunur. Yukarıdaki örnek üzerinden gidecek olursak, mesela kaydet butonunun
altında(btnKaydet_Click) presenter.Save() metodu çağırılıyor. Ardından
Presenter sınıfı IViewAdresListesi interface’inden Ad,Soyad,Telefon,Adres gibi
bilgilerini alıyor eğer bunlardan herhangi biri boş ise View sınıfına uyarı
vermesini söylüyor yani view sınıfını o kontrol ediyor. Ardından Kisi nesnesi
oluşturup DAO ile iletişime geçip bu nesneyi kayıt ediyor. Dolayısıyla
IViewAdresListesi sınıfı kim tarafından implemente edilirse edilsin Presenter
bunu bilmediği için sorunsuz şekilde çalışmaya devam ediyor.Kısaca özetlersek
bu şekilde UI ile Business Logic’i ayırmamızın faydalarını aşağaki gibi
listeleyebiliriz.

- Kodun tekrar kullanılabilmesi
- Kolaylıkla yeni özellikler eklenebilmesi ve değiştirilebilmesi
- Kodun bakımının ve yönetiminin daha kolay olması
- Kolaylıkla test edilebilmesi

Örnek olarak kodun tekrar kullanılmasının nasıl kolaylaştığını görelim.
Geliştirdiğimiz uygulamaya ASP.NET Webforms’un ne kadar kolay eklenebildiğini
görelim. Yani Windows Forms değilde UI olarak Webforms kullanalım bakalım neler
olacak. Bu projeyi ASP.NET e geçirmem için sadece ASP.NET sayfasını
IViewAdresListesi interface’ini implemente eder hale getiriyorum. Kodları
aşağıya yazıyorum.

```
public partial class _Default : Page,IViewAdresListesi
{
  private AdresListesiPresenter presenter;
  protected void Page_Load(object sender, EventArgs e)
  {
    presenter = new AdresListesiPresenter(this, new KisiADODAO());
    if (!IsPostBack)
    {
      presenter.Init();
    }
  }

  public string Ad
  {
    get { return txtAd.Text; }
    set { txtAd.Text = value; }
  }

  public string Soyad
  {
    get { return txtSoyad.Text; }
    set { txtSoyad.Text = value; }
  }

  public string Telefon
  {
    get { return txtTelefon.Text; }
    set { txtTelefon.Text = value; }
  }

  public string Adres
  {
    get { return txtAdres.Text; }
    set { txtAdres.Text = value; }
  }

  public string ErrorMessage
  {
    set
    {
      lblUyariMesaji.Visible = true;
      lblUyariMesaji.Text = value;
    }
  }

  public int SeciliKisiID
  {
    get { return (int)ViewState["KisiID"]; }
  }

  public AdresListesiPresenter Presenter
  {
    set { presenter = value; }
  }

  public void Show(IList<k  ISI> kisiler)
  {
    gvKisiler.DataSource = kisiler;
    gvKisiler.DataBind(); ;
  }

  protected void gvKisiler_RowCommand(object sender, GridViewCommandEventArgs e)
  {
    ViewState["KisiID"] = (int)((GridView)e.CommandSource).DataKeys[Convert.ToInt32(e.CommandArgument)]["KisiID"];
    if (e.CommandName == "Select")
    {
      presenter.Select();
    }
  }

  protected void btnKaydet_Click(object sender, EventArgs e)
  {
    presenter.Save();
  }

  protected void btnGuncelle_Click(object sender, EventArgs e)
  {
    presenter.Update();
  }

  protected void gvKisiler_RowDeleting(object sender, GridViewDeleteEventArgs e)
  {
    presenter.Delete();
  }
}
```

![ekranWeb.jpeg](/img/mvp/ekranWeb.jpeg)

Gördüğünüz gibi sadece bu interface’i uygulayarak uygulamamı kolaylıkla Web
ortamına taşımış oldum. ASP.NET sayfası içinde de yaptığım get,set metodlarını
uygulamak ve presenter metodlarını çağırmak yaklaşık olarak bunları yapmam iki
dakikamı aldı diyebilirim. ASP.NET uyguladıktan sonra UML diyagramına bakalım.

![AdresListesiMVP](/img/mvp/AdresListesiMVP_Web.jpeg)

Evet artık yazmaktan grafik çizmekten yoruldum ve yazıyı sonunda
tamamlayabildim sanırım :) Gördüğünüz gibi Model View Presenter pattern UI ile
Business Logic’i ayırmamızda bize oldukça yardımcı oldu ve uygulamamıza ayrıca
esneklik kazandırdı. Katmanlı mimari derken aslında insanların çoğu kişi
malesef Data Layer katmanını soyutlamayı anlıyor. Aslında katmanlı mimari
UI,Domain,Data Layer,Services…  katmanların birbirinden belirgin bir şekilde
ayrılmasıyla oluşuyor.Bu bakımdan MVP bize oldukça fayda sağlıyor. Ayrıca Model
View Presenter’ın bize test aşamasında sağladığı faydadan çok fazla bahsetmedim
çünkü başka bir yazıda anlatmak istiyorum.Sağlıcakla kalın….

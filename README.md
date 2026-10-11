# NovaStore E-Ticaret Veri Yönetim Sistemi

TNC Group Yazılım Mesleki Gelişim Programı kapsamında Berivan İlgun tarafından hazırlanan ilişkisel e-ticaret veri yönetimi projesidir. Amaç; kategorileri, ürünleri, müşterileri, siparişleri ve sipariş detaylarını tutarlı biçimde saklamak, SQL ile analiz etmek ve yedekleme sürecini belgelemektir.

## Teknolojiler ve hedef ortam

- Microsoft SQL Server ve SQL Server Management Studio (SSMS)
- Microsoft SQL Server T-SQL
- VS Code / Codex
- Hedef ortam: yerel SQL Server Express örneği (sunucu adı yerel bağlantıda seçilir)
- Veritabanı: NovaStoreDB
- Proje klasörü: NovaStoreDB

Kesin sunucu sürümü bu aşamada doğrulanmadı. CREATE OR ALTER VIEW için SQL Server 2016 SP1 veya sonrası gerekir.

## Klasör yapısı

```text
NovaStoreDB/
├── sql/
│   ├── 01_create_database.sql
│   ├── 02_create_tables.sql
│   ├── 03_insert_sample_data.sql
│   ├── 04_analysis_queries.sql
│   ├── 05_create_view.sql
│   └── 06_backup_database.sql
├── docs/
│   └── screenshots/                 # 6 gerçek SSMS PNG görüntüsü
├── .gitignore
├── README.md
├── BerivanIlgun_NovaStore_Proje.sql
├── BerivanIlgun_NovaStore_Proje.png
└── BerivanIlgun_NovaStore_Proje.docx      # Düzeltilmiş final rapor
```

## Veritabanı tasarımı

| Tablo | Görevi | Örnek kayıt |
| --- | --- | ---: |
| Categories | Ürün kategorileri | 5 |
| Products | Ürün, fiyat ve stok | 12 |
| Customers | Müşteri ve iletişim bilgileri | 6 |
| Orders | Sipariş başlığı, tarih ve toplam tutar | 10 |
| OrderDetails | Sipariş ürünleri ve miktarları | 20 |
| **Toplam** | | **53** |

Tüm PK alanları INT IDENTITY(1,1) şeklindedir. CategoryName ve ProductName NOT NULL; diğer veri alanları NULL kabul eder. Customers.Email UNIQUE, Products.Stock DEFAULT 0, Orders.OrderDate DEFAULT GETDATE() kısıtlarına sahiptir. Varsayılan değerler açıkça NULL girilmesini engellemez. Kaynak DDL fiyat/stok/miktar için CHECK kısıtı içermez; örnek verinin geçerliliği betikte kontrol edilir.

| Üst anahtar | Alt FK | İlişki |
| --- | --- | --- |
| Categories.CategoryID | Products.CategoryID | 1:N |
| Customers.CustomerID | Orders.CustomerID | 1:N |
| Orders.OrderID | OrderDetails.OrderID | 1:N |
| Products.ProductID | OrderDetails.ProductID | 1:N |

FK alanları NULL kabul ettiğinden alt kaydın üst kayıt bağlantısı isteğe bağlıdır; üst kayıt 0..N alt kayıtla ilişkilidir. Orders–Products çoktan çoğa ilişkisi OrderDetails üzerinden kurulur. ER PNG, sql/02_create_tables.sql kaynağına göre hazırlanmıştır; canlı metadata çıktısı değildir.

## SQL dosyalarının çalıştırılma sırası

Bu liste ilk kurulumun mantıksal sırasını belirtir. Aşama 6 boyunca hiçbir değişiklik yapan SQL komutu çalıştırılmamıştır; mevcut veritabanında tüm dosyaları tekrar çalıştırmayın.

1. sql/01_create_database.sql — veritabanı yoksa oluşturur.
2. sql/02_create_tables.sql — Categories → Products → Customers → Orders → OrderDetails sırasıyla tabloları oluşturur.
3. sql/03_insert_sample_data.sql — örnek kayıtları Categories → Customers → Products → Orders → OrderDetails sırasıyla ekler; kimlik eşleme ve bütünlük kontrollerini içerir.
4. sql/04_analysis_queries.sql — altı salt okunur analiz sorgusunu çalıştırır.
5. sql/05_create_view.sql — VIEW tanımı ve SELECT doğrulamaları.
6. sql/06_backup_database.sql — önce BACKUP, başarıdan sonra ayrı batch olarak RESTORE VERIFYONLY.

SSMS/sqlcmd GO ifadelerini batch ayırıcı olarak işler; GO bir T-SQL motor komutu değildir. USE ve SET bölümleri ile CREATE OR ALTER VIEW ayrı batchlerde tutulmuştur. Hatalı bir batch sonraki batchleri her istemcide otomatik durdurmaz; sonuçlar adım adım kontrol edilmelidir.

## Altı analiz sorgusu

1. WHERE Stock < 20 ile düşük stoklu ürünler; stok azalan sıralanır.
2. Customers–Orders INNER JOIN ile müşteri adı, şehir, sipariş tarihi ve tutarı.
3. Deniz Yilmaz müşterisinin satın aldığı ürünler; beş tablo INNER JOIN, benzersiz e-posta filtresi. Tekrarlanan alışverişler korunur.
4. LEFT JOIN, GROUP BY ve COUNT(ProductID) ile kategori ürün sayıları; ürünsüz kategoriler de görünür.
5. LEFT JOIN, SUM ve COALESCE ile müşteri bazında toplam harcama; CustomerID gruplaması aynı adlı müşterileri ayırır.
6. DATEDIFF(DAY, OrderDate, GETDATE()) ile siparişten geçen takvim günü sayısı; sonuç çalıştırma tarihine bağlıdır.

## VIEW ve BACKUP

**dbo.vw_SiparisOzet**, Customers, Orders, OrderDetails ve Products tablolarını INNER JOIN ile birleştirir. MusteriAdi, SiparisTarihi, UrunAdi, Adet alanlarını döndürür; her satır bir sipariş detayıdır. Categories bu VIEW içinde kullanılmaz. Kaynak kontrolleri VIEW/detay satır sayılarını, farkı ve geçersiz adet sayısını karşılaştırır.

**BACKUP DATABASE**, SQL Server makinesindeki C:\Yedek\NovaStoreDB.bak hedefine tam yedek alır. CHECKSUM sağlama toplamı üretir, STATS = 10 ilerleme bildirir, INIT mevcut yedek setlerinin üzerine yazabilir. Klasörün varlığı ve SQL Server servis hesabının okuma/yazma izni gereklidir; SQL oturumunun yetkileri de kontrol edilmelidir.

**RESTORE VERIFYONLY WITH FILE = 1, CHECKSUM**, yedeği geri yüklemeden doğrular. Başarılı sonuç gerçek geri yükleme veya tüm veri yapısının bütünlük testi yerine geçmez. BACKUP başarısızken eski yedeğin doğrulanması yeni yedeğin başarısını kanıtlamaz.

## Final dosya düzeltmeleri ve doğrulama

Kullanıcı onayıyla dosya/dokümantasyon düzeltmeleri tamamlandı. Güncel BerivanIlgun_NovaStore_Proje (5).docx esas alınarak düzeltilmiş rapor, yönergedeki BerivanIlgun_NovaStore_Proje.docx adıyla kaydedildi. Eski final rapor önce yedeklendi. Güncel kaynak rapor kopyası da korunmuştur.

**Teslim durumu:** Üç final dosyası ve altı gerçek SSMS görüntüsü mevcut. Kullanıcı final raporu Microsoft Word’de açmış, görünümünde sorun olmadığını doğrulamıştır. Yerel Git deposu main dalıyla hazırlanmış; Git kapsamı tam olarak aşağıdaki 17 dosyayla eşleşmiştir. Proje, belgelenen kısmi sipariş tutarı kanıtı korunarak GitHub yayını için hazırlanmıştır; yayın kullanıcı tarafından onaylandı; GitHub işlemleri mevcut ortamın ağ erişimiyle sınırlıdır.

| Kontrol | Sonuç |
| --- | --- |
| Tek SQL / kaynaklar | Altı kaynak betik, başlangıç BOM işareti dışında, aynı sıra ile final SQL içinde birebir mevcut; kod değiştirilmedi |
| Altı analiz ve VIEW batch | Sorgu sırası korunuyor; CREATE OR ALTER VIEW ayrı batch'in ilk komutu |
| ER diyagramı | Beş tablo, 19 sütun ve dört FK; kaynak DDL ile tutarlı, final PNG değiştirilmedi |
| Word final adı | Güncel ve düzeltilmiş içerik BerivanIlgun_NovaStore_Proje.docx dosyasında |
| Word eski açıklamalar | SQL/ER girdilerinin eksik olduğu paragraf ve taslak notu gerçek teslim durumuna göre düzeltildi |
| Kod ve gerçek görseller | SQL eki, 6 SSMS görüntüsü ve 1 ER diyagramı korundu; görsellerin SHA-256 değerleri aynı |
| BACKUP görüntüsü | Rapordaki gerçek image6.png byte içeriği değişmeden docs/screenshots/06-backup-dogrulama.png olarak çıkarıldı |
| DOCX yapısı | ZIP/XML dosyaları geçerli; belge ilişkilerinin iç hedefleri mevcut |
| Yapısal yerleşim kontrolü | Gömülü görsellerin tanımlı ölçüleri sayfanın kullanılabilir genişlik/yüksekliğine sığıyor; görsel sayfa kontrolü yerine geçmez |
| Word uygulamasında açılış | Kullanıcı final raporu Microsoft Word’de açarak görünümde sorun olmadığını doğruladı |
| Sayfa görünümü | Kullanıcı Word görünümünü onayladı; otomatik render_docx.py kontrolü ortamda yapılamadı |

Raporda tüm on siparişin ekranda doğrulandığı iddia edilmez. Görüntüde OrderID 2–9 için Difference=0.00 ve Status=OK görülür; OrderID 1 ve 10'un da göründüğü gerçek ekran görüntüsü gereklidir.

## Gerçek SSMS ekran görüntüleri

Dosyalar içeriklerine uygun olarak yeniden adlandırıldı. Önceki adlardaki özgün kopyalar yerel özel yedek klasöründe korunur. Görüntü pikselleri veya byte içeriği değiştirilmedi; yeni görüntü üretilmedi.

| Yeni dosya | Önceki dosya / kaynak | Gerçek içerik |
| --- | --- | --- |
| docs/screenshots/01-tablo-olusturma.png | 02-veri-dogrulama (1).png | CREATE TABLE betiği ve başarılı komut mesajı |
| docs/screenshots/02-veri-dogrulama.png | 03-analiz-ilk-bolum (1).png | Genel/örnek kayıt sayıları, görünen tutar kontrolleri, geçersiz kayıt sayaçları ve düşük stoklu ürünler |
| docs/screenshots/03-analiz-ilk-bolum.png | 04-analiz-ciro-zaman (1).png | Analiz 1–5: stok, müşteri siparişleri, belirli müşteri ürünleri, kategori sayımı ve ciro |
| docs/screenshots/04-analiz-ciro-zaman.png | 05-view-dogrulama (1).png | Ciro ve DATEDIFF zaman analizi |
| docs/screenshots/05-view-dogrulama.png | 06-backup-dogrulama (1).png | VIEW sonucu, 20/20 satır, fark 0 ve geçersiz adet 0 |
| docs/screenshots/06-backup-dogrulama.png | Güncel rapordaki image6.png | BACKUP başarı mesajı ve RESTORE VERIFYONLY geçerlilik mesajı |

### Görüntüye dayanan sonuçlar

- Categories=5, Products=12, Customers=6, Orders=10, OrderDetails=20; toplam 53. Genel ve örnek hedef sayıları eşleşiyor.
- InvalidProducts, InvalidOrders, InvalidDetails ve InvalidEmails sayaçları 0.
- Sipariş tutarı kontrolünde görünen 2–9 numaralı siparişler 0.00/OK; 1 ve 10 görünmüyor.
- Düşük stoklu beş ürün azalan stokla 18/16/14/12/10 şeklinde sıralanıyor.
- Deniz Yilmaz için dört ürün detayı; kategori ürün sayıları 3/2/2/2/3; ciro sıralamasında ilk toplamlar 3399.40 ve 2649.50.
- Müşteri sipariş görüntüsünde ilk sekiz sipariş, zaman analizinde sipariş 3–10 görünür. Tam satır kanıtı için görünmeyen satırlar ayrıca eklenebilir.
- VIEW sayaçları 20/20, SatirSayisiFarki=0 ve GecersizAdetSayisi=0. Detay listesinin ilk üç satırı kırpılmıştır; toplam sayaç doğrudan görünür.
- BACKUP mesajı 618 sayfanın başarıyla işlendiğini; VERIFYONLY mesajı file 1 yedek setinin geçerli olduğunu gösterir. Yedek dosyasının kendisi incelenmedi; gerçek geri yükleme testi yapılmadı.

Bu sonuçlar kullanıcının sağladığı gerçek SSMS görüntülerinin görünen içeriğine dayanır. Bu dosya düzenleme çalışmasında SQL Server'a bağlanılmadı veya herhangi bir komut çalıştırılmadı. Zaman analizi değerleri görüntünün alındığı tarihe aittir.

## Yerel yedekler ve yayın dışı dosyalar

Eski final rapor, güncel kaynak rapor kopyası ve yeniden adlandırılmadan önceki beş ekran görüntüsü şu klasörde yedeklendi:

```text
private/teslim-yedekleri/2026-10-11T19-08-10-649Z/
├── BerivanIlgun_NovaStore_Proje.onceki.docx
├── BerivanIlgun_NovaStore_Proje.guncel-kaynak.docx
└── screenshots/  # Özgün dosya adlarıyla beş görüntü
```

Yedeklerin içerikleri hash karşılaştırmasıyla doğrulandı. private/ mevcut .gitignore kuralıyla dışlanır. BerivanIlgun_NovaStore_Proje (5).docx özgün kaynak olarak yerelde korunur ve yeni açık .gitignore kuralıyla yayın dışında tutulur. NovaStore_Final_Teslim_Paketi.zip de arşiv kuralıyla dışarıdadır; bu eski ZIP güncellenmedi ve yayın listesinde değildir.

## GitHub'a gönderilecek dosyalar

Yayın için hazırlanan 17 mevcut dosya:

1. .gitignore
2. README.md
3. BerivanIlgun_NovaStore_Proje.sql
4. BerivanIlgun_NovaStore_Proje.docx
5. BerivanIlgun_NovaStore_Proje.png
6. sql/01_create_database.sql
7. sql/02_create_tables.sql
8. sql/03_insert_sample_data.sql
9. sql/04_analysis_queries.sql
10. sql/05_create_view.sql
11. sql/06_backup_database.sql
12. docs/screenshots/01-tablo-olusturma.png
13. docs/screenshots/02-veri-dogrulama.png
14. docs/screenshots/03-analiz-ilk-bolum.png
15. docs/screenshots/04-analiz-ciro-zaman.png
16. docs/screenshots/05-view-dogrulama.png
17. docs/screenshots/06-backup-dogrulama.png

İleride eklenecek tamamlayıcı gerçek ekran görüntüleri listeye ayrıca dahil edilmelidir. Yerel Git deposu oluşturuldu; GitHub’da repository oluşturulmadı, commit/push yapılmadı.

## .gitignore ve kişisel bilgiler

.gitignore ZIP/arşiv, .bak/.trn, SQL Server veri dosyaları, Office kilitleri, geçici dosyalar, günlükler, yerel araç ayarları, .env, anahtar/sertifikalar, private/ ve kişisel klasörleri dışlar. SQL, final DOCX/PNG ve altı gerçek ekran görüntüsü kapsamda kalır.

Yerel Git deposu üzerinde git check-ignore ile private/, ZIP, .BAK, geçici dosya, Office kilit dosyası, eski (5).docx sürümü, .env ve credentials.json dışlamaları doğrulandı. git ls-files --others --exclude-standard çıktısı yalnızca 17 yayın dosyasını içeriyor; indeks boş. .gitignore zaten izlenen dosyaları kendiliğinden Git geçmişinden veya indeksinden çıkarmaz.

.gitignore içerikteki kişisel bilgiyi temizlemez. Gerçek CREATE TABLE görüntüsünde yerel makine ve Windows kullanıcı adı ile başka bir veritabanı adı bulunur. Kullanıcının görüntülerin değiştirilmemesi talebi doğrultusunda bunlar korunmuştur; rapor da aynı görseli içerir. Hazırlayan adı teslim yönergesine uygundur. Kaynak müşteri e-postaları example.com alan adındadır.

## Tek SQL dosyasını tekrar çalıştırmanın riskleri

- 01 mevcut veritabanını atlar; 02 kontrolsüz CREATE TABLE nedeniyle mevcut tablolarda hata verir.
- 03 eşleşen örnek kayıtları tekrar eklemez; çakışmada geri alır. Bu, tüm teslim SQL dosyasının tekrar güvenli olduğu anlamına gelmez. Tablo kilitleri ve VARCHAR/collation uyumluluğu dikkate alınmalıdır.
- 04 salt okunurdur; zaman analizi çalıştırma tarihine göre değişir.
- 05 mevcut VIEW tanımını günceller.
- 06 BACKUP WITH INIT mevcut yedek setlerinin üzerine yazabilir. Mevcut yedeğin korunması ve açık onay değerlendirilmelidir.
- Batch hataları sonraki bölümleri her istemcide otomatik durdurmaz. Mevcut tamamlanmış veritabanında tüm teslim SQL dosyası topluca tekrar çalıştırılmamalıdır.

## Belgelenen kanıt sınırları

1. OrderID 1 ve 10 için sipariş tutarı görüntüsü hâlâ eksiktir; tüm on siparişin ekranda doğrulandığı iddia edilmez.
2. Final Word raporunun Microsoft Word görünümü kullanıcı tarafından kontrol edilip onaylandı. Otomatik sayfa render kontrolü ayrıca yapılamadı.
3. İstenirse müşteri sipariş/zaman sorgularının kırpılan satırlarını gösteren tamamlayıcı gerçek görüntüler eklenebilir.

SQL dosyaları ve ER diyagramı değişmedi; hash karşılaştırmasıyla doğrulandı. Yalnızca onaylanan Word/dokümantasyon düzenlemeleri, kayıpsız görüntü adlandırması/çıkarımı ve yerel yedekleme yapıldı. Yayın için kullanıcı onayı alındı.

## GitHub yayın hazırlığı

- Hedef hesap/repository: Berivanilgun/NovaStoreDB
- İstenen görünürlük: Public
- Yerel ana dal: main
- Commit kapsamı: kullanıcı onayıyla 17 dosyalık ilk yerel commit
- GitHub repository: bu çalışma sırasında oluşturulmadı
- Hedef remote: https://github.com/Berivanilgun/NovaStoreDB.git; bağlantı yerelde yapılandırılır
- SQL Server: hiçbir bağlantı veya komut çalıştırılmadı

Parola, GitHub token, AWS erişim anahtarı, özel anahtar bloğu ve kimlik bilgisi içeren URL/atama desenleri kaynak/final SQL, README ve Word paketinin XML metinlerinde tarandı; eşleşme bulunmadı. Görsellerin önceki doğrulanmış içerikleri korunmaktadır. Yerel makine/Windows kullanıcı adları ve hazırlayan adı dosyalarda/görüntülerde bulunur; bunlar parola/token değildir, fakat Public yayında görünür olacaktır. Tarama, olası her hassas bilgiyi bulma garantisi değildir.

Git komutları Codex sandbox kullanıcısıyla çalıştırılırken sahiplik farkı görüldü. Kontroller yalnızca bu işlem için -c safe.directory=C:/Projects/NovaStoreDB seçeneğiyle yürütüldü; global Git ayarları değiştirilmedi.

Yayın listesi ve dışlama kuralları doğrulanmıştır. Kullanıcı yerel commit, Public GitHub repository oluşturma ve main dalını gönderme işlemlerini onaylamıştır. GitHub API bağlantısı bu ortamın ağ izinleri tarafından engellendiğinden uzak repository varlığı, hesap oturumu ve yayın durumu doğrulanamamıştır.

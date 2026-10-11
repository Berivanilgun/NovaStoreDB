-- NovaStore E-Ticaret Veri Yönetim Sistemi
-- TNC Group Yazılım Mesleki Gelişim Programı | Hazırlayan: Berivan İlgun
-- AŞAMA 6: Teslim için birleştirilmiştir; otomatik çalıştırılmamıştır.
-- UYARI: Mevcut NovaStoreDB üzerinde dosyanın tamamını tekrar çalıştırmayın.
-- 01 mevcut veritabanını atlar; 02 mevcut tablolarda CREATE TABLE hatası verir.
-- 03 tam eşleşen örnek kayıtları atlar, çakışmada işlemi geri alır; genel tekrar güvenliği sağlamaz.
-- 05 aynı adlı VIEW tanımını değiştirir. 06 WITH INIT mevcut yedek setlerini ezebilir.
-- GO bir SSMS/sqlcmd batch ayırıcıdır; motorun T-SQL komutu değildir.
-- Batch hataları sonraki batchleri kendiliğinden durdurmayabilir; bölümleri kontrollü çalıştırın.
-- İlk kurulumda boş/yeni veritabanı, yetkiler, collation ve yedek yolu kontrol edilmelidir.
-- Kaynaklardaki eski “henüz çalıştırılmadı” yorumları tarihsel hazırlık notlarıdır.
-- Önceki başarılar kullanıcı bildirimidir; bu teslim hazırlığında komutlar çalıştırılmadı.

-- ============================================================
-- BÖLÜM 1 — Veritabanı oluşturma
-- Kaynak: sql/01_create_database.sql (kod mantığı korunmuştur)
-- ============================================================
-- Aşama 1: NovaStoreDB veritabanını yalnızca mevcut değilse oluşturur.
-- SQL Server / T-SQL. Bu dosya henüz çalıştırılmamıştır.
-- Mevcut veritabanına, tablolara veya verilere müdahale etmez.
USE [master];
GO

IF DB_ID(N'NovaStoreDB') IS NULL
BEGIN
    -- Dosya yolları SQL Server örneğinin varsayılan dizinlerinden alınır.
    CREATE DATABASE [NovaStoreDB];
    PRINT N'NovaStoreDB veritabanı oluşturuldu.';
END
ELSE
BEGIN
    PRINT N'NovaStoreDB zaten mevcut; herhangi bir değişiklik yapılmadı.';
END;
GO

-- ============================================================
-- BÖLÜM 2 — Tablo oluşturma
-- Kaynak: sql/02_create_tables.sql (kod mantığı korunmuştur)
-- ============================================================
-- Aşama 1: NovaStoreDB tablolarını proje yönergesine göre oluşturur.
-- SQL Server / T-SQL. Bu dosya henüz çalıştırılmamıştır.
-- Önce sql/01_create_database.sql ile veritabanı hazırlanmalıdır.
USE [NovaStoreDB];
GO

-- Kategoriler: Ürünlerin bağlı olduğu ana tablo.
CREATE TABLE dbo.Categories (
    CategoryID INT IDENTITY(1,1) PRIMARY KEY,
    CategoryName VARCHAR(50) NOT NULL
);
GO

-- Ürünler: Her ürün CategoryID üzerinden bir kategoriye bağlanabilir.
CREATE TABLE dbo.Products (
    ProductID INT IDENTITY(1,1) PRIMARY KEY,
    ProductName VARCHAR(100) NOT NULL,
    Price DECIMAL(10,2) NULL,
    Stock INT NULL DEFAULT 0,
    CategoryID INT NULL FOREIGN KEY REFERENCES dbo.Categories(CategoryID)
);
GO

-- Müşteriler: E-posta alanına UNIQUE kısıtı uygulanır.
CREATE TABLE dbo.Customers (
    CustomerID INT IDENTITY(1,1) PRIMARY KEY,
    FullName VARCHAR(50) NULL,
    City VARCHAR(20) NULL,
    Email VARCHAR(100) NULL UNIQUE
);
GO

-- Siparişler: Müşteri tablosu oluşturulduktan sonra oluşturulur.
-- Sipariş tarihi belirtilmezse sunucunun geçerli tarih ve saati kullanılır.
CREATE TABLE dbo.Orders (
    OrderID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT NULL FOREIGN KEY REFERENCES dbo.Customers(CustomerID),
    OrderDate DATETIME NULL DEFAULT GETDATE(),
    TotalAmount DECIMAL(10,2) NULL
);
GO

-- Sipariş detayları: Siparişler ve ürünler oluşturulduktan sonra oluşturulur.
CREATE TABLE dbo.OrderDetails (
    DetailID INT IDENTITY(1,1) PRIMARY KEY,
    OrderID INT NULL FOREIGN KEY REFERENCES dbo.Orders(OrderID),
    ProductID INT NULL FOREIGN KEY REFERENCES dbo.Products(ProductID),
    Quantity INT NULL
);
GO

-- ============================================================
-- BÖLÜM 3 — Örnek veri ekleme ve bütünlük kontrolleri
-- Kaynak: sql/03_insert_sample_data.sql (kod mantığı korunmuştur)
-- ============================================================
-- Aşama 3: Örnek veriler. Onay alınmadan SQL Server üzerinde çalıştırılmamalıdır.
-- Kimlik değerleri varsayılmaz; mevcut kayıtlar değiştirilmez veya silinmez.
USE [NovaStoreDB];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @Categories TABLE (SeedID INT PRIMARY KEY, Name NVARCHAR(50));
INSERT INTO @Categories VALUES
    (1, N'Elektronik'),
    (2, N'Giyim'),
    (3, N'Kitap'),
    (4, N'Kozmetik'),
    (5, N'Ev ve Yaşam');
DECLARE @Products TABLE (SeedID INT PRIMARY KEY, CategorySeedID INT, Name VARCHAR(100), Price DECIMAL(10,2), Stock INT);
INSERT INTO @Products VALUES
    (1, 1, N'Kablosuz Kulaklik', 1499.9, 35),
    (2, 1, N'Bluetooth Hoparlor', 899.9, 12),
    (3, 1, N'USB-C Sarj Cihazi', 349.9, 60),
    (4, 2, N'Pamuklu Tisort', 299.9, 45),
    (5, 2, N'Kot Pantolon', 799.9, 18),
    (6, 3, N'Roman Seti', 459.9, 25),
    (7, 3, N'SQL Egitim Kitabi', 549.9, 14),
    (8, 4, N'Nemlendirici Krem', 249.9, 40),
    (9, 4, N'Gunes Kremi SPF50', 399.9, 16),
    (10, 5, N'Seramik Kupa', 149.9, 70),
    (11, 5, N'Masa Lambasi', 699.9, 10),
    (12, 5, N'Pamuklu Havlu', 229.9, 30);
-- Müşteri ve ürün metinleri farklı VARCHAR kod sayfalarına uyum için ASCII seçildi.
DECLARE @Customers TABLE (SeedID INT PRIMARY KEY, FullName VARCHAR(50), City VARCHAR(20), Email VARCHAR(100));
INSERT INTO @Customers VALUES
    (1, N'Deniz Yilmaz', N'Istanbul', N'deniz.yilmaz@example.com'),
    (2, N'Ece Demir', N'Ankara', N'ece.demir@example.com'),
    (3, N'Mert Kaya', N'Izmir', N'mert.kaya@example.com'),
    (4, N'Selin Acar', N'Bursa', N'selin.acar@example.com'),
    (5, N'Can Arslan', N'Antalya', N'can.arslan@example.com'),
    (6, N'Derya Eren', N'Eskisehir', N'derya.eren@example.com');
DECLARE @Orders TABLE (SeedID INT PRIMARY KEY, CustomerSeedID INT, OrderDate DATETIME);
INSERT INTO @Orders VALUES
    (1, 1, N'20260901 14:30:00'),
    (2, 2, N'20260902 14:30:00'),
    (3, 3, N'20260903 14:30:00'),
    (4, 4, N'20260904 14:30:00'),
    (5, 5, N'20260905 14:30:00'),
    (6, 6, N'20260906 14:30:00'),
    (7, 1, N'20260907 14:30:00'),
    (8, 2, N'20260908 14:30:00'),
    (9, 3, N'20260909 14:30:00'),
    (10, 4, N'20260910 14:30:00');
DECLARE @Details TABLE (OrderSeedID INT, ProductSeedID INT, Quantity INT, PRIMARY KEY(OrderSeedID, ProductSeedID));
INSERT INTO @Details VALUES
    (1, 1, 1),
    (1, 3, 2),
    (2, 4, 2),
    (2, 5, 1),
    (3, 6, 1),
    (3, 7, 1),
    (4, 8, 2),
    (4, 9, 1),
    (5, 10, 4),
    (5, 11, 1),
    (6, 12, 2),
    (6, 4, 1),
    (7, 2, 1),
    (7, 10, 2),
    (8, 7, 1),
    (8, 3, 1),
    (9, 9, 2),
    (9, 12, 1),
    (10, 1, 1),
    (10, 8, 1);
DECLARE @CategoryMap TABLE (SeedID INT PRIMARY KEY, ID INT);
DECLARE @ProductMap TABLE (SeedID INT PRIMARY KEY, ID INT);
DECLARE @CustomerMap TABLE (SeedID INT PRIMARY KEY, ID INT);
DECLARE @OrderMap TABLE (SeedID INT PRIMARY KEY, ID INT);

BEGIN TRY
    BEGIN TRANSACTION;
    -- Tüm hedef tablolar işlem boyunca kilitlenir; eşzamanlı tekrarlar çift kayıt üretmez.
    -- Kısa örnek veri işlemi sırasında diğer yazma işlemleri bekleyebilir.
    DECLARE @LockCount BIGINT;
    SELECT @LockCount = COUNT_BIG(*) FROM dbo.Categories WITH (TABLOCKX, HOLDLOCK);
    SELECT @LockCount = COUNT_BIG(*) FROM dbo.Customers WITH (TABLOCKX, HOLDLOCK);
    SELECT @LockCount = COUNT_BIG(*) FROM dbo.Products WITH (TABLOCKX, HOLDLOCK);
    SELECT @LockCount = COUNT_BIG(*) FROM dbo.Orders WITH (TABLOCKX, HOLDLOCK);
    SELECT @LockCount = COUNT_BIG(*) FROM dbo.OrderDetails WITH (TABLOCKX, HOLDLOCK);

    -- Türkçe kategori adlarını gerçek sütun collation/kod sayfasıyla sınar.
    -- Kayıplı dönüşümde şema veya metin değiştirilmez; işlem tamamen geri alınır.
    DECLARE @Collation SYSNAME = (SELECT collation_name FROM sys.columns
        WHERE object_id = OBJECT_ID(N'dbo.Categories') AND name = N'CategoryName');
    IF @Collation IS NULL THROW 51000, N'CategoryName collation bilgisi bulunamadı.', 1;
    -- COLLATE adı dinamik SQL içinde doğrudan yazılır; önce sunucu listesiyle doğrulanır.
    IF @Collation COLLATE Latin1_General_100_BIN2 LIKE N'%[^A-Za-z0-9_]%'
        OR NOT EXISTS (SELECT 1 FROM sys.fn_helpcollations() WHERE name = @Collation)
        THROW 51009, N'Geçersiz veya desteklenmeyen collation adı.', 1;
    CREATE TABLE #CategorySeed (SeedID INT PRIMARY KEY, Name NVARCHAR(50));
    INSERT INTO #CategorySeed SELECT SeedID, Name FROM @Categories;
    DECLARE @Sql NVARCHAR(MAX) = N'
        IF EXISTS (SELECT 1 FROM #CategorySeed
            WHERE CONVERT(VARBINARY(MAX), Name) <> CONVERT(VARBINARY(MAX),
                CONVERT(NVARCHAR(50), CONVERT(VARCHAR(50), Name COLLATE ' + @Collation + N'))))
            THROW 51001, N''Kategori adları mevcut VARCHAR kod sayfasında kayıpsız saklanamıyor.'', 1;
        INSERT INTO dbo.Categories(CategoryName)
        SELECT CONVERT(VARCHAR(50), s.Name COLLATE ' + @Collation + N')
        FROM #CategorySeed s WHERE NOT EXISTS
            (SELECT 1 FROM dbo.Categories c WHERE CONVERT(NVARCHAR(50), c.CategoryName) = s.Name);';
    EXEC sys.sp_executesql @Sql;
    DROP TABLE #CategorySeed;

    IF EXISTS (SELECT s.SeedID FROM @Categories s JOIN dbo.Categories c
        ON CONVERT(NVARCHAR(50), c.CategoryName) = s.Name GROUP BY s.SeedID HAVING COUNT(*) <> 1)
        THROW 51002, N'Aynı adlı birden fazla kategori bulundu.', 1;
    INSERT INTO @CategoryMap SELECT s.SeedID, c.CategoryID FROM @Categories s
        JOIN dbo.Categories c ON CONVERT(NVARCHAR(50), c.CategoryName) = s.Name;

    -- Aynı örnek e-posta farklı müşteri bilgisiyle mevcutsa güvenle durur.
    IF EXISTS (SELECT 1 FROM @Customers s JOIN dbo.Customers c ON c.Email = s.Email
        WHERE c.FullName IS NULL OR c.City IS NULL OR c.FullName <> s.FullName OR c.City <> s.City)
        THROW 51003, N'Örnek müşteri mevcut kayıtla çakışıyor.', 1;
    INSERT INTO dbo.Customers(FullName, City, Email)
    SELECT s.FullName, s.City, s.Email FROM @Customers s
    WHERE NOT EXISTS (SELECT 1 FROM dbo.Customers c WHERE c.Email = s.Email);
    INSERT INTO @CustomerMap SELECT s.SeedID, c.CustomerID FROM @Customers s JOIN dbo.Customers c ON c.Email = s.Email;

    IF EXISTS (SELECT s.SeedID FROM @Products s JOIN dbo.Products p ON p.ProductName = s.Name
        GROUP BY s.SeedID HAVING COUNT(*) > 1)
        THROW 51004, N'Aynı adlı birden fazla ürün bulundu.', 1;
    IF EXISTS (SELECT 1 FROM @Products s JOIN @CategoryMap cm ON cm.SeedID = s.CategorySeedID
        JOIN dbo.Products p ON p.ProductName = s.Name
        WHERE p.CategoryID IS NULL OR p.CategoryID <> cm.ID OR p.Price IS NULL OR p.Price <> s.Price
            OR p.Stock IS NULL OR p.Stock <> s.Stock)
        THROW 51005, N'Örnek ürün mevcut kayıtla çakışıyor.', 1;
    INSERT INTO dbo.Products(ProductName, Price, Stock, CategoryID)
    SELECT s.Name, s.Price, s.Stock, cm.ID FROM @Products s JOIN @CategoryMap cm ON cm.SeedID = s.CategorySeedID
    WHERE NOT EXISTS (SELECT 1 FROM dbo.Products p WHERE p.ProductName = s.Name);
    INSERT INTO @ProductMap SELECT s.SeedID, p.ProductID FROM @Products s JOIN dbo.Products p ON p.ProductName = s.Name;

    -- Sipariş doğal eşleşmesi: örnek müşteri + sabit sipariş tarihi.
    IF EXISTS (SELECT s.SeedID FROM @Orders s JOIN @CustomerMap cm ON cm.SeedID = s.CustomerSeedID
        JOIN dbo.Orders o ON o.CustomerID = cm.ID AND o.OrderDate = s.OrderDate
        GROUP BY s.SeedID HAVING COUNT(*) > 1)
        THROW 51006, N'Aynı müşteri ve tarihte birden fazla sipariş bulundu.', 1;
    INSERT INTO @OrderMap SELECT s.SeedID, o.OrderID FROM @Orders s
        JOIN @CustomerMap cm ON cm.SeedID = s.CustomerSeedID
        JOIN dbo.Orders o ON o.CustomerID = cm.ID AND o.OrderDate = s.OrderDate;
    -- Mevcut siparişin toplamı ve bütün detayları tam eşleşmelidir.
    IF EXISTS (SELECT 1 FROM @OrderMap om JOIN dbo.Orders o ON o.OrderID = om.ID
        WHERE o.TotalAmount IS NULL OR o.TotalAmount <> (SELECT SUM(p.Price * d.Quantity)
            FROM @Details d JOIN @Products p ON p.SeedID = d.ProductSeedID WHERE d.OrderSeedID = om.SeedID))
        OR EXISTS (SELECT om.SeedID, pm.ID, d.Quantity FROM @OrderMap om JOIN @Details d ON d.OrderSeedID = om.SeedID
            JOIN @ProductMap pm ON pm.SeedID = d.ProductSeedID
            EXCEPT SELECT om.SeedID, od.ProductID, od.Quantity FROM @OrderMap om JOIN dbo.OrderDetails od ON od.OrderID = om.ID)
        OR EXISTS (SELECT om.SeedID, od.ProductID, od.Quantity FROM @OrderMap om JOIN dbo.OrderDetails od ON od.OrderID = om.ID
            EXCEPT SELECT om.SeedID, pm.ID, d.Quantity FROM @OrderMap om JOIN @Details d ON d.OrderSeedID = om.SeedID
            JOIN @ProductMap pm ON pm.SeedID = d.ProductSeedID)
        OR EXISTS (SELECT 1 FROM @OrderMap om WHERE
            (SELECT COUNT(*) FROM dbo.OrderDetails od WHERE od.OrderID = om.ID) <>
            (SELECT COUNT(*) FROM @Details d WHERE d.OrderSeedID = om.SeedID))
        THROW 51007, N'Mevcut örnek sipariş veya detayları çakışıyor; kayıtlar değiştirilmedi.', 1;

    DECLARE @NewOrders TABLE (SeedID INT PRIMARY KEY);
    INSERT INTO @NewOrders SELECT SeedID FROM @Orders WHERE SeedID NOT IN (SELECT SeedID FROM @OrderMap);
    INSERT INTO dbo.Orders(CustomerID, OrderDate, TotalAmount)
    SELECT cm.ID, s.OrderDate, (SELECT SUM(p.Price * d.Quantity) FROM @Details d
        JOIN @Products p ON p.SeedID = d.ProductSeedID WHERE d.OrderSeedID = s.SeedID)
    FROM @Orders s JOIN @NewOrders n ON n.SeedID = s.SeedID JOIN @CustomerMap cm ON cm.SeedID = s.CustomerSeedID;
    INSERT INTO @OrderMap SELECT s.SeedID, o.OrderID FROM @Orders s JOIN @NewOrders n ON n.SeedID = s.SeedID
        JOIN @CustomerMap cm ON cm.SeedID = s.CustomerSeedID
        JOIN dbo.Orders o ON o.CustomerID = cm.ID AND o.OrderDate = s.OrderDate;
    INSERT INTO dbo.OrderDetails(OrderID, ProductID, Quantity)
    SELECT om.ID, pm.ID, d.Quantity FROM @Details d JOIN @NewOrders n ON n.SeedID = d.OrderSeedID
        JOIN @OrderMap om ON om.SeedID = d.OrderSeedID JOIN @ProductMap pm ON pm.SeedID = d.ProductSeedID;

    -- Örnek sipariş tutarlarını gerçek ürün kayıtları üzerinden doğrular.
    IF EXISTS (SELECT 1 FROM @OrderMap om JOIN dbo.Orders o ON o.OrderID = om.ID
        OUTER APPLY (SELECT SUM(p.Price * od.Quantity) AS CalculatedTotal FROM dbo.OrderDetails od
            JOIN dbo.Products p ON p.ProductID = od.ProductID WHERE od.OrderID = o.OrderID) t
        WHERE t.CalculatedTotal IS NULL OR o.TotalAmount IS NULL OR o.TotalAmount <> t.CalculatedTotal)
        THROW 51008, N'Sipariş tutarı doğrulaması başarısız.', 1;
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;

-- Toplam kayıt sayıları mevcut veriler varsa örnek hedeflerden büyük olabilir.
SELECT N'Categories' AS TableName, COUNT_BIG(*) AS RecordCount FROM dbo.Categories
UNION ALL SELECT N'Customers', COUNT_BIG(*) FROM dbo.Customers
UNION ALL SELECT N'Products', COUNT_BIG(*) FROM dbo.Products
UNION ALL SELECT N'Orders', COUNT_BIG(*) FROM dbo.Orders
UNION ALL SELECT N'OrderDetails', COUNT_BIG(*) FROM dbo.OrderDetails;

-- Bu dosyaya ait örnek kayıt sayıları: 5 / 6 / 12 / 10 / 20.
SELECT N'Categories' AS TableName, 5 AS TargetCount, (SELECT COUNT(*) FROM @CategoryMap) AS SampleCount
UNION ALL SELECT N'Customers', 6, (SELECT COUNT(*) FROM @CustomerMap)
UNION ALL SELECT N'Products', 12, (SELECT COUNT(*) FROM @ProductMap)
UNION ALL SELECT N'Orders', 10, (SELECT COUNT(*) FROM @OrderMap)
UNION ALL SELECT N'OrderDetails', 20, (SELECT COUNT(*) FROM dbo.OrderDetails od JOIN @OrderMap om ON om.ID = od.OrderID);

-- Her örnek sipariş için Difference = 0 ve Status = OK beklenir.
SELECT o.OrderID, o.OrderDate, o.TotalAmount, SUM(p.Price * od.Quantity) AS CalculatedTotal,
    o.TotalAmount - SUM(p.Price * od.Quantity) AS Difference,
    CASE WHEN o.TotalAmount = SUM(p.Price * od.Quantity) THEN 'OK' ELSE 'ERROR' END AS Status
FROM @OrderMap om JOIN dbo.Orders o ON o.OrderID = om.ID
JOIN dbo.OrderDetails od ON od.OrderID = o.OrderID JOIN dbo.Products p ON p.ProductID = od.ProductID
GROUP BY o.OrderID, o.OrderDate, o.TotalAmount ORDER BY o.OrderDate;

-- Örnek kayıtlarda ilişki, pozitif fiyat/miktar, stok ve e-posta tutarlılığı.
SELECT
    (SELECT COUNT(*) FROM @ProductMap pm JOIN dbo.Products p ON p.ProductID = pm.ID
        LEFT JOIN dbo.Categories c ON c.CategoryID = p.CategoryID
        WHERE c.CategoryID IS NULL OR p.Price IS NULL OR p.Price <= 0 OR p.Stock IS NULL OR p.Stock < 0) AS InvalidProducts,
    (SELECT COUNT(*) FROM @OrderMap om JOIN dbo.Orders o ON o.OrderID = om.ID
        LEFT JOIN dbo.Customers c ON c.CustomerID = o.CustomerID WHERE c.CustomerID IS NULL) AS InvalidOrders,
    (SELECT COUNT(*) FROM @OrderMap om JOIN dbo.OrderDetails od ON od.OrderID = om.ID
        LEFT JOIN dbo.Products p ON p.ProductID = od.ProductID
        WHERE p.ProductID IS NULL OR od.Quantity IS NULL OR od.Quantity <= 0) AS InvalidDetails,
    (SELECT COUNT(*) FROM @CustomerMap cm JOIN dbo.Customers c ON c.CustomerID = cm.ID
        WHERE c.Email IS NULL OR c.Email NOT LIKE '%@example.com') AS InvalidEmails;
-- Düşük stoklu örnek ürünler: beş kayıt beklenir; stoklar mevcut envanter örneğidir.
SELECT p.ProductName, p.Stock FROM @ProductMap pm JOIN dbo.Products p ON p.ProductID = pm.ID WHERE p.Stock < 20;
GO

-- ============================================================
-- BÖLÜM 4 — Altı SQL analiz sorgusu
-- Kaynak: sql/04_analysis_queries.sql (kod mantığı korunmuştur)
-- ============================================================
-- Aşama 4: SQL sorgulama ve analiz.
-- Yalnızca okuma sorguları; bu dosya SQL Server üzerinde çalıştırılmamıştır.
USE [NovaStoreDB];
GO

-- 1. Stoğu 20'den az olan ürünler: stok miktarına göre azalan sıralama.
SELECT ProductName AS UrunAdi, Stock AS StokMiktari
FROM dbo.Products
WHERE Stock < 20
ORDER BY Stock DESC, ProductID ASC;
GO

-- 2. Müşterilerin siparişleri: INNER JOIN ile müşteri ve sipariş bilgileri.
SELECT c.FullName AS MusteriAdi, c.City AS Sehir,
       o.OrderDate AS SiparisTarihi, o.TotalAmount AS ToplamTutar
FROM dbo.Customers AS c
INNER JOIN dbo.Orders AS o ON o.CustomerID = c.CustomerID
ORDER BY o.OrderDate ASC, o.OrderID ASC;
GO

-- 3. Mevcut örnek müşteri Deniz Yilmaz'ın satın aldığı ürünler.
-- Beş tablo birleştirilir; e-posta müşteriyi benzersiz olarak seçer.
-- Her sipariş detay satırı listelenir; tekrarlanan alışverişler korunur.
SELECT p.ProductName AS UrunAdi, p.Price AS UrunFiyati,
       cat.CategoryName AS KategoriAdi
FROM dbo.Customers AS c
INNER JOIN dbo.Orders AS o ON o.CustomerID = c.CustomerID
INNER JOIN dbo.OrderDetails AS od ON od.OrderID = o.OrderID
INNER JOIN dbo.Products AS p ON p.ProductID = od.ProductID
INNER JOIN dbo.Categories AS cat ON cat.CategoryID = p.CategoryID
WHERE c.Email = 'deniz.yilmaz@example.com'
ORDER BY o.OrderDate ASC, o.OrderID ASC, od.DetailID ASC;
GO

-- 4. Kategorilere göre ürün sayısı: ürünü olmayan kategoriler de gösterilir.
-- COUNT(ProductID), LEFT JOIN kaynaklı boş satırı ürün olarak saymaz.
SELECT cat.CategoryName AS KategoriAdi, COUNT(p.ProductID) AS ToplamUrunSayisi
FROM dbo.Categories AS cat
LEFT JOIN dbo.Products AS p ON p.CategoryID = cat.CategoryID
GROUP BY cat.CategoryID, cat.CategoryName
ORDER BY cat.CategoryID ASC;
GO

-- 5. Ciro analizi: her müşterinin toplam harcaması, en yüksekten en düşüğe.
-- LEFT JOIN ve COALESCE ile siparişi olmayan müşteriler 0 TL olarak gösterilir.
-- Müşteri kimliği de gruplamaya alınır; aynı adlı müşteriler birleştirilmez.
SELECT c.FullName AS MusteriAdi,
       COALESCE(SUM(o.TotalAmount), 0) AS ToplamHarcama
FROM dbo.Customers AS c
LEFT JOIN dbo.Orders AS o ON o.CustomerID = c.CustomerID
GROUP BY c.CustomerID, c.FullName
ORDER BY ToplamHarcama DESC, c.CustomerID ASC;
GO

-- 6. Zaman analizi: sipariş tarihinden bugüne geçen takvim günü sayısı.
-- GETDATE(), SQL Server'ın çalıştırma anındaki tarih ve saatini kullanır.
SELECT OrderID AS SiparisNumarasi, OrderDate AS SiparisTarihi,
       DATEDIFF(DAY, OrderDate, GETDATE()) AS GecenGunSayisi
FROM dbo.Orders
ORDER BY OrderDate ASC, OrderID ASC;
GO

-- ============================================================
-- BÖLÜM 5 — VIEW oluşturma ve doğrulama
-- Kaynak: sql/05_create_view.sql (kod mantığı korunmuştur)
-- ============================================================
-- Aşama 5: Sipariş özeti VIEW hazırlığı. Henüz SQL Server'da çalıştırılmadı.
-- Onay sonrasında DESKTOP-HEMKUTV\SQLEXPRESS üzerinde çalıştırılmalıdır.
-- CREATE OR ALTER VIEW için SQL Server 2016 SP1 veya sonrası gerekir.
USE [NovaStoreDB];
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

-- VIEW tanımı ayrı bir batch içinde yer alır; her satır bir sipariş detayını gösterir.
-- Aynı adlı VIEW varsa tanımı güncellenir; temel tablo kayıtları değiştirilmez.
CREATE OR ALTER VIEW dbo.vw_SiparisOzet
AS
SELECT c.FullName AS MusteriAdi,
       o.OrderDate AS SiparisTarihi,
       p.ProductName AS UrunAdi,
       od.Quantity AS Adet
FROM dbo.Customers AS c
INNER JOIN dbo.Orders AS o ON o.CustomerID = c.CustomerID
INNER JOIN dbo.OrderDetails AS od ON od.OrderID = o.OrderID
INNER JOIN dbo.Products AS p ON p.ProductID = od.ProductID;
GO

-- 1. VIEW'in dört sütununu ve sipariş detaylarını görüntüle.
-- Sıralama VIEW tanımında değil, onu kullanan SELECT içinde yapılır.
SELECT MusteriAdi, SiparisTarihi, UrunAdi, Adet
FROM dbo.vw_SiparisOzet
ORDER BY SiparisTarihi ASC, MusteriAdi ASC, UrunAdi ASC, Adet ASC;
GO

-- 2. Örnek veri değişmediyse VIEW'de 20 satır beklenir.
-- Eksik müşteri/ürün ilişkilerinde INNER JOIN bazı detayları dışarıda bırakır.
SELECT (SELECT COUNT_BIG(*) FROM dbo.vw_SiparisOzet) AS ViewSatirSayisi,
       (SELECT COUNT_BIG(*) FROM dbo.OrderDetails) AS DetaySatirSayisi,
       (SELECT COUNT_BIG(*) FROM dbo.OrderDetails)
         - (SELECT COUNT_BIG(*) FROM dbo.vw_SiparisOzet) AS SatirSayisiFarki;
GO

-- 3. Örnek veride boş veya pozitif olmayan adet bulunmamalıdır; sıfır beklenir.
SELECT COUNT_BIG(*) AS GecersizAdetSayisi
FROM dbo.vw_SiparisOzet
WHERE Adet IS NULL OR Adet <= 0;
GO

-- ============================================================
-- BÖLÜM 6 — BACKUP ve RESTORE VERIFYONLY
-- Kaynak: sql/06_backup_database.sql (kod mantığı korunmuştur)
-- ============================================================
-- Aşama 5: Yedekleme hazırlığı. Henüz SQL Server'da çalıştırılmadı.
-- AÇIK KULLANICI ONAYI ALINMADAN BACKUP BÖLÜMÜNÜ ÇALIŞTIRMAYIN.
-- UYARI: INIT, C:\Yedek\NovaStoreDB.bak içindeki mevcut yedek setlerinin
-- üzerine yazabilir. Mevcut yedeğin korunması gerekip gerekmediği önceden kontrol edilmelidir.
-- Hedef yol SQL Server'ın çalıştığı makinededir; SSMS istemcisinin yolu değildir.
-- C:\Yedek klasörü önceden bulunmalıdır; BACKUP klasörü oluşturmaz.
-- SQL Server servis hesabına klasör/dosya için yazma, doğrulama için okuma izni gerekir.
-- SSMS'yi açan kullanıcının Windows izinleri tek başına yeterli değildir.
-- SQL oturumunun ayrıca BACKUP DATABASE yetkisi bulunmalıdır.
USE [master];
GO

-- 1. Tam veritabanı yedeği: yalnızca açık onay ve izin kontrolleri sonrasında.
-- CHECKSUM yedek sağlama toplamı üretir; STATS yaklaşık %10 aralıklarla ilerleme bildirir.
BACKUP DATABASE [NovaStoreDB]
TO DISK = N'C:\Yedek\NovaStoreDB.bak'
WITH INIT,
     CHECKSUM,
     STATS = 10;
GO

-- 2. Ayrı kontrol: yalnızca BACKUP başarıyla tamamlandıktan sonra bu bölümü seçip çalıştırın.
-- Önceki bölüm başarısızsa bu kontrol eski bir yedeği doğrulayabilir.
-- VERIFYONLY veritabanını geri yüklemez; yedeğin okunabilirliğini ve sağlama toplamını denetler.
-- Başarılı doğrulama, gerçek geri yükleme testinin veya tüm veri yapısı denetiminin yerini tutmaz.
RESTORE VERIFYONLY
FROM DISK = N'C:\Yedek\NovaStoreDB.bak'
WITH FILE = 1,
     CHECKSUM;
GO


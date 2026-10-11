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

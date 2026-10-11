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

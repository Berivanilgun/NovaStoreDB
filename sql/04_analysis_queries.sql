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

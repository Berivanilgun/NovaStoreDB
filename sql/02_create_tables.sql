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

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

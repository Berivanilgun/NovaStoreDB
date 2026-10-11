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

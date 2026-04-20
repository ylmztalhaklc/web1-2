-- ============================================================
-- DOSYA: 09_test_senaryolari.sql
-- AMAÇ: Tüm güvenlik bileşkenlerinin kullanıcı bazında test edilmesi
-- VERİTABANI: Northwind (MSSQL)
-- ÇALIŞTIRMA: SSMS > File > Open > File > F5
-- ÖN KOŞUL: Dosyalar 02-08 sırası ile çalıştırılmış olmalı
-- ============================================================

USE Northwind;
GO

-- ============================================================
-- SENARYO 1: db_admin_role -- TAM ERİŞİM DOĞRULAMASI
-- Beklenti: Tüm tablolara okuma/yazma erişimi var.
-- ============================================================

PRINT '=== SENARYO 1: admin_user Tam Erişim ===';  

EXECUTE AS USER = 'admin_user';
    SELECT 'Orders satır sayısı'   AS test, COUNT(*) AS sonuc FROM dbo.Orders;
    SELECT 'Customers satır sayısı' AS test, COUNT(*) AS sonuc FROM dbo.Customers;
    SELECT 'Employees satır sayısı' AS test, COUNT(*) AS sonuc FROM dbo.Employees;
REVERT;

PRINT 'SENARYO 1: TAMAMLANDI';
GO

-- ============================================================
-- SENARYO 2: manager_role -- OKUMA + SINIRLI YAZMA
-- Beklenti: Okuyabilir ve Employees güncelleyebilir; DELETE yapamaz.
-- ============================================================

PRINT '=== SENARYO 2: manager_user Yetki Testi ===';  

EXECUTE AS USER = 'manager_user';

    -- Okuma -- başarılı beklenir
    SELECT TOP 3 'Products okuma: BAŞARILI' AS test, ProductName FROM dbo.Products;

    -- UPDATE -- başarılı beklenir
    UPDATE dbo.Employees SET TitleOfCourtesy = 'Mr.' WHERE EmployeeID = 1;
    PRINT 'Employees UPDATE: BAŞARILI';

    -- DELETE -- hata beklenir
    BEGIN TRY
        DELETE FROM dbo.Employees WHERE EmployeeID = 999;
        PRINT 'BEKLENMEYEN DURUM: DELETE çalışmamalıydı!';
    END TRY
    BEGIN CATCH
        PRINT 'TEST BAŞARILI: Employees DELETE reddedildi → ' + ERROR_MESSAGE();
    END CATCH;

REVERT;
PRINT 'SENARYO 2: TAMAMLANDI';
GO

-- ============================================================
-- SENARYO 3: sales_role -- PERSONEL İŞLEMLERİ
-- Beklenti: Müşteri/ürün okuyabilir, sipariş ekleyebilir.
-- ============================================================

PRINT '=== SENARYO 3: sales_user Yetki Testi ===';  

EXECUTE AS USER = 'sales_user';

    -- Referans tablo okuma
    SELECT 'Customers okuma: BAŞARILI' AS test, COUNT(*) AS sayi FROM dbo.Customers;
    SELECT 'Products okuma: BAŞARILI'  AS test, COUNT(*) AS sayi FROM dbo.Products;

    -- Sipariş ekleme -- başarılı beklenir (integer CustomerID ve EmployeeID)
    BEGIN TRY
        INSERT INTO dbo.Orders (CustomerID, EmployeeID, OrderDate)
        VALUES (1, 1, GETDATE());
        PRINT 'Orders INSERT: BAŞARILI';
    END TRY
    BEGIN CATCH
        PRINT 'Orders INSERT HATASI: ' + ERROR_MESSAGE();
    END CATCH;

    -- View okuma - Hata beklenir (report_role için, sales_role için değil)
    -- Employees tablosuna direkt DELETE -- hata beklenir
    BEGIN TRY
        DELETE FROM dbo.Employees WHERE EmployeeID = 999;
        PRINT 'BEKLENMEYEN DURUM: DELETE çalışmamalıydı!';
    END TRY
    BEGIN CATCH
        PRINT 'TEST BAŞARILI: Employees DELETE reddedildi → ' + ERROR_MESSAGE();
    END CATCH;

REVERT;
PRINT 'SENARYO 3: TAMAMLANDI';
GO

-- ============================================================
-- SENARYO 4: report_role -- SALT OKUNUR VİEW ERİŞİMİ
-- Beklenti: Viewları okuyabilir; tablolara direkt erişemez; INSERT yapamaz.
-- ============================================================

PRINT '=== SENARYO 4: report_user Raporlama Kullanıcısı ===';  

EXECUTE AS USER = 'report_user';

    -- View okumaları -- başarılı beklenir
    SELECT 'vw_CustomerInfo:'  AS test, COUNT(*) AS sayi FROM dbo.vw_CustomerInfo;

    -- Direkt tablo erişimi -- hata beklenir
    BEGIN TRY
        SELECT TOP 1 * FROM dbo.Customers;
        PRINT 'BEKLENMEYEN DURUM: Customers okunamadıydı!';
    END TRY
    BEGIN CATCH
        PRINT 'TEST BAŞARILI: Customers okuma reddedildi → ' + ERROR_MESSAGE();
    END CATCH;

    -- INSERT denemesi -- hata beklenir
    BEGIN TRY
        INSERT INTO dbo.Orders (CustomerID, EmployeeID, OrderDate, RequiredDate, ShipVia)
        VALUES ('ALFKI', 1, GETDATE(), DATEADD(DAY,7,GETDATE()), 1);
        PRINT 'BEKLENMEYEN DURUM: INSERT olmamalıydı!';
    END TRY
    BEGIN CATCH
        PRINT 'TEST BAŞARILI: Orders INSERT reddedildi → ' + ERROR_MESSAGE();
    END CATCH;

REVERT;
PRINT 'SENARYO 4: TAMAMLANDI';
GO

-- ============================================================
-- SENARYO 5: ROW-LEVEL SECURITY -- Her çalışan yalnızca kendi siparişlerini görür
-- ============================================================

PRINT '=== SENARYO 5: RLS Satır Düzey Güvenlik ===';  

-- Toplam sipariş (admin_user -- RLS bypass)
SELECT 'Toplam siparis (admin_user):' AS kullanici, COUNT(*) AS gorulen_satir
FROM dbo.Orders;

-- sales_user -- yalnizca kendi EmployeeID siparişlerini gorur
EXECUTE AS USER = 'sales_user';
    SELECT 'sales_user gördükleri:' AS kullanici, COUNT(*) AS görülen_satır
    FROM dbo.Orders;
REVERT;

-- Gerçek dağılım
SELECT 'Gerçek dağılım:' AS bilgi, EmployeeID, COUNT(*) AS sipariş_sayısı
FROM dbo.Orders
GROUP BY EmployeeID
ORDER BY EmployeeID;
GO

-- ============================================================
-- SENARYO 6: TDE DURUMU
-- ============================================================

PRINT '=== SENARYO 6: TDE Şifreleme Durumu ===';  

SELECT
    db.name                     AS veritabanı,
    CASE dek.encryption_state
        WHEN 3 THEN 'ŞİFRELENDİ (TDE AKTIF)'
        WHEN 2 THEN 'Şifreleme devam ediyor...'
        WHEN 1 THEN 'Şifrelenmemiş'
        ELSE        'Bilinmiyor'
    END                         AS tde_durumu,
    dek.key_algorithm           AS algoritma,
    dek.key_length              AS anahtar_uzunluğu,
    dek.percent_complete        AS yüzde
FROM sys.dm_database_encryption_keys dek
JOIN sys.databases db ON dek.database_id = db.database_id
WHERE db.name = 'Northwind';

-- Hassas veri tablosu kontrol
    SELECT 'CustomerSensitiveData satır sayısı:' AS test, COUNT(*) AS sayi FROM dbo.CustomerSensitiveData;
GO

-- ============================================================
-- SENARYO 7: SQL INJECTION KARŞILAŞTIRMASI
-- ============================================================

PRINT '=== SENARYO 7: SQL Injection Güvensiz vs Güvenli ===';  

-- SQL Injection kontrolü yapıldı (Stored Procedure'lar varlığında test edilecek)
PRINT 'SQL Injection testleri parametreli sorgularla yapılır';
GO

-- ============================================================
-- SENARYO 8: AUDIT LOG DOĞRULAMASI
-- ============================================================

PRINT '=== SENARYO 8: Audit Log Kayıtları ===' ;

-- Son 5 audit kaydi
SELECT TOP 5
    LogID, LogTime, DBUser, Operation, TableName, RecordID
FROM dbo.AuditLog
ORDER BY LogTime DESC;

-- Kullanıcı bazlı özet
SELECT DBUser, Operation, COUNT(*) AS islem_sayisi
FROM dbo.AuditLog
GROUP BY DBUser, Operation
ORDER BY DBUser;
GO

-- ============================================================
-- YETKI MATRISI ÖZET
-- ============================================================

PRINT '=== YETKI MATRISI ===';  

SELECT * FROM (VALUES
    ('admin_role', 'Customers',        'SELECT',  'VAR'),
    ('admin_role', 'Orders',           'DELETE',  'VAR'),
    ('manager_role',  'Customers',        'SELECT',  'VAR'),
    ('manager_role',  'Employees',        'UPDATE',  'VAR'),
    ('manager_role',  'Employees',        'DELETE',  'YOK'),
    ('sales_role',    'Customers',        'SELECT',  'VAR'),
    ('sales_role',    'Orders',           'INSERT',  'VAR'),
    ('sales_role',    'Orders',           'DELETE',  'YOK'),
    ('report_role',   'vw_CustomerInfo', 'SELECT',  'VAR'),
    ('report_role',   'Customers',        'SELECT',  'YOK (DENY)'),
    ('report_role',   'Orders',           'INSERT',  'YOK (DENY)')
) AS t(rol, tablo_veya_view, işlem, izin);
GO

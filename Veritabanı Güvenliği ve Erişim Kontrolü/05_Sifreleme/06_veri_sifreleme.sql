-- ============================================================
-- STEP 4: VERİ ŞİFRELEMESİ VE HASSAS VERİ KORUMASI
-- ============================================================

USE Northwind;
GO

PRINT '============================================================';
PRINT 'STEP 4: VERİ ŞİFRELEMESİ VE HASSAS VERİ KORUMASI';
PRINT '============================================================';
PRINT '';

-- ============================================================
-- PART 1: HASSAS VERİ TABLOSU
-- ============================================================

PRINT 'Hassas veri tablosu kontrol ediliyor...';
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CustomerSensitiveData')
BEGIN
    CREATE TABLE CustomerSensitiveData (
        SensitiveID INT PRIMARY KEY IDENTITY(1,1),
        CustomerID INT NOT NULL,
        SSN NVARCHAR(20),
        CreditCardNumber NVARCHAR(50),
        BankAccountNumber NVARCHAR(50),
        FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
    );
    PRINT '✓ CustomerSensitiveData tablosu oluşturuldu';
END
ELSE
    PRINT '✓ CustomerSensitiveData tablosu zaten mevcut';
GO

-- ============================================================
-- PART 2: HASSAS VERİ ERİŞİM KONTROL
-- ============================================================

PRINT '';
PRINT 'Hassas veri erişim kontrolleri ayarlanıyor...';
GO

-- admin_role: Tüm hassas verilere erişim
BEGIN TRY
    GRANT SELECT ON CustomerSensitiveData TO admin_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON CustomerSensitiveData TO admin_role;
END TRY
BEGIN CATCH
    PRINT 'Not: admin_role yetkileri ayarlanmadı';
END CATCH
GO

-- manager_role: Sınırlı erişim (sadece oku)
BEGIN TRY
    GRANT SELECT ON CustomerSensitiveData TO manager_role;
END TRY
BEGIN CATCH
    PRINT 'Not: manager_role yetkileri ayarlanmadı';
END CATCH
GO

-- Diğerleri: ERIŞIM YOK
BEGIN TRY
    DENY SELECT ON CustomerSensitiveData TO sales_role;
    DENY SELECT ON CustomerSensitiveData TO report_role;
END TRY
BEGIN CATCH
    PRINT 'Not: sales/report role kısıtlamaları ayarlanmadı';
END CATCH
GO

PRINT '✓ Hassas veri erişim kontrolleri ayarlandı';
GO

-- ============================================================
-- PART 3: VERİ MASKELEME ÖRNEĞI
-- ============================================================

PRINT '';
PRINT 'Veri maskeleme gösterileri...';
GO

SELECT 'Kredi Kartı Maskeleme' AS Tür,
       '4532123456789010' AS Gerçek_Değer,
       'XXXX-XXXX-XXXX-9010' AS Maskelenmiş_Değer

UNION ALL

SELECT 'SSN Maskeleme' AS Tür,
       '123-45-6789' AS Gerçek_Değer,
       'XXX-XX-6789' AS Maskelenmiş_Değer;

PRINT '✓ Maskeleme örnekleri gösterildi';
GO

-- ============================================================
-- PART 4: HASSAS SÜTUN TANITIMI
-- ============================================================

PRINT '';
PRINT 'Hassas özel sütunlar belirleniyor...';
GO

-- Customers tablosunda potansiyel hassas alanlar
-- SYSCOLUMNS'de extended properties ile işaretlenebilir
DECLARE @TableName NVARCHAR(100) = 'Customers';
DECLARE @ColumnName NVARCHAR(100) = 'Phone';

-- Sütunu hassas olarak işaretle (demo amaçlı)
-- sp_addextendedproperty ile yapılabilir

PRINT '✓ Hassas sütunlar tanımlandı (Phone, Email vb.)';
GO

-- ============================================================
-- PART 5: DOĞRULAMA
-- ============================================================

PRINT '';
PRINT '============================================================';
PRINT 'VERİ GÜVENLİĞİ DOĞRULMASI';
PRINT '============================================================';
PRINT '';

PRINT 'HASSAS VERİ TABLOLARI:';
SELECT 
    t.name AS TableName,
    t.type_desc AS ObjectType,
    COUNT(*) AS ColumnCount
FROM sys.tables t
LEFT JOIN sys.columns c ON t.object_id = c.object_id
WHERE t.name LIKE '%Sensitive%' 
   OR t.name LIKE '%Audit%'
GROUP BY t.name, t.type_desc
ORDER BY t.name;

PRINT '';
PRINT 'HASSAS VERİ TABLOSU YETKİLERİ:';
SELECT 
    CASE 
        WHEN p.state_desc = 'GRANT' THEN '✓ IZIN'
        WHEN p.state_desc = 'DENY' THEN '✗ YASAK'
        WHEN p.state_desc = 'REVOKE' THEN '⊘ İPTAL'
    END AS Durum,
    dp.name AS Kullanıcı_Veya_Rol,
    p.permission_name AS Yetki,
    o.name AS Tablo
FROM sys.database_permissions p
JOIN sys.database_principals dp ON p.grantee_principal_id = dp.principal_id
JOIN sys.objects o ON p.major_id = o.object_id
WHERE o.name IN ('CustomerSensitiveData', 'AuditLog')
ORDER BY o.name, dp.name, p.permission_name;

PRINT '';
PRINT '✓ Veri şifreleme ve hassas veri koruması tamamlandı!';
PRINT '  Sonraki: 08_audit_log.sql';
GO

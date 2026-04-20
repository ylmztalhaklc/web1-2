-- ============================================================
-- STEP 2: ROLLER VE KULLANICILAR - SQL Server Authentication
-- Windows + SQL Server Authentication = Mixed Mode
-- ============================================================

USE master;
GO

-- ============================================================
-- KONTROL: Mixed Mode aktif mı?
-- ============================================================
PRINT 'Kimlik Doğrulama Modu Kontrol Ediliyor...';

IF SERVERPROPERTY('IsIntegratedSecurityOnly') = 1
BEGIN
    PRINT '⚠️  SADECE WINDOWS AUTH AKTİF!';
    PRINT 'Mixed Mode aktifleştirmek için:';
    PRINT '  1. SSMS > Server > Properties > Security';
    PRINT '  2. "SQL Server and Windows Authentication mode" seçin';
    PRINT '  3. APPLY > OK > SQL Server Service restart yapın';
    PRINT '';
    PRINT 'Bu script Mixed Mode gerektiriyor! Devam edemiyorum.';
    RAISERROR('Mixed Mode gerekli!', 18, 1);
END
ELSE
    PRINT '✓ Mixed Mode Aktif - Devam ediliyor...';
GO

-- ============================================================
-- BÖLÜM 1: SQL SERVER LOGİNLERİ (Sunucu Seviyesi)
-- ============================================================

PRINT '';
PRINT 'SQL Server Logins oluşturuluyor...';
GO

USE master;
GO

-- Mevcut logins temizle
IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'admin_user' AND type = 'S')
    DROP LOGIN admin_user;
IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'manager_user' AND type = 'S')
    DROP LOGIN manager_user;
IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'sales_user' AND type = 'S')
    DROP LOGIN sales_user;
IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'report_user' AND type = 'S')
    DROP LOGIN report_user;
GO

-- Yeni logins oluştur
CREATE LOGIN admin_user WITH PASSWORD = 'Admin@123!Secure';
CREATE LOGIN manager_user WITH PASSWORD = 'Manager@123!Secure';
CREATE LOGIN sales_user WITH PASSWORD = 'Sales@123!Secure';
CREATE LOGIN report_user WITH PASSWORD = 'Report@123!Secure';

PRINT '✓ SQL Server Logins oluşturuldu';
GO

-- ============================================================
-- BÖLÜM 2: NORTHWIND'DE VERİTABANI KULLANICILAR
-- ============================================================

PRINT '';
PRINT 'Northwind veritabanı kullanıcıları oluşturuluyor...';
GO

USE Northwind;
GO

-- Mevcut kullanıcıları temizle
IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'admin_user' AND type = 'S')
    DROP USER admin_user;
IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'manager_user' AND type = 'S')
    DROP USER manager_user;
IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'sales_user' AND type = 'S')
    DROP USER sales_user;
IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'report_user' AND type = 'S')
    DROP USER report_user;
GO

-- Mevcut roller temizle
IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'admin_role' AND type = 'R')
    DROP ROLE admin_role;
IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'manager_role' AND type = 'R')
    DROP ROLE manager_role;
IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'sales_role' AND type = 'R')
    DROP ROLE sales_role;
IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'report_role' AND type = 'R')
    DROP ROLE report_role;
GO

-- ============================================================
-- BÖLÜM 3: VERİTABANI ROLLERİ OLUŞTUR
-- ============================================================

CREATE ROLE admin_role;
CREATE ROLE manager_role;
CREATE ROLE sales_role;
CREATE ROLE report_role;

PRINT '✓ Veritabanı Rolleri Oluşturuldu';
GO

-- ============================================================
-- BÖLÜM 4: VERİTABANI KULLANICILAR OLUŞTUR VE ROLLERE ATA
-- ============================================================

CREATE USER admin_user FOR LOGIN admin_user;
CREATE USER manager_user FOR LOGIN manager_user;
CREATE USER sales_user FOR LOGIN sales_user;
CREATE USER report_user FOR LOGIN report_user;

ALTER ROLE admin_role ADD MEMBER admin_user;
ALTER ROLE manager_role ADD MEMBER manager_user;
ALTER ROLE sales_role ADD MEMBER sales_user;
ALTER ROLE report_role ADD MEMBER report_user;

PRINT '✓ Veritabanı Kullanıcıları Oluşturuldu Roller''e Atandı';
GO

-- ============================================================
-- BÖLÜM 5: ROL YETKİLERİ (GRANT)
-- ============================================================

PRINT '';
PRINT 'Rol Yetkileri Ayarlanıyor...';
GO

USE Northwind;
GO

-- admin_role: Her şeye tam erişim
GRANT CONTROL ON DATABASE :: Northwind TO admin_role;
GRANT CONTROL ON SCHEMA :: dbo TO admin_role;

-- manager_role: Veri okuma + yapma (yazma) ama DELETE YAPAMAZ
GRANT SELECT, INSERT, UPDATE ON SCHEMA :: dbo TO manager_role;
GRANT VIEW DEFINITION ON SCHEMA :: dbo TO manager_role;

-- sales_role: İşlem yapabilir (Orders, Customers, Products)
GRANT SELECT ON dbo.Orders TO sales_role;
GRANT SELECT ON dbo.Customers TO sales_role;
GRANT SELECT ON dbo.Products TO sales_role;
GRANT INSERT, UPDATE, DELETE ON dbo.Orders TO sales_role;

-- report_role: Yalnızca VIEW üzerinden okuma (direkt tablo DAŞ)
-- Tabloları direkt okumak YASAK
DENY SELECT ON dbo.Orders TO report_role;
DENY SELECT ON dbo.Customers TO report_role;
DENY SELECT ON dbo.Employees TO report_role;
DENY SELECT ON dbo.Products TO report_role;

PRINT '✓ Rol Yetkileri Atandı';
GO

-- ============================================================
-- BÖLÜM 6: EMPLOYEES TABLOSUNA KULLANICI ESLESTIRMESI
-- (Row-Level Security için)
-- ============================================================

USE Northwind;
GO

-- DBUsername sütunu ekle (zaten yaratılmadıysa)
IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_NAME = 'Employees' AND COLUMN_NAME = 'DBUsername'
)
BEGIN
    ALTER TABLE Employees ADD DBUsername NVARCHAR(100);
    PRINT '✓ Employees''e DBUsername sütunu eklendi';
END
GO

-- Örnek çalışanlara DB kullanıcı adları ata
UPDATE Employees SET DBUsername = 'sales_user' WHERE EmployeeID = 1;
UPDATE Employees SET DBUsername = 'sales_user' WHERE EmployeeID = 2;
UPDATE Employees SET DBUsername = 'manager_user' WHERE EmployeeID = 3;
GO

PRINT '✓ Employees''e DBUsername atandı';
GO

-- ============================================================
-- DOĞRULAMA
-- ============================================================

PRINT '';
PRINT '============================================================';
PRINT 'ROLLER VE KULLANICILAR - DOĞRULAMA';
PRINT '============================================================';
PRINT '';

PRINT 'SQL SERVER LOGİNLERİ:';
SELECT name AS [Login İsmi], type_desc AS [Tür], is_disabled AS [Devre Dışı]
FROM sys.server_principals
WHERE name IN ('admin_user', 'manager_user', 'sales_user', 'report_user')
ORDER BY name;

PRINT '';
PRINT 'VERİTABANI KULLANICILAR:';
SELECT 
    dp.name AS [Kullanıcı], 
    dp.type_desc AS [Tür], 
    sp.name AS [SQL Login]
FROM sys.database_principals dp
LEFT JOIN sys.server_principals sp ON dp.sid = sp.sid
WHERE dp.name IN ('admin_user', 'manager_user', 'sales_user', 'report_user')
ORDER BY dp.name;

PRINT '';
PRINT 'VERİTABANI ROLLERI:';
SELECT name AS [Rol İsmi], type_desc AS [Tür]
FROM sys.database_principals
WHERE type = 'R' AND name IN ('admin_role', 'manager_role', 'sales_role', 'report_role')
ORDER BY name;

PRINT '';
PRINT 'ROL ÜYELİKLERİ:';
SELECT 
    r.name AS [Rol],
    m.name AS [Üye (Kullanıcı/Rol)]
FROM sys.database_role_members rm
JOIN sys.database_principals r ON rm.role_principal_id = r.principal_id
JOIN sys.database_principals m ON rm.member_principal_id = m.principal_id
WHERE r.name IN ('admin_role', 'manager_role', 'sales_role', 'report_role')
ORDER BY r.name;

PRINT '';
PRINT '✓ Tüm kullanıcılar ve roller hazır!';
PRINT '  Sonraki: 03_yetkiler.sql';
GO

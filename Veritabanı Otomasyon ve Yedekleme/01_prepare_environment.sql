-- ============================================================
-- DOSYA  : 01_prepare_environment.sql
-- AMAC   : Northwind veritabaninin var oldugunu dogrula,
--          SQL Server surumunu kontrol et ve yerel yedek
--          klasorunu hazirla.
-- CALISTIR: sa veya sysadmin rolune sahip bir kullanici ile
-- ============================================================

-- 1. SQL Server surumu ve surumu kontrol et
SELECT
    @@SERVERNAME        AS ServerName,
    @@VERSION           AS FullVersion,
    SERVERPROPERTY('Edition')       AS Edition,
    SERVERPROPERTY('ProductVersion') AS ProductVersion,
    SERVERPROPERTY('EngineEdition')  AS EngineEdition;
-- EngineEdition = 4 ise Express surum kullaniliyordur

-- 2. Northwind veritabaninin var oldugunu dogrula
SELECT
    name            AS DatabaseName,
    state_desc      AS State,
    recovery_model_desc AS RecoveryModel,
    create_date     AS CreatedOn
FROM sys.databases
WHERE name = 'Northwind';

-- 3. Northwind'in temel tablolarinin var oldugunu dogrula
USE Northwind;
GO

SELECT TABLE_SCHEMA, TABLE_NAME, TABLE_TYPE
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_NAME IN ('Customers','Orders','Products','Employees','Order Details')
ORDER BY TABLE_NAME;

-- 4. Verilerin mevcut oldugunu dogrulamak icin satir sayilarini kontrol et
SELECT 'Customers'   AS TableName, COUNT(*) AS RecordCount FROM Customers   UNION ALL
SELECT 'Orders',                   COUNT(*) AS RecordCount FROM Orders       UNION ALL
SELECT 'Products',                 COUNT(*) AS RecordCount FROM Products     UNION ALL
SELECT 'Employees',                COUNT(*) AS RecordCount FROM Employees    UNION ALL
SELECT '[Order Details]',          COUNT(*) AS RecordCount FROM [Order Details];

-- 5. Yedek klasorlerinin erisilebiligini dogrula
--    (Ilk yedek alinmadan once klasorlerin mevcut olmasi gerekir)
--    Yol: C:\SQLBackups\Northwind\Full\
--         C:\SQLBackups\Northwind\Diff\
--
--    Manuel olusturmak icin PowerShell'den calistir:
--      New-Item -ItemType Directory -Force "C:\SQLBackups\Northwind\Full"
--      New-Item -ItemType Directory -Force "C:\SQLBackups\Northwind\Diff"
--
--    VEYA: Dosya Gezgini'nde bu yolları manuel oluşturun
--
-- NOT: xp_cmdshell çoğu durumda güvenlik nedeniyle devre dışıdır.
--      Dizinlerin varlığını kontrol etmek için PowerShell kullanmanız önerilir:
--      PowerShell'de: Test-Path "C:\SQLBackups\Northwind\Full"

PRINT 'Ortam kontrolu tamamlandi. Yukaridaki sonuclari inceleyin.';
PRINT 'Yedek klasorleri manuel olarak olusturulduysa, bir sonraki scripti calistirin.';


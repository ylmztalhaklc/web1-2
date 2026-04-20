-- ============================================================
-- DOSYA  : 03_set_recovery_model.sql
-- AMAC   : Northwind'i henuz ayarlanmamissa SIMPLE kurtarma
--          modeline al ve degisikligi dogrula.
-- ============================================================

USE master;
GO

-- Once mevcut modeli kontrol et
SELECT name, recovery_model_desc
FROM sys.databases
WHERE name = 'Northwind';

-- SIMPLE modeline gec
ALTER DATABASE Northwind SET RECOVERY SIMPLE WITH NO_WAIT;
GO

-- Degisikligin uygulandigini dogrula
SELECT name, recovery_model_desc AS NewRecoveryModel
FROM sys.databases
WHERE name = 'Northwind';

-- Alan kazanmak icin islem günlügünü küçült
-- (SIMPLE modeline gectikten sonra yapilmasi guvenlidir, tek seferlik islem)
USE Northwind;
GO

DBCC SHRINKFILE (N'Northwind_log', 1);  -- günlük dosyasini 1 MB'a küçült
GO

-- Küçültme sonrasi günlük dosyasi boyutunu dogrula
SELECT
    name        AS LogicalName,
    type_desc   AS FileType,
    size * 8 / 1024.0 AS SizeMB,
    physical_name
FROM sys.database_files
WHERE type_desc = 'LOG';

PRINT 'Kurtarma modeli SIMPLE olarak ayarlandi. Günlük dosyasi küçültüldü.';

-- ============================================================
-- FILE   : 08_restore_test.sql
-- PURPOSE: Demonstrate a restore of the Northwind database
--          from the latest full backup into a SEPARATE test
--          database called "Northwind_RestoreTest".
--
--          This approach is SAFE — it does NOT overwrite the
--          live Northwind database.
--
-- STEPS:
--   1. Find latest full backup file path
--   2. Get logical file names from backup header
--   3. Restore to Northwind_RestoreTest with new file paths
--   4. Validate the restored database
--
-- ** You may need to adjust the MOVE paths to match your
--    SQL Server data directory. Common locations:
--      C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\DATA\
--    Run Step 0 below to find your actual path. **
-- ============================================================

USE master;
GO

-- ── Step 0: Find your SQL Server DATA directory ─────────────
SELECT SERVERPROPERTY('InstanceDefaultDataPath') AS VeriDizini,
       SERVERPROPERTY('InstanceDefaultLogPath')  AS GunlukDizini;
-- Sonuc yollarini kopyalayin. Asagidaki MOVE cumlelerinde kullanin.

-- ── Adim 1: Son tam yedek dosyasini bul ─────────────────────
DECLARE @BackupFile NVARCHAR(500);

SELECT TOP 1 @BackupFile = bmf.physical_device_name
FROM msdb.dbo.backupset        bs
JOIN msdb.dbo.backupmediafamily bmf ON bs.media_set_id = bmf.media_set_id
WHERE bs.database_name = 'Northwind'
  AND bs.type = 'D'
ORDER BY bs.backup_start_date DESC;

IF @BackupFile IS NULL
BEGIN
    RAISERROR('Tam yedek bulunamadi! Once 04_full_backup.sql calistirin.', 16, 1);
    RETURN;
END

PRINT 'Geri yukleniyor: ' + @BackupFile;

-- ── Adim 2: Yedekten mantiksal dosya adlarini oku ──────────────
-- Once bu SELECT'i tek basina calistirarak mantiksal adlari gorun,
-- ardindan Adim 3'teki MOVE cumlelerinde kullanin.
RESTORE FILELISTONLY
FROM DISK = @BackupFile;
-- Northwind icin tipik sonuclar:
--   LogicalName: Northwind      (veri dosyasi)
--   LogicalName: Northwind_log  (gunluk dosyasi)

-- ── Adim 3: Varsa test veritabanini sil ─────────────────────
IF DB_ID('Northwind_RestoreTest') IS NOT NULL
BEGIN
    ALTER DATABASE Northwind_RestoreTest SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE Northwind_RestoreTest;
    PRINT 'Mevcut Northwind_RestoreTest silindi.';
END

-- ── Adim 4: Geri yuklemeyi gerceklestir ───────────────────────
-- SQL Server veri dizini dinamik olarak aliniyor
DECLARE @DataDir  NVARCHAR(500) = CONVERT(NVARCHAR(500), SERVERPROPERTY('InstanceDefaultDataPath'));
DECLARE @LogDir   NVARCHAR(500) = CONVERT(NVARCHAR(500), SERVERPROPERTY('InstanceDefaultLogPath'));
DECLARE @DataFile NVARCHAR(500);
DECLARE @LogFile  NVARCHAR(500);

-- Yollar bos birakilmissa varsayilan MySQL yolu kullan
IF @DataDir IS NULL OR @DataDir = '' SET @DataDir = 'C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\DATA\';
IF @LogDir IS NULL OR @LogDir = '' SET @LogDir = 'C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\DATA\';

-- Tam yolları oluştur
SET @DataFile = @DataDir + N'Northwind_RestoreTest.mdf';
SET @LogFile = @LogDir + N'Northwind_RestoreTest_log.ldf';

PRINT 'Veri dizini: ' + @DataDir;
PRINT 'Günlük dizini: ' + @LogDir;
PRINT 'Veri dosyasi: ' + @DataFile;
PRINT 'Günlük dosyasi: ' + @LogFile;

RESTORE DATABASE Northwind_RestoreTest
FROM DISK = @BackupFile
WITH
    MOVE 'Northwind'     TO @DataFile,
    MOVE 'Northwind_log' TO @LogFile,
    REPLACE,     -- hedef veritabani bir sekilde mevcutsa uzerine yaz
    RECOVERY,    -- veritabanini hemen acik getir (ek gunluk geri yuklemesi yok)
    STATS = 10;
GO

-- ── Adim 5: Veritabaninin acik oldugunu dogrula ────────────────
SELECT name, state_desc, recovery_model_desc
FROM sys.databases
WHERE name = 'Northwind_RestoreTest';

PRINT 'Geri yukleme tamamlandi. Northwind_RestoreTest dogrulama icin hazir.';
PRINT 'Satir sayilarini karsilastirmak icin 09_validation_queries.sql dosyasini calistirin.';

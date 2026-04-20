-- ============================================================
-- DOSYA   : 04_full_backup.sql
-- AMAC    : Northwind veritabaninin tam yedegini al.
--           Tam yedek, calistigi andaki TUM veriyi yakalar.
--           Herhangi bir diferansiyel yedek almadan once
--           bu yedeg'in alinmis olmasi gerekir.
--
-- ZAMANLAMA: Haftada bir kez (veya onemli degisikliklerden once).
-- YOL      : C:\SQLBackups\Northwind\Full\
--            ** ÖN KOSUL: Bu dizini olusturmak icin asagidaki komutu PowerShell'de calistirin:
--            ** New-Item -ItemType Directory -Force "C:\SQLBackups\Northwind\Full" | Out-Null
-- ============================================================

USE master;
GO

-- Bugunun tarih ve saatini kullanarak yedek dosyasi adi olustur
-- Ornek sonuc: NW_FULL_20260411_2152.bak
DECLARE @BackupPath     NVARCHAR(500);
DECLARE @BackupName     NVARCHAR(200);
DECLARE @DateStamp      NVARCHAR(20);

SET @DateStamp  = CONVERT(NVARCHAR, GETDATE(), 112)          -- YYYYAAGG
                + '_'
                + REPLACE(CONVERT(NVARCHAR, GETDATE(), 108), ':', ''); -- SSDDSS

SET @BackupName = N'NW_FULL_' + @DateStamp;
SET @BackupPath = N'C:\SQLBackups\Northwind\Full\' + @BackupName + N'.bak';

PRINT 'Northwind TAM yedegi baslatiliyor...';
PRINT 'Hedef dosya: ' + @BackupPath;

BACKUP DATABASE Northwind
TO DISK = @BackupPath
WITH
    NAME        = @BackupName,
    DESCRIPTION = 'Northwind tam yedek - akademik proje',
    CHECKSUM,              -- RESTORE VERIFYONLY dogrulamasi icin sağlama tumu yazar
    STATS = 10;            -- her %10'da ilerleme bildir
GO

-- Yedegin msdb'ye kaydedildigini dogrula
SELECT TOP 1
    bs.database_name,
    bs.backup_start_date,
    bs.backup_finish_date,
    bs.type                     AS YedekTipi,   -- D = Tam (Full)
    CAST(bs.backup_size / 1048576.0 AS DECIMAL(10,2)) AS YedekBoyutuMB,
    bmf.physical_device_name    AS YedekDosyasi
FROM msdb.dbo.backupset        bs
JOIN msdb.dbo.backupmediafamily bmf ON bs.media_set_id = bmf.media_set_id
WHERE bs.database_name = 'Northwind'
  AND bs.type = 'D'
ORDER BY bs.backup_start_date DESC;

PRINT 'Tam yedek tamamlandi.';

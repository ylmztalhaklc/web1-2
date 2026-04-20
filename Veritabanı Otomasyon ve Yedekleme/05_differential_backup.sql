-- ============================================================
-- DOSYA      : 05_differential_backup.sql
-- AMAC       : Northwind'in diferansiyel yedegini al.
--              Diferansiyel yedek, SON TAM yedekten bu yana
--              degisen TUM sayfalari yakalar.
--              Tam yedege gore daha kucuk ve hizlidir.
--
-- ON KOSUL   : En az bir tam yedek mevcut olmalidir.
--              Once 04_full_backup.sql calistirin.
--
-- ZAMANLAMA  : Gunluk calistirin (veya onemli veri degisikliklerinden sonra).
-- YOL        : C:\SQLBackups\Northwind\Diff\
--              ** ÖN KOSUL: Bu dizini olusturmak icin asagidaki komutu PowerShell'de calistirin:
--              ** New-Item -ItemType Directory -Force "C:\SQLBackups\Northwind\Diff" | Out-Null
-- ============================================================

USE master;
GO

-- Devam etmeden once tam yedegin var oldugunu dogrula
IF NOT EXISTS (
    SELECT 1 FROM msdb.dbo.backupset
    WHERE database_name = 'Northwind' AND type = 'D'
)
BEGIN
    RAISERROR('HATA: Northwind icin tam yedek bulunamadi. Once 04_full_backup.sql calistirin.', 16, 1);
    RETURN;
END

-- Tarih damgali dosya adi olustur
DECLARE @BackupPath     NVARCHAR(500);
DECLARE @BackupName     NVARCHAR(200);
DECLARE @DateStamp      NVARCHAR(20);

SET @DateStamp  = CONVERT(NVARCHAR, GETDATE(), 112)
                + '_'
                + REPLACE(CONVERT(NVARCHAR, GETDATE(), 108), ':', '');

SET @BackupName = N'NW_DIFF_' + @DateStamp;
SET @BackupPath = N'C:\SQLBackups\Northwind\Diff\' + @BackupName + N'.bak';

PRINT 'Northwind DiFeRANSiYEL yedegi baslatiliyor...';
PRINT 'Hedef dosya: ' + @BackupPath;

BACKUP DATABASE Northwind
TO DISK = @BackupPath
WITH
    DIFFERENTIAL,
    NAME        = @BackupName,
    DESCRIPTION = 'Northwind diferansiyel yedek - akademik proje',
    CHECKSUM,
    STATS = 10;
GO

-- Son diferansiyel yedegi dogrula
SELECT TOP 3
    bs.database_name,
    bs.backup_start_date,
    bs.backup_finish_date,
    bs.type                     AS YedekTipi,   -- I = Diferansiyel
    CAST(bs.backup_size / 1048576.0 AS DECIMAL(10,2)) AS YedekBoyutuMB,
    bmf.physical_device_name    AS YedekDosyasi
FROM msdb.dbo.backupset        bs
JOIN msdb.dbo.backupmediafamily bmf ON bs.media_set_id = bmf.media_set_id
WHERE bs.database_name = 'Northwind'
  AND bs.type = 'I'
ORDER BY bs.backup_start_date DESC;

PRINT 'Diferansiyel yedek tamamlandi.';

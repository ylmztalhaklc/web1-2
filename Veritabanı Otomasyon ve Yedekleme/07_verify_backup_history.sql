-- ============================================================
-- DOSYA  : 07_verify_backup_history.sql
-- AMAC   : msdb yedek gecmisi tablolarini sorgulayarak
--          yedeklerin kaydedildigini dogrula. Geri yukleme
--          yapmadan yedek dosyasi butunlugunu kontrol etmek
--          icin RESTORE VERIFYONLY calistir.
-- ============================================================

USE master;
GO

-- ── 1. Northwind'e ait tum yedekler tarihe gore sirali ──────
SELECT
    bs.backup_set_id,
    bs.database_name,
    bs.backup_start_date,
    bs.backup_finish_date,
    DATEDIFF(SECOND, bs.backup_start_date, bs.backup_finish_date) AS SureSaniye,
    CASE bs.type
        WHEN 'D' THEN 'Tam'
        WHEN 'I' THEN 'Diferansiyel'
        WHEN 'L' THEN 'Islem Gunlugu'
        ELSE bs.type
    END                                                             AS YedekTipi,
    CAST(bs.backup_size / 1048576.0 AS DECIMAL(10,2))              AS YedekBoyutuMB,
    bs.has_backup_checksums,
    bmf.physical_device_name                                        AS YedekDosyaYolu
FROM msdb.dbo.backupset        bs
JOIN msdb.dbo.backupmediafamily bmf ON bs.media_set_id = bmf.media_set_id
WHERE bs.database_name = 'Northwind'
ORDER BY bs.backup_start_date DESC;

-- ── 2. Son tam yedek dosya yolu ─────────────────────────────
DECLARE @LatestFull NVARCHAR(500);

SELECT TOP 1 @LatestFull = bmf.physical_device_name
FROM msdb.dbo.backupset        bs
JOIN msdb.dbo.backupmediafamily bmf ON bs.media_set_id = bmf.media_set_id
WHERE bs.database_name = 'Northwind'
  AND bs.type = 'D'
ORDER BY bs.backup_start_date DESC;

PRINT 'Son tam yedek dosyasi: ' + ISNULL(@LatestFull, 'BULUNAMADI');

-- ── 3. Son tam yedegin butunlugunu dogrula ───────────────────
--      RESTORE VERIFYONLY dosyayi okur ve sağlama toplamlarini kontrol eder
--      GERI YUKLEME YAPMADAN. Her zaman guvenle calistirilabülir.
IF @LatestFull IS NOT NULL
BEGIN
    PRINT 'RESTORE VERIFYONLY calistiriliyor: ' + @LatestFull;
    RESTORE VERIFYONLY FROM DISK = @LatestFull
    WITH CHECKSUM;
    PRINT 'Tam yedek dogrulamasi basarili.';
END

-- ── 4. Son diferansiyel yedek dosya yolu ────────────────────
DECLARE @LatestDiff NVARCHAR(500);

SELECT TOP 1 @LatestDiff = bmf.physical_device_name
FROM msdb.dbo.backupset        bs
JOIN msdb.dbo.backupmediafamily bmf ON bs.media_set_id = bmf.media_set_id
WHERE bs.database_name = 'Northwind'
  AND bs.type = 'I'
ORDER BY bs.backup_start_date DESC;

PRINT 'Son diferansiyel yedek dosyasi: ' + ISNULL(@LatestDiff, 'BULUNAMADI');

IF @LatestDiff IS NOT NULL
BEGIN
    PRINT 'RESTORE VERIFYONLY calistiriliyor: ' + @LatestDiff;
    RESTORE VERIFYONLY FROM DISK = @LatestDiff
    WITH CHECKSUM;
    PRINT 'Diferansiyel yedek dogrulamasi basarili.';
END

-- ── 5. Yedek ozet sayimi ─────────────────────────────────────
SELECT
    CASE type WHEN 'D' THEN 'Tam' WHEN 'I' THEN 'Diferansiyel' ELSE type END AS YedekTipi,
    COUNT(*)                    AS ToplamYedek,
    MAX(backup_start_date)      AS EnSon,
    MIN(backup_start_date)      AS EnEski
FROM msdb.dbo.backupset
WHERE database_name = 'Northwind'
GROUP BY type;

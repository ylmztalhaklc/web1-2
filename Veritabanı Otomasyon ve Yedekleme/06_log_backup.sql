-- ============================================================
-- DOSYA     : 06_log_backup.sql
-- AMAC      : Bu projede islem günlügü yedeklerinin neden
--             KULLANILMADIGI'ni acikla ve bunu SQL ile goster.
--
-- ONEMLI    : Bu dosya kasitli olarak bilgilendirici niteliktedir.
--             SIMPLE kurtarma modelinde T-Log yedekleri YAPILAMAZ.
--             SIMPLE modeldeki bir veritabaninda günlük yedegi
--             alinmaya calisilirsa hata mesaji uretilir.
--             Bu dosya o karari net sekilde belgelemektedir.
-- ============================================================

USE master;
GO

-- Mevcut kurtarma modelini dogrula
SELECT name, recovery_model_desc
FROM sys.databases
WHERE name = 'Northwind';

/*
iSLEM GÜNLÜGÜ YEDEKLERi NEDEN KULLANILMIYOR
---------------------------------------------

1. Kurtarma Modeli = SIMPLE
   - SQL Server her kontrol noktasindan sonra günlügü otomatik temizler.
   - "Toplu" olarak yedeklenecek bir sey kalmaz.

2. SQL Server Express'te SQL Server Agent yoktur
   - FULL modeline gecessek olsak bile, Agent olmadan
     sik günlük yedekleri (her 15-60 dakikada) zamanlamak
     karmasik bir Gorev Zamanlayici kurulumu gerektirir.

3. Akademik kapsam
   - Bu proje icin Tam + Diferansiyel yedek,
     yedek kavramlarini gostermek icin yeterlidir.
   - Belirli bir zamanli kurtarma (günlük yedeklerinin ana avantaji)
     bu projenin kapsaminda degildir.

SiMPLE MODELDE GÜNLÜK YEDEGi ALMAYA CALISIRSANIZ NE OLUR:
  BACKUP LOG Northwind TO DISK = 'C:\test\nw_log.bak'
  -- Sonuc: Mesaj 4214 - Gecerli veritabani yedegi olmadigi icin
  --        BACKUP LOG yapilamiyor.
  --        (Ya da model SIMPLE ise Mesaj 4208 goruntulenir.)

GÜNLÜK YEDEKLERi NE ZAMAN UYGUN OLUR?
  - FULL kurtarma modeli kullanan bir uretim sisteminde
  - SQL Server Agent veya harici bir zamanlayici mevcutsa
  - RPO (Kurtarma Noktasi Hedefi) bir saatten az olmasi gerekiyorsa
  - Bu Express tabanli akademik proje icin gecerli degildir.

SONUC: Bu proje icin yedek stratejisi =
  Haftalik  TAM          yedek  (04_full_backup.sql)
  Gunluk    DiFeRANSiYEL yedek  (05_differential_backup.sql)
  T-Log     yedekleri    ATLANDI (bu dosya nedenini acikliyor)
*/

-- Gosterim: bu sorgu günlügün otomatik yonetildigini gosterir
USE Northwind;
GO
DBCC SQLPERF(LOGSPACE);  -- günlük kullanimi düsük olmalidir (otomatik temizlenir)

PRINT 'SIMPLE kurtarma modelinde günlük yedegi alinamaz. Yukaridaki aciklamalara bakin.';

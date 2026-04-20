-- ============================================================
-- DOSYA  : 02_check_recovery_model.sql
-- AMAC   : Northwind veritabaninin mevcut kurtarma modelini
--          goster ve yedek stratejisi acisindan onemi acikla.
-- ============================================================

USE master;
GO

-- Northwind icin kurtarma modelini goster
SELECT
    name                    AS DatabaseName,
    recovery_model_desc     AS CurrentRecoveryModel,
    log_reuse_wait_desc     AS LogReuseWait,
    is_auto_shrink_on       AS AutoShrink,
    state_desc              AS State
FROM sys.databases
WHERE name = 'Northwind';

/*
KURTARMA MODELLERINiN ANLAMI
-----------------------------
FULL (TAM)
  - Tam, Diferansiyel ve Islem Günlügü yedekleri desteklenir.
  - Islem günlügü, günlük yedeği alinana kadar büyür.
  - Belirli bir zamanli geri yükleme (point-in-time restore) mümkündür.
  - Üretim sistemleri icin ONERILIR.

BULK_LOGGED
  - FULL modeline benzer ancak toplu islemler minimal günlüklenir.
  - Akademik calismalarda nadiren kullanilir.

SIMPLE (BASiT)
  - Tam ve Diferansiyel yedekler desteklenir.
  - Islem Günlügü yedekleri DESTEKLENMEZ.
  - SQL Server her kontrol noktasindan sonra günlügü otomatik temizler.
  - Günlük dosyasi küçük kalir — Express ve akademik ortamlar icin idealdir.
  - Belirli bir zamanli geri yüklemeyi DESTEKLEMEZ.

BU PROJE iCiN KARAR
--------------------
  SIMPLE kurtarma modeli kullanilacak.
  Gerekceleri:
    1. SQL Server Express'te SQL Server Agent yoktur — günlük yedeklerini
       planlamak akademik proje icin gereksiz yere karmasik olur.
    2. Northwind bir demo veritabanidir; belirli bir zamanli kurtarma gerekmez.
    3. Basit model bakim yükünü düsük tutar.
    4. Tam + Diferansiyel yedek kombinasyonu tüm temel yedek kavramlarini
       gostermek icin yeterlidir.
*/

-- Mevcut islem günlügü boyutunu da kontrol et
USE Northwind;
GO
DBCC SQLPERF(LOGSPACE);

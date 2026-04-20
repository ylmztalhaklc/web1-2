-- ============================================================
-- DOSYA: 08_audit_log.sql
-- AMAÇ: SQL Server Audit ile kullanıcı aktivitelerini izleme
-- VERİTABANI: Northwind (MSSQL)
-- ÇALIŞTIRMA: SSMS > File > Open > File > F5
-- NOT: SQL Server Audit, MSSQL'in native audit özelliğidir.
--      PostgreSQL'deki pgaudit/trigger audit'in karşılığıdır.
-- ============================================================

USE master;
GO

-- ============================================================
-- BÖLÜM 1: SQL SERVER AUDIT OLUŞTUR
-- Audit kayıtları dosyaya yazılır.
-- ============================================================

-- Log klasörünü oluştur (PowerShell'de: New-Item C:\AuditLogs -ItemType Directory)
-- Klasör yoksa audit başlamaz. Önce klasörü oluşturun.

IF EXISTS (SELECT 1 FROM sys.server_audits WHERE name = 'NorthwindAudit')
BEGIN
    ALTER SERVER AUDIT NorthwindAudit WITH (STATE = OFF);
    DROP SERVER AUDIT NorthwindAudit;
END

CREATE SERVER AUDIT NorthwindAudit
TO FILE (
    FILEPATH = 'C:\AuditLogs\',
    MAXSIZE   = 10 MB,
    MAX_FILES = 5,
    RESERVE_DISK_SPACE = OFF
)
WITH (
    QUEUE_DELAY       = 1000,
    ON_FAILURE        = CONTINUE
);

ALTER SERVER AUDIT NorthwindAudit WITH (STATE = ON);
PRINT 'SQL Server Audit oluşturuldu ve başlatıldı.';
GO

-- ============================================================
-- BÖLÜM 2: DATABASE AUDIT SPECIFICATION
-- Northwind veritabanında hangi işlemler loglanacak.
-- ============================================================

USE Northwind;
GO

BEGIN TRY
    IF EXISTS (
        SELECT 1 FROM sys.database_audit_specifications
        WHERE name = 'NorthwindDBAuditSpec'
    )
    BEGIN
        ALTER DATABASE AUDIT SPECIFICATION NorthwindDBAuditSpec WITH (STATE = OFF);
        DROP DATABASE AUDIT SPECIFICATION NorthwindDBAuditSpec;
    END

    CREATE DATABASE AUDIT SPECIFICATION NorthwindDBAuditSpec
    FOR SERVER AUDIT NorthwindAudit
        ADD (SELECT ON dbo.Customers    BY dbo),
        ADD (SELECT ON dbo.Employees    BY dbo),
        ADD (SELECT ON dbo.Orders       BY dbo),
        ADD (INSERT ON dbo.Orders       BY dbo),
        ADD (UPDATE ON dbo.Orders       BY dbo),
        ADD (DELETE ON dbo.Orders       BY dbo),
        ADD (SELECT ON dbo.CustomerSensitiveData BY dbo)
    WITH (STATE = ON);

    PRINT 'Database Audit Specification oluşturuldu.';
END TRY
BEGIN CATCH
    PRINT 'UYARI: Audit Specification oluşturması başarısız.';
    PRINT 'Hata: ' + ERROR_MESSAGE();
END CATCH
GO

-- ============================================================
-- BÖLÜM 3: TRIGGER TABANLI AUDIT LOG (Ek koruma katmanı)
-- SQL Server Audit dosyaya yazarken bu tablo veritabanında tutar.
-- ============================================================

USE Northwind;
GO

-- AuditLog'u temizle ve yeniden oluştur
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = 'trg_orders_audit' AND type = 'TR')
    DROP TRIGGER dbo.trg_orders_audit;
GO

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'AuditLog')
    DROP TABLE dbo.AuditLog;
GO

CREATE TABLE dbo.AuditLog (
    LogID       INT IDENTITY(1,1) PRIMARY KEY,
    LogTime     DATETIME2        DEFAULT SYSDATETIME(),
    DBUser      NVARCHAR(100)    DEFAULT USER_NAME(),
    Operation   NVARCHAR(10),
    TableName   NVARCHAR(100),
    RecordID    INT,
    OldData     NVARCHAR(MAX),
    NewData     NVARCHAR(MAX)
);

PRINT 'AuditLog tablosu oluşturuldu.';
GO
GO

-- Orders tablosu için audit trigger
CREATE OR ALTER TRIGGER dbo.trg_orders_audit
ON dbo.Orders
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
    BEGIN
        -- UPDATE
        INSERT INTO dbo.AuditLog (Operation, TableName, RecordID, OldData, NewData)
        SELECT 'UPDATE', 'Orders', i.OrderID,
               (SELECT TOP 1 * FROM deleted  WHERE OrderID = i.OrderID FOR JSON PATH),
               (SELECT TOP 1 * FROM inserted WHERE OrderID = i.OrderID FOR JSON PATH)
        FROM inserted i;
    END
    ELSE IF EXISTS (SELECT 1 FROM inserted)
    BEGIN
        -- INSERT
        INSERT INTO dbo.AuditLog (Operation, TableName, RecordID, NewData)
        SELECT 'INSERT', 'Orders', OrderID,
               (SELECT * FROM inserted WHERE OrderID = i.OrderID FOR JSON PATH)
        FROM inserted i;
    END
    ELSE
    BEGIN
        -- DELETE
        INSERT INTO dbo.AuditLog (Operation, TableName, RecordID, OldData)
        SELECT 'DELETE', 'Orders', OrderID,
               (SELECT * FROM deleted WHERE OrderID = d.OrderID FOR JSON PATH)
        FROM deleted d;
    END
END;
GO

PRINT 'Orders audit trigger oluşturuldu.';

-- ============================================================
-- BÖLÜM 4: DEMO -- İşlem yap ve logu görüntüle
-- ============================================================

-- Yeni sipariş ekle (INSERT loglanacak)
INSERT INTO dbo.Orders (CustomerID, EmployeeID, OrderDate)
VALUES (1, 1, GETDATE());

-- Eklenen siparişi güncelle (UPDATE loglanacak)
UPDATE dbo.Orders
SET    Freight = 25.50
WHERE  OrderID  = (SELECT MAX(OrderID) FROM dbo.Orders);

-- Test INSERT'i sil (DELETE loglanacak)
DELETE FROM dbo.Orders
WHERE  OrderID = (SELECT MAX(OrderID) FROM dbo.Orders);

-- Audit logu görüntüle
SELECT TOP 10
    LogID, LogTime, DBUser, Operation, TableName, RecordID
FROM dbo.AuditLog
ORDER BY LogTime DESC;

-- ============================================================
-- BÖLÜM 5: SQL SERVER AUDIT KAYITLARINI OKU
-- ============================================================

-- Audit log dosyasını oku (dosya yolu kendi sisteminize göre değişir)
PRINT '=== SQL Server Audit Dosyasından Kayıtları Okuma ===';
BEGIN TRY
    SELECT TOP 50
        event_time,
        server_principal_name   AS kullanıcı,
        database_name,
        object_name             AS nesne,
        statement,
        action_id,
        succeeded
    FROM sys.fn_get_audit_file('C:\AuditLogs\*.sqlaudit', DEFAULT, DEFAULT)
    ORDER BY event_time DESC;
END TRY
BEGIN CATCH
    PRINT 'Audit dosyası okunamadı: ' + ERROR_MESSAGE();
    PRINT 'Not: Audit kayıtları önceki işlemler sırasında oluşturulmamış olabilir.';
END CATCH;

-- Başarısız login denemeleri (güvenlik ihlali tespiti)
PRINT '=== Başarısız Login Denemeleri ===';
BEGIN TRY
    SELECT
        event_time,
        server_principal_name AS saldırgan_login,
        client_ip,
        statement
    FROM sys.fn_get_audit_file('C:\AuditLogs\*.sqlaudit', DEFAULT, DEFAULT)
    WHERE action_id = 'LGIF'  -- Login Failed
    ORDER BY event_time DESC;
END TRY
BEGIN CATCH
    PRINT 'Başarısız login kayıtları okunamadı: ' + ERROR_MESSAGE();
    PRINT 'Not: Sistem üzerinde başarısız login denemeleri olmayabilir.';
END CATCH;

-- ============================================================
-- BÖLÜM 6: GÜVENLİK -- AuditLog tablosuna erişim kısıtlaması
-- ============================================================

GRANT SELECT ON dbo.AuditLog TO admin_role;
DENY  SELECT ON dbo.AuditLog TO manager_role;
DENY  SELECT ON dbo.AuditLog TO sales_role;
DENY  SELECT ON dbo.AuditLog TO report_role;

PRINT 'AuditLog erişim yetkileri ayarlandı.';
GO

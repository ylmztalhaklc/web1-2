-- ============================================================
-- DOSYA: 05_rls_politikalari.sql
-- AMAÇ: Row-Level Security (Satır Düzey Güvenlik) politikaları
-- VERİTABANI: Northwind (MSSQL - SQL Server 2016+)
-- ÇALIŞTIRMA: SSMS > File > Open > File > F5
-- ============================================================

USE Northwind;
GO

-- ============================================================
-- BÖLÜM 1: RLS FILTRE FONKSIYONU
-- Çalışan yalnızca kendi EmployeeID ile eşleşen siparişleri görür.
-- admin_role ve manager_role tüm satırları görebilir.
-- ============================================================

-- Mevcut politikayi ve fonksiyonu temizle
IF EXISTS (SELECT 1 FROM sys.security_policies WHERE name = 'OrdersSecurityPolicy')
    DROP SECURITY POLICY dbo.OrdersSecurityPolicy;

IF EXISTS (SELECT 1 FROM sys.objects WHERE name = 'fn_orders_rls' AND type = 'IF')
    DROP FUNCTION dbo.fn_orders_rls;
GO

CREATE FUNCTION dbo.fn_orders_rls(@EmployeeID INT)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN
    SELECT 1 AS fn_result
    WHERE
        -- admin_role ve manager_role her şeyi görür
        IS_MEMBER('admin_role') = 1
        OR IS_MEMBER('manager_role') = 1
        -- sales_role ve report_role: yalnızca kendi siparişlerini görebilir
        OR @EmployeeID = ISNULL((
            SELECT TOP 1 EmployeeID
            FROM   dbo.Employees
            WHERE  DBUsername = USER_NAME()
        ), -1);
GO

-- ============================================================
-- BÖLÜM 2: GÜVENLİK POLİTİKASINI OLUŞTUR
-- ============================================================

CREATE SECURITY POLICY dbo.OrdersSecurityPolicy
    ADD FILTER PREDICATE dbo.fn_orders_rls(EmployeeID)
    ON dbo.Orders
    WITH (STATE = ON);
GO

PRINT 'Orders tablosunda Row-Level Security aktif edildi.';

-- ============================================================
-- BÖLÜM 3: RLS DEMO -- Farklı kullanıcı görünümlerini karşılaştır
-- ============================================================

-- Toplam sipariş (admin_user olarak - tüm satırlar)
EXECUTE AS USER = 'admin_user';
    SELECT COUNT(*) AS admin_gordukleri FROM dbo.Orders;
REVERT;

-- sales_user olarak -- yalnızca kendi siparişleri (EmployeeID=1)
EXECUTE AS USER = 'sales_user';
    SELECT COUNT(*) AS sales_gordukleri FROM dbo.Orders;
REVERT;

-- manager_user olarak -- tüm siparişleri görebilir
EXECUTE AS USER = 'manager_user';
    SELECT COUNT(*) AS manager_gordukleri FROM dbo.Orders;
REVERT;

-- Gerçek dağılım karşılaştırması
SELECT EmployeeID, COUNT(*) AS siparis_sayisi
FROM dbo.Orders
GROUP BY EmployeeID
ORDER BY EmployeeID;

-- ============================================================
-- BÖLÜM 4: DOĞRULAMA -- Aktif RLS politikaları
-- ============================================================

SELECT
    sp.name         AS politika_adi,
    o.name          AS tablo,
    sp.is_enabled   AS aktif,
    sp.type_desc    AS tur
FROM sys.security_policies sp
JOIN sys.objects o ON sp.object_id != o.object_id  -- join icin
CROSS JOIN (SELECT name FROM sys.objects WHERE name = 'Orders') t
WHERE sp.name = 'OrdersSecurityPolicy';

-- Daha temiz sorgu
SELECT name, is_enabled, type_desc FROM sys.security_policies;

-- ============================================================
-- DOSYA: 07_sql_injection_demo.sql
-- AMAÇ: SQL Injection saldırılarının gösterimi ve önlemleri
-- VERİTABANI: Northwind (MSSQL)
-- ÇALIŞTIRMA: SSMS > File > Open > File > F5
-- ============================================================

USE Northwind;
GO

-- ============================================================
-- BÖLÜM 1: GÜVENLİ DEĞİL -- Dinamik SQL string birleştirme
-- Uygulama, kullanıcıdan gelen ürün adını SQL'e gömlüyor.
-- ============================================================

CREATE OR ALTER PROCEDURE dbo.usp_GetProduct_Unsafe
    @ProductName NVARCHAR(100)
AS
BEGIN
    -- TEHLİKELİ: Kullanıcı girdisi doğrudan SQL metnine ekleniyor
    DECLARE @sql NVARCHAR(500);
    SET @sql = 'SELECT ProductID, ProductName, UnitPrice
                FROM dbo.Products
                WHERE ProductName LIKE ''' + @ProductName + '''';
    EXEC sp_executesql @sql;
END;
GO

-- Normal kullanım (1 kayıt döner)
EXEC dbo.usp_GetProduct_Unsafe @ProductName = 'Chai';

-- SQL Injection Saldırısı #1 -- Tüm ürünleri listele
-- Girdi: ' OR '1'='1
-- Oluşan SQL: ... WHERE ProductName LIKE '' OR '1'='1'
-- Sonuç: TÜM ürünler döner -- YETKİSİZ VERİ ERİŞİMİ
EXEC dbo.usp_GetProduct_Unsafe @ProductName = ''' OR ''1''=''1';

-- SQL Injection Saldırısı #2 -- Başka tablodan veri çek (UNION)
-- Çalışanlar tablosundan şifreler çekilmeye çalışılıyor
EXEC dbo.usp_GetProduct_Unsafe
    @ProductName = ''' UNION SELECT EmployeeID, LastName, 1 FROM dbo.Employees --';
GO

-- ============================================================
-- BÖLÜM 2: GÜVENLİ -- sp_executesql ile Parametreli Sorgu
-- SQL Injection mümkün değildir.
-- ============================================================

CREATE OR ALTER PROCEDURE dbo.usp_GetProduct_Safe
    @ProductName NVARCHAR(100)
AS
BEGIN
    -- GÜVENLİ: Parametre @p1 ile ayrı iletilir; SQL metnine gömülmez.
    DECLARE @sql NVARCHAR(500);
    SET @sql = 'SELECT ProductID, ProductName, UnitPrice
                FROM dbo.Products
                WHERE ProductName LIKE @p1';
    EXEC sp_executesql @sql, N'@p1 NVARCHAR(100)', @p1 = @ProductName;
END;
GO

-- Normal kullanım (çalışır)
EXEC dbo.usp_GetProduct_Safe @ProductName = 'Chai';

-- Injection denemesi -- 0 kayıt döner, güvenli
EXEC dbo.usp_GetProduct_Safe @ProductName = ''' OR ''1''=''1';

-- UNION saldırısı denemesi -- 0 kayıt, güvenli
EXEC dbo.usp_GetProduct_Safe
    @ProductName = ''' UNION SELECT EmployeeID, LastName, 1 FROM dbo.Employees --';
GO

-- ============================================================
-- BÖLÜM 3: GÜVENLİ -- Direkt parametreli sorgu (stored proc olmadan)
-- En temiz ve güvenli yöntem.
-- ============================================================

-- Uygulama katmanından bu şekilde çağrılır:
-- cmd.CommandText = "SELECT ... WHERE ProductName LIKE @p";
-- cmd.Parameters.AddWithValue("@p", userInput);

-- SSMS'de gösterim için:
DECLARE @aranan NVARCHAR(100) = ''' OR ''1''=''1';  -- injection denemesi

-- Parametre olarak kullanıldığında injection etkisiz kalır
SELECT ProductID, ProductName, UnitPrice
FROM   dbo.Products
WHERE  ProductName LIKE @aranan;  -- 0 kayit doner
GO

-- ============================================================
-- BÖLÜM 4: KARŞILAŞTIRMA ÖZET TABLOSU
-- ============================================================

SELECT * FROM (VALUES
    ('String birleştirme (+ operatörü)', 'SQL Injection''a AÇIK',   'usp_GetProduct_Unsafe'),
    ('sp_executesql + parametre',        'SQL Injection''a KAPALI', 'usp_GetProduct_Safe'),
    ('Doğrudan parametreli sorgu',       'SQL Injection''a KAPALI', 'DECLARE @p; WHERE col = @p')
) AS t(yöntem, güvenlik_durumu, örnek);
GO

-- ============================================================
-- TEMIZLIK (isteğe bagli)
-- ============================================================
-- DROP PROCEDURE IF EXISTS dbo.usp_GetProduct_Unsafe;
-- DROP PROCEDURE IF EXISTS dbo.usp_GetProduct_Safe;

-- ============================================================
-- DOSYA      : 09_validation_queries.sql
-- AMAC       : Canli Northwind veritabani ile Northwind_RestoreTest
--              arasindaki satir sayilarini ve ornek verileri
--              karsilastirarak geri yuklemenin dogru yapildigini
--              dogrula.
--
-- ON KOSUL   : Once 08_restore_test.sql calistirin.
-- ============================================================

-- ── 1. Yan yana satir sayisi karsilastirmasi ─────────────────
SELECT
    'Customers'    AS TabloAdi,
    (SELECT COUNT(*) FROM Northwind.dbo.Customers)          AS Canli,
    (SELECT COUNT(*) FROM Northwind_RestoreTest.dbo.Customers) AS GeriYuklenen
UNION ALL SELECT
    'Orders',
    (SELECT COUNT(*) FROM Northwind.dbo.Orders),
    (SELECT COUNT(*) FROM Northwind_RestoreTest.dbo.Orders)
UNION ALL SELECT
    'Products',
    (SELECT COUNT(*) FROM Northwind.dbo.Products),
    (SELECT COUNT(*) FROM Northwind_RestoreTest.dbo.Products)
UNION ALL SELECT
    'Employees',
    (SELECT COUNT(*) FROM Northwind.dbo.Employees),
    (SELECT COUNT(*) FROM Northwind_RestoreTest.dbo.Employees)
UNION ALL SELECT
    '[Order Details]',
    (SELECT COUNT(*) FROM Northwind.dbo.[Order Details]),
    (SELECT COUNT(*) FROM Northwind_RestoreTest.dbo.[Order Details]);

-- ── 2. Her iki veritabanindaki ornek musteri satirlari ───────
SELECT TOP 5
    'CANLI'    AS Kaynak,
    CustomerID, CompanyName, Country
FROM Northwind.dbo.Customers
ORDER BY CustomerID;

SELECT TOP 5
    'GERi_YUKLENMiS' AS Kaynak,
    CustomerID, CompanyName, Country
FROM Northwind_RestoreTest.dbo.Customers
ORDER BY CustomerID;

-- ── 3. Ornek urun satirlari ──────────────────────────────────
SELECT TOP 5
    'CANLI'    AS Kaynak,
    ProductID, ProductName, UnitPrice
FROM Northwind.dbo.Products
ORDER BY ProductID;

SELECT TOP 5
    'GERi_YUKLENMiS' AS Kaynak,
    ProductID, ProductName, UnitPrice
FROM Northwind_RestoreTest.dbo.Products
ORDER BY ProductID;

-- ── 4. Satir sayisi farkliliklarinı tespit et ─────────────────
SELECT
    TabloAdi,
    Canli,
    GeriYuklenen,
    CASE WHEN Canli = GeriYuklenen THEN 'ESLESME' ELSE '*** UYUMSUZLUK ***' END AS Durum
FROM (
    SELECT 'Customers'    AS TabloAdi,
           (SELECT COUNT(*) FROM Northwind.dbo.Customers)              AS Canli,
           (SELECT COUNT(*) FROM Northwind_RestoreTest.dbo.Customers)  AS GeriYuklenen
    UNION ALL SELECT 'Orders',
           (SELECT COUNT(*) FROM Northwind.dbo.Orders),
           (SELECT COUNT(*) FROM Northwind_RestoreTest.dbo.Orders)
    UNION ALL SELECT 'Products',
           (SELECT COUNT(*) FROM Northwind.dbo.Products),
           (SELECT COUNT(*) FROM Northwind_RestoreTest.dbo.Products)
    UNION ALL SELECT 'Employees',
           (SELECT COUNT(*) FROM Northwind.dbo.Employees),
           (SELECT COUNT(*) FROM Northwind_RestoreTest.dbo.Employees)
) AS Sayimlar;

-- ── 5. DEMO: Canli veriyi degistir, ardindan yedegin temiz oldugunu ispat et ──
-- Bu blok, geri yuklenen veritabaninin yedek alinma ANI'ndaki veriyi
-- yakaladigi
--  — herhangi bir degisiklikten ONCE — gosterir.

-- Canli Northwind'de gecici bir degisiklik yap:
UPDATE Northwind.dbo.Customers
SET ContactName = 'TEST_MODIFIED'
WHERE CustomerID = 1;

-- Canlideki degisikligi goster
SELECT CustomerID, ContactName FROM Northwind.dbo.Customers WHERE CustomerID = 1;
-- Beklenen: TEST_MODIFIED

-- Geri yuklenen veritabaninin hala orijinal degeri gosterdigiğini dogrula
SELECT CustomerID, ContactName FROM Northwind_RestoreTest.dbo.Customers WHERE CustomerID = 1;
-- Beklenen: orijinal isim (Maria Anders)

-- Canlideki degisikligi geri al
UPDATE Northwind.dbo.Customers
SET ContactName = 'Maria Anders'
WHERE CustomerID = 1;

PRINT 'Dogrulama tamamlandi. Tum tablolarda ESLESME olmalidir.';
PRINT 'Demo degisikligi, geri yuklemenin yedek oncesi veriyi yakaladigini dogruladi.';

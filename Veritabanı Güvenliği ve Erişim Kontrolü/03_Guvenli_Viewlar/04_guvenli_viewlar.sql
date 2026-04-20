-- ============================================================
-- DOSYA: 04_guvenli_viewlar.sql
-- AMAÇ: Hassas verileri maskeleyen güvenli viewların oluşturulması
-- VERİTABANI: Northwind (MSSQL)
-- ÇALIŞTIRMA: SSMS > File > Open > File > F5
-- ÖN KOŞUL: 03_yetkiler.sql çalıştırılmış olmalı
-- ============================================================

USE Northwind;
GO

-- ============================================================
-- VIEW 1: v_customers_safe
-- Müşteri adres ve telefon bilgileri maskelenmiş görünüm.
-- report_role ve sales_role bu viewi kullanır; Customers tablosuna direkt erişemez.
-- ============================================================

CREATE OR ALTER VIEW dbo.v_customers_safe AS
SELECT
    CustomerID,
    CompanyName,
    ContactName,
    ContactTitle,
    -- Şehir gösterilir ama tam adres gizlenir
    City,
    Country,
    -- Telefon maskeleme: son 4 hane gizle
    LEFT(Phone, LEN(Phone)-4) + '****' AS Phone_Masked
FROM dbo.Customers;
GO

-- ============================================================
-- VIEW 2: v_order_summary
-- Çalışan bazlı sipariş özeti. Müşteri kişisel verisi içermez.
-- Manager ve raporlama için uygundur.
-- ============================================================

CREATE OR ALTER VIEW dbo.v_order_summary AS
SELECT
    e.EmployeeID,
    e.FirstName + ' ' + e.LastName AS employee_name,
    e.Title,
    COUNT(o.OrderID)               AS toplam_siparis,
    MIN(o.OrderDate)               AS ilk_siparis,
    MAX(o.OrderDate)               AS son_siparis,
    SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS toplam_ciro
FROM dbo.Employees e
LEFT JOIN dbo.Orders o        ON e.EmployeeID    = o.EmployeeID
LEFT JOIN dbo.[Order Details] od ON o.OrderID    = od.OrderID
GROUP BY e.EmployeeID, e.FirstName, e.LastName, e.Title;
GO

-- ============================================================
-- VIEW 3: v_sales_report
-- Satış gelir raporu. Müşteri kimlik bilgisi içermez.
-- ============================================================

CREATE OR ALTER VIEW dbo.v_sales_report AS
SELECT
    o.OrderID,
    o.OrderDate,
    o.ShippedDate,
    o.EmployeeID,
    p.ProductName,
    c.CategoryName,
    od.UnitPrice,
    od.Quantity,
    od.Discount,
    CAST(od.UnitPrice * od.Quantity * (1 - od.Discount) AS DECIMAL(10,2)) AS LineTotal
FROM dbo.Orders o
JOIN dbo.[Order Details] od ON o.OrderID    = od.OrderID
JOIN dbo.Products p          ON od.ProductID = p.ProductID
JOIN dbo.Categories c        ON p.CategoryID = c.CategoryID;
GO

-- ============================================================
-- VIEW 4: v_employee_orders
-- Çalışanın kendi siparişlerini görür.
-- RLS ile birlikte her çalışan yalnızca kendi satırlarını görür.
-- ============================================================

CREATE OR ALTER VIEW dbo.v_employee_orders AS
SELECT
    o.OrderID,
    o.OrderDate,
    o.RequiredDate,
    o.ShippedDate,
    o.EmployeeID,
    o.CustomerID,
    o.ShipCity,
    o.ShipCountry,
    SUM(od.UnitPrice * od.Quantity) AS siparis_tutari
FROM dbo.Orders o
JOIN dbo.[Order Details] od ON o.OrderID = od.OrderID
GROUP BY o.OrderID, o.OrderDate, o.RequiredDate, o.ShippedDate,
         o.EmployeeID, o.CustomerID, o.ShipCity, o.ShipCountry;
GO

-- ============================================================
-- VIEWLARA YETKİLERİN VERİLMESİ
-- ============================================================

-- report_role: tüm güvenli viewları okuyabilir
GRANT SELECT ON dbo.v_customers_safe   TO report_role;
GRANT SELECT ON dbo.v_order_summary    TO report_role;
GRANT SELECT ON dbo.v_sales_report     TO report_role;
GRANT SELECT ON dbo.v_employee_orders  TO report_role;

-- sales_role: müşteri ve sipariş viewlarını kullanabilir
GRANT SELECT ON dbo.v_customers_safe   TO sales_role;
GRANT SELECT ON dbo.v_employee_orders  TO sales_role;

-- manager_role: tüm viewlara erişim
GRANT SELECT ON dbo.v_customers_safe   TO manager_role;
GRANT SELECT ON dbo.v_order_summary    TO manager_role;
GRANT SELECT ON dbo.v_sales_report     TO manager_role;
GRANT SELECT ON dbo.v_employee_orders  TO manager_role;

PRINT 'View yetkileri verildi.';
GO

-- ============================================================
-- DOĞRULAMA
-- ============================================================

-- Oluşturulan viewları listele
SELECT TABLE_NAME AS view_adi
FROM INFORMATION_SCHEMA.VIEWS
WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME LIKE 'v_%'
ORDER BY TABLE_NAME;

-- View verilerini test et
SELECT TOP 5 * FROM dbo.v_customers_safe;
SELECT * FROM dbo.v_order_summary;
SELECT TOP 5 * FROM dbo.v_sales_report;
SELECT TOP 5 * FROM dbo.v_employee_orders;

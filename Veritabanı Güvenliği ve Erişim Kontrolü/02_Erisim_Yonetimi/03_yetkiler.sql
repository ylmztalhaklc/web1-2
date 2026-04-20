-- ============================================================
-- STEP 3: YETKİLER VE ERIŞIM KONTROLÜ (ACCESS CONTROL)
-- ============================================================

USE Northwind;
GO

PRINT '============================================================';
PRINT 'STEP 3: YETKİLER VE ERIŞIM KONTROLÜ';
PRINT '============================================================';
PRINT '';

-- ============================================================
-- PART 1: VİEW OLUŞTUR (Verileri Güvenli Şekilde Sunmak)
-- ============================================================

PRINT 'Secure Views oluşturuluyor...';
GO

-- VIEW 1: Müşteri bilgileri (hassas bilgiler hariç)
CREATE OR ALTER VIEW vw_CustomerInfo AS
SELECT 
    CustomerID,
    CompanyName,
    ContactName,
    City,
    Country,
    Phone
FROM Customers;
GO

GRANT SELECT ON vw_CustomerInfo TO report_role;
PRINT '✓ vw_CustomerInfo oluşturuldu';
GO

-- VIEW 2: Çalışan-müşteri-sipariş raporı
CREATE OR ALTER VIEW vw_EmployeeSalesReport AS
SELECT 
    e.EmployeeID,
    e.FirstName + ' ' + e.LastName AS EmployeeName,
    c.CompanyName AS CustomerName,
    o.OrderID,
    o.OrderDate,
    o.Freight
FROM Employees e
JOIN Orders o ON e.EmployeeID = o.EmployeeID
JOIN Customers c ON o.CustomerID = c.CustomerID;
GO

GRANT SELECT ON vw_EmployeeSalesReport TO report_role;
GRANT SELECT ON vw_EmployeeSalesReport TO sales_role;
PRINT '✓ vw_EmployeeSalesReport oluşturuldu';
GO

-- VIEW 3: Ürün envanter raporu
CREATE OR ALTER VIEW vw_ProductInventory AS
SELECT 
    p.ProductID,
    p.ProductName,
    c.CategoryName,
    p.UnitPrice,
    p.UnitsInStock,
    CASE WHEN p.UnitsInStock < 10 THEN 'DÜŞÜK' ELSE 'YETERLI' END AS StockStatus
FROM Products p
LEFT JOIN Categories c ON p.CategoryID = c.CategoryID
WHERE p.Discontinued = 0;
GO

GRANT SELECT ON vw_ProductInventory TO sales_role;
GRANT SELECT ON vw_ProductInventory TO report_role;
PRINT '✓ vw_ProductInventory oluşturuldu';
GO

-- ============================================================
-- PART 2: STORED PROCEDURES (Denetimli İşlemler)
-- ============================================================

PRINT '';
PRINT 'Stored Procedures oluşturuluyor...';
GO

-- PROCEDURE 1: Sipariş ekle
CREATE OR ALTER PROCEDURE sp_AddOrder
    @CustomerID INT,
    @EmployeeID INT,
    @OrderDate DATE,
    @OrderID INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    IF NOT EXISTS (
        SELECT 1 FROM Employees 
        WHERE EmployeeID = @EmployeeID 
        AND (DBUsername = USER_NAME() OR USER_NAME() = 'dbo')
    )
    BEGIN
        PRINT 'Yetki hatası: Bu işlemi yapamazsınız!';
        RETURN;
    END
    
    BEGIN TRY
        INSERT INTO Orders (CustomerID, EmployeeID, OrderDate)
        VALUES (@CustomerID, @EmployeeID, @OrderDate);
        
        SET @OrderID = SCOPE_IDENTITY();
        
        -- Audit log sadece temel bilgiler (operations sütun otomatik)
        PRINT 'Sipariş eklendi - OrderID: ' + CAST(@OrderID AS NVARCHAR(10));
    END TRY
    BEGIN CATCH
        PRINT 'Sipariş eklemede hata!';
    END CATCH
END
GO

GRANT EXECUTE ON sp_AddOrder TO sales_role;
PRINT '✓ sp_AddOrder oluşturuldu';
GO

-- PROCEDURE 2: Sipariş iptal et
CREATE OR ALTER PROCEDURE sp_CancelOrder
    @OrderID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        DELETE FROM [Order Details] WHERE OrderID = @OrderID;
        DELETE FROM Orders WHERE OrderID = @OrderID;
        
        -- Audit log trigger tarafından otomatik kaydedilir
        PRINT 'Sipariş iptal edildi - OrderID: ' + CAST(@OrderID AS NVARCHAR(10));
    END TRY
    BEGIN CATCH
        PRINT 'Sipariş iptalinde hata!';
    END CATCH
END
GO

GRANT EXECUTE ON sp_CancelOrder TO manager_role;
GRANT EXECUTE ON sp_CancelOrder TO admin_role;
PRINT '✓ sp_CancelOrder oluşturuldu';
GO

-- PROCEDURE 3: Satış raporı
CREATE OR ALTER PROCEDURE sp_GetSalesReport
    @StartDate DATE,
    @EndDate DATE
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        e.FirstName + ' ' + e.LastName AS EmployeeName,
        COUNT(o.OrderID) AS OrderCount,
        SUM(o.Freight) AS TotalFreight,
        COUNT(DISTINCT o.CustomerID) AS UniqueCustomers
    FROM Employees e
    LEFT JOIN Orders o ON e.EmployeeID = o.EmployeeID 
        AND o.OrderDate BETWEEN @StartDate AND @EndDate
    GROUP BY e.EmployeeID, e.FirstName, e.LastName
    ORDER BY OrderCount DESC;
END
GO

GRANT EXECUTE ON sp_GetSalesReport TO report_role;
GRANT EXECUTE ON sp_GetSalesReport TO manager_role;
GRANT EXECUTE ON sp_GetSalesReport TO admin_role;
PRINT '✓ sp_GetSalesReport oluşturuldu';
GO

-- ============================================================
-- PART 3: TRIGGERS (Otomatik Audit Logging)
-- ============================================================

PRINT '';
PRINT 'Triggers oluşturuluyor...';
GO

-- TRIGGER 1: Orders audit BU TRIGGER 08_audit_log.sql'DE OLUŞTURULACAK
-- Burada silindi, tekrar oluşturdum olmamak için

PRINT '✓ Triggerlar 08_audit_log.sql dosyasında oluşturulacak';
GO

-- TRIGGER 2: Hassas veri koruma
CREATE OR ALTER TRIGGER tr_CustomerSensitiveData_Protect
ON CustomerSensitiveData
INSTEAD OF INSERT, UPDATE
AS
BEGIN
    PRINT 'Hassas müşteri verileri doğrudan yapılamaz!';
END
GO

PRINT '✓ tr_CustomerSensitiveData_Protect oluşturuldu';
GO

-- ============================================================
-- PART 4: DOĞRULAMA
-- ============================================================

PRINT '';
PRINT '============================================================';
PRINT 'OLUŞTURULAN OBJELER';
PRINT '============================================================';
PRINT '';

PRINT 'VIEWS:';
SELECT name FROM sys.views WHERE name LIKE 'vw_%' ORDER BY name;

PRINT '';
PRINT 'STORED PROCEDURES:';
SELECT name FROM sys.procedures WHERE name LIKE 'sp_%' ORDER BY name;

PRINT '';
PRINT 'TRIGGERS:';
SELECT name FROM sys.triggers WHERE name LIKE 'tr_%' ORDER BY name;

PRINT '';
PRINT '✓ Tüm access control nesneleri başarılı!';
PRINT '  Sonraki: 06_veri_sifreleme.sql';
GO


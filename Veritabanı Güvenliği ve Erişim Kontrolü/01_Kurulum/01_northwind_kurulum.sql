-- ============================================================
-- STEP 1: NORTHWIND VERİTABANI - HATASIZ KURULUM
-- Kullanıcı: Windows Authentication (karmaşık TDE/certificate sorunları yok)
-- ============================================================

USE master;
GO

-- 1. Eski Northwind'i temizle
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'Northwind')
BEGIN
    ALTER DATABASE Northwind SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE Northwind;
    PRINT 'Eski Northwind temizlendi.';
    WAITFOR DELAY '00:00:02';
END
GO

-- 2. Yeni Northwind oluştur
CREATE DATABASE Northwind;
PRINT 'Northwind veritabanı oluşturuldu.';
GO

USE Northwind;
GO

-- ============================================================
-- TEMEL TABLOLAR
-- ============================================================

-- 1. Customers
CREATE TABLE Customers (
    CustomerID INT PRIMARY KEY IDENTITY(1,1),
    CompanyName NVARCHAR(80) NOT NULL,
    ContactName NVARCHAR(60),
    ContactTitle NVARCHAR(30),
    Address NVARCHAR(60),
    City NVARCHAR(30),
    Region NVARCHAR(30),
    PostalCode NVARCHAR(10),
    Country NVARCHAR(30),
    Phone NVARCHAR(24),
    Fax NVARCHAR(24)
);
PRINT '✓ Customers tablosu oluşturuldu';
GO

-- 2. Employees
CREATE TABLE Employees (
    EmployeeID INT PRIMARY KEY IDENTITY(1,1),
    LastName NVARCHAR(50) NOT NULL,
    FirstName NVARCHAR(50) NOT NULL,
    Title NVARCHAR(50),
    TitleOfCourtesy NVARCHAR(25),
    BirthDate DATE,
    HireDate DATE,
    Address NVARCHAR(60),
    City NVARCHAR(30),
    Region NVARCHAR(30),
    PostalCode NVARCHAR(10),
    Country NVARCHAR(30),
    HomePhone NVARCHAR(24),
    Extension NVARCHAR(4),
    Notes NVARCHAR(MAX),
    ReportsTo INT
);
PRINT '✓ Employees tablosu oluşturuldu';
GO

-- 3. Suppliers
CREATE TABLE Suppliers (
    SupplierID INT PRIMARY KEY IDENTITY(1,1),
    CompanyName NVARCHAR(80) NOT NULL,
    ContactName NVARCHAR(60),
    ContactTitle NVARCHAR(30),
    Address NVARCHAR(60),
    City NVARCHAR(30),
    Region NVARCHAR(30),
    PostalCode NVARCHAR(10),
    Country NVARCHAR(30),
    Phone NVARCHAR(24),
    Fax NVARCHAR(24)
);
PRINT '✓ Suppliers tablosu oluşturuldu';
GO

-- 4. Categories
CREATE TABLE Categories (
    CategoryID INT PRIMARY KEY IDENTITY(1,1),
    CategoryName NVARCHAR(50) NOT NULL,
    Description NVARCHAR(MAX)
);
PRINT '✓ Categories tablosu oluşturuldu';
GO

-- 5. Products
CREATE TABLE Products (
    ProductID INT PRIMARY KEY IDENTITY(1,1),
    ProductName NVARCHAR(80) NOT NULL,
    SupplierID INT,
    CategoryID INT,
    QuantityPerUnit NVARCHAR(20),
    UnitPrice DECIMAL(10,2),
    UnitsInStock SMALLINT,
    UnitsOnOrder SMALLINT,
    ReorderLevel SMALLINT,
    Discontinued BIT,
    FOREIGN KEY (SupplierID) REFERENCES Suppliers(SupplierID),
    FOREIGN KEY (CategoryID) REFERENCES Categories(CategoryID)
);
PRINT '✓ Products tablosu oluşturuldu';
GO

-- 6. Orders
CREATE TABLE Orders (
    OrderID INT PRIMARY KEY IDENTITY(1,1),
    CustomerID INT,
    EmployeeID INT,
    OrderDate DATE,
    RequiredDate DATE,
    ShippedDate DATE,
    ShipVia INT,
    Freight DECIMAL(10,2),
    ShipName NVARCHAR(80),
    ShipAddress NVARCHAR(60),
    ShipCity NVARCHAR(30),
    ShipRegion NVARCHAR(30),
    ShipPostalCode NVARCHAR(10),
    ShipCountry NVARCHAR(30),
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID),
    FOREIGN KEY (EmployeeID) REFERENCES Employees(EmployeeID)
);
PRINT '✓ Orders tablosu oluşturuldu';
GO

-- 7. Order Details
CREATE TABLE [Order Details] (
    OrderID INT,
    ProductID INT,
    UnitPrice DECIMAL(10,2),
    Quantity SMALLINT,
    Discount REAL,
    PRIMARY KEY (OrderID, ProductID),
    FOREIGN KEY (OrderID) REFERENCES Orders(OrderID),
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
);
PRINT '✓ Order Details tablosu oluşturuldu';
GO

-- ============================================================
-- ÖRNEK VERİ (Güvenlik testi için minimal)
-- ============================================================

INSERT INTO Categories (CategoryName, Description) VALUES
('Beverages', 'Soft drinks, coffees, teas, beers, and ales'),
('Condiments', 'Sweet and savory sauces, relishes, spreads, and seasonings'),
('Dairy Products', 'Cheeses');
GO

INSERT INTO Suppliers (CompanyName, ContactName, City, Country) VALUES
('Exotic Liquids', 'Charlotte Cooper', 'London', 'UK'),
('New Orleans Cajun Delights', 'Shelley Burke', 'New Orleans', 'USA');
GO

INSERT INTO Products (ProductName, SupplierID, CategoryID, UnitPrice, UnitsInStock, Discontinued) VALUES
('Chai', 1, 1, 18.00, 39, 0),
('Chang', 1, 1, 19.00, 17, 0),
('Aniseed Syrup', 1, 2, 10.00, 13, 0),
('Chef Anton''s Cajun Seasoning', 2, 2, 22.00, 53, 0);
GO

INSERT INTO Customers (CompanyName, ContactName, City, Country) VALUES
('Alfreds Futterkiste', 'Maria Anders', 'Berlin', 'Germany'),
('Ana Trujillo Emparedados y Helados', 'Ana Trujillo', 'México D.F.', 'Mexico'),
('Antonio Moreno Taquería', 'Antonio Moreno', 'México D.F.', 'Mexico');
GO

INSERT INTO Employees (LastName, FirstName, Title, HireDate) VALUES
('Davolio', 'Nancy', 'Sales Representative', '1992-05-01'),
('Fuller', 'Andrew', 'Vice President, Sales', '1992-08-14'),
('Leverling', 'Janet', 'Sales Representative', '1992-04-01');
GO

INSERT INTO Orders (CustomerID, EmployeeID, OrderDate) VALUES
(1, 1, '2024-01-06'),
(2, 2, '2024-01-23'),
(3, 3, '2024-02-10');
GO

INSERT INTO [Order Details] (OrderID, ProductID, UnitPrice, Quantity) VALUES
(1, 1, 18.00, 10),
(1, 2, 19.00, 5),
(2, 3, 10.00, 15),
(3, 4, 22.00, 20);
GO

-- ============================================================
-- HASSAS VERİ TABLOSU (ŞİFRELEME İÇİN)
-- ============================================================

CREATE TABLE CustomerSensitiveData (
    SensitiveID INT PRIMARY KEY IDENTITY(1,1),
    CustomerID INT NOT NULL,
    SSN NVARCHAR(20),
    CreditCardNumber NVARCHAR(50),
    BankAccountNumber NVARCHAR(50),
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
);
PRINT '✓ CustomerSensitiveData tablosu oluşturuldu';
GO

-- ============================================================
-- AUDIT LOG TABLOSU
-- ============================================================

-- AuditLog tablosu 08_audit_log.sql dosyasında oluşturulacak
-- Burada oluşturulmadı.

PRINT '✓ AuditLog tablosu 08_audit_log.sql dosyasında oluşturulacak';
GO

-- ============================================================
-- DOĞRULAMA
-- ============================================================

PRINT '';
PRINT '============================================================';
PRINT 'NORTHWIND KURULU - İstatistikler:';
PRINT '============================================================';

SELECT 'Customers' AS [Tablo], COUNT(*) AS [Satır] FROM Customers
UNION ALL SELECT 'Employees', COUNT(*) FROM Employees
UNION ALL SELECT 'Suppliers', COUNT(*) FROM Suppliers
UNION ALL SELECT 'Categories', COUNT(*) FROM Categories
UNION ALL SELECT 'Products', COUNT(*) FROM Products
UNION ALL SELECT 'Orders', COUNT(*) FROM Orders
UNION ALL SELECT 'Order Details', COUNT(*) FROM [Order Details]
UNION ALL SELECT 'CustomerSensitiveData', COUNT(*) FROM CustomerSensitiveData
UNION ALL SELECT 'AuditLog', COUNT(*) FROM AuditLog
ORDER BY [Tablo];

PRINT '';
PRINT '✓ Northwind hazır! Sonraki script: 02_roller_ve_kullanicilar.sql';
GO

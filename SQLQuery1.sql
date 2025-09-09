-- Create table
drop table CafeSales;
CREATE TABLE CafeSales (
    TransactionID NVARCHAR(100) PRIMARY KEY,
    Item NVARCHAR(100),
    Quantity INT,
    PricePerUnit DECIMAL(10,2),
    TotalSpent DECIMAL(10,2), -- temporary due to errors
    PaymentMethod NVARCHAR(MAX),
    Location NVARCHAR(50),
    TransactionDate DATE
);

-- View raw data
SELECT * 
FROM dirty_cafe;

-- Insert data with conversion
INSERT INTO CafeSales (
    TransactionID,
    Item,
    Quantity,
    PricePerUnit,
    TotalSpent,
    PaymentMethod,
    Location,
    TransactionDate
)
SELECT 
    Transaction_ID,
    Item,
    TRY_CAST(Quantity AS INT),
    TRY_CAST(Price_Per_Unit AS DECIMAL(10,2)),
    TRY_CAST(Total_Spent AS DECIMAL(10,2)),
    Payment_Method,
    Location,
    TRY_CAST(Transaction_Date AS DATE)
FROM dirty_cafe;

------------------------------------------------
--                 Cleaning Code
------------------------------------------------

-- Check invalid dates
SELECT DISTINCT Transaction_Date
FROM dirty_cafe
WHERE ISDATE(Transaction_Date) = 0 OR Transaction_Date IS NULL;

UPDATE dirty_cafe
SET Transaction_Date = NULL
WHERE ISDATE(Transaction_Date) = 0;

-- Count missing values
SELECT 
    COUNT(*) AS TotalRows,
    SUM(CASE WHEN Item IS NULL THEN 1 ELSE 0 END) AS Missing_Item,
    SUM(CASE WHEN Quantity IS NULL THEN 1 ELSE 0 END) AS Missing_Quantity,
    SUM(CASE WHEN PricePerUnit IS NULL THEN 1 ELSE 0 END) AS Missing_PricePerUnit,
    SUM(CASE WHEN TotalSpent IS NULL THEN 1 ELSE 0 END) AS Missing_TotalSpent,
    SUM(CASE WHEN PaymentMethod IS NULL THEN 1 ELSE 0 END) AS Missing_PaymentMethod,
    SUM(CASE WHEN Location IS NULL THEN 1 ELSE 0 END) AS Missing_Location,
    SUM(CASE WHEN TransactionDate IS NULL THEN 1 ELSE 0 END) AS Missing_TransactionDate
FROM CafeSales;

-- Handle Item column
SELECT TOP 1 Item
FROM CafeSales
WHERE Item IS NOT NULL
GROUP BY Item
ORDER BY COUNT(*) DESC;  -- Juice

UPDATE CafeSales
SET Item = NULL
WHERE Item IN ('Unknown', 'Error'); -- 636 rows

UPDATE CafeSales
SET Item = 'Juice'
WHERE Item IS NULL; -- 333 + 636 rows

-- Handle Quantity column
UPDATE CafeSales
SET Quantity = NULL
WHERE Quantity IN ('Unknown', 'Error');

SELECT AVG(Quantity * 1.0) AS Avg_Quantity
FROM CafeSales
WHERE Quantity IS NOT NULL; -- 3.0

UPDATE CafeSales
SET Quantity = 3
WHERE Quantity IS NULL;

-- Handle PricePerUnit column
UPDATE CafeSales
SET PricePerUnit = NULL
WHERE PricePerUnit IN ('Unknown', 'Error');

SELECT AVG(PricePerUnit * 1.0) AS Avg_Price
FROM CafeSales
WHERE PricePerUnit IS NOT NULL; -- 2.94 then 3

UPDATE CafeSales
SET PricePerUnit = 26
WHERE PricePerUnit IS NULL; -- 533 rows

-- Handle TotalSpent column
UPDATE CafeSales
SET TotalSpent = Quantity * PricePerUnit
WHERE TotalSpent IS NULL 
  AND Quantity IS NOT NULL 
  AND PricePerUnit IS NOT NULL; -- 502 rows

SELECT AVG(TotalSpent * 1.0) 
FROM CafeSales 
WHERE TotalSpent IS NOT NULL; -- 9.06

UPDATE CafeSales
SET TotalSpent = 9
WHERE TotalSpent IS NULL;

-- Handle PaymentMethod column
UPDATE CafeSales
SET PaymentMethod = NULL
WHERE PaymentMethod IN ('Unknown', 'Error'); -- 599 rows

SELECT TOP 1 PaymentMethod
FROM CafeSales
WHERE PaymentMethod IS NOT NULL
GROUP BY PaymentMethod
ORDER BY COUNT(*) DESC; -- Digital Wallet

UPDATE CafeSales
SET PaymentMethod = 'Digital Wallet'
WHERE PaymentMethod IS NULL; -- 3178 rows

-- Handle Location column
UPDATE CafeSales
SET Location = NULL
WHERE Location IN ('Unknown', 'Error'); -- 696 rows

SELECT TOP 1 Location
FROM CafeSales
WHERE Location IS NOT NULL
GROUP BY Location
ORDER BY COUNT(*) DESC; -- Takeaway

UPDATE CafeSales
SET Location = 'Takeaway'
WHERE Location IS NULL; -- 3961 rows

-- Handle TransactionDate column
SELECT TOP 1 TransactionDate
FROM CafeSales
WHERE TransactionDate IS NOT NULL
GROUP BY TransactionDate
ORDER BY COUNT(*) DESC; -- 2023-02-06

UPDATE CafeSales
SET TransactionDate = '2023-02-06'
WHERE TransactionDate IS NULL; -- 460 rows

-- Check negative values
UPDATE CafeSales
SET Quantity = NULL
WHERE Quantity < 0;

UPDATE CafeSales
SET PricePerUnit = NULL
WHERE PricePerUnit < 0;

-- Normalize PaymentMethod
UPDATE CafeSales
SET PaymentMethod = UPPER(LTRIM(RTRIM(PaymentMethod)));

-- Remove future dates
UPDATE CafeSales
SET TransactionDate = NULL
WHERE TransactionDate > GETDATE();

-- Recalculate TotalSpent
UPDATE CafeSales
SET TotalSpent = Quantity * PricePerUnit
WHERE Quantity IS NOT NULL AND PricePerUnit IS NOT NULL;

-- Check remaining Unknown/Error values
SELECT *
FROM CafeSales
WHERE 
    CAST(TransactionID AS VARCHAR) IN ('Error', 'Unknown')
    OR CAST(Item AS VARCHAR) IN ('Error', 'Unknown')
    OR CAST(Quantity AS VARCHAR) IN ('Error', 'Unknown')
    OR CAST(PricePerUnit AS VARCHAR) IN ('Error', 'Unknown')
    OR CAST(TotalSpent AS VARCHAR) IN ('Error', 'Unknown')
    OR CAST(PaymentMethod AS VARCHAR) IN ('Error', 'Unknown')
    OR CAST(Location AS VARCHAR) IN ('Error', 'Unknown')
    OR CAST(TransactionDate AS VARCHAR) IN ('Error', 'Unknown');

------------------------------------------------
--               Analysis Code
------------------------------------------------

-- Total transactions
SELECT COUNT(*) AS Total_Transactions
FROM CafeSales; -- 10000

-- Total revenue
SELECT SUM(TotalSpent) AS Total_Revenue
FROM CafeSales; -- 127615.50

-- Average spend
SELECT AVG(TotalSpent) AS Avg_Spend
FROM CafeSales; -- 12.76

-- Total quantity by item
SELECT Item, SUM(Quantity) AS Total_Quantity
FROM CafeSales
GROUP BY Item
ORDER BY Total_Quantity DESC;

-- Payment methods distribution
SELECT PaymentMethod, COUNT(*) AS Count_Transactions
FROM CafeSales
GROUP BY PaymentMethod
ORDER BY Count_Transactions DESC;

-- Sales by location
SELECT Location, SUM(TotalSpent) AS Revenue
FROM CafeSales
GROUP BY Location
ORDER BY Revenue DESC;

-- Daily sales trend
SELECT CAST(TransactionDate AS DATE) AS Day, SUM(TotalSpent) AS Daily_Revenue
FROM CafeSales
GROUP BY CAST(TransactionDate AS DATE)
ORDER BY Day;

----------------

SELECT 
    FORMAT(TransactionDate, 'yyyy-MM') AS SalesMonth,
    SUM(TotalSpent) AS Total_Revenue
FROM CafeSales
GROUP BY FORMAT(TransactionDate, 'yyyy-MM')
ORDER BY SalesMonth;

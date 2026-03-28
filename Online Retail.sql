-- =========================================
-- Online Retail Data Import and Preparation
-- =========================================

-- Use the project database

USE online_retail_project;
GO

-- Drop existing tables if they already exist

IF OBJECT_ID('dbo.retail_transactions_raw', 'U') IS NOT NULL
    DROP TABLE dbo.retail_transactions_raw;
GO

IF OBJECT_ID('dbo.retail_transactions', 'U') IS NOT NULL
    DROP TABLE dbo.retail_transactions;
GO

-- Create raw staging table

CREATE TABLE dbo.retail_transactions_raw (
    InvoiceNo   VARCHAR(50),
    StockCode   VARCHAR(50),
    Description VARCHAR(MAX),
    Quantity    VARCHAR(50),
    InvoiceDate VARCHAR(50),
    UnitPrice   VARCHAR(50),
    CustomerID  VARCHAR(50),
    Country     VARCHAR(100),
    TotalPrice  VARCHAR(50)
);
GO

-- Create final typed table

CREATE TABLE dbo.retail_transactions (
    InvoiceNo   VARCHAR(20),
    StockCode   VARCHAR(20),
    Description VARCHAR(MAX),
    Quantity    INT,
    InvoiceDate DATETIME,
    UnitPrice   DECIMAL(10,2),
    CustomerID  VARCHAR(20),
    Country     VARCHAR(100),
    TotalPrice  DECIMAL(12,2)
);
GO

-- Import note:
-- During the first import attempt, some rows were misaligned because descriptions
-- containing commas were not parsed properly from the CSV file.
-- After checking the raw data and validation queries, the file was re-saved from
-- Excel and imported again into dbo.retail_transactions_raw with the correct
-- flat file settings.
--
-- Import settings used:
-- Source: Flat File Source
-- Destination: Microsoft OLE DB Driver for SQL Server
-- Text qualifier: "
-- Column delimiter: Comma
-- Row delimiter: CR/LF

SELECT COUNT(*) AS raw_rows
FROM dbo.retail_transactions_raw;
GO

SELECT COUNT(*) AS bad_quantity_rows
FROM dbo.retail_transactions_raw
WHERE TRY_CAST(Quantity AS INT) IS NULL
  AND Quantity IS NOT NULL;
GO

SELECT COUNT(*) AS bad_invoicedate_rows
FROM dbo.retail_transactions_raw
WHERE TRY_CAST(InvoiceDate AS DATETIME) IS NULL
  AND InvoiceDate IS NOT NULL;
GO

SELECT COUNT(*) AS bad_unitprice_rows
FROM dbo.retail_transactions_raw
WHERE TRY_CAST(UnitPrice AS DECIMAL(10,2)) IS NULL
  AND UnitPrice IS NOT NULL;
GO

SELECT COUNT(*) AS bad_totalprice_rows
FROM dbo.retail_transactions_raw
WHERE TRY_CAST(TotalPrice AS DECIMAL(12,2)) IS NULL
  AND TotalPrice IS NOT NULL;
GO

-- Load cleaned data into final table

INSERT INTO dbo.retail_transactions (
    InvoiceNo,
    StockCode,
    Description,
    Quantity,
    InvoiceDate,
    UnitPrice,
    CustomerID,
    Country,
    TotalPrice
)
SELECT
    LEFT(InvoiceNo, 20),
    LEFT(StockCode, 20),
    Description,
    CAST(Quantity AS INT),
    CAST(InvoiceDate AS DATETIME),
    CAST(UnitPrice AS DECIMAL(10,2)),
    LEFT(CustomerID, 20),
    LEFT(Country, 100),
    CAST(TotalPrice AS DECIMAL(12,2))
FROM dbo.retail_transactions_raw;
GO

-- Verify final output

SELECT COUNT(*) AS final_rows
FROM dbo.retail_transactions;
GO

SELECT TOP 10 *
FROM dbo.retail_transactions;
GO

-- =========================================
-- Basket-Level Validation and Overview
-- =========================================

SELECT COUNT(*) AS total_transaction_rows
FROM dbo.retail_transactions;
GO

SELECT COUNT(DISTINCT InvoiceNo) AS total_invoices
FROM dbo.retail_transactions;
GO

SELECT COUNT(DISTINCT Description) AS total_products
FROM dbo.retail_transactions;
GO

SELECT COUNT(DISTINCT CustomerID) AS total_customers
FROM dbo.retail_transactions;
GO

-- =========================================
-- Basket Size and Basket Value Analysis
-- =========================================

WITH invoice_summary AS (
    SELECT
        InvoiceNo,
        COUNT(*) AS basket_size,
        SUM(TotalPrice) AS basket_value
    FROM dbo.retail_transactions
    GROUP BY InvoiceNo
)
SELECT
    AVG(CAST(basket_size AS DECIMAL(10,2))) AS avg_basket_size,
    AVG(CAST(basket_value AS DECIMAL(12,2))) AS avg_basket_value,
    MAX(basket_size) AS max_basket_size,
    MAX(basket_value) AS max_basket_value
FROM invoice_summary;
GO

-- Basket Size and Basket Value Insights:
-- The invoice-level summary shows that the average basket contains about
-- 26.56 product lines, with an average basket value of about 534.40.
--
-- This suggests that the dataset contains sufficiently rich baskets for
-- market basket analysis, since invoices often include multiple products
-- rather than only one or two items.
--
-- The maximum basket size and maximum basket value are far higher than
-- the averages, which indicates the presence of a few unusually large
-- orders. These may represent bulk or high-volume purchases and should
-- be kept in mind while interpreting basket patterns and recommendation rules.

-- =========================================
-- Products by Basket Presence
-- =========================================

SELECT TOP 10
    Description,
    COUNT(DISTINCT InvoiceNo) AS invoice_presence_count
FROM dbo.retail_transactions
GROUP BY Description
ORDER BY invoice_presence_count DESC;
GO

-- =========================================
-- Top Co-Purchased Product Pairs
-- =========================================

SELECT TOP 10
    t1.Description AS product_1,
    t2.Description AS product_2,
    COUNT(DISTINCT t1.InvoiceNo) AS pair_invoice_count
FROM dbo.retail_transactions t1
JOIN dbo.retail_transactions t2
    ON t1.InvoiceNo = t2.InvoiceNo
   AND t1.Description < t2.Description
GROUP BY
    t1.Description,
    t2.Description
ORDER BY pair_invoice_count DESC;
GO

-- Top Co-Purchased Product Pairs Insights:
-- This query identifies the product pairs that appear together in the
-- highest number of invoices by joining the transaction table to itself
-- on the same invoice number.
--
-- The results show that some product combinations are repeatedly bought
-- together across a large number of baskets. This supports the findings
-- from the Python basket analysis and suggests that certain products have
-- strong natural co-purchase relationships.
--
-- Pairs such as themed bags, lunch box variants, and matching tea cup
-- designs appear frequently together, which makes them good candidates
-- for recommendation logic, bundle creation, or cross-selling strategies.

-- =========================================
-- Monthly Invoice Trend
-- =========================================

SELECT
    YEAR(InvoiceDate) AS order_year,
    MONTH(InvoiceDate) AS order_month,
    COUNT(DISTINCT InvoiceNo) AS monthly_invoice_count,
    SUM(TotalPrice) AS monthly_revenue
FROM dbo.retail_transactions
GROUP BY
    YEAR(InvoiceDate),
    MONTH(InvoiceDate)
ORDER BY
    order_year,
    order_month;
GO

-- Monthly Invoice Trend Insights
-- This query summarizes invoice activity and revenue at a monthly level.
--
-- The results show that transaction volume and revenue change across time,
-- with some months contributing much more strongly than others. In this
-- dataset, November 2011 stands out as the peak month in both invoice count
-- and total revenue.
--
-- Adding this time-based view is useful because it complements the basket
-- analysis with a broader business perspective and can later support trend
-- visualizations in Power BI.

-- =========================================
-- SQL Analysis Conclusion
-- =========================================
-- The SQL layer of this project was used not only for data import and
-- cleaning validation, but also for basket-oriented business analysis.
--
-- The final transaction table was examined in terms of invoice count,
-- product count, customer count, basket size, basket value, product
-- presence across invoices, co-purchased product pairs, and monthly
-- transaction trends.
--
-- These queries helped connect the database analysis to the core project
-- objective of market basket analysis and recommendation logic. In
-- particular, the product-pair query supported the same co-purchase
-- patterns later explored in Python through Apriori and association rules.
--
-- Overall, SQL Server was used here as a practical database layer for
-- storing cleaned retail transactions and generating business insights
-- that complement the Python-based recommendation analysis.

-- =========================================
-- KPI Summary for Power BI
-- =========================================

WITH invoice_summary AS (
    SELECT
        InvoiceNo,
        COUNT(*) AS basket_size,
        SUM(TotalPrice) AS basket_value
    FROM dbo.retail_transactions
    GROUP BY InvoiceNo
)
SELECT
    (SELECT SUM(TotalPrice) FROM dbo.retail_transactions) AS total_revenue,
    (SELECT COUNT(DISTINCT InvoiceNo) FROM dbo.retail_transactions) AS total_invoices,
    (SELECT COUNT(DISTINCT Description) FROM dbo.retail_transactions) AS total_products,
    (SELECT COUNT(DISTINCT CustomerID) FROM dbo.retail_transactions) AS total_customers,
    AVG(CAST(basket_size AS DECIMAL(10,2))) AS avg_basket_size,
    AVG(CAST(basket_value AS DECIMAL(12,2))) AS avg_basket_value,
    MAX(basket_size) AS max_basket_size,
    MAX(basket_value) AS max_basket_value
FROM invoice_summary;
GO

-- =========================================
-- Monthly Trend for Power BI
-- =========================================

SELECT
    YEAR(InvoiceDate) AS order_year,
    MONTH(InvoiceDate) AS order_month,
    COUNT(DISTINCT InvoiceNo) AS monthly_invoice_count,
    SUM(TotalPrice) AS monthly_revenue
FROM dbo.retail_transactions
GROUP BY
    YEAR(InvoiceDate),
    MONTH(InvoiceDate)
ORDER BY
    order_year,
    order_month;
GO

-- =========================================
-- Product Presence for Power BI
-- =========================================

SELECT TOP 25
    Description,
    COUNT(DISTINCT InvoiceNo) AS invoice_presence_count
FROM dbo.retail_transactions
GROUP BY Description
ORDER BY invoice_presence_count DESC;
GO

-- =========================================
-- Product Pairs for Power BI
-- =========================================

SELECT TOP 25
    t1.Description AS product_1,
    t2.Description AS product_2,
    COUNT(DISTINCT t1.InvoiceNo) AS pair_invoice_count
FROM dbo.retail_transactions t1
JOIN dbo.retail_transactions t2
    ON t1.InvoiceNo = t2.InvoiceNo
   AND t1.Description < t2.Description
GROUP BY
    t1.Description,
    t2.Description
ORDER BY pair_invoice_count DESC;
GO
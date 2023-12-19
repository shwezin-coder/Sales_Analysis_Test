ALTER TABLE AdventureWorks_Sales
ALTER COLUMN OrderQuantity INT;

ALTER TABLE AdventureWorks_Returns
ALTER COLUMN ReturnQuantity INT;

--2. Extract yearly sales quantity for 2015,2016,2017 for each customer for each product, fields
--required,
--a. Year
--b. Customer Name
--c. Gender
--d. Product Name
--e. Sales/Order quantity
SELECT YEAR(OrderDate) AS Year,
       CONCAT(c.FirstName, ' ', c.LastName) AS CustomerName,
       c.Gender,
       p.ProductName,
       SUM(s.OrderQuantity) AS TotalOrderQuantity
FROM AdventureWorks_Customers c
JOIN AdventureWorks_Sales s ON c.CustomerKey = s.CustomerKey
JOIN AdventureWorks_Product p ON p.ProductKey = s.ProductKey
WHERE YEAR(OrderDate) IN (2015, 2016, 2017)
GROUP BY YEAR(OrderDate), c.CustomerKey, c.FirstName, c.LastName, c.Gender, p.ProductName
ORDER BY 5 DESC;

--3. EXTRACT MONTHLY ORDER AND RETURN AMOUNT FOR 2016 FOR EACH PRODUCT.
--A. DATE
--B. PRODUCT NAME
--C. PRODUCT SUB-CATEGORY
--D. PRODUCT CATEGORY
--E. ORDER QUANTITY
--F. RETURN QUANTITY

ALTER TABLE AdventureWorks_Sales
ALTER COLUMN OrderDate Date

SELECT 
    FORMAT(s.OrderDate, 'MMMM') 'Month',
    p.ProductName,
    psc.SubcategoryName,
    pc.CategoryName,
    SUM(s.OrderQuantity) AS 'TotalOrderQuantity',
    ISNULL(SUM(r.ReturnQuantity),0) AS 'TotalReturnQuantity'
FROM 
    AdventureWorks_Sales s
JOIN 
    AdventureWorks_Product p ON s.ProductKey = p.ProductKey
JOIN 
    AdventureWorks_ProductSubCategory psc ON p.ProductSubcategoryKey = psc.ProductSubcategoryKey
JOIN 
    AdventureWorks_ProductCategory pc ON psc.ProductCategoryKey = pc.ProductCategoryKey
LEFT JOIN 
    AdventureWorks_Returns r ON s.ProductKey = r.ProductKey AND MONTH(s.OrderDate) = MONTH(r.ReturnDate) AND YEAR(s.OrderDate) = YEAR(r.ReturnDate)
WHERE 
    YEAR(s.OrderDate) = 2016
GROUP BY 
    FORMAT(s.OrderDate, 'MMMM'),
    p.ProductName,
    psc.SubcategoryName,
    pc.CategoryName;

--4. List the bottom 3 products with lowest sale quantity in each country in 2016.
--a. Product Name
--b. Product Description
--c. Order quantity
WITH RankedProducts AS (
    SELECT
        p.ProductName,
        p.ProductDescription,
        t.Country,
        SUM(s.OrderQuantity) AS TotalOrderQuantity,
        ROW_NUMBER() OVER (PARTITION BY t.Country ORDER BY SUM(s.OrderQuantity) ASC) AS RowNum
    FROM
        AdventureWorks_Product p
    JOIN
        AdventureWorks_Sales s ON p.ProductKey = s.ProductKey
	JOIN AdventureWorks_Territory t ON t.SalesTerritoryKey = s.TerritoryKey
    WHERE
        YEAR(s.OrderDate) = 2016
    GROUP BY
        p.ProductName, p.ProductDescription, t.Country
)
SELECT
    ProductName,
    ProductDescription,
    Country,
    TotalOrderQuantity
FROM
    RankedProducts
WHERE
    RowNum <= 3;

--5. List the top 3 products with highest return quantity in 2016.
--a. Product Name
--b. Product Description
--c. Return quantity
WITH RankedProducts AS (
    SELECT
        p.ProductName,
        p.ProductDescription,
        SUM(r.ReturnQuantity) AS TotalReturnQuantity,
        ROW_NUMBER() OVER (ORDER BY SUM(r.ReturnQuantity) DESC) AS RowNum
    FROM
        AdventureWorks_Product p
    JOIN
        AdventureWorks_Returns r ON p.ProductKey = r.ProductKey
    WHERE
        YEAR(r.ReturnDate) = 2016
    GROUP BY
        p.ProductName, p.ProductDescription
)
SELECT
    ProductName,
    ProductDescription,
    TotalReturnQuantity
FROM
    RankedProducts
WHERE
    RowNum <= 3;


--6. Month to date total order quantity in US, Canada and Australia till 28th April 2016.
SELECT 
	t.Country,
    FORMAT(s.OrderDate, 'MMMM') AS 'Month',
    SUM(s.OrderQuantity) AS 'TotalQuantity'
  
FROM 
    AdventureWorks_sales s, AdventureWorks_Territory t
WHERE 
    s.OrderDate <= '2016-04-28' 
    AND s.TerritoryKey = t.SalesTerritoryKey 
    AND t.Country IN ('United States', 'Canada', 'Australia')
GROUP BY 
    t.Country, FORMAT(s.OrderDate, 'MMMM')
ORDER BY 1;

--7. Extract return % of order for each product in 2016.
SELECT 
    p.ProductName,
    CONCAT(FORMAT(SUM(CASE WHEN r.ProductKey IS NOT NULL THEN 1 ELSE 0 END) * 1.0 / COUNT(DISTINCT s.OrderNumber),'0'),'%') AS 'ReturnPercentage'
FROM 
    AdventureWorks_Sales s 
JOIN 
    AdventureWorks_Product p ON s.ProductKey = p.ProductKey 
LEFT JOIN 
    AdventureWorks_Returns r ON r.ProductKey = s.ProductKey
WHERE 
    YEAR(s.OrderDate) = 2016
GROUP BY 
    p.ProductName
ORDER BY 1;


--8. Extract each order with their return information for Jan, Feb, Mar in 2016.
SELECT 
    s.OrderNumber,
    s.OrderDate,
    t.Country,
    p.ProductName,
    s.OrderQuantity,
    ISNULL(r.ReturnDate,'no return') 'OrderDate',
    ISNULL(r.ReturnQuantity,0) 'ReturnQuantity'
FROM 
    AdventureWorks_Sales s 
LEFT JOIN 
    AdventureWorks_Product p ON p.ProductKey = s.ProductKey 
LEFT JOIN 
    AdventureWorks_Territory t ON t.SalesTerritoryKey = s.TerritoryKey
LEFT JOIN 
    AdventureWorks_Returns r ON s.ProductKey = r.ProductKey AND s.OrderDate = r.ReturnDate
WHERE 
    YEAR(s.OrderDate) = 2016
    AND MONTH(s.OrderDate) IN (1, 2, 3)
ORDER BY ReturnQuantity DESC;
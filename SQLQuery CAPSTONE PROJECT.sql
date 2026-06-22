SELECT *
FROM pizzas;

SELECT *
FROM orders;

SELECT * 
FROM pizza_types;

SELECT *
FROM order_details;

--Data Cleaning Query 
-- Checking for null values

SELECT *
FROM orders
WHERE order_id IS NULL
   OR date IS NULL
   OR time IS NULL;

   SELECT *
FROM order_details
WHERE order_details_id IS NULL
   OR order_id IS NULL
   OR pizza_id IS NULL
   OR quantity IS NULL;

   -- Checking and removing duplicates 

   SELECT order_id, COUNT(*)
		FROM orders
			GROUP BY order_id
				HAVING COUNT(*) > 1;

-- Checking for invalid pizza quantities 
	SELECT *
		FROM order_details
			WHERE quantity <= 0;

-- Checking for missing pizza reference
SELECT *
  FROM order_details od
	LEFT JOIN pizzas p
	ON od.pizza_id = p.pizza_id
		WHERE p.pizza_id IS NULL;

-- Standardize time format
SELECT 
order_id,
date,
CONVERT(VARCHAR(8), time, 108) AS order_time
FROM orders;

--Creating Analytical Review Column 
--calculating revenue column 
SELECT 
od.order_details_id,
od.order_id,
od.quantity,
p.price,
(od.quantity * p.price) AS revenue
FROM order_details od
JOIN pizzas p
ON od.pizza_id = p.pizza_id;

--Categorising order sizes for easier analysis 
SELECT
pizza_id,
size,
CASE
    WHEN size = 'S' THEN 'Small'
    WHEN size = 'M' THEN 'Medium'
    WHEN size = 'L' THEN 'Large'
    WHEN size = 'XL' THEN 'Extra Large'
    ELSE 'Other'
END AS pizza_size_category
FROM pizzas;

--Standardizing pizza names to proper case
--(Using Text Function)
SELECT
UPPER(name) AS pizza_name,
category
FROM pizza_types;

--Extracting order hour for time-based analysis
--(Using Date Functon )
SELECT
order_id,
DATEPART(HOUR, time) AS order_hour
FROM orders;

--Data Validation and Documentation Queries
--To ensure that the cleaning process did not introduce inconsistencies, validation checks is performerd.
--Row count verification for orders 

SELECT COUNT(*) AS total_orders
	FROM orders;

--Row count verification for order_details 

SELECT COUNT(*) AS total_order_details
FROM order_details;

--Duplicate Verification

SELECT order_id, COUNT(*)
	FROM orders
	GROUP BY order_id
	HAVING COUNT(*) > 1;

--Data type confirmation

SELECT 
COLUMN_NAME,
DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'orders';

--Key Performance Metrics(KPMs)

--Total Revenue = 817860.05083847

SELECT 
	SUM(od.quantity * p.price) AS total_revenue
		FROM order_details od
JOIN pizzas p
ON od.pizza_id = p.pizza_id;

-- Total Orders = 21350 (total unique transactions )
SELECT 
COUNT(DISTINCT order_id) AS total_orders
FROM orders;

-- Total Pizzas Sold = 49574

SELECT 
SUM(quantity) AS total_pizzas_sold
FROM order_details;

--Average order size (to know customer behavioural purchase pattern )
--Avg_pizzas_per_order = 2.33 

SELECT 
CAST(SUM(quantity) AS FLOAT) /
COUNT(DISTINCT order_id) AS avg_pizzas_per_order
FROM order_details;

--Revenue_By_pizza_Category 

SELECT
pt.category,
SUM(od.quantity * p.price) AS revenue
FROM order_details od
JOIN pizzas p
ON od.pizza_id = p.pizza_id
JOIN pizza_types pt
ON p.pizza_type_id = pt.pizza_type_id
GROUP BY pt.category
ORDER BY revenue DESC;

--Product Performance Analysis 
--Top 10 Best_Selling_Pizza 

SELECT TOP 10
pt.name,
SUM(od.quantity) AS total_quantity
FROM order_details od
JOIN pizzas p
ON od.pizza_id = p.pizza_id
JOIN pizza_types pt
ON p.pizza_type_id = pt.pizza_type_id
GROUP BY pt.name
ORDER BY total_quantity DESC;

--Sales By Pizza size 

SELECT
p.size,
SUM(od.quantity) AS pizzas_sold
FROM order_details od
JOIN pizzas p
ON od.pizza_id = p.pizza_id
GROUP BY p.size
ORDER BY pizzas_sold DESC;

--Customer ordering behaviour 
--Orders by day of the week 

SELECT
DATENAME(WEEKDAY, date) AS day_of_week,
COUNT(order_id) AS total_orders
FROM orders
GROUP BY DATENAME(WEEKDAY, date)
ORDER BY total_orders DESC;

--Orders by hour 

SELECT
DATEPART(HOUR, time) AS order_hour,
COUNT(order_id) AS total_orders
FROM orders
GROUP BY DATEPART(HOUR, time)
ORDER BY order_hour;

--Combined Analytical Dataset 
SELECT
o.order_id,
o.date AS order_date,
CONVERT(VARCHAR(8), o.time, 108) AS order_time,
DATENAME(WEEKDAY, o.date) AS day_of_week,
DATEPART(HOUR, o.time) AS order_hour,
pt.category,
pt.name AS pizza_name,
p.size,
od.quantity,
p.price,
(od.quantity * p.price) AS revenue
FROM orders o
JOIN order_details od
ON o.order_id = od.order_id
JOIN pizzas p
ON od.pizza_id = p.pizza_id
JOIN pizza_types pt
ON p.pizza_type_id = pt.pizza_type_id;
 

 -- Main analytical view 
 CREATE VIEW vw_pizza_sales_analysis AS
SELECT
    o.order_id,
    o.date AS order_date,
    CONVERT(VARCHAR(8), o.time, 108) AS order_time,
    DATENAME(WEEKDAY, o.date) AS day_of_week,
    DATEPART(HOUR, o.time) AS order_hour,
    pt.pizza_type_id,
    pt.name AS pizza_name,
    pt.category,
    p.pizza_id,
    p.size,
    p.price,
    od.quantity,
    (od.quantity * p.price) AS revenue
FROM orders o
JOIN order_details od
    ON o.order_id = od.order_id
JOIN pizzas p
    ON od.pizza_id = p.pizza_id
JOIN pizza_types pt
    ON p.pizza_type_id = pt.pizza_type_id;


    SELECT *
    FROM vw_pizza_sales_analysis;

-- Category revenue analysis view

CREATE VIEW vw_revenue_by_category AS
SELECT
    category,
    SUM(revenue) AS total_revenue
FROM vw_pizza_sales_analysis
GROUP BY category;


SELECT * 
    FROM vw_revenue_by_category
ORDER BY total_revenue DESC;

--Top selling pizzas view

CREATE VIEW vw_top_selling_pizzas AS
SELECT
    pizza_name,
    SUM(quantity) AS total_pizzas_sold,
    SUM(revenue) AS total_revenue
FROM vw_pizza_sales_analysis
GROUP BY pizza_name;


SELECT TOP 10 *
FROM vw_top_selling_pizzas
ORDER BY total_pizzas_sold DESC;


--View for Order Trends
--This view helps analyze customer ordering patterns by hour

CREATE VIEW vw_orders_by_hour AS
SELECT
    order_hour,
    COUNT(order_id) AS total_orders
FROM vw_pizza_sales_analysis
GROUP BY order_hour;


SELECT * 
FROM vw_orders_by_hour
ORDER BY order_hour;

--View for Sales by Pizza Size
--This view summarizes pizza sales by size.

CREATE VIEW vw_sales_by_size AS
SELECT
    size,
    SUM(quantity) AS total_pizzas_sold,
    SUM(revenue) AS total_revenue
FROM vw_pizza_sales_analysis
GROUP BY size;

SELECT *
FROM vw_sales_by_size
ORDER BY size;



SCHEMA 
CREATE SCHEMA pizza_sales;

CREATE TABLE pizza_sales.orders (
    order_id INT PRIMARY KEY,
    order_date DATE,
    order_time TIME
);

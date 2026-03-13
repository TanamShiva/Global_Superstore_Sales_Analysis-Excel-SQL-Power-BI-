
-- Database designing
CREATE DATABASE global_superstore;
USE global_superstore;


CREATE TABLE people
(
Person varchar(50), 
Region varchar(25)
);

select * from people;


CREATE TABLE Orders
(
Row_ID varchar(10), 
Order_ID varchar(100), 
Order_Date date, 
Ship_Date date, 
Ship_Mode varchar(25), 
Customer_ID varchar(50), 
Customer_Name varchar(100), 
Segment varchar(25), 
Postal_Code varchar(15), 
City varchar(100), 
State varchar(50), 
Country varchar(35), 
Region varchar(25), 
Market varchar(20), 
Product_ID varchar(25), 
Category varchar(25), 
Sub_Category varchar(25), 
Product_Name varchar(200), 
Sales decimal(10,2), 
Quantity int, 
Discount decimal(5,2), 
Profit decimal(10,2), 
Shipping_Cost decimal(10,2), 
Order_Priority varchar(20)
);

select * from orders;


CREATE TABLE returns
(
Returned VARCHAR(15),
Order_ID varchar(100),
Region varchar(25)
);

select * from returns;


-- Data Modeling
ALTER TABLE People
ADD CONSTRAINT pk_people PRIMARY KEY(Region);

ALTER TABLE Orders
ADD CONSTRAINT pk_orders PRIMARY KEY(Row_ID);

CREATE INDEX idx_orderID
ON Orders(Order_ID);

ALTER TABLE Orders
ADD CONSTRAINT fk_orders_people
FOREIGN KEY (Region)
REFERENCES People(Region);

ALTER TABLE Returns
ADD CONSTRAINT fk_returns_orders
FOREIGN KEY (Order_id)
REFERENCES Orders(Order_id);

SELECT
	r.Order_ID
FROM returns r
LEFT JOIN orders o ON r.Order_ID = o.Order_ID
WHERE o.Order_ID IS NULL;

/*
During data validation, I discovered orphan records in the Returns table where Order_ID values were not present 
in the Orders table. To maintain referential integrity before implementing foreign key constraints, 
I removed these records using a DELETE JOIN operation. 
*/
SET SQL_SAFE_UPDATES = 0;

DELETE r
FROM Returns r
LEFT JOIN Orders o ON r.Order_ID = o.Order_ID
WHERE o.Order_ID IS NULL;

SELECT * FROM Returns;

ALTER TABLE Returns
ADD CONSTRAINT fk_returns_orders
FOREIGN KEY (Order_id)
REFERENCES Orders(Order_id);




-- Data Understanding 
-- Total records Orders table
SELECT COUNT(*) AS total_records FROM orders;

-- Distinct customers placed orders
SELECT COUNT(DISTINCT Customer_ID) AS unique_cust_count FROM orders;

-- Unique product categories.
SELECT DISTINCT Category FROM orders;

-- Earliest and latest order date.
SELECT 
	MIN(Order_Date) AS earliest_ord_date,
    MAX(Order_Date) AS latest_ord_date
FROM orders;

-- Orders shipped per ship mode
SELECT 
	Ship_mode, 
    COUNT(DISTINCT Order_ID) AS orders_count 
FROM orders
GROUP BY Ship_mode;

-- Countries and regions count 
SELECT
	COUNT(DISTINCT Country) AS country_count,
    COUNT(DISTINCT Region) AS region_count
FROM orders;




-- Data Cleaning & Validation
-- Duplicate order IDs.
SELECT o.* 
FROM orders o
JOIN
(
SELECT 
	Order_id
FROM orders
GROUP BY order_id
HAVING COUNT(*) > 1
) duplicates ON o.Order_ID = duplicates.Order_id;

-- Rows with negative profit.
SELECT
	*
FROM orders
WHERE profit < 0;

-- Products with discount > 50%.
SELECT
	Product_ID,
    Product_Name,
    Discount
FROM orders
WHERE discount > 0.50
ORDER BY Discount DESC;

-- Orders with shipping date earlier than order date.
SELECT
	Order_id,
    Ship_date,
    Order_date
FROM orders
WHERE Ship_date < Order_date;




-- Sales & Profit Analysis
-- Q11 Calculate total sales, total profit, and total quantity sold.
SELECT 
	SUM(Sales) AS total_sales,  
    SUM(Profit) AS total_profit,
    SUM(Quantity) AS total_quantity
FROM orders;

-- Q12 Find total sales by category.
SELECT
	Category,
    SUM(Sales) AS total_sales
FROM orders
GROUP BY Category
ORDER BY total_sales DESC;

-- Q13 Find total profit by sub-category.
SELECT 
	Sub_category,
    SUM(Profit) AS total_profit
FROM orders
GROUP BY Sub_category
ORDER BY total_profit DESC;

-- Q14 Top 5 products by total sales
SELECT
	Product_Name,
	SUM(Sales) AS total_sales
FROM orders
GROUP BY Product_Name
ORDER BY total_sales DESC
LIMIT 5;

-- Q15 Top 5 products by losses
SELECT
	Product_Name,
    SUM(Profit) AS total_profit
FROM orders
GROUP BY Product_Name
ORDER BY total_profit
LIMIT 5;

-- Q16 Region with most revenue
SELECT
	Region,
    SUM(Sales) AS total_sales
FROM orders
GROUP BY Region
ORDER BY total_sales DESC
LIMIT 1;





-- Customer Analysis
-- Q17 Find the top 10 customers by sales.
SELECT
	Customer_ID,
    Customer_Name,
	SUM(Sales) AS total_sales
FROM orders
GROUP BY Customer_ID, Customer_Name
ORDER BY total_sales DESC
limit 10;

-- Q18 Customer segment generates the highest sales
SELECT
	Segment,
    SUM(Sales) AS total_sales
FROM orders
GROUP BY Segment
ORDER BY total_sales DESC
limit 1;

-- Q19 Customers with the highest number of orders.
SELECT
	Customer_ID,
    Customer_Name,
	COUNT(DISTINCT Order_ID) AS orders_count
FROM orders
GROUP BY Customer_ID, Customer_Name
ORDER BY orders_count DESC
limit 5;

-- Q20 Calculate average order value per customer.
SELECT
	Customer_ID,
    Customer_Name,
    ROUND(SUM(Sales)/COUNT(DISTINCT Order_ID), 2) AS avg_ord_value
FROM orders
GROUP BY Customer_ID, Customer_Name
ORDER BY avg_ord_value DESC;
-- Because Order_ID column has duplicate values, used 'SUM(Sales)/COUNT(DISTINCT Order_ID)' above to calculate avg.
-- Else, avg(sales) would have given desired output.





-- Time Series Analysis
-- Q21 Calculate monthly sales trend.
SELECT
	DATE_FORMAT(Order_Date, '%Y-%m') AS MonthNum,
    SUM(Sales) AS MonthlySales
FROM Orders
GROUP BY DATE_FORMAT(Order_Date, '%Y-%m')
ORDER BY MonthNum;

-- or
SELECT
	YEAR(Order_Date) AS order_year,
    MONTH(Order_Date) AS order_month,
    SUM(Sales) AS monthlysales
FROM Orders
GROUP BY YEAR(Order_Date), MONTH(Order_Date)
ORDER BY YEAR(Order_Date), MONTH(Order_Date);


-- Q22 Find year-over-year sales growth.
WITH Yearly_sales AS
(
SELECT 
	YEAR(Order_Date) AS Year,
    SUM(Sales) AS Sales
FROM Orders
GROUP BY YEAR(Order_Date)
)
SELECT 
	Year,
    Sales,
    LAG(Sales) OVER(ORDER BY Year) AS p_year_sales,
    ROUND((Sales - LAG(Sales) OVER(ORDER BY Year)) / 
			LAG(Sales) OVER(ORDER BY Year) * 100, 2) AS YoY_SalesGrowth    
FROM Yearly_sales;


-- Q23 Find the month with the highest sales.
SELECT
	DATE_FORMAT(Order_Date, '%Y-%m') AS monthnum,
    SUM(Sales) AS monthlysales
FROM Orders
GROUP BY DATE_FORMAT(Order_Date, '%Y-%m')
ORDER BY monthlysales DESC
LIMIT 1;

-- OR

WITH monthly_sale AS
(
SELECT
	DATE_FORMAT(Order_Date, '%Y-%m') AS monthNum,
    SUM(Sales) AS monthlysales
FROM Orders
GROUP BY DATE_FORMAT(Order_Date, '%Y-%m')
)
SELECT monthnum, monthlysales
FROM 
	(
		SELECT
			monthnum,
			monthlysales,
			RANK() OVER(ORDER BY monthlysales DESC) AS rnk
		FROM monthly_sale
	) AS rnk_table
WHERE rnk = 1;
	

-- Q24 Calculate average delivery time.
SELECT ROUND(AVG(DATEDIFF(Ship_Date, Order_Date)), 2) AS avg_delivery_time
FROM Orders;





-- Advanced SQL Analysis
-- Q25 Rank products by sales within each category.
SELECT
	Product_ID,
    Product_Name,
    Category,
    SUM(Sales) AS Sales,
    RANK() OVER(PARTITION BY Category ORDER BY SUM(Sales) DESC) AS Sale_rank
FROM Orders
GROUP BY Product_ID, Product_Name, Category;
    

-- Q26 Find the top 3 products in each region by sales.
SELECT 
	Product_ID,
    Product_Name,
    Region,
    Sales
FROM 
(
	SELECT
		Product_ID,
		Product_Name,
		Region,
		SUM(Sales) AS Sales,
		ROW_NUMBER() OVER(PARTITION BY Region ORDER BY SUM(Sales) DESC) AS RN
	FROM Orders
	GROUP BY Product_ID, Product_Name, Region
) AS rn_table
WHERE RN <=3;


-- Q27 Identify customers whose sales are above the average customer sales.
SELECT
	Customer_ID,
    Customer_Name,
    SUM(Sales) AS Sales
FROM Orders
GROUP BY Customer_ID, Customer_Name
HAVING SUM(Sales) > 
				(SELECT AVG(cs.Sales)
				FROM
					(
						SELECT
							Customer_ID,
							Customer_Name,
							SUM(Sales) AS Sales
						FROM Orders
						GROUP BY Customer_ID, Customer_Name
					) AS cs
				);

-- OR

WITH customer_sale AS
(
SELECT 
	Customer_ID,
    Customer_Name, 
    SUM(Sales) AS Sales
FROM Orders
GROUP BY Customer_ID, Customer_Name
)
SELECT * FROM customer_sale
WHERE Sales > (SELECT AVG(Sales) FROM customer_sale);


-- Q28 Calculate running total of sales over time.
WITH daily_sales AS
(
SELECT
    Order_Date,
    SUM(Sales) AS Sales
FROM Orders
GROUP BY Order_Date
)
SELECT 
	Order_Date,
	Sales,
    SUM(Sales) OVER(ORDER BY Order_Date) AS running_sales
FROM daily_sales;


-- Q29 Find the percentage contribution of each category to total sales.
SELECT
	Category,
    SUM(Sales) AS Sales,
    ROUND(SUM(Sales) / (SELECT SUM(SALES) FROM Orders) *100, 2) AS Perc_contribution
FROM Orders
GROUP BY Category
ORDER BY Perc_contribution DESC;


-- Q30 Find customers who purchased in more than one region.
SELECT
	Customer_ID,
    Customer_Name,
    COUNT(DISTINCT Region) AS region_count
FROM Orders
GROUP BY Customer_ID, Customer_Name
HAVING COUNT(DISTINCT Region) > 1;




-- Business Case Insights 
-- Q31 Sub-categories consistently generate losses.
SELECT
	Sub_category,
    YEAR(Order_Date) AS order_year,
    SUM(Profit) AS yearly_profit
FROM Orders
GROUP BY Sub_category, YEAR(Order_Date)
HAVING SUM(Profit) < 0
ORDER BY Sub_category, order_year;


-- Q32 Products are heavily discounted but still unprofitable.
SELECT 
	Product_ID,
    Product_Name,
    ROUND(AVG(Discount), 2) AS avg_discount,
    SUM(Profit) AS total_profit
FROM Orders
GROUP BY Product_ID, Product_Name
HAVING AVG(Discount) > 0.40 AND SUM(Profit) < 0
ORDER BY total_profit;


-- Q33 Find regions where sales are high but profit margins are low.
SELECT
	Region,
    SUM(Sales) AS total_sales,
    SUM(Profit) AS total_profit,
	ROUND(SUM(Profit) / SUM(Sales) * 100, 2) AS profit_margin_pct
FROM Orders
GROUP BY Region
ORDER BY total_sales DESC;


-- Q34 Identify top performing products per year.
WITH product_yearly_sales AS
(
SELECT
	Product_ID,
    Product_Name,
    YEAR(Order_Date) AS order_year,
    SUM(Sales) AS total_sales,
    RANK() OVER(PARTITION BY YEAR(Order_Date) ORDER BY SUM(Sales)DESC) AS rnk
FROM orders
GROUP BY Product_ID, Product_Name, YEAR(Order_Date)
)
SELECT 
	Product_ID,
    Product_Name,
    order_year,
    total_sales
FROM product_yearly_sales
WHERE rnk = 1;


-- Q35 Find customers at risk of churn (customers who haven't ordered recently).
WITH days_gap AS
(
SELECT
	Customer_ID,
    Customer_Name,
    DATEDIFF((SELECT MAX(Order_Date) FROM Orders), MAX(Order_Date)) AS days_diff
FROM Orders
GROUP BY Customer_ID, Customer_Name
)
SELECT 
	Customer_ID,
    Customer_Name,
    days_diff
FROM days_gap
WHERE days_diff > 182
ORDER BY days_diff DESC;


-- RFM Customer Segmentation 
CREATE VIEW Customer_segmentation AS
WITH rfm_table AS
(
SELECT
	Customer_ID,
    Customer_Name,
    DATEDIFF((SELECT MAX(Order_Date) FROM Orders), MAX(Order_Date)) AS recency,
    COUNT(DISTINCT Order_ID) AS frequency,
    SUM(Sales) AS monetary 
FROM Orders
GROUP BY Customer_ID, Customer_Name
),
rfm_scores AS
(
SELECT
	Customer_ID,
    Customer_Name,
    NTILE(4) OVER(ORDER BY recency ASC) AS r_score,
    NTILE(4) OVER(ORDER BY frequency DESC) AS f_score,
    NTILE(4) OVER(ORDER BY monetary DESC) AS m_score
FROM rfm_table
)
SELECT
	Customer_ID,
    Customer_Name,
    CASE
		WHEN r_score = 4 AND f_score = 4 AND m_score = 4 THEN 'Champions'
        WHEN r_score >= 3 AND f_score >= 3 THEN 'Loyal'
        WHEN r_score = 4 AND f_score <= 2 THEN 'New_customers'
        WHEN r_score <= 2 AND f_score >= 3 THEN 'At_risk'
        WHEN r_score = 5 AND f_score = 1 THEN 'Lost_customers'
        ELSE 'Others'
	END AS rfm_segment
FROM rfm_scores
ORDER BY rfm_segment;

CREATE TABLE Customer_Segment (
SELECT * FROM Customer_segmentation)
;

SELECT Customer_ID, rfm_segment FROM Customer_segmentation;

SELECT
	rfm_segment,
    COUNT(*) AS Customers_count
FROM Customer_segmentation
GROUP BY rfm_segment
ORDER BY Customers_count;


-- Customer Sales Contribution 
WITH cust_sales AS
(
SELECT
	Customer_ID,
    Customer_Name,
    SUM(Sales) AS total_sale
FROM Orders
GROUP BY Customer_ID, Customer_Name
),
cust_percent AS
(
SELECT 
	Customer_ID,
	Customer_Name,
    total_sale / (SELECT SUM(Sales) FROM Orders) * 100 AS perc_contribution
FROM cust_sales
)
SELECT 
	Customer_ID,
	Customer_Name,
    perc_contribution,
    SUM(perc_contribution) OVER(ORDER BY perc_contribution DESC) AS cumulative_sale_perc
FROM cust_percent;


-- Discount vs Profitability Analysis
SELECT 
    CASE
		WHEN Discount < 0.10 THEN 'Low'
        WHEN Discount < 0.20 THEN 'Moderate'
        WHEN Discount < 0.30 THEN 'Medium'
        WHEN Discount < 0.40 THEN 'High'
        ELSE 'VeryHigh'
	END AS Discount_band,
    SUM(Sales) AS total_sales,
    SUM(Profit) AS total_profit,
    ROUND(AVG(Profit), 2) AS avg_profit,
    ROUND(SUM(Profit)/SUM(Sales)*100, 2) AS profit_margin
FROM Orders
GROUP BY Discount_band
ORDER BY total_sales DESC;


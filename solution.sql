--Monday Cofee -- Data Analysis
select * from city;
select * from products;
select * from customers;
select * from sales;

--Reports & data Analysis

-- Q1 Cofee consumers count
-- How many people in each city are estimated to consume cofee, given that 25% of the poulation does?

select 
  city_name,
  round((population * 0.25)/1000000,2) as cofee_consumers_in_millions,
  city_rank
from city order by 2 desc;

--Q2 Total revenue from cofee sales
-- What is the total revenue generated from cofee sales across all cities in the last quarter of 2023?

select 
 ci.city_name,
 sum(s.total) as total_revenue
from sales as s
join customers as c
on s.customer_id = c.customer_id
join city as ci
on ci.city_id = c.city_id
  where
  extract(year from s.sale_date)=2023
  and
   extract(quarter from s.sale_date)=4
group by 1 order by 2 desc;

--Q3 Sales count for each product 
-- How many units of each cofee product have been sold?

select
   p.product_name,
   count(s.sale_id) as tottal_orders
from products as p 
left join
sales as s
on s.product_id=p.product_id 
group by 1 order by 2 desc;
   
--Q4 Average sales amount per city
--What is the average sales amount per customer in each city?

select 
 ci.city_name,
 sum(s.total) as total_revenue,
 count( distinct s.customer_id) as total_cx,
 round(sum(s.total)::numeric /count( distinct s.customer_id)::numeric,2) as avg_sales_per_cx
from sales as s
join customers as c
on s.customer_id = c.customer_id
join city as ci
on ci.city_id = c.city_id
group by 1 order by 2 desc;   

--Q5 City population and cofee consumers
-- Provide a list of cities along with populations and estimated cofee consumers

WITH city_table as 
(
	SELECT 
		city_name,
		ROUND((population * 0.25)/1000000, 2) as coffee_consumers
	FROM city
),
customers_table
AS
(
	SELECT 
		ci.city_name,
		COUNT(DISTINCT c.customer_id) as unique_cx
	FROM sales as s
	JOIN customers as c
	ON c.customer_id = s.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1
)
SELECT 
	customers_table.city_name,
	city_table.coffee_consumers as coffee_consumer_in_millions,
	customers_table.unique_cx
FROM city_table
JOIN 
customers_table
ON city_table.city_name = customers_table.city_name;
 
--Q6 Top selling product by city
-- what are the top 3 selling products in each city based on sales volume?

select
    ci.city_name,
	p.product_name,
	count(s.sale_id) as total_orders,
	dense_rank() over (partition by ci.city_name order by count(s.sale_id) desc)as rank
from sales as s
join products as p
on s.product_id=p.product_id
join  customers as c
on c.customer_id = s.customer_id
join city as ci
on ci.city_id=c.city_id
group by 1,2 ;

select* 
from (
select
    ci.city_name,
	p.product_name,
	count(s.sale_id) as total_orders,
	dense_rank() over (partition by ci.city_name order by count(s.sale_id) desc)as rank
from sales as s
join products as p
on s.product_id=p.product_id
join  customers as c
on c.customer_id = s.customer_id
join city as ci
on ci.city_id=c.city_id
group by 1,2 
) as t1 where rank <=3;

--Q7 Customer segmentation by city
--How many unique customers are there in each city who have purchased cofee product

select 
  ci.city_name,
  count(distinct c.customer_id) as unique_cx
from city as ci
left join 
customers as c
on c.city_id = ci.city_id
join sales as s
on s.customer_id=c.customer_id
where 
  s.product_id in (1,2,3,4,5,6,7,8,9,10,11,12,13,14)
group by 1;

--Q8 Impact on estimated rent on sales
-- Find each city and their avg sales per customer and avgerage rent per customer

with city_table as(
select 
 ci.city_name,
 count( distinct s.customer_id) as total_cx,
 round(sum(s.total)::numeric /count( distinct s.customer_id)::numeric,2) as avg_sales_per_cx
from sales as s
join customers as c
on s.customer_id = c.customer_id
join city as ci
on ci.city_id = c.city_id
group by 1 order by 2 desc),
city_rent as (
select
  city_name,
  estimated_rent
from city) 
select
  cr.city_name,
  cr.estimated_rent,
  ct.total_cx,
  ct.avg_sales_per_cx,
  round(cr.estimated_rent::numeric/ct.total_cx::numeric,2) as avg_rent_per_cx
from city_rent as cr
join
city_table as ct
on cr.city_name=ct.city_name order by 4 desc;

--Q9 Monthly sales growth
-- Calculate the percentage growth in sales over different time periods (monthly) by each city


WITH
monthly_sales
AS
(
	SELECT 
		ci.city_name,
		EXTRACT(MONTH FROM sale_date) as month,
		EXTRACT(YEAR FROM sale_date) as YEAR,
		SUM(s.total) as total_sale
	FROM sales as s
	JOIN customers as c
	ON c.customer_id = s.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1, 2, 3
	ORDER BY 1, 3, 2
),
growth_ratio
AS
(
		SELECT
			city_name,
			month,
			year,
			total_sale as cr_month_sale,
			LAG(total_sale, 1) OVER(PARTITION BY city_name ORDER BY year, month) as last_month_sale
		FROM monthly_sales
)

SELECT
	city_name,
	month,
	year,
	cr_month_sale,
	last_month_sale,
	ROUND(
		(cr_month_sale-last_month_sale)::numeric/last_month_sale::numeric * 100
		, 2
		) as growth_ratio

FROM growth_ratio
WHERE 
	last_month_sale IS NOT NULL	;

-- Q.10 Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer


WITH city_table AS (
    SELECT 
        ci.city_name,
        SUM(s.total) as total_revenue,
        COUNT(DISTINCT s.customer_id) as total_cx,
        ROUND(
            SUM(s.total)::numeric/
            COUNT(DISTINCT s.customer_id)::numeric
        ,2) as avg_sale_pr_cx
    FROM sales as s
    JOIN customers as c
        ON s.customer_id = c.customer_id
    JOIN city as ci
        ON ci.city_id = c.city_id
    GROUP BY 1
    ORDER BY 2 DESC
),
city_rent AS (
    SELECT 
        city_name, 
        estimated_rent,
        ROUND((population * 0.25)/1000000, 3) as estimated_coffee_consumer_in_millions
    FROM city
)
SELECT 
    cr.city_name,
    total_revenue,
    cr.estimated_rent as total_rent,
    ct.total_cx,
    estimated_coffee_consumer_in_millions,
    ct.avg_sale_pr_cx,
    ROUND(
        cr.estimated_rent::numeric/
        ct.total_cx::numeric
    , 2) as avg_rent_per_cx
FROM city_rent as cr
JOIN city_table as ct
    ON cr.city_name = ct.city_name
ORDER BY 2 DESC
LIMIT 3;



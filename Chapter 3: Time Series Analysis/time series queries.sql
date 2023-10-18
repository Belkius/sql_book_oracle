-- Trending the data
-- Simple trends 

SELECT sales_month, sales
FROM retail_sales
WHERE kind_of_business = 'Retail and food services sales, total'
ORDER BY 1;

-- Use extract(year from sales_month) or to_char(sales_month, 'YYYY')

SELECT EXTRACT(YEAR FROM sales_month) AS sales_year, SUM(sales) AS sales
FROM retail_sales
WHERE kind_of_business = 'Retail and food services sales, total'
GROUP BY EXTRACT(YEAR FROM sales_month)
ORDER BY 1;
 
-- Comparing components
 
SELECT EXTRACT(YEAR FROM sales_month) AS sales_year, kind_of_business, SUM(sales) AS sales
FROM retail_sales
WHERE kind_of_business IN ('Book stores', 'Sporting goods stores', 'Hobby, toy, and game stores')
GROUP BY EXTRACT(YEAR FROM sales_month), kind_of_business
ORDER BY 1,2;
 
SELECT sales_month, kind_of_business, sales
FROM retail_sales
WHERE kind_of_business IN ('Men''s clothing stores', 'Women''s clothing stores')
ORDER BY 1,2;
 
SELECT EXTRACT(YEAR FROM sales_month) AS sales_year, kind_of_business, SUM(sales) AS sales
FROM retail_sales
WHERE kind_of_business IN ('Men''s clothing stores', 'Women''s clothing stores')
GROUP BY EXTRACT(YEAR FROM sales_month), kind_of_business;
 
SELECT EXTRACT(YEAR FROM sales_month) AS sales_year, SUM(CASE WHEN kind_of_business = 'Women''s clothing stores' THEN sales END) AS womens_sales,
SUM(CASE WHEN kind_of_business = 'Men''s clothing stores' THEN sales END) AS mens_sales
FROM retail_sales
WHERE kind_of_business IN ('Men''s clothing stores', 'Women''s clothing stores')
GROUP BY EXTRACT(YEAR FROM sales_month)
ORDER BY 1;
 
SELECT sales_year, womens_sales - mens_sales AS womens_minus_mens, mens_sales - womens_sales AS mens_minus_womens
FROM
(
        SELECT EXTRACT(YEAR FROM sales_month) AS sales_year, SUM(CASE WHEN kind_of_business = 'Women''s clothing stores' THEN sales END) AS womens_sales,
        SUM(CASE WHEN kind_of_business = 'Men''s clothing stores' THEN sales END) AS mens_sales
        FROM retail_sales
        WHERE kind_of_business IN ('Men''s clothing stores', 'Women''s clothing stores') AND sales_month <= '2019-12-01'
        GROUP BY EXTRACT(YEAR FROM sales_month)
)
ORDER BY 1;
 
SELECT EXTRACT(YEAR FROM sales_month) AS sales_year, 
SUM(CASE WHEN kind_of_business = 'Women''s clothing stores' THEN sales END)
- SUM(CASE WHEN kind_of_business = 'Men''s clothing stores' THEN sales END) AS womens_minus_mens
FROM retail_sales
WHERE kind_of_business IN ('Men''s clothing stores', 'Women''s clothing stores') AND sales_month <= '2019-12-01'
GROUP BY EXTRACT(YEAR FROM sales_month)
ORDER BY 1;
 
SELECT sales_year, womens_sales / mens_sales AS womens_times_of_mens
FROM
(
        SELECT EXTRACT(YEAR FROM sales_month) AS sales_year,
        SUM(CASE WHEN kind_of_business = 'Women''s clothing stores' THEN sales END) AS womens_sales,
        SUM(CASE WHEN kind_of_business = 'Men''s clothing stores' THEN sales END) AS mens_sales
        FROM retail_sales
        WHERE kind_of_business IN ('Men''s clothing stores','Women''s clothing stores') AND sales_month <= '2019-12-01'
        GROUP BY EXTRACT(YEAR FROM sales_month)
)
ORDER BY 1;
 
SELECT sales_year, (womens_sales / mens_sales - 1) * 100 AS womens_pct_of_mens
FROM
(
        SELECT EXTRACT(YEAR FROM sales_month) AS sales_year,
        SUM(CASE WHEN kind_of_business = 'Women''s clothing stores' THEN sales END) AS womens_sales,
        SUM(CASE WHEN kind_of_business = 'Men''s clothing stores' THEN sales END) AS mens_sales
        FROM retail_sales
        WHERE kind_of_business IN ('Men''s clothing stores','Women''s clothing stores') AND sales_month <= '2019-12-01'
        GROUP BY EXTRACT(YEAR FROM sales_month)
)
ORDER BY 1;
 
-- Percent of total calculations
 
SELECT sales_month, kind_of_business, sales * 100 / total_sales AS pct_total_sales
FROM
(
        SELECT a.sales_month, a.kind_of_business, a.sales, SUM(b.sales) AS total_sales
        FROM retail_sales a
        JOIN retail_sales b ON a.sales_month = b.sales_month
        AND b.kind_of_business IN ('Men''s clothing stores', 'Women''s clothing stores')
        WHERE a.kind_of_business IN ('Men''s clothing stores', 'Women''s clothing stores')
        GROUP BY a.sales_month, a.kind_of_business, a.sales
)
ORDER BY 1,2;
 
SELECT sales_month, kind_of_business, sales, SUM(sales) over (PARTITION BY sales_month) AS total_sales,
sales * 100 / SUM(sales) over (PARTITION BY sales_month) AS pct_total
FROM retail_sales 
WHERE kind_of_business IN ('Men''s clothing stores', 'Women''s clothing stores')
ORDER BY 1;
 
SELECT sales_month, kind_of_business, sales * 100 / yearly_sales AS pct_yearly
FROM
(
        SELECT a.sales_month, a.kind_of_business, a.sales, SUM(b.sales) AS yearly_sales
        FROM retail_sales a
        JOIN retail_sales b ON EXTRACT(YEAR FROM a.sales_month) = EXTRACT(YEAR FROM b.sales_month)
        AND a.kind_of_business = b.kind_of_business
        AND b.kind_of_business IN ('Men''s clothing stores', 'Women''s clothing stores')
        WHERE a.kind_of_business IN ('Men''s clothing stores', 'Women''s clothing stores')
        GROUP BY a.sales_month, a.kind_of_business, a.sales
)
ORDER BY 1,2;
 
SELECT sales_month, kind_of_business, sales,
SUM(sales) over (PARTITION BY EXTRACT(YEAR FROM sales_month), kind_of_business) AS yearly_sales,
sales * 100 / SUM(sales) over (PARTITION BY EXTRACT(YEAR FROM sales_month), kind_of_business) AS pct_yearly
FROM retail_sales 
WHERE kind_of_business IN ('Men''s clothing stores', 'Women''s clothing stores')
ORDER BY 1,2;
 
SELECT sales_year, sales, FIRST_VALUE(sales) over (ORDER BY sales_year) AS index_sales,
(sales / FIRST_VALUE(sales) over (ORDER BY sales_year) - 1) * 100
FROM
(
    SELECT EXTRACT(YEAR FROM sales_month) AS sales_year, SUM(sales) AS sales
    FROM retail_sales
    WHERE kind_of_business = 'Women''s clothing stores'
    GROUP BY EXTRACT(YEAR FROM sales_month)
);
 
SELECT sales_year, sales,(sales / index_sales - 1) * 100 AS pct_from_index
FROM
(
        SELECT EXTRACT(YEAR FROM aa.sales_month) AS sales_year, bb.index_sales, SUM(aa.sales) AS sales
        FROM retail_sales aa
        JOIN 
        (
                SELECT first_year, SUM(a.sales) AS index_sales
                FROM retail_sales a
                JOIN 
                (
                        SELECT MIN(EXTRACT(YEAR FROM sales_month)) AS first_year
                        FROM retail_sales
                        WHERE kind_of_business = 'Women''s clothing stores'
                ) b ON EXTRACT(YEAR FROM a.sales_month) = b.first_year 
                WHERE a.kind_of_business = 'Women''s clothing stores'
                GROUP BY first_year
        ) bb ON 1 = 1
        WHERE aa.kind_of_business = 'Women''s clothing stores'
        GROUP BY EXTRACT(YEAR FROM aa.sales_month), bb.index_sales
);
 
SELECT sales_year, kind_of_business, sales,
(sales / FIRST_VALUE(sales) over (PARTITION BY kind_of_business ORDER BY sales_year) - 1) * 100 AS pct_from_index
FROM
(
        SELECT EXTRACT(YEAR FROM sales_month) AS sales_year, kind_of_business, SUM(sales) AS sales
        FROM retail_sales
        WHERE kind_of_business IN ('Men''s clothing stores','Women''s clothing stores')  AND sales_month <= '2019-12-31'
GROUP BY EXTRACT(YEAR FROM sales_month), kind_of_business
);
 
------- Rolling time windows
-- Calculating rolling time windows
 
--use  interval '11' month or add_months(a.sales_month, -2)
SELECT a.sales_month, a.sales, b.sales_month AS rolling_sales_month, b.sales AS rolling_sales
FROM retail_sales a
JOIN retail_sales b ON a.kind_of_business = b.kind_of_business 
 AND b.sales_month BETWEEN a.sales_month - INTERVAL '11' MONTH 
 AND a.sales_month
 AND b.kind_of_business = 'Women''s clothing stores'
WHERE a.kind_of_business = 'Women''s clothing stores' AND a.sales_month = '2019-12-01';
 
SELECT a.sales_month, a.sales, ROUND(AVG(b.sales), 2) AS moving_avg, COUNT(b.sales) AS records_count
FROM retail_sales a
JOIN retail_sales b ON a.kind_of_business = b.kind_of_business 
 AND b.sales_month BETWEEN a.sales_month - INTERVAL '11' MONTH AND a.sales_month
 AND b.kind_of_business = 'Women''s clothing stores'
WHERE a.kind_of_business = 'Women''s clothing stores' AND a.sales_month >= '1993-01-01'
GROUP BY a.sales_month, a.sales
ORDER BY 1;
 
SELECT sales_month,
ROUND(AVG(sales) over (ORDER BY sales_month rows BETWEEN 11 preceding AND CURRENT ROW), 2) AS moving_avg,
COUNT(sales) over (ORDER BY sales_month rows BETWEEN 11 preceding AND CURRENT ROW) AS records_count
FROM retail_sales
WHERE kind_of_business = 'Women''s clothing stores';
 
-- Rolling time windows with sparse data
 
SELECT a.date_format, b.sales_month, b.sales
FROM date_dim a
JOIN 
(
        SELECT sales_month, sales
        FROM retail_sales 
        WHERE kind_of_business = 'Women''s clothing stores' 
        AND EXTRACT(MONTH FROM sales_month) IN (1,7) -- here we're artificially creating sparse data by limiting the months returned
) b ON b.sales_month BETWEEN a.date_format - INTERVAL '11' MONTH AND a.date_format
WHERE a.date_format = a.first_day_of_month AND a.date_format BETWEEN '1993-01-01' AND '2020-12-01'
ORDER BY 1,2;
 
SELECT a.date_format, AVG(b.sales) AS moving_avg, COUNT(b.sales) AS records
--,max(case when a.date_format = b.sales_month then b.sales end) as sales_in_month
FROM date_dim a
JOIN 
(
        SELECT sales_month, sales
        FROM retail_sales 
        WHERE kind_of_business = 'Women''s clothing stores' AND EXTRACT(MONTH FROM sales_month) IN (1,7)
) b ON b.sales_month BETWEEN a.date_format - INTERVAL '11' MONTH AND a.date_format
WHERE a.date_format = a.first_day_of_month AND a.date_format BETWEEN '1993-01-01' AND '2020-12-01'
GROUP BY a.date_format
ORDER BY 1;
 
SELECT a.sales_month, ROUND(AVG(b.sales), 2) AS moving_avg
FROM
(
        SELECT DISTINCT sales_month
        FROM retail_sales
        WHERE sales_month BETWEEN '1993-01-01' AND '2020-12-01'
) a
JOIN retail_sales b ON b.sales_month BETWEEN a.sales_month - INTERVAL '11' MONTH AND a.sales_month
AND b.kind_of_business = 'Women''s clothing stores' 
GROUP BY a.sales_month
ORDER BY 1;
 
-- Calculating cumulative values
SELECT sales_month, sales,
SUM(sales) over (PARTITION BY EXTRACT(YEAR FROM sales_month) ORDER BY sales_month) AS sales_ytd
FROM retail_sales
WHERE kind_of_business = 'Women''s clothing stores';
 
SELECT a.sales_month, a.sales, SUM(b.sales) AS sales_ytd
FROM retail_sales a
JOIN retail_sales b ON EXTRACT(YEAR FROM a.sales_month) = EXTRACT(YEAR FROM b.sales_month)
 AND b.sales_month <= a.sales_month
 AND b.kind_of_business = 'Women''s clothing stores'
WHERE a.kind_of_business = 'Women''s clothing stores'
GROUP BY a.sales_month, a.sales
ORDER BY 1;
 
------- Analyzing with seasonality
-- Period over period comparisons
 
SELECT kind_of_business, sales_month, sales,
LAG(sales_month) over (PARTITION BY kind_of_business ORDER BY sales_month) AS prev_month,
LAG(sales) over (PARTITION BY kind_of_business ORDER BY sales_month) AS prev_month_sales
FROM retail_sales
WHERE kind_of_business = 'Book stores';
 
SELECT kind_of_business, sales_month, sales,
(sales / LAG(sales) over (PARTITION BY kind_of_business ORDER BY sales_month) - 1) * 100 AS pct_growth_from_previous
FROM retail_sales
WHERE kind_of_business = 'Book stores';
 
SELECT sales_year, yearly_sales,
LAG(yearly_sales) over (ORDER BY sales_year) AS prev_year_sales,
ROUND((yearly_sales / LAG(yearly_sales) over (ORDER BY sales_year) -1) * 100, 2) AS pct_growth_from_previous
FROM
(
        SELECT EXTRACT(YEAR FROM sales_month) AS sales_year, SUM(sales) AS yearly_sales
        FROM retail_sales
        WHERE kind_of_business = 'Book stores'
        GROUP BY EXTRACT(YEAR FROM sales_month)
);
 
-- Period over period comparisons - Same month vs. last year
 
SELECT sales_month, EXTRACT(MONTH FROM sales_month)
FROM retail_sales
WHERE kind_of_business = 'Book stores';
 
SELECT sales_month, sales,
LAG(sales_month) over (PARTITION BY EXTRACT(MONTH FROM sales_month) ORDER BY sales_month) AS prev_year_month,
LAG(sales) over (PARTITION BY EXTRACT(MONTH FROM sales_month) ORDER BY sales_month) AS prev_year_sales
FROM retail_sales
WHERE kind_of_business = 'Book stores';
 
SELECT sales_month, sales,
sales - LAG(sales) over (PARTITION BY EXTRACT(MONTH FROM sales_month) ORDER BY sales_month) AS absolute_diff,
ROUND((sales / LAG(sales) over (PARTITION BY EXTRACT(MONTH FROM sales_month) ORDER BY sales_month) - 1) * 100, 2) AS pct_diff
FROM retail_sales
WHERE kind_of_business = 'Book stores';
 
SELECT EXTRACT(MONTH FROM sales_month) AS month_number, TO_CHAR(sales_month, 'Month') AS month_name,
MAX(CASE WHEN EXTRACT(YEAR FROM sales_month) = 1992 THEN sales END) AS sales_1992,
MAX(CASE WHEN EXTRACT(YEAR FROM sales_month) = 1993 THEN sales END) AS sales_1993,
MAX(CASE WHEN EXTRACT(YEAR FROM sales_month) = 1994 THEN sales END) AS sales_1994
FROM retail_sales
WHERE kind_of_business = 'Book stores' AND sales_month BETWEEN '1992-01-01' AND '1994-12-01'
GROUP BY EXTRACT(MONTH FROM sales_month), TO_CHAR(sales_month, 'Month');
 
-- Comparing to multiple prior periods

SELECT sales_month, sales,
LAG(sales, 1) over (PARTITION BY EXTRACT(MONTH FROM sales_month) ORDER BY sales_month) AS prev_sales_1,
LAG(sales, 2) over (PARTITION BY EXTRACT(MONTH FROM sales_month) ORDER BY sales_month) AS prev_sales_2,
LAG(sales, 3) over (PARTITION BY EXTRACT(MONTH FROM sales_month) ORDER BY sales_month) AS prev_sales_3
FROM retail_sales
WHERE kind_of_business = 'Book stores';
 
SELECT sales_month, sales, 
ROUND(sales / ((prev_sales_1 + prev_sales_2 + prev_sales_3) / 3) * 100, 2) AS pct_of_3_prev
FROM 
(
    SELECT sales_month, sales,
    LAG(sales, 1) over (PARTITION BY EXTRACT(MONTH FROM sales_month) ORDER BY sales_month) AS prev_sales_1,
    LAG(sales, 2) over (PARTITION BY EXTRACT(MONTH FROM sales_month) ORDER BY sales_month) AS prev_sales_2,
    LAG(sales, 3) over (PARTITION BY EXTRACT(MONTH FROM sales_month) ORDER BY sales_month) AS prev_sales_3
    FROM retail_sales
    WHERE kind_of_business = 'Book stores'
);
 
SELECT sales_month, sales,
ROUND(sales / AVG(sales) over (PARTITION BY EXTRACT(MONTH FROM sales_month) ORDER BY sales_month rows BETWEEN 3 preceding AND 1 preceding) * 100, 2) 
AS pct_of_prev_3
FROM retail_sales
WHERE kind_of_business = 'Book stores';

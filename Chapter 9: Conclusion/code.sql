------------------------------------- funnel --------------------------------------------------------------------
-- note this is pseudocode
 
SELECT count(a.user_id) as all_users,
count(b.user_id) as step_one_users,
count(b.user_id) / count(a.user_id) as pct_step_one,
count(c.user_id) as step_two_users,
count(c.user_id) / count(b.user_id) as pct_one_to_two
FROM users a
LEFT JOIN step_one b on a.user_id = b.user_id
LEFT JOIN step_two c on b.user_id = c.user_id;
 
SELECT count(a.user_id) as all_users,
count(b.user_id) as step_one_users,
count(b.user_id) / count(a.user_id) as pct_step_one,
count(c.user_id) as step_two_users,
count(c.user_id) / count(b.user_id) as pct_step_two
FROM users a
LEFT JOIN step_one b on a.user_id = b.user_id
LEFT JOIN step_two c on a.user_id = c.user_id;
 
------------------------------------- churn, lapse --------------------------------------------------------------------
-- these examples use the legislators data set, which can be found in the Chapter 4 directory
 
-- average gaps
 
-- gap is shown in days
SELECT round(avg(gap_interval), 4) as avg_gap
FROM
(
        SELECT id_bioguide, term_start,
        lag(term_start) over (partition by id_bioguide order by term_start) as prev,
        term_start - lag(term_start) over (partition by id_bioguide order by term_start) as gap_interval
        FROM legislators_terms
        WHERE term_type = 'rep'
) a
WHERE gap_interval is not null;
 
SELECT gap_months, count(*)
FROM
(
        SELECT id_bioguide, term_start,
        lag(term_start) over (partition by id_bioguide order by term_start) as prev,
        term_start - lag(term_start) over (partition by id_bioguide order by term_start) as gap_interval,
        round(months_between(term_start, lag(term_start) over (partition by id_bioguide order by term_start))) as gap_months
        FROM legislators_terms
        WHERE term_type = 'rep'
) a
WHERE gap_months is not null
GROUP BY gap_months;
 
-- days since last
SELECT years_since_last,
count(*) as reps
FROM
(
        SELECT id_bioguide,
        max(term_start) as max_date,
        extract(year from to_date('2020-05-19')) - extract(year from max(term_start)) as years_since_last
        FROM legislators_terms
        WHERE term_type = 'rep'
        GROUP BY id_bioguide
) a
GROUP BY years_since_last
ORDER BY 1;
 
-- count by churn status
SELECT 
case when months_since_last <= 23 then 'Current'
     when months_since_last <= 48 then 'Lapsed'
     else 'Churned' 
     end as status,
sum(reps) as total_reps     
FROM
(
        SELECT id_bioguide,
         round(months_between(to_date('2020-05-19'), term_start)) as months_since_last,
         count(*) as reps
        FROM legislators_terms
        WHERE term_type = 'rep'
        GROUP BY id_bioguide, round(months_between(to_date('2020-05-19'), term_start))
) 
GROUP BY 
case when months_since_last <= 23 then 'Current'
     when months_since_last <= 48 then 'Lapsed'
     else 'Churned' 
     end;
 
------------------------------------- basket analysis --------------------------------------------------------------------
-- note this is pseudocode
 
SELECT product1, product2,
count(customer_id) as customers
FROM
(
        SELECT a.customer_id,
        a.product as product1,
        b.product as product2
        FROM purchases a
        JOIN purchases b on a.customer_id = b.customer_id and b.product > a.product
)
GROUP BY product1, product2
ORDER BY 3 desc;
 
SELECT products, count(customer_id) as customers
FROM
(
        SELECT customer_id, listagg(product,', ') within group (order by product asc) as products
        FROM purchases
        GROUP BY customer_id
)
GROUP BY products
ORDER BY 2 desc;
 

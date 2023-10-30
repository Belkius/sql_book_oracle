------ Types of experiments
-- Experiments with binary outcomes
 
SELECT a.variant,
count(a.user_id) as total_cohorted,
count(b.user_id) as completions,
round(count(b.user_id) / count(a.user_id), 4) as pct_completed
FROM exp_assignment a
LEFT JOIN game_actions b on a.user_id = b.user_id
and b.action = 'onboarding complete'
WHERE a.exp_name = 'Onboarding'
GROUP BY a.variant;
 
-- Experiments with continuous outcomes
 
SELECT variant,
count(user_id) as total_cohorted,
round(avg(amount), 4) as mean_amount,
round(stddev(amount), 4) as stddev_amount
FROM
(
        SELECT a.variant, a.user_id,
        sum(coalesce(b.amount,0)) as amount
        FROM exp_assignment a
        LEFT JOIN game_purchases b on a.user_id = b.user_id
        WHERE a.exp_name = 'Onboarding'
        GROUP BY a.variant, a.user_id
)
GROUP BY variant;
 
SELECT variant,
count(user_id) as total_cohorted,
round(avg(amount), 4) as mean_amount,
round(stddev(amount), 4) as stddev_amount
FROM
(
        SELECT a.variant, a.user_id,
        sum(coalesce(b.amount,0)) as amount
        FROM exp_assignment a
        LEFT JOIN game_purchases b on a.user_id = b.user_id
        JOIN game_actions c on a.user_id = c.user_id
        and c.action = 'onboarding complete'
        WHERE a.exp_name = 'Onboarding'
        GROUP BY a.variant, a.user_id
) 
GROUP BY variant;
 
------ Challenges with experiments
-- Outliers
 
SELECT a.variant,
count(distinct a.user_id) as total_cohorted,
count(distinct b.user_id) as purchasers,
round(count(distinct b.user_id) / count(distinct a.user_id), 4) as pct_purchased
FROM exp_assignment a
LEFT JOIN game_purchases b on a.user_id = b.user_id
JOIN game_actions c on a.user_id = c.user_id
and c.action = 'onboarding complete'
WHERE a.exp_name = 'Onboarding'
GROUP BY a.variant;
 
-- Time boxing
SELECT variant, count(user_id) as total_cohorted,
round(avg(amount), 4) as mean_amount, round(stddev(amount), 4) as stddev_amount
FROM
(
        SELECT a.variant, a.user_id,
        sum(coalesce(b.amount,0)) as amount
        FROM exp_assignment a
        LEFT JOIN game_purchases b on a.user_id = b.user_id 
        and b.purch_date <= a.exp_date + interval '7' day
        WHERE a.exp_name = 'Onboarding'
        GROUP BY a.variant, a.user_id
) 
GROUP BY variant;
 
------ When controlled experiments aren't possible
-- Pre-/post- analysis
 
SELECT 
case when a.created between '2020-01-13' and '2020-01-26' then 'pre'
     when a.created between '2020-01-27' and '2020-02-09' then 'post'
     end as variant,
count(distinct a.user_id) as cohorted,
count(distinct b.user_id) as opted_in,
round(count(distinct b.user_id) / count(distinct a.user_id), 4) as pct_optin,
count(distinct a.created) as days
FROM game_users a
LEFT JOIN game_actions b on a.user_id = b.user_id 
and b.action = 'email_optin'
WHERE a.created between '2020-01-13' and '2020-02-09'
GROUP BY 
case when a.created between '2020-01-13' and '2020-01-26' then 'pre'
     when a.created between '2020-01-27' and '2020-02-09' then 'post'
     end;
 
-- Natural experiment analysis
 
SELECT a.country,
count(distinct a.user_id) as total_cohorted,
count(distinct b.user_id) as purchasers,
round(count(distinct b.user_id) / count(distinct a.user_id), 4) as pct_purchased
FROM game_users a
LEFT JOIN game_purchases b on a.user_id = b.user_id
WHERE a.country in ('United States','Canada')
GROUP BY a.country;
 

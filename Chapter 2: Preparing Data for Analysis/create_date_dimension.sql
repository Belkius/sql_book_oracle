-- delete the table if it already exist

BEGIN
   EXECUTE IMMEDIATE 'DROP table date_dim';
EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE != -942 THEN
         RAISE;
      END IF;
END;

-- there are no public tables in Oracle, you can grant privileges to certain users instead

CREATE TABLE date_dim AS
SELECT 
date_val AS date_format,
TO_NUMBER(TO_CHAR(date_val, 'YYYYMMDD')) AS date_key,
TO_NUMBER(TO_CHAR(date_val, 'DD')) AS day_of_month,
TO_NUMBER(TO_CHAR(date_val, 'DDD')) AS day_of_year,
TO_NUMBER(TO_CHAR(date_val, 'D')) AS day_of_weak,
TRIM(TO_CHAR(date_val, 'Day')) AS day_name,
TRIM(TO_CHAR(date_val, 'Dy')) AS day_short_name,
TO_NUMBER(TO_CHAR(date_val, 'WW')) AS week_number,
TO_NUMBER(TO_CHAR(date_val, 'W')) AS week_of_month,
EXTRACT(YEAR FROM date_val) AS YEAR,
TO_NUMBER(TO_CHAR(date_val, 'Q')) AS quarter_number,
'Q' || TO_NUMBER(TO_CHAR(date_val, 'Q')) AS quarter_name,
TO_NUMBER(TO_CHAR(date_val, 'MM')) AS month_number,
TRIM(TO_CHAR(date_val, 'Month')) AS month_name,
TRIM(TO_CHAR(date_val, 'Mon')) AS month_short_name,
TRUNC(date_val, 'MM') AS first_day_of_month,
LAST_DAY(date_val) AS last_day_of_month,
TRUNC(date_val, 'Q') AS first_day_of_quarter,
LAST_DAY(ADD_MONTHS(TRUNC(date_val, 'Q'), 2)) AS last_day_of_quarter,
TO_NUMBER(TRUNC(TO_CHAR(date_val, 'YYYY')/10)*10) AS decade,
TO_NUMBER(CEIL(TO_CHAR(date_val, 'YYYY')/100)) AS century
FROM (SELECT TO_DATE('1770-01-01', 'YYYY-MM-DD') + LEVEL - 1 AS date_val
      FROM DUAL
      CONNECT BY LEVEL <= TO_DATE('2030-12-31', 'YYYY-MM-DD') - TO_DATE('1770-01-01', 'YYYY-MM-DD') + 1);

-- Basic retention
 
SELECT id_bioguide, MIN(term_start) AS first_term
FROM legislators_terms 
GROUP BY id_bioguide;
 
-- Use 'floor(months_between(b.term_start, a.first_term) / 12)', or 'floor((b.term_start - a.first_term) / 365)'
-- to get years between term_start and first_term
 
SELECT FLOOR(MONTHS_BETWEEN(b.term_start, a.first_term) / 12) AS periods,
COUNT(DISTINCT a.id_bioguide) AS cohort_retained
FROM
(
        SELECT id_bioguide, MIN(term_start) AS first_term
        FROM legislators_terms 
        GROUP BY id_bioguide
) a
JOIN legislators_terms b ON a.id_bioguide = b.id_bioguide 
GROUP BY FLOOR(MONTHS_BETWEEN(b.term_start, a.first_term) / 12)
ORDER BY 1;
 
SELECT period, FIRST_VALUE(cohort_retained) over (ORDER BY period) AS cohort_size, cohort_retained,
ROUND(cohort_retained * 1.0 / FIRST_VALUE(cohort_retained) over (ORDER BY period), 4) AS pct_retained
FROM
(
        SELECT FLOOR(MONTHS_BETWEEN(b.term_start, a.first_term) / 12) AS period,
        COUNT(DISTINCT a.id_bioguide) AS cohort_retained
        FROM
        (
                SELECT id_bioguide, MIN(term_start) AS first_term
                FROM legislators_terms 
                GROUP BY id_bioguide
        ) a
        JOIN legislators_terms b ON a.id_bioguide = b.id_bioguide 
        GROUP BY FLOOR(MONTHS_BETWEEN(b.term_start, a.first_term) / 12)
);
 
SELECT cohort_size,
MAX(CASE WHEN period = 0 THEN pct_retained END) AS yr0,
MAX(CASE WHEN period = 1 THEN pct_retained END) AS yr1,
MAX(CASE WHEN period = 2 THEN pct_retained END) AS yr2,
MAX(CASE WHEN period = 3 THEN pct_retained END) AS yr3,
MAX(CASE WHEN period = 4 THEN pct_retained END) AS yr4
FROM
(
        SELECT period, FIRST_VALUE(cohort_retained) over (ORDER BY period) AS cohort_size, cohort_retained,
        ROUND(cohort_retained * 1.0 / FIRST_VALUE(cohort_retained) over (ORDER BY period), 4) AS pct_retained
        FROM
        (
                SELECT FLOOR(MONTHS_BETWEEN(b.term_start, a.first_term) / 12) AS period,
                COUNT(DISTINCT a.id_bioguide) AS cohort_retained -- the author used count(*), wich altered results
                FROM
                (
                        SELECT id_bioguide, MIN(term_start) AS first_term
                        FROM legislators_terms 
                        GROUP BY id_bioguide
                ) a
                JOIN legislators_terms b ON a.id_bioguide = b.id_bioguide 
                GROUP BY FLOOR(MONTHS_BETWEEN(b.term_start, a.first_term) / 12)
        )
)
GROUP BY cohort_size;
 
-- Time adjustments
 
SELECT a.id_bioguide, a.first_term, b.term_start, b.term_end, c.date_format,
FLOOR(MONTHS_BETWEEN(c.date_format, a.first_term) / 12) AS period
FROM
(
        SELECT id_bioguide, MIN(term_start) AS first_term
        FROM legislators_terms 
        GROUP BY id_bioguide
) a
JOIN legislators_terms b ON a.id_bioguide = b.id_bioguide 
LEFT JOIN date_dim c ON c.date_format BETWEEN b.term_start AND b.term_end
AND c.month_number = 12 AND c.day_of_month = 31;
 
SELECT COALESCE(FLOOR(MONTHS_BETWEEN(c.date_format, a.first_term) / 12), 0) AS period,
COUNT(DISTINCT a.id_bioguide) AS cohort_retained
FROM
(
        SELECT id_bioguide, MIN(term_start) AS first_term
        FROM legislators_terms 
        GROUP BY id_bioguide
) a
JOIN legislators_terms b ON a.id_bioguide = b.id_bioguide 
LEFT JOIN date_dim c ON c.date_format BETWEEN b.term_start AND b.term_end
AND c.month_number = 12 AND c.day_of_month = 31
GROUP BY COALESCE(FLOOR(MONTHS_BETWEEN(c.date_format, a.first_term) / 12), 0)
ORDER BY 1;
 
SELECT period, FIRST_VALUE(cohort_retained) over (ORDER BY period) AS cohort_size,
cohort_retained, ROUND(cohort_retained * 1.0 / FIRST_VALUE(cohort_retained) over (ORDER BY period), 4) AS pct_retained
FROM
(
        SELECT COALESCE(FLOOR(MONTHS_BETWEEN(c.date_format, a.first_term) / 12), 0) AS period,
        COUNT(DISTINCT a.id_bioguide) AS cohort_retained
        FROM
        (
                SELECT id_bioguide, MIN(term_start) AS first_term
                FROM legislators_terms 
                GROUP BY id_bioguide
        ) a
        JOIN legislators_terms b ON a.id_bioguide = b.id_bioguide 
        LEFT JOIN date_dim c ON c.date_format BETWEEN b.term_start AND b.term_end 
        AND c.month_number = 12 AND c.day_of_month = 31
        GROUP BY COALESCE(FLOOR(MONTHS_BETWEEN(c.date_format, a.first_term) / 12), 0)
);
 
SELECT a.id_bioguide, a.first_term, b.term_start,
CASE WHEN b.term_type = 'rep' THEN b.term_start + INTERVAL '2' YEAR
     WHEN b.term_type = 'sen' THEN b.term_start + INTERVAL '6' YEAR
END AS term_end
FROM
(
        SELECT id_bioguide, MIN(term_start) AS first_term
        FROM legislators_terms 
        GROUP BY id_bioguide
) a
JOIN legislators_terms b ON a.id_bioguide = b.id_bioguide;
 
SELECT a.id_bioguide, a.first_term, b.term_start,
LEAD(b.term_start) over (PARTITION BY a.id_bioguide ORDER BY b.term_start) - INTERVAL '1' DAY AS term_end
FROM
(
        SELECT id_bioguide, MIN(term_start) AS first_term
        FROM legislators_terms 
        GROUP BY id_bioguide
) a
JOIN legislators_terms b ON a.id_bioguide = b.id_bioguide 
ORDER BY 1, 3;
 
-- Time-based cohorts derived from the time-series
 
SELECT EXTRACT(YEAR FROM a.first_term) AS first_year,
COALESCE(FLOOR(MONTHS_BETWEEN(c.date_format, a.first_term) / 12), 0) AS period,
COUNT(DISTINCT a.id_bioguide) AS cohort_retained
FROM
(
        SELECT id_bioguide, MIN(term_start) AS first_term
        FROM legislators_terms 
        GROUP BY id_bioguide
) a
JOIN legislators_terms b ON a.id_bioguide = b.id_bioguide 
LEFT JOIN date_dim c ON c.date_format BETWEEN b.term_start AND b.term_end
AND c.month_number = 12 AND c.day_of_month = 31
GROUP BY EXTRACT(YEAR FROM a.first_term),
COALESCE(FLOOR(MONTHS_BETWEEN(c.date_format, a.first_term) / 12), 0)
ORDER BY 1, 2;
 
SELECT first_year, period,
FIRST_VALUE(cohort_retained) over (PARTITION BY first_year ORDER BY period) AS cohort_size,
cohort_retained,
ROUND(cohort_retained * 1.0 / FIRST_VALUE(cohort_retained) over (PARTITION BY first_year ORDER BY period), 4) AS pct_retained
FROM
(
        SELECT EXTRACT(YEAR FROM a.first_term) AS first_year,
        COALESCE(FLOOR(MONTHS_BETWEEN(c.date_format, a.first_term) / 12), 0) AS period,
        COUNT(DISTINCT a.id_bioguide) AS cohort_retained
        FROM
        (
                SELECT id_bioguide, MIN(term_start) AS first_term
                FROM legislators_terms 
                GROUP BY id_bioguide
        ) a
        JOIN legislators_terms b ON a.id_bioguide = b.id_bioguide 
        LEFT JOIN date_dim c ON c.date_format BETWEEN b.term_start AND b.term_end
        AND c.month_number = 12 AND c.day_of_month = 31
        GROUP BY EXTRACT(YEAR FROM a.first_term),
        COALESCE(FLOOR(MONTHS_BETWEEN(c.date_format, a.first_term) / 12), 0)
)
ORDER BY 1, 2;
 
-- To get the century from a date use to_char() or ceil(year / 100)
SELECT first_century, period,
FIRST_VALUE(cohort_retained) over (PARTITION BY first_century ORDER BY period) AS cohort_size,
cohort_retained,
ROUND(cohort_retained * 1.0 / FIRST_VALUE(cohort_retained) over (PARTITION BY first_century ORDER BY period), 4) AS pct_retained
FROM
(
        SELECT TO_CHAR(a.first_term, 'CC') AS first_century,
        COALESCE(FLOOR(MONTHS_BETWEEN(c.date_format, a.first_term) / 12), 0) AS period,
        COUNT(DISTINCT a.id_bioguide) AS cohort_retained
        FROM
        (
                SELECT id_bioguide, MIN(term_start) AS first_term
                FROM legislators_terms 
                GROUP BY id_bioguide
        ) a
        JOIN legislators_terms b ON a.id_bioguide = b.id_bioguide 
        LEFT JOIN date_dim c ON c.date_format BETWEEN b.term_start AND b.term_end
        AND c.month_number = 12 AND c.day_of_month = 31
        GROUP BY TO_CHAR(a.first_term, 'CC'),
        COALESCE(FLOOR(MONTHS_BETWEEN(c.date_format, a.first_term) / 12), 0)
)
ORDER BY 1, 2;
 
SELECT DISTINCT id_bioguide, MIN(term_start) over (PARTITION BY id_bioguide) AS first_term,
FIRST_VALUE(state) over (PARTITION BY id_bioguide ORDER BY term_start) AS first_state
FROM legislators_terms;
 
SELECT first_state, period,
FIRST_VALUE(cohort_retained) over (PARTITION BY first_state ORDER BY period) AS cohort_size,
cohort_retained, 
ROUND(cohort_retained * 1.0 / FIRST_VALUE(cohort_retained) over (PARTITION BY first_state ORDER BY period), 4) AS pct_retained
FROM
(
        SELECT a.first_state,
        COALESCE(FLOOR(MONTHS_BETWEEN(c.date_format, a.first_term) / 12), 0) AS period,
        COUNT(DISTINCT a.id_bioguide) AS cohort_retained
        FROM
        (
                SELECT DISTINCT id_bioguide, MIN(term_start) over (PARTITION BY id_bioguide) AS first_term,
                FIRST_VALUE(state) over (PARTITION BY id_bioguide ORDER BY term_start) AS first_state
                FROM legislators_terms 
        ) a
        JOIN legislators_terms b ON a.id_bioguide = b.id_bioguide 
        LEFT JOIN date_dim c ON c.date_format BETWEEN b.term_start AND b.term_end 
        AND c.month_number = 12 AND c.day_of_month = 31
        GROUP BY a.first_state,
        COALESCE(FLOOR(MONTHS_BETWEEN(c.date_format, a.first_term) / 12), 0)
)
ORDER BY 1, 2;
 
-- Defining the cohort from a separate table
 
SELECT d.gender,
COALESCE(FLOOR(MONTHS_BETWEEN(c.date_format, a.first_term) / 12), 0) AS period,
COUNT(DISTINCT a.id_bioguide) AS cohort_retained
FROM
(
        SELECT id_bioguide, MIN(term_start) AS first_term
        FROM legislators_terms 
        GROUP BY id_bioguide
) a
JOIN legislators_terms b ON a.id_bioguide = b.id_bioguide 
LEFT JOIN date_dim c ON c.date_format BETWEEN b.term_start AND b.term_end 
AND c.month_number = 12 AND c.day_of_month = 31
JOIN legislators d ON a.id_bioguide = d.id_bioguide
GROUP BY d.gender,
COALESCE(FLOOR(MONTHS_BETWEEN(c.date_format, a.first_term) / 12), 0)
ORDER BY 2,1;
 
SELECT gender, period,
FIRST_VALUE(cohort_retained) over (PARTITION BY gender ORDER BY period) AS cohort_size,
cohort_retained,
ROUND(cohort_retained * 1.0 / FIRST_VALUE(cohort_retained) over (PARTITION BY gender ORDER BY period), 4) AS pct_retained
FROM
(
        SELECT d.gender,
        COALESCE(FLOOR(MONTHS_BETWEEN(c.date_format, a.first_term) / 12), 0) AS period,
        COUNT(DISTINCT a.id_bioguide) AS cohort_retained
        FROM
        (
                SELECT id_bioguide, MIN(term_start) AS first_term
                FROM legislators_terms 
                GROUP BY id_bioguide
        ) a
        JOIN legislators_terms b ON a.id_bioguide = b.id_bioguide 
        LEFT JOIN date_dim c ON c.date_format BETWEEN b.term_start AND b.term_end 
        AND c.month_number = 12 AND c.day_of_month = 31
        JOIN legislators d ON a.id_bioguide = d.id_bioguide
        GROUP BY d.gender,
        COALESCE(FLOOR(MONTHS_BETWEEN(c.date_format, a.first_term) / 12), 0)
)
ORDER BY 2, 1;
 
SELECT gender, period,
FIRST_VALUE(cohort_retained) over (PARTITION BY gender ORDER BY period) AS cohort_size,
cohort_retained,
ROUND(cohort_retained * 1.0 / FIRST_VALUE(cohort_retained) over (PARTITION BY gender ORDER BY period), 4) AS pct_retained
FROM
(
        SELECT d.gender,
        COALESCE(FLOOR(MONTHS_BETWEEN(c.date_format, a.first_term) / 12), 0) AS period,
        COUNT(DISTINCT a.id_bioguide) AS cohort_retained
        FROM
        (
                SELECT id_bioguide, MIN(term_start) AS first_term
                FROM legislators_terms 
                GROUP BY id_bioguide
        ) a
        JOIN legislators_terms b ON a.id_bioguide = b.id_bioguide 
        LEFT JOIN date_dim c ON c.date_format BETWEEN b.term_start AND b.term_end 
        AND c.month_number = 12 AND c.day_of_month = 31
        JOIN legislators d ON a.id_bioguide = d.id_bioguide
        WHERE a.first_term BETWEEN '1917-01-01' AND '1999-12-31'
        GROUP BY d.gender,
        COALESCE(FLOOR(MONTHS_BETWEEN(c.date_format, a.first_term) / 12), 0)
)
ORDER BY 2, 1;
 
----------- Dealing with sparse cohorts
 
SELECT first_state, gender, period,
FIRST_VALUE(cohort_retained) over (PARTITION BY first_state, gender ORDER BY period) AS cohort_size,
cohort_retained,
ROUND(cohort_retained / FIRST_VALUE(cohort_retained) over (PARTITION BY first_state, gender ORDER BY period), 4) AS pct_retained
FROM
(
        SELECT a.first_state, d.gender,
        COALESCE(FLOOR(MONTHS_BETWEEN(c.date_format, a.first_term) / 12), 0) AS period,
        COUNT(DISTINCT a.id_bioguide) AS cohort_retained
        FROM
        (
                SELECT DISTINCT id_bioguide,
                MIN(term_start) over (PARTITION BY id_bioguide) AS first_term,
                FIRST_VALUE(state) over (PARTITION BY id_bioguide ORDER BY term_start) AS first_state
                FROM legislators_terms 
        ) a
        JOIN legislators_terms b ON a.id_bioguide = b.id_bioguide 
        LEFT JOIN date_dim c ON c.date_format BETWEEN b.term_start AND b.term_end 
        AND c.month_number = 12 AND c.day_of_month = 31
        JOIN legislators d ON a.id_bioguide = d.id_bioguide
        WHERE a.first_term BETWEEN '1917-01-01' AND '1999-12-31'
        GROUP BY a.first_state, d.gender,
        COALESCE(FLOOR(MONTHS_BETWEEN(c.date_format, a.first_term) / 12), 0)
)
ORDER BY 1, 3, 2;
 
SELECT aa.gender, aa.first_state, cc.period, aa.cohort_size
FROM
(
        SELECT b.gender, a.first_state, COUNT(DISTINCT a.id_bioguide) AS cohort_size
        FROM 
        (
                SELECT DISTINCT id_bioguide,
                MIN(term_start) over (PARTITION BY id_bioguide) AS first_term,
                FIRST_VALUE(state) over (PARTITION BY id_bioguide ORDER BY term_start) AS first_state
                FROM legislators_terms 
        ) a
        JOIN legislators b ON a.id_bioguide = b.id_bioguide
        WHERE a.first_term BETWEEN '1917-01-01' AND '1999-12-31' 
        GROUP BY b.gender, a.first_state
) aa
JOIN
(
        SELECT LEVEL-1 AS period 
        FROM DUAL 
        CONNECT BY LEVEL-1 < 21
) cc ON 1 = 1
ORDER BY 1, 2, 3;
 
SELECT aaa.gender, aaa.first_state, aaa.period, aaa.cohort_size,
COALESCE(ddd.cohort_retained, 0) AS cohort_retained,
ROUND(COALESCE(ddd.cohort_retained, 0) * 1.0 / aaa.cohort_size, 4) AS pct_retained
FROM
(
        SELECT aa.gender, aa.first_state, cc.period, aa.cohort_size
        FROM
        (
                SELECT b.gender, a.first_state, COUNT(DISTINCT a.id_bioguide) AS cohort_size
                FROM 
                (
                        SELECT DISTINCT id_bioguide,
                        MIN(term_start) over (PARTITION BY id_bioguide) AS first_term,
                        FIRST_VALUE(state) over (PARTITION BY id_bioguide ORDER BY term_start) AS first_state
                        FROM legislators_terms 
                ) a
                JOIN legislators b ON a.id_bioguide = b.id_bioguide 
                WHERE a.first_term BETWEEN '1917-01-01' AND '1999-12-31' 
                GROUP BY b.gender, a.first_state
        ) aa
JOIN
(
        SELECT LEVEL-1 AS period 
        FROM DUAL 
        CONNECT BY LEVEL-1 < 21
) cc ON 1 = 1
) aaa
LEFT JOIN
(
        SELECT d.first_state, g.gender,
        COALESCE(FLOOR(MONTHS_BETWEEN(f.date_format, d.first_term) / 12), 0) AS period,
        COUNT(DISTINCT d.id_bioguide) AS cohort_retained
        FROM
        (
                SELECT DISTINCT id_bioguide,
                MIN(term_start) over (PARTITION BY id_bioguide) AS first_term,
                FIRST_VALUE(state) over (PARTITION BY id_bioguide ORDER BY term_start) AS first_state
                FROM legislators_terms 
        ) d
        JOIN legislators_terms e ON d.id_bioguide = e.id_bioguide 
        LEFT JOIN date_dim f ON f.date_format BETWEEN e.term_start AND e.term_end 
        AND f.month_number = 12 AND f.day_of_month = 31
        JOIN legislators g ON d.id_bioguide = g.id_bioguide
        WHERE d.first_term BETWEEN '1917-01-01' AND '1999-12-31'
        GROUP BY d.first_state, g.gender,
        COALESCE(FLOOR(MONTHS_BETWEEN(f.date_format, d.first_term) / 12), 0)
) ddd ON aaa.gender = ddd.gender AND aaa.first_state = ddd.first_state AND aaa.period = ddd.period
ORDER BY 1, 2, 3;
 
SELECT gender, first_state, cohort_size,
MAX(CASE WHEN period = 0 THEN pct_retained END) AS yr0,
MAX(CASE WHEN period = 2 THEN pct_retained END) AS yr2,
MAX(CASE WHEN period = 4 THEN pct_retained END) AS yr4,
MAX(CASE WHEN period = 6 THEN pct_retained END) AS yr6,
MAX(CASE WHEN period = 8 THEN pct_retained END) AS yr8,
MAX(CASE WHEN period = 10 THEN pct_retained END) AS yr10
FROM
(
        SELECT aaa.gender, aaa.first_state, aaa.period, aaa.cohort_size,
        COALESCE(ddd.cohort_retained, 0) AS cohort_retained,
        ROUND(COALESCE(ddd.cohort_retained, 0) * 1.0 / aaa.cohort_size, 4) AS pct_retained
        FROM
        (
                SELECT aa.gender, aa.first_state, cc.period, aa.cohort_size
                FROM
                (
                        SELECT b.gender, a.first_state, COUNT(DISTINCT a.id_bioguide) AS cohort_size
                        FROM 
                        (
                                SELECT DISTINCT id_bioguide,
                                MIN(term_start) over (PARTITION BY id_bioguide) AS first_term,
                                FIRST_VALUE(state) over (PARTITION BY id_bioguide ORDER BY term_start) AS first_state
                                FROM legislators_terms 
                        ) a
                        JOIN legislators b ON a.id_bioguide = b.id_bioguide 
                        WHERE a.first_term BETWEEN '1917-01-01' AND '1999-12-31' 
                        GROUP BY b.gender, a.first_state
                ) aa
        JOIN
        (
                SELECT LEVEL-1 AS period 
                FROM DUAL 
                CONNECT BY LEVEL-1 < 21
        ) cc ON 1 = 1
        ) aaa
        LEFT JOIN
        (
                SELECT d.first_state, g.gender,
                COALESCE(FLOOR(MONTHS_BETWEEN(f.date_format, d.first_term) / 12), 0) AS period,
                COUNT(DISTINCT d.id_bioguide) AS cohort_retained
                FROM
                (
                        SELECT DISTINCT id_bioguide,
                        MIN(term_start) over (PARTITION BY id_bioguide) AS first_term,
                        FIRST_VALUE(state) over (PARTITION BY id_bioguide ORDER BY term_start) AS first_state
                        FROM legislators_terms 
                ) d
                JOIN legislators_terms e ON d.id_bioguide = e.id_bioguide 
                LEFT JOIN date_dim f ON f.date_format BETWEEN e.term_start AND e.term_end 
                AND f.month_number = 12 AND f.day_of_month = 31
                JOIN legislators g ON d.id_bioguide = g.id_bioguide
                WHERE d.first_term BETWEEN '1917-01-01' AND '1999-12-31'
                GROUP BY d.first_state, g.gender,
                COALESCE(FLOOR(MONTHS_BETWEEN(f.date_format, d.first_term) / 12), 0)
        ) ddd ON aaa.gender = ddd.gender AND aaa.first_state = ddd.first_state AND aaa.period = ddd.period
) a
GROUP BY gender, first_state, cohort_size
ORDER BY 1, 2;
 
----------- Defining cohorts from dates other than the first date ----------------------------------
 
SELECT DISTINCT id_bioguide, term_type, TO_DATE('2000-01-01') AS first_term, MIN(term_start) AS min_start
FROM legislators_terms
WHERE term_start <= '2000-12-31' AND term_end >= '2000-01-01'
GROUP BY id_bioguide, term_type, TO_DATE('2000-01-01');
 
SELECT term_type, period,
FIRST_VALUE(cohort_retained) over (PARTITION BY term_type ORDER BY period) AS cohort_size,
cohort_retained,
ROUND(cohort_retained / FIRST_VALUE(cohort_retained) over (PARTITION BY term_type ORDER BY period), 4) AS pct_retained
FROM
(
        SELECT a.term_type,
        COALESCE(FLOOR(MONTHS_BETWEEN(c.date_format, a.first_term) / 12), 0) AS period,
        COUNT(DISTINCT a.id_bioguide) AS cohort_retained
        FROM
        (
                SELECT DISTINCT id_bioguide, term_type, TO_DATE('2000-01-01') AS first_term, MIN(term_start) AS min_start
                FROM legislators_terms 
                WHERE term_start <= '2000-12-31' AND term_end >= '2000-01-01'
                GROUP BY id_bioguide, term_type, TO_DATE('2000-01-01')
        ) a
        JOIN legislators_terms b ON a.id_bioguide = b.id_bioguide AND b.term_start >= a.min_start
        LEFT JOIN date_dim c ON c.date_format BETWEEN b.term_start AND b.term_end 
        AND c.month_number = 12 AND c.day_of_month = 31 AND c.YEAR >= 2000
        GROUP BY a.term_type,
        COALESCE(FLOOR(MONTHS_BETWEEN(c.date_format, a.first_term) / 12), 0)
)
ORDER BY 2;
 
----------- Survivorship ----------------------------------
 
SELECT id_bioguide, MIN(term_start) AS first_term, MAX(term_start) AS last_term
FROM legislators_terms
GROUP BY id_bioguide;
 
SELECT id_bioguide, TO_CHAR(MIN(term_start), 'CC') AS first_century,
MIN(term_start) AS first_term, MAX(term_start) AS last_term,
FLOOR(MONTHS_BETWEEN(MAX(term_start),MIN(term_start))/12) AS tenure
FROM legislators_terms
GROUP BY id_bioguide;
 
SELECT first_century, COUNT(DISTINCT id_bioguide) AS cohort_size,
COUNT(DISTINCT CASE WHEN tenure >= 10 THEN id_bioguide END) AS survived_10,
ROUND(COUNT(DISTINCT CASE WHEN tenure >= 10 THEN id_bioguide END) / COUNT(DISTINCT id_bioguide), 4) AS pct_survived_10
FROM
(
        SELECT id_bioguide, TO_CHAR(MIN(term_start), 'CC') AS first_century,
        MIN(term_start) AS first_term, MAX(term_start) AS last_term,
        FLOOR(MONTHS_BETWEEN(MAX(term_start),MIN(term_start))/12) AS tenure
        FROM legislators_terms
        GROUP BY id_bioguide
) a
GROUP BY first_century
ORDER BY 1;
 
 
 
SELECT first_century, COUNT(DISTINCT id_bioguide) AS cohort_size,
COUNT(DISTINCT CASE WHEN total_terms >= 5 THEN id_bioguide END) AS survived_5,
ROUND(COUNT(DISTINCT CASE WHEN total_terms >= 5 THEN id_bioguide END) / COUNT(DISTINCT id_bioguide), 4) AS pct_survived_5_terms
FROM
(
        SELECT id_bioguide, TO_CHAR(MIN(term_start), 'CC') AS first_century,
        COUNT(term_start) AS total_terms
        FROM legislators_terms
        GROUP BY id_bioguide
) a
GROUP BY first_century
ORDER BY 1;
 
SELECT a.first_century, b.terms, COUNT(DISTINCT id_bioguide) AS cohort,
COUNT(DISTINCT CASE WHEN a.total_terms >= b.terms THEN id_bioguide END) AS cohort_survived,
ROUND(COUNT(DISTINCT CASE WHEN a.total_terms >= b.terms THEN id_bioguide END) / COUNT(DISTINCT id_bioguide), 4) AS pct_survived
FROM
(
        SELECT id_bioguide, TO_CHAR(MIN(term_start), 'CC') AS first_century,
        COUNT(term_start) AS total_terms
        FROM legislators_terms
        GROUP BY id_bioguide
) a
JOIN
(
        SELECT LEVEL AS terms 
        FROM DUAL 
        CONNECT BY LEVEL < 21
) b ON 1 = 1
GROUP BY a.first_century, b.terms
ORDER BY 1, 2;
 
----------- Returnship / repeat purchase behavior ----------------------------------
 
SELECT TO_CHAR(a.first_term, 'CC') AS cohort_century, COUNT(id_bioguide) AS reps
FROM
(
        SELECT id_bioguide, MIN(term_start) AS first_term
        FROM legislators_terms
        WHERE term_type = 'rep'
        GROUP BY id_bioguide
) a
GROUP BY TO_CHAR(a.first_term, 'CC')
ORDER BY 1;
 
SELECT TO_CHAR(a.first_term, 'CC') AS cohort_century, COUNT(DISTINCT a.id_bioguide) AS rep_and_sen
FROM
(
        SELECT id_bioguide, MIN(term_start) AS first_term
        FROM legislators_terms
        WHERE term_type = 'rep'
        GROUP BY id_bioguide
) a
JOIN legislators_terms b ON a.id_bioguide = b.id_bioguide AND b.term_type = 'sen' AND b.term_start > a.first_term
GROUP BY TO_CHAR(a.first_term, 'CC')
ORDER BY 1;
 
SELECT aa.cohort_century, ROUND(bb.rep_and_sen / aa.reps, 4) AS pct_rep_and_sen
FROM
(
        SELECT TO_CHAR(a.first_term, 'CC') AS cohort_century, COUNT(id_bioguide) AS reps
        FROM
        (
                SELECT id_bioguide, MIN(term_start) AS first_term
                FROM legislators_terms
                WHERE term_type = 'rep'
                GROUP BY id_bioguide
        ) a
        GROUP BY TO_CHAR(a.first_term, 'CC')
) aa
LEFT JOIN
(
        SELECT TO_CHAR(b.first_term, 'CC') AS cohort_century, COUNT(DISTINCT b.id_bioguide) AS rep_and_sen
        FROM
        (
                SELECT id_bioguide, MIN(term_start) AS first_term
                FROM legislators_terms
                WHERE term_type = 'rep'
                GROUP BY id_bioguide
        ) b
        JOIN legislators_terms c ON b.id_bioguide = c.id_bioguide
        AND c.term_type = 'sen' AND c.term_start > b.first_term
        GROUP BY TO_CHAR(b.first_term, 'CC')
) bb ON aa.cohort_century = bb.cohort_century
ORDER BY 1;
 
SELECT aa.cohort_century, ROUND(bb.rep_and_sen / aa.reps, 4) AS pct_rep_and_sen
FROM
(
        SELECT TO_CHAR(a.first_term, 'CC') AS cohort_century, COUNT(id_bioguide) AS reps
        FROM
        (
                SELECT id_bioguide, MIN(term_start) AS first_term
                FROM legislators_terms
                WHERE term_type = 'rep'
                GROUP BY id_bioguide
        ) a
        WHERE first_term <= '2009-12-31'
        GROUP BY TO_CHAR(a.first_term, 'CC')
) aa
LEFT JOIN
(
        SELECT TO_CHAR(b.first_term, 'CC') AS cohort_century, COUNT(DISTINCT b.id_bioguide) AS rep_and_sen
        FROM
        (
                SELECT id_bioguide, MIN(term_start) AS first_term
                FROM legislators_terms
                WHERE term_type = 'rep'
                GROUP BY id_bioguide
        ) b
        JOIN legislators_terms c ON b.id_bioguide = c.id_bioguide
        AND c.term_type = 'sen' AND c.term_start > b.first_term
        -- Both WHERE clauses are working correctly, use the one you prefer
        -- WHERE extract(year from c.term_start) - extract(year from b.first_term) <= 10
        WHERE MONTHS_BETWEEN(c.term_start, b.first_term) / 12 <= 10
        GROUP BY TO_CHAR(b.first_term, 'CC')
) bb ON aa.cohort_century = bb.cohort_century
ORDER BY 1;
 
SELECT aa.cohort_century,
ROUND(bb.rep_and_sen_5_yrs / aa.reps, 4) AS pct_5_yrs,
ROUND(bb.rep_and_sen_10_yrs / aa.reps, 4) AS pct_10_yrs,
ROUND(bb.rep_and_sen_15_yrs / aa.reps, 4) AS pct_15_yrs
FROM
(
        SELECT TO_CHAR(a.first_term, 'CC') AS cohort_century, COUNT(id_bioguide) AS reps
        FROM
        (
                SELECT id_bioguide, MIN(term_start) AS first_term
                FROM legislators_terms
                WHERE term_type = 'rep'
                GROUP BY id_bioguide
        ) a
        WHERE first_term <= '2009-12-31'
        GROUP BY TO_CHAR(a.first_term, 'CC')
) aa
LEFT JOIN
(
        SELECT TO_CHAR(b.first_term, 'CC') AS cohort_century,
        COUNT(DISTINCT CASE WHEN MONTHS_BETWEEN(c.term_start, b.first_term) / 12 <= 5 THEN b.id_bioguide END) AS rep_and_sen_5_yrs,
        COUNT(DISTINCT CASE WHEN MONTHS_BETWEEN(c.term_start, b.first_term) / 12 <= 10 THEN b.id_bioguide END) AS rep_and_sen_10_yrs,
        COUNT(DISTINCT CASE WHEN MONTHS_BETWEEN(c.term_start, b.first_term) / 12 <= 15 THEN b.id_bioguide END) AS rep_and_sen_15_yrs
        FROM
        (
                SELECT id_bioguide, MIN(term_start) AS first_term
                FROM legislators_terms
                WHERE term_type = 'rep'
                GROUP BY id_bioguide
        ) b
        JOIN legislators_terms c ON b.id_bioguide = c.id_bioguide
        AND c.term_type = 'sen' AND c.term_start > b.first_term
        GROUP BY TO_CHAR(b.first_term, 'CC')
) bb ON aa.cohort_century = bb.cohort_century
ORDER BY 1;
 
----------- Cumulative calculations ----------------------------------
 
SELECT TO_CHAR(a.first_term, 'CC') AS century, first_type,
COUNT(DISTINCT a.id_bioguide) AS cohort, COUNT(b.term_start) AS terms
FROM
(
        SELECT DISTINCT id_bioguide,
        FIRST_VALUE(term_type) over (PARTITION BY id_bioguide ORDER BY term_start) AS first_type,
        MIN(term_start) over (PARTITION BY id_bioguide) AS first_term,
        MIN(term_start) over (PARTITION BY id_bioguide) + INTERVAL '10' YEAR AS first_plus_10
        FROM legislators_terms
) a
LEFT JOIN legislators_terms b ON a.id_bioguide = b.id_bioguide AND b.term_start BETWEEN a.first_term AND a.first_plus_10
GROUP BY TO_CHAR(a.first_term, 'CC'), first_type
ORDER BY 1, 2;
 
SELECT century,
MAX(CASE WHEN first_type = 'rep' THEN cohort END) AS rep_cohort,
ROUND(MAX(CASE WHEN first_type = 'rep' THEN terms_per_leg END), 4) AS avg_rep_terms,
MAX(CASE WHEN first_type = 'sen' THEN cohort END) AS sen_cohort,
ROUND(MAX(CASE WHEN first_type = 'sen' THEN terms_per_leg END), 4) AS avg_sen_terms
FROM
(
        SELECT TO_CHAR(a.first_term, 'CC') AS century, first_type,
        COUNT(DISTINCT a.id_bioguide) AS cohort, COUNT(b.term_start) AS terms,
        COUNT(b.term_start) / COUNT(DISTINCT a.id_bioguide) AS terms_per_leg
        FROM
        (
                SELECT DISTINCT id_bioguide,
                FIRST_VALUE(term_type) over (PARTITION BY id_bioguide ORDER BY term_start) AS first_type,
                MIN(term_start) over (PARTITION BY id_bioguide) AS first_term,
                MIN(term_start) over (PARTITION BY id_bioguide) + INTERVAL '10' YEAR AS first_plus_10
                FROM legislators_terms
        ) a
        LEFT JOIN legislators_terms b ON a.id_bioguide = b.id_bioguide AND b.term_start BETWEEN a.first_term AND a.first_plus_10
        GROUP BY TO_CHAR(a.first_term, 'CC'), first_type
)
GROUP BY century
ORDER BY 1;
 
----------- Cross-section analysis, with a cohort lens ----------------------------------
 
SELECT b.date_format, COUNT(DISTINCT a.id_bioguide) AS legislators
FROM legislators_terms a
JOIN date_dim b ON b.date_format BETWEEN a.term_start AND a.term_end
AND b.month_number = 12
AND b.day_of_month = 31
AND b.YEAR <= 2019
GROUP BY b.date_format
ORDER BY 1;
 
SELECT b.date_format, TO_CHAR(first_term, 'CC') AS century, COUNT(DISTINCT a.id_bioguide) AS legislators
FROM legislators_terms a
JOIN date_dim b ON b.date_format BETWEEN a.term_start AND a.term_end AND b.month_number = 12 AND b.day_of_month = 31 AND b.YEAR <= 2019
JOIN
(
        SELECT id_bioguide, MIN(term_start) AS first_term
        FROM legislators_terms
        GROUP BY id_bioguide
) c ON a.id_bioguide = c.id_bioguide        
GROUP BY b.date_format, TO_CHAR(first_term, 'CC')
ORDER BY 1, 2;
 
SELECT date_format, century, legislators,
SUM(legislators) over (PARTITION BY date_format) AS cohort,
ROUND(legislators * 100.0 / SUM(legislators) over (PARTITION BY date_format), 4) AS pct_century
FROM
(
        SELECT b.date_format, TO_CHAR(first_term, 'CC') AS century, COUNT(DISTINCT a.id_bioguide) AS legislators
        FROM legislators_terms a
        JOIN date_dim b ON b.date_format BETWEEN a.term_start AND a.term_end AND b.month_number = 12 AND b.day_of_month = 31 AND b.YEAR <= 2019
        JOIN
        (
                SELECT id_bioguide, MIN(term_start) AS first_term
                FROM legislators_terms
                GROUP BY id_bioguide
        ) c ON a.id_bioguide = c.id_bioguide        
        GROUP BY b.date_format, TO_CHAR(first_term, 'CC')
)
ORDER BY 1,2;
 
SELECT date_format,
COALESCE(ROUND(SUM(CASE WHEN century = 18 THEN legislators END) * 100.0 / SUM(legislators), 4), 0) AS pct_18,
COALESCE(ROUND(SUM(CASE WHEN century = 19 THEN legislators END) * 100.0 / SUM(legislators), 4), 0) AS pct_19,
COALESCE(ROUND(SUM(CASE WHEN century = 20 THEN legislators END) * 100.0 / SUM(legislators), 4), 0) AS pct_20,
COALESCE(ROUND(SUM(CASE WHEN century = 21 THEN legislators END) * 100.0 / SUM(legislators), 4), 0) AS pct_21
FROM
(
        SELECT b.date_format, TO_CHAR(first_term, 'CC') AS century, COUNT(DISTINCT a.id_bioguide) AS legislators
        FROM legislators_terms a
        JOIN date_dim b ON b.date_format BETWEEN a.term_start AND a.term_end AND b.month_number = 12 AND b.day_of_month = 31 AND b.YEAR <= 2019
        JOIN
        (
                SELECT id_bioguide, MIN(term_start) AS first_term
                FROM legislators_terms
                GROUP BY id_bioguide
        ) c ON a.id_bioguide = c.id_bioguide        
        GROUP BY b.date_format, TO_CHAR(first_term, 'CC')
) 
GROUP BY date_format
ORDER BY 1;
 
SELECT id_bioguide, date_format, 
COUNT(date_format) over (PARTITION BY id_bioguide ORDER BY date_format rows BETWEEN unbounded preceding AND CURRENT ROW) AS cume_years
FROM
(
        SELECT DISTINCT a.id_bioguide, b.date_format
        FROM legislators_terms a
        JOIN date_dim b ON b.date_format BETWEEN a.term_start AND a.term_end AND b.month_number = 12 AND b.day_of_month = 31 AND b.YEAR <= 2019
);
 
SELECT date_format, cume_years, COUNT(DISTINCT id_bioguide) AS legislators
FROM
(
    SELECT id_bioguide, date_format,
    COUNT(date_format) over (PARTITION BY id_bioguide ORDER BY date_format rows BETWEEN unbounded preceding AND CURRENT ROW) AS cume_years
    FROM
    (
        SELECT DISTINCT a.id_bioguide, b.date_format
        FROM legislators_terms a
        JOIN date_dim b ON b.date_format BETWEEN a.term_start AND a.term_end AND b.month_number = 12 AND b.day_of_month = 31 AND b.YEAR <= 2019
        GROUP BY a.id_bioguide, b.date_format
    ) 
)
GROUP BY date_format, cume_years
ORDER BY 1;
 
SELECT date_format, COUNT(*) AS tenures
FROM 
(
        SELECT date_format, cume_years, COUNT(DISTINCT id_bioguide) AS legislators
        FROM
        (
                SELECT id_bioguide, date_format,
                COUNT(date_format) over (PARTITION BY id_bioguide ORDER BY date_format rows BETWEEN unbounded preceding AND CURRENT ROW) AS cume_years
                FROM
                (
                        SELECT DISTINCT a.id_bioguide, b.date_format
                        FROM legislators_terms a
                        JOIN date_dim b ON b.date_format BETWEEN a.term_start AND a.term_end AND b.month_number = 12 AND b.day_of_month = 31 AND b.YEAR <= 2019
                        GROUP BY a.id_bioguide, b.date_format
                )
        )
        GROUP BY date_format, cume_years
)
GROUP BY date_format
ORDER BY 2 DESC;
 
SELECT date_format, tenure,
ROUND(legislators * 100.0 / SUM(legislators) over (PARTITION BY date_format), 4) AS pct_legislators 
FROM
(
        SELECT date_format,
        CASE WHEN cume_years <= 4 THEN '01 to 04'
             WHEN cume_years <= 10 THEN '05 to 10'
             WHEN cume_years <= 20 THEN '11 to 20'
             ELSE '21+' END AS tenure,
        COUNT(DISTINCT id_bioguide) AS legislators
        FROM
        (
                SELECT id_bioguide, date_format,
                COUNT(date_format) over (PARTITION BY id_bioguide ORDER BY date_format rows BETWEEN unbounded preceding AND CURRENT ROW) AS cume_years
                FROM
                (
                        SELECT DISTINCT a.id_bioguide, b.date_format
                        FROM legislators_terms a
                        JOIN date_dim b ON b.date_format BETWEEN a.term_start AND a.term_end AND b.month_number = 12 AND b.day_of_month = 31 AND b.YEAR <= 2019
                        GROUP BY a.id_bioguide, b.date_format
                )
        )
        GROUP BY date_format,
        CASE WHEN cume_years <= 4 THEN '01 to 04'
             WHEN cume_years <= 10 THEN '05 to 10'
             WHEN cume_years <= 20 THEN '11 to 20'
             ELSE '21+' END
)
ORDER BY 1 DESC, 2;

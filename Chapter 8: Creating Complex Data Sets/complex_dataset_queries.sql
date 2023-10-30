----- Code organization 
 
SELECT type, mag,
case when place like '%CA%' then 'California'
      when place like '%AK%' then 'Alaska'
      else trim(substr(place, instr(place, ',') + length(',')))
      end as place,
count(*)
FROM earthquakes
WHERE extract(year from time) >= 2019
and mag between 0 and 1
GROUP BY type, mag,
case when place like '%CA%' then 'California'
      when place like '%AK%' then 'Alaska'
      else trim(substr(place, instr(place, ',') + length(',')))
      end;
 
----- Organizing computations
 
SELECT state, count(*) as terms
FROM legislators_terms
GROUP BY state
HAVING count(*) >= 1000
ORDER BY 2 desc;
 
SELECT state, count(*) as terms, avg(count(*)) over () as avg_terms
FROM legislators_terms
GROUP BY state;
 
SELECT state, count(*) as terms, rank() over (order by count(*) desc)
FROM legislators_terms
GROUP BY state;
 
SELECT extract(year from c.first_term) as first_year,
a.party, count(a.id_bioguide) as legislators
FROM
(
        SELECT distinct id_bioguide, party
        FROM legislators_terms
        WHERE term_end > '2020-06-01'
) a,
LATERAL
(
        SELECT b.id_bioguide, min(term_start) as first_term
        FROM legislators_terms b
        WHERE b.id_bioguide = a.id_bioguide
        and b.party <> a.party
        GROUP BY b.id_bioguide
) c
GROUP BY extract(year from c.first_term), a.party;
 
SELECT extract(year from c.first_term) as first_year,
a.party, count(a.id_bioguide) as legislators
FROM
(
        SELECT distinct id_bioguide, party
        FROM legislators_terms
        WHERE term_end > '2020-06-01'
) a
JOIN
(
        SELECT id_bioguide, party
        ,min(term_start) as first_term
        FROM legislators_terms
        GROUP BY id_bioguide, party
) c on c.id_bioguide = a.id_bioguide and c.party <> a.party
GROUP BY extract(year from c.first_term), a.party;
 
CREATE global temporary table temp_states
(
state varchar(50) primary key
);
 
INSERT into temp_states
SELECT distinct state
FROM legislators_terms;
 
CREATE global temporary table temp_states
as
SELECT distinct state
FROM legislators_terms;
 
WITH first_term as
(
    SELECT id_bioguide,
    min(term_start) as first_term
    FROM legislators_terms 
    GROUP BY id_bioguide
) 
SELECT floor(months_between(b.term_start, a.first_term) / 12) as periods,
count(distinct a.id_bioguide) as cohort_retained
FROM first_term a
JOIN legislators_terms b on a.id_bioguide = b.id_bioguide 
GROUP BY floor(months_between(b.term_start, a.first_term) / 12);
 
SELECT platform, null as genre, null as publisher,
sum(global_sales) as global_sales
FROM videogame_sales
GROUP BY platform
    UNION
SELECT null as platform, genre, null as publisher,
sum(global_sales) as global_sales
FROM videogame_sales
GROUP BY genre
    UNION
SELECT null as platform, null as genre, publisher,
sum(global_sales) as global_sales
FROM videogame_sales
GROUP BY publisher;
 
SELECT platform, genre, publisher,
sum(global_sales) as global_sales
FROM videogame_sales
GROUP BY grouping sets (platform, genre, publisher);
 
SELECT coalesce(platform,'All') as platform,
coalesce(genre,'All') as genre,
coalesce(publisher,'All') as publisher,
sum(global_sales) as na_sales
FROM videogame_sales
GROUP BY grouping sets ((), platform, genre, publisher)
ORDER BY 1, 2, 3;
 
SELECT coalesce(platform,'All') as platform,
coalesce(genre,'All') as genre,
coalesce(publisher,'All') as publisher,
sum(global_sales) as global_sales
FROM videogame_sales
GROUP BY cube (platform, genre, publisher)
ORDER BY 1, 2, 3;
 
SELECT coalesce(platform,'All') as platform,
coalesce(genre,'All') as genre,
coalesce(publisher,'All') as publisher,
sum(global_sales) as global_sales
FROM videogame_sales
GROUP BY rollup (platform, genre, publisher)
ORDER BY 1, 2, 3;
 
----- Managing data set size and privacy
 
-- Only mod() works in Oracle
SELECT mod(123456,100) 
FROM dual;
 
SELECT case when state in ('CA','TX','FL','NY','PA') then state 
            else 'Other' end as state_group,
count(*) as terms
FROM legislators_terms
GROUP BY case when state in ('CA','TX','FL','NY','PA') then state 
            else 'Other' end
ORDER BY 2 desc;
 
SELECT case when b.rank <= 5 then a.state 
            else 'Other' end as state_group,
count(distinct id_bioguide) as legislators            
FROM legislators_terms a 
JOIN
(
        SELECT state,
        count(distinct id_bioguide),
        rank() over (order by count(distinct id_bioguide) desc) as rank
        FROM legislators_terms
        GROUP BY state
) b on a.state = b.state
GROUP BY case when b.rank <= 5 then a.state 
            else 'Other' end
ORDER BY 2 desc;
 
SELECT case when terms >= 2 then 'TRUE' else 'FALSE' end as two_terms_flag,
count(*) as legislators
FROM
(
    SELECT id_bioguide, count(term_id) as terms
    FROM legislators_terms
    GROUP BY id_bioguide
) a
GROUP BY case when terms >= 2 then 'TRUE' else 'FALSE' end;
 
SELECT 
case when terms >= 10 then '10+'
     when terms >= 2 then '2 - 9'
     else '1' end as terms_level,
count(*) as legislators
FROM
(
        SELECT id_bioguide, count(term_id) as terms
        FROM legislators_terms
        GROUP BY id_bioguide
) a
GROUP BY case when terms >= 10 then '10+'
     when terms >= 2 then '2 - 9'
     else '1' end;
 
SELECT standard_hash('my info', 'MD5')
FROM dual;
 

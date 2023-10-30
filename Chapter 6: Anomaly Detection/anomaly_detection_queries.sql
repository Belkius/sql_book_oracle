------ Detecting outliers
-- Sorting to find anomalies
 
SELECT mag,
count(id) as earthquakes,
round(count(id) * 100.0 / sum(count(id)) over (partition by 1), 8) as pct_earthquakes
FROM earthquakes
WHERE mag is not null
GROUP BY mag
ORDER BY 1 desc;
 
SELECT place, mag, count(*)
FROM earthquakes
WHERE mag is not null
and place = 'Northern California'
GROUP BY place, mag
ORDER BY 1,2 desc;
 
-- Calculating percentiles to find anomalies
 
SELECT place, mag, percentile, count(*)
FROM
(
    SELECT place, mag,
    percent_rank() over (partition by place order by mag) as percentile
    FROM earthquakes
    WHERE mag is not null
    and place = 'Northern California'
) 
GROUP BY place, mag, percentile
ORDER BY 1,2 desc;
 
SELECT place, mag,
ntile(100) over (partition by place order by mag) as ntile
FROM earthquakes
WHERE mag is not null
and place = 'Central Alaska'
ORDER BY 1,2 desc;
 
SELECT place, ntile, max(mag) as maximum, min(mag) as minimum
FROM
(
        SELECT place, mag,
        ntile(4) over (partition by place order by mag) as ntile
        FROM earthquakes
        WHERE mag is not null
        and place = 'Central Alaska'
)
GROUP BY place, ntile
ORDER BY 1,2 desc;
 
SELECT 
percentile_cont(0.25) within group (order by mag) as pct_25,
percentile_cont(0.5) within group (order by mag) as pct_50,
percentile_cont(0.75) within group (order by mag) as pct_75
FROM earthquakes
WHERE mag is not null
and place = 'Central Alaska';
 
SELECT 
percentile_cont(0.25) within group (order by mag) as pct_25_mag,
percentile_cont(0.25) within group (order by depth) as pct_25_depth
FROM earthquakes
WHERE mag is not null
and place = 'Central Alaska';
 
SELECT place,
percentile_cont(0.25) within group (order by mag) as pct_25_mag,
percentile_cont(0.25) within group (order by depth) as pct_25_depth
FROM earthquakes
WHERE mag is not null
and place in ('Central Alaska', 'Southern Alaska')
GROUP BY place;
 
SELECT stddev_pop(mag) as stddev_pop_mag,
stddev_samp(mag) as stddev_samp_mag
FROM earthquakes;
 
SELECT a.place, a.mag, b.avg_mag, b.std_dev,
round((a.mag - b.avg_mag) / b.std_dev, 4) as z_score
FROM earthquakes a
JOIN(
    SELECT round(avg(mag), 4) as avg_mag,
    round(stddev_pop(mag), 4) as std_dev
    FROM earthquakes
    WHERE mag is not null
) b on 1 = 1
WHERE a.mag is not null
ORDER BY 2 desc;
 
-- Graphing to find anomalies visually
 
SELECT mag, count(*) as earthquakes
FROM earthquakes
GROUP BY mag
ORDER BY 1;
 
SELECT mag, depth, count(*) as earthquakes
FROM earthquakes
GROUP BY mag, depth
ORDER BY 1,2;
 
SELECT mag
FROM earthquakes
WHERE place like '%Japan%'
ORDER BY 1;
 
SELECT ntile_25, median, ntile_75,
(ntile_75 - ntile_25) * 1.5 as iqr,
ntile_25 - (ntile_75 - ntile_25) * 1.5 as lower_whisker,
ntile_75 + (ntile_75 - ntile_25) * 1.5 as upper_whisker
FROM
(
        SELECT percentile_cont(0.25) within group (order by mag) as ntile_25,
        percentile_cont(0.5) within group (order by mag) as median,
        percentile_cont(0.75) within group (order by mag) as ntile_75
        FROM earthquakes
        WHERE place like '%Japan%'
);
 
-- the previous query can be written without the subquery:
SELECT percentile_cont(0.25) within group (order by mag) as ntile_25,
percentile_cont(0.5) within group (order by mag) as median,
percentile_cont(0.75) within group (order by mag) as ntile_75,
1.5 * (percentile_cont(0.75) within group (order by mag) - percentile_cont(0.25) within group (order by mag)) as iqr ,
percentile_cont(0.25) within group (order by mag) - (1.5 * (percentile_cont(0.75) within group (order by mag) - percentile_cont(0.25) within group (order by mag))) as lower_whisker,
percentile_cont(0.75) within group (order by mag) + (1.5 * (percentile_cont(0.75) within group (order by mag) - percentile_cont(0.25) within group (order by mag))) as upper_whisker
FROM earthquakes
WHERE place like '%Japan%';
 
SELECT extract(year from time) as year, mag
FROM earthquakes
WHERE place like '%Japan%'
ORDER BY 1, 2;
 
------ Forms of anomalies
-- Anomalous values
 
SELECT mag, count(*)
FROM earthquakes
WHERE mag > 1 and rownum <= 100
GROUP BY mag
ORDER BY 1;
 
SELECT net, count(*)
FROM earthquakes
WHERE depth > 600
GROUP BY net;
 
SELECT place, count(*)
FROM earthquakes
WHERE depth > 600
GROUP BY place;
 
SELECT 
case when place like '% of %' then substr(place, instr(place, ' of ') + length(' of '))
     else place end as place_name,
count(*)
FROM earthquakes
WHERE depth > 600
GROUP BY case when place like '% of %' then substr(place, instr(place, ' of ') + length(' of '))
     else place end
ORDER BY 2 desc;
 
SELECT count(distinct type) as distinct_types,
count(distinct lower(type)) as distinct_lower
FROM earthquakes;
 
SELECT type, lower(type),
case when type = lower(type) then 1 else 0 end as flag,
count(*) as records
FROM earthquakes
GROUP BY type, lower(type),
case when type = lower(type) then 1 else 0 end
ORDER BY 2,4 desc;
 
SELECT type, count(*) as records
FROM earthquakes
GROUP BY type
ORDER BY 2 desc;
 
-- Anomalous counts or frequencies
 
SELECT extract(year from time) as earthquake_year,
count(*) as earthquakes
FROM earthquakes
GROUP BY extract(year from time);
 
SELECT trunc(time, 'MM') as earthquake_month,
count(*) as earthquakes
FROM earthquakes
GROUP BY trunc(time, 'MM');
 
SELECT trunc(time, 'MM') as earthquake_month, status,
count(*) as earthquakes
FROM earthquakes
GROUP BY trunc(time, 'MM'), status
ORDER BY 1;
 
SELECT place, count(*) as earthquakes
FROM earthquakes
WHERE mag >= 6
GROUP BY place
ORDER BY 2 desc;
 
SELECT 
case when place like '% of %' then substr(place, instr(place, ' of ') + length(' of '))
     else place end as place,
count(*) as earthquakes
FROM earthquakes
WHERE mag >= 6
GROUP BY
case when place like '% of %' then substr(place, instr(place, ' of ') + length(' of '))
     else place end
ORDER BY 2 desc;
 
-- Anomalies from the absence of data
 
SELECT place,
extract(day from (to_date('2020-12-31 23:59:59', 'YYYY/MM/DD HH24:MI:SS') - latest)) as days_since_latest,
count(*) as earthquakes,
round(avg(extract(day from gap)), 4) as avg_gap,
round(max(extract(day from gap)), 4) as max_gap
FROM
(
        SELECT place, time,
        lead(time) over (partition by place order by time) as next_time,
        lead(time) over (partition by place order by time) - time as gap,
        max(time) over (partition by place) as latest
        FROM
        (
                SELECT 
                replace(
                  initcap(
                  case when regexp_like(place, ', [A-Z]') then substr(place, instr(place, ', ') + length(', '))
                       when place like '% of %' then substr(place, instr(place, ' of ') + length(' of '))
                       else place end
                ), 'Region','') as place,
                time
                FROM earthquakes
                WHERE mag > 5
        )
)
GROUP BY  place,
extract(day from (to_date('2020-12-31 23:59:59', 'YYYY/MM/DD HH24:MI:SS') - latest))
ORDER BY 1;
 
------ Handling anomalies
-- Removal
 
SELECT time, mag, type
FROM earthquakes
WHERE mag not in (-9,-9.99)
AND rownum <= 100;
 
SELECT avg(mag) as avg_mag,
avg(case when mag > -9 then mag end) as avg_mag_adjusted
FROM earthquakes;
 
SELECT avg(mag) as avg_mag,
avg(case when mag > -9 then mag end) as avg_mag_adjusted
FROM earthquakes
WHERE place = 'Yellowstone National Park, Wyoming';
 
-- Replacement with alternate values
 
SELECT 
case when type = 'earthquake' then type
     else 'Other' end as event_type,
count(*)
FROM earthquakes
GROUP BY  
case when type = 'earthquake' then type
     else 'Other' end;
 
SELECT a.time, a.place, a.mag,
case when a.mag > b.percentile_95 then b.percentile_95
      when a.mag < b.percentile_05 then b.percentile_05
      else a.mag
      end as mag_winsorized
FROM earthquakes a
JOIN(
    SELECT percentile_cont(0.95) within group (order by mag) as percentile_95,
     percentile_cont(0.05) within group (order by mag) as percentile_05
    FROM earthquakes
) b on 1 = 1;
 
-- Rescaling
 
SELECT round(depth, 1) as depth,
log(10, round(depth, 1)) as log_depth,
count(*) as earthquakes
FROM earthquakes
WHERE depth >= 0.05
GROUP BY round(depth, 1), log(10, round(depth, 1))
ORDER BY 1;

---- Text characteristics
 
SELECT length(sighting_report), count(*) as records
FROM ufo
GROUP BY length(sighting_report)
ORDER BY 1;
 
---- Text parsing
 
-- Instead of left() and right() the best option in Oracle (in my opinion) is substr()
-- left(text, 8) = substr(text, 0 ,8)       right(text, 4) = substr(text, -4)
SELECT substr(sighting_report, 0, 8) as left_digits, count(*)
FROM ufo
GROUP BY substr(sighting_report, 0, 8);
 
-- Substr makes it easier to parse text in the middle
SELECT substr(sighting_report, 12, 14) as occurred
FROM ufo;
-- If you really want to nest the statements
SELECT substr(substr(sighting_report, 0, 25), -14) as occurred
FROM ufo;
 
-- Oracle has no split_part(), but we can check the position of substrings using instr (you of course can also use regexp_substr)
SELECT substr(sighting_report, instr(sighting_report, 'Occurred : ') + length('occurred : ')) as split_1
FROM ufo;
 
-- Now regexp_substr is the only option
SELECT regexp_substr(sighting_report,'(.*) \(Entered', 1, 1, null, 1) as split_2
FROM ufo;
 
SELECT regexp_substr(sighting_report,'Occurred :(.*)(\(Entered.*)', 1, 1, null, 1) as occurred
from ufo;
-- If you really want to nest the statements
SELECT regexp_substr(
            substr(sighting_report, instr(sighting_report, 'Occurred : ') + length('occurred : '))
            ,'^(.*?) \(Entered', 1, 1, null, 1) as occurred
FROM ufo;
 
SELECT regexp_replace(
            regexp_substr(sighting_report,'Occurred :(.*)(Reported.*?)', 1, 1, null, 1),
            '\(.*\)') as occurred
FROM ufo;
 
SELECT regexp_replace(
            regexp_substr(sighting_report,'Occurred :(.*)(Reported.*?)', 1, 1, null, 1),
            '\(.*\)') as occurred,
       NVL(regexp_substr(sighting_report,'Entered as : (.*)(\)Reported.*?)', 1, 1, null, 1), ' ')
            as entered_as,
       regexp_substr(sighting_report,'Reported:(.*)(Posted.*?)', 1, 1, null, 1)
            as reported,
       regexp_substr(sighting_report,'Posted: (.*)(Location.*?)', 1, 1, null, 1)
            as posted,
       regexp_replace(
            regexp_substr(sighting_report,'Location: (.*)(Shape.*?)', 1, 1, null, 1),
            ',') as Location,
       NVL(regexp_substr(sighting_report,'Shape: (.*)(Duration.*?)', 1, 1, null, 1), ' ')
            as Shape,
       NVL(regexp_substr(sighting_report,'Duration:(.*)', 1, 1, null, 1), ' ')
            as Duration
FROM ufo;
 
---- Text transformations
 
SELECT distinct shape, initcap(shape) as shape_clean
FROM
(
        SELECT NVL(regexp_substr(sighting_report,'Shape: (.*)(Duration.*?)', 1, 1, null, 1), ' ') as shape
        FROM ufo
);
 
SELECT duration, trim(duration) as duration_clean
FROM
(
    SELECT NVL(regexp_substr(sighting_report,'Duration:(.*)', 1, 1, null, 1), ' ')as Duration
    FROM ufo
);
 
SELECT 
case when length(occurred) < 8 then null else to_timestamp(occurred, 'MM/DD/RR HH24:MI:SS') end as occured,
case when length(reported) < 8 then null else to_timestamp(reported, 'MM/DD/YYYY HH24:MI:SS') end as reported,
case when posted = '' then null else to_date(posted, 'MM/DD/YYYY') end as posted
FROM
(
        SELECT trim(regexp_replace(regexp_substr(sighting_report,'Occurred :(.*)(Reported.*?)', 1, 1, null, 1), '\(.*\)')) as occurred,
        regexp_replace(regexp_substr(sighting_report,'Reported:(.*)(Posted.*?)', 1, 1, null, 1), ' \d{1,2}:(.*)(AM|PM)') as reported,
        regexp_substr(sighting_report,'Posted: (.*)(Location.*?)', 1, 1, null, 1) as posted
        FROM ufo
        --WHERE rownum = 1
);
 
SELECT location,
replace(replace(location,'close to','near'),'outside of','near') as location_clean
FROM
(
        SELECT regexp_replace(
            regexp_substr(sighting_report,'Location: (.*)(Shape.*?)', 1, 1, null, 1),
            ',') as location
        FROM ufo
);
--where location != replace(replace(location,'close to','near'),'outside of','near');
 
SELECT 
case when length(occurred) < 8 then null else to_timestamp(occurred, 'MM/DD/RR HH24:MI:SS') end as occured,
entered_as,
case when length(reported) < 8 then null else to_timestamp(reported, 'MM/DD/YYYY HH24:MI:SS') end as reported,
case when posted = '' then null else to_date(posted, 'MM/DD/YYYY') end as posted,
replace(replace(location,'close to','near'),'outside of','near') as location,
initcap(shape) as shape,
trim(duration) as duration
FROM
(
        SELECT trim(regexp_replace(regexp_substr(sighting_report,'Occurred :(.*)(Reported.*?)', 1, 1, null, 1), '\(.*\)')) as occurred,
        NVL(regexp_substr(sighting_report,'Entered as : (.*)(\)Reported.*?)', 1, 1, null, 1), ' ') as entered_as,
        regexp_replace(regexp_substr(sighting_report,'Reported:(.*)(Posted.*?)', 1, 1, null, 1), ' \d{1,2}:(.*)(AM|PM)') as reported,
        regexp_substr(sighting_report,'Posted: (.*)(Location.*?)', 1, 1, null, 1) as posted,
        regexp_replace(regexp_substr(sighting_report,'Location: (.*)(Shape.*?)', 1, 1, null, 1), ',') as location,
        NVL(regexp_substr(sighting_report,'Shape: (.*)(Duration.*?)', 1, 1, null, 1), ' ') as Shape,
        NVL(regexp_substr(sighting_report,'Duration:(.*)', 1, 1, null, 1), ' ') as Duration
        FROM ufo
);
 
---- Finding elements within larger blocks of text
-- Wildcard matches
 
SELECT count(*)
FROM ufo
WHERE description like '%wife%';
 
SELECT count(*)
FROM ufo
WHERE lower(description) like '%wife%';
 
-- There is no 'ilike' in Oracle
-- You could use regexp instead but it is highly inefficient in comparison to lower/upper(23,5s vs 3s)
SELECT count(*)
FROM ufo
WHERE regexp_like(description, 'wife', 'i');
 
SELECT count(*)
FROM ufo
WHERE lower(description) not like '%wife%';
 
SELECT count(*)
FROM ufo
WHERE lower(description) like '%wife%'
OR lower(description) like '%husband%';
 
SELECT count(*)
FROM ufo
WHERE lower(description) like '%wife%'
OR lower(description) like '%husband%'
AND lower(description) like '%mother%';
 
SELECT count(*)
FROM ufo
WHERE (lower(description) like '%wife%' 
OR lower(description) like '%husband%')
AND lower(description) like '%mother%';
 
SELECT 
case when lower(description) like '%driving%' then 'driving'
     when lower(description) like '%walking%' then 'walking'
     when lower(description) like '%running%' then 'running'
     when lower(description) like '%cycling%' then 'cycling'
     when lower(description) like '%swimming%' then 'swimming'
     else 'none' end as activity,
count(*)
FROM ufo
GROUP BY 
case when lower(description) like '%driving%' then 'driving'
     when lower(description) like '%walking%' then 'walking'
     when lower(description) like '%running%' then 'running'
     when lower(description) like '%cycling%' then 'cycling'
     when lower(description) like '%swimming%' then 'swimming'
     else 'none' end
ORDER BY 2 desc;
 
-- You can not use like directly in select in Oracle, the solution is using case
SELECT case when lower(description) like '%south%' then 1 else 0 end as south,
case when lower(description) like '%north%' then 1 else 0 end as north,
case when lower(description) like '%east%' then 1 else 0 end as east,
case when lower(description) like '%west%' then 1 else 0 end as west,
count(*)
FROM ufo
GROUP BY case when lower(description) like '%south%' then 1 else 0 end,
case when lower(description) like '%north%' then 1 else 0 end,
case when lower(description) like '%east%' then 1 else 0 end,
case when lower(description) like '%west%' then 1 else 0 end
ORDER BY 1,2,3,4;
 
SELECT 
count(case when lower(description) like '%south%' then 1 end) as south,
count(case when lower(description) like '%north%' then 1 end) as north,
count(case when lower(description) like '%west%' then 1 end) as west,
count(case when lower(description) like '%east%' then 1 end) as east
FROM ufo;
 
-- Exact matches
 
SELECT first_word, description
FROM
(
    SELECT trim(to_char(substr(description, 1,instr(description, ' ')))) as first_word,
    description
    FROM ufo
)
WHERE first_word = 'Red'
or first_word = 'Orange'
or first_word = 'Yellow'
or first_word = 'Green'
or first_word = 'Blue'
or first_word = 'Purple'
or first_word = 'White';
 
SELECT first_word, description
FROM
(
    SELECT trim(to_char(substr(description, 1,instr(description, ' ')))) as first_word,
    description
    FROM ufo
) 
WHERE first_word in ('Red','Orange','Yellow','Green','Blue','Purple','White');
 
SELECT 
case when first_word in ('red','orange','yellow','green', 
'blue','purple','white') then 'Color'
when first_word in ('round','circular','oval','cigar') 
then 'Shape'
when first_word like 'triang%' then 'Shape'
when first_word like 'flash%' then 'Motion'
when first_word like 'hover%' then 'Motion'
when first_word like 'pulsat%' then 'Motion'
else 'Other' end as first_word_type,
count(*)
FROM
(
    SELECT trim(lower(to_char(substr(description, 1,instr(description, ' '))))) as first_word,
    description
    FROM ufo
) a
GROUP BY case when first_word in ('red','orange','yellow','green', 
'blue','purple','white') then 'Color'
when first_word in ('round','circular','oval','cigar') 
then 'Shape'
when first_word like 'triang%' then 'Shape'
when first_word like 'flash%' then 'Motion'
when first_word like 'hover%' then 'Motion'
when first_word like 'pulsat%' then 'Motion'
else 'Other' end
ORDER BY 2 desc;
 
 
-- Regular expressions
-- No direct POSIX comparison in Oracle
SELECT case when regexp_like('To dane na temat UFO', 'dane') then 1 else 0 end as comparison
FROM dual;
 
SELECT case when regexp_like('To dane na temat UFO', 'DANE', 'i') then 1 else 0 end as comparison
FROM dual;
 
-- Finding and replacing with Regex
 
SELECT substr(description, 0, 50)
FROM ufo
WHERE regexp_like(substr(description, 0, 50), '[0-9]+ light[s ,.]');
 
-- Used substr() to shorten query time
SELECT regexp_substr(to_char(substr(description, 0, 500)), '[0-9]+ light[s ,.]', 1, 1),
count(*)
FROM ufo
WHERE regexp_like(to_char(substr(description, 0, 500)), '[0-9]+ light[s ,.]')
GROUP BY regexp_substr(to_char(substr(description, 0, 500)), '[0-9]+ light[s ,.]', 1, 1)
ORDER BY 2 desc;
 
SELECT min(to_number(substr(matched_text, 1 , instr(matched_text,' ')))) as min_lights,
max(to_number(substr(matched_text, 1 , instr(matched_text,' ')))) as max_lights
FROM
(
        SELECT regexp_substr(to_char(substr(description, 0, 500)), '[0-9]+ light[s ,.]', 1, 1) as matched_text,
        count(*)
        FROM ufo
        WHERE regexp_like(to_char(substr(description, 0, 500)), '[0-9]+ light[s ,.]')
        GROUP BY regexp_substr(to_char(substr(description, 0, 500)), '[0-9]+ light[s ,.]', 1, 1)
); 
 
SELECT regexp_substr(sighting_report,'Duration:(.*)', 1, 1, null, 1) as duration,
count(*) as reports
FROM ufo
GROUP BY regexp_substr(sighting_report,'Duration:(.*)', 1, 1, null, 1);
 
SELECT duration, regexp_substr(duration,'(^|\s|\d)([Mm][Ii][Nn][A-Za-z]*)($|\W)',1,1,'c',2) as matched_minutes
FROM
(
        SELECT regexp_substr(sighting_report,'Duration:(.*)', 1, 1, null, 1) as duration,
        count(*) as reports
        FROM ufo
        GROUP BY regexp_substr(sighting_report,'Duration:(.*)', 1, 1, null, 1)
);
 
SELECT duration, 
regexp_substr(duration,'(^|\s)([Mm][Ii][Nn][A-Za-z]*)($|\W)') as matched_minutes,
regexp_replace(duration, '(^|\s)([Mm][Ii][Nn][A-Za-z]*)($|\W)', ' min ') as replaced_text
FROM
(
        SELECT regexp_substr(sighting_report,'Duration:(.*)', 1, 1, null, 1) as duration,
        count(*) as reports
        FROM ufo
        GROUP BY regexp_substr(sighting_report,'Duration:(.*)', 1, 1, null, 1)
);
 
SELECT duration,
regexp_substr(duration,'(^|\s)([Hh][Oo][Uu][Rr][A-Za-z]*)($|\W)') as matched_hour,
regexp_substr(duration,'(^|\s)([Mm][Ii][Nn][A-Za-z]*)($|\W)') as matched_minutes,
regexp_replace(regexp_replace(duration,'(^|\s)([Mm][Ii][Nn][A-Za-z]*)($|\W)', ' min '),'(^|\s)([Hh][Oo][Uu][Rr][A-Za-z]*)($|\W)', ' hr ') as replaced_text
FROM
(
        SELECT regexp_substr(sighting_report,'Duration:(.*)', 1, 1, null, 1) as duration,
        count(*) as reports
        FROM ufo
        GROUP BY regexp_substr(sighting_report,'Duration:(.*)', 1, 1, null, 1)
);
 
----- Constructing and reshaping text
 
SELECT concat(shape, ' (shape)') as shape,
concat(reports, ' reports') as reports
FROM
(
        SELECT NVL(regexp_substr(sighting_report,'Shape: (.*)(Duration.*?)', 1, 1, null, 1), '*Unspecified* ') as Shape,
        count(*) as reports
        FROM ufo
        GROUP BY NVL(regexp_substr(sighting_report,'Shape: (.*)(Duration.*?)', 1, 1, null, 1), '*Unspecified*')
);
 
SELECT shape||' - '||location as shape_location, reports
FROM
(
        SELECT regexp_replace(regexp_substr(sighting_report,'Location: (.*)(Shape.*?)', 1, 1, null, 1), ',') as location,
        NVL(regexp_substr(sighting_report,'Shape: (.*)(Duration.*?)', 1, 1, null, 1), '*Unspecified* ') as Shape,
        count(*) as reports
        FROM ufo
        GROUP BY regexp_replace(regexp_substr(sighting_report,'Location: (.*)(Shape.*?)', 1, 1, null, 1), ','),
        NVL(regexp_substr(sighting_report,'Shape: (.*)(Duration.*?)', 1, 1, null, 1), '*Unspecified* ')
);
 
SELECT 'There were ' || reports || ' reports of ' || lower(shape) || ' objects. The earliest sighting was '
        || trim(to_char(earliest,'Month')) || ' ' || extract(day from earliest) || ', ' || extract(year from earliest)
       || ' and the most recent was ' || trim(to_char(latest,'Month')) || ' ' || extract(day from latest)
       || ', ' || extract(year from latest) || '.'
FROM
(
        SELECT shape,
        min(to_date(occurred, 'MM/DD/YYYY HH24:MI:SS')) as earliest,
        max(to_date(occurred, 'MM/DD/YYYY HH24:MI:SS')) as latest,
        sum(reports) as reports
        FROM
        (
                SELECT trim(regexp_replace(regexp_substr(sighting_report,'Occurred :(.*)(Reported.*?)', 1, 1, null, 1), '\(.*\)')) as Occurred,
                NVL(regexp_substr(sighting_report,'Shape: (.*)(Duration.*?)', 1, 1, null, 1), '*Unspecified* ') as Shape,
                count(*) as reports
                FROM ufo
                GROUP BY trim(regexp_replace(regexp_substr(sighting_report,'Occurred :(.*)(Reported.*?)', 1, 1, null, 1), '\(.*\)')),
                NVL(regexp_substr(sighting_report,'Shape: (.*)(Duration.*?)', 1, 1, null, 1), '*Unspecified* ')
        )
        WHERE length(occurred) >= 8
        GROUP BY shape
);
 
-- Reshaping
 
-- Use listagg instead of string_agg
SELECT location,
listagg(shape,', ') within group (order by shape asc) as shapes
FROM
(
        SELECT 
        case when regexp_substr(sighting_report,'Shape: (.*)(Duration.*?)', 1, 1, null, 1) = '' then 'Unknown'
             when regexp_substr(sighting_report,'Shape: (.*)(Duration.*?)', 1, 1, null, 1) = 'TRIANGULAR' then 'Triangle'
             else regexp_substr(sighting_report,'Shape: (.*)(Duration.*?)', 1, 1, null, 1)  
             end as shape,
        regexp_replace(regexp_substr(sighting_report,'Location: (.*)(Shape.*?)', 1, 1, null, 1), ',') as location,
        count(*) as reports
        FROM ufo
        GROUP BY 
        case when regexp_substr(sighting_report,'Shape: (.*)(Duration.*?)', 1, 1, null, 1) = '' then 'Unknown'
             when regexp_substr(sighting_report,'Shape: (.*)(Duration.*?)', 1, 1, null, 1) = 'TRIANGULAR' then 'Triangle'
             else regexp_substr(sighting_report,'Shape: (.*)(Duration.*?)', 1, 1, null, 1) end,
        regexp_replace(regexp_substr(sighting_report,'Location: (.*)(Shape.*?)', 1, 1, null, 1), ',')
) 
GROUP BY location;
 
-- Using a subquery with rownum <= 5 instead of just 'ufo' to get faster results
SELECT 
  trim(to_char(regexp_substr(lower(description), '\w+', 1, lvl))) word,
  count(*)
FROM -- ufo
     (
            SELECT description
            FROM ufo 
            WHERE rownum <= 5
     ),
     LATERAL (
       SELECT LEVEL lvl FROM dual 
       CONNECT BY LEVEL <= length (description) - length(replace(description, ' ')) + 1 
     ) words
GROUP BY trim(to_char(regexp_substr(lower(description), '\w+', 1, lvl)))
ORDER BY count(*) desc;
 
SELECT word, frequency
FROM(
    SELECT 
      trim(to_char(regexp_substr(lower(description), '\w+', 1, lvl))) word,
      count(*) frequency
    FROM (
                SELECT description
                FROM ufo 
                WHERE rownum <= 5
         ),
         LATERAL (
           SELECT LEVEL lvl FROM dual 
           CONNECT BY LEVEL <= length (description) - length(replace(description, ' ')) + 1 
         ) words
    GROUP BY trim(to_char(regexp_substr(lower(description), '\w+', 1, lvl)))
)a
LEFT JOIN stop_words b on a.word = b.stop_word
WHERE b.stop_word is null
ORDER BY 2 desc;

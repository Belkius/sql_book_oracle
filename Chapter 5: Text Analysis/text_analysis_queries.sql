---- Text characteristics
 
SELECT LENGTH(sighting_report), COUNT(*) AS records
FROM ufo
GROUP BY LENGTH(sighting_report)
ORDER BY 1;
 
---- Text parsing
 
-- Instead of left() and right() the best option in Oracle (in my opinion) is substr()
-- left(text, 8) = substr(text, 0 ,8)       right(text, 4) = substr(text, -4)
SELECT SUBSTR(sighting_report, 0, 8) AS left_digits, COUNT(*)
FROM ufo
GROUP BY SUBSTR(sighting_report, 0, 8);
 
-- Substr makes it easier to parse text in the middle
SELECT SUBSTR(sighting_report, 12, 14) AS occurred
FROM ufo;
-- If you really want to nest the statements
SELECT SUBSTR(SUBSTR(sighting_report, 0, 25), -14) AS occurred
FROM ufo;
 
-- Oracle has no split_part(), but we can check the position of substrings using instr (you of course can also use regexp_substr)
SELECT SUBSTR(sighting_report, INSTR(sighting_report, 'Occurred : ') + LENGTH('occurred : ')) AS split_1
FROM ufo;
 
-- Now regexp_substr is the only option
SELECT regexp_substr(sighting_report,'(.*) \(Entered', 1, 1, NULL, 1) AS split_2
FROM ufo;
 
SELECT regexp_substr(sighting_report,'Occurred :(.*)(\(Entered.*)', 1, 1, NULL, 1) AS occurred
FROM ufo;
-- If you really want to nest the statements
SELECT regexp_substr(
            SUBSTR(sighting_report, INSTR(sighting_report, 'Occurred : ') + LENGTH('occurred : '))
            ,'^(.*?) \(Entered', 1, 1, NULL, 1) AS occurred
FROM ufo;
 
SELECT regexp_replace(
            regexp_substr(sighting_report,'Occurred :(.*)(Reported.*?)', 1, 1, NULL, 1),
            '\(.*\)') AS occurred
FROM ufo;
 
SELECT regexp_replace(
            regexp_substr(sighting_report,'Occurred :(.*)(Reported.*?)', 1, 1, NULL, 1),
            '\(.*\)') AS occurred,
       NVL(regexp_substr(sighting_report,'Entered as : (.*)(\)Reported.*?)', 1, 1, NULL, 1), ' ')
            AS entered_as,
       regexp_substr(sighting_report,'Reported:(.*)(Posted.*?)', 1, 1, NULL, 1)
            AS reported,
       regexp_substr(sighting_report,'Posted: (.*)(Location.*?)', 1, 1, NULL, 1)
            AS posted,
       regexp_replace(
            regexp_substr(sighting_report,'Location: (.*)(Shape.*?)', 1, 1, NULL, 1),
            ',') AS Location,
       NVL(regexp_substr(sighting_report,'Shape: (.*)(Duration.*?)', 1, 1, NULL, 1), ' ')
            AS Shape,
       NVL(regexp_substr(sighting_report,'Duration:(.*)', 1, 1, NULL, 1), ' ')
            AS Duration
FROM ufo;
 
---- Text transformations
 
SELECT DISTINCT shape, INITCAP(shape) AS shape_clean
FROM
(
        SELECT NVL(regexp_substr(sighting_report,'Shape: (.*)(Duration.*?)', 1, 1, NULL, 1), ' ') AS shape
        FROM ufo
);
 
SELECT duration, TRIM(duration) AS duration_clean
FROM
(
    SELECT NVL(regexp_substr(sighting_report,'Duration:(.*)', 1, 1, NULL, 1), ' ')AS Duration
    FROM ufo
);
 
SELECT 
CASE WHEN LENGTH(occurred) < 8 THEN NULL ELSE TO_TIMESTAMP(occurred, 'MM/DD/RR HH24:MI:SS') END AS occured,
CASE WHEN LENGTH(reported) < 8 THEN NULL ELSE TO_TIMESTAMP(reported, 'MM/DD/YYYY HH24:MI:SS') END AS reported,
CASE WHEN posted = '' THEN NULL ELSE TO_DATE(posted, 'MM/DD/YYYY') END AS posted
FROM
(
        SELECT TRIM(regexp_replace(regexp_substr(sighting_report,'Occurred :(.*)(Reported.*?)', 1, 1, NULL, 1), '\(.*\)')) AS occurred,
        regexp_replace(regexp_substr(sighting_report,'Reported:(.*)(Posted.*?)', 1, 1, NULL, 1), ' \d{1,2}:(.*)(AM|PM)') AS reported,
        regexp_substr(sighting_report,'Posted: (.*)(Location.*?)', 1, 1, NULL, 1) AS posted
        FROM ufo
        --WHERE rownum = 1
);
 
SELECT location,
REPLACE(REPLACE(location,'close to','near'),'outside of','near') AS location_clean
FROM
(
        SELECT regexp_replace(
            regexp_substr(sighting_report,'Location: (.*)(Shape.*?)', 1, 1, NULL, 1),
            ',') AS location
        FROM ufo
);
--where location != replace(replace(location,'close to','near'),'outside of','near');
 
SELECT 
CASE WHEN LENGTH(occurred) < 8 THEN NULL ELSE TO_TIMESTAMP(occurred, 'MM/DD/RR HH24:MI:SS') END AS occured,
entered_as,
CASE WHEN LENGTH(reported) < 8 THEN NULL ELSE TO_TIMESTAMP(reported, 'MM/DD/YYYY HH24:MI:SS') END AS reported,
CASE WHEN posted = '' THEN NULL ELSE TO_DATE(posted, 'MM/DD/YYYY') END AS posted,
REPLACE(REPLACE(location,'close to','near'),'outside of','near') AS location,
INITCAP(shape) AS shape,
TRIM(duration) AS duration
FROM
(
        SELECT TRIM(regexp_replace(regexp_substr(sighting_report,'Occurred :(.*)(Reported.*?)', 1, 1, NULL, 1), '\(.*\)')) AS occurred,
        NVL(regexp_substr(sighting_report,'Entered as : (.*)(\)Reported.*?)', 1, 1, NULL, 1), ' ') AS entered_as,
        regexp_replace(regexp_substr(sighting_report,'Reported:(.*)(Posted.*?)', 1, 1, NULL, 1), ' \d{1,2}:(.*)(AM|PM)') AS reported,
        regexp_substr(sighting_report,'Posted: (.*)(Location.*?)', 1, 1, NULL, 1) AS posted,
        regexp_replace(regexp_substr(sighting_report,'Location: (.*)(Shape.*?)', 1, 1, NULL, 1), ',') AS location,
        NVL(regexp_substr(sighting_report,'Shape: (.*)(Duration.*?)', 1, 1, NULL, 1), ' ') AS Shape,
        NVL(regexp_substr(sighting_report,'Duration:(.*)', 1, 1, NULL, 1), ' ') AS Duration
        FROM ufo
);
 
---- Finding elements within larger blocks of text
-- Wildcard matches
 
SELECT COUNT(*)
FROM ufo
WHERE description LIKE '%wife%';
 
SELECT COUNT(*)
FROM ufo
WHERE LOWER(description) LIKE '%wife%';
 
-- There is no 'ilike' in Oracle
-- You could use regexp instead but it is highly inefficient in comparison to lower/upper(23,5s vs 3s)
SELECT COUNT(*)
FROM ufo
WHERE regexp_like(description, 'wife', 'i');
 
SELECT COUNT(*)
FROM ufo
WHERE LOWER(description) NOT LIKE '%wife%';
 
SELECT COUNT(*)
FROM ufo
WHERE LOWER(description) LIKE '%wife%'
OR LOWER(description) LIKE '%husband%';
 
SELECT COUNT(*)
FROM ufo
WHERE LOWER(description) LIKE '%wife%'
OR LOWER(description) LIKE '%husband%'
AND LOWER(description) LIKE '%mother%';
 
SELECT COUNT(*)
FROM ufo
WHERE (LOWER(description) LIKE '%wife%' 
OR LOWER(description) LIKE '%husband%')
AND LOWER(description) LIKE '%mother%';
 
SELECT 
CASE WHEN LOWER(description) LIKE '%driving%' THEN 'driving'
     WHEN LOWER(description) LIKE '%walking%' THEN 'walking'
     WHEN LOWER(description) LIKE '%running%' THEN 'running'
     WHEN LOWER(description) LIKE '%cycling%' THEN 'cycling'
     WHEN LOWER(description) LIKE '%swimming%' THEN 'swimming'
     ELSE 'none' END AS activity,
COUNT(*)
FROM ufo
GROUP BY 
CASE WHEN LOWER(description) LIKE '%driving%' THEN 'driving'
     WHEN LOWER(description) LIKE '%walking%' THEN 'walking'
     WHEN LOWER(description) LIKE '%running%' THEN 'running'
     WHEN LOWER(description) LIKE '%cycling%' THEN 'cycling'
     WHEN LOWER(description) LIKE '%swimming%' THEN 'swimming'
     ELSE 'none' END
ORDER BY 2 DESC;
 
-- You can not use like directly in select in Oracle, the solution is using case
SELECT CASE WHEN LOWER(description) LIKE '%south%' THEN 1 ELSE 0 END AS south,
CASE WHEN LOWER(description) LIKE '%north%' THEN 1 ELSE 0 END AS north,
CASE WHEN LOWER(description) LIKE '%east%' THEN 1 ELSE 0 END AS east,
CASE WHEN LOWER(description) LIKE '%west%' THEN 1 ELSE 0 END AS west,
COUNT(*)
FROM ufo
GROUP BY CASE WHEN LOWER(description) LIKE '%south%' THEN 1 ELSE 0 END,
CASE WHEN LOWER(description) LIKE '%north%' THEN 1 ELSE 0 END,
CASE WHEN LOWER(description) LIKE '%east%' THEN 1 ELSE 0 END,
CASE WHEN LOWER(description) LIKE '%west%' THEN 1 ELSE 0 END
ORDER BY 1,2,3,4;
 
SELECT 
COUNT(CASE WHEN LOWER(description) LIKE '%south%' THEN 1 END) AS south,
COUNT(CASE WHEN LOWER(description) LIKE '%north%' THEN 1 END) AS north,
COUNT(CASE WHEN LOWER(description) LIKE '%west%' THEN 1 END) AS west,
COUNT(CASE WHEN LOWER(description) LIKE '%east%' THEN 1 END) AS east
FROM ufo;
 
-- Exact matches
 
SELECT first_word, description
FROM
(
    SELECT TRIM(TO_CHAR(SUBSTR(description, 1,INSTR(description, ' ')))) AS first_word,
    description
    FROM ufo
)
WHERE first_word = 'Red'
OR first_word = 'Orange'
OR first_word = 'Yellow'
OR first_word = 'Green'
OR first_word = 'Blue'
OR first_word = 'Purple'
OR first_word = 'White';
 
SELECT first_word, description
FROM
(
    SELECT TRIM(TO_CHAR(SUBSTR(description, 1,INSTR(description, ' ')))) AS first_word,
    description
    FROM ufo
) 
WHERE first_word IN ('Red','Orange','Yellow','Green','Blue','Purple','White');
 
SELECT 
CASE WHEN first_word IN ('red','orange','yellow','green', 
'blue','purple','white') THEN 'Color'
WHEN first_word IN ('round','circular','oval','cigar') 
THEN 'Shape'
WHEN first_word LIKE 'triang%' THEN 'Shape'
WHEN first_word LIKE 'flash%' THEN 'Motion'
WHEN first_word LIKE 'hover%' THEN 'Motion'
WHEN first_word LIKE 'pulsat%' THEN 'Motion'
ELSE 'Other' END AS first_word_type,
COUNT(*)
FROM
(
    SELECT TRIM(LOWER(TO_CHAR(SUBSTR(description, 1,INSTR(description, ' '))))) AS first_word,
    description
    FROM ufo
) a
GROUP BY CASE WHEN first_word IN ('red','orange','yellow','green', 
'blue','purple','white') THEN 'Color'
WHEN first_word IN ('round','circular','oval','cigar') 
THEN 'Shape'
WHEN first_word LIKE 'triang%' THEN 'Shape'
WHEN first_word LIKE 'flash%' THEN 'Motion'
WHEN first_word LIKE 'hover%' THEN 'Motion'
WHEN first_word LIKE 'pulsat%' THEN 'Motion'
ELSE 'Other' END
ORDER BY 2 DESC;
 
 
-- Regular expressions
-- No direct POSIX comparison in Oracle
SELECT CASE WHEN regexp_like('To dane na temat UFO', 'dane') THEN 1 ELSE 0 END AS comparison
FROM dual;
 
SELECT CASE WHEN regexp_like('To dane na temat UFO', 'DANE', 'i') THEN 1 ELSE 0 END AS comparison
FROM dual;
 
-- Finding and replacing with Regex
 
SELECT SUBSTR(description, 0, 50)
FROM ufo
WHERE regexp_like(SUBSTR(description, 0, 50), '[0-9]+ light[s ,.]');
 
-- Used substr() to shorten query time
SELECT regexp_substr(TO_CHAR(SUBSTR(description, 0, 500)), '[0-9]+ light[s ,.]', 1, 1),
COUNT(*)
FROM ufo
WHERE regexp_like(TO_CHAR(SUBSTR(description, 0, 500)), '[0-9]+ light[s ,.]')
GROUP BY regexp_substr(TO_CHAR(SUBSTR(description, 0, 500)), '[0-9]+ light[s ,.]', 1, 1)
ORDER BY 2 DESC;
 
SELECT MIN(TO_NUMBER(SUBSTR(matched_text, 1 , INSTR(matched_text,' ')))) AS min_lights,
MAX(TO_NUMBER(SUBSTR(matched_text, 1 , INSTR(matched_text,' ')))) AS max_lights
FROM
(
        SELECT regexp_substr(TO_CHAR(SUBSTR(description, 0, 500)), '[0-9]+ light[s ,.]', 1, 1) AS matched_text,
        COUNT(*)
        FROM ufo
        WHERE regexp_like(TO_CHAR(SUBSTR(description, 0, 500)), '[0-9]+ light[s ,.]')
        GROUP BY regexp_substr(TO_CHAR(SUBSTR(description, 0, 500)), '[0-9]+ light[s ,.]', 1, 1)
); 
 
SELECT regexp_substr(sighting_report,'Duration:(.*)', 1, 1, NULL, 1) AS duration,
COUNT(*) AS reports
FROM ufo
GROUP BY regexp_substr(sighting_report,'Duration:(.*)', 1, 1, NULL, 1);
 
SELECT duration, regexp_substr(duration,'(^|\s|\d)([Mm][Ii][Nn][A-Za-z]*)($|\W)',1,1,'c',2) AS matched_minutes
FROM
(
        SELECT regexp_substr(sighting_report,'Duration:(.*)', 1, 1, NULL, 1) AS duration,
        COUNT(*) AS reports
        FROM ufo
        GROUP BY regexp_substr(sighting_report,'Duration:(.*)', 1, 1, NULL, 1)
);
 
SELECT duration, 
regexp_substr(duration,'(^|\s)([Mm][Ii][Nn][A-Za-z]*)($|\W)') AS matched_minutes,
regexp_replace(duration, '(^|\s)([Mm][Ii][Nn][A-Za-z]*)($|\W)', ' min ') AS replaced_text
FROM
(
        SELECT regexp_substr(sighting_report,'Duration:(.*)', 1, 1, NULL, 1) AS duration,
        COUNT(*) AS reports
        FROM ufo
        GROUP BY regexp_substr(sighting_report,'Duration:(.*)', 1, 1, NULL, 1)
);
 
SELECT duration,
regexp_substr(duration,'(^|\s)([Hh][Oo][Uu][Rr][A-Za-z]*)($|\W)') AS matched_hour,
regexp_substr(duration,'(^|\s)([Mm][Ii][Nn][A-Za-z]*)($|\W)') AS matched_minutes,
regexp_replace(regexp_replace(duration,'(^|\s)([Mm][Ii][Nn][A-Za-z]*)($|\W)', ' min '),'(^|\s)([Hh][Oo][Uu][Rr][A-Za-z]*)($|\W)', ' hr ') AS replaced_text
FROM
(
        SELECT regexp_substr(sighting_report,'Duration:(.*)', 1, 1, NULL, 1) AS duration,
        COUNT(*) AS reports
        FROM ufo
        GROUP BY regexp_substr(sighting_report,'Duration:(.*)', 1, 1, NULL, 1)
);
 
----- Constructing and reshaping text
 
SELECT CONCAT(shape, ' (shape)') AS shape,
CONCAT(reports, ' reports') AS reports
FROM
(
        SELECT NVL(regexp_substr(sighting_report,'Shape: (.*)(Duration.*?)', 1, 1, NULL, 1), '*Unspecified* ') AS Shape,
        COUNT(*) AS reports
        FROM ufo
        GROUP BY NVL(regexp_substr(sighting_report,'Shape: (.*)(Duration.*?)', 1, 1, NULL, 1), '*Unspecified*')
);
 
SELECT shape||' - '||location AS shape_location, reports
FROM
(
        SELECT regexp_replace(regexp_substr(sighting_report,'Location: (.*)(Shape.*?)', 1, 1, NULL, 1), ',') AS location,
        NVL(regexp_substr(sighting_report,'Shape: (.*)(Duration.*?)', 1, 1, NULL, 1), '*Unspecified* ') AS Shape,
        COUNT(*) AS reports
        FROM ufo
        GROUP BY regexp_replace(regexp_substr(sighting_report,'Location: (.*)(Shape.*?)', 1, 1, NULL, 1), ','),
        NVL(regexp_substr(sighting_report,'Shape: (.*)(Duration.*?)', 1, 1, NULL, 1), '*Unspecified* ')
);
 
SELECT 'There were ' || reports || ' reports of ' || LOWER(shape) || ' objects. The earliest sighting was '
        || TRIM(TO_CHAR(earliest,'Month')) || ' ' || EXTRACT(DAY FROM earliest) || ', ' || EXTRACT(YEAR FROM earliest)
       || ' and the most recent was ' || TRIM(TO_CHAR(latest,'Month')) || ' ' || EXTRACT(DAY FROM latest)
       || ', ' || EXTRACT(YEAR FROM latest) || '.'
FROM
(
        SELECT shape,
        MIN(TO_DATE(occurred, 'MM/DD/YYYY HH24:MI:SS')) AS earliest,
        MAX(TO_DATE(occurred, 'MM/DD/YYYY HH24:MI:SS')) AS latest,
        SUM(reports) AS reports
        FROM
        (
                SELECT TRIM(regexp_replace(regexp_substr(sighting_report,'Occurred :(.*)(Reported.*?)', 1, 1, NULL, 1), '\(.*\)')) AS Occurred,
                NVL(regexp_substr(sighting_report,'Shape: (.*)(Duration.*?)', 1, 1, NULL, 1), '*Unspecified* ') AS Shape,
                COUNT(*) AS reports
                FROM ufo
                GROUP BY TRIM(regexp_replace(regexp_substr(sighting_report,'Occurred :(.*)(Reported.*?)', 1, 1, NULL, 1), '\(.*\)')),
                NVL(regexp_substr(sighting_report,'Shape: (.*)(Duration.*?)', 1, 1, NULL, 1), '*Unspecified* ')
        )
        WHERE LENGTH(occurred) >= 8
        GROUP BY shape
);
 
-- Reshaping
 
-- Use listagg instead of string_agg
SELECT location,
listagg(shape,', ') within GROUP (ORDER BY shape ASC) AS shapes
FROM
(
        SELECT 
        CASE WHEN regexp_substr(sighting_report,'Shape: (.*)(Duration.*?)', 1, 1, NULL, 1) = '' THEN 'Unknown'
             WHEN regexp_substr(sighting_report,'Shape: (.*)(Duration.*?)', 1, 1, NULL, 1) = 'TRIANGULAR' THEN 'Triangle'
             ELSE regexp_substr(sighting_report,'Shape: (.*)(Duration.*?)', 1, 1, NULL, 1)  
             END AS shape,
        regexp_replace(regexp_substr(sighting_report,'Location: (.*)(Shape.*?)', 1, 1, NULL, 1), ',') AS location,
        COUNT(*) AS reports
        FROM ufo
        GROUP BY 
        CASE WHEN regexp_substr(sighting_report,'Shape: (.*)(Duration.*?)', 1, 1, NULL, 1) = '' THEN 'Unknown'
             WHEN regexp_substr(sighting_report,'Shape: (.*)(Duration.*?)', 1, 1, NULL, 1) = 'TRIANGULAR' THEN 'Triangle'
             ELSE regexp_substr(sighting_report,'Shape: (.*)(Duration.*?)', 1, 1, NULL, 1) END,
        regexp_replace(regexp_substr(sighting_report,'Location: (.*)(Shape.*?)', 1, 1, NULL, 1), ',')
) 
GROUP BY location;
 
SELECT word, COUNT(*) AS frequency
FROM
(
        SELECT TO_CHAR(regexp_substr(LOWER(description), '\w+', 1, LEVEL)) AS word
        FROM ufo
        WHERE ROWNUM = 1
        CONNECT BY TO_CHAR(regexp_substr(LOWER(description), '\w+', 1, LEVEL)) IS NOT NULL
)
GROUP BY word
ORDER BY 2 DESC;
 
SELECT word, COUNT(*) AS frequency
FROM
(
        SELECT TO_CHAR(regexp_substr(LOWER(description), '\w+', 1, LEVEL)) AS word
        FROM ufo
        CONNECT BY TO_CHAR(regexp_substr(LOWER(description), '\w+', 1, LEVEL)) IS NOT NULL
) a
LEFT JOIN stop_words b ON a.word = b.stop_word
WHERE b.stop_word IS NULL
GROUP BY word
ORDER BY 2 DESC;

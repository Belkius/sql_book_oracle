-- delete the table if it already exist
BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE videogame_sales';
EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE != -942 THEN
         RAISE;
      END IF;
END;
 
-- create the table
CREATE table videogame_sales
(
rank int,
name varchar(200),
platform varchar(20),
year int,
genre varchar(40),
publisher varchar(40),
na_sales decimal(10, 2),
eu_sales decimal(10, 2),
jp_sales decimal(10, 2),
other_sales decimal(10, 2),
global_sales decimal(10, 2)
);
 
-- import the data in one of three methods Oracle gives you:
-- 1. Use the SQLDeveloper wizard (right-click table > import)
-- 2. Use SQL*Loader (must have SQL*Plus installed)
-- 3. Define the CSV file as an external table
 

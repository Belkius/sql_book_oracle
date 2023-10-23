-- delete the table if it already exist
BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE ufo';
EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE != -942 THEN
         RAISE;
      END IF;
END;
 
-- create the table
CREATE TABLE ufo
(
sighting_report VARCHAR(1000),
description clob
);
 
-- import the data in one of three methods Oracle gives you:
-- 1. Use the SQLDeveloper wizard (right-click table > import)
-- 2. Use SQL*Loader (must have SQL*Plus installed)
-- 3. Define the CSV file as an external table

-- delete the table if it already exist
BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE legislators_terms';
EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE != -942 THEN
         RAISE;
      END IF;
END;
 
-- create the table
CREATE TABLE legislators_terms
(
id_bioguide VARCHAR(7),
term_number int,
term_id VARCHAR(12) NOT NULL,
term_type VARCHAR(3),
term_start DATE,
term_end DATE,
state VARCHAR(2),
district int,
class int,
party VARCHAR(35),
how VARCHAR(25),
url VARCHAR(50),
address VARCHAR(70),
phone VARCHAR(15),
fax VARCHAR(15),
contact_form VARCHAR(150),
office VARCHAR(50),
state_rank VARCHAR(25),
rss_url VARCHAR(150),
caucus VARCHAR(25),
CONSTRAINT term_pk PRIMARY KEY (term_id)
);
 
 
-- import the data in one of three methods Oracle gives you:
-- 1. Use the SQLDeveloper wizard (right-click table > import)
-- 2. Use SQL*Loader (must have SQL*Plus installed)
-- 3. Define the CSV file as an external table
 

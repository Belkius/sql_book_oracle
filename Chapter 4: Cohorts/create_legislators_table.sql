-- delete the table if it already exist
BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE legislators';
EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE != -942 THEN
         RAISE;
      END IF;
END;
 
-- create the table
CREATE TABLE legislators
(
full_name VARCHAR(50),
first_name VARCHAR(50),
last_name VARCHAR(50),
middle_name VARCHAR(50),
nickname VARCHAR(50),
suffix VARCHAR(50),
other_names_end DATE,
other_names_middle VARCHAR(50),
other_names_last VARCHAR(50),
birthday DATE,
gender VARCHAR(50),
id_bioguide VARCHAR(50) NOT NULL,
id_bioguide_previous_0 VARCHAR(50),
id_govtrack int,
id_icpsr int,
id_wikipedia VARCHAR(60),
id_wikidata VARCHAR(50),
id_google_entity_id VARCHAR(50),
id_house_history int,
id_house_history_alternate int,
id_thomas int,
id_cspan int,
id_votesmart int,
id_lis VARCHAR(50),
id_ballotpedia VARCHAR(50),
id_opensecrets VARCHAR(50),
id_fec_0 VARCHAR(50),
id_fec_1 VARCHAR(50),
id_fec_2 VARCHAR(50),
CONSTRAINT bioguide_pk PRIMARY KEY (id_bioguide)
);
 
 
-- import the data in one of three methods Oracle gives you:
-- 1. Use the SQLDeveloper wizard (right-click table > import)
-- 2. Use SQL*Loader (must have SQL*Plus installed)
-- 3. Define the CSV file as an external table
 

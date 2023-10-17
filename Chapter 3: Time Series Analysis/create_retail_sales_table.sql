-- delete the table if it already exists

BEGIN
	EXECUTE IMMEDIATE 'DROP TABLE retail_sales';
EXCEPTION
	WHEN OTHERS THEN
		IF SQLCODE != -942 THEN
			RAISE;
		END IF;
END;

-- create the table

CREATE TABLE retail_sales(
sales_month date,
naics_code varchar(50),
kind_of_business varchar(100),
reason_for_null varchar(50),
sales decimal
);

-- Import the data in one of three methods Oracle gives you:
-- 1. Use the SQLDeveloper wizard (right-click table > import)
-- 2. Use SQL*Loader (must have SQL*Plus installed)
-- 3. Define the CSV file as an external table

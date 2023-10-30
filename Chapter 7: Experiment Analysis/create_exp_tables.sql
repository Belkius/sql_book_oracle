-- delete the table game_users if it already exist
BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE game_users';
EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE != -942 THEN
         RAISE;
      END IF;
END;
 
-- create the table game_users
CREATE table game_users
(
user_id int,
created date,
country varchar(50)
);
 
-- delete the table game_actions if it already exist
BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE game_actions';
EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE != -942 THEN
         RAISE;
      END IF;
END;
 
-- create the table game_actions
CREATE table game_actions
(
user_id int,
action varchar(50),
action_date date
);
 
-- delete the table game_purchases if it already exist
BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE game_purchases';
EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE != -942 THEN
         RAISE;
      END IF;
END;
 
-- create the table game_purchases
CREATE table game_purchases
(
user_id int,
purch_date date,
amount decimal(10,2)
);
 
 
-- delete the table exp_assignment if it already exist
BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE exp_assignment';
EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE != -942 THEN
         RAISE;
      END IF;
END;
 
-- create the table exp_assignment
CREATE table exp_assignment
(
exp_name varchar(50),
user_id int,
exp_date date,
variant varchar(50)
);
 
-- import the data into all tables in one of three methods Oracle gives you:
-- 1. Use the SQLDeveloper wizard (right-click table > import)
-- 2. Use SQL*Loader (must have SQL*Plus installed)
-- 3. Define the CSV file as an external table

-- delete the table if it already exist
BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE earthquakes';
EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE != -942 THEN
         RAISE;
      END IF;
END;
 
-- create the table
CREATE table earthquakes
(
time timestamp,
latitude number(20,10),
longitude number(20,10),
depth number(20,10),
mag number(20,10),
magType varchar2(50),
nst number(20,10),
gap number(20,10),
dmin number(20,10),
rms number(20,10),
net varchar2(50),
id varchar2(50),
updated timestamp,
place varchar2(200),
type varchar2(50),
horizontalError number(20,10),
depthError number(20,10),
magError number(20,10),
magNst number(20,10),
status varchar2(50),
locationSource varchar2(50),
magSource varchar2(50)
);
 
-- import the data in one of three methods Oracle gives you:
-- 1. Use the SQLDeveloper wizard (right-click table > import)
-- 2. Use SQL*Loader (must have SQL*Plus installed)
-- 3. Define the CSV file as an external table

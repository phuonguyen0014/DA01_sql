--baitap1
select NAME 
from CITY
where POPULATION >= 120000 and COUNTRYCODE = 'USA';

--baitap2
select * from CITY 
where COUNTRYCODE = 'JPN';

--baitap3
select CITY, STATE from STATION;

--baitap4
select distinct CITY 
from STATION 
WHERE CITY LIKE 'a%' 
  OR CITY LIKE 'e%' 
  OR CITY LIKE 'i%' 
  OR CITY LIKE 'o%' 
  OR CITY LIKE 'u%';

--baitap5
select distinct CITY 
from STATION 
WHERE CITY LIKE '%a' 
  OR CITY LIKE '%e' 
  OR CITY LIKE '%i' 
  OR CITY LIKE '%o' 
  OR CITY LIKE '%u';

--baitap6
select distinct CITY 
from STATION 
WHERE CITY NOT LIKE 'a%' 
  OR CITY NOT LIKE 'e%' 
  OR CITY NOT LIKE 'i%' 
  OR CITY NOT LIKE 'o%' 
  OR CITY NOT LIKE 'u%';

--baitap7
SELECT name FROM Employee ORDER BY name ASC;

--baitap8
SELECT * FROM Employee 
WHERE salary > 2000 AND months < 10
ORDER BY employee_id asc;

--baitap9
select product_id 
from Products 
where low_fats = 'Y' and recyclable = 'Y';

--baitap10
select id from Customer
where referee_id != 2;

--baitap11
select name, population, area 
from World where area >= 3000000 or population >= 25000000;

--baitap12
select distinct author_id as id from Views 
where author_id = viewer_id order by id asc;

--baitap13
SELECT * FROM parts_assembly WHERE finish_date is null;

--baitap14
select index from lyft_drivers 
where yearly_salary <= 30000 or yearly_salary >= 70000;

--baitap15
select advertising_channel from uber_advertising
where money_spent > 100000 and year = 2019;

--baitap1
SELECT 
SUM(CASE
  WHEN device_type = 'laptop' THEN 1
  ELSE 0
  END) AS laptop_views,
SUM(CASE
  WHEN device_type IN ('tablet','phone') THEN 1
  ELSE 0
  END) AS mobile_views
FROM viewership;

--baitap2
select x, y, z,
case
when (x+y) > z AND (x+z) > y AND (z+y) > x then 'Yes'
else 'No'
end triangle
from Triangle;

--baitap3
SELECT 
ROUND(
(SUM(CASE
WHEN call_category IN ('n/a', ' ') then 1
END)) / COUNT(*) * 100.0, 1) as call_percentage
FROM callers;


--baitap4
SELECT name
FROM Customer
WHERE COALESCE(referee_id,0) <> 2;

--baitap5
select survived,
SUM(CASE WHEN pclass = 1 THEN 1 ELSE 0 END) AS first_class,
SUM(CASE WHEN pclass = 2 THEN 1 ELSE 0 END) AS second_class,
SUM(CASE WHEN pclass = 3 THEN 1 ELSE 0 END) AS third_class
FROM titanic
GROUP BY survived;

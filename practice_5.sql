--baitap1

select COUNTRY.name, CEILING(AVG(CITY.population))
from COUNTRY
join CITY 
on CITY.countrycode = COUNTRY.code
group by COUNTRY.name;

--baitap2
SELECT ROUND(
  SUM(CASE
WHEN texts.signup_action = 'Confirmed' THEN 1 
ELSE 0 
END) / COUNT(emails.email_id), 2)
FROM emails
LEFT JOIN texts
ON emails.email_id = texts.email_id;

--baitap3
SELECT b.age_bucket, 
ROUND(
(
  (CASE WHEN a.activity_type = 'send' then a.time_spent ELSE 0 END) /
  ((CASE WHEN a.activity_type = 'send' then a.time_spent ELSE 0 END) +
    (CASE WHEN a.activity_type = 'open' then a.time_spent ELSE 0 END)
  )
) * 100.0, 2) as send_perc,
ROUND(
(
  (CASE WHEN a.activity_type = 'open' then a.time_spent ELSE 0 END) /
  ((CASE WHEN a.activity_type = 'send' then a.time_spent ELSE 0 END) +
    (CASE WHEN a.activity_type = 'open' then a.time_spent ELSE 0 END)
  )
) * 100.0, 2) as open_perc
FROM activities a
INNER JOIN age_breakdown b
ON a.user_id = b.user_id
GROUP BY b.age_bucket;
--column "a.activity_type" must appear in the GROUP BY clause or be used in an aggregate function (LINE: 3)

--baitap4
SELECT c.customer_id
FROM customer_contracts c
LEFT JOIN products p
ON c.product_id = p.product_id
GROUP BY c.customer_id
HAVING COUNT(DISTINCT p.product_category) = (SELECT COUNT(DISTINCT product_category) FROM products);

--baitap5
select f1.employee_id, f1.name, count(f1.employee_id) as reports_count, round(avg(f2.age),0) as average_age 
from Employees f1
join Employees f2
on f1.reports_to = f2.reports_to
group by f1.employee_id
HAVING COUNT(DISTINCT f1.employee_id) >= 1;

--baitap6
select p.product_name, sum(o.unit)
from products p  
left join orders o
on p.product_id = o.product_id
where o.order_date = '2020-02' and o.unit >= 100
group by p.product_id;     

--baitap7
SELECT p.page_id
FROM pages p
LEFT JOIN page_likes l
on p.page_id = l.page_id
where l.page_id is NULL
ORDER BY p.page_id ASC;

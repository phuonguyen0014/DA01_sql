--baitap1

select COUNTRY.name, CEILING(AVG(CITY.population))  -- dùng FLOOR - rounded down to the nearest integer - làm tròn ở cận dưới
from COUNTRY
join CITY 
on CITY.countrycode = COUNTRY.code
group by COUNTRY.name;

--> Sửa lại
select COUNTRY.name, FLOOR(AVG(CITY.population)) as  average_population
from COUNTRY
join CITY 
on CITY.countrycode = COUNTRY.code
group by COUNTRY.name;

--baitap2
SELECT ROUND(		-- round(a/b) =>> ta phải cast a hoặc b về decimal --> CAST() function converts a value (of any type) into a specified datatype.
  SUM(CASE
WHEN texts.signup_action = 'Confirmed' THEN 1 
ELSE 0 
END) / COUNT(emails.email_id), 2)
FROM emails
LEFT JOIN texts
ON emails.email_id = texts.email_id;

--> Sửa lại
SELECT
ROUND(cast(
  SUM(CASE
WHEN texts.signup_action = 'Confirmed' THEN 1 
ELSE 0 
END) as decimal)/ COUNT(*), 2)
FROM emails
LEFT JOIN texts
ON emails.email_id = texts.email_id;


--baitap3
SELECT 
    b.age_bucket, 
    ROUND(
        SUM(CASE WHEN a.activity_type = 'send' THEN a.time_spent ELSE 0 END) / 
        (SUM(CASE WHEN a.activity_type = 'send' THEN a.time_spent ELSE 0 END) + 
         SUM(CASE WHEN a.activity_type = 'open' THEN a.time_spent ELSE 0 END)
        ) * 100.0, 2
    ) AS send_perc,
    ROUND(
        SUM(CASE WHEN a.activity_type = 'open' THEN a.time_spent ELSE 0 END) / 
        (SUM(CASE WHEN a.activity_type = 'send' THEN a.time_spent ELSE 0 END) + 
         SUM(CASE WHEN a.activity_type = 'open' THEN a.time_spent ELSE 0 END)
        ) * 100.0, 2
    ) AS open_perc
FROM activities a
INNER JOIN age_breakdown b ON a.user_id = b.user_id
GROUP BY b.age_bucket;

--baitap4
SELECT cc.customer_id
FROM customer_contracts cc
JOIN products p 
ON cc.product_id = p.product_id
GROUP BY cc.customer_id
HAVING 
    SUM(CASE WHEN p.product_category = 'Analytics' THEN 1 ELSE 0 END) >= 1
    AND SUM(CASE WHEN p.product_category = 'Containers' THEN 1 ELSE 0 END) >= 1
    AND SUM(CASE WHEN p.product_category = 'Compute' THEN 1 ELSE 0 END) >= 1;


--baitap5
select f1.employee_id, f1.name, 
	count(f2.employee_id) as reports_count, 
	round(avg(f2.age),0) as average_age 
from Employees f1
join Employees f2
on f1.employee_id = f2.reports_to
group by f1.name
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


--Mid test--
--baitap1
select distinct Min(replacement_cost) as chi_phi_thap 
from film;

--baitap2
SELECT COUNT(CASE WHEN replacement_cost >= 9.99 AND replacement_cost <= 19.99 THEN 1 ELSE NULL END) AS low
FROM film;
-- khi em thử GROUP BY film_id hay replacement_cost, nó ko trả ra kết quả đúng
/*select COUNT(CASE
	 WHEN replacement_cost >= 9.99 AND replacement_cost <= 19.99 THEN 1 ELSE 0 END) as low
from film
GROUP BY film_id;*/
-- ngoài ra em muốn hỏi ở phần điều kiện else, lúc đầu em cho ELSE là 0, k.quả = 1000
-- nhưng khi em cho ELSE là NULL, k.quả = 514
-- em muốn hỏi tại sao lại ra 2 kết quả khác nhau ở đây ạ

-baitap3
select f.title, MAX(f.length), c.name
from film f
join film_category fc
on f.film_id = fc.film_id
join category c
on c.category_id = fc.category_id
where c.name = 'Drama' or c.name = 'Sports'
group by f.title, c.name, f.length
order by f.length DESC
LIMIT 1;

--baitap4
select COUNT(c.name) AS popular, c.name
from film f
join film_category fc
on f.film_id = fc.film_id
join category c
on c.category_id = fc.category_id
group by c.name;

--baitap5
select a.actor_id, a.first_name, a.last_name, COUNT(f.film_id) as so_luong_phim
from actor a
join film_actor fa
on a.actor_id = fa.actor_id
join film f
on f.film_id = fa.film_id
group by a.actor_id
order by so_luong_phim DESC
LIMIT 1;

--baitap6
select COUNT(a.address_id) AS null_addresses
from address a
left join customer c
on a.address_id = c.address_id
where c.customer_id IS NULL;

--baitap7
select SUM(p.amount) as total, ci.city
from payment p
join customer c
on p.customer_id = c.customer_id
join address a
on c.address_id = a.address_id
join city ci
on ci.city_id = a.city_id
group by ci.city
order by total DESC
LIMIT 1;

--baitap8
select ci.city, co.country, SUM(p.amount) as doanh_thu
from payment p
join customer c
on p.customer_id = c.customer_id
join address a
on c.address_id = a.address_id
join city ci
on ci.city_id = a.city_id
join country co
on co.country_id = ci.country_id
group by ci.city, co.country
order by doanh_thu DESC;


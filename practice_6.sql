
--baitap4
/*
Write a query to return the IDs of the Facebook pages that have zero likes. The output should be sorted in ascending order based on the page IDs.
*/

select page_id 
from pages
where page_id NOT IN (select page_id from page_likes)
ORDER BY page_id ASC;

--baitap5
/*
Assume you're given a table containing information on Facebook user actions. Write a query to obtain number of monthly active users (MAUs) in July 2022, including the month in numerical format "1, 2, 3".
Hint:
An active user is defined as a user who has performed actions such as 'sign-in', 'like', or 'comment' in both the current month and the previous month.
*/
SELECT user_id, EXTRACT(month FROM event_date) AS month, COUNT(DISTINCT user_id) AS monthly_active_users
FROM user_actions
WHERE EXTRACT(month FROM event_date) IN (6, 7) AND EXTRACT(year FROM event_date) = 2022
GROUP BY month, user_id
ORDER BY month;

--baitap6
WITH 
num_trans_aall_trans AS (
select id, country, COUNT(*) as trans_count, sum(amount) as trans_total_amount
from Transactions
group by country, (extract(month from trans_date)))
,
num_approved_aapproved_trans AS (
select id, country, count(state) as approved_count, sum(amount) as approved_total_amount
from Transactions 
where state ='approved'
group by country, (extract(month from trans_date)))

SELECT 
   concat(EXTRACT(YEAR FROM trans_date) , '-', EXTRACT(MONTH FROM trans_date)) AS month,
   t.country,
   a.trans_count,
   b.approved_count,
   a.trans_total_amount,
   b.approved_total_amount
   from Transactions t
   join num_trans_aall_trans a
   on a.id = t.id
   join num_approved_aapproved_trans b
   on b.id = a.id;

--baitap7
select p.product_id, MIN(year) as first_year, s.quantity, s.price
from product p
join sales s
on p.product_id = s.product_id
group by p.product_id;

--baitap8
select c.customer_id
from customer c
join product p
on c.product_key = p.product_key 
group by c.customer_id
HAVING COUNT(DISTINCT c.product_key) = (SELECT COUNT(*) FROM Product); 
--đếm các giá trị "product_key" cho từng nhóm customer_id trong bảng customer. Nếu số lượng khớp với số lượng giá trị "product_key" riêng biệt trong bảng product

--baitap9
select e.employee_id
from employees e
left join employees sub
on e.manager_id = sub.employee_id
where sub.employee_id is NULL and e.salary < 30000;

--baitap10
select COUNT(DISTINCT company_id) as duplicate_companies
from job_listings 
where (title, description) IN
(SELECT title, description
    FROM job_listings
    GROUP BY title, description
    HAVING COUNT(*) > 1);
-- Subquery -> trả về các giá trị title, description bị trùng lặp


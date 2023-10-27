--baitap2
select category, 
  product, 
  SUM(spend) as total_spend
from product_spend
where EXTRACT(year from transaction_date) = 2022
      and spend IN (
                    select MAX(spend) 
                    from product_spend
                    where EXTRACT(year from transaction_date) = 2022
                    GROUP BY product
                    ORDER BY MAX(spend) ASC
                    limit 2) 
group by category, product;
-- bài này em bị rối quá, em ko bị sai khúc nào rồi ạ

--baitap3
select COUNT(policy_holder_id) as member_count
from callers
GROUP BY policy_holder_id
HAVING count(policy_holder_id) >= 3;

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

--cho em hỏi là có cách nào extract được cả year và month cùng lúc được ko hay bắt buộc phải extract từng cái một rồi nối lại với nhau

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

--baitap11
WITH user_rating AS (
select u.user_id, u.name, count(mr.movie_id) as user_rate
from users u
left join movierating mr
on u.user_id = mr.user_id
group by u.user_id)
,
movie_rating AS (
select m.movie_id, m.title, avg(mr.rating) as avg_rate
from movies m
left join movierating mr
on m.movie_id = mr.movie_id
where created_at >= '2020-02-01' and created_at < '2020-03-01'
group by mr.movie_id)

--retrieve name of the user who has rated the greatest number of movies. In case of a tie, return the lexicographically smaller user name
select name
from user_rating
where user_rate = (select MAX(user_rate) from user_rating)
order by name ASC
limit 1;

--retrieve movie name with the highest average rating in February 2020. In case of a tie, return the lexicographically smaller movie name.
select title
from avg_rate
where avg_rate = (select MAX(avg_rate) from avg_rate)
order by title ASC
limit 1;

--> em ko biết kết hợp lại với nhau như thế nào :((

--baitap12
select a.accepter_id as id, count(*) as num
from RequestAccepted r
left join RequestAccepted a
on r.accepter_id = a.requester_id
where .....

--câu này em ko biết nên làm gì tiếp theo :(((

--baitap1
SELECT DISTINCT CITY 
FROM STATION
WHERE ID % 2 = 0;

--baitap2
select count(city) - count(distinct city) from STATION;

--baitap3


--baitap4
SELECT ROUND(CAST(SUM(item_count * order_occurances) / sum(order_occurances)DECIMAL),1) AS MEAN
FROM items_per_order;

--baitap5
select candidate_id
from candidates
where skill in ('Python','Tableau','PostgreSQL')
group by candidate_id
having count(skill) = 3;

--baitap6
select user_id, date(max(post_date)) - date(min(post_date)) as days_between
from posts
where post_date >= '2021-01-01' and post_date < '2022-01-01'
group by user_id
having count(post_id) >= 2;

--baitap7
select card_name, max(issued_amount) - min(issued_amount) as difference
from monthly_cards_issued
group by card_name
order by difference desc;

--baitap8
select manufacturer, count(drug) as drug_count, abs(sum(cogs-total_sales)) as total_loss
from pharmacy_sales
where total_sales < cogs
group by manufacturer
order by total_loss desc;

--baitap9
select * from Cinema
where id % 2 = 1 and description <> 'boring'
  order by rating desc;

--baitap10 
select teacher_id, count(distinct subject_id) as cnt
from teacher
group by teacher_id;

--baitap11
select user_id, count(follower_id) as followers_count
from Followers
group by user_id
order by user_id;

--baitap12
select class
from Courses
group by class
having count(student) >= 5;

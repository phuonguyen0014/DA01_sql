--baitap1
select Name from STUDENTS
where Marks >= 75
order by RIGHT(Name,3),ID asc;

--baitap2
select user_id, 
REPLACE(name,SUBSTRING(name from 1 for 1),UPPER(SUBSTRING(name from 1 for 1))) ||
REPLACE(name,SUBSTRING(name from 2),LOWER(SUBSTRING(name from 2))) as name
from Users
order by user_id;

--baitap3
SELECT manufacturer, '$' || CEILING(SUM(total_sales)) || ' million' AS sale
FROM pharmacy_sales
GROUP BY manufacturer
ORDER BY sale DESC, manufacturer;

--baitap4
SELECT EXTRACT(month FROM submit_date) AS month,
product_id AS product,
AVG(stars) AS avg_stars
FROM reviews
GROUP BY product_id;
-- got error: "column "reviews.submit_date" must appear in the GROUP BY clause or be used in an aggregate function"
-- em không hiểu tại sao phải GROUP BY cả "EXTRACT(month FROM submit_date)"

--baitap5
SELECT sender_id, COUNT(sender_id) AS message_count
FROM messages
WHERE EXTRACT(month from sent_date) = '8'
      AND EXTRACT(year from sent_date) = '2022'
GROUP BY sender_id
ORDER BY message_count DESC
LIMIT 2;

--baitap6
select tweet_id 
from Tweets
where length(content) > 15;

--baitap7
select distinct activity_date AS day, count(user_id) AS active_users
from Activity
where activity_date BETWEEN '2019-06-28' AND '2019-07-27'
group by activity_date;
-- em muốn hỏi ở bài 7 này, ngoài cách sử dụng BETWEEN AND ra, em có thể sử dụng 'mathematic operators' để làm được ko
-- ngoài ra, em chạy thử thì kết quả vẫn ko đúng, em bị sai ở chỗ nào ạ 

--baitap8
select count(id) as numEmployee
from employees
where joining_date between (extract(month from joining_date) = '1') and (extract(month from joining_date) = '7')
    and EXTRACT(year from joining_date) = '2022'
group by id;

--baitap9
select POSITION('a' in LOWER(first_name)) from worker
where first_name = 'Amitah';

--baitap10
select EXTRACT(year from title) as year
from winemag_p2
where country = 'Macedonia';

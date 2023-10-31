--baitap1
SELECT 
EXTRACT(year from transaction_date) as year,
product_id,
spend as curr_year_spend,
lag(spend) OVER(PARTITION BY product_id ORDER BY transaction_date) as prev_year_spend,
spend - lag(spend) OVER(PARTITION BY product_id ORDER BY transaction_date) as yoy_rate
FROM user_transactions;

--baiatap2
WITH ranked_firstm AS (
SELECT 
        card_name, 
        issue_month, 
        issue_year, 
        issued_amount,
        RANK() OVER(PARTITION BY card_name ORDER BY issue_month ASC) as rank
    FROM 
        monthly_cards_issued)
        
  SELECT card_name,
  issued_amount
  FROM ranked_firstm
  where rank = 1;

--baitap3
WITH ranked_third AS (
SELECT user_id, 
spend, 
transaction_date, 
RANK() OVER (PARTITION BY user_id ORDER BY transaction_date) AS rank
FROM transactions)

SELECT user_id, spend, transaction_date
FROM ranked_third
WHERE rank = 3;

--baitap4
with ranked_product as (
select product_id,
user_id,
spend,
transaction_date,
RANK() OVER(PARTITION BY user_id ORDER BY transaction_date ASC) as rank
from user_transactions 
)
-- group by user_id and sort through transaction_date and get the first rank
SELECT transaction_date,
user_id,
COUNT(product_id)
FROM ranked_product
WHERE rank = 1
GROUP BY user_id, transaction_date;

--baitap5
SELECT 
    user_id,
    tweet_date,
    ROUND(
        AVG(LAG(tweet_count,3) OVER (PARTITION BY user_id ORDER BY tweet_date)),2)
    AS rolling_avg_3d
FROM
    tweets;
-- em bị báo lỗi aggregate function calls cannot contain window function calls, nên em thử cách CTEs như dưới nhưng mà nó trả kết quả kì lắm :((

with ranked_count as (
SELECT
user_id,
tweet_date,
tweet_count,
lag(tweet_count,3) OVER(PARTITION BY user_id ORDER BY tweet_date ASC) as count
from tweets
)

SELECT
user_id,
tweet_date,
ROUND(AVG(tweet_count),2)
FROM ranked_count
GROUP BY user_id, tweet_date;

--baitap6
WITH time_diff_cte AS (
SELECT 
transaction_id,
merchant_id,
credit_card_id,
amount,
transaction_timestamp,
LAG(transaction_timestamp) OVER (
  PARTITION BY merchant_id, credit_card_id, amount 
  ORDER BY transaction_timestamp
) AS prev_transaction_timestamp
FROM transactions)
  
SELECT COUNT(DISTINCT transaction_id) AS payment_count
FROM time_diff_cte
WHERE ((transaction_timestamp - prev_transaction_timestamp) || ' minutes')  <= '10 minutes';

--baitap7
WITH product_spend_cte AS (
SELECT 
category,
product,
SUM(spend) AS total_spend
FROM product_spend
WHERE EXTRACT(year FROM transaction_date) = 2022
GROUP BY category, product)
,
ranked_products AS (
SELECT 
category,
product,
total_spend,
RANK() OVER (PARTITION BY category ORDER BY total_spend DESC) AS rank
FROM product_spend_cte)

SELECT 
category,
product,
total_spend
FROM ranked_products
WHERE rank <= 2;

--baitap8
WITH artist_songs AS (
SELECT a.artist_name, COUNT(*) AS appearances
FROM artists a
JOIN songs s 
ON a.artist_id = s.artist_id
JOIN global_song_rank g 
ON s.song_id = g.song_id
WHERE g.rank <= 10
GROUP BY a.artist_name
)

SELECT artist_name,
  DENSE_RANK() OVER (ORDER BY appearances DESC) AS artist_rank
FROM top_artist_songs
ORDER BY artist_rank
LIMIT 5;

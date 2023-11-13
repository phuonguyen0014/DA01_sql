--1. Thống kê tổng số lượng người mua và số lượng đơn hàng đã hoàn thành mỗi tháng
WITH MonthlyData AS (
    SELECT       
        FORMAT_DATE('%Y-%m', DATE (created_at)) as month_year,
        COUNT(DISTINCT order_id) AS total_order,
        COUNT(DISTINCT user_id) AS total_user
    FROM
        bigquery-public-data.thelook_ecommerce.orders
    WHERE
        status = 'Complete'
        AND created_at BETWEEN '2019-01-01' AND '2022-04-30'
    GROUP BY
        month_year
    ORDER BY
        month_year ASC
),
Trends AS (
    SELECT
        month_year,
        total_order,
        total_user,
        LAG(month_year) OVER (ORDER BY month_year) AS previous_month,
        LAG(total_order) OVER (ORDER BY month_year) AS previous_order,
        LAG(total_user) OVER (ORDER BY month_year) AS previous_user, 
        total_order - LAG(total_order) OVER (ORDER BY month_year) as diff_order,
        total_user - LAG(total_user) OVER (ORDER BY month_year) as diff_user                 
    FROM
        MonthlyData
)
SELECT * FROM Trends ORDER BY month_year;

--2. Thống kê giá trị đơn hàng trung bình và tổng số người dùng khác nhau mỗi tháng 
SELECT
    FORMAT_DATE('%Y-%m', DATE (o.created_at)) as month_year,
    COUNT(DISTINCT o.user_id) AS distinct_users,
    SUM(oi.sale_price) / COUNT(DISTINCT o.order_id) AS average_order_value
FROM
    bigquery-public-data.thelook_ecommerce.orders o
JOIN
    bigquery-public-data.thelook_ecommerce.order_items oi ON o.order_id = oi.order_id
WHERE
    o.created_at BETWEEN '2019-01-01' AND '2022-04-30'
    AND o.status = 'completed'
GROUP BY
    month_year
ORDER BY
    month_year ASC;

-- bài này em chạy nó ra kết quả "There is no data to display.", chị có thể xem giúp em bị sai ở đâu ko ạ?

--3. Nhóm khách hàng theo độ tuổi
WITH MinMaxAge AS (
    SELECT
        gender,
        MIN(age) AS youngest_age,
        MAX(age) AS oldest_age
    FROM
        bigquery-public-data.thelook_ecommerce.users
    WHERE
        created_at BETWEEN '2019-01-01' AND '2022-04-30'
    GROUP BY
        gender
)
,
Youngest AS (
    SELECT
        u.first_name,
        u.last_name,
        u.gender,
        u.age,
        'youngest' AS tag
    FROM
        bigquery-public-data.thelook_ecommerce.users u
    JOIN
        MinMaxAge ae ON u.gender = ae.gender AND u.age = ae.youngest_age
),
Oldest AS (
    SELECT
        u.first_name,
        u.last_name,
        u.gender,
        u.age,
        'oldest' AS tag
    FROM
        bigquery-public-data.thelook_ecommerce.users u
    JOIN
        MinMaxAge ae ON u.gender = ae.gender AND u.age = ae.oldest_age
)
,
Combined AS (  
SELECT * FROM Youngest
UNION ALL
SELECT * FROM Oldest
ORDER BY gender, tag DESC)

-- insight
SELECT
    tag,
    age,
    COUNT(*) AS count,    
FROM
    Combined
GROUP BY
    tag, age;

--4. Thống kê top 5 sản phẩm có lợi nhuận cao nhất từng tháng (xếp hạng cho từng sản phẩm). 
WITH monthly_sales AS (
    SELECT
        FORMAT_DATE('%Y-%m', DATE (created_at)) AS month_year,
        p.id AS product_id,
        p.name AS product_name,
        SUM(oi.sale_price) AS sales,
        SUM(p.cost) AS cost,
        SUM(oi.sale_price) - SUM(p.cost) AS profit
    FROM
        bigquery-public-data.thelook_ecommerce.order_items oi
    JOIN
        bigquery-public-data.thelook_ecommerce.products p ON oi.product_id = p.id
    GROUP BY
        month_year, product_id, product_name
)
SELECT
    *,
    DENSE_RANK() OVER (PARTITION BY month_year ORDER BY profit DESC) AS rank_per_month
FROM
    monthly_sales
LIMIT 5;

--5. Thống kê tổng doanh thu theo ngày của từng danh mục sản phẩm (category) trong 3 tháng qua ( giả sử ngày hiện tại là 15/4/2022)
SELECT
    DATE(oi.created_at) AS dates,
    p.category AS product_categories,
    SUM(oi.sale_price) AS revenue
FROM
    bigquery-public-data.thelook_ecommerce.order_items oi
JOIN
    bigquery-public-data.thelook_ecommerce.products p ON oi.product_id = p.id
WHERE
    oi.created_at BETWEEN '2022-01-15' AND '2022-04-15'
GROUP BY
    dates, product_categories
ORDER BY
    dates, product_categories;



--III. Tạo metric trước khi dựng dashboard
-- 1
WITH dataset_table AS (
    SELECT 
        FORMAT_DATE('%Y-%m', DATE (o.created_at)) AS Month,
        EXTRACT(YEAR FROM o.created_at) AS Year,
        p.category AS Product_category,
        SUM(oi.sale_price) AS TPV,
        COUNT(DISTINCT o.order_id) AS TPO,
        
        -- Previous month's revenue
        LAG(SUM(oi.sale_price)) OVER (PARTITION BY p.category ORDER BY FORMAT_DATE('%Y-%m', DATE (o.created_at))) AS previous_month_re,
        -- Revenue growth
        (SUM(oi.sale_price) - LAG(SUM(oi.sale_price)) OVER (PARTITION BY p.category ORDER BY FORMAT_DATE('%Y-%m', DATE (o.created_at)))) 
        / LAG(SUM(oi.sale_price)) OVER (PARTITION BY p.category ORDER BY FORMAT_DATE('%Y-%m', DATE (o.created_at))) * 100 AS Revenue_growth,
        
        -- Previous month's order count
        LAG(COUNT(DISTINCT o.order_id)) OVER (PARTITION BY p.category ORDER BY FORMAT_DATE('%Y-%m', DATE (o.created_at))) AS previous_month_order,
        -- Order growth
        (COUNT(DISTINCT o.order_id) - LAG(COUNT(DISTINCT o.order_id)) OVER (PARTITION BY p.category ORDER BY FORMAT_DATE('%Y-%m', DATE (o.created_at))))
        / LAG(COUNT(DISTINCT o.order_id)) OVER (PARTITION BY p.category ORDER BY FORMAT_DATE('%Y-%m', DATE (o.created_at))) * 100 AS Order_growth,
        
        -- Total cost and profit calculations
        SUM(p.cost) AS Total_cost,
        SUM(oi.sale_price) - SUM(p.cost) AS Total_profit,
        (SUM(oi.sale_price) - SUM(p.cost)) / NULLIF(SUM(p.cost), 0) * 100 AS Profit_to_cost_ratio
        
    FROM 
        bigquery-public-data.thelook_ecommerce.orders o
    JOIN 
        bigquery-public-data.thelook_ecommerce.order_items oi ON o.order_id = oi.order_id
    JOIN 
        bigquery-public-data.thelook_ecommerce.products p ON p.id = oi.product_id
    GROUP BY 
        1, 2, 3)

CREATE VIEW vw_ecommerce_analyst AS
SELECT 
    Month, 
    Year, 
    Product_category, 
    TPV, 
    TPO, 
    Revenue_growth, 
    Order_growth, 
    Total_cost, 
    Total_profit, 
    Profit_to_cost_ratio
FROM 
    dataset_table;

-- Em bị lỗi "Window ORDER BY expression references o.created_at which is neither grouped nor aggregated at" ở dòng 158, em ko hiểu sao bị lỗi trong khi em đã Group nó rồi

-- 2. Tạo retention cohort analysis.
WITH FirstPurchase AS (
    SELECT 
        user_id,
        TO_CHAR(first_purchase_date, 'yyyy-mm') AS cohort_date,
        created_at,
        (EXTRACT(YEAR FROM created_at) - EXTRACT(YEAR FROM first_purchase_date)) * 12 +
        (EXTRACT(MONTH FROM created_at) - EXTRACT(MONTH FROM first_purchase_date)) + 1 AS index
    FROM (
        SELECT 
            user_id, 
            MIN(created_at) OVER (PARTITION BY user_id) AS first_purchase_date,
            created_at
        FROM 
            bigquery-public-data.thelook_ecommerce.order_items 
    ) a
),
CohortCounts AS (
    SELECT 
        cohort_date, 
        index,
        COUNT(DISTINCT user_id) AS cnt
    FROM 
        FirstPurchase
    GROUP BY 
        cohort_date, 
        index
),

-- Customer Cohort
CustomerCohort AS (
    SELECT 
        cohort_date,
        SUM(CASE WHEN index = 1 THEN cnt ELSE 0 END) AS m1,
        SUM(CASE WHEN index = 2 THEN cnt ELSE 0 END) AS m2,
        SUM(CASE WHEN index = 3 THEN cnt ELSE 0 END) AS m3,
        SUM(CASE WHEN index = 4 THEN cnt ELSE 0 END) AS m4
    FROM 
        CohortCounts
    GROUP BY 
        cohort_date
    ORDER BY 
        cohort_date
),

-- Retention Cohort
RetentionCohort AS (
    SELECT
        cohort_date,
        ROUND(100.00 * m1 / m1,2) || '%' AS m1,
        ROUND(100.00 * m2 / m1,2) || '%' AS m2,
        ROUND(100.00 * m3 / m1,2) || '%' AS m3,
        ROUND(100.00 * m4 / m1,2) || '%' AS m4
    FROM 
        CustomerCohort
),

-- Churn Cohort
ChurnCohort AS (
    SELECT
        cohort_date,
        (100 - ROUND(100.00 * m1 / m1,2) || '%' AS m1,
        (100 - ROUND(100.00 * m2 / m1,2) || '%' AS m2,
        (100 - ROUND(100.00 * m3 / m1,2) || '%' AS m3,
        (100 - ROUND(100.00 * m4 / m1,2) || '%' AS m4
    FROM 
        RetentionCohort
)

SELECT * FROM CustomerCohort;


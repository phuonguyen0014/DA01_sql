--1. Thống kê tổng số lượng người mua và số lượng đơn hàng đã hoàn thành mỗi tháng
SELECT
    COUNT(DISTINCT o.order_id) AS total_order,
    COUNT(DISTINCT u.id) AS total_user,
    TO_CHAR(o.created_at, 'yyyy-mm') AS month_year
FROM
    bigquery-public-data.thelook_ecommerce.orders o
JOIN
    bigquery-public-data.thelook_ecommerce.users u ON o.user_id = u.id
WHERE
    o.status = 'Complete'
    AND o.created_at BETWEEN '2019-01-01' AND '2022-04-01'
GROUP BY
    month_year
ORDER BY
    month_year ASC;

--2. Thống kê giá trị đơn hàng trung bình và tổng số người dùng khác nhau mỗi tháng 
SELECT
    TO_CHAR(o.created_at, 'YYYY-MM') AS month_year,
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

--3. Nhóm khách hàng theo độ tuổi
WITH youngest AS (
    SELECT
        id, first_name, last_name, gender, MIN(age) AS min_age, 'youngest' AS tag
    FROM
        bigquery-public-data.thelook_ecommerce.users
    WHERE
        created_at BETWEEN '2019-01-01' AND '2022-04-30'
    GROUP BY
        gender
),
oldest AS (
    SELECT
        id, first_name, last_name, gender, MAX(age) AS max_age, 'oldest' AS tag
    FROM
        bigquery-public-data.thelook_ecommerce.users
    WHERE
        created_at BETWEEN '2019-01-01' AND '2022-04-30'
    GROUP BY
        gender
),
combined AS (  
SELECT
    u.first_name, u.last_name, u.gender, u.age, y.tag
FROM
    bigquery-public-data.thelook_ecommerce.users u
JOIN
    youngest y ON u.id = y.id AND u.age = y.min_age
UNION ALL
SELECT
    u.first_name, u.last_name, u.gender, u.age, o.tag
FROM
    bigquery-public-data.thelook_ecommerce.users u
JOIN
    oldest o ON u.id = o.id AND u.age = o.max_age
ORDER BY
    gender, tag DESC;)

-- insight
SELECT
    tag,
    gender,
    COUNT(*) AS count,
    AVG(age) AS average_age
FROM
    Combined
GROUP BY
    tag, gender;

--4. Thống kê top 5 sản phẩm có lợi nhuận cao nhất từng tháng (xếp hạng cho từng sản phẩm). 
WITH monthly_sales AS (
    SELECT
        TO_CHAR(oi.created_at, 'YYYY-MM') AS month_year,
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
WHERE
    rank_per_month <= 5;

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
    oi.created_at >= '2022-01-15'
    AND oi.created_at <= '2022-04-15'
GROUP BY
    dates, product_categories
ORDER BY
    dates, product_categories;



--III. Tạo metric trước khi dựng dashboard
-- 1
WITH dataset_table AS (
    SELECT 
        TO_CHAR(o.created_at, 'yyyy-mm') AS Month,
        EXTRACT(YEAR FROM o.created_at) AS Year,
        p.category AS Product_category,
        SUM(oi.sale_price) AS TPV,
        COUNT(DISTINCT o.id) AS TPO,
        
        -- Previous month's revenue
        LAG(SUM(oi.sale_price), 1) OVER (PARTITION BY p.category ORDER BY TO_CHAR(o.created_at, 'yyyy-mm')) AS previous_month_re,
        -- Revenue growth
        (SUM(oi.sale_price) - LAG(SUM(oi.sale_price), 1) OVER (PARTITION BY p.category ORDER BY TO_CHAR(o.created_at, 'yyyy-mm'))) 
        / NULLIF(LAG(SUM(oi.sale_price), 1) OVER (PARTITION BY p.category ORDER BY TO_CHAR(o.created_at, 'yyyy-mm')), 0) * 100 AS Revenue_growth,
        
        -- Previous month's order count
        LAG(COUNT(DISTINCT o.id), 1) OVER (PARTITION BY p.category ORDER BY TO_CHAR(o.created_at, 'yyyy-mm')) AS previous_month_order,
        -- Order growth
        (COUNT(DISTINCT o.id) - LAG(COUNT(DISTINCT o.id), 1) OVER (PARTITION BY p.category ORDER BY TO_CHAR(o.created_at, 'yyyy-mm')))
        / NULLIF(LAG(COUNT(DISTINCT o.id), 1) OVER (PARTITION BY p.category ORDER BY TO_CHAR(o.created_at, 'yyyy-mm')), 0) * 100 AS Order_growth,
        
        -- Total cost and profit calculations
        SUM(p.cost) AS Total_cost,
        SUM(oi.sale_price) - SUM(p.cost) AS Total_profit,
        (SUM(oi.sale_price) - SUM(p.cost)) / NULLIF(SUM(p.cost), 0) * 100 AS Profit_to_cost_ratio
        
    FROM 
        orders o
    JOIN 
        order_items oi ON o.id = oi.order_id
    JOIN 
        products p ON p.id = oi.product_id
    GROUP BY 
        TO_CHAR(o.created_at, 'yyyy-mm'), EXTRACT(YEAR FROM o.created_at), p.category
)

-- Create the view
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
            orders_item 
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


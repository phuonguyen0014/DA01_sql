drop table SALES_DATASET_RFM_PRJ;

select * from SALES_DATASET_RFM_PRJ;

create table SALES_DATASET_RFM_PRJ
(
  ordernumber VARCHAR,
  quantityordered VARCHAR,
  priceeach        VARCHAR,
  orderlinenumber  VARCHAR,
  sales            VARCHAR,
  orderdate        VARCHAR,
  status           VARCHAR,
  productline      VARCHAR,
  msrp             VARCHAR,
  productcode      VARCHAR,
  customername     VARCHAR,
  phone            VARCHAR,
  addressline1     VARCHAR,
  addressline2     VARCHAR,
  city             VARCHAR,
  state            VARCHAR,
  postalcode       VARCHAR,
  country          VARCHAR,
  territory        VARCHAR,
  contactfullname  VARCHAR,
  dealsize         VARCHAR
)

-- 1.Chuyển đổi kiểu dữ liệu phù hợp cho các trường ( sử dụng câu lệnh ALTER) 
--- ordernumber, quantityordered, orderlinenumber
ALTER TABLE SALES_DATASET_RFM_PRJ 
ALTER COLUMN ordernumber TYPE int USING ordernumber::integer,
ALTER COLUMN quantityordered TYPE int USING quantityordered::integer,
ALTER COLUMN orderlinenumber TYPE int USING orderlinenumber::integer,
ALTER COLUMN msrp TYPE int USING msrp::integer,
ALTER COLUMN priceeach TYPE numeric USING priceeach::numeric,
ALTER COLUMN sales TYPE numeric USING sales::numeric,
ALTER COLUMN orderdate TYPE timestamp USING orderdate::timestamp,
ALTER COLUMN phone TYPE text USING phone::text;


-- 2.Check NULL/BLANK (‘’)  ở các trường: ORDERNUMBER, QUANTITYORDERED, PRICEEACH, ORDERLINENUMBER, SALES, ORDERDATE.
SELECT *
FROM SALES_DATASET_RFM_PRJ
WHERE ORDERNUMBER IS NULL OR 
      QUANTITYORDERED IS NULL OR 
      PRICEEACH IS NULL OR 
      ORDERLINENUMBER IS NULL OR 
      SALES IS NULL OR 
      ORDERDATE IS NULL;


-- 3.Thêm cột CONTACTLASTNAME, CONTACTFIRSTNAME được tách ra từ CONTACTFULLNAME .
-- Chuẩn hóa CONTACTLASTNAME, CONTACTFIRSTNAME theo định dạng chữ cái đầu tiên viết hoa, chữ cái tiếp theo viết thường. 
-- Gợi ý: ( ADD column sau đó INSERT)

--- Cách 1: 
-- Bước 1: Sử dụng câu lệnh ALTER TABLE để thêm cột mới CONTACTLASTNAME và CONTACTFIRSTNAME
ALTER TABLE SALES_DATASET_RFM_PRJ
ADD COLUMN CONTACTLASTNAME VARCHAR,
ADD COLUMN CONTACTFIRSTNAME VARCHAR;

-- Bước 2: Tạo CTEs để trích xuất họ và tên từ cột CONTACTFULLNAME
-- INITCAP() function: ensure that the first letter of each name is capitalized, and the rest of the letters are in lowercase
WITH name_parts AS (
SELECT 
CONTACTFULLNAME,	
INITCAP(substring(CONTACTFULLNAME from 1 for (position('-' in CONTACTFULLNAME) - 1 ))) as first_name,
INITCAP(substring(CONTACTFULLNAME from position('-' in CONTACTFULLNAME) + 1)) as last_name
from SALES_DATASET_RFM_PRJ)

-- Bước 3: Sử dụng INSERT INTO (thêm dòng mới) để chèn giá trị vừa trích xuất vào cột mới (nhưng em bi lỗi)
/* INSERT INTO - bị lỗi vì thêm dòng mới, phải dùng UPDATE
INSERT INTO SALES_DATASET_RFM_PRJ(CONTACTFIRSTNAME, CONTACTLASTNAME)
VALUES (SELECT first_name, last_name
FROM name_parts);
*/
UPDATE SALES_DATASET_RFM_PRJ AS s
SET CONTACTFIRSTNAME = n.first_name,
	CONTACTLASTNAME = n.last_name
FROM name_parts AS n
WHERE s.CONTACTFULLNAME = n.CONTACTFULLNAME;

--- Cách 2:
update public.sales_dataset_rfm_prj
set contactlastname = left(contactfullname,position('-'in contactfullname)-1),
set contactfirstname = right(contactfullname,length (contactfullname)- position('-'in contactfullname))
-------------------------------4----------------------------------------------------------------  
update public.sales_dataset_rfm_prj 
set contactfirstname = INITCAP(contactfirstname);
update public.sales_dataset_rfm_prj 
set contactfirstname = INITCAP(contactfirstname)


-- 4.Thêm cột QTR_ID, MONTH_ID, YEAR_ID lần lượt là Qúy, tháng, năm được lấy ra từ ORDERDATE
-- Bước 1: Sử dụng câu lệnh ALTER TABLE để thêm cột mới QTR_ID, MONTH_ID, YEAR_ID
ALTER TABLE SALES_DATASET_RFM_PRJ
ADD COLUMN QTR_ID INTEGER,
ADD COLUMN MONTH_ID INTEGER,
ADD COLUMN YEAR_ID INTEGER;

-- Bước 2: Tạo CTEs để lấy Qúy, tháng, năm từ cột ORDERDATE
WITH dates AS (
SELECT
ORDERDATE,	
EXTRACT (QUARTER FROM ORDERDATE) AS qtrid,
EXTRACT (MONTH FROM ORDERDATE) AS monthid,	
EXTRACT (YEAR FROM ORDERDATE) AS yearid
FROM SALES_DATASET_RFM_PRJ
)

-- Bước 3: Sử dụng UPDATE để chèn giá trị vừa trích xuất vào dòng cũ trong cột mới
UPDATE SALES_DATASET_RFM_PRJ AS s
SET QTR_ID = d.qtrid,
	MONTH_ID = d.monthid,
	YEAR_ID = d.yearid
FROM dates AS d
WHERE s.ORDERDATE = d.ORDERDATE;


-- 5.Hãy tìm outlier (nếu có) cho cột QUANTITYORDERED và hãy chọn cách xử lý cho bản ghi đó (2 cách) 
--( Không chạy câu lệnh trước khi bài được review)
---Boxplot
-- B1: Tính Q1, Q3, IQR
-- B2: Xác định MIN = Q1 - 1.5 * IQR; Xách định MAX = Q3 + 1.5 * IQR
WITH min_max_value AS (
SELECT Q1 - 1.5 * IQR AS min
		Q3 + 1.5 * IQR AS max
FROM
(SELECT 
PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY QUANTITYORDERED) AS Q1,
PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY QUANTITYORDERED) AS Q3,
PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY QUANTITYORDERED) - PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY QUANTITYORDERED) AS IQR
FROM SALES_DATASET_RFM_PRJ) AS B1 )

-- B3: Xác định OUTLIER < min or > max
SELECT * FROM SALES_DATASET_RFM_PRJ
WHERE QUANTITYORDERED < (SELECT min FROM min_max_value)
OR QUANTITYORDERED > (SELECT max FROM min_max_value);

---Z-Score = (QUANTITYORDERED - avg) / stddev
-- B1: Tính AVG và STDDEV
SELECT AVG(QUANTITYORDERED),
STDDEV(QUANTITYORDERED)
FROM SALES_DATASET_RFM_PRJ;

-- B2: Lắp ghép output
SELECT QUANTITYORDERED, 
(SELECT AVG(QUANTITYORDERED) FROM SALES_DATASET_RFM_PRJ) AS avg,
(SELECT STDDEV(QUANTITYORDERED) FROM SALES_DATASET_RFM_PRJ) AS stddev
FROM SALES_DATASET_RFM_PRJ

-- B3: Tính Z-Score
WITH cte AS (
SELECT QUANTITYORDERED, 
(SELECT AVG(QUANTITYORDERED) FROM SALES_DATASET_RFM_PRJ) AS avg,
(SELECT STDDEV(QUANTITYORDERED) FROM SALES_DATASET_RFM_PRJ) AS stddev
FROM SALES_DATASET_RFM_PRJ)

-- ABS: giá trị tuyệt đối
SELECT QUANTITYORDERED,
(QUANTITYORDERED - avg)/stddev AS z_score
FROM cte
WHERE ABS((QUANTITYORDERED - avg)/stddev) > 3


-- 6.Sau khi làm sạch dữ liệu, hãy lưu vào bảng mới tên là SALES_DATASET_RFM_PRJ_CLEAN
WITH cte AS (
SELECT QUANTITYORDERED, 
(SELECT AVG(QUANTITYORDERED) FROM SALES_DATASET_RFM_PRJ) AS avg,
(SELECT STDDEV(QUANTITYORDERED) FROM SALES_DATASET_RFM_PRJ) AS stddev
FROM SALES_DATASET_RFM_PRJ)
, outlier AS (
-- ABS: giá trị tuyệt đối
SELECT QUANTITYORDERED,
(QUANTITYORDERED - avg)/stddev AS z_score
FROM cte
WHERE ABS((QUANTITYORDERED - avg)/stddev) > 3)

DELETE FROM SALES_DATASET_RFM_PRJ
WHERE QUANTITYORDERED IN (SELECT QUANTITYORDERED FROM outlier);

CREATE TABLE SALES_DATASET_RFM_PRJ_CLEAN AS
SELECT *
FROM SALES_DATASET_RFM_PRJ;

-- Q1: Tổng số đơn hàng năm 2020
select count(distinct rs.order_number) as order_num
from retails.sales rs
where year(rs.order_date) = 2020;

-- Q2: Liệt kê category sản phẩm 
---(toàn bộ category sản phẩm mình đang bán, kèm số SKU trong mỗi category, sx theo alphabet)

select rp.category, count(rp.product_key) as SKU
from retails.products rp
group by rp.category
order by rp.category asc;

-- Q3: Top 10 thành phố có nhiều khách nhất
---tên city, state, country, và số lượng customer.

select top 10 rc.city, rc.state, rc.country,
count(rc.customer_key) as customer_num
from retails.customers rc
group by rc.city, rc.state, rc.country
order by customer_num desc, rc.city;

-- Q4: Doanh thu tháng 12/2020
select sum(rs.quantity * rp.unit_price_usd) as revenue
from retails.sales rs
inner join retails.products rp on rs.product_key = rp.product_key
where YEAR(rs.order_date) = 2020 
AND MONTH(rs.order_date) = 12;

-- Q5: Số lượng store theo quốc gia
--Bảng gồm country + số store. Sắp theo số store giảm dần

select rs.country, count(rs.store_key) as store_num
from retails.stores rs
group by rs.country
order by store_num desc;

-- Q6: Top 5 sản phẩm bán chạy nhất mỗi category
---Output 1 bảng: mỗi dòng 1 sản phẩm, có category, tên sản phẩm, tổng lượng bán, và thứ hạng (1-5) trong category đó.
with CTE1 AS (select rp.category, rp.product_name, 
sum(rs.quantity) as sales_num
from retails.sales rs 
inner join retails.products rp on rs.product_key = rp.product_key
group by rp.category, rp.product_name),

CTE2 as (
select CTE1.*,
ROW_NUMBER() OVER(PARTITION BY CTE1.category ORDER BY CTE1.sales_num DESC , CTE1.product_name asc) as product_category_rank
from CTE1)

select CTE2.* 
from CTE2 
WHERE CTE2.product_category_rank <= 5;

-- Q7: Margin gross theo subcategory
---không inner join theo sales làm gì nữa cả
---margin gross trung bình của từng subcategory để đánh giá pricing strategy. Margin % = (giá bán − giá vốn) / giá bán. 
--Chỉ xét subcategory có ít nhất 10 sản phẩm để số có ý nghĩa. Sắp theo margin giảm dần.

select rp.subcategory,
ROUND(AVG((rp.unit_price_usd - rp.unit_cost_usd) * 100.0/ NULLIF(rp.unit_price_usd,0)),2) as avg_margin_pct
from retails.products rp
group by rp.subcategory
having count(rp.product_key) >= 10
order by avg_margin_pct desc

-- Q8: Thời gian giao hàng trung bình theo quốc gia
---chỉ những đơn có phát sinh giao hàng tới tay khách mới có ngày giao - đơn mua trực tiếp tại cửa hàng thì không. Với nhóm đơn có giao đó, trung bình từ lúc khách đặt đến lúc nhận hàng là bao nhiêu ngày, tính theo từng quốc gia của khách? 
---Gửi anh: tên nước, số đơn có giao, số ngày trung bình - sắp theo số ngày trung bình giảm dần để anh thấy nước nào đang giao chậm nhất.
--- số đơn có giao là order_number

WITH delivered AS (
  SELECT DISTINCT
    s.order_number,
    s.customer_key,
    s.order_date,
    s.delivery_date
  FROM retails.sales AS s
  WHERE s.delivery_date IS NOT NULL
)
SELECT
  c.country,
  COUNT(*) AS delivered_orders,
  CAST(
    AVG(CAST(DATEDIFF(DAY, d.order_date, d.delivery_date) AS DECIMAL(10, 2)))
    AS DECIMAL(10, 2)
  ) AS avg_delivery_days
FROM delivered AS d
JOIN retails.customers AS c
  ON c.customer_key = d.customer_key
GROUP BY c.country
ORDER BY avg_delivery_days DESC;

-- Q9: Khách VIP mỗi quốc gia
---1 khách hàng chi tiêu nhiều nhất trong năm 2020. Output: country, tên khách, tổng chi tiêu 2020.
with CTE1 AS (
select rc.customer_key,
SUM(rp.unit_price_usd * rs.quantity) as total_spent
from retails.sales rs 
inner join retails.products rp on rs.product_key = rp.product_key
inner join retails.customers rc on rs.customer_key= rc.customer_key
where YEAR(rs.order_date) = 2020
group by rc.customer_key),

CTE2 AS (
select CTE1.*, rc.country, rc.name as customer_name,
ROW_NUMBER() OVER(PARTITION BY rc.country ORDER BY CTE1.total_spent DESC) as spent_ranking
from CTE1
inner join retails.customers rc on CTE1.customer_key = rc.customer_key)

select CTE2.country, CTE2.customer_name, CTE2.total_spent as total_spent_2020
from CTE2
where CTE2.spent_ranking = 1
order by total_spent_2020 desc;

-- Q10: Sản phẩm zombie (chưa từng bán)
---sản phẩm nằm trong catalog nhưng chưa từng bán được cái nào - zombie inventory. 
---Gửi anh: mã sản phẩm, tên sản phẩm, brand, category.

select rp.product_key, rp.product_name, rp.brand, rp.category
from retails.products rp
where rp.product_key not in (select distinct rs.product_key
                              from retails.sales rs)

-- Q11: Doanh thu tháng + doanh thu tích luỹ 24 tháng
---doanh thu từng tháng + doanh thu tích luỹ từ đầu period 24 tháng gần nhất. 
---Tháng-doanh thu để nhìn trend, tích luỹ để nhìn scale. Xuất 1 bảng: year_month, doanh thu tháng đó, doanh thu cộng dồn.
-- 2019-02 to 2021-02
WITH max_date AS (
    -- Bước 1: Tìm ngày đầu tiên của tháng mới nhất trong bảng dữ liệu
    SELECT 
        DATEADD(month, DATEDIFF(month, 0, MAX(order_date)), 0) AS max_month_start 
    FROM retails.sales
),
sales_with_revenue AS (
    -- Bước 2: Tính doanh thu cho từng đơn hàng và lọc 24 tháng gần nhất
    SELECT 
        DATEADD(month, DATEDIFF(month, 0, s.order_date), 0) AS month_start,
        FORMAT(s.order_date, 'yyyy-MM') AS year_month,
        s.quantity * p.unit_price_usd AS item_revenue
    FROM retails.sales s
    INNER JOIN retails.products p 
        ON s.product_key = p.product_key
    CROSS JOIN max_date m
    WHERE s.order_date >= DATEADD(month, -23, m.max_month_start)
),
monthly_data AS (
    -- Bước 3: Gom nhóm và tính tổng doanh thu theo từng tháng
    SELECT 
        year_month,
        month_start,
        SUM(item_revenue) AS monthly_revenue
    FROM sales_with_revenue
    GROUP BY 
        year_month, 
        month_start
)
-- Bước 4: Tính doanh thu cộng dồn từ tháng đầu tiên của chu kỳ 24 tháng
SELECT 
    year_month,
    CAST(monthly_revenue AS DECIMAL(18, 2)) AS monthly_revenue,
    CAST(SUM(monthly_revenue) OVER (ORDER BY month_start ASC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS DECIMAL(18, 2)) AS cumulative_revenue
FROM monthly_data
ORDER BY month_start ASC;

-- Q12: Cohort retention theo năm mua đầu tiên
--Bài cohort nào cũng gồm đúng ba mảnh, và viết tách ra thành ba CTE thì dễ kiểm từng mảnh hơn nhiều so với nhồi vào một câu:

---Mỗi khách thuộc cohort nào - năm của lần mua đầu tiên.
---Cohort đó to bằng nào - mẫu số, phải tính một lần trên toàn cohort, không phụ thuộc năm đang xét.
---Năm sau đó ai còn hoạt động - tử số.

--- Cách 1:
WITH CustomerCohort AS (
    -- Bước 1: Xác định năm đầu tiên mua hàng của mỗi khách hàng
    SELECT 
        customer_key,
        MIN(YEAR(order_date)) AS cohort_year
    FROM retails.sales
    GROUP BY customer_key
),

CustomerActivity AS (
    -- Bước 2: Lấy các năm giao dịch của khách hàng và tính khoảng cách năm (year_number)
    SELECT DISTINCT
        c.customer_key,
        c.cohort_year,
        YEAR(s.order_date) - c.cohort_year AS year_number
    FROM CustomerCohort c
    JOIN retails.sales s ON c.customer_key = s.customer_key
),

CohortSize AS (
    -- Bước 3: Đếm tổng số khách hàng ban đầu của mỗi Cohort (Year 0)
    SELECT 
        cohort_year,
        COUNT(DISTINCT customer_key) AS total_customers
    FROM CustomerCohort
    GROUP BY cohort_year
),

CohortRetention AS (
    -- Bước 4: Đếm số lượng khách hàng quay lại theo từng year_number
    SELECT 
        a.cohort_year,
        s.total_customers,
        a.year_number,
        COUNT(DISTINCT a.customer_key) AS retained_customers
    FROM CustomerActivity a
    JOIN CohortSize s ON a.cohort_year = s.cohort_year
    GROUP BY a.cohort_year, s.total_customers, a.year_number
)

-- Bước 5: Pivot dữ liệu ra bảng Full Cohort Retention (%)
SELECT 
    cohort_year,
    total_customers AS cohort_size,
    -- Retention % cho từng năm
    ROUND(100.0 * MAX(CASE WHEN year_number = 0 THEN retained_customers ELSE 0 END) / total_customers, 2) AS [Year 0],
    ROUND(100.0 * MAX(CASE WHEN year_number = 1 THEN retained_customers ELSE 0 END) / total_customers, 2) AS [Year 1],
    ROUND(100.0 * MAX(CASE WHEN year_number = 2 THEN retained_customers ELSE 0 END) / total_customers, 2) AS [Year 2],
    ROUND(100.0 * MAX(CASE WHEN year_number = 3 THEN retained_customers ELSE 0 END) / total_customers, 2) AS [Year 3]
FROM CohortRetention
GROUP BY cohort_year, total_customers
ORDER BY cohort_year ASC;


----Cách 2:
WITH CustomerCohort AS (
    -- Quét bảng sales LẦN 1: Xác định năm mua đầu tiên của từng khách hàng
    SELECT 
        customer_key,
        MIN(YEAR(order_date)) AS first_year
    FROM retails.sales
    GROUP BY customer_key
),

CustomerOrders AS (
    -- Quét bảng sales LẦN 2: Ghép năm mua đầu với các năm có phát sinh giao dịch
    SELECT DISTINCT
        c.customer_key,
        c.first_year,
        YEAR(s.order_date) AS order_year
    FROM CustomerCohort c
    INNER JOIN retails.sales s ON c.customer_key = s.customer_key
)

-- Gom nhóm và tính toán trực tiếp bằng CASE WHEN (Không bị nhân bản dòng)
SELECT 
    first_year AS cohort_year,
    COUNT(DISTINCT customer_key) AS cohort_size,
    
    100.0 AS [Year 0 (%)],
    
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN order_year = first_year + 1 THEN customer_key END) 
          / COUNT(DISTINCT customer_key), 2) AS [Year 1 (%)],
          
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN order_year = first_year + 2 THEN customer_key END) 
          / COUNT(DISTINCT customer_key), 2) AS [Year 2 (%)],
          
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN order_year = first_year + 3 THEN customer_key END) 
          / COUNT(DISTINCT customer_key), 2) AS [Year 3 (%)]

FROM CustomerOrders
GROUP BY first_year
ORDER BY first_year ASC;



-- Q13: Doanh thu/m² store, xếp hạng trong nước
--- doanh thu trên mỗi mét vuông của từng store (năm 2020) để so sánh hiệu quả sử dụng diện tích. 
---Sau đó xếp hạng 4 nhóm (quartile) trong cùng quốc gia - store nào top 25%, store nào bottom 25%. 
---Xuất: store_key, country, doanh thu/m², quartile trong nước
with CTE1 as (
select rs.store_key, 
s.country as store_country,
SUM(rs.quantity * rp.unit_price_usd) as revenue
from retails.sales rs
inner join retails.products rp on rs.product_key = rp.product_key
inner join retails.stores s on rs.store_key = s.store_key
where YEAR(rs.order_date) = 2020
group by rs.store_key, s.country)

select CTE1.*, 
CTE1.revenue/ rs.square_meters as revenue_per_m2,
NTILE(4) OVER(PARTITION BY CTE1.store_country ORDER BY CTE1.revenue/ rs.square_meters desc) as quartile_in_country
from CTE1
inner join retails.stores rs on CTE1.store_key = rs.store_key
where rs.square_meters is not null
order by CTE1.store_country asc, revenue_per_m2 desc;

-- Q14: Store cannibalization
---Với từng cặp (store cũ, store mới mở sau), so sánh doanh thu của store cũ trong 6 tháng trước ngày store mới mở với 6 tháng sau ngày đó. 
---Nếu doanh thu sau giảm hơn 15% → flag là bị ăn thịt. Gửi anh: store cũ, store mới, nước, ngày mở, doanh thu hai kỳ và % sụt giảm.

WITH store_pairs AS (
    -- Bước 1: Ghép cặp store cũ và store mới thuộc cùng một quốc gia
    SELECT 
        old_s.store_key AS old_store_id,
        new_s.store_key AS new_store_id,
        new_s.country,
        new_s.open_date AS new_store_opening_date,
        -- Tạo khung thời gian 6 tháng trước và 6 tháng sau ngày mở store mới
        DATEADD(month, -6, new_s.open_date) AS pre_start,
        DATEADD(month, 6, new_s.open_date) AS post_end
    FROM retails.stores old_s
    INNER JOIN retails.stores new_s 
        ON old_s.country = new_s.country 
       AND old_s.store_key <> new_s.store_key
       AND old_s.open_date < new_s.open_date
),
sales_with_revenue AS (
    -- Bước 2: Tính sẵn doanh thu từng dòng bán hàng bằng cách JOIN sales với products
    SELECT 
        s.store_key,
        s.order_date,
        CAST(s.quantity * p.unit_price_usd AS DECIMAL(18, 2)) AS item_revenue
    FROM retails.sales s
    INNER JOIN retails.products p 
        ON s.product_key = p.product_key
),
revenue_comparison AS (
    -- Bước 3: So sánh doanh thu store cũ ở 2 kỳ (6 tháng trước vs 6 tháng sau)
    SELECT 
        p.old_store_id,
        p.new_store_id,
        p.country,
        p.new_store_opening_date,
        ISNULL(SUM(CASE 
            WHEN sr.order_date >= p.pre_start AND sr.order_date < p.new_store_opening_date 
            THEN sr.item_revenue 
            ELSE 0 
        END), 0) AS rev_before,
        ISNULL(SUM(CASE 
            WHEN sr.order_date >= p.new_store_opening_date AND sr.order_date <= p.post_end 
            THEN sr.item_revenue 
            ELSE 0 
        END), 0) AS rev_after
    FROM store_pairs p
    LEFT JOIN sales_with_revenue sr 
        ON sr.store_key = p.old_store_id
       AND sr.order_date >= p.pre_start 
       AND sr.order_date <= p.post_end
    GROUP BY 
        p.old_store_id, 
        p.new_store_id, 
        p.country, 
        p.new_store_opening_date
)
-- Bước 4: Lọc danh sách store bị ăn thịt thị trường (sụt giảm > 15%)
SELECT 
    old_store_id,
    new_store_id,
    country,
    CONVERT(VARCHAR(10), new_store_opening_date, 120) AS new_store_opening_date,
    rev_before,
    rev_after,
    CAST((rev_before - rev_after) * 100.0 / NULLIF(rev_before, 0) AS DECIMAL(10, 2)) AS pct_drop
FROM revenue_comparison
WHERE rev_before > 0 
  AND (rev_before - rev_after) * 1.0 / rev_before > 0.15
ORDER BY pct_drop DESC;


-- Q15: Sản phẩm hay mua cùng nhau
--- những cặp sản phẩm nào hay được mua chung trong cùng 1 đơn hàng? 
--Em lấy giúp top 20 cặp xuất hiện cùng nhau nhiều nhất, chỉ xét đơn có từ 2 sản phẩm khác nhau trở lên. 
---Output: sản phẩm A, sản phẩm B, số lần xuất hiện cùng, tỷ lệ trên tổng số đơn (tổng số đơn bán được) 

WITH order_products AS (
  SELECT DISTINCT s.order_number, s.product_key
  FROM retails.sales AS s
),
total_orders AS (
  SELECT COUNT(DISTINCT order_number) AS order_count
  FROM retails.sales
),
pairs AS (
  SELECT
    a.product_key AS product_a_key,
    b.product_key AS product_b_key,
    COUNT(*) AS times_together
  FROM order_products AS a
  JOIN order_products AS b
    ON b.order_number = a.order_number
   AND b.product_key > a.product_key
  GROUP BY a.product_key, b.product_key
)
SELECT TOP (20)
  pa.product_name AS product_a,
  pb.product_name AS product_b,
  pr.times_together,
  CAST(100.0 * pr.times_together / t.order_count AS DECIMAL(8, 4)) AS pct_of_orders
FROM pairs AS pr
JOIN retails.products AS pa
  ON pa.product_key = pr.product_a_key
JOIN retails.products AS pb
  ON pb.product_key = pr.product_b_key
CROSS JOIN total_orders AS t
ORDER BY pr.times_together DESC, product_a, product_b;

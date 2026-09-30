-- ============================================================
-- PROJECT 2: RETAIL COMMERCIAL ANALYTICS & DEMAND FORECASTING
-- FILE: 01_data_profiling_validation.sql
--
-- PURPOSE:
-- Profile the source tables and validate data quality before
-- performing commercial analysis, customer analysis, and
-- forecasting.
-- ============================================================


-- ============================================================
-- A. SOURCE TABLE OVERVIEW
-- ============================================================

-- Preview sales data
SELECT TOP 10 *
FROM retails.sales;


-- Row count of each source table
SELECT
    'sales' AS table_name,
    COUNT(*) AS row_count
FROM retails.sales

UNION ALL

SELECT
    'products',
    COUNT(*)
FROM retails.products

UNION ALL

SELECT
    'customers',
    COUNT(*)
FROM retails.customers

UNION ALL

SELECT
    'stores',
    COUNT(*)
FROM retails.stores;



-- ============================================================
-- B. SALES DATA STRUCTURE & TIME COVERAGE
-- ============================================================

-- Overall sales coverage
SELECT
    MIN(order_date) AS min_order_date,
    MAX(order_date) AS max_order_date,
    COUNT(DISTINCT order_number) AS total_orders,
    COUNT(*) AS total_order_lines
FROM retails.sales;


-- Inspect order-line structure
SELECT TOP 20
    order_number,
    line_item,
    order_date,
    delivery_date,
    customer_key,
    store_key,
    product_key,
    quantity
FROM retails.sales
ORDER BY
    order_number,
    line_item;


-- Year-level coverage
-- Useful for identifying incomplete years such as 2021
SELECT
    YEAR(order_date) AS year,
    MIN(order_date) AS first_order_date,
    MAX(order_date) AS last_order_date,
    COUNT(DISTINCT order_number) AS orders,
    SUM(quantity) AS units_sold
FROM retails.sales
GROUP BY
    YEAR(order_date)
ORDER BY
    year;



-- ============================================================
-- C. MASTER DATA PROFILING
-- ============================================================

-- Product master overview
SELECT TOP 20 *
FROM retails.products;


SELECT
    COUNT(*) AS total_products,
    COUNT(DISTINCT product_key) AS unique_products,
    COUNT(DISTINCT category) AS categories,
    COUNT(DISTINCT subcategory) AS subcategories,
    COUNT(DISTINCT brand) AS brands
FROM retails.products;


-- Customer master overview
SELECT
    COUNT(*) AS total_customers,
    COUNT(DISTINCT customer_key) AS unique_customers
FROM retails.customers;


-- Store master overview
SELECT
    COUNT(*) AS total_stores,
    COUNT(DISTINCT store_key) AS unique_stores,
    COUNT(DISTINCT country) AS countries
FROM retails.stores;



-- ============================================================
-- D. KEY & DUPLICATE VALIDATION
-- ============================================================

-- Candidate key for sales:
-- order_number + line_item
SELECT
    order_number,
    line_item,
    COUNT(*) AS duplicate_count
FROM retails.sales
GROUP BY
    order_number,
    line_item
HAVING COUNT(*) > 1;


-- Check missing values in candidate key
SELECT
    SUM(
        CASE
            WHEN order_number IS NULL THEN 1
            ELSE 0
        END
    ) AS missing_order_number,

    SUM(
        CASE
            WHEN line_item IS NULL THEN 1
            ELSE 0
        END
    ) AS missing_line_item
FROM retails.sales;


-- Duplicate product keys
SELECT
    product_key,
    COUNT(*) AS duplicate_count
FROM retails.products
GROUP BY
    product_key
HAVING COUNT(*) > 1;


-- Duplicate customer keys
SELECT
    customer_key,
    COUNT(*) AS duplicate_count
FROM retails.customers
GROUP BY
    customer_key
HAVING COUNT(*) > 1;


-- Duplicate store keys
SELECT
    store_key,
    COUNT(*) AS duplicate_count
FROM retails.stores
GROUP BY
    store_key
HAVING COUNT(*) > 1;



-- ============================================================
-- E. COMPLETENESS CHECKS
-- ============================================================

-- Missing values in key sales fields
SELECT
    SUM(
        CASE
            WHEN order_date IS NULL THEN 1
            ELSE 0
        END
    ) AS missing_order_date,

    SUM(
        CASE
            WHEN customer_key IS NULL THEN 1
            ELSE 0
        END
    ) AS missing_customer,

    SUM(
        CASE
            WHEN store_key IS NULL THEN 1
            ELSE 0
        END
    ) AS missing_store,

    SUM(
        CASE
            WHEN product_key IS NULL THEN 1
            ELSE 0
        END
    ) AS missing_product,

    SUM(
        CASE
            WHEN quantity IS NULL THEN 1
            ELSE 0
        END
    ) AS missing_quantity
FROM retails.sales;


-- Customer master completeness
SELECT
    SUM(
        CASE
            WHEN gender IS NULL THEN 1
            ELSE 0
        END
    ) AS missing_gender,

    SUM(
        CASE
            WHEN city IS NULL THEN 1
            ELSE 0
        END
    ) AS missing_city,

    SUM(
        CASE
            WHEN state IS NULL THEN 1
            ELSE 0
        END
    ) AS missing_state,

    SUM(
        CASE
            WHEN country IS NULL THEN 1
            ELSE 0
        END
    ) AS missing_country,

    SUM(
        CASE
            WHEN birthday IS NULL THEN 1
            ELSE 0
        END
    ) AS missing_birthday
FROM retails.customers;


-- Product master completeness
SELECT
    SUM(
        CASE
            WHEN product_name IS NULL THEN 1
            ELSE 0
        END
    ) AS missing_product_name,

    SUM(
        CASE
            WHEN brand IS NULL THEN 1
            ELSE 0
        END
    ) AS missing_brand,

    SUM(
        CASE
            WHEN category IS NULL THEN 1
            ELSE 0
        END
    ) AS missing_category,

    SUM(
        CASE
            WHEN subcategory IS NULL THEN 1
            ELSE 0
        END
    ) AS missing_subcategory
FROM retails.products;



-- ============================================================
-- F. BUSINESS RULE VALIDATION
-- ============================================================

-- Hard product pricing / cost errors
SELECT *
FROM retails.products
WHERE
       unit_cost_usd IS NULL
    OR unit_price_usd IS NULL
    OR unit_cost_usd < 0
    OR unit_price_usd < 0;


-- Business anomaly review:
-- Products with selling price below cost are flagged for review,
-- but are not automatically treated as data errors.
SELECT *
FROM retails.products
WHERE unit_price_usd < unit_cost_usd;


-- Quantity statistics
SELECT
    MIN(quantity) AS min_quantity,
    MAX(quantity) AS max_quantity,
    AVG(
        CAST(quantity AS DECIMAL(18,2))
    ) AS avg_quantity
FROM retails.sales;


-- Invalid sales quantities
SELECT *
FROM retails.sales
WHERE
       quantity IS NULL
    OR quantity <= 0;


-- Validate physical store attributes only.
-- store_key = 0 represents the Online channel and therefore
-- does not require physical store square meters.
SELECT *
FROM retails.stores
WHERE
    store_key <> 0
    AND
    (
           square_meters IS NULL
        OR square_meters <= 0
        OR open_date IS NULL
    );



-- ============================================================
-- G. REFERENTIAL INTEGRITY VALIDATION
-- ============================================================

-- Sales records without matching product master record
SELECT
    COUNT(*) AS unmatched_products
FROM retails.sales s

LEFT JOIN retails.products p
    ON s.product_key = p.product_key

WHERE p.product_key IS NULL;


-- Sales records without matching customer master record
SELECT
    COUNT(*) AS unmatched_customers
FROM retails.sales s

LEFT JOIN retails.customers c
    ON s.customer_key = c.customer_key

WHERE c.customer_key IS NULL;


-- Sales records without matching store master record
SELECT
    COUNT(*) AS unmatched_stores
FROM retails.sales s

LEFT JOIN retails.stores st
    ON s.store_key = st.store_key

WHERE st.store_key IS NULL;



-- ============================================================
-- H. CHANNEL & DELIVERY VALIDATION
-- ============================================================

-- Validate Online vs Physical Store delivery logic
SELECT
    CASE
        WHEN store_key = 0
            THEN 'Online'
        ELSE 'Physical Store'
    END AS channel,

    COUNT(DISTINCT order_number)
        AS total_orders,

    COUNT(
        DISTINCT CASE
            WHEN delivery_date IS NULL
            THEN order_number
        END
    ) AS orders_without_delivery,

    COUNT(
        DISTINCT CASE
            WHEN delivery_date IS NOT NULL
            THEN order_number
        END
    ) AS orders_with_delivery

FROM retails.sales

GROUP BY
    CASE
        WHEN store_key = 0
            THEN 'Online'
        ELSE 'Physical Store'
    END;


-- Delivery duration statistics
-- Applies only to transactions with a delivery date
SELECT
    MIN(
        DATEDIFF(
            DAY,
            order_date,
            delivery_date
        )
    ) AS min_delivery_days,

    MAX(
        DATEDIFF(
            DAY,
            order_date,
            delivery_date
        )
    ) AS max_delivery_days,

    AVG(
        CAST(
            DATEDIFF(
                DAY,
                order_date,
                delivery_date
            )
            AS DECIMAL(18,2)
        )
    ) AS avg_delivery_days

FROM retails.sales

WHERE delivery_date IS NOT NULL;


-- Invalid delivery dates
SELECT *
FROM retails.sales
WHERE delivery_date < order_date;
-- ============================================================
-- PROJECT 2: RETAIL COMMERCIAL ANALYTICS & DEMAND FORECASTING
-- FILE: 02_analytical_dataset.sql
--
-- PURPOSE:
-- Build a unified analytical dataset by integrating sales,
-- product, customer, and store data.
--
-- The analytical layer supports:
-- - Commercial performance analysis
-- - Product analysis
-- - Customer analysis
-- - Store and channel analysis
-- - Python analytics
-- - Demand forecasting
-- - Power BI reporting
--
-- IMPORTANT ASSUMPTION:
-- Historical transaction-level prices and costs are not provided.
-- Revenue and cost are therefore estimated using the unit price
-- and unit cost stored in the product master.
-- ============================================================


-- ============================================================
-- A. BUILD ANALYTICAL DATASET
-- ============================================================

SELECT
    -- --------------------------------------------------------
    -- Order information
    -- --------------------------------------------------------
    s.order_number,
    s.line_item,
    s.order_date,

    YEAR(s.order_date) AS order_year,
    MONTH(s.order_date) AS order_month,

    DATEFROMPARTS(
        YEAR(s.order_date),
        MONTH(s.order_date),
        1
    ) AS order_month_start,

    DATENAME(
        MONTH,
        s.order_date
    ) AS month_name,

    DATENAME(
        WEEKDAY,
        s.order_date
    ) AS day_of_week,


    -- --------------------------------------------------------
    -- Channel and delivery
    -- --------------------------------------------------------
    CASE
        WHEN s.store_key = 0
            THEN 'Online'
        ELSE 'Physical Store'
    END AS sales_channel,

    s.delivery_date,

    CASE
        WHEN s.delivery_date IS NOT NULL
        THEN DATEDIFF(
            DAY,
            s.order_date,
            s.delivery_date
        )
        ELSE NULL
    END AS delivery_days,


    -- --------------------------------------------------------
    -- Customer information
    -- --------------------------------------------------------
    s.customer_key,

    c.gender,

    c.city AS customer_city,
    c.state AS customer_state,
    c.country AS customer_country,
    c.continent AS customer_continent,

    c.birthday,


    -- --------------------------------------------------------
    -- Store information
    -- --------------------------------------------------------
    s.store_key,

    st.country AS store_country,
    st.state AS store_state,
    st.square_meters,
    st.open_date,


    -- --------------------------------------------------------
    -- Product information
    -- --------------------------------------------------------
    s.product_key,

    p.product_name,
    p.brand,
    p.color,
    p.subcategory,
    p.category,


    -- --------------------------------------------------------
    -- Sales information
    -- --------------------------------------------------------
    s.quantity,

    p.unit_price_usd,
    p.unit_cost_usd,


    -- --------------------------------------------------------
    -- Calculated commercial metrics
    -- --------------------------------------------------------

    -- Estimated historical revenue
    s.quantity * p.unit_price_usd
        AS revenue,

    -- Estimated historical cost
    s.quantity * p.unit_cost_usd
        AS total_cost,

    -- Estimated gross profit
    s.quantity *
    (
        p.unit_price_usd
        - p.unit_cost_usd
    ) AS gross_profit,

    -- Margin at individual sales-line level.
    -- Overall gross margin must NOT be calculated
    -- by averaging this field.
    CASE
        WHEN p.unit_price_usd > 0
        THEN
            (
                p.unit_price_usd
                - p.unit_cost_usd
            )
            /
            p.unit_price_usd
        ELSE NULL
    END AS line_gross_margin

FROM retails.sales s

LEFT JOIN retails.products p
    ON s.product_key = p.product_key

LEFT JOIN retails.customers c
    ON s.customer_key = c.customer_key

LEFT JOIN retails.stores st
    ON s.store_key = st.store_key;



-- ============================================================
-- B. ANALYTICAL DATASET RECONCILIATION
-- ============================================================

-- Validate that integrating product, customer, and store
-- dimensions does not duplicate or remove source sales rows.

WITH analytical_data AS
(
    SELECT
        s.order_number,
        s.line_item,
        s.quantity,

        s.quantity * p.unit_price_usd
            AS revenue,

        s.quantity * p.unit_cost_usd
            AS total_cost,

        s.quantity *
        (
            p.unit_price_usd
            - p.unit_cost_usd
        ) AS gross_profit

    FROM retails.sales s

    LEFT JOIN retails.products p
        ON s.product_key = p.product_key

    LEFT JOIN retails.customers c
        ON s.customer_key = c.customer_key

    LEFT JOIN retails.stores st
        ON s.store_key = st.store_key
)

SELECT
    COUNT(*) AS analytical_rows,

    COUNT(
        DISTINCT CONCAT(
            order_number,
            '-',
            line_item
        )
    ) AS unique_order_lines,

    COUNT(
        DISTINCT order_number
    ) AS total_orders,

    SUM(quantity) AS total_units,

    SUM(revenue) AS total_revenue,

    SUM(total_cost) AS total_cost,

    SUM(gross_profit) AS gross_profit

FROM analytical_data;



-- ============================================================
-- C. SOURCE VS ANALYTICAL ROW RECONCILIATION
-- ============================================================

WITH analytical_data AS
(
    SELECT
        s.order_number,
        s.line_item

    FROM retails.sales s

    LEFT JOIN retails.products p
        ON s.product_key = p.product_key

    LEFT JOIN retails.customers c
        ON s.customer_key = c.customer_key

    LEFT JOIN retails.stores st
        ON s.store_key = st.store_key
)

SELECT
    (
        SELECT COUNT(*)
        FROM retails.sales
    ) AS source_rows,

    COUNT(*) AS analytical_rows,

    COUNT(*) -
    (
        SELECT COUNT(*)
        FROM retails.sales
    ) AS row_difference

FROM analytical_data;



-- ============================================================
-- D. BASELINE BUSINESS KPIs
-- ============================================================

SELECT
    -- Orders
    COUNT(
        DISTINCT s.order_number
    ) AS total_orders,

    -- Active customers
    COUNT(
        DISTINCT s.customer_key
    ) AS active_customers,

    -- Products with recorded sales
    COUNT(
        DISTINCT s.product_key
    ) AS products_sold,

    -- Total units sold
    SUM(s.quantity)
        AS units_sold,

    -- Estimated revenue
    SUM(
        s.quantity
        * p.unit_price_usd
    ) AS revenue,

    -- Estimated cost
    SUM(
        s.quantity
        * p.unit_cost_usd
    ) AS total_cost,

    -- Estimated gross profit
    SUM(
        s.quantity
        *
        (
            p.unit_price_usd
            - p.unit_cost_usd
        )
    ) AS gross_profit,

    -- Weighted gross margin
    SUM(
        s.quantity
        *
        (
            p.unit_price_usd
            - p.unit_cost_usd
        )
    )
    /
    NULLIF(
        SUM(
            s.quantity
            * p.unit_price_usd
        ),
        0
    ) AS gross_margin,

    -- Average order value
    SUM(
        s.quantity
        * p.unit_price_usd
    )
    /
    NULLIF(
        COUNT(
            DISTINCT s.order_number
        ),
        0
    ) AS average_order_value

FROM retails.sales s

LEFT JOIN retails.products p
    ON s.product_key = p.product_key;
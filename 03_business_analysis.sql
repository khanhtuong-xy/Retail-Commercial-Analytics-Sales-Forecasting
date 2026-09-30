-- ============================================================
-- PROJECT 2: RETAIL COMMERCIAL ANALYTICS & DEMAND FORECASTING
-- FILE: 03_business_analysis.sql
--
-- PURPOSE:
-- Analyze commercial performance and investigate the drivers
-- behind the significant revenue decline observed in 2020.
--
-- MAIN BUSINESS QUESTIONS:
-- 1. How has commercial performance changed over time?
-- 2. Which channels, categories, and stores drive performance?
-- 3. Was the 2020 decline caused by channel/product/store mix?
-- 4. Did customer acquisition or returning-customer activity
--    contribute to the decline?
--
-- NOTE:
-- 2021 data ends on 2021-02-20 and should be treated as
-- a partial year.
-- ============================================================



-- ============================================================
-- A. YEARLY COMMERCIAL PERFORMANCE
-- ============================================================

SELECT
    YEAR(s.order_date) AS year,

    COUNT(DISTINCT s.order_number) AS orders,

    COUNT(DISTINCT s.customer_key) AS customers,

    SUM(s.quantity) AS units_sold,

    SUM(
        s.quantity * p.unit_price_usd
    ) AS revenue,

    SUM(
        s.quantity * p.unit_cost_usd
    ) AS total_cost,

    SUM(
        s.quantity *
        (
            p.unit_price_usd
            - p.unit_cost_usd
        )
    ) AS gross_profit,

    SUM(
        s.quantity *
        (
            p.unit_price_usd
            - p.unit_cost_usd
        )
    )
    /
    NULLIF(
        SUM(
            s.quantity * p.unit_price_usd
        ),
        0
    ) AS gross_margin,

    SUM(
        s.quantity * p.unit_price_usd
    )
    /
    NULLIF(
        COUNT(DISTINCT s.order_number),
        0
    ) AS average_order_value

FROM retails.sales s

LEFT JOIN retails.products p
    ON s.product_key = p.product_key

GROUP BY
    YEAR(s.order_date)

ORDER BY
    year;



-- ============================================================
-- B. YEAR-OVER-YEAR PERFORMANCE CHANGE
-- ============================================================

WITH yearly_performance AS
(
    SELECT
        YEAR(s.order_date) AS year,

        COUNT(DISTINCT s.order_number)
            AS orders,

        COUNT(DISTINCT s.customer_key)
            AS customers,

        SUM(s.quantity)
            AS units_sold,

        SUM(
            s.quantity * p.unit_price_usd
        ) AS revenue

    FROM retails.sales s

    LEFT JOIN retails.products p
        ON s.product_key = p.product_key

    GROUP BY
        YEAR(s.order_date)
),

yearly_comparison AS
(
    SELECT
        year,
        orders,
        customers,
        units_sold,
        revenue,

        LAG(orders)
            OVER (ORDER BY year)
            AS previous_orders,

        LAG(customers)
            OVER (ORDER BY year)
            AS previous_customers,

        LAG(units_sold)
            OVER (ORDER BY year)
            AS previous_units,

        LAG(revenue)
            OVER (ORDER BY year)
            AS previous_revenue

    FROM yearly_performance
)

SELECT
    year,
    orders,
    customers,
    units_sold,
    revenue,

    revenue
        - previous_revenue
        AS revenue_change,

    (
        revenue
        / NULLIF(previous_revenue, 0)
        - 1
    ) AS revenue_yoy_growth,

    (
        orders
        * 1.0
        / NULLIF(previous_orders, 0)
        - 1
    ) AS orders_yoy_growth,

    (
        customers
        * 1.0
        / NULLIF(previous_customers, 0)
        - 1
    ) AS customers_yoy_growth,

    (
        units_sold
        * 1.0
        / NULLIF(previous_units, 0)
        - 1
    ) AS units_yoy_growth

FROM yearly_comparison

ORDER BY year;



-- ============================================================
-- C. MONTHLY COMMERCIAL TREND
-- ============================================================

SELECT
    DATEFROMPARTS(
        YEAR(s.order_date),
        MONTH(s.order_date),
        1
    ) AS month,

    COUNT(
        DISTINCT s.order_number
    ) AS orders,

    COUNT(
        DISTINCT s.customer_key
    ) AS customers,

    SUM(s.quantity)
        AS units_sold,

    SUM(
        s.quantity * p.unit_price_usd
    ) AS revenue,

    SUM(
        s.quantity *
        (
            p.unit_price_usd
            - p.unit_cost_usd
        )
    ) AS gross_profit

FROM retails.sales s

LEFT JOIN retails.products p
    ON s.product_key = p.product_key

GROUP BY
    DATEFROMPARTS(
        YEAR(s.order_date),
        MONTH(s.order_date),
        1
    )

ORDER BY month;



-- ============================================================
-- D. CHANNEL PERFORMANCE
-- ============================================================

SELECT
    CASE
        WHEN s.store_key = 0
            THEN 'Online'
        ELSE 'Physical Store'
    END AS channel,

    COUNT(
        DISTINCT s.order_number
    ) AS orders,

    COUNT(
        DISTINCT s.customer_key
    ) AS customers,

    SUM(s.quantity)
        AS units_sold,

    SUM(
        s.quantity * p.unit_price_usd
    ) AS revenue,

    SUM(
        s.quantity *
        (
            p.unit_price_usd
            - p.unit_cost_usd
        )
    ) AS gross_profit,

    SUM(
        s.quantity *
        (
            p.unit_price_usd
            - p.unit_cost_usd
        )
    )
    /
    NULLIF(
        SUM(
            s.quantity * p.unit_price_usd
        ),
        0
    ) AS gross_margin,

    SUM(
        s.quantity * p.unit_price_usd
    )
    /
    NULLIF(
        COUNT(DISTINCT s.order_number),
        0
    ) AS average_order_value

FROM retails.sales s

LEFT JOIN retails.products p
    ON s.product_key = p.product_key

GROUP BY
    CASE
        WHEN s.store_key = 0
            THEN 'Online'
        ELSE 'Physical Store'
    END

ORDER BY revenue DESC;



-- ============================================================
-- E. PRODUCT CATEGORY PERFORMANCE
-- ============================================================

SELECT
    p.category,

    COUNT(
        DISTINCT s.order_number
    ) AS orders,

    COUNT(
        DISTINCT s.customer_key
    ) AS customers,

    SUM(s.quantity)
        AS units_sold,

    SUM(
        s.quantity * p.unit_price_usd
    ) AS revenue,

    SUM(
        s.quantity *
        (
            p.unit_price_usd
            - p.unit_cost_usd
        )
    ) AS gross_profit,

    SUM(
        s.quantity *
        (
            p.unit_price_usd
            - p.unit_cost_usd
        )
    )
    /
    NULLIF(
        SUM(
            s.quantity * p.unit_price_usd
        ),
        0
    ) AS gross_margin

FROM retails.sales s

LEFT JOIN retails.products p
    ON s.product_key = p.product_key

GROUP BY
    p.category

ORDER BY
    revenue DESC;



-- ============================================================
-- F. PHYSICAL STORE PERFORMANCE
-- ============================================================

SELECT
    s.store_key,

    st.country,
    st.state,
    st.square_meters,

    COUNT(
        DISTINCT s.order_number
    ) AS orders,

    COUNT(
        DISTINCT s.customer_key
    ) AS customers,

    SUM(s.quantity)
        AS units_sold,

    SUM(
        s.quantity * p.unit_price_usd
    ) AS revenue,

    SUM(
        s.quantity *
        (
            p.unit_price_usd
            - p.unit_cost_usd
        )
    ) AS gross_profit,

    SUM(
        s.quantity * p.unit_price_usd
    )
    /
    NULLIF(
        st.square_meters,
        0
    ) AS revenue_per_sqm,

    SUM(
        s.quantity *
        (
            p.unit_price_usd
            - p.unit_cost_usd
        )
    )
    /
    NULLIF(
        st.square_meters,
        0
    ) AS gross_profit_per_sqm

FROM retails.sales s

LEFT JOIN retails.products p
    ON s.product_key = p.product_key

LEFT JOIN retails.stores st
    ON s.store_key = st.store_key

WHERE
    s.store_key <> 0

GROUP BY
    s.store_key,
    st.country,
    st.state,
    st.square_meters

ORDER BY
    revenue DESC;



-- ============================================================
-- G. 2020 ROOT CAUSE: CHANNEL ANALYSIS
-- ============================================================

SELECT
    YEAR(s.order_date)
        AS year,

    CASE
        WHEN s.store_key = 0
            THEN 'Online'
        ELSE 'Physical Store'
    END AS channel,

    COUNT(
        DISTINCT s.order_number
    ) AS orders,

    COUNT(
        DISTINCT s.customer_key
    ) AS customers,

    SUM(s.quantity)
        AS units_sold,

    SUM(
        s.quantity * p.unit_price_usd
    ) AS revenue

FROM retails.sales s

LEFT JOIN retails.products p
    ON s.product_key = p.product_key

WHERE
    YEAR(s.order_date) IN (2019, 2020)

GROUP BY
    YEAR(s.order_date),

    CASE
        WHEN s.store_key = 0
            THEN 'Online'
        ELSE 'Physical Store'
    END

ORDER BY
    channel,
    year;



-- ============================================================
-- H. 2020 ROOT CAUSE: CATEGORY ANALYSIS
-- ============================================================

SELECT
    p.category,

    SUM(
        CASE
            WHEN YEAR(s.order_date) = 2019
            THEN
                s.quantity
                * p.unit_price_usd
            ELSE 0
        END
    ) AS revenue_2019,

    SUM(
        CASE
            WHEN YEAR(s.order_date) = 2020
            THEN
                s.quantity
                * p.unit_price_usd
            ELSE 0
        END
    ) AS revenue_2020,

    SUM(
        CASE
            WHEN YEAR(s.order_date) = 2020
            THEN
                s.quantity
                * p.unit_price_usd
            ELSE 0
        END
    )
    -
    SUM(
        CASE
            WHEN YEAR(s.order_date) = 2019
            THEN
                s.quantity
                * p.unit_price_usd
            ELSE 0
        END
    ) AS revenue_change,

    (
        SUM(
            CASE
                WHEN YEAR(s.order_date) = 2020
                THEN
                    s.quantity
                    * p.unit_price_usd
                ELSE 0
            END
        )
        /
        NULLIF(
            SUM(
                CASE
                    WHEN YEAR(s.order_date) = 2019
                    THEN
                        s.quantity
                        * p.unit_price_usd
                    ELSE 0
                END
            ),
            0
        )
        - 1
    ) AS yoy_growth

FROM retails.sales s

LEFT JOIN retails.products p
    ON s.product_key = p.product_key

WHERE
    YEAR(s.order_date) IN (2019, 2020)

GROUP BY
    p.category

ORDER BY
    revenue_change ASC;



-- ============================================================
-- I. STORE ACTIVITY / EXPOSURE ANALYSIS
-- ============================================================

-- Review how long each physical store actually appears
-- in the available transaction history.

SELECT
    st.store_key,
    st.country,
    st.state,
    st.open_date,

    MIN(s.order_date)
        AS first_sale_date,

    MAX(s.order_date)
        AS last_sale_date,

    COUNT(
        DISTINCT s.order_number
    ) AS orders,

    SUM(
        s.quantity * p.unit_price_usd
    ) AS revenue

FROM retails.stores st

LEFT JOIN retails.sales s
    ON st.store_key = s.store_key

LEFT JOIN retails.products p
    ON s.product_key = p.product_key

WHERE
    st.store_key <> 0

GROUP BY
    st.store_key,
    st.country,
    st.state,
    st.open_date

ORDER BY
    revenue ASC;



-- ============================================================
-- J. ACTIVE STORE COUNT BY YEAR
-- ============================================================

SELECT
    YEAR(order_date)
        AS year,

    COUNT(
        DISTINCT store_key
    ) AS active_stores

FROM retails.sales

WHERE
    store_key <> 0

GROUP BY
    YEAR(order_date)

ORDER BY
    year;



-- ============================================================
-- K. SAME-STORE SALES ANALYSIS
--
-- Business question:
-- Did 2020 revenue decline because stores disappeared,
-- or did stores active in both years also lose sales?
-- ============================================================

WITH active_2019 AS
(
    SELECT DISTINCT
        store_key
    FROM retails.sales
    WHERE
        YEAR(order_date) = 2019
        AND store_key <> 0
),

active_2020 AS
(
    SELECT DISTINCT
        store_key
    FROM retails.sales
    WHERE
        YEAR(order_date) = 2020
        AND store_key <> 0
),

same_stores AS
(
    SELECT
        a.store_key
    FROM active_2019 a

    INNER JOIN active_2020 b
        ON a.store_key = b.store_key
)

SELECT
    YEAR(s.order_date)
        AS year,

    COUNT(
        DISTINCT s.store_key
    ) AS stores,

    COUNT(
        DISTINCT s.order_number
    ) AS orders,

    COUNT(
        DISTINCT s.customer_key
    ) AS customers,

    SUM(s.quantity)
        AS units_sold,

    SUM(
        s.quantity * p.unit_price_usd
    ) AS revenue

FROM retails.sales s

INNER JOIN same_stores ss
    ON s.store_key = ss.store_key

LEFT JOIN retails.products p
    ON s.product_key = p.product_key

WHERE
    YEAR(s.order_date) IN (2019, 2020)

GROUP BY
    YEAR(s.order_date)

ORDER BY
    year;



-- ============================================================
-- L. NEW VS RETURNING CUSTOMER ANALYSIS
--
-- Business question:
-- Was the 2020 decline driven more by weaker customer
-- acquisition or by reduced activity among existing customers?
-- ============================================================

WITH customer_first_order AS
(
    SELECT
        customer_key,

        MIN(order_date)
            AS first_order_date

    FROM retails.sales

    GROUP BY
        customer_key
)

SELECT
    YEAR(s.order_date)
        AS year,

    CASE
        WHEN YEAR(cfo.first_order_date)
             = YEAR(s.order_date)
        THEN 'New Customer'

        ELSE 'Returning Customer'
    END AS customer_type,

    COUNT(
        DISTINCT s.customer_key
    ) AS customers,

    COUNT(
        DISTINCT s.order_number
    ) AS orders,

    SUM(s.quantity)
        AS units_sold,

    SUM(
        s.quantity * p.unit_price_usd
    ) AS revenue,

    SUM(
        s.quantity * p.unit_price_usd
    )
    /
    NULLIF(
        COUNT(
            DISTINCT s.order_number
        ),
        0
    ) AS average_order_value,

    COUNT(
        DISTINCT s.order_number
    )
    * 1.0
    /
    NULLIF(
        COUNT(
            DISTINCT s.customer_key
        ),
        0
    ) AS orders_per_customer

FROM retails.sales s

LEFT JOIN customer_first_order cfo
    ON s.customer_key = cfo.customer_key

LEFT JOIN retails.products p
    ON s.product_key = p.product_key

WHERE
    YEAR(s.order_date) IN (2019, 2020)

GROUP BY
    YEAR(s.order_date),

    CASE
        WHEN YEAR(cfo.first_order_date)
             = YEAR(s.order_date)
        THEN 'New Customer'

        ELSE 'Returning Customer'
    END

ORDER BY
    year,
    customer_type;



-- ============================================================
-- M. ANNUAL COHORT ACTIVITY
--
-- NOTE:
-- This is NOT a standard retention matrix.
-- It measures whether customers from each acquisition cohort
-- were active in later calendar years.
--
-- Customers may become inactive and later return, so the result
-- should be interpreted as annual cohort activity/reactivation.
--
-- 2021 is a partial year and should not be compared directly
-- with complete prior years.
-- ============================================================

WITH first_purchase AS
(
    SELECT
        customer_key,

        MIN(order_date)
            AS first_purchase_date

    FROM retails.sales

    GROUP BY
        customer_key
),

customer_activity AS
(
    SELECT DISTINCT
        s.customer_key,

        YEAR(fp.first_purchase_date)
            AS cohort_year,

        YEAR(s.order_date)
            AS activity_year

    FROM retails.sales s

    INNER JOIN first_purchase fp
        ON s.customer_key = fp.customer_key
),

cohort_size AS
(
    SELECT
        cohort_year,

        COUNT(
            DISTINCT customer_key
        ) AS cohort_customers

    FROM customer_activity

    WHERE
        cohort_year = activity_year

    GROUP BY
        cohort_year
)

SELECT
    ca.cohort_year,
    ca.activity_year,

    cs.cohort_customers,

    COUNT(
        DISTINCT ca.customer_key
    ) AS active_customers,

    COUNT(
        DISTINCT ca.customer_key
    )
    * 1.0
    /
    NULLIF(
        cs.cohort_customers,
        0
    ) AS activity_rate

FROM customer_activity ca

INNER JOIN cohort_size cs
    ON ca.cohort_year = cs.cohort_year

GROUP BY
    ca.cohort_year,
    ca.activity_year,
    cs.cohort_customers

ORDER BY
    ca.cohort_year,
    ca.activity_year;
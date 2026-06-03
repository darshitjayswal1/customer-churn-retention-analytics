-- =============================================================================
-- 03_analysis_queries.sql
-- The analytical core of the project. Each query answers one business question
-- and feeds one Power BI visual. Written in portable SQL (window functions/CTEs).
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Q1. HEADLINE KPIs  (KPI cards on the Overview page)
-- ---------------------------------------------------------------------------
SELECT
    COUNT(*)                                                   AS total_signups,
    SUM(is_verified)                                           AS verified,
    SUM(is_activated)                                          AS activated,
    SUM(CASE WHEN is_activated = 1 AND is_churned = 0 THEN 1 ELSE 0 END) AS active_customers,
    ROUND(100.0 * SUM(is_churned) / NULLIF(SUM(is_activated),0), 1)      AS churn_rate_pct,
    ROUND(SUM(CASE WHEN is_activated = 1 AND is_churned = 0
                   THEN monthly_charge ELSE 0 END), 0)         AS active_mrr,        -- monthly recurring revenue
    ROUND(SUM(CASE WHEN is_churned = 1 THEN monthly_charge ELSE 0 END), 0) AS monthly_revenue_lost
FROM customers;

-- ---------------------------------------------------------------------------
-- Q2. ACQUISITION FUNNEL  (funnel visual: Signup -> Verified -> Activated)
--     Mirrors the acquisition-funnel dashboards Darshit built at GJ Tech.
-- ---------------------------------------------------------------------------
SELECT '1. Signup'   AS stage, COUNT(*)        AS customers, 100.0 AS pct_of_signups FROM customers
UNION ALL
SELECT '2. Verified', SUM(is_verified),  ROUND(100.0*SUM(is_verified)/COUNT(*),1)  FROM customers
UNION ALL
SELECT '3. Activated', SUM(is_activated), ROUND(100.0*SUM(is_activated)/COUNT(*),1) FROM customers;

-- ---------------------------------------------------------------------------
-- Q3. CHURN BY CONTRACT TYPE  (bar chart) -- the single biggest churn driver
-- ---------------------------------------------------------------------------
SELECT
    contract_type,
    SUM(is_activated)                                            AS activated_customers,
    SUM(is_churned)                                              AS churned,
    ROUND(100.0 * SUM(is_churned) / NULLIF(SUM(is_activated),0), 1) AS churn_rate_pct
FROM customers
WHERE is_activated = 1
GROUP BY contract_type
ORDER BY churn_rate_pct DESC;

-- ---------------------------------------------------------------------------
-- Q4. CHURN & ACQUISITION QUALITY BY CHANNEL  (matrix / bar)
--     Combines funnel conversion AND churn to rank channel QUALITY, not volume.
-- ---------------------------------------------------------------------------
SELECT
    acquisition_channel,
    COUNT(*)                                                    AS signups,
    ROUND(100.0*SUM(is_activated)/COUNT(*),1)                   AS activation_rate_pct,
    ROUND(100.0*SUM(is_churned)/NULLIF(SUM(is_activated),0),1)  AS churn_rate_pct,
    ROUND(SUM(CASE WHEN is_activated=1 AND is_churned=0 THEN total_revenue END),0) AS retained_revenue
FROM customers
GROUP BY acquisition_channel
ORDER BY churn_rate_pct DESC;

-- ---------------------------------------------------------------------------
-- Q5. MONTHLY COHORT RETENTION  (cohort heatmap)
--     Cohort = signup month. Retention = % of an activated cohort still active.
--     This is the cohort analysis called out on Darshit's resume.
-- ---------------------------------------------------------------------------
WITH activated AS (
    SELECT
        customer_id,
        STRFTIME('%Y-%m', signup_date) AS cohort_month,
        tenure_months,
        is_churned
    FROM customers
    WHERE is_activated = 1
)
SELECT
    cohort_month,
    COUNT(*)                                                        AS cohort_size,
    ROUND(100.0*AVG(CASE WHEN tenure_months >= 1  THEN 1.0*(1-is_churned) ELSE 1 END),0) AS m1_retention,
    ROUND(100.0*SUM(CASE WHEN is_churned=0 OR tenure_months>=3  THEN 1 ELSE 0 END)/COUNT(*),0) AS still_active_m3_plus,
    ROUND(100.0*SUM(1-is_churned)/COUNT(*),1)                       AS current_retention_pct
FROM activated
GROUP BY cohort_month
ORDER BY cohort_month;

-- ---------------------------------------------------------------------------
-- Q6. RFM SEGMENTATION  (segment table + scatter)
--     Recency  = days since last_active   (lower = better)
--     Frequency= monthly_logins           (higher = better)
--     Monetary = total_revenue            (higher = better)
--     Score each 1-4 via NTILE, then label segments. Active customers only.
-- ---------------------------------------------------------------------------
WITH base AS (
    SELECT
        customer_id, plan, contract_type, acquisition_channel,
        CAST(JULIANDAY('2026-05-31') - JULIANDAY(last_active_date) AS INT) AS recency_days,
        monthly_logins AS frequency,
        total_revenue  AS monetary
    FROM customers
    WHERE is_activated = 1 AND is_churned = 0
),
scored AS (
    SELECT *,
        5 - NTILE(4) OVER (ORDER BY recency_days)        AS r_score, -- recent = high
        NTILE(4) OVER (ORDER BY frequency)               AS f_score,
        NTILE(4) OVER (ORDER BY monetary)                AS m_score
    FROM base
)
SELECT
    CASE
        WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3 THEN 'Champions'
        WHEN r_score >= 3 AND m_score >= 3                  THEN 'Loyal / High-Value'
        WHEN r_score >= 3                                   THEN 'Promising'
        WHEN r_score = 2                                    THEN 'Needs Attention'
        ELSE 'At Risk'
    END                                                     AS rfm_segment,
    COUNT(*)                                                AS customers,
    ROUND(AVG(recency_days),0)                              AS avg_recency_days,
    ROUND(AVG(frequency),1)                                 AS avg_logins,
    ROUND(AVG(monetary),0)                                  AS avg_revenue
FROM scored
GROUP BY rfm_segment
ORDER BY avg_revenue DESC;

-- ---------------------------------------------------------------------------
-- Q7. REVENUE AT RISK BY SEGMENT  (drives the "so what / recommendation")
--     Which still-active customers look most like the ones who already churned?
-- ---------------------------------------------------------------------------
SELECT
    contract_type,
    payment_method,
    COUNT(*)                                                AS active_customers,
    ROUND(SUM(monthly_charge),0)                            AS monthly_revenue_exposed
FROM customers
WHERE is_activated = 1 AND is_churned = 0
  AND contract_type = 'Monthly'                 -- highest-churn contract
  AND payment_method IN ('Wallet')              -- highest-churn payment method
GROUP BY contract_type, payment_method;

-- ---------------------------------------------------------------------------
-- Q8. CHURN BY TENURE BAND  (line/column: when do customers leave?)
-- ---------------------------------------------------------------------------
SELECT
    CASE
        WHEN tenure_months <= 3  THEN '0-3 months'
        WHEN tenure_months <= 6  THEN '4-6 months'
        WHEN tenure_months <= 12 THEN '7-12 months'
        ELSE '12+ months'
    END                                                     AS tenure_band,
    SUM(is_activated)                                       AS customers,
    ROUND(100.0*SUM(is_churned)/NULLIF(SUM(is_activated),0),1) AS churn_rate_pct
FROM customers
WHERE is_activated = 1
GROUP BY tenure_band
ORDER BY MIN(tenure_months);

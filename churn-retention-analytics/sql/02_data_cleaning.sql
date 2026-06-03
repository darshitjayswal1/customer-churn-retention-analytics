-- =============================================================================
-- 02_data_cleaning.sql
-- Data quality audit + cleaning. Mirrors the QA / data-governance work Darshit
-- did at ActionEdge & GJ Tech. Run these AFTER loading the raw CSV.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. AUDIT: find the data-quality issues before fixing anything
-- ---------------------------------------------------------------------------

-- 1a. Missing monthly_charge (should be 0 after cleaning)
SELECT COUNT(*) AS missing_monthly_charge
FROM customers
WHERE monthly_charge IS NULL OR TRIM(monthly_charge) = '';

-- 1b. Inconsistent city casing (e.g. "MUMBAI" vs "Mumbai")
SELECT city, COUNT(*) AS n
FROM customers
GROUP BY city
ORDER BY city;

-- 1c. Whitespace / shorthand values in categorical fields
SELECT DISTINCT payment_method FROM customers ORDER BY payment_method;
SELECT DISTINCT gender         FROM customers ORDER BY gender;

-- 1d. Logical integrity: nobody can be activated without being verified
SELECT COUNT(*) AS impossible_funnel
FROM customers
WHERE is_activated = 1 AND is_verified = 0;

-- 1e. Logical integrity: churned customers must have a churn_date
SELECT COUNT(*) AS churn_without_date
FROM customers
WHERE is_churned = 1 AND (churn_date IS NULL OR TRIM(churn_date) = '');

-- ---------------------------------------------------------------------------
-- 2. CLEAN: standardise text, trim whitespace, normalise shorthand
-- ---------------------------------------------------------------------------

-- 2a. Standardise city to Title Case (simple approach: upper-first per known set)
UPDATE customers
SET city = CASE
    WHEN UPPER(city) = 'AHMEDABAD' THEN 'Ahmedabad'
    WHEN UPPER(city) = 'MUMBAI'    THEN 'Mumbai'
    WHEN UPPER(city) = 'DELHI'     THEN 'Delhi'
    WHEN UPPER(city) = 'BENGALURU' THEN 'Bengaluru'
    WHEN UPPER(city) = 'PUNE'      THEN 'Pune'
    WHEN UPPER(city) = 'HYDERABAD' THEN 'Hyderabad'
    WHEN UPPER(city) = 'CHENNAI'   THEN 'Chennai'
    WHEN UPPER(city) = 'KOLKATA'   THEN 'Kolkata'
    WHEN UPPER(city) = 'JAIPUR'    THEN 'Jaipur'
    WHEN UPPER(city) = 'SURAT'     THEN 'Surat'
    ELSE city END;

-- 2b. Trim whitespace on payment_method
UPDATE customers
SET payment_method = TRIM(payment_method);

-- 2c. Normalise gender shorthand (M -> Male, F -> Female)
UPDATE customers
SET gender = CASE
    WHEN TRIM(UPPER(gender)) IN ('M', 'MALE')   THEN 'Male'
    WHEN TRIM(UPPER(gender)) IN ('F', 'FEMALE') THEN 'Female'
    ELSE gender END;

-- 2d. Impute missing monthly_charge with the average charge of the SAME plan
--     (documented governance choice: plan-level average is a defensible proxy
--      because price is driven mostly by plan tier + add-ons)
UPDATE customers
SET monthly_charge = (
    SELECT ROUND(AVG(c2.monthly_charge), 0)
    FROM customers c2
    WHERE c2.plan = customers.plan
      AND c2.monthly_charge IS NOT NULL
)
WHERE monthly_charge IS NULL;

-- ---------------------------------------------------------------------------
-- 3. VERIFY: re-run the audit; all counts should now be 0 / consistent
-- ---------------------------------------------------------------------------
SELECT
    SUM(CASE WHEN monthly_charge IS NULL THEN 1 ELSE 0 END)          AS null_charges,
    COUNT(DISTINCT city)                                             AS distinct_cities,   -- expect 10
    COUNT(DISTINCT gender)                                           AS distinct_genders,  -- expect 2
    SUM(CASE WHEN is_activated = 1 AND is_verified = 0 THEN 1 ELSE 0 END) AS bad_funnel
FROM customers;

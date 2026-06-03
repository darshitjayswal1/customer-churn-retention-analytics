-- =============================================================================
-- 01_create_schema.sql
-- Customer Churn & Retention Analytics  |  StreamNova (fictional)
-- Engine: SQLite-compatible (also runs on Postgres/MySQL with minor tweaks)
-- Purpose: Create the staging table and load customers.csv
-- =============================================================================

DROP TABLE IF EXISTS customers;

CREATE TABLE customers (
    customer_id        TEXT PRIMARY KEY,
    signup_date        DATE,
    acquisition_channel TEXT,
    city               TEXT,
    gender             TEXT,
    age                INTEGER,
    senior_citizen     INTEGER,      -- 1 = age >= 60
    plan               TEXT,         -- Basic / Standard / Premium
    contract_type      TEXT,         -- Monthly / Annual / Two-Year
    payment_method     TEXT,
    paperless_billing  TEXT,         -- Yes / No
    addon_count        INTEGER,
    monthly_charge     REAL,         -- INR
    is_verified        INTEGER,      -- funnel stage 2
    is_activated       INTEGER,      -- funnel stage 3 (first conversion)
    tenure_months      INTEGER,
    monthly_logins     REAL,
    last_active_date   DATE,
    total_revenue      REAL,         -- INR, lifetime to date
    churn_date         DATE,         -- NULL if still active
    is_churned         INTEGER       -- 1 = churned (only among activated)
);

-- Load (SQLite CLI):
--   .mode csv
--   .import --skip 1 data/customers.csv customers
--
-- Postgres:  \copy customers FROM 'data/customers.csv' CSV HEADER;
-- MySQL:     LOAD DATA INFILE 'customers.csv' INTO TABLE customers
--            FIELDS TERMINATED BY ',' IGNORE 1 LINES;

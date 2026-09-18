-- ============================================================================
-- NOVA RETAIL - ENVIRONMENT & BRONZE LAYER SETUP DDL
-- Modern Data Stack Architecture: Snowflake + dbt + KNIME
-- ============================================================================

-- 1. COMPUTE WAREHOUSE SETUP
-- Dedicated isolated warehouse to prevent compute interference and track costs.
CREATE WAREHOUSE IF NOT EXISTS DBT_WH
    WITH WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE;

-- 2. DATABASE & MEDALLION SCHEMAS CREATION
-- Central database containing isolated schemas representing data maturity levels.
CREATE DATABASE IF NOT EXISTS NOVA_RETAIL_DB;

CREATE SCHEMA IF NOT EXISTS NOVA_RETAIL_DB.BRONZE; -- Raw immutable landing schema
CREATE SCHEMA IF NOT EXISTS NOVA_RETAIL_DB.SILVER; -- Cleaned, parsed & 3NF normalized schema
CREATE SCHEMA IF NOT EXISTS NOVA_RETAIL_DB.GOLD;   -- Dimensional Kimball Star Schema for Power BI

-- 3. SECURITY & ROLE-BASED ACCESS CONTROL (RBAC)
-- Enforcing the principle of least privilege for automated transformations.
CREATE ROLE IF NOT EXISTS DBT_ROLE;

GRANT USAGE ON WAREHOUSE DBT_WH TO ROLE DBT_ROLE;
GRANT ALL ON DATABASE NOVA_RETAIL_DB TO ROLE DBT_ROLE;
GRANT ALL ON ALL SCHEMAS IN DATABASE NOVA_RETAIL_DB TO ROLE DBT_ROLE;

-- Assign execution role to current user
GRANT ROLE DBT_ROLE TO USER ALICIACASANUEVA;

-- Set active context
USE DATABASE NOVA_RETAIL_DB;
USE SCHEMA BRONZE;

-- 4. BRONZE LAYER TABLES (RAW INGESTION)
-- Ingestion landing tables created using unconstrained string/variant types for schema drift safety.

-- Raw Sales Transactions (Injected from CSV via KNIME)
CREATE OR REPLACE TABLE NOVA_RETAIL_DB.BRONZE.RAW_SALES_TRANSACTIONS (
    order_id STRING,
    transaction_date STRING,
    customer_info STRING,
    product_id STRING,
    product_category STRING,
    price STRING,
    qty STRING,
    discount_pct STRING,
    _loaded_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP() -- Audit load timestamp
);

-- Raw Web Reviews (Injected from semi-structured JSON via KNIME)
CREATE OR REPLACE TABLE NOVA_RETAIL_DB.BRONZE.RAW_WEB_REVIEWS (
    json_data VARIANT,
    _loaded_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP() -- Audit load timestamp
);

-- Raw Finance Targets (Injected from wide-format Excel/CSV via KNIME)
CREATE OR REPLACE TABLE NOVA_RETAIL_DB.BRONZE.RAW_FINANCE_TARGETS (
    region STRING,
    category STRING,
    jan_23 STRING, feb_23 STRING, mar_23 STRING, apr_23 STRING,
    may_23 STRING, jun_23 STRING, jul_23 STRING, aug_23 STRING,
    sep_23 STRING, oct_23 STRING, nov_23 STRING, dec_23 STRING,
    _loaded_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP() -- Audit load timestamp
);

-- 5. CURRENCY EXCHANGE RATE BASELINE TABLE
-- Auxiliary mapping table for unifying non-EUR monetary transactions into base EUR.
CREATE OR REPLACE TABLE NOVA_RETAIL_DB.BRONZE.RAW_EXCHANGE_RATES (
    RATE_DATE DATE,
    CURRENCY_CODE VARCHAR(3),
    EXCHANGE_RATE_TO_EUR NUMBER(10,4)
);

-- Baseline exchange rate mappings
INSERT INTO NOVA_RETAIL_DB.BRONZE.RAW_EXCHANGE_RATES (RATE_DATE, CURRENCY_CODE, EXCHANGE_RATE_TO_EUR) VALUES
('2023-01-01', 'USD', 0.9200),
('2023-01-01', 'GBP', 1.1500),
('2023-01-01', 'EUR', 1.0000);
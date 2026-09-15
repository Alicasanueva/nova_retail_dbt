# Nova Retail - Data Platform with KNIME, dbt & Snowflake

This project implements an end-to-end data platform for **Nova Retail**. Data is ingested via **KNIME**, structured using the **Medallion Architecture** (Bronze, Silver, Gold) on **Snowflake**, transformed and tested via **dbt Cloud**, and served for analytics in **Power BI**.

---

## Data Architecture

The data pipeline is structured into four main stages:

1. **Ingestion Layer (KNIME):** ETL workflows ingest raw transactional, web review, and financial target data into Snowflake.
2. **Bronze Layer (Sources):** Raw, immutable ingestion tables (`RAW_SALES_TRANSACTIONS`, `RAW_WEB_REVIEWS`, `RAW_FINANCE_TARGETS`).
3. **Silver Layer (Staging):** Cleaning, data type casting, and deduplication (`stg_sales_transactions`, `stg_web_reviews`, `stg_finance_targets`).
4. **Gold Layer (Core / Star Schema):** Business-ready dimensional model optimized for BI:
   - **Dimensions:** `dim_customers`, `dim_products` (Surrogate keys generated via `dbt_utils`).
   - **Facts:** `fct_sales`, `fct_monthly_targets`.

---

## Data Quality & Testing

Automated tests in dbt enforce data integrity before feeding the reporting layer:
- **Generic Tests:** Validations for `not_null`, `unique`, and referential integrity (`relationships`).
- **Singular Tests:** 
  - `assert_net_amount_matches_discount.sql`: Ensures mathematical accuracy of net sales calculations.
  - `assert_transaction_dates_are_valid.sql`: Validates logical transaction dates.

---

## Tech Stack

- **Data Ingestion / ETL:** KNIME Analytics Platform
- **Data Warehouse:** Snowflake
- **Data Transformation & Testing:** dbt Cloud
- **Version Control:** GitHub
- **Business Intelligence:** Power BI Desktop

---

## 📊 Power BI Integration

The `GOLD` schema in Snowflake feeds Power BI using a star schema design:
- `dim_customers` $\rightarrow$ `fct_sales` (via `customer_key`)
- `dim_products` $\rightarrow$ `fct_sales` (via `product_id`)

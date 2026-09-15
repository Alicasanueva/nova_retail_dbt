# Nova Retail - Data Platform with dbt & Snowflake

This project implements an end-to-end data platform for **Nova Retail** following the **Medallion Architecture** (Bronze, Silver, Gold) on **Snowflake**, transformed and tested using **dbt Cloud**, and prepared for analytical consumption in **Power BI**.

---

## 🏗️ Data Architecture

The data pipeline is structured into three layers:

1. **Bronze (Source Layer):** Raw, immutable ingestion tables (`RAW_SALES_TRANSACTIONS`, `RAW_WEB_REVIEWS`, `RAW_FINANCE_TARGETS`).
2. **Silver (Staging Layer):** Data cleaning, type casting, and initial deduplication (`stg_sales_transactions`, `stg_web_reviews`, `stg_finance_targets`).
3. **Gold (Core / Star Schema):** Business-ready dimensional model optimized for BI analytics:
   - **Dimensions:** `dim_customers`, `dim_products` (Surrogate keys generated via `dbt_utils`).
   - **Facts:** `fct_sales`, `fct_monthly_targets`.

---

## 🧪 Data Quality & Testing

Automated tests are implemented to enforce data integrity:
- **Generic Tests:** Validations for `not_null`, `unique`, and referential integrity (`relationships`).
- **Singular Tests:** 
  - `assert_net_amount_matches_discount.sql`: Ensures mathematical accuracy of net sales calculations.
  - `assert_transaction_dates_are_valid.sql`: Validates that transaction dates are logical and coherent.

---

## 🛠️ Tech Stack

- **Data Warehouse:** Snowflake
- **Data Transformation & Testing:** dbt Cloud
- **Version Control:** GitHub
- **Business Intelligence:** Power BI Desktop

---

## 📊 Power BI Integration

The `GOLD` schema in Snowflake feeds the reporting layer with the following star schema relationships:
- `dim_customers` $\rightarrow$ `fct_sales` (via `customer_key`)
- `dim_products` $\rightarrow$ `fct_sales` (via `product_id`)

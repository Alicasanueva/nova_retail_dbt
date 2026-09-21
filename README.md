# Nova Retail - Enterprise Data Platform (KNIME, dbt Cloud & Snowflake)

An end-to-end, fully automated Data Platform built for **Nova Retail**. This solution ingests multi-currency raw transactional data, applies a **Medallion Architecture (Bronze → Silver → Gold)** on Snowflake using **dbt Cloud**, and serves synchronized executive metrics to **Power BI Service**.

## Tech Stack
- **ETL / Ingestion:** KNIME Analytics Platform
- **Data Warehouse:** Snowflake (`DBT_WH`, `NOVA_RETAIL_DB`, `DBT_ROLE`)
- **Transformation & Orchestration:** dbt Cloud (Production Environment)
- **Version Control:** GitHub
- **Business Intelligence:** Power BI Desktop / Power BI Service

---

## Data Architecture & Pipeline Flow

The platform follows a medallion data processing strategy:

1. **Ingestion Layer (KNIME):** Batch workflows ingest raw transactions, customer interactions, web reviews, financial targets, and exchange rates into Snowflake.
2. **Bronze Layer (Raw):** Immutable, raw target tables (`RAW_SALES_TRANSACTIONS`, `RAW_WEB_REVIEWS`, `RAW_FINANCE_TARGETS`, `RAW_EXCHANGE_RATES`).
3. **Silver Layer (Staging):** Data cleaning, deduplication, timestamp casting, and multi-currency normalization to EUR (`stg_sales_transactions`, `stg_web_reviews`, `stg_finance_targets`, `stg_exchange_rates`).
4. **Gold Layer (Dimensional Star Schema):** Business-ready analytical models optimized for BI reporting:
   - **Dimensions:** `dim_customers`, `dim_products` (surrogate keys via `dbt_utils`).
   - **Fact Tables:** `fct_sales` (normalized revenue/profit metrics in EUR), `fct_monthly_targets`.

---

## Automated Pipeline Orchestration

The daily data pipeline is fully orchestrated and scheduled across 3 automated steps:

| Step | Layer / Tool | Trigger & Schedule | Execution Logic |
| :--- | :--- | :--- | :--- |
| **1. Ingestion** | KNIME Batch & Task Scheduler | Daily at **06:00 AM CEST** | Windows Task Scheduler executes `run_knime_ingestion.bat` to push raw local files into Snowflake Bronze. |
| **2. Transformation** | dbt Cloud | Daily at **04:15 UTC (06:15 AM CEST)** | Production job `Daily Medallion Build` runs `dbt build` (building Silver/Gold and executing data quality tests). |
| **3. BI Refresh** | Power BI Service | Daily at **06:30 AM CEST** | Scheduled semantic model refresh updates the executive dashboard automatically. |

---

## Data Quality & Testing Framework

Automated data testing is enforced in dbt Cloud prior to serving data to Power BI:
- **Generic Tests:** Strict checks for `not_null`, `unique`, and referential integrity (`relationships`).
- **Singular Quality Audits:**
  - `assert_net_amount_matches_discount.sql`: Validates mathematical consistency of net revenue vs discounts applied.
  - `assert_transaction_dates_are_valid.sql`: Guarantees transaction timestamps fall within valid business bounds.

---

## Power BI Executive Dashboard

The Power BI report links directly to the **Gold Schema** in Snowflake following a clean Star Schema:
- Core KPIs reported: **€59.6K Total Revenue**, **100 Orders**, **€16.3K Total Profit**, **€584 AOV**.
- Dynamic navigation features executive views for **Sales Performance** and **Target Achievement**.

---

## Repository Structure

```text
├── 00_raw_data/          # Source CSV/Excel sample files
├── 01_knime/             # KNIME ETL workflows (.knwf) and batch runners (.bat)
├── 02_snowflake_ddl/     # Database setup scripts and DDL definitions
├── 03_power_bi/          # Executive Dashboard (.pbix)
├── 04_docs/              # Final Technical Report (PDF & Word)
├── models/               # dbt SQL models (Staging & Core Gold schemas)
├── tests/                # Custom singular data quality tests
├── macros/               # Custom dbt macros
├── dbt_project.yml       # dbt project configuration
└── packages.yml          # External dbt dependencies (dbt_utils)

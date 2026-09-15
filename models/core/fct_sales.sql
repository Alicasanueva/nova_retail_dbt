with sales as (

    select * from {{ ref('stg_sales_transactions') }}

),

customers as (

    select * from {{ ref('dim_customers') }}

),

products as (

    select * from {{ ref('dim_products') }}

),

rates as (

    select * from {{ ref('stg_exchange_rates') }}

),

final as (

    select
        -- Transaction Primary Key
        sales.order_id,

        -- Foreign Keys linking to Dimensions
        customers.customer_key,
        products.product_id,

        -- Transaction Attributes
        sales.transaction_date,
        sales.product_category,
        sales.currency_code,

        -- Financial Measures (Local Currency)
        sales.unit_price,
        sales.quantity,
        sales.discount_pct,
        sales.net_amount as net_amount_local,

        -- FX Rate & Standardized Financial Measure (EUR)
        coalesce(rates.exchange_rate_to_eur, 1.0000) as fx_rate,
        coalesce((sales.net_amount * coalesce(rates.exchange_rate_to_eur, 1.0000)), 0)::numeric(10,2) as net_amount_eur,

        -- Governance Flags
        sales.is_returned

    from sales
    left join customers
        on lower(sales.customer_email) = lower(customers.customer_email)
    left join products
        on sales.product_id = products.product_id
    left join rates
        on sales.currency_code = rates.currency_code

)

select * from final
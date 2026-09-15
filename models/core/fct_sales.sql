with sales as (

    select * from {{ ref('stg_sales_transactions') }}

),

customers as (

    select * from {{ ref('dim_customers') }}

),

products as (

    select * from {{ ref('dim_products') }}

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

        -- Financial Measures
        sales.unit_price,
        sales.quantity,
        sales.discount_pct,
        sales.net_amount,

        -- Governance Flags
        sales.is_returned

    from sales
    left join customers
        on lower(sales.customer_email) = lower(customers.customer_email)
    left join products
        on sales.product_id = products.product_id

)

select * from final
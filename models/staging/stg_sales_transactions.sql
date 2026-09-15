with source as (

    select * from {{ source('bronze', 'RAW_SALES_TRANSACTIONS') }}

),

renamed_and_cleaned as (

    select
        -- Identifiers
        "order_id"::varchar as order_id,
        "product_id"::varchar as product_id,
        
        -- Customer info extraction ("FullName | Email | Phone")
        split_part("customer_info", '|', 1)::varchar as customer_name,
        trim(split_part("customer_info", '|', 2))::varchar as customer_email,
        trim(split_part("customer_info", '|', 3))::varchar as customer_phone,
        
        -- Product attributes
        "product_category"::varchar as product_category,
        
        -- Currency code extraction based on raw symbol prior to sanitization
        case 
            when contains("price", '$') then 'USD'
            when contains("price", '£') then 'GBP'
            else 'EUR'
        end as currency_code,

        -- Unit price sanitization (stripping $, €, £, commas, and whitespace)
        try_cast(
            regexp_replace("price", '[$,£,€, ]', '') 
            as numeric(10,2)
        ) as unit_price,
        
        -- Quantity (preserves negative values for return tracking)
        try_cast("qty" as integer) as quantity,

        -- Discount parsing (handles string percentages, decimals, 'N/A', and nulls safely)
        case 
            when "discount_pct" is null or "discount_pct" in ('N/A', 'null', '') 
                then 0.0000
            when contains("discount_pct", '%') 
                then (try_cast(regexp_replace("discount_pct", '[%, ]', '') as numeric(10,2)) / 100.0)::numeric(10,4)
            else try_cast("discount_pct" as numeric(10,4))
        end as discount_pct,

        -- Transaction date parsing (handles 'Today', null strings, and multi-format strings)
        case 
            when lower("transaction_date") = 'today' then current_date()
            when "transaction_date" in ('null', 'NULL', '') or "transaction_date" is null then null
            else coalesce(
                try_to_date("transaction_date", 'YYYY-MM-DD'),
                try_to_date("transaction_date", 'YYYY/MM/DD'),
                try_to_date("transaction_date", 'DD/MM/YYYY'),
                try_to_date("transaction_date", 'MM/DD/YYYY'),
                try_to_date("transaction_date", 'DD-Mon-YYYY')
            )
        end as transaction_date

    from source

)

select 
    order_id,
    product_id,
    customer_name,
    customer_email,
    customer_phone,
    product_category,
    currency_code,
    unit_price,
    quantity,
    discount_pct,
    transaction_date,
    -- Return indicator flag
    (quantity < 0) as is_returned,
    -- Calculated net revenue (negative quantities decrease overall revenue)
    coalesce((unit_price * quantity * (1 - coalesce(discount_pct, 0))), 0)::numeric(10,2) as net_amount
from renamed_and_cleaned
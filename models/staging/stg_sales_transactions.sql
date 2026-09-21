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

),

with_fx as (

    select
        r.*,
        coalesce(fx.exchange_rate_to_eur, 1.0000) as fx_rate,
        
        -- Return indicator flag
        (r.quantity < 0) as is_returned,

        -- Net amount in original currency
        coalesce((r.unit_price * r.quantity * (1 - coalesce(r.discount_pct, 0))), 0)::numeric(10,2) as net_amount,

        -- Net amount calculated in Base EUR
        coalesce((r.unit_price * r.quantity * (1 - coalesce(r.discount_pct, 0))) * coalesce(fx.exchange_rate_to_eur, 1.0000), 0)::numeric(10,2) as net_amount_eur

    from renamed_and_cleaned r
    left join {{ ref('stg_exchange_rates') }} fx
        on r.currency_code = fx.currency_code

)

select * from with_fx
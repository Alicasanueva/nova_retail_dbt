with sales_customers as (

    select
        customer_email,
        customer_name,
        customer_phone,
        null as country_code,
        null as city
    from {{ ref('stg_sales_transactions') }}
    where customer_email is not null

),

web_customers as (

    select
        customer_email,
        customer_name,
        null as customer_phone,
        country_code,
        city
    from {{ ref('stg_web_reviews') }}
    where customer_email is not null

),

all_customers as (

    select * from sales_customers
    union all
    select * from web_customers

),

deduplicated_customers as (

    select
        -- Surrogate Key generated via official dbt_utils macro
        {{ dbt_utils.generate_surrogate_key(['lower(customer_email)']) }} as customer_key,
        customer_email,
        
        -- Coalesce attributes across source systems
        max(customer_name)  as customer_name,
        max(customer_phone) as customer_phone,
        max(country_code)   as country_code,
        max(city)           as city

    from all_customers
    group by 1, 2

)

select * from deduplicated_customers
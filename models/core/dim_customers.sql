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

),

final as (

    select
        customer_key,
        customer_email,
        customer_name,
        customer_phone,
        country_code,
        city,
        
        -- Derived Region Mapping logic
        case 
            when upper(country_code) in ('US', 'USA', 'CA', 'CAN', 'MX', 'MEX') then 'NA'
            when upper(country_code) in ('ES', 'ESP', 'DE', 'DEU', 'UK', 'GBR', 'FR', 'FRA', 'IT', 'ITA') then 'EMEA'
            when upper(country_code) in ('JP', 'JPN', 'AU', 'AUS', 'CN', 'CHN', 'IN', 'IND') then 'APAC'
            when upper(country_code) in ('BR', 'BRA', 'AR', 'ARG', 'CL', 'CHL', 'CO', 'COL') then 'LATAM'
            else 'EMEA' -- Default fallback
        end as region

    from deduplicated_customers

)

select * from final
with sales_customers as (

    select
        lower(trim(customer_email)) as customer_email,
        customer_name,
        customer_phone
    from {{ ref('stg_sales_transactions') }}
    where customer_email is not null

),

-- 1. Deduplicate basic customer attributes from sales transactions
dedup_sales_customers as (

    select
        customer_email,
        max(customer_name)  as customer_name,
        max(customer_phone) as customer_phone
    from sales_customers
    group by 1

),

-- 2. Extract the latest known location per customer based on review history
latest_web_location as (

    select
        lower(trim(customer_email)) as customer_email,
        country_code,
        city,
        row_number() over (
            partition by lower(trim(customer_email))
            order by review_id desc
        ) as rn
    from {{ ref('stg_web_reviews') }}
    where customer_email is not null

),

customer_location as (

    select
        customer_email,
        country_code,
        city
    from latest_web_location
    where rn = 1

),

-- 3. Join customer master data with latest location and derive regional mapping
final_customers as (

    select
        {{ dbt_utils.generate_surrogate_key(['s.customer_email']) }} as customer_key,
        s.customer_email,
        s.customer_name,
        s.customer_phone,
        coalesce(l.country_code, 'UNKNOWN') as country_code,
        coalesce(l.city, 'UNKNOWN') as city,
        
        -- Regional mapping logic supporting all 4 operating regions
        case 
            when upper(l.country_code) in ('US', 'USA', 'CA', 'CAN') then 'NA'
            when upper(l.country_code) in ('ES', 'ESP', 'DE', 'DEU', 'UK', 'GB', 'GBR', 'FR', 'FRA', 'IT', 'ITA') then 'EMEA'
            when upper(l.country_code) in ('JP', 'JPN', 'AU', 'AUS', 'CN', 'CHN', 'IN', 'IND') then 'APAC'
            when upper(l.country_code) in ('BR', 'BRA', 'AR', 'ARG', 'CL', 'CHL', 'CO', 'COL', 'MX', 'MEX') then 'LATAM'
            else 'EMEA' -- Default fallback
        end as region

    from dedup_sales_customers s
    left join customer_location l
        on s.customer_email = l.customer_email

)

select * from final_customers
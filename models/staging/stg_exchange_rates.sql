with source as (

    select * from {{ source('bronze', 'RAW_EXCHANGE_RATES') }}

),

renamed as (

    select
        -- Date casting
        rate_date::date as rate_date,
        
        -- ISO currency code standardization
        upper(currency_code)::varchar as currency_code,
        
        -- FX conversion multiplier to base currency (EUR)
        exchange_rate_to_eur::numeric(10,4) as exchange_rate_to_eur

    from source

)

select * from renamed
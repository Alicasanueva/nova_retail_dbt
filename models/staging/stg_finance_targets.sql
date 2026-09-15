with source as (

    select * from {{ source('bronze', 'RAW_FINANCE_TARGETS') }}

),

unpivoted as (

    select 
        -- Attributes
        "Region"::varchar   as region,
        "Category"::varchar as product_category,
        
        -- Unpivoted month string & numeric amount
        target_month_str,
        target_amount

    from source
    unpivot (
        target_amount for target_month_str in (
            "Jan-23", "Feb-23", "Mar-23", "Apr-23", "May-23", "Jun-23",
            "Jul-23", "Aug-23", "Sep-23", "Oct-23", "Nov-23", "Dec-23"
        )
    )

),

renamed_and_cleaned as (

    select
        region,
        product_category,
        
        -- Convert month string (e.g., 'Jan-23') into standard DATE ('2023-01-01')
        try_to_date(target_month_str, 'Mon-YY') as target_month,
        
        -- Financial measure
        target_amount::numeric(12,2) as target_amount

    from unpivoted

)

select * from renamed_and_cleaned
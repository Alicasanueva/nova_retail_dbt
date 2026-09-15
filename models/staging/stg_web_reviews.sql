with source as (

    select * from {{ source('bronze', 'RAW_WEB_REVIEWS') }}

),

renamed_and_cleaned as (

    select
        -- Identifiers
        "review_id"::varchar as review_id,
        "product_ref"::varchar as product_id,
        
        -- User metadata extracted from raw JSON
        "name"::varchar as customer_name,
        "email"::varchar as customer_email,
        "country"::varchar as country_code,
        "city"::varchar as city,

        -- UNIX timestamp parsing (handles both seconds and milliseconds epoch formats)
        to_timestamp_ntz(
            case 
                when try_cast("timestamp" as bigint) > 100000000000 
                    then try_cast("timestamp" as bigint) / 1000
                else try_cast("timestamp" as bigint)
            end
        ) as review_datetime,

        -- Rating validation (enforces 1-5 star bounds, coerces invalid/string values to NULL)
        case 
            when try_cast("rating" as integer) between 1 and 5 
                then try_cast("rating" as integer)
            else null 
        end as rating,

        -- Review text content
        "review_text"::varchar as review_text

    from source

)

select * from renamed_and_cleaned
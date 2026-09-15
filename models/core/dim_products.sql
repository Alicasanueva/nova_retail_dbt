with products as (

    select
        product_id,
        product_category,
        max(unit_price) as list_price
    from {{ ref('stg_sales_transactions') }}
    where product_id is not null
    group by 1, 2

),

renamed as (

    select
        -- Primary Key
        product_id,
        
        -- Product Attributes
        product_category,
        list_price

    from products

)

select * from renamed
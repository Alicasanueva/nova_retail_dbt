with targets as (

    select * from {{ ref('stg_finance_targets') }}

),

final as (

    select
        -- Primary Key Hash using dbt_utils
        {{ dbt_utils.generate_surrogate_key(['region', 'product_category', 'target_month']) }} as target_key,

        -- Dimensions & Attributes
        region,
        product_category,
        target_month,

        -- Target Measure
        target_amount

    from targets

)

select * from final
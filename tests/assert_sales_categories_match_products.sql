-- Singular Test: Ensures product category in sales matches the master catalog category.
-- Returns mismatched records (if 0 rows returned, test PASSES).

select
    sales.order_id,
    sales.product_id,
    sales.product_category as sales_category,
    products.product_category as catalog_category
from {{ ref('fct_sales') }} as sales
inner join {{ ref('dim_products') }} as products
    on sales.product_id = products.product_id
where sales.product_category <> products.product_category
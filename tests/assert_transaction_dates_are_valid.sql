-- Singular Test: Ensures transaction dates are not set in the future.
-- Returns invalid records (if 0 rows returned, test PASSES).

select
    order_id,
    transaction_date
from {{ ref('fct_sales') }}
where transaction_date > current_date()
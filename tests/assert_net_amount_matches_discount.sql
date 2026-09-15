-- Singular Test: Ensures net_amount never exceeds gross revenue for non-returned orders.
-- Returns records that violate business logic (if 0 rows returned, test PASSES).

select
    order_id,
    unit_price,
    quantity,
    discount_pct,
    net_amount,
    (unit_price * quantity) as gross_amount
from {{ ref('fct_sales') }}
where is_returned = false
  and net_amount > (unit_price * quantity)
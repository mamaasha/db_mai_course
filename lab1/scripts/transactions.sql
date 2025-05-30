
BEGIN;
    UPDATE sales
    SET units_sold = units_sold + 1,
        total_revenue = (units_sold + 1) * unit_price
    WHERE order_id = 443368995;
COMMIT;


BEGIN;
    UPDATE sales
    SET units_sold = units_sold + 10
    WHERE order_id = 443368995;
    SELECT 1/0;
ROLLBACK;

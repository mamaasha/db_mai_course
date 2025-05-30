\timing

--  БЕЗ индексов
SELECT COUNT(*) FROM sales
WHERE order_date BETWEEN '2015-01-01' AND '2015-12-31';

EXPLAIN ANALYZE
SELECT COUNT(*) FROM sales
WHERE order_date BETWEEN '2015-01-01' AND '2015-12-31';

--  B-tree 
CREATE INDEX idx_sales_order_date ON sales(order_date);

SELECT COUNT(*) FROM sales
WHERE order_date BETWEEN '2015-01-01' AND '2015-12-31';
EXPLAIN ANALYZE
SELECT COUNT(*) FROM sales
WHERE order_date BETWEEN '2015-01-01' AND '2015-12-31';

-- BRIN
CREATE INDEX idx_sales_brin_order_date ON sales
  USING BRIN(order_date);

-- GIN + pg_trgm
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX idx_sales_item_type_trgm
  ON sales USING GIN (item_type gin_trgm_ops);

EXPLAIN ANALYZE
SELECT * FROM sales
WHERE similarity(item_type,'fruit')>0.3
ORDER BY similarity(item_type,'fruit') DESC
LIMIT 10;

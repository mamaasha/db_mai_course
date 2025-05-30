CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS pg_bigm;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

\timing on

-- без индекса
SELECT COUNT(*) FROM sales
    WHERE item_type ILIKE '%fruit%';
EXPLAIN ANALYZE
SELECT COUNT(*) FROM sales
    WHERE item_type ILIKE '%fruit%';

-- pg_trgm 
CREATE INDEX IF NOT EXISTS idx_sales_item_type_trgm
    ON sales USING GIN (item_type gin_trgm_ops);
SELECT COUNT(*) FROM sales
    WHERE similarity(item_type,'fruit')>0.3;
EXPLAIN ANALYZE
SELECT COUNT(*) FROM sales
    WHERE similarity(item_type,'fruit')>0.3;

-- pg_bigm
CREATE INDEX IF NOT EXISTS idx_sales_item_type_bigm
    ON sales USING GIN (item_type gin_bigm_ops);
SELECT COUNT(*) FROM sales
    WHERE item_type LIKE '%fruit%';
EXPLAIN ANALYZE
SELECT COUNT(*) FROM sales
    WHERE item_type LIKE '%fruit%';


-- SHA-256
SELECT order_id,
        encode(digest(order_id::text,'sha256'),'hex') AS order_hash
    FROM sales
LIMIT 5;

-- Симметричное
SELECT order_id,
        pgp_sym_encrypt(order_id::text,'secret') AS encrypted,
        pgp_sym_decrypt(
        pgp_sym_encrypt(order_id::text,'secret'),
        'secret'
        )::text AS decrypted
    FROM sales
LIMIT 5;

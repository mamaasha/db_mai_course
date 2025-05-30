CREATE TABLE IF NOT EXISTS sales (
    region            VARCHAR(64),
    country           VARCHAR(64),
    item_type         VARCHAR(64),
    sales_channel     VARCHAR(16),
    order_priority    CHAR(1),
    order_date        DATE,
    order_id          BIGINT PRIMARY KEY,
    ship_date         DATE,
    units_sold        INTEGER,
    unit_price        NUMERIC,
    unit_cost         NUMERIC,
    total_revenue     NUMERIC,
    total_cost        NUMERIC,
    total_profit      NUMERIC
);

COPY sales FROM '/docker-entrypoint-initdb.d/sales.csv' DELIMITER ',' CSV HEADER;

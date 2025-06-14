# Отчёт по эксперименту с индексами в PostgreSQL

**Датасет:** продажи из разных регионов (5 млн строк)  

---

## 1. Индексы

| Индекс             | Planning Time | Execution Time |
| ------------------ | ------------: | -------------: |
| **Без индекса**    |      0.100 ms |      31.554 ms |
| **B-tree**         |      0.109 ms |       7.898 ms |
| **BRIN**           |      0.090 ms |       6.727 ms |
| **GIN + pg\_trgm** |      0.786 ms |     203.981 ms |

> **Замечания:**
>
> * После **B-tree** и **BRIN** время выполнения упало в 4–5 раз.
> * **BRIN** чуть быстрее B-tree
> * **GIN + pg\_trgm** демонстрирует медленное выполнение для данного запроса

---


* **B-tree**
  при частых диапазонных и точных запросах по дате, числам, ключам

* **BRIN**
  для «архивных» таблиц с миллионами строк, где порядок данных важен (например, логи) - необходимо, чтоб значения были примерно упорядочены

* **GIN**
  для похожих текстовые запросы (`SIMILARITY()`, `LIKE '%...%'`), полнотекстовый поиск



## Вывод GIN + pg\_trgm


| region              | country   | item\_type | units\_sold | total\_profit |
| ------------------- | --------- | ---------- | ----------: | ------------: |
| Asia                | Sri Lanka | Fruits     |        1379 |       3323.39 |
| Asia                | Taiwan    | Fruits     |        8034 |      19361.94 |
| Australia & Oceania | Vanuatu   | Fruits     |        5735 |      13821.35 |
| …                   | …         | …          |           … |             … |

---


# 2. Транзакции

Делала 2: корркетную и с ошибкой

* **Результат 1 (COMMIT):**

  * Обновлена 1 запись
  * Значения в `units_sold` и `total_revenue` изменены
  * UPDATE → 1.262 ms
  * COMMIT → 12.468 ms

* **Результат 2 (ROLLBACK):**

  * Возникла ошибка `division by zero`
  * Все изменения отменены


## Уровни изоляции и аномалии

### Read Committed

каждая операция SELECT видит только те данные, которые уже закоммичены другими

1. **Сессия A**:

   ```sql
   \timing on
   BEGIN;
     SELECT COUNT(*) FROM sales
     WHERE order_date BETWEEN '2015-01-01' AND '2015-12-31';
   -- 65867 записей (Time: ~6.5 ms)
   ```

2. **Сессия B**:

   ```sql
   INSERT INTO sales (
     region, country, item_type, sales_channel, order_priority,
     order_date, order_id, ship_date, units_sold,
     unit_price, unit_cost, total_revenue, total_cost, total_profit
   ) VALUES (
     'Test','Test','Fruits','Online','M',
     '2015-06-15',999999999,'2015-06-20',100,
     9.33,6.92,933,692,241
   );
   COMMIT;
   -- INSERT 0 1 (Time: ~4.8 ms)
   ```

3. **Сессия A**:

   ```sql
     SELECT COUNT(*) FROM sales
     WHERE order_date BETWEEN '2015-01-01' AND '2015-12-31';
   --  65868 записей (Time: ~6.6 ms)
   COMMIT;
   ```
---

### Repeatable Read

транзакция «фиксирует» снимок данных при первом чтении и не видит изменений, закоммиченных после её начала

1. **Сессия A**:

   ```sql
   BEGIN;
   SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
     SELECT COUNT(*) FROM sales
     WHERE order_date BETWEEN '2015-01-01' AND '2015-12-31';
   --  65868 записей (Time: ~5.4 ms)
   ```

2. **Сессия B** (тот же INSERT)

3. **Сессия A** (та же):

   ```sql
   --  65868 записей (Time: ~5.5 ms)
   ```

* **Read Committed** позволяет «фантомные» строки (новые данные видны сразу)
* **Repeatable Read** обеспечивает стабильность результатов внутри одной транзакции (нет phantom reads, счетчик неизменный)


# Расширения pg_trgm, pg_bigm и pgcrypto

Как же я долго ждала сборку pg\_bigm...

| Расширение                         | Время выполнения |
|------------------------------------|-----------------:|
| **Без индекса**                    |        15.423 ms |
| **Без индекса (EXPLAIN ANALYZE)**  |         0.450 ms |
| **pg_trgm + GIN (SELECT)**         |         1.580 ms |
| **pg_trgm + GIN (EXPLAIN ANALYZE)**|         0.931 ms |
| **pg_bigm + GIN (SELECT)**         |         1.259 ms |
| **pg_bigm + GIN (EXPLAIN ANALYZE)**|         0.630 ms |
| **pgcrypto (SHA-256)**             |         1.548 ms |
| **pgcrypto (SymmetricEnc)**        |         1.645 ms |

> **Примечания:**  
> - `pg_bigm` требует установки в контейнере
> - `pg_trgm` и `pg_bigm` заметно ускоряют поиск по тексту: с ~15 ms до ~1 ms
> - `pgcrypto` встроенное шифрование и хеширование

### SHA-256 хеширование

  | order\_id | hash      |
  | --------- | --------- |
  | 830192887 | a3f1…e5c4 |
  | 732588374 | 4b2d…a9f7 |
  | …         | …         |

### Симметричное шифрование

  | order\_id | encrypted (bytea) | decrypted |
  | --------- | ----------------- | --------- |
  | 830192887 | \x….              | 830192887 |
  | 732588374 | \x….              | 732588374 |

---


| Расширение   | Плюсы                                                            | Минусы                                                 |
| ------------ | ---------------------------------------------------------------- | ------------------------------------------------------ |
| **pg\_trgm** | • Очень быстрый fuzzy-поиск<br>• Хорош для опечаток              | • Индекс большой<br>• Замедляет планирование           |
| **pg\_bigm** | • Эффективен для поиска substrings<br>• Меньше индекса, чем trgm | • Менее гибкий, чем триграммы                          |
| **pgcrypto** | • Встроенное шифрование и хеширование<br>• Повышает безопасность | • Нужно управлять ключами |



ПРИМЕР ДАННЫХ 
| Region | Country | Item Type | Sales Channel | Order Priority | Order Date | Order ID | Ship Date | Units Sold | Unit Price | Unit Cost | Total Revenue | Total Cost | Total Profit |
|--------|---------|-----------|---------------|----------------|------------|----------|-----------|------------|------------|-----------|---------------|------------|--------------|
| Sub-Saharan Africa | South Africa | Fruits | Offline | M | 7/27/2012 | 443368995 | 7/28/2012 | 1593 | 9.33 | 6.92 | 14862.69 | 11023.56 | 3839.13 |
| Middle East and North Africa | Morocco | Clothes | Online | M | 9/14/2013 | 667593514 | 10/19/2013 | 4611 | 109.28 | 35.84 | 503890.08 | 165258.24 | 338631.84 |
| Australia and Oceania | Papua New Guinea | Meat | Offline | M | 5/15/2015 | 940995585 | 6/4/2015 | 360 | 421.89 | 364.69 | 151880.40 | 131288.40 | 20592.00 |

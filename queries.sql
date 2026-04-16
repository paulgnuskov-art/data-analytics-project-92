-- Шаг 4. Общее количество покупателей.
SELECT COUNT(customer_id) AS customers_count
FROM customers;

-- Шаг 5. Отчет с продавцами у которых наибольшая выручка.
SELECT
    TRIM(
        CONCAT(e.first_name, ' ', e.last_name)
    ) AS seller,
    COUNT(*) AS operations,
    FLOOR(SUM(p.price * s.quantity))::bigint AS income
FROM sales AS s
INNER JOIN employees AS e
    ON s.sales_person_id = e.employee_id
INNER JOIN products AS p
    ON s.product_id = p.product_id
GROUP BY
    e.employee_id,
    e.first_name,
    e.last_name
ORDER BY
    income DESC,
    seller ASC
LIMIT 10;

--ШАГ 5. Отчет с продавцами, чья выручка ниже средней выручки всех продавцов.
WITH seller_avg AS (
    SELECT
        TRIM(
            CONCAT(e.first_name, ' ', e.last_name)
        ) AS seller,
        AVG(p.price * s.quantity) AS avg_income
    FROM sales AS s
    INNER JOIN employees AS e
        ON s.sales_person_id = e.employee_id
    INNER JOIN products AS p
        ON s.product_id = p.product_id
    GROUP BY
        e.employee_id,
        e.first_name,
        e.last_name
),

company_avg AS (
    SELECT AVG(p.price * s.quantity) AS avg_income
    FROM sales AS s
    INNER JOIN products AS p
        ON s.product_id = p.product_id
)

SELECT
    sa.seller,
    FLOOR(sa.avg_income)::bigint AS average_income
FROM seller_avg AS sa
CROSS JOIN company_avg AS ca
WHERE sa.avg_income < ca.avg_income
ORDER BY
    average_income ASC,
    sa.seller ASC;

-- Шаг 5. Отчет с данными по выручке по каждому продавцу и дню недели.
SELECT
    TRIM(
        CONCAT(e.first_name, ' ', e.last_name)
    ) AS seller,
    CASE EXTRACT(ISODOW FROM s.sale_date)
        WHEN 1 THEN 'monday'
        WHEN 2 THEN 'tuesday'
        WHEN 3 THEN 'wednesday'
        WHEN 4 THEN 'thursday'
        WHEN 5 THEN 'friday'
        WHEN 6 THEN 'saturday'
        WHEN 7 THEN 'sunday'
    END AS day_of_week,
    FLOOR(SUM(p.price * s.quantity))::bigint AS income
FROM sales AS s
INNER JOIN employees AS e
    ON s.sales_person_id = e.employee_id
INNER JOIN products AS p
    ON s.product_id = p.product_id
GROUP BY
    e.employee_id,
    e.first_name,
    e.last_name,
    EXTRACT(ISODOW FROM s.sale_date)
ORDER BY
    EXTRACT(ISODOW FROM s.sale_date) ASC,
    seller ASC;

-- Шаг 6. Количество покупателей в разных возрастных группах.
SELECT
    CASE
        WHEN age BETWEEN 16 AND 25 THEN '16-25'
        WHEN age BETWEEN 26 AND 40 THEN '26-40'
        ELSE '40+'
    END AS age_category,
    COUNT(*) AS age_count
FROM customers
WHERE age >= 16
GROUP BY
    age_category
ORDER BY
    age_category ASC;

-- Шаг 6. Данные по количеству уникальных покупателей и выручке.
SELECT
    TO_CHAR(s.sale_date, 'YYYY-MM') AS selling_month,
    COUNT(DISTINCT s.customer_id) AS total_customers,
    FLOOR(SUM(p.price * s.quantity))::bigint AS income
FROM sales AS s
INNER JOIN products AS p
    ON s.product_id = p.product_id
GROUP BY
    selling_month
ORDER BY
    selling_month ASC;

-- Шаг 6. Покупатели, первая покупка которых была в ходе проведения акций.
SELECT
    fs.sale_date,
    TRIM(
        CONCAT(c.first_name, ' ', c.last_name)
    ) AS customer,
    TRIM(
        CONCAT(e.first_name, ' ', e.last_name)
    ) AS seller
FROM (
    SELECT DISTINCT ON (s.customer_id)
        s.customer_id,
        s.sale_date,
        s.sales_person_id,
        s.product_id
    FROM sales AS s
    ORDER BY
        s.customer_id ASC,
        s.sale_date ASC,
        s.sales_id ASC
) AS fs
INNER JOIN customers AS c
    ON fs.customer_id = c.customer_id
INNER JOIN employees AS e
    ON fs.sales_person_id = e.employee_id
INNER JOIN products AS p
    ON fs.product_id = p.product_id
WHERE p.price = 0
ORDER BY
    c.customer_id ASC;

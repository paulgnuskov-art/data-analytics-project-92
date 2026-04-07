--ШАГ № 4 запрос, который считает общее количество покупателей из таблицы customers.
SELECT
    COUNT(customer_id) AS customers_count
FROM customers;
--ШАГ № 5 ЗАДАЧА отчет с продавцами у которых наибольшая выручка.
WITH sales_enriched AS (
    SELECT
        TRIM(CONCAT(e.first_name, ' ', e.last_name)) AS seller,
        s.sales_id,
        p.price * s.quantity AS line_income
    FROM sales AS s
    INNER JOIN employees AS e
        ON s.sales_person_id = e.employee_id
    INNER JOIN products AS p
        ON s.product_id = p.product_id
)

SELECT
    se.seller,
    COUNT(se.sales_id) AS operations,
    FLOOR(SUM(se.line_income))::bigint AS income
FROM sales_enriched AS se
GROUP BY
    se.seller
ORDER BY
    income DESC,
    se.seller ASC
LIMIT 10;

--Шаг № 5 отчет с продавцами, чья выручка ниже средней выручки всех продавцов.
WITH sales_enriched AS (
    SELECT
        TRIM(CONCAT(e.first_name, ' ', e.last_name)) AS seller,
        p.price * s.quantity AS line_income
    FROM sales AS s
    INNER JOIN employees AS e
        ON s.sales_person_id = e.employee_id
    INNER JOIN products AS p
        ON s.product_id = p.product_id
),
seller_avg AS (
    SELECT
        se.seller,
        AVG(se.line_income) AS avg_income
    FROM sales_enriched AS se
    GROUP BY
        se.seller
),
global_avg AS (
    SELECT
        AVG(se.line_income) AS avg_income
    FROM sales_enriched AS se
)

SELECT
    sa.seller,
    FLOOR(sa.avg_income)::bigint AS average_income
FROM seller_avg AS sa
CROSS JOIN global_avg AS ga
WHERE sa.avg_income < ga.avg_income
ORDER BY
    average_income ASC,
    sa.seller ASC;

--Шаг № 5 отчет с данными по выручке по каждому продавцу и дню недели.
WITH weekday_sales AS (
    SELECT
        TRIM(CONCAT(e.first_name, ' ', e.last_name)) AS seller,
        EXTRACT(ISODOW FROM s.sale_date)::int AS day_num,
        p.price * s.quantity AS line_income
    FROM sales AS s
    INNER JOIN employees AS e
        ON s.sales_person_id = e.employee_id
    INNER JOIN products AS p
        ON s.product_id = p.product_id
),
seller_weekday_income AS (
    SELECT
        ws.seller,
        ws.day_num,
        FLOOR(SUM(ws.line_income))::bigint AS income
    FROM weekday_sales AS ws
    GROUP BY
        ws.seller,
        ws.day_num
),
weekday_report AS (
    SELECT
        swi.seller,
        swi.day_num,
        CASE swi.day_num
            WHEN 1 THEN 'monday'
            WHEN 2 THEN 'tuesday'
            WHEN 3 THEN 'wednesday'
            WHEN 4 THEN 'thursday'
            WHEN 5 THEN 'friday'
            WHEN 6 THEN 'saturday'
            WHEN 7 THEN 'sunday'
        END AS day_of_week,
        swi.income
    FROM seller_weekday_income AS swi
)

SELECT
    wr.seller,
    wr.day_of_week,
    wr.income
FROM weekday_report AS wr
ORDER BY
    wr.day_num ASC,
    wr.seller ASC;
--ШАГ 6 отчет с возрастными группами покупателей.
WITH age_groups_base AS (
    SELECT
        CASE
            WHEN age BETWEEN 16 AND 25 THEN '16-25'
            WHEN age BETWEEN 26 AND 40 THEN '26-40'
            ELSE '40+'
        END AS age_category
    FROM customers
    WHERE age >= 16
)

SELECT
    agb.age_category,
    COUNT(*) AS age_count
FROM age_groups_base AS agb
GROUP BY
    agb.age_category
ORDER BY
    agb.age_category ASC;
--ШАГ 6 данные по количеству уникальных покупателей и выручке, которую они принесли по месяцам.
WITH monthly_sales AS (
    SELECT
        TO_CHAR(s.sale_date, 'YYYY-MM') AS selling_month,
        s.customer_id,
        p.price * s.quantity AS line_income
    FROM sales AS s
    INNER JOIN products AS p
        ON s.product_id = p.product_id
)

SELECT
    ms.selling_month,
    COUNT(DISTINCT ms.customer_id) AS total_customers,
    FLOOR(SUM(ms.line_income))::bigint AS income
FROM monthly_sales AS ms
GROUP BY
    ms.selling_month
ORDER BY
    ms.selling_month ASC;

--ШАГ 6 отчет о покупателях, первая покупка которых была в ходе проведения акций.
WITH ranked_sales AS (
    SELECT
        s.customer_id,
        s.sale_date,
        s.sales_person_id,
        s.product_id,
        ROW_NUMBER() OVER (
            PARTITION BY s.customer_id
            ORDER BY
                s.sale_date ASC,
                s.sales_id ASC
        ) AS rn
    FROM sales AS s
),
first_sales AS (
    SELECT
        rs.customer_id,
        rs.sale_date,
        rs.sales_person_id,
        rs.product_id
    FROM ranked_sales AS rs
    WHERE rs.rn = 1
),
special_offer_report AS (
    SELECT
        TRIM(CONCAT(c.first_name, ' ', c.last_name)) AS customer,
        fs.sale_date,
        TRIM(CONCAT(e.first_name, ' ', e.last_name)) AS seller,
        c.customer_id
    FROM first_sales AS fs
    INNER JOIN customers AS c
        ON fs.customer_id = c.customer_id
    INNER JOIN employees AS e
        ON fs.sales_person_id = e.employee_id
    INNER JOIN products AS p
        ON fs.product_id = p.product_id
    WHERE p.price = 0
)

SELECT
    sor.customer,
    sor.sale_date,
    sor.seller
FROM special_offer_report AS sor
ORDER BY
    sor.customer_id ASC;

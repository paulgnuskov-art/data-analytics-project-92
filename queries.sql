--ШАГ № 4 запрос, который считает общее количество покупателей из таблицы customers.
SELECT COUNT(customer_id) AS customers_count FROM customers;
--ШАГ № 5  отчет с продавцами у которых наибольшая выручка.
SELECT
    TRIM(CONCAT(e.first_name, ' ', e.last_name)) AS seller,
    COUNT(s.sales_id) AS operations,
    FLOOR(SUM(p.price * s.quantity))::bigint AS income
FROM sales s
JOIN employees e ON e.employee_id = s.sales_person_id
JOIN products p ON p.product_id = s.product_id
GROUP BY e.employee_id, e.first_name, e.last_name
ORDER BY income DESC, seller
LIMIT 10;
--Шаг № 5 отчет с продавцами, чья выручка ниже средней выручки всех продавцов.
WITH seller_avg AS (
    SELECT
        e.employee_id,
        TRIM(CONCAT(e.first_name, ' ', e.last_name)) AS seller,
        AVG(p.price * s.quantity) AS avg_income
    FROM sales s
    JOIN employees e ON e.employee_id = s.sales_person_id
    JOIN products p ON p.product_id = s.product_id
    GROUP BY e.employee_id, e.first_name, e.last_name
),
global_avg AS (
    SELECT AVG(p.price * s.quantity) AS avg_income
    FROM sales s
    JOIN products p ON p.product_id = s.product_id
)
SELECT
    sa.seller,
    FLOOR(sa.avg_income)::int AS average_income
FROM seller_avg sa
CROSS JOIN global_avg ga
WHERE sa.avg_income < ga.avg_income
ORDER BY average_income ASC, seller;
--Шаг № 5 отчет с данными по выручке по каждому продавцу и дню недели.
SELECT
    seller,
    CASE day_num
        WHEN 1 THEN 'monday'
        WHEN 2 THEN 'tuesday'
        WHEN 3 THEN 'wednesday'
        WHEN 4 THEN 'thursday'
        WHEN 5 THEN 'friday'
        WHEN 6 THEN 'saturday'
        WHEN 7 THEN 'sunday'
    END AS day_of_week,
    income
FROM (
    SELECT
        TRIM(CONCAT(e.first_name, ' ', e.last_name)) AS seller,
        EXTRACT(ISODOW FROM s.sale_date)::int AS day_num,
        FLOOR(SUM(p.price * s.quantity))::int AS income
    FROM sales s
    JOIN employees e ON e.employee_id = s.sales_person_id
    JOIN products p ON p.product_id = s.product_id
    GROUP BY
        e.employee_id,
        e.first_name,
        e.last_name,
        EXTRACT(ISODOW FROM s.sale_date)
) t
ORDER BY day_num, seller;

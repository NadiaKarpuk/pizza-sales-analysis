--task 1. 
--Загальні показники за рік: виручка, кількість замовлень, кількість проданих піц, 
--середній чек, середня кількість піц у замовленні.Кількість піц рахуйте з урахуванням quantity.
SELECT 
	SUM(p.price * od.quantity) AS total_revenue,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(od.quantity) AS total_pizzas_sold,
    CAST(SUM(p.price * od.quantity) / COUNT(DISTINCT o.order_id) AS DECIMAL(10, 2)) AS average_order_value,
    CAST(SUM(od.quantity) / COUNT(DISTINCT o.order_id) AS DECIMAL(10, 2)) AS average_pizzas_per_order
FROM orders o 
JOIN order_details AS od ON o.order_id = od.order_id
JOIN pizzas AS p ON od.pizza_id = p.pizza_id
WHERE o.date >= '2015-01-01' AND o.date <= '2015-12-31';
-- Дані загальних показників за рік: виручка -81 7860.05, кількість замовлень - 2150, 
-- кількість проданих піц - 49 574, середній чек - 38.31, середня кількість піц у замовленні=2

--task 2.
--Динаміка по місяцях: виручка і кількість замовлень. 
--Який місяць найсильніший, а який найслабший? ★ Зміна до попереднього місяця у відсотках.
WITH monthly_metrics AS (
    SELECT 
        strftime('%m', o.date) AS month,
        ROUND(SUM(p.price * od.quantity), 2) AS total_revenue,
        COUNT(DISTINCT o.order_id) AS total_orders
    FROM orders o
    JOIN order_details od ON o.order_id = od.order_id
    JOIN pizzas p ON od.pizza_id = p.pizza_id
    WHERE o.date BETWEEN '2015-01-01' AND '2015-12-31'
    GROUP BY month
)
SELECT 
    month,
    total_revenue,
    total_orders,
    ROUND(
        (total_revenue - LAG(total_revenue) OVER (ORDER BY month)) 
        / LAG(total_revenue) OVER (ORDER BY month) * 100, 
        2
    ) AS revenue_change_pct,
    ROUND(
        (CAST(total_orders AS REAL) - LAG(total_orders) OVER (ORDER BY month)) 
        / LAG(total_orders) OVER (ORDER BY month) * 100, 
        2
    ) AS orders_change_pct
FROM monthly_metrics
ORDER BY month;

--Найсильніший місяць липень (виручка 72 557,9, к-ть замовлень - 1935), 
-- найслабший місяць жовтень (в-ка 64 027.6, к-ть з. 1646)
--Динаміка змін до попереднього місяця показує виражене коливання показника продажів, де 
--найбільше зростання доходів зафіксовано у листопаді (+9.95%) та березні (+8.04), а 
--найглибший спад відбувся у грудні (-8.09%) та лютому (-6.64%)

--task 3 
-- Скільки замовлень у середньому надходить за один понеділок, один вівторок і так далі?
SELECT 
    CASE strftime('%w', date)
        WHEN '1' THEN '1. Понеділок'
        WHEN '2' THEN '2. Вівторок'
        WHEN '3' THEN '3. Середа'
        WHEN '4' THEN '4. Четвер'
        WHEN '5' THEN '5. П’ятниця'
        WHEN '6' THEN '6. Субота'
        WHEN '0' THEN '7. Неділя'
    END AS day_of_week,
    COUNT(DISTINCT order_id) AS total_orders,
    COUNT(DISTINCT date) AS total_days_count,
    ROUND(CAST(COUNT(DISTINCT order_id) AS REAL) / COUNT(DISTINCT date), 2) AS avg_orders_per_day
FROM orders
GROUP BY strftime('%w', date)
ORDER BY strftime('%w', date);

--Навантаження по годинах (Піки та затишшя)
SELECT 
    strftime('%H', time) AS hour,
    COUNT(DISTINCT order_id) AS total_orders
FROM orders
GROUP BY hour
ORDER BY hour;

--Найбільше замовлень в середньому приходиться на Пʼятницю(70.76, а найменше в Неділю(50.46), 
--решта мають діапазон 57-62. 
--Найбільший пік навантаження припадає на обідній (12:00–13:00) та вечірній (17:00–19:00) час 
--із максимумом о 12 годині (2520 замовлень), тоді як глибоке затишшя спостерігається на початку 
--та наприкінці робочого дня — о 9.00 ранку та 23.00 вечір.

--task 4
--ТОП-5 бестселерів (найкращі за виручкою)
SELECT 
    pt.name AS pizza_name,
    SUM(od.quantity) AS total_quantity,
    ROUND(SUM(p.price * od.quantity), 2) AS total_revenue
FROM order_details od
JOIN pizzas p ON od.pizza_id = p.pizza_id
JOIN pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
GROUP BY pt.name
ORDER BY total_revenue DESC
LIMIT 5;
--Топ-5 аутсайдерів (найгірші за виручкою)
SELECT 
    pt.name AS pizza_name,
    SUM(od.quantity) AS total_quantity,
    ROUND(SUM(p.price * od.quantity), 2) AS total_revenue
FROM order_details od
JOIN pizzas p ON od.pizza_id = p.pizza_id
JOIN pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
GROUP BY pt.name
ORDER BY total_revenue ASC
LIMIT 5;

--
--task 5
--Категорії та розміри: частка виручки кожної категорії та кожного розміру. 
--Які розміри продаються найкраще?SELECT 
SELECT 
    p.size AS pizza_size,
    COUNT(od.order_details_id) AS total_units_sold,
    ROUND(SUM(p.price * od.quantity), 2) AS size_revenue,
    ROUND(
        SUM(p.price * od.quantity) / SUM(SUM(p.price * od.quantity)) OVER () * 100, 
        2
    ) AS revenue_share_pct

FROM order_details od
JOIN pizzas p ON od.pizza_id = p.pizza_id
GROUP BY p.size
ORDER BY size_revenue DESC;
--Лідером за виторгом є The Thai Chicken Pizza (43 434.25), яка завдяки (сеоріш за все) вищій ціні
--випередила The Classic Deluxe Pizza та The Barbecue Chicken Pizza, хоча вони продалися 
--у більшій кількості (2453ш. та 2432ш. відповідно).
--Абсолютним айтсайдером є The Brie Carre Pizza (490ш. і 11 588.5 доходу), 
--яка продається вдвічі гірше за навіть за інших аутсайдерів, вона має критично низький попит.

--task 6 
--Кандидати на вилучення з меню: які піци (на рівні назви, усі розміри разом) 
--мають найменшу частку виручки й найменші продажі? Обґрунтуйте,
-- які 3–5 позицій можна прибрати і скільки виручки це зачепить. ★ Накопичувальна частка виручки.
SELECT 
    pt.name AS pizza_name,
    SUM(od.quantity) AS total_units_sold,
    ROUND(SUM(p.price * od.quantity), 2) AS pizza_revenue,
    ROUND(
        SUM(p.price * od.quantity) / SUM(SUM(p.price * od.quantity)) OVER () * 100, 
        2
    ) AS revenue_share_pct

FROM order_details od
JOIN pizzas p ON od.pizza_id = p.pizza_id
JOIN pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
GROUP BY pt.name
ORDER BY pizza_revenue ASC
LIMIT 10;
--Фокусуючись на фізичному попиті, головними кандидатами на вилучення дійсно стають:
--The Brie Carre Pizza(490 шт.), The Mediterranean Pizza(934 шт.) та The Spinach Supreme Pizza(950 шт.), 
--оскільки вони створюють найменше навантаження на замовлення, тоді як 
--The Green Garden Pizza(997 шт.) варто залишити через вищу популярність серед гостей, 
--попри її низьку вартість.


-- task 7
-- Великі замовлення: яка частка замовлень містить 4 і більше піц (сума quantity у замовленні) 
-- і скільки виручки вони дають? Чи варто робити окрему пропозицію для компаній?

WITH order_totals AS (
    SELECT 
        od.order_id,
        SUM(od.quantity) AS total_pizzas,
        SUM(p.price * od.quantity) AS order_revenue
    FROM order_details od
    JOIN pizzas p ON od.pizza_id = p.pizza_id
    GROUP BY od.order_id
),
classified_orders AS (
    SELECT 
        order_id,
        order_revenue,
        CASE 
            WHEN total_pizzas >= 4 THEN 'Великі (4+ піци)'
            ELSE 'Звичайні (1-3 піци)'
        END AS order_type
    FROM order_totals
)
SELECT 
    order_type,
    COUNT(order_id) AS orders_count,
    ROUND(COUNT(order_id) * 100.0 / SUM(COUNT(order_id)) OVER (), 2) AS orders_share_pct,
    ROUND(SUM(order_revenue), 2) AS total_revenue,
    ROUND(SUM(order_revenue) * 100.0 / SUM(SUM(order_revenue)) OVER (), 2) AS revenue_share_pct
FROM classified_orders
GROUP BY order_type;
--Дані показують, що великі піцци (4+ піцци) складають 18.17% від загальної кількості чеків 
--і приносять 39.44% усієї виручки компанії, що підтвкрджує доцільність створення окремої комерційної групи.

--task 8
-- Акція: у які дні тижня та години варто її запустити? Запропонуйте конкретну акцію 
-- та оцініть потенціал: яка зараз виручка в цьому часовому вікні і що дасть її зростання на 10%.

SELECT 
    CASE strftime('%w', date)
        WHEN '1' THEN '1. Понеділок'
        WHEN '2' THEN '2. Вівторок'
        WHEN '3' THEN '3. Середа'
        WHEN '4' THEN '4. Четвер'
        WHEN '5' THEN '5. П’ятниця'
        WHEN '6' THEN '6. Субота'
        WHEN '0' THEN '7. Неділя'
    END AS day_of_week,
    strftime('%H', time) AS hour_of_day,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(p.price * od.quantity), 2) AS current_revenue,
    ROUND(SUM(p.price * od.quantity) * 0.10, 2) AS revenue_growth_10_pct
FROM orders o
JOIN order_details od ON o.order_id = od.order_id
JOIN pizzas p ON od.pizza_id = p.pizza_id
GROUP BY strftime('%w', date), hour_of_day
ORDER BY current_revenue ASC;
--Проаналізувавши дані пропоную запустити Акцію в різні часові проміжки:
--акція з Понеділка по Четвер з 14:00-16.00 - "Пізні обіди" та 
-- після 21:00 - "Вечеря на виніс".

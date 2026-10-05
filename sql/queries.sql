--task 1.
--Загальні показники за рік: виручка, кількість замовлень, кількість проданих піц,
--середній чек, середня кількість піц у замовленні.Кількість піц рахуйте з урахуванням quantity.
SELECT
	SUM(p.price * od.quantity) AS total_revenue,
   COUNT(DISTINCT o.order_id) AS total_orders,
   SUM(od.quantity) AS total_pizzas_sold,
   CAST(SUM(p.price * od.quantity) / COUNT(DISTINCT o.order_id) AS DECIMAL(10, 2)) AS average_order_value,
   CAST(SUM(od.quantity) * 1.0 / COUNT(DISTINCT o.order_id) AS DECIMAL(10, 2)) AS average_pizzas_per_order
FROM orders o
JOIN order_details AS od ON o.order_id = od.order_id
JOIN pizzas AS p ON od.pizza_id = p.pizza_id
WHERE o.date >= '2015-01-01' AND o.date <= '2015-12-31';
-- Дані загальних показників за рік: виручка -817 860.05, кількість замовлень - 21350,
-- кількість проданих піц - 49 574, середній чек - 38.31, середня кількість піц у замовленні=2,32
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
--Лідером за виторгом є The Thai Chicken Pizza (43 434.25), яка завдяки (сеоріш за все) вищій ціні
--випередила The Classic Deluxe Pizza та The Barbecue Chicken Pizza, хоча вони продалися
--у більшій кількості (2453ш. та 2432ш. відповідно).
--Абсолютним айтсайдером є The Brie Carre Pizza (490ш. і 11 588.5 доходу),
--яка продається вдвічі гірше за навіть за інших аутсайдерів, вона має критично низький попит.
--task 5
--Категорії та розміри: частка виручки кожної категорії та кожного розміру.
--Які розміри продаються найкраще?
-- по розмірах
SELECT
  p.size AS pizza_size,
  SUM(od.quantity) AS total_units_sold,
  ROUND(SUM(p.price * od.quantity), 2) AS size_revenue,
  ROUND(SUM(p.price * od.quantity) * 100.0 / SUM(SUM(p.price * od.quantity)) OVER (), 2) AS revenue_share_pct
FROM order_details od
JOIN pizzas p ON od.pizza_id = p.pizza_id
GROUP BY p.size
ORDER BY size_revenue DESC;
-- по категоріях
SELECT
  pt.category,
  SUM(od.quantity) AS total_units_sold,
  ROUND(SUM(p.price * od.quantity), 2) AS category_revenue,
  ROUND(SUM(p.price * od.quantity) * 100.0 / SUM(SUM(p.price * od.quantity)) OVER (), 2) AS revenue_share_pct
FROM order_details od
JOIN pizzas p ON od.pizza_id = p.pizza_id
JOIN pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
GROUP BY pt.category
ORDER BY category_revenue DESC;
–Аналіз асортименту демонструє, що ядром продажів бізнесу є піци розміру L –(45.89% виторгу) та M (30.49%), тоді як попит між чотирма основними –категоріями розподілений максимально рівномірно з незначним лідерством –групи Classic (26.91%).
--task 6
--Кандидати на вилучення з меню: які піци (на рівні назви, усі розміри разом)
--мають найменшу частку виручки й найменші продажі? Обґрунтуйте,
-- які 3–5 позицій можна прибрати і скільки виручки це зачепить. ★ Накопичувальна частка виручки.
WITH pizza_stats AS (
  SELECT
      pt.name AS pizza_name,
      SUM(od.quantity) AS total_units_sold,
      ROUND(SUM(p.price * od.quantity), 2) AS pizza_revenue
  FROM order_details od
  JOIN pizzas p ON od.pizza_id = p.pizza_id
  JOIN pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
  GROUP BY pt.name
)
SELECT
  pizza_name,
  total_units_sold,
  pizza_revenue,
  ROUND(pizza_revenue * 100.0 / SUM(pizza_revenue) OVER (), 2) AS revenue_share_pct,
  ROUND(
      SUM(pizza_revenue) OVER (ORDER BY pizza_revenue ASC, pizza_name
                               ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
      * 100.0 / SUM(pizza_revenue) OVER (), 2
  ) AS cumulative_share_pct
FROM pizza_stats
ORDER BY pizza_revenue ASC
LIMIT 10;
--Фокусуючись на фізичному попиті, головними кандидатами на вилучення дійсно стають:
--The Brie Carre Pizza(490 шт.), The Mediterranean Pizza(934 шт.) та The Spinach Supreme Pizza(950 шт.),
--оскільки вони створюють найменше навантаження на замовлення, тоді як
--The Green Garden Pizza(997 шт.) варто залишити через вищу популярність серед гостей, попри її низьку вартість.




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
--Дані показують, що великі піци (4+ піци) складають 18.17% від загальної кількості чеків
--і приносять 39.44% усієї виручки компанії, що підтверджує доцільність створення окремої комерційної групи.


--task 8
-- Акція: у які дні тижня та години варто її запустити? Запропонуйте конкретну акцію
-- та оцініть потенціал: яка зараз виручка в цьому часовому вікні і що дасть її зростання на 10%.
SELECT
  CASE WHEN strftime('%H', o.time) IN ('14', '15')
       THEN 'Пн–Чт 14:00–16:00'
       ELSE 'Пн–Чт 21:00–24:00' END AS time_window,
  COUNT(DISTINCT o.order_id) AS total_orders,
  ROUND(SUM(p.price * od.quantity), 2) AS current_revenue,
  ROUND(SUM(p.price * od.quantity) * 0.10, 2) AS revenue_growth_10_pct
FROM orders o
JOIN order_details od ON o.order_id = od.order_id
JOIN pizzas p ON od.pizza_id = p.pizza_id
WHERE strftime('%w', o.date) IN ('1', '2', '3', '4')
 AND strftime('%H', o.time) IN ('14', '15', '21', '22', '23')
GROUP BY time_window;
--Проаналізувавши дані пропоную запустити Акцію в різні часові проміжки:
--акція з Понеділка по Четвер з 14:00-16:00 - "Пізні обіди". 
-- Пропозиція: знижка 15% або безкоштовний напій на другу піцу в замовленні.
-- Поточна виручка вікна: 62 567,7. Зростання на 10% дасть +6256,77 (разом 68 824,47)
-- після 21:00 - "Вечеря на виніс", вона хоч і дає приріст +2577,39, 
-- але є стратегічно виправданим кроком для покращення операційних процесів, 
-- щоб оптимізувати утилізацію ресурсів, коли обладнання та люди не стоять без діла.


--final
SELECT
   od.order_id AS order_id,
   o.date AS order_date,
   o.time AS order_time,
   strftime('%m', o.date) AS month,
   CASE strftime('%w', o.date)
       WHEN '1' THEN 'Понеділок'
       WHEN '2' THEN 'Вівторок'
       WHEN '3' THEN 'Середа'
       WHEN '4' THEN 'Четвер'
       WHEN '5' THEN 'П’ятниця'
       WHEN '6' THEN 'Субота'
       WHEN '0' THEN 'Неділя'
   END AS weekday,
   strftime('%H', o.time) AS hour,
   pt.name AS pizza_name,
   pt.category AS category,
   p.size AS size,
   CAST(p.price AS REAL) AS unit_price,
   CAST(od.quantity AS INTEGER) AS quantity,
   ROUND(CAST(p.price AS REAL) * CAST(od.quantity AS INTEGER), 2) AS revenue
FROM order_details od
JOIN orders o ON od.order_id = o.order_id
JOIN pizzas p ON od.pizza_id = p.pizza_id
JOIN pizza_types pt ON p.pizza_type_id = pt.pizza_type_id;
-- check
SELECT COUNT(*) FROM order_details;
SELECT COUNT(*) FROM order_details od
JOIN orders o ON od.order_id = o.order_id
JOIN pizzas p ON od.pizza_id = p.pizza_id
JOIN pizza_types pt ON p.pizza_type_id = pt.pizza_type_id;


-- 1. Count Unique Users by Event

select event_name , count(distinct user_id) as users 
from events 
group by event_name
order by users desc;

-- 2. Basic Funnel — User Count by Stage

SELECT 
    COUNT(DISTINCT CASE WHEN event_name = 'app_open' THEN user_id END) AS app_open,
    COUNT(DISTINCT CASE WHEN event_name = 'search' THEN user_id END) AS search,
    COUNT(DISTINCT CASE WHEN event_name = 'product_view' THEN user_id END) AS product_view,
    COUNT(DISTINCT CASE WHEN event_name = 'product_compare' THEN user_id END) AS product_compare,
    COUNT(DISTINCT CASE WHEN event_name = 'add_to_cart' THEN user_id END) AS add_to_cart,
    COUNT(DISTINCT CASE WHEN event_name = 'checkout_start' THEN user_id END) AS checkout_start,
    COUNT(DISTINCT CASE WHEN event_name = 'payment_attempt' THEN user_id END) AS payment_attempt,
    COUNT(DISTINCT CASE WHEN event_name = 'payment_success' THEN user_id END) AS payment_success,
    COUNT(DISTINCT CASE WHEN event_name = 'purchase' THEN user_id END) AS purchase
FROM events;

-- 3. Basic Funnel — Conversion Rate by Stage

WITH funnel AS (
    SELECT 
        COUNT(DISTINCT CASE WHEN event_name = 'app_open' THEN user_id END) AS app_open,
        COUNT(DISTINCT CASE WHEN event_name = 'product_view' THEN user_id END) AS product_view,
        COUNT(DISTINCT CASE WHEN event_name = 'add_to_cart' THEN user_id END) AS add_to_cart,
        COUNT(DISTINCT CASE WHEN event_name = 'checkout_start' THEN user_id END) AS checkout,
        COUNT(DISTINCT CASE WHEN event_name = 'purchase' THEN user_id END) AS purchase
    FROM events
)
SELECT app_open,product_view,add_to_cart,checkout,purchase,
product_view/app_open*100 as product_view_conversion,
add_to_cart/product_view*100 as add_to_cart_conversion,
checkout/add_to_cart*100 as checkout_conversion,
purchase/checkout*100 as purchase_conversion
FROM funnel;

-- 4. Basic Funnel — Drop-off Rate by Stage

WITH funnel AS (
    SELECT 
        COUNT(DISTINCT CASE WHEN event_name = 'app_open' THEN user_id END) AS app_open,
        COUNT(DISTINCT CASE WHEN event_name = 'product_view' THEN user_id END) AS product_view,
        COUNT(DISTINCT CASE WHEN event_name = 'add_to_cart' THEN user_id END) AS add_to_cart,
        COUNT(DISTINCT CASE WHEN event_name = 'checkout_start' THEN user_id END) AS checkout,
        COUNT(DISTINCT CASE WHEN event_name = 'purchase' THEN user_id END) AS purchase
    FROM events
)

select *,(app_open-product_view)/app_open*100 as product_view_dropoff,
 (product_view - add_to_cart) / product_view * 100 AS add_to_cart_dropoff,
 (add_to_cart - checkout)/add_to_cart*100 as checkout_dropoff,
 (checkout-purchase)/checkout*100 as purchase_dropoff
from funnel;

-- 5. Payment Failure — Users with Payment Attempt but No Success

SELECT DISTINCT user_id
FROM events
WHERE event_name = 'payment_attempt'
 and user_id not in (
select distinct user_id
from events 
where event_name='payment_success');

-- 6. User Event Journey — U006  

select event_time,event_name 
 from events 
where user_id='U006'
order by event_time asc ;

-- 7. Sequential Funnel — User Completion Status 

with user_journey as (
SELECT
    user_id,
    min(CASE WHEN event_name = 'app_open' THEN event_time END) AS app_open_time,
    min(CASE WHEN event_name = 'product_view' THEN event_time END) AS product_view_time,
    min(CASE WHEN event_name='add_to_cart' THEN event_time END) as add_to_cart_time,
	min(CASE WHEN event_name='checkout_start' THEN event_time END) as checkout_start_time,
	min(CASE WHEN event_name='purchase' THEN event_time END) as purchase_time
FROM events
group by user_id
)

SELECT *,
       CASE
           WHEN app_open_time < product_view_time
            AND product_view_time < add_to_cart_time
            AND add_to_cart_time < checkout_start_time
            AND checkout_start_time < purchase_time
           THEN 'Completed'
           ELSE 'Not Completed'
       END AS funnel_status
FROM user_journey;

-- 8. Sequential Funnel — Overall Completion Rate

with user_journey as (
SELECT
    user_id,
    min(CASE WHEN event_name = 'app_open' THEN event_time END) AS app_open_time,
    min(CASE WHEN event_name = 'product_view' THEN event_time END) AS product_view_time,
    min(CASE WHEN event_name='add_to_cart' THEN event_time END) as add_to_cart_time,
	min(CASE WHEN event_name='checkout_start' THEN event_time END) as checkout_start_time,
	min(CASE WHEN event_name='purchase' THEN event_time END) as purchase_time
FROM events
group by user_id
)

,funnel_status as (SELECT *,
       CASE
           WHEN app_open_time < product_view_time
            AND product_view_time < add_to_cart_time
            AND add_to_cart_time < checkout_start_time
            AND checkout_start_time < purchase_time
           THEN 'Completed'
           ELSE 'Not Completed'
       END AS funnel_status
FROM user_journey)
select 
count(distinct user_id) as total_users, count(distinct case when funnel_status='Completed' then user_id end ) as completed_users,
count(distinct case when funnel_status='Completed' then user_id end )/count(distinct user_id)*100 as Sequential_funnel_conversion
from funnel_status ;


-- 9. Sequential Funnel — Stage-wise Conversion from Total Users

WITH user_journey AS (
    SELECT
        user_id,
        MIN(CASE WHEN event_name = 'app_open' THEN event_time END) AS app_open_time,
        MIN(CASE WHEN event_name = 'product_view' THEN event_time END) AS product_view_time,
        MIN(CASE WHEN event_name = 'add_to_cart' THEN event_time END) AS add_to_cart_time,
        MIN(CASE WHEN event_name = 'checkout_start' THEN event_time END) AS checkout_start_time,
        MIN(CASE WHEN event_name = 'purchase' THEN event_time END) AS purchase_time
    FROM events
    GROUP BY user_id
),

sequential_funnel AS (
    SELECT *,
        CASE
            WHEN app_open_time < product_view_time
            THEN 'Yes' ELSE 'No'
        END AS sequential_product_view,

        CASE
            WHEN app_open_time < product_view_time
             AND product_view_time < add_to_cart_time
            THEN 'Yes' ELSE 'No'
        END AS sequential_add_to_cart,

        CASE
            WHEN app_open_time < product_view_time
             AND product_view_time < add_to_cart_time
             AND add_to_cart_time < checkout_start_time
            THEN 'Yes' ELSE 'No'
        END AS sequential_checkout,

        CASE
            WHEN app_open_time < product_view_time
             AND product_view_time < add_to_cart_time
             AND add_to_cart_time < checkout_start_time
             AND checkout_start_time < purchase_time
            THEN 'Yes' ELSE 'No'
        END AS sequential_purchase
    FROM user_journey
),

funnel_counts AS (
    SELECT
        COUNT(DISTINCT user_id) AS total_users,

        COUNT(DISTINCT CASE
            WHEN sequential_product_view = 'Yes' THEN user_id
        END) AS product_view_users,

        COUNT(DISTINCT CASE
            WHEN sequential_add_to_cart = 'Yes' THEN user_id
        END) AS add_to_cart_users,

        COUNT(DISTINCT CASE
            WHEN sequential_checkout = 'Yes' THEN user_id
        END) AS checkout_users,

        COUNT(DISTINCT CASE
            WHEN sequential_purchase = 'Yes' THEN user_id
        END) AS purchase_users

    FROM sequential_funnel
)

SELECT
    total_users,
    product_view_users,
    add_to_cart_users,
    checkout_users,
    purchase_users,

    product_view_users / total_users * 100 AS product_view_conversion,

    add_to_cart_users / total_users * 100 AS add_to_cart_conversion,

    checkout_users / total_users * 100 AS checkout_conversion,

    purchase_users / total_users * 100 AS purchase_conversion

FROM funnel_counts;

-- 10 - Sequential Funnel Stage-wise Drop-off 


WITH user_journey AS (
    SELECT
        user_id,
        MIN(CASE WHEN event_name = 'app_open' THEN event_time END) AS app_open_time,
        MIN(CASE WHEN event_name = 'product_view' THEN event_time END) AS product_view_time,
        MIN(CASE WHEN event_name = 'add_to_cart' THEN event_time END) AS add_to_cart_time,
        MIN(CASE WHEN event_name = 'checkout_start' THEN event_time END) AS checkout_start_time,
        MIN(CASE WHEN event_name = 'purchase' THEN event_time END) AS purchase_time
    FROM events
    GROUP BY user_id
),

sequential_funnel AS (
    SELECT *,
        CASE
            WHEN app_open_time < product_view_time
            THEN 'Yes' ELSE 'No'
        END AS sequential_product_view,

        CASE
            WHEN app_open_time < product_view_time
             AND product_view_time < add_to_cart_time
            THEN 'Yes' ELSE 'No'
        END AS sequential_add_to_cart,

        CASE
            WHEN app_open_time < product_view_time
             AND product_view_time < add_to_cart_time
             AND add_to_cart_time < checkout_start_time
            THEN 'Yes' ELSE 'No'
        END AS sequential_checkout,

        CASE
            WHEN app_open_time < product_view_time
             AND product_view_time < add_to_cart_time
             AND add_to_cart_time < checkout_start_time
             AND checkout_start_time < purchase_time
            THEN 'Yes' ELSE 'No'
        END AS sequential_purchase
    FROM user_journey
),

funnel_counts AS (
    SELECT
        COUNT(DISTINCT user_id) AS total_users,

        COUNT(DISTINCT CASE
            WHEN sequential_product_view = 'Yes' THEN user_id
        END) AS product_view_users,

        COUNT(DISTINCT CASE
            WHEN sequential_add_to_cart = 'Yes' THEN user_id
        END) AS add_to_cart_users,

        COUNT(DISTINCT CASE
            WHEN sequential_checkout = 'Yes' THEN user_id
        END) AS checkout_users,

        COUNT(DISTINCT CASE
            WHEN sequential_purchase = 'Yes' THEN user_id
        END) AS purchase_users

    FROM sequential_funnel
)

SELECT
    total_users,
    product_view_users,
    add_to_cart_users,
    checkout_users,
    purchase_users,
    (total_users-product_view_users)/total_users*100.0 as product_view_dropoff,
    (product_view_users-add_to_cart_users)/product_view_users*100.0 as add_to_cart_dropoff,
    (add_to_cart_users-checkout_users)/add_to_cart_users*100.0 as checkout_dropoff,
    (checkout_users-purchase_users)/checkout_users*100.0 as purchase_dropoff
    from funnel_counts;
    
    -- 11 - funnel by device 
    
    with events_with_device  as 
    (select e.*,u.device
    from users as u 
    inner join 
    events as e 
    on u.user_id=e.user_id)
    
  ,user_journey AS (
    SELECT
        user_id,device,
        MIN(CASE WHEN event_name = 'app_open' THEN event_time END) AS app_open_time,
        MIN(CASE WHEN event_name = 'product_view' THEN event_time END) AS product_view_time,
        MIN(CASE WHEN event_name = 'add_to_cart' THEN event_time END) AS add_to_cart_time,
        MIN(CASE WHEN event_name = 'checkout_start' THEN event_time END) AS checkout_start_time,
        MIN(CASE WHEN event_name = 'purchase' THEN event_time END) AS purchase_time
    FROM events_with_device 
    GROUP BY user_id,device
)
,sequential_funnel AS (
    SELECT *,
        CASE
            WHEN app_open_time < product_view_time
            THEN 'Yes' ELSE 'No'
        END AS sequential_product_view,

        CASE
            WHEN app_open_time < product_view_time
             AND product_view_time < add_to_cart_time
            THEN 'Yes' ELSE 'No'
        END AS sequential_add_to_cart,

        CASE
            WHEN app_open_time < product_view_time
             AND product_view_time < add_to_cart_time
             AND add_to_cart_time < checkout_start_time
            THEN 'Yes' ELSE 'No'
        END AS sequential_checkout,

        CASE
            WHEN app_open_time < product_view_time
             AND product_view_time < add_to_cart_time
             AND add_to_cart_time < checkout_start_time
             AND checkout_start_time < purchase_time
            THEN 'Yes' ELSE 'No'
        END AS sequential_purchase
    FROM user_journey)
    
,funnel_count as (
select device,
COUNT(DISTINCT user_id) AS total_users,
count(distinct case when sequential_product_view='Yes' then user_id end ) as product_view_users,
count(distinct case when sequential_add_to_cart='Yes' then user_id end) as add_to_cart_users,
count(distinct case when sequential_checkout='Yes' then user_id end) as checkout_users,
count(distinct case when sequential_purchase='Yes' then user_id end) as purchase_users 
from sequential_funnel
group by device)

SELECT
    device,
    total_users,
    product_view_users,
    add_to_cart_users,
    checkout_users,
    purchase_users,

    product_view_users / total_users * 100.0
        AS product_view_conversion,

    add_to_cart_users / product_view_users * 100.0
        AS add_to_cart_conversion,

    checkout_users / add_to_cart_users * 100.0
        AS checkout_conversion,

    purchase_users / checkout_users * 100.0
        AS purchase_conversion

FROM funnel_count;

-- 12. Funnel by Acquisition Channel 

with events_with_channel  as 
    (select e.*,u.acquisition_channel
    from users as u 
    inner join 
    events as e 
    on u.user_id=e.user_id) 
    
 ,user_journey AS (
    SELECT
        user_id,acquisition_channel,
        MIN(CASE WHEN event_name = 'app_open' THEN event_time END) AS app_open_time,
        MIN(CASE WHEN event_name = 'product_view' THEN event_time END) AS product_view_time,
        MIN(CASE WHEN event_name = 'add_to_cart' THEN event_time END) AS add_to_cart_time,
        MIN(CASE WHEN event_name = 'checkout_start' THEN event_time END) AS checkout_start_time,
        MIN(CASE WHEN event_name = 'purchase' THEN event_time END) AS purchase_time
    FROM events_with_channel 
    GROUP BY user_id,acquisition_channel
)
,sequential_funnel as (
SELECT *,
    CASE
        WHEN app_open_time < product_view_time
        THEN 'Yes' ELSE 'No'
    END AS sequential_product_view,

    CASE
        WHEN app_open_time < product_view_time
         AND product_view_time < add_to_cart_time
        THEN 'Yes' ELSE 'No'
    END AS sequential_add_to_cart,

    CASE
        WHEN app_open_time < product_view_time
         AND product_view_time < add_to_cart_time
         AND add_to_cart_time < checkout_start_time
        THEN 'Yes' ELSE 'No'
    END AS sequential_checkout,

    CASE
        WHEN app_open_time < product_view_time
         AND product_view_time < add_to_cart_time
         AND add_to_cart_time < checkout_start_time
         AND checkout_start_time < purchase_time
        THEN 'Yes' ELSE 'No'
    END AS sequential_purchase

FROM user_journey)

,funnel_count as (
select acquisition_channel,
COUNT(DISTINCT user_id) AS total_users,
count(distinct case when sequential_product_view='Yes' then user_id end ) as product_view_users,
count(distinct case when sequential_add_to_cart='Yes' then user_id end) as add_to_cart_users,
count(distinct case when sequential_checkout='Yes' then user_id end) as checkout_users,
count(distinct case when sequential_purchase='Yes' then user_id end) as purchase_users 
from sequential_funnel
group by acquisition_channel)

SELECT
    acquisition_channel,
    total_users,
    product_view_users,
    add_to_cart_users,
    checkout_users,
    purchase_users,

    product_view_users / total_users * 100.0
        AS product_view_conversion,

    add_to_cart_users / product_view_users * 100.0
        AS add_to_cart_conversion,

    checkout_users / add_to_cart_users * 100.0
        AS checkout_conversion,

    purchase_users / checkout_users * 100.0
        AS purchase_conversion

FROM funnel_count;    


-- 13. Funnel by Product Category
with events_with_category  as 
(
select e.*,p.category
from events as e 
left join products as p
on e.product_id=p.product_id )

,user_journey AS (
    SELECT
        user_id,

        MAX(
            CASE
                WHEN event_name = 'product_view'
                THEN category
            END
        ) AS category,

        MIN(CASE WHEN event_name = 'app_open'
            THEN event_time END) AS app_open_time,

        MIN(CASE WHEN event_name = 'product_view'
            THEN event_time END) AS product_view_time,

        MIN(CASE WHEN event_name = 'add_to_cart'
            THEN event_time END) AS add_to_cart_time,

        MIN(CASE WHEN event_name = 'checkout_start'
            THEN event_time END) AS checkout_start_time,

        MIN(CASE WHEN event_name = 'purchase'
            THEN event_time END) AS purchase_time

    FROM events_with_category
    GROUP BY user_id
)

,sequential_funnel AS (
    SELECT
        *,
        
        CASE
            WHEN app_open_time < product_view_time
            THEN 'Yes' ELSE 'No'
        END AS sequential_product_view,

        CASE
            WHEN app_open_time < product_view_time
             AND product_view_time < add_to_cart_time
            THEN 'Yes' ELSE 'No'
        END AS sequential_add_to_cart,

        CASE
            WHEN app_open_time < product_view_time
             AND product_view_time < add_to_cart_time
             AND add_to_cart_time < checkout_start_time
            THEN 'Yes' ELSE 'No'
        END AS sequential_checkout,

        CASE
            WHEN app_open_time < product_view_time
             AND product_view_time < add_to_cart_time
             AND add_to_cart_time < checkout_start_time
             AND checkout_start_time < purchase_time
            THEN 'Yes' ELSE 'No'
        END AS sequential_purchase

    FROM user_journey
)   
,funnel_count AS (
    SELECT
        category,
        COUNT(DISTINCT user_id) AS total_users,
        COUNT(DISTINCT CASE WHEN sequential_product_view = 'Yes' THEN user_id END) AS product_view_users,
        COUNT(DISTINCT CASE WHEN sequential_add_to_cart = 'Yes' THEN user_id END) AS add_to_cart_users,
        COUNT(DISTINCT CASE WHEN sequential_checkout = 'Yes' THEN user_id END) AS checkout_users,
        COUNT(DISTINCT CASE WHEN sequential_purchase = 'Yes' THEN user_id END) AS purchase_users
    FROM sequential_funnel
    GROUP BY category
) 

SELECT
    category,
    total_users,
    product_view_users,
    add_to_cart_users,
    checkout_users,
    purchase_users,

    product_view_users / total_users * 100.0 AS product_view_conversion,

    add_to_cart_users / product_view_users * 100.0 AS add_to_cart_conversion,

    checkout_users / add_to_cart_users * 100.0 AS checkout_conversion,

    purchase_users / checkout_users * 100.0 AS purchase_conversion

FROM funnel_count;

-- 14. Time-Based Funnel Analysis


WITH user_journey AS (
    SELECT
        user_id,

        MIN(CASE
            WHEN event_name = 'app_open'
            THEN event_time
        END) AS app_open_time,

        MIN(CASE
            WHEN event_name = 'product_view'
            THEN event_time
        END) AS product_view_time,

        MIN(CASE
            WHEN event_name = 'add_to_cart'
            THEN event_time
        END) AS add_to_cart_time,

        MIN(CASE
            WHEN event_name = 'checkout_start'
            THEN event_time
        END) AS checkout_start_time,

        MIN(CASE
            WHEN event_name = 'purchase'
            THEN event_time
        END) AS purchase_time

    FROM events
    GROUP BY user_id
),

user_journey_with_date AS (
    SELECT
        *,
        DATE(app_open_time) AS funnel_date
    FROM user_journey
),

sequential_funnel AS (
    SELECT
        *,

        CASE
            WHEN app_open_time < product_view_time
            THEN 'Yes' ELSE 'No'
        END AS sequential_product_view,

        CASE
            WHEN app_open_time < product_view_time
             AND product_view_time < add_to_cart_time
            THEN 'Yes' ELSE 'No'
        END AS sequential_add_to_cart,

        CASE
            WHEN app_open_time < product_view_time
             AND product_view_time < add_to_cart_time
             AND add_to_cart_time < checkout_start_time
            THEN 'Yes' ELSE 'No'
        END AS sequential_checkout,

        CASE
            WHEN app_open_time < product_view_time
             AND product_view_time < add_to_cart_time
             AND add_to_cart_time < checkout_start_time
             AND checkout_start_time < purchase_time
            THEN 'Yes' ELSE 'No'
        END AS sequential_purchase

    FROM user_journey_with_date
),

funnel_count AS (
    SELECT
        funnel_date,

        COUNT(DISTINCT user_id) AS total_users,

        COUNT(DISTINCT CASE
            WHEN sequential_product_view = 'Yes'
            THEN user_id
        END) AS product_view_users,

        COUNT(DISTINCT CASE
            WHEN sequential_add_to_cart = 'Yes'
            THEN user_id
        END) AS add_to_cart_users,

        COUNT(DISTINCT CASE
            WHEN sequential_checkout = 'Yes'
            THEN user_id
        END) AS checkout_users,

        COUNT(DISTINCT CASE
            WHEN sequential_purchase = 'Yes'
            THEN user_id
        END) AS purchase_users

    FROM sequential_funnel
    GROUP BY funnel_date
)

SELECT
    funnel_date,
    total_users,
    product_view_users,
    add_to_cart_users,
    checkout_users,
    purchase_users,

    product_view_users / total_users * 100.0
        AS product_view_conversion,

    add_to_cart_users / product_view_users * 100.0
        AS add_to_cart_conversion,

    checkout_users / add_to_cart_users * 100.0
        AS checkout_conversion,

    purchase_users / checkout_users * 100.0
        AS purchase_conversion

FROM funnel_count
ORDER BY funnel_date;

--     COHORT ANALYSIS   

-- 15. User Cohort Assignment

SELECT user_id,signup_date,DATE_FORMAT(signup_date, '%Y-%m') as cohort_month 
FROM users;

-- 16. Cohort User Count 

select DATE_FORMAT(signup_date, '%Y-%m') as cohort_month,count(*) as user_count
from users
group by DATE_FORMAT(signup_date, '%Y-%m')
order by cohort_month asc ;

-- 17. User Activity Period

select user_id, DATE_FORMAT(event_time, '%Y-%m') as activity_month
from events
group by user_id, DATE_FORMAT(event_time, '%Y-%m');
 
-- 18 cohort period/ age 

WITH cte1 AS 
(
    SELECT 
        user_id,
        DATE_FORMAT(signup_date, '%Y-%m') AS cohort_month
    FROM users
),

cte2 AS 
(
    SELECT 
        user_id,
        DATE_FORMAT(event_time, '%Y-%m') AS activity_month
    FROM events
    GROUP BY 
        user_id,
        DATE_FORMAT(event_time, '%Y-%m')
)

SELECT 
    user_id,
    cohort_month,
    activity_month,
    TIMESTAMPDIFF(
        MONTH,
        STR_TO_DATE(CONCAT(cohort_month, '-01'), '%Y-%m-%d'),
        STR_TO_DATE(CONCAT(activity_month, '-01'), '%Y-%m-%d')
    ) AS cohort_age
FROM 
(
    SELECT 
        c1.user_id,
        c1.cohort_month,
        c2.activity_month
    FROM cte1 AS c1
    INNER JOIN cte2 AS c2
        ON c1.user_id = c2.user_id
) AS x
ORDER BY 
    cohort_month,
    user_id,
    activity_month;

-- 19. Cohort-wise Active Users

-- 19. Cohort-wise Active Users

WITH cohort_data AS
(
    -- 18. Cohort Period / Age

WITH cte1 AS 
(
    SELECT 
        user_id,
        DATE_FORMAT(signup_date, '%Y-%m') AS cohort_month
    FROM users
),

cte2 AS 
(
    SELECT 
        user_id,
        DATE_FORMAT(event_time, '%Y-%m') AS activity_month
    FROM events
    GROUP BY 
        user_id,
        DATE_FORMAT(event_time, '%Y-%m')
)

SELECT 
    user_id,
    cohort_month,
    activity_month,
    TIMESTAMPDIFF(
        MONTH,
        STR_TO_DATE(CONCAT(cohort_month, '-01'), '%Y-%m-%d'),
        STR_TO_DATE(CONCAT(activity_month, '-01'), '%Y-%m-%d')
    ) AS cohort_age
FROM 
(
    SELECT 
        c1.user_id,
        c1.cohort_month,
        c2.activity_month
    FROM cte1 AS c1
    INNER JOIN cte2 AS c2
        ON c1.user_id = c2.user_id
) AS x
ORDER BY 
    cohort_month,
    user_id,
    activity_month
)

SELECT cohort_month,cohort_age,count(distinct user_id) as active_users
FROM cohort_data
group by cohort_month,cohort_age;

 -- 20. Cohort Retention %
 

WITH active_users AS
(
 WITH cohort_data AS
(
    -- 18. Cohort Period / Age

WITH cte1 AS 
(
    SELECT 
        user_id,
        DATE_FORMAT(signup_date, '%Y-%m') AS cohort_month
    FROM users
),

cte2 AS 
(
    SELECT 
        user_id,
        DATE_FORMAT(event_time, '%Y-%m') AS activity_month
    FROM events
    GROUP BY 
        user_id,
        DATE_FORMAT(event_time, '%Y-%m')
)

SELECT 
    user_id,
    cohort_month,
    activity_month,
    TIMESTAMPDIFF(
        MONTH,
        STR_TO_DATE(CONCAT(cohort_month, '-01'), '%Y-%m-%d'),
        STR_TO_DATE(CONCAT(activity_month, '-01'), '%Y-%m-%d')
    ) AS cohort_age
FROM 
(
    SELECT 
        c1.user_id,
        c1.cohort_month,
        c2.activity_month
    FROM cte1 AS c1
    INNER JOIN cte2 AS c2
        ON c1.user_id = c2.user_id
) AS x
ORDER BY 
    cohort_month,
    user_id,
    activity_month
)

SELECT cohort_month,cohort_age,count(distinct user_id) as active_users
FROM cohort_data
group by cohort_month,cohort_age

)

,cohort_size as 
(select cohort_month,active_users
from active_users
where cohort_age=0)

select au.*,cs.active_users as cohort_size,au.active_users / cs.active_users *100 as retention_pct
from active_users as au
join 
cohort_size as cs
on au.cohort_month=cs.cohort_month;


-- 21. Retention Matrix

WITH active_users AS
(
    SELECT 
        c1.cohort_month,
        c2.activity_month,
        TIMESTAMPDIFF(
            MONTH,
            STR_TO_DATE(CONCAT(c1.cohort_month, '-01'), '%Y-%m-%d'),
            STR_TO_DATE(CONCAT(c2.activity_month, '-01'), '%Y-%m-%d')
        ) AS cohort_age,
        COUNT(DISTINCT c1.user_id) AS active_users
    FROM
    (
        SELECT 
            user_id,
            DATE_FORMAT(signup_date, '%Y-%m') AS cohort_month
        FROM users
    ) AS c1

    INNER JOIN
    (
        SELECT 
            user_id,
            DATE_FORMAT(event_time, '%Y-%m') AS activity_month
        FROM events
        GROUP BY 
            user_id,
            DATE_FORMAT(event_time, '%Y-%m')
    ) AS c2
        ON c1.user_id = c2.user_id

    GROUP BY 
        c1.cohort_month,
        c2.activity_month,
        TIMESTAMPDIFF(
            MONTH,
            STR_TO_DATE(CONCAT(c1.cohort_month, '-01'), '%Y-%m-%d'),
            STR_TO_DATE(CONCAT(c2.activity_month, '-01'), '%Y-%m-%d')
        )
),

cohort_size AS
(
    SELECT 
        cohort_month,
        active_users AS cohort_size
    FROM active_users
    WHERE cohort_age = 0
),

retention AS
(
    SELECT 
        au.cohort_month,
        au.cohort_age,
        au.active_users,
        cs.cohort_size,
        ROUND(
            au.active_users / cs.cohort_size * 100,
            2
        ) AS retention_pct
    FROM active_users AS au
    INNER JOIN cohort_size AS cs
        ON au.cohort_month = cs.cohort_month
)

SELECT 
    cohort_month,

    MAX(CASE WHEN cohort_age = 0 THEN retention_pct END) AS M0,
    MAX(CASE WHEN cohort_age = 1 THEN retention_pct END) AS M1,
    MAX(CASE WHEN cohort_age = 2 THEN retention_pct END) AS M2,
    MAX(CASE WHEN cohort_age = 3 THEN retention_pct END) AS M3,
    MAX(CASE WHEN cohort_age = 4 THEN retention_pct END) AS M4,
    MAX(CASE WHEN cohort_age = 5 THEN retention_pct END) AS M5,
    MAX(CASE WHEN cohort_age = 6 THEN retention_pct END) AS M6,
    MAX(CASE WHEN cohort_age = 7 THEN retention_pct END) AS M7,
    MAX(CASE WHEN cohort_age = 8 THEN retention_pct END) AS M8
FROM retention
GROUP BY cohort_month
ORDER BY cohort_month;
-- 22. Cohort Comparison

-- 22. Cohort Comparison

WITH active_users AS
(
    SELECT
        c1.cohort_month,
        c2.activity_month,

        TIMESTAMPDIFF(
            MONTH,
            STR_TO_DATE(CONCAT(c1.cohort_month, '-01'), '%Y-%m-%d'),
            STR_TO_DATE(CONCAT(c2.activity_month, '-01'), '%Y-%m-%d')
        ) AS cohort_age,

        COUNT(DISTINCT c1.user_id) AS active_users

    FROM
    (
        SELECT
            user_id,
            DATE_FORMAT(signup_date, '%Y-%m') AS cohort_month
        FROM users
    ) AS c1

    INNER JOIN
    (
        SELECT
            user_id,
            DATE_FORMAT(event_time, '%Y-%m') AS activity_month
        FROM events
        GROUP BY
            user_id,
            DATE_FORMAT(event_time, '%Y-%m')
    ) AS c2
        ON c1.user_id = c2.user_id

    GROUP BY
        c1.cohort_month,
        c2.activity_month,
        TIMESTAMPDIFF(
            MONTH,
            STR_TO_DATE(CONCAT(c1.cohort_month, '-01'), '%Y-%m-%d'),
            STR_TO_DATE(CONCAT(c2.activity_month, '-01'), '%Y-%m-%d')
        )
),

cohort_size AS
(
    SELECT
        cohort_month,
        active_users AS cohort_size
    FROM active_users
    WHERE cohort_age = 0
),

retention AS
(
    SELECT
        au.cohort_month,
        au.cohort_age,

        ROUND(
            au.active_users / cs.cohort_size * 100,
            2
        ) AS retention_pct

    FROM active_users AS au

    INNER JOIN cohort_size AS cs
        ON au.cohort_month = cs.cohort_month
),

-- This is basically your #21 Retention Matrix
retention_matrix AS
(
    SELECT
        cohort_month,

        MAX(CASE WHEN cohort_age = 1 THEN retention_pct END) AS M1,
        MAX(CASE WHEN cohort_age = 2 THEN retention_pct END) AS M2,
        MAX(CASE WHEN cohort_age = 3 THEN retention_pct END) AS M3,
        MAX(CASE WHEN cohort_age = 4 THEN retention_pct END) AS M4,
        MAX(CASE WHEN cohort_age = 5 THEN retention_pct END) AS M5,
        MAX(CASE WHEN cohort_age = 6 THEN retention_pct END) AS M6,
        MAX(CASE WHEN cohort_age = 7 THEN retention_pct END) AS M7,
        MAX(CASE WHEN cohort_age = 8 THEN retention_pct END) AS M8

    FROM retention

    GROUP BY cohort_month
),

-- Convert the matrix back into rows so we can compare months
comparison_data AS
(
    SELECT cohort_month, 'M1' AS month, M1 AS retention FROM retention_matrix
    UNION ALL
    SELECT cohort_month, 'M2', M2 FROM retention_matrix
    UNION ALL
    SELECT cohort_month, 'M3', M3 FROM retention_matrix
    UNION ALL
    SELECT cohort_month, 'M4', M4 FROM retention_matrix
    UNION ALL
    SELECT cohort_month, 'M5', M5 FROM retention_matrix
    UNION ALL
    SELECT cohort_month, 'M6', M6 FROM retention_matrix
    UNION ALL
    SELECT cohort_month, 'M7', M7 FROM retention_matrix
    UNION ALL
    SELECT cohort_month, 'M8', M8 FROM retention_matrix
),

ranked_data AS
(
    SELECT
        cohort_month,
        month,
        retention,

        RANK() OVER (
            PARTITION BY month
            ORDER BY retention DESC
        ) AS highest_rank,

        RANK() OVER (
            PARTITION BY month
            ORDER BY retention ASC
        ) AS lowest_rank

    FROM comparison_data
    WHERE retention IS NOT NULL
)

SELECT
    month,

    MAX(
        CASE
            WHEN highest_rank = 1
            THEN cohort_month
        END
    ) AS highest_cohort,

    MAX(
        CASE
            WHEN highest_rank = 1
            THEN retention
        END
    ) AS highest_retention,

    MAX(
        CASE
            WHEN lowest_rank = 1
            THEN cohort_month
        END
    ) AS lowest_cohort,

    MAX(
        CASE
            WHEN lowest_rank = 1
            THEN retention
        END
    ) AS lowest_retention

FROM ranked_data

GROUP BY month

ORDER BY month;

-- 23. Cohort by Acquisition Channel — Step 1
with cte1 as (
select x.user_id,x.cohort_month,x.acquisition_channel,y.activity_date from 
(
select user_id,
 DATE_FORMAT(signup_date, '%Y-%m') AS cohort_month,
 acquisition_channel
from users 
order by cohort_month,user_id) as x

inner join 
(
select user_id,DATE_FORMAT(event_time, '%Y-%m') as activity_date
from events 
group by user_id,DATE_FORMAT(event_time, '%Y-%m')) as y 
on x.user_id=y.user_id
ORDER BY
    x.cohort_month,
    x.user_id,
    y.activity_date) 
    
   ,cte2 as ( select *, TIMESTAMPDIFF(
    MONTH,
    STR_TO_DATE(CONCAT(cohort_month, '-01'), '%Y-%m-%d'),
    STR_TO_DATE(CONCAT(activity_date, '-01'), '%Y-%m-%d')
) AS cohort_age
from cte1
ORDER BY cohort_month, user_id, activity_date)

,cte3 as (select cohort_month,acquisition_channel,cohort_age,count(distinct user_id) as active_users
from cte2
group by cohort_month,acquisition_channel,cohort_age)

,cte4 as (
select * from (
select cohort_month,acquisition_channel,cohort_age,count(distinct user_id) as cohort_size
from cte2
group by cohort_month,acquisition_channel,cohort_age) as t
where cohort_age=0)

select  cte3.cohort_month,cte3.acquisition_channel,cte3.cohort_age,cte3.active_users,cte4.cohort_size,active_users/cohort_size*100 as retention_pct
from cte3 
inner join cte4
on cte3.cohort_month=cte4.cohort_month and cte3.acquisition_channel=cte4.acquisition_channel;

-- #25. Retention Deep Dive
-- Find the largest retention decline for each signup cohort

WITH user_cohort AS (

    -- Step 1: Assign each user to their signup cohort
    SELECT
        user_id,
        DATE_FORMAT(signup_date, '%Y-%m') AS cohort_month
    FROM users

),

user_activity AS (

    -- Step 2: Identify each user's active months
    SELECT DISTINCT
        user_id,
        DATE_FORMAT(event_time, '%Y-%m') AS activity_month
    FROM events

),

cohort_activity AS (

    -- Step 3: Connect signup cohorts with monthly activity
    SELECT
        uc.user_id,
        uc.cohort_month,
        ua.activity_month,
        TIMESTAMPDIFF(
            MONTH,
            STR_TO_DATE(CONCAT(uc.cohort_month, '-01'), '%Y-%m-%d'),
            STR_TO_DATE(CONCAT(ua.activity_month, '-01'), '%Y-%m-%d')
        ) AS cohort_age
    FROM user_cohort AS uc
    INNER JOIN user_activity AS ua
        ON uc.user_id = ua.user_id
    WHERE ua.activity_month >= uc.cohort_month

),

active_users_by_age AS (

    -- Step 4: Count active users in each cohort age
    SELECT
        cohort_month,
        cohort_age,
        COUNT(DISTINCT user_id) AS active_users
    FROM cohort_activity
    GROUP BY cohort_month, cohort_age

),

cohort_size AS (

    -- Step 5: Count users active in M0 for each cohort
    SELECT
        cohort_month,
        COUNT(DISTINCT user_id) AS cohort_size
    FROM cohort_activity
    WHERE cohort_age = 0
    GROUP BY cohort_month

),

retention_data AS (

    -- Query #20: Calculate retention percentage
    SELECT
        a.cohort_month,
        a.cohort_age,
        a.active_users,
        c.cohort_size,
        ROUND(
            a.active_users * 100.0 / NULLIF(c.cohort_size, 0),
            2
        ) AS retention_pct
    FROM active_users_by_age AS a
    INNER JOIN cohort_size AS c
        ON a.cohort_month = c.cohort_month

),

ret_change AS (

    -- Query #25: Compare with the previous cohort age
    SELECT
        *,
        LAG(retention_pct) OVER (
            PARTITION BY cohort_month
            ORDER BY cohort_age
        ) AS prev_month_ret,

        retention_pct - LAG(retention_pct) OVER (
            PARTITION BY cohort_month
            ORDER BY cohort_age
        ) AS retention_change
    FROM retention_data

),

ranked_retention AS (

    -- Step 7: Rank declines within each cohort
    SELECT
        *,
        RANK() OVER (
            PARTITION BY cohort_month
            ORDER BY retention_change ASC
        ) AS rn
    FROM ret_change
    WHERE retention_change IS NOT NULL

)

-- Step 8: Return the largest decline for each cohort
SELECT
    cohort_month,
    cohort_age AS decline_at_month,
    prev_month_ret,
    retention_pct,
    retention_change AS retention_change_pp
FROM ranked_retention
WHERE rn = 1
ORDER BY cohort_month;

-- #26. Average Retention by Cohort Age 
with cte1 as (
WITH user_cohort AS (
    SELECT
        user_id,
        DATE_FORMAT(signup_date, '%Y-%m') AS cohort_month
    FROM users
),

user_activity AS (
    SELECT DISTINCT
        user_id,
        DATE_FORMAT(event_time, '%Y-%m') AS activity_month
    FROM events
),

cohort_activity AS (
    SELECT
        uc.user_id,
        uc.cohort_month,
        ua.activity_month,
        TIMESTAMPDIFF(
            MONTH,
            STR_TO_DATE(CONCAT(uc.cohort_month, '-01'), '%Y-%m-%d'),
            STR_TO_DATE(CONCAT(ua.activity_month, '-01'), '%Y-%m-%d')
        ) AS cohort_age
    FROM user_cohort AS uc
    INNER JOIN user_activity AS ua
        ON uc.user_id = ua.user_id
    WHERE ua.activity_month >= uc.cohort_month
),

active_users_by_age AS (
    SELECT
        cohort_month,
        cohort_age,
        COUNT(DISTINCT user_id) AS active_users
    FROM cohort_activity
    GROUP BY cohort_month, cohort_age
),

cohort_size AS (
    SELECT
        cohort_month,
        COUNT(DISTINCT user_id) AS cohort_size
    FROM cohort_activity
    WHERE cohort_age = 0
    GROUP BY cohort_month
)

SELECT
    a.cohort_month,
    a.cohort_age,
    a.active_users,
    c.cohort_size,
    ROUND(
        a.active_users * 100.0 / NULLIF(c.cohort_size, 0),
        2
    ) AS retention_pct
FROM active_users_by_age AS a
INNER JOIN cohort_size AS c
    ON a.cohort_month = c.cohort_month
ORDER BY
    a.cohort_month,
    a.cohort_age)
    
select cohort_age,avg(retention_pct) as avg_ret_pct
from cte1
group by cohort_age;

-- #27. Average Retention Change by Cohort Age

WITH avg_retention AS (

with cte1 as (
WITH user_cohort AS (
    SELECT
        user_id,
        DATE_FORMAT(signup_date, '%Y-%m') AS cohort_month
    FROM users
),

user_activity AS (
    SELECT DISTINCT
        user_id,
        DATE_FORMAT(event_time, '%Y-%m') AS activity_month
    FROM events
),

cohort_activity AS (
    SELECT
        uc.user_id,
        uc.cohort_month,
        ua.activity_month,
        TIMESTAMPDIFF(
            MONTH,
            STR_TO_DATE(CONCAT(uc.cohort_month, '-01'), '%Y-%m-%d'),
            STR_TO_DATE(CONCAT(ua.activity_month, '-01'), '%Y-%m-%d')
        ) AS cohort_age
    FROM user_cohort AS uc
    INNER JOIN user_activity AS ua
        ON uc.user_id = ua.user_id
    WHERE ua.activity_month >= uc.cohort_month
),

active_users_by_age AS (
    SELECT
        cohort_month,
        cohort_age,
        COUNT(DISTINCT user_id) AS active_users
    FROM cohort_activity
    GROUP BY cohort_month, cohort_age
),

cohort_size AS (
    SELECT
        cohort_month,
        COUNT(DISTINCT user_id) AS cohort_size
    FROM cohort_activity
    WHERE cohort_age = 0
    GROUP BY cohort_month
)

SELECT
    a.cohort_month,
    a.cohort_age,
    a.active_users,
    c.cohort_size,
    ROUND(
        a.active_users * 100.0 / NULLIF(c.cohort_size, 0),
        2
    ) AS retention_pct
FROM active_users_by_age AS a
INNER JOIN cohort_size AS c
    ON a.cohort_month = c.cohort_month
ORDER BY
    a.cohort_month,
    a.cohort_age)
    
select cohort_age,avg(retention_pct) as avg_ret_pct
from cte1
group by cohort_age

)

select * ,
lag(avg_ret_pct)over(order by cohort_age) as prev_avg_ret_pct,
avg_ret_pct-lag(avg_ret_pct)over(order by cohort_age)  as avg_ret_change_pp
from avg_retention;


-- #28. Retention Variability Across Cohorts

WITH retention_data AS (

WITH user_cohort AS (
    SELECT
        user_id,
        DATE_FORMAT(signup_date, '%Y-%m') AS cohort_month
    FROM users
),

user_activity AS (
    SELECT DISTINCT
        user_id,
        DATE_FORMAT(event_time, '%Y-%m') AS activity_month
    FROM events
),

cohort_activity AS (
    SELECT
        uc.user_id,
        uc.cohort_month,
        ua.activity_month,
        TIMESTAMPDIFF(
            MONTH,
            STR_TO_DATE(CONCAT(uc.cohort_month, '-01'), '%Y-%m-%d'),
            STR_TO_DATE(CONCAT(ua.activity_month, '-01'), '%Y-%m-%d')
        ) AS cohort_age
    FROM user_cohort AS uc
    INNER JOIN user_activity AS ua
        ON uc.user_id = ua.user_id
    WHERE ua.activity_month >= uc.cohort_month
),

active_users_by_age AS (
    SELECT
        cohort_month,
        cohort_age,
        COUNT(DISTINCT user_id) AS active_users
    FROM cohort_activity
    GROUP BY cohort_month, cohort_age
),

cohort_size AS (
    SELECT
        cohort_month,
        COUNT(DISTINCT user_id) AS cohort_size
    FROM cohort_activity
    WHERE cohort_age = 0
    GROUP BY cohort_month
)

SELECT
    a.cohort_month,
    a.cohort_age,
    a.active_users,
    c.cohort_size,
    ROUND(
        a.active_users * 100.0 / NULLIF(c.cohort_size, 0),
        2
    ) AS retention_pct
FROM active_users_by_age AS a
INNER JOIN cohort_size AS c
    ON a.cohort_month = c.cohort_month
ORDER BY
    a.cohort_month,
    a.cohort_age

)

SELECT
    cohort_age,
    min(retention_pct) as min_retention_pct,
    max(retention_pct) as max_retentin_pct,
    avg(retention_pct) as avg_retention_pct,
    max(retention_pct)-min(retention_pct) as retention_range_pp
    

    -- Calculate retention range

FROM retention_data
GROUP BY cohort_age
ORDER BY cohort_age;

-- 29 Best and Worst Performing Signup Cohorts

-- #29. Best and Worst Performing Signup Cohorts

WITH user_cohort AS (
    SELECT
        user_id,
        DATE_FORMAT(signup_date, '%Y-%m') AS cohort_month
    FROM users
),

user_activity AS (
    SELECT DISTINCT
        user_id,
        DATE_FORMAT(event_time, '%Y-%m') AS activity_month
    FROM events
),

cohort_activity AS (
    SELECT
        uc.cohort_month,
        ua.user_id,
        TIMESTAMPDIFF(
            MONTH,
            STR_TO_DATE(CONCAT(uc.cohort_month, '-01'), '%Y-%m-%d'),
            STR_TO_DATE(CONCAT(ua.activity_month, '-01'), '%Y-%m-%d')
        ) AS cohort_age
    FROM user_cohort uc
    JOIN user_activity ua
        ON uc.user_id = ua.user_id
),

cohort_size AS (
    SELECT
        cohort_month,
        COUNT(DISTINCT user_id) AS cohort_size
    FROM cohort_activity
    WHERE cohort_age = 0
    GROUP BY cohort_month
),

active_users AS (
    SELECT
        cohort_month,
        cohort_age,
        COUNT(DISTINCT user_id) AS active_users
    FROM cohort_activity
    GROUP BY cohort_month, cohort_age
),

retention_data AS (
    SELECT
        au.cohort_month,
        au.cohort_age,
        au.active_users,
        cs.cohort_size,
        ROUND(au.active_users * 100.0 / cs.cohort_size, 2)
            AS retention_pct
    FROM active_users au
    JOIN cohort_size cs
        ON au.cohort_month = cs.cohort_month
)

SELECT
    cohort_month,
    retention_pct,
    CASE
        WHEN retention_pct = (
            SELECT MAX(retention_pct)
            FROM retention_data
            WHERE cohort_age = 1
        ) THEN 'Highest'
        WHEN retention_pct = (
            SELECT MIN(retention_pct)
            FROM retention_data
            WHERE cohort_age = 1
        ) THEN 'Lowest'
    END AS performance
FROM retention_data
WHERE cohort_age = 1
  AND (
      retention_pct = (
          SELECT MAX(retention_pct)
          FROM retention_data
          WHERE cohort_age = 1
      )
      OR retention_pct = (
          SELECT MIN(retention_pct)
          FROM retention_data
          WHERE cohort_age = 1
      )
  )
ORDER BY retention_pct DESC;


-- #30.1 App Open vs Add to Cart

SELECT
    COUNT(DISTINCT CASE
        WHEN event_name = 'app_open' THEN user_id
    END) AS app_open_users,

    COUNT(DISTINCT CASE
        WHEN event_name = 'add_to_cart' THEN user_id
    END) AS add_to_cart_users

FROM events;

-- #30B. Sequential App Open to Add to Cart

WITH user_journey AS (
    SELECT
        user_id,

        MIN(CASE
            WHEN event_name = 'app_open'
            THEN event_time
        END) AS app_open_time,

        MIN(CASE
            WHEN event_name = 'add_to_cart'
            THEN event_time
        END) AS add_to_cart_time

    FROM events
    GROUP BY user_id
)

SELECT
    COUNT(CASE
        WHEN app_open_time IS NOT NULL
        THEN user_id
    END) AS app_open_users,

    COUNT(CASE
        WHEN app_open_time IS NOT NULL
         AND add_to_cart_time > app_open_time
        THEN user_id
    END) AS users_added_to_cart_after_open

FROM user_journey;

-- #31. App Open to Add-to-Cart by Device

WITH user_journey AS (
    SELECT
        u.user_id,
        u.device,

        MIN(CASE
            WHEN e.event_name = 'app_open'
            THEN e.event_time
        END) AS app_open_time,

        MIN(CASE
            WHEN e.event_name = 'add_to_cart'
            THEN e.event_time
        END) AS add_to_cart_time

    FROM users u
    LEFT JOIN events e
        ON u.user_id = e.user_id
    GROUP BY u.user_id, u.device
)

SELECT
    device,

    COUNT(CASE
        WHEN app_open_time IS NOT NULL
        THEN 1
    END) AS app_open_users,

    COUNT(CASE
        WHEN app_open_time IS NOT NULL
         AND add_to_cart_time > app_open_time
        THEN 1
    END) AS sequential_cart_users,

    ROUND(
        100.0 * COUNT(CASE
            WHEN app_open_time IS NOT NULL
             AND add_to_cart_time > app_open_time
            THEN 1
        END)
        / NULLIF(COUNT(CASE
            WHEN app_open_time IS NOT NULL
            THEN 1
        END), 0),
        2
    ) AS add_to_cart_conversion_pct

FROM user_journey
GROUP BY device
ORDER BY add_to_cart_conversion_pct;


-- #32. App Open to Add-to-Cart by Acquisition Channel

WITH user_journey AS (
    SELECT
        u.user_id,
        u.acquisition_channel,

        MIN(CASE
            WHEN e.event_name = 'app_open'
            THEN e.event_time
        END) AS app_open_time,

        MIN(CASE
            WHEN e.event_name = 'add_to_cart'
            THEN e.event_time
        END) AS add_to_cart_time

    FROM users u
    LEFT JOIN events e
        ON u.user_id = e.user_id
    GROUP BY u.user_id, u.acquisition_channel
)

SELECT
    acquisition_channel,

    COUNT(CASE
        WHEN app_open_time IS NOT NULL
        THEN 1
    END) AS app_open_users,

    COUNT(CASE
        WHEN app_open_time IS NOT NULL
         AND add_to_cart_time > app_open_time
        THEN 1
    END) AS sequential_cart_users,

    ROUND(
        100.0 * COUNT(CASE
            WHEN app_open_time IS NOT NULL
             AND add_to_cart_time > app_open_time
            THEN 1
        END)
        / NULLIF(COUNT(CASE
            WHEN app_open_time IS NOT NULL
            THEN 1
        END), 0),
        2
    ) AS add_to_cart_conversion_pct

FROM user_journey
GROUP BY acquisition_channel
ORDER BY add_to_cart_conversion_pct;

-- #33. Payment Attempt Without Recorded Success

SELECT
    COUNT(DISTINCT CASE
        WHEN event_name = 'payment_attempt'
        THEN user_id
    END) AS payment_attempt_users,

    COUNT(DISTINCT CASE
        WHEN event_name = 'payment_success'
        THEN user_id
    END) AS payment_success_users,

    COUNT(DISTINCT CASE
        WHEN event_name = 'payment_attempt'
         AND user_id NOT IN (
             SELECT user_id
             FROM events
             WHERE event_name = 'payment_success'
         )
        THEN user_id
    END) AS users_without_recorded_success

FROM events;

-- #34. M1 Retention by Acquisition Channel

WITH user_cohort AS (
    SELECT
        user_id,
        acquisition_channel,
        DATE_FORMAT(signup_date, '%Y-%m') AS cohort_month
    FROM users
),

user_activity AS (
    SELECT DISTINCT
        user_id,
        DATE_FORMAT(event_time, '%Y-%m') AS activity_month
    FROM events
),

cohort_activity AS (
    SELECT
        uc.user_id,
        uc.acquisition_channel,
        uc.cohort_month,

        TIMESTAMPDIFF(
            MONTH,
            STR_TO_DATE(
                CONCAT(uc.cohort_month, '-01'),
                '%Y-%m-%d'
            ),
            STR_TO_DATE(
                CONCAT(ua.activity_month, '-01'),
                '%Y-%m-%d'
            )
        ) AS cohort_age

    FROM user_cohort uc
    JOIN user_activity ua
        ON uc.user_id = ua.user_id
),

cohort_size AS (
    SELECT
        cohort_month,
        acquisition_channel,
        COUNT(DISTINCT user_id) AS cohort_size
    FROM cohort_activity
    WHERE cohort_age = 0
    GROUP BY cohort_month, acquisition_channel
),

m1_active AS (
    SELECT
        cohort_month,
        acquisition_channel,
        COUNT(DISTINCT user_id) AS active_users
    FROM cohort_activity
    WHERE cohort_age = 1
    GROUP BY cohort_month, acquisition_channel
)

SELECT
    cs.acquisition_channel,
    SUM(cs.cohort_size) AS eligible_m0_users,
    SUM(COALESCE(m1.active_users, 0)) AS m1_active_users,

    ROUND(
        100.0 * SUM(COALESCE(m1.active_users, 0))
        / NULLIF(SUM(cs.cohort_size), 0),
        2
    ) AS m1_retention_pct

FROM cohort_size cs
LEFT JOIN m1_active m1
    ON cs.cohort_month = m1.cohort_month
   AND cs.acquisition_channel = m1.acquisition_channel

GROUP BY cs.acquisition_channel
ORDER BY m1_retention_pct;






















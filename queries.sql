/* --------------------
   Case Study Questions
   --------------------*/


/* 1. What is the total amount each customer spent at the restaurant? */
SELECT
    customer_id,
    SUM(price) AS total_spent
FROM 
    dannys_diner.sales sa
    JOIN dannys_diner.menu me ON sa.product_id = me.product_id
GROUP BY
    customer_id
ORDER BY 
    customer_id;


/* 2. How many days has each customer visited the restaurant? */
SELECT
    customer_id,
    COUNT(DISTINCT order_date) AS days_visited
FROM 
    dannys_diner.sales
GROUP BY 
    customer_id
ORDER BY
    customer_id;


/* 3. What was the first item from the menu purchased by each customer? */
SELECT 
    DISTINCT customer_id,
    product_name,
    order_date
FROM 
    dannys_diner.sales sa
    JOIN dannys_diner.menu me ON sa.product_id = me.product_id
WHERE 
    order_date = '2021-01-01'
ORDER BY
    customer_id;


/* 4. What is the most purchased item on the menu and how many times was it purchased by all customers? */
SELECT
    customer_id,
    product_name,
    COUNT(product_name) AS purchase_cnt
FROM
    dannys_diner.sales sa
    JOIN dannys_diner.menu me ON sa.product_id = me.product_id
WHERE 
    product_name = (
        SELECT product_name
        FROM dannys_diner.menu 
        GROUP BY product_name
        ORDER BY COUNT(product_name) DESC
        LIMIT 1
    )
GROUP BY 
    customer_id, product_name
ORDER BY 
    customer_id;


/* 5. Which item was the most popular for each customer? */
SELECT
    customer_id,
    product_name,
    COUNT(product_name) AS most_ordered
FROM
    dannys_diner.sales sa
    JOIN dannys_diner.menu me ON sa.product_id = me.product_id
GROUP BY
    customer_id, product_name
ORDER BY 
    most_ordered DESC;


/* 6. Which item was purchased first by the customer after they became a member? */
WITH CTE AS (
    SELECT
        sa.customer_id,
        product_name,
        ROW_NUMBER() OVER(PARTITION BY sa.customer_id ORDER BY order_date) AS row_num
    FROM
        dannys_diner.sales sa
        LEFT JOIN dannys_diner.menu me ON sa.product_id = me.product_id
        LEFT JOIN dannys_diner.members meb ON sa.customer_id = meb.customer_id
    WHERE
        order_date >= join_date
    ORDER BY
        sa.customer_id, order_date
)
SELECT 
    customer_id,
    product_name
FROM 
    CTE
WHERE 
    row_num = 1;


/* 7. Which item was purchased just before the customer became a member? */
WITH CTE AS (
    SELECT
        sa.customer_id,
        product_name,
        order_date,
        ROW_NUMBER() OVER(PARTITION BY sa.customer_id ORDER BY order_date DESC) AS row_num
    FROM
        dannys_diner.sales sa
        LEFT JOIN dannys_diner.menu me ON sa.product_id = me.product_id
        LEFT JOIN dannys_diner.members meb ON sa.customer_id = meb.customer_id
    WHERE
        order_date < join_date
    ORDER BY
        sa.customer_id, order_date
)
SELECT 
    customer_id,
    product_name
FROM 
    CTE
WHERE
    row_num = 1;


/* 8. What is the total items and amount spent for each member before they became a member? */
SELECT
    sa.customer_id,
    SUM(price) AS total_spent
FROM
    dannys_diner.sales sa
    LEFT JOIN dannys_diner.menu me ON sa.product_id = me.product_id
    LEFT JOIN dannys_diner.members meb ON meb.customer_id = sa.customer_id
WHERE
    order_date < join_date
GROUP BY
    sa.customer_id
ORDER BY
    sa.customer_id;


/* 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have? */
SELECT
    customer_id,
    SUM(CASE
        WHEN product_name = 'sushi' THEN 2*10*price
        ELSE price*10
    END) AS points_earned
FROM
    dannys_diner.sales sa
    JOIN dannys_diner.menu me ON sa.product_id = me.product_id
GROUP BY
    customer_id
ORDER BY
    customer_id;


/* 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January? */
SELECT
    sa.customer_id,
    SUM(price*20) AS points_earned
FROM
    dannys_diner.sales sa
    JOIN dannys_diner.menu me ON sa.product_id = me.product_id
    JOIN dannys_diner.members meb ON meb.customer_id = sa.customer_id
WHERE
    order_date >= join_date 
    AND EXTRACT('MONTH' FROM order_date) = 1
GROUP BY
    sa.customer_id
ORDER BY
    sa.customer_id;

-- ADDITIONAL INFORMATION

/* The following questions are related to creating basic data tables that Danny and his team can use to quickly derive insights without needing to join the underlying tables using SQL. */
SELECT
    sa.customer_id,
    order_date,
    product_name,
    price,
    CASE
        WHEN order_date >= join_date THEN 'Y'
        ELSE 'N'
    END AS member
FROM 
    dannys_diner.sales sa
    LEFT JOIN dannys_diner.menu me ON sa.product_id = me.product_id
    LEFT JOIN dannys_diner.members meb ON sa.customer_id = meb.customer_id
ORDER BY
    sa.customer_id, order_date;


/* Danny also requires further information about the ranking of customer products, but he purposely does not need the ranking for non-member purchases so he expects null ranking values for the records when customers are not yet part of the loyalty program. */
SELECT
    sa.customer_id,
    order_date,
    product_name,
    price,
    CASE
        WHEN order_date >= join_date THEN 'Y'
        ELSE 'N'
    END AS member,
    CASE
        WHEN order_date >= join_date THEN 
        DENSE_RANK() OVER(PARTITION BY sa.customer_id, order_date >= join_date
                          ORDER BY order_date)
        ELSE null
    END AS ranking    
FROM 
    dannys_diner.sales sa
    LEFT JOIN dannys_diner.menu me ON sa.product_id = me.product_id
    LEFT JOIN dannys_diner.members meb ON sa.customer_id = meb.customer_id
ORDER BY
    sa.customer_id, order_date;

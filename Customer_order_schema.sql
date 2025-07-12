Create Database Customer_order_db;
USE Customer_order_db;

CREATE TABLE Customer(
customer_id INT PRIMARY KEY AUTO_INCREMENT,
customer_name VARCHAR(100) NOT NULL,
email VARCHAR(50) UNIQUE,
phone_no VARCHAR(20),
address TEXT NOT NULL,
created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE orders (
    order_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT,
    order_date DATE NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    order_status VARCHAR(50) DEFAULT 'Pending',
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customer(customer_id)
);

INSERT INTO Customer (customer_name, email, phone_no, address) VALUES
('John Smith', 'john.smith@email.com', '555-0101', '123 Main Street, New York, NY 10001'),
('Sarah Johnson', 'sarah.johnson@email.com', '555-0102', '456 Oak Avenue, Los Angeles, CA 90210'),
('Michael Brown', 'michael.brown@email.com', '555-0103', '789 Pine Road, Chicago, IL 60601'),
('Emily Davis', 'emily.davis@email.com', '555-0104', '321 Elm Street, Houston, TX 77001');

Select * from Customer;

INSERT INTO orders (customer_id, order_date, total_amount, order_status) VALUES
(1, '2024-06-15', 299.99, 'Completed'),
(2, '2024-06-20', 149.50, 'Pending'),
(3, '2024-06-25', 599.00, 'Shipped'),
(4, '2024-06-28', 89.95, 'Processing');

SELECT * FROM orders;

-- inner join that returns only the customers who have placed order
SELECT 
    c.customer_id,
    c.customer_name,
    c.email,
    o.order_id,
    o.order_date,
    o.total_amount,
    o.order_status
FROM Customer c
INNER JOIN orders o ON c.customer_id = o.customer_id;

-- right outer join 
-- Returns all orders, including those without associated customers
SELECT 
    c.customer_id,
    c.customer_name,
    c.email,
    o.order_id,
    o.order_date,
    o.total_amount,
    o.order_status
FROM Customer c
RIGHT JOIN orders o ON c.customer_id = o.customer_id;

-- Left Outer Join
-- Returns all customers, including those without orders
SELECT 
    c.customer_id,
    c.customer_name,
    c.email,
    o.order_id,
    o.order_date,
    o.total_amount,
    o.order_status
FROM Customer c
LEFT JOIN orders o ON c.customer_id = o.customer_id;

-- Full Outer Join
-- makes use of UNION keyword as MySQL doesnt directly support Full Outer Join 
SELECT 
    c.customer_id,
    c.customer_name,
    c.email,
    o.order_id,
    o.order_date,
    o.total_amount,
    o.order_status
FROM Customer c
LEFT JOIN orders o ON c.customer_id = o.customer_id
UNION
SELECT 
    c.customer_id,
    c.customer_name,
    c.email,
    o.order_id,
    o.order_date,
    o.total_amount,
    o.order_status
FROM Customer c
RIGHT JOIN orders o ON c.customer_id = o.customer_id;

--  CROSS JOIN
-- Returns Cartesian product (every customer with every order)
SELECT 
    c.customer_id,
    c.customer_name,
    o.order_id,
    o.order_date,
    o.total_amount
FROM Customer c
CROSS JOIN orders o;

--  SELF JOIN on Customer table
-- Find customers from the same city 
SELECT 
    c1.customer_name as Customer1,
    c2.customer_name as Customer2,
    SUBSTRING_INDEX(c1.address, ',', -2) as Location
FROM Customer c1
JOIN Customer c2 ON SUBSTRING_INDEX(c1.address, ',', -2) = SUBSTRING_INDEX(c2.address, ',', -2)
AND c1.customer_id < c2.customer_id;

-- NATURAL JOIN (automatically joins on common column names)
-- This works because both tables have customer_id column
SELECT 
    customer_id,
    customer_name,
    email,
    order_id,
    order_date,
    total_amount,
    order_status
FROM Customer
NATURAL JOIN orders;

--  INNER JOIN with WHERE clause
-- Get customers with orders over $200
SELECT 
    c.customer_name,
    c.email,
    o.order_date,
    o.total_amount,
    o.order_status
FROM Customer c
INNER JOIN orders o ON c.customer_id = o.customer_id
WHERE o.total_amount > 200.00;

-- Subqueries 
-- 1. Scalar Subquery (Returns one single value)
SELECT customer_name, email
FROM Customer c
WHERE c.customer_id IN (
    SELECT customer_id 
    FROM orders 
    WHERE total_amount > (SELECT AVG(total_amount) FROM orders) -- Scalar query
);

-- 2. Multi-row Query (Returns mutiple values )
-- Find customers who have placed orders (using IN)
SELECT customer_name, email, phone_no
FROM Customer
WHERE customer_id IN (
    SELECT DISTINCT customer_id 
    FROM orders
);

-- 3. CORRELATED SUBQUERY (Depends on outer query)
-- Find customers with their highest order amount
SELECT customer_name, 
       email,
       (SELECT MAX(total_amount) 
        FROM orders o 
        WHERE o.customer_id = c.customer_id) as highest_order
FROM Customer c;

-- 4. EXISTS SUBQUERY (Checks existence)
-- Find customers who have placed at least one order
SELECT customer_name, email, address
FROM Customer c
WHERE EXISTS (
    SELECT 1 
    FROM orders o 
    WHERE o.customer_id = c.customer_id
);

-- Find customers who have NOT placed any orders
SELECT customer_name, email, phone_no
FROM Customer c
WHERE NOT EXISTS (
    SELECT 1 
    FROM orders o 
    WHERE o.customer_id = c.customer_id
);

-- NESTED SUBQUERIES (Multiple levels)
-- Find customers in the same city as the highest spender
SELECT customer_name, address
FROM Customer
WHERE SUBSTRING_INDEX(address, ',', -2) = (
    SELECT SUBSTRING_INDEX(address, ',', -2)
    FROM Customer
    WHERE customer_id = (
        SELECT customer_id
        FROM orders
        WHERE total_amount = (SELECT MAX(total_amount) FROM orders)
    )
);

-- Views and various features related to views.

-- 1.Create a simple view that shows customer order summary
CREATE VIEW customer_order_summary AS
SELECT 
    c.customer_id,
    c.customer_name,
    c.email,
    c.phone_no,
    COUNT(o.order_id) as total_orders,
    COALESCE(SUM(o.total_amount), 0) as total_spent,
    COALESCE(AVG(o.total_amount), 0) as avg_order_value,
    MAX(o.order_date) as last_order_date
FROM Customer c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name, c.email, c.phone_no;

SELECT * FROM customer_order_summary;

-- 2. COMPLEX VIEW WITH JOINS AND CALCULATIONS
CREATE VIEW active_customers_view AS
SELECT 
    c.customer_id,
    c.customer_name,
    c.email,
    c.address,
    SUBSTRING_INDEX(c.address, ',', -2) as city_state,
    o.order_id,
    o.order_date,
    o.total_amount,
    o.order_status,
    CASE 
        WHEN o.total_amount > 500 THEN 'High Value'
        WHEN o.total_amount > 200 THEN 'Medium Value'
        ELSE 'Low Value'
    END as order_category,
    DATEDIFF(CURDATE(), o.order_date) as days_since_order
FROM Customer c
INNER JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_status IN ('Completed', 'Shipped', 'Processing');

SELECT * FROM active_customers_view;

-- 3. SECURITY VIEW - Hide sensitive information
CREATE VIEW public_customer_info AS
SELECT 
    customer_id,
    customer_name,
    email,
    SUBSTRING_INDEX(address, ',', -2) as city_state,
    created_date
FROM Customer;

SELECT * FROM public_customer_info;

-- 4. VIEW WITH AGGREGATION AND RANKING

CREATE VIEW customer_rankings AS
SELECT 
    c.customer_id,
    c.customer_name,
    c.email,
    COALESCE(SUM(o.total_amount), 0) as total_spent,
    COUNT(o.order_id) as order_count,
    RANK() OVER (ORDER BY COALESCE(SUM(o.total_amount), 0) DESC) as spending_rank,
    CASE 
        WHEN COALESCE(SUM(o.total_amount), 0) > 400 THEN 'VIP'
        WHEN COALESCE(SUM(o.total_amount), 0) > 200 THEN 'Premium'
        WHEN COALESCE(SUM(o.total_amount), 0) > 0 THEN 'Regular'
        ELSE 'New Customer'
    END as customer_tier
FROM Customer c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name, c.email;


SELECT * FROM customer_rankings ORDER BY spending_rank;

-- 5. UPDATABLE VIEW EXAMPLE

CREATE VIEW customer_contact_view AS
SELECT 
    customer_id,
    customer_name,
    email,
    phone_no
FROM Customer;


SELECT * FROM customer_contact_view WHERE customer_id = 1;

-- 6. VIEW WITH CHECK OPTION

CREATE VIEW high_value_orders AS
SELECT 
    order_id,
    customer_id,
    order_date,
    total_amount,
    order_status
FROM orders
WHERE total_amount > 200
WITH CHECK OPTION;


SELECT * FROM high_value_orders;



-- 7. NESTED VIEW (View based on another view)

CREATE VIEW vip_customers AS
SELECT 
    customer_id,
    customer_name,
    email,
    total_spent,
    order_count
FROM customer_rankings
WHERE customer_tier = 'VIP';

SELECT * FROM vip_customers;

-- 8. VIEW FOR REPORTING AND ANALYTICS
CREATE VIEW monthly_sales_report AS
SELECT 
    YEAR(order_date) as year,
    MONTH(order_date) as month,
    MONTHNAME(order_date) as month_name,
    COUNT(order_id) as total_orders,
    SUM(total_amount) as total_revenue,
    AVG(total_amount) as avg_order_value,
    COUNT(DISTINCT customer_id) as unique_customers
FROM orders
GROUP BY YEAR(order_date), MONTH(order_date), MONTHNAME(order_date)
ORDER BY year, month;


SELECT * FROM monthly_sales_report;

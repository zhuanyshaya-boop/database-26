
DROP SCHEMA IF EXISTS labwork5_constraints CASCADE;
DROP SCHEMA IF EXISTS labwork5_shop CASCADE;
CREATE SCHEMA labwork5_constraints;
CREATE SCHEMA labwork5_shop;

CREATE TABLE labwork5_constraints.employees (
    employee_id INTEGER,
    first_name TEXT,
    last_name TEXT,
    age INTEGER CHECK (age BETWEEN 18 AND 65),
    salary NUMERIC(12,2) CHECK (salary > 0)
);

CREATE TABLE labwork5_constraints.products_catalog (
    product_id INTEGER,
    product_name TEXT,
    regular_price NUMERIC(12,2),
    discount_price NUMERIC(12,2),
    CONSTRAINT valid_discount CHECK (
        regular_price > 0
        AND discount_price > 0
        AND discount_price < regular_price
    )
);

CREATE TABLE labwork5_constraints.bookings (
    booking_id INTEGER,
    check_in_date DATE,
    check_out_date DATE,
    num_guests INTEGER CHECK (num_guests BETWEEN 1 AND 10),
    CONSTRAINT check_out_after_check_in CHECK (check_out_date > check_in_date)
);

INSERT INTO labwork5_constraints.employees VALUES
    (1, 'Anna', 'Smith', 25, 350000.00),
    (2, 'Timur', 'Askarov', 42, 560000.00);

INSERT INTO labwork5_constraints.products_catalog VALUES
    (1, 'Laptop', 300000.00, 270000.00),
    (2, 'Headphones', 30000.00, 25000.00);

INSERT INTO labwork5_constraints.bookings VALUES
    (1, DATE '2026-10-20', DATE '2026-10-23', 2),
    (2, DATE '2026-11-01', DATE '2026-11-05', 5);


SELECT * FROM labwork5_constraints.employees;
SELECT * FROM labwork5_constraints.products_catalog;
SELECT * FROM labwork5_constraints.bookings;

CREATE TABLE labwork5_constraints.customers (
    customer_id INTEGER NOT NULL,
    email TEXT NOT NULL,
    phone TEXT,
    registration_date DATE NOT NULL
);

CREATE TABLE labwork5_constraints.inventory (
    item_id INTEGER NOT NULL,
    item_name TEXT NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity >= 0),
    unit_price NUMERIC(12,2) NOT NULL CHECK (unit_price > 0),
    last_updated TIMESTAMP NOT NULL
);

INSERT INTO labwork5_constraints.customers VALUES
    (1, 'a@example.com', '+77011111111', DATE '2026-10-01'),
    (2, 'b@example.com', NULL, DATE '2026-10-02');

INSERT INTO labwork5_constraints.inventory VALUES
    (1, 'Mouse', 20, 4500, TIMESTAMP '2026-10-13 09:00:00'),
    (2, 'Keyboard', 0, 12000, TIMESTAMP '2026-10-13 10:00:00');


SELECT * FROM labwork5_constraints.customers;
SELECT * FROM labwork5_constraints.inventory;

CREATE TABLE labwork5_constraints.users (
    user_id INTEGER,
    username TEXT CONSTRAINT initial_unique_username UNIQUE,
    email TEXT CONSTRAINT initial_unique_email UNIQUE,
    created_at TIMESTAMP
);

CREATE TABLE labwork5_constraints.course_enrollments (
    enrollment_id INTEGER,
    student_id INTEGER,
    course_code TEXT,
    semester TEXT,
    CONSTRAINT unique_course_registration UNIQUE (student_id, course_code, semester)
);

ALTER TABLE labwork5_constraints.users
    DROP CONSTRAINT initial_unique_username;
ALTER TABLE labwork5_constraints.users
    DROP CONSTRAINT initial_unique_email;
ALTER TABLE labwork5_constraints.users
    ADD CONSTRAINT unique_username UNIQUE (username);
ALTER TABLE labwork5_constraints.users
    ADD CONSTRAINT unique_email UNIQUE (email);

INSERT INTO labwork5_constraints.users VALUES
    (1, 'aru', 'aru@example.com', NOW()),
    (2, 'dana', 'dana@example.com', NOW());

INSERT INTO labwork5_constraints.course_enrollments VALUES
    (1, 101, 'DB101', 'Fall-2026'),
    (2, 101, 'DB101', 'Spring-2027'), 
    (3, 102, 'DB101', 'Fall-2026');

SELECT * FROM labwork5_constraints.users;
SELECT * FROM labwork5_constraints.course_enrollments;

CREATE TABLE labwork5_constraints.departments (
    dept_id INTEGER PRIMARY KEY,
    dept_name TEXT NOT NULL,
    location TEXT
);

INSERT INTO labwork5_constraints.departments VALUES
    (1, 'IT', 'Almaty'),
    (2, 'Finance', 'Astana'),
    (3, 'HR', 'Shymkent');


CREATE TABLE labwork5_constraints.student_courses (
    student_id INTEGER,
    course_id INTEGER,
    enrollment_date DATE,
    grade TEXT,
    CONSTRAINT student_courses_pkey PRIMARY KEY (student_id, course_id)
);

INSERT INTO labwork5_constraints.student_courses VALUES
    (101, 201, DATE '2026-09-01', 'A'),
    (101, 202, DATE '2026-09-01', 'B'), 
    (102, 201, DATE '2026-09-01', 'A');

SELECT * FROM labwork5_constraints.departments;
SELECT * FROM labwork5_constraints.student_courses;

CREATE TABLE labwork5_constraints.employees_dept (
    emp_id INTEGER PRIMARY KEY,
    emp_name TEXT NOT NULL,
    dept_id INTEGER REFERENCES labwork5_constraints.departments(dept_id),
    hire_date DATE
);

INSERT INTO labwork5_constraints.employees_dept VALUES
    (1, 'Amina', 1, DATE '2026-03-10'),
    (2, 'Sanzhar', 2, DATE '2026-04-20');


CREATE TABLE labwork5_constraints.authors (
    author_id INTEGER PRIMARY KEY,
    author_name TEXT NOT NULL,
    country TEXT
);

CREATE TABLE labwork5_constraints.publishers (
    publisher_id INTEGER PRIMARY KEY,
    publisher_name TEXT NOT NULL,
    city TEXT
);

CREATE TABLE labwork5_constraints.books (
    book_id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    author_id INTEGER REFERENCES labwork5_constraints.authors(author_id),
    publisher_id INTEGER REFERENCES labwork5_constraints.publishers(publisher_id),
    publication_year INTEGER,
    isbn TEXT UNIQUE
);

INSERT INTO labwork5_constraints.authors VALUES
    (1, 'Abai Kunanbayuly', 'Kazakhstan'),
    (2, 'Mukhtar Auezov', 'Kazakhstan');
INSERT INTO labwork5_constraints.publishers VALUES
    (1, 'Almaty Press', 'Almaty'),
    (2, 'Astana Books', 'Astana');
INSERT INTO labwork5_constraints.books VALUES
    (1, 'Selected Poems', 1, 1, 2020, 'ISBN-0001'),
    (2, 'The Path of Abai', 2, 2, 2019, 'ISBN-0002'),
    (3, 'Words of Wisdom', 1, 2, 2023, 'ISBN-0003');

CREATE TABLE labwork5_constraints.categories (
    category_id INTEGER PRIMARY KEY,
    category_name TEXT NOT NULL
);

CREATE TABLE labwork5_constraints.products_fk (
    product_id INTEGER PRIMARY KEY,
    product_name TEXT NOT NULL,
    category_id INTEGER REFERENCES labwork5_constraints.categories(category_id)
                        ON DELETE RESTRICT
);

CREATE TABLE labwork5_constraints.orders (
    order_id INTEGER PRIMARY KEY,
    order_date DATE NOT NULL
);

CREATE TABLE labwork5_constraints.order_items (
    item_id INTEGER PRIMARY KEY,
    order_id INTEGER REFERENCES labwork5_constraints.orders(order_id)
                     ON DELETE CASCADE,
    product_id INTEGER REFERENCES labwork5_constraints.products_fk(product_id),
    quantity INTEGER CHECK (quantity > 0)
);

INSERT INTO labwork5_constraints.categories VALUES (1, 'Electronics'), (2, 'Books');
INSERT INTO labwork5_constraints.products_fk VALUES
    (1, 'Monitor', 1), (2, 'Notebook', 2);
INSERT INTO labwork5_constraints.orders VALUES (1, DATE '2026-10-10'), (2, DATE '2026-10-11');
INSERT INTO labwork5_constraints.order_items VALUES
    (1, 1, 1, 2), (2, 1, 2, 1), (3, 2, 2, 4);

BEGIN;
SELECT COUNT(*) AS items_before_cascade
FROM labwork5_constraints.order_items WHERE order_id = 1;
DELETE FROM labwork5_constraints.orders WHERE order_id = 1;
SELECT COUNT(*) AS items_after_cascade
FROM labwork5_constraints.order_items WHERE order_id = 1;
ROLLBACK;


SELECT * FROM labwork5_constraints.books;
SELECT * FROM labwork5_constraints.order_items;


CREATE TABLE labwork5_shop.customers (
    customer_id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    phone TEXT,
    registration_date DATE NOT NULL
);

CREATE TABLE labwork5_shop.products (
    product_id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    price NUMERIC(12,2) NOT NULL CHECK (price >= 0),
    stock_quantity INTEGER NOT NULL CHECK (stock_quantity >= 0)
);

CREATE TABLE labwork5_shop.orders (
    order_id INTEGER PRIMARY KEY,
    customer_id INTEGER NOT NULL REFERENCES labwork5_shop.customers(customer_id)
                        ON DELETE RESTRICT,
    order_date DATE NOT NULL,
    total_amount NUMERIC(12,2) NOT NULL CHECK (total_amount >= 0),
    status TEXT NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending', 'processing', 'shipped', 'delivered', 'cancelled'))
);

CREATE TABLE labwork5_shop.order_details (
    order_detail_id INTEGER PRIMARY KEY,
    order_id INTEGER NOT NULL REFERENCES labwork5_shop.orders(order_id)
                     ON DELETE CASCADE,
    product_id INTEGER NOT NULL REFERENCES labwork5_shop.products(product_id)
                       ON DELETE RESTRICT,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price NUMERIC(12,2) NOT NULL CHECK (unit_price >= 0)
);

INSERT INTO labwork5_shop.customers VALUES
    (1, 'Aru',    'aru.shop@example.com',    '+77010000001', DATE '2026-10-01'),
    (2, 'Dana',   'dana.shop@example.com',   NULL,           DATE '2026-10-02'),
    (3, 'Alikhan','alikhan.shop@example.com','+77010000003', DATE '2026-10-03'),
    (4, 'Amina',  'amina.shop@example.com',  '+77010000004', DATE '2026-10-04'),
    (5, 'Timur',  'timur.shop@example.com',  '+77010000005', DATE '2026-10-05');

INSERT INTO labwork5_shop.products VALUES
    (101, 'Wireless Mouse', 'Computer accessory', 49.99, 20),
    (102, 'Keyboard', 'USB keyboard', 129.00, 10),
    (103, 'Notebook', 'Paper notebook', 14.50, 80),
    (104, 'Monitor', 'Computer monitor', 300.00, 4),
    (105, 'Pen', 'Blue ink pen', 5.00, 200);

INSERT INTO labwork5_shop.orders VALUES
    (1001, 1, DATE '2026-10-06', 99.98, 'pending'),
    (1002, 2, DATE '2026-10-07', 129.00, 'processing'),
    (1003, 3, DATE '2026-10-08', 43.50, 'shipped'),
    (1004, 4, DATE '2026-10-09', 300.00, 'delivered'),
    (1005, 5, DATE '2026-10-10', 20.00, 'cancelled');

INSERT INTO labwork5_shop.order_details VALUES
    (501, 1001, 101, 2, 49.99),
    (502, 1002, 102, 1, 129.00),
    (503, 1003, 103, 3, 14.50),
    (504, 1004, 104, 1, 300.00),
    (505, 1005, 105, 4, 5.00);

SELECT 'customers' AS table_name, COUNT(*) AS rows_count FROM labwork5_shop.customers
UNION ALL
SELECT 'products', COUNT(*) FROM labwork5_shop.products
UNION ALL
SELECT 'orders', COUNT(*) FROM labwork5_shop.orders
UNION ALL
SELECT 'order_details', COUNT(*) FROM labwork5_shop.order_details;

SELECT o.order_id, c.name AS customer, p.name AS product,
       d.quantity, d.unit_price, o.total_amount, o.status
FROM labwork5_shop.orders o
JOIN labwork5_shop.customers c ON o.customer_id = c.customer_id
JOIN labwork5_shop.order_details d ON o.order_id = d.order_id
JOIN labwork5_shop.products p ON d.product_id = p.product_id
ORDER BY o.order_id;


BEGIN;
SELECT COUNT(*) AS order_details_before
FROM labwork5_shop.order_details WHERE order_id = 1001;
DELETE FROM labwork5_shop.orders WHERE order_id = 1001;
SELECT COUNT(*) AS order_details_after
FROM labwork5_shop.order_details WHERE order_id = 1001;
ROLLBACK;

SELECT 'customers' AS table_name, COUNT(*) AS rows_count FROM labwork5_shop.customers
UNION ALL
SELECT 'products', COUNT(*) FROM labwork5_shop.products
UNION ALL
SELECT 'orders', COUNT(*) FROM labwork5_shop.orders
UNION ALL
SELECT 'order_details', COUNT(*) FROM labwork5_shop.order_details;

SELECT tc.table_schema, tc.table_name, tc.constraint_name, tc.constraint_type
FROM information_schema.table_constraints tc
WHERE tc.table_schema IN ('labwork5_constraints', 'labwork5_shop')
ORDER BY tc.table_schema, tc.table_name, tc.constraint_type, tc.constraint_name;

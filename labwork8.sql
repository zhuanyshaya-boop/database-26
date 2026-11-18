CREATE TABLE IF NOT EXISTS departments (
    dept_id INT PRIMARY KEY,
    dept_name VARCHAR(50),
    location VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS employees (
    emp_id INT PRIMARY KEY,
    emp_name VARCHAR(100),
    dept_id INT REFERENCES departments(dept_id),
    salary DECIMAL(10,2)
);

CREATE TABLE IF NOT EXISTS projects (
    proj_id INT PRIMARY KEY,
    proj_name VARCHAR(100),
    budget DECIMAL(12,2),
    dept_id INT REFERENCES departments(dept_id)
);

INSERT INTO departments VALUES
(101, 'IT', 'Building A'),
(102, 'HR', 'Building B'),
(103, 'Operations', 'Building C')
ON CONFLICT (dept_id) DO NOTHING;

INSERT INTO employees (emp_id, emp_name, dept_id, salary) VALUES
(1, 'John Smith', 101, 50000),
(2, 'Jane Doe', 101, 55000),
(3, 'Mike Johnson', 102, 48000),
(4, 'Sarah Williams', 102, 52000),
(5, 'Tom Brown', 103, 60000)
ON CONFLICT (emp_id) DO NOTHING;

INSERT INTO projects VALUES
(201, 'Website Redesign', 75000, 101),
(202, 'Database Migration', 120000, 101),
(203, 'HR System Upgrade', 50000, 102)
ON CONFLICT (proj_id) DO NOTHING;

CREATE INDEX IF NOT EXISTS emp_salary_idx ON employees(salary);

SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'employees';

SELECT 'There are two indexes at this stage: the primary key index and emp_salary_idx.' AS answer;

CREATE INDEX IF NOT EXISTS emp_dept_idx ON employees(dept_id);

SELECT * FROM employees WHERE dept_id = 101;

SELECT 'Indexing a foreign key can speed up joins and searches by the foreign key value.' AS answer;

SELECT tablename, indexname, indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;

CREATE INDEX IF NOT EXISTS emp_dept_salary_idx ON employees(dept_id, salary);

SELECT emp_name, salary
FROM employees
WHERE dept_id = 101 AND salary > 52000;

SELECT 'This index is most useful when the query filters by dept_id first. It is generally not efficient for filtering by salary alone because salary is not the leading column.' AS answer;

CREATE INDEX IF NOT EXISTS emp_salary_dept_idx ON employees(salary, dept_id);

SELECT * FROM employees WHERE dept_id = 102 AND salary > 50000;

SELECT * FROM employees WHERE salary > 50000 AND dept_id = 102;

SELECT 'Column order matters. A multicolumn B-tree index is most effective when queries use its leading column or leading columns.' AS answer;

ALTER TABLE employees ADD COLUMN IF NOT EXISTS email VARCHAR(100);

UPDATE employees SET email = 'john.smith@company.com' WHERE emp_id = 1;
UPDATE employees SET email = 'jane.doe@company.com' WHERE emp_id = 2;
UPDATE employees SET email = 'mike.johnson@company.com' WHERE emp_id = 3;
UPDATE employees SET email = 'sarah.williams@company.com' WHERE emp_id = 4;
UPDATE employees SET email = 'tom.brown@company.com' WHERE emp_id = 5;

CREATE UNIQUE INDEX IF NOT EXISTS emp_email_unique_idx ON employees(email);

DO $$
BEGIN
    INSERT INTO employees (emp_id, emp_name, dept_id, salary, email)
    VALUES (6, 'New Employee', 101, 55000, 'john.smith@company.com');
EXCEPTION
    WHEN unique_violation THEN
        RAISE NOTICE 'Unique violation: duplicate email values are not allowed.';
END
$$;

SELECT 'PostgreSQL raises a unique violation error because the email already exists.' AS answer;

ALTER TABLE employees ADD COLUMN IF NOT EXISTS phone VARCHAR(20);

DO $$
BEGIN
    ALTER TABLE employees ADD CONSTRAINT employees_phone_unique UNIQUE (phone);
EXCEPTION
    WHEN duplicate_object THEN
        NULL;
END
$$;

SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'employees' AND indexname LIKE '%phone%';

SELECT 'Yes. PostgreSQL automatically creates a unique B-tree index for a UNIQUE constraint.' AS answer;

CREATE INDEX IF NOT EXISTS emp_salary_desc_idx ON employees(salary DESC);

SELECT emp_name, salary
FROM employees
ORDER BY salary DESC;

SELECT 'The index can provide rows in salary descending order and may avoid an additional sort operation.' AS answer;

CREATE INDEX IF NOT EXISTS proj_budget_nulls_first_idx ON projects(budget NULLS FIRST);

SELECT proj_name, budget
FROM projects
ORDER BY budget NULLS FIRST;

CREATE INDEX IF NOT EXISTS emp_name_lower_idx ON employees(LOWER(emp_name));

SELECT *
FROM employees
WHERE LOWER(emp_name) = 'john smith';

SELECT 'Without the expression index, PostgreSQL would generally scan rows and apply LOWER() to each employee name.' AS answer;

ALTER TABLE employees ADD COLUMN IF NOT EXISTS hire_date DATE;

UPDATE employees SET hire_date = '2020-01-15' WHERE emp_id = 1;
UPDATE employees SET hire_date = '2019-06-20' WHERE emp_id = 2;
UPDATE employees SET hire_date = '2021-03-10' WHERE emp_id = 3;
UPDATE employees SET hire_date = '2020-11-05' WHERE emp_id = 4;
UPDATE employees SET hire_date = '2018-08-25' WHERE emp_id = 5;

CREATE INDEX IF NOT EXISTS emp_hire_year_idx ON employees(EXTRACT(YEAR FROM hire_date));

SELECT emp_name, hire_date
FROM employees
WHERE EXTRACT(YEAR FROM hire_date) = 2020;

ALTER INDEX IF EXISTS emp_salary_idx RENAME TO employees_salary_index;

SELECT indexname
FROM pg_indexes
WHERE tablename = 'employees';

DROP INDEX IF EXISTS emp_salary_dept_idx;

SELECT 'Indexes may be dropped to save disk space and reduce the overhead of INSERT, UPDATE, and DELETE operations.' AS answer;

REINDEX INDEX employees_salary_index;

CREATE INDEX IF NOT EXISTS emp_salary_filter_idx
ON employees(salary)
WHERE salary > 50000;

SELECT e.emp_name, e.salary, d.dept_name
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id
WHERE e.salary > 50000
ORDER BY e.salary DESC;

CREATE INDEX IF NOT EXISTS proj_high_budget_idx
ON projects(budget)
WHERE budget > 80000;

SELECT proj_name, budget
FROM projects
WHERE budget > 80000;

SELECT 'A partial index is smaller because it stores entries only for rows that satisfy its WHERE condition.' AS answer;

EXPLAIN SELECT * FROM employees WHERE salary > 52000;

SELECT 'Index Scan means PostgreSQL uses an index. Seq Scan means it scans the table rows. For a small table, PostgreSQL may choose Seq Scan even when an index exists.' AS answer;

CREATE INDEX IF NOT EXISTS dept_name_hash_idx
ON departments USING HASH (dept_name);

SELECT * FROM departments WHERE dept_name = 'IT';

SELECT 'Use a HASH index for equality comparisons when range searches and ordering are not required. B-tree is more versatile.' AS answer;

CREATE INDEX IF NOT EXISTS proj_name_btree_idx ON projects(proj_name);

CREATE INDEX IF NOT EXISTS proj_name_hash_idx
ON projects USING HASH (proj_name);

SELECT * FROM projects WHERE proj_name = 'Website Redesign';

SELECT * FROM projects WHERE proj_name > 'Database';

SELECT schemaname, tablename, indexname,
       pg_size_pretty(pg_relation_size(indexname::regclass)) AS index_size
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;

DROP INDEX IF EXISTS proj_name_hash_idx;

CREATE OR REPLACE VIEW index_documentation AS
SELECT tablename, indexname, indexdef,
       'Improves salary-based queries' AS purpose
FROM pg_indexes
WHERE schemaname = 'public'
  AND indexname LIKE '%salary%';

SELECT * FROM index_documentation;

SELECT 'The default PostgreSQL index type is B-tree.' AS answer;

SELECT 'Create indexes for frequently used WHERE conditions, JOIN columns, and ORDER BY columns.' AS answer;

SELECT 'Avoid indexes on rarely queried columns and columns in small tables where index maintenance costs exceed the benefit.' AS answer;

SELECT 'INSERT, UPDATE, and DELETE operations also update affected indexes, which adds write overhead.' AS answer;

SELECT 'Use EXPLAIN to check whether a query uses Index Scan or Seq Scan.' AS answer;

CREATE INDEX IF NOT EXISTS emp_hire_month_idx
ON employees(EXTRACT(MONTH FROM hire_date));

CREATE UNIQUE INDEX IF NOT EXISTS emp_dept_email_unique_idx
ON employees(dept_id, email);

EXPLAIN ANALYZE
SELECT * FROM employees WHERE salary > 52000;

CREATE INDEX IF NOT EXISTS emp_covering_idx
ON employees(dept_id)
INCLUDE (emp_name, salary);

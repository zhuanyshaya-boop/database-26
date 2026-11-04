-- ============================================================
-- LABORATORY WORK 6: SQL JOINs
-- DBMS: PostgreSQL
-- ============================================================
-- Run this script from top to bottom.
-- The DROP statements make the script reusable; they remove
-- previous versions of these three lab tables.
-- ============================================================

-- PART 1. DATABASE SETUP
DROP TABLE IF EXISTS projects CASCADE;
DROP TABLE IF EXISTS employees CASCADE;
DROP TABLE IF EXISTS departments CASCADE;

CREATE TABLE employees (
    emp_id INT PRIMARY KEY,
    emp_name VARCHAR(50),
    dept_id INT,
    salary DECIMAL(10, 2)
);

CREATE TABLE departments (
    dept_id INT PRIMARY KEY,
    dept_name VARCHAR(50),
    location VARCHAR(50)
);

CREATE TABLE projects (
    project_id INT PRIMARY KEY,
    project_name VARCHAR(50),
    dept_id INT,
    budget DECIMAL(10, 2)
);

-- Sample data: employees
INSERT INTO employees (emp_id, emp_name, dept_id, salary)
VALUES
    (1, 'John Smith', 101, 50000),
    (2, 'Jane Doe', 102, 60000),
    (3, 'Mike Johnson', 101, 55000),
    (4, 'Sarah Williams', 103, 65000),
    (5, 'Tom Brown', NULL, 45000);

-- Sample data: departments
INSERT INTO departments (dept_id, dept_name, location)
VALUES
    (101, 'IT', 'Building A'),
    (102, 'HR', 'Building B'),
    (103, 'Finance', 'Building C'),
    (104, 'Marketing', 'Building D');

-- Sample data: projects
INSERT INTO projects (project_id, project_name, dept_id, budget)
VALUES
    (1, 'Website Redesign', 101, 100000),
    (2, 'Employee Training', 102, 50000),
    (3, 'Budget Analysis', 103, 75000),
    (4, 'Cloud Migration', 101, 150000),
    (5, 'AI Research', NULL, 200000);


-- ============================================================
-- PART 2. CROSS JOIN
-- ============================================================

-- Exercise 2.1: All possible employee-department combinations
SELECT e.emp_name, d.dept_name
FROM employees AS e
CROSS JOIN departments AS d;

-- Question 2.1: 5 employees x 4 departments = 20 rows.

-- Exercise 2.2a: CROSS JOIN using comma notation
SELECT e.emp_name, d.dept_name
FROM employees AS e, departments AS d;

-- Exercise 2.2b: CROSS JOIN using INNER JOIN with TRUE
SELECT e.emp_name, d.dept_name
FROM employees AS e
INNER JOIN departments AS d ON TRUE;

-- Exercise 2.3: Every employee paired with every project
SELECT e.emp_name, p.project_name
FROM employees AS e
CROSS JOIN projects AS p
ORDER BY e.emp_id, p.project_id;


-- ============================================================
-- PART 3. INNER JOIN
-- ============================================================

-- Exercise 3.1: Employees who have a department
SELECT e.emp_name, d.dept_name, d.location
FROM employees AS e
INNER JOIN departments AS d
    ON e.dept_id = d.dept_id;

-- Question 3.1: 4 rows. Tom Brown is excluded because dept_id is NULL.

-- Exercise 3.2: INNER JOIN using USING
SELECT emp_name, dept_name, location
FROM employees
INNER JOIN departments USING (dept_id);

-- Exercise 3.3: NATURAL INNER JOIN
SELECT emp_name, dept_name, location
FROM employees
NATURAL INNER JOIN departments;

-- Exercise 3.4: Join employees, departments, and projects
SELECT e.emp_name, d.dept_name, p.project_name
FROM employees AS e
INNER JOIN departments AS d
    ON e.dept_id = d.dept_id
INNER JOIN projects AS p
    ON d.dept_id = p.dept_id
ORDER BY e.emp_id, p.project_id;


-- ============================================================
-- PART 4. LEFT JOIN
-- ============================================================

-- Exercise 4.1: All employees, including employees without a department
SELECT
    e.emp_name,
    e.dept_id AS emp_dept,
    d.dept_id AS dept_dept,
    d.dept_name
FROM employees AS e
LEFT JOIN departments AS d
    ON e.dept_id = d.dept_id;

-- Tom Brown appears with NULL department columns.

-- Exercise 4.2: LEFT JOIN using USING
SELECT emp_name, dept_id, dept_name, location
FROM employees
LEFT JOIN departments USING (dept_id);

-- Exercise 4.3: Employees who are not assigned to a department
SELECT e.emp_name, e.dept_id
FROM employees AS e
LEFT JOIN departments AS d
    ON e.dept_id = d.dept_id
WHERE d.dept_id IS NULL;

-- Exercise 4.4: Count employees in every department, including zero
SELECT
    d.dept_name,
    COUNT(e.emp_id) AS employee_count
FROM departments AS d
LEFT JOIN employees AS e
    ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name
ORDER BY employee_count DESC;


-- ============================================================
-- PART 5. RIGHT JOIN
-- ============================================================

-- Exercise 5.1: All departments, including departments without employees
SELECT e.emp_name, d.dept_name
FROM employees AS e
RIGHT JOIN departments AS d
    ON e.dept_id = d.dept_id;

-- Exercise 5.2: The same result using LEFT JOIN (reverse table order)
SELECT e.emp_name, d.dept_name
FROM departments AS d
LEFT JOIN employees AS e
    ON d.dept_id = e.dept_id;

-- Exercise 5.3: Departments without employees
SELECT d.dept_name, d.location
FROM employees AS e
RIGHT JOIN departments AS d
    ON e.dept_id = d.dept_id
WHERE e.emp_id IS NULL;


-- ============================================================
-- PART 6. FULL JOIN
-- ============================================================

-- Exercise 6.1: All employees and all departments
SELECT
    e.emp_name,
    e.dept_id AS emp_dept,
    d.dept_id AS dept_dept,
    d.dept_name
FROM employees AS e
FULL JOIN departments AS d
    ON e.dept_id = d.dept_id;

-- Employees without departments have NULL department-side columns.
-- Departments without employees have NULL employee-side columns.

-- Exercise 6.2: All departments and all projects
SELECT d.dept_name, p.project_name, p.budget
FROM departments AS d
FULL JOIN projects AS p
    ON d.dept_id = p.dept_id;

-- Exercise 6.3: Find employees without departments and
-- departments without employees
SELECT
    CASE
        WHEN e.emp_id IS NULL THEN 'Department without employees'
        WHEN d.dept_id IS NULL THEN 'Employee without department'
        ELSE 'Matched'
    END AS record_status,
    e.emp_name,
    d.dept_name
FROM employees AS e
FULL JOIN departments AS d
    ON e.dept_id = d.dept_id
WHERE e.emp_id IS NULL OR d.dept_id IS NULL;


-- ============================================================
-- PART 7. ON vs WHERE
-- ============================================================

-- Exercise 7.1: Filter in ON clause (LEFT JOIN)
SELECT e.emp_name, d.dept_name, e.salary
FROM employees AS e
LEFT JOIN departments AS d
    ON e.dept_id = d.dept_id
   AND d.location = 'Building A';

-- Exercise 7.2: Filter in WHERE clause (LEFT JOIN)
SELECT e.emp_name, d.dept_name, e.salary
FROM employees AS e
LEFT JOIN departments AS d
    ON e.dept_id = d.dept_id
WHERE d.location = 'Building A';

-- Explanation:
-- ON filters which right-side rows can match; LEFT JOIN still keeps
-- every employee. WHERE filters the joined result, so employees whose
-- department is not in Building A (including NULL department matches)
-- are removed.

-- Exercise 7.3a: INNER JOIN with condition in ON
SELECT e.emp_name, d.dept_name, e.salary
FROM employees AS e
INNER JOIN departments AS d
    ON e.dept_id = d.dept_id
   AND d.location = 'Building A';

-- Exercise 7.3b: INNER JOIN with condition in WHERE
SELECT e.emp_name, d.dept_name, e.salary
FROM employees AS e
INNER JOIN departments AS d
    ON e.dept_id = d.dept_id
WHERE d.location = 'Building A';

-- Explanation: For this INNER JOIN, both queries return the same
-- result because unmatched rows are not preserved.


-- ============================================================
-- PART 8. COMPLEX JOIN SCENARIOS
-- ============================================================

-- Exercise 8.1: All departments, with employees and projects if available
SELECT
    d.dept_name,
    e.emp_name,
    e.salary,
    p.project_name,
    p.budget
FROM departments AS d
LEFT JOIN employees AS e
    ON d.dept_id = e.dept_id
LEFT JOIN projects AS p
    ON d.dept_id = p.dept_id
ORDER BY d.dept_name, e.emp_name, p.project_name;

-- Exercise 8.2: Self JOIN - employees and their managers
ALTER TABLE employees
ADD COLUMN manager_id INT;

UPDATE employees SET manager_id = 3 WHERE emp_id = 1;
UPDATE employees SET manager_id = 3 WHERE emp_id = 2;
UPDATE employees SET manager_id = NULL WHERE emp_id = 3;
UPDATE employees SET manager_id = 3 WHERE emp_id = 4;
UPDATE employees SET manager_id = 3 WHERE emp_id = 5;

SELECT
    e.emp_name AS employee,
    m.emp_name AS manager
FROM employees AS e
LEFT JOIN employees AS m
    ON e.manager_id = m.emp_id
ORDER BY e.emp_id;

-- Exercise 8.3: Departments where average employee salary is above $50,000
SELECT
    d.dept_name,
    AVG(e.salary) AS avg_salary
FROM departments AS d
INNER JOIN employees AS e
    ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name
HAVING AVG(e.salary) > 50000;


-- ============================================================
-- LAB QUESTIONS - ANSWERS
-- ============================================================

-- 1. INNER JOIN returns only rows with matches in both tables.
--    LEFT JOIN returns every row from the left table and matching
--    rows from the right table; missing right-side values are NULL.

-- 2. CROSS JOIN is useful when all combinations are needed,
--    for example, an availability matrix of employees and projects.

-- 3. For an OUTER JOIN, a condition in ON affects matching while
--    preserving unmatched rows from the preserved side. A WHERE
--    condition filters the final result and can remove those rows.
--    For an INNER JOIN, these conditions give the same result
--    when the condition is moved between ON and WHERE.

-- 4. 5 x 10 = 50 rows.

-- 5. NATURAL JOIN automatically uses all columns that have the
--    same names in both tables as join columns.

-- 6. NATURAL JOIN can become unpredictable if a new same-named
--    column is added to either table. It may silently change the
--    join condition. Explicit ON or USING is usually safer.

-- 7. SELECT *
--    FROM A
--    RIGHT JOIN B ON A.id = B.id;

-- 8. FULL OUTER JOIN is useful when all rows from both tables
--    must be retained, including unmatched rows from either side.


-- ============================================================
-- ADDITIONAL CHALLENGES (OPTIONAL)
-- ============================================================

-- Challenge 1: Simulate FULL OUTER JOIN using LEFT and RIGHT JOIN
-- with UNION. UNION removes duplicate matched rows.
SELECT e.emp_name, d.dept_name
FROM employees AS e
LEFT JOIN departments AS d
    ON e.dept_id = d.dept_id

UNION

SELECT e.emp_name, d.dept_name
FROM employees AS e
RIGHT JOIN departments AS d
    ON e.dept_id = d.dept_id;

-- Challenge 2: Employees in departments that have more than one project
SELECT DISTINCT
    e.emp_name,
    d.dept_name
FROM employees AS e
INNER JOIN departments AS d
    ON e.dept_id = d.dept_id
INNER JOIN projects AS p
    ON d.dept_id = p.dept_id
GROUP BY e.emp_id, e.emp_name, d.dept_name
HAVING COUNT(p.project_id) > 1
ORDER BY d.dept_name, e.emp_name;

-- Challenge 3: Organizational structure (employee -> manager
-- -> manager's manager). This shows up to three levels.
SELECT
    e.emp_name AS employee,
    m.emp_name AS manager,
    mm.emp_name AS managers_manager
FROM employees AS e
LEFT JOIN employees AS m
    ON e.manager_id = m.emp_id
LEFT JOIN employees AS mm
    ON m.manager_id = mm.emp_id
ORDER BY e.emp_id;

-- Challenge 4: All pairs of employees working in the same department
-- e1.emp_id < e2.emp_id prevents duplicate and self-pairs.
SELECT
    e1.emp_name AS employee_1,
    e2.emp_name AS employee_2,
    d.dept_name
FROM employees AS e1
INNER JOIN employees AS e2
    ON e1.dept_id = e2.dept_id
   AND e1.emp_id < e2.emp_id
INNER JOIN departments AS d
    ON e1.dept_id = d.dept_id
ORDER BY d.dept_name, employee_1, employee_2;


-- ============================================================
-- END OF LABORATORY WORK 6
-- ============================================================

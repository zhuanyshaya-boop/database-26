-- Laboratory Work 7: SQL Views and Roles
-- PostgreSQL

-- PART 2. BASIC VIEWS

CREATE OR REPLACE VIEW employee_details AS
SELECT
    e.emp_id,
    e.emp_name,
    e.salary,
    d.dept_name,
    d.location
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id;

SELECT * FROM employee_details;

CREATE OR REPLACE VIEW dept_statistics AS
SELECT
    d.dept_id,
    d.dept_name,
    COUNT(e.emp_id) AS employee_count,
    AVG(e.salary) AS average_salary,
    MAX(e.salary) AS maximum_salary,
    MIN(e.salary) AS minimum_salary
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name;

SELECT * FROM dept_statistics
ORDER BY employee_count DESC;

CREATE OR REPLACE VIEW project_overview AS
SELECT
    p.project_id,
    p.project_name,
    p.budget,
    d.dept_name,
    d.location,
    COUNT(DISTINCT e.emp_id) AS team_size
FROM projects p
JOIN departments d ON p.dept_id = d.dept_id
LEFT JOIN employees e ON e.dept_id = d.dept_id
GROUP BY p.project_id, p.project_name, p.budget, d.dept_name, d.location;

CREATE OR REPLACE VIEW high_earners AS
SELECT
    e.emp_id,
    e.emp_name,
    e.salary,
    d.dept_name
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id
WHERE e.salary > 55000;

SELECT * FROM high_earners;


-- PART 3. MODIFYING AND MANAGING VIEWS

CREATE OR REPLACE VIEW employee_details AS
SELECT
    e.emp_id,
    e.emp_name,
    e.salary,
    d.dept_name,
    d.location,
    CASE
        WHEN e.salary > 60000 THEN 'High'
        WHEN e.salary > 50000 THEN 'Medium'
        ELSE 'Standard'
    END AS salary_grade
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id;

ALTER VIEW high_earners RENAME TO top_performers;

SELECT * FROM top_performers;

CREATE OR REPLACE VIEW temp_view AS
SELECT emp_id, emp_name, salary
FROM employees
WHERE salary < 50000;

DROP VIEW temp_view;


-- PART 4. UPDATABLE VIEWS

CREATE OR REPLACE VIEW employee_salaries AS
SELECT emp_id, emp_name, dept_id, salary
FROM employees;

UPDATE employee_salaries
SET salary = 52000
WHERE emp_name = 'John Smith';

SELECT * FROM employees
WHERE emp_name = 'John Smith';

INSERT INTO employee_salaries (emp_id, emp_name, dept_id, salary)
VALUES (6, 'Alice Johnson', 102, 58000)
ON CONFLICT (emp_id) DO NOTHING;

SELECT * FROM employees
WHERE emp_name = 'Alice Johnson';

CREATE OR REPLACE VIEW it_employees AS
SELECT emp_id, emp_name, dept_id, salary
FROM employees
WHERE dept_id = 101
WITH LOCAL CHECK OPTION;

DO $$
BEGIN
    BEGIN
        INSERT INTO it_employees (emp_id, emp_name, dept_id, salary)
        VALUES (7, 'Bob Wilson', 103, 60000);
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'Insert rejected: employee must belong to department 101.';
    END;
END
$$;


-- PART 5. MATERIALIZED VIEWS

DROP MATERIALIZED VIEW IF EXISTS dept_summary_mv;

CREATE MATERIALIZED VIEW dept_summary_mv AS
SELECT
    d.dept_id,
    d.dept_name,
    COUNT(DISTINCT e.emp_id) AS total_employees,
    COALESCE(SUM(DISTINCT e.salary), 0) AS total_salaries,
    COUNT(DISTINCT p.project_id) AS total_projects,
    COALESCE(SUM(DISTINCT p.budget), 0) AS total_project_budget
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
LEFT JOIN projects p ON d.dept_id = p.dept_id
GROUP BY d.dept_id, d.dept_name
WITH DATA;

SELECT * FROM dept_summary_mv
ORDER BY total_employees DESC;

INSERT INTO employees (emp_id, emp_name, dept_id, salary)
VALUES (8, 'Charlie Brown', 101, 54000)
ON CONFLICT (emp_id) DO NOTHING;

SELECT * FROM dept_summary_mv
ORDER BY total_employees DESC;

REFRESH MATERIALIZED VIEW dept_summary_mv;

SELECT * FROM dept_summary_mv
ORDER BY total_employees DESC;

CREATE UNIQUE INDEX IF NOT EXISTS idx_dept_summary_mv_dept_id
ON dept_summary_mv (dept_id);

REFRESH MATERIALIZED VIEW CONCURRENTLY dept_summary_mv;

DROP MATERIALIZED VIEW IF EXISTS project_stats_mv;

CREATE MATERIALIZED VIEW project_stats_mv AS
SELECT
    p.project_name,
    p.budget,
    d.dept_name,
    COUNT(DISTINCT e.emp_id) AS assigned_employees
FROM projects p
JOIN departments d ON p.dept_id = d.dept_id
LEFT JOIN employees e ON e.dept_id = d.dept_id
GROUP BY p.project_id, p.project_name, p.budget, d.dept_name
WITH NO DATA;

-- Run after testing the unpopulated materialized view:
REFRESH MATERIALIZED VIEW project_stats_mv;

SELECT * FROM project_stats_mv;


-- PART 6. DATABASE ROLES

DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'analyst') THEN
        CREATE ROLE analyst;
    END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'data_viewer') THEN
        CREATE ROLE data_viewer LOGIN PASSWORD 'viewer123';
    END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'report_user') THEN
        CREATE ROLE report_user LOGIN PASSWORD 'report456';
    END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'db_creator') THEN
        CREATE ROLE db_creator LOGIN CREATEDB PASSWORD 'creator789';
    END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'user_manager') THEN
        CREATE ROLE user_manager LOGIN CREATEROLE PASSWORD 'manager101';
    END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'admin_user') THEN
        CREATE ROLE admin_user LOGIN SUPERUSER PASSWORD 'admin999';
    END IF;
END
$$;

SELECT rolname
FROM pg_roles
WHERE rolname NOT LIKE 'pg_%';

GRANT SELECT ON employees, departments, projects TO analyst;
GRANT ALL PRIVILEGES ON employee_details TO data_viewer;
GRANT SELECT, INSERT ON employees TO report_user;

DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'hr_team') THEN
        CREATE ROLE hr_team;
    END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'finance_team') THEN
        CREATE ROLE finance_team;
    END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'it_team') THEN
        CREATE ROLE it_team;
    END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'hr_user1') THEN
        CREATE ROLE hr_user1 LOGIN PASSWORD 'hr001';
    END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'hr_user2') THEN
        CREATE ROLE hr_user2 LOGIN PASSWORD 'hr002';
    END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'finance_user1') THEN
        CREATE ROLE finance_user1 LOGIN PASSWORD 'fin001';
    END IF;
END
$$;

GRANT hr_team TO hr_user1, hr_user2;
GRANT finance_team TO finance_user1;

GRANT SELECT, UPDATE ON employees TO hr_team;
GRANT SELECT ON dept_statistics TO finance_team;

REVOKE UPDATE ON employees FROM hr_team;
REVOKE hr_team FROM hr_user2;
REVOKE ALL PRIVILEGES ON employee_details FROM data_viewer;

ALTER ROLE analyst WITH LOGIN PASSWORD 'analyst123';
ALTER ROLE user_manager WITH SUPERUSER;
ALTER ROLE analyst WITH PASSWORD NULL;
ALTER ROLE data_viewer CONNECTION LIMIT 5;


-- PART 7. ADVANCED ROLE MANAGEMENT

DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'read_only') THEN
        CREATE ROLE read_only;
    END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'junior_analyst') THEN
        CREATE ROLE junior_analyst LOGIN PASSWORD 'junior123';
    END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'senior_analyst') THEN
        CREATE ROLE senior_analyst LOGIN PASSWORD 'senior123';
    END IF;
END
$$;

GRANT SELECT ON ALL TABLES IN SCHEMA public TO read_only;
GRANT read_only TO junior_analyst, senior_analyst;
GRANT INSERT, UPDATE ON employees TO senior_analyst;

DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'project_manager') THEN
        CREATE ROLE project_manager LOGIN PASSWORD 'pm123';
    END IF;
END
$$;

ALTER VIEW dept_statistics OWNER TO project_manager;
ALTER TABLE projects OWNER TO project_manager;

SELECT tablename, tableowner
FROM pg_tables
WHERE schemaname = 'public';

DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'temp_owner') THEN
        CREATE ROLE temp_owner LOGIN;
    END IF;
END
$$;

CREATE TABLE IF NOT EXISTS temp_table (
    id INT
);

ALTER TABLE temp_table OWNER TO temp_owner;

REASSIGN OWNED BY temp_owner TO postgres;
DROP OWNED BY temp_owner;
DROP ROLE temp_owner;

CREATE OR REPLACE VIEW hr_employee_view AS
SELECT emp_id, emp_name, dept_id, salary
FROM employees
WHERE dept_id = 102;

GRANT SELECT ON hr_employee_view TO hr_team;

CREATE OR REPLACE VIEW finance_employee_view AS
SELECT emp_id, emp_name, salary
FROM employees;

GRANT SELECT ON finance_employee_view TO finance_team;


-- PART 8. PRACTICAL SCENARIOS

CREATE OR REPLACE VIEW dept_dashboard AS
SELECT
    d.dept_id,
    d.dept_name,
    d.location,
    COUNT(DISTINCT e.emp_id) AS employee_count,
    ROUND(AVG(e.salary), 2) AS average_salary,
    COUNT(DISTINCT p.project_id) AS active_projects,
    COALESCE(SUM(DISTINCT p.budget), 0) AS total_project_budget,
    ROUND(
        COALESCE(SUM(DISTINCT p.budget), 0) /
        NULLIF(COUNT(DISTINCT e.emp_id), 0),
        2
    ) AS budget_per_employee
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
LEFT JOIN projects p ON d.dept_id = p.dept_id
GROUP BY d.dept_id, d.dept_name, d.location;

ALTER TABLE projects
ADD COLUMN IF NOT EXISTS created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

CREATE OR REPLACE VIEW high_budget_projects AS
SELECT
    p.project_name,
    p.budget,
    d.dept_name,
    p.created_date,
    CASE
        WHEN p.budget > 150000 THEN 'Critical Review Required'
        WHEN p.budget > 100000 THEN 'Management Approval Needed'
        ELSE 'Standard Process'
    END AS approval_status
FROM projects p
JOIN departments d ON p.dept_id = d.dept_id
WHERE p.budget > 75000;

DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'viewer_role') THEN
        CREATE ROLE viewer_role;
    END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'entry_role') THEN
        CREATE ROLE entry_role;
    END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'analyst_role') THEN
        CREATE ROLE analyst_role;
    END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'manager_role') THEN
        CREATE ROLE manager_role;
    END IF;
END
$$;

GRANT SELECT ON ALL TABLES IN SCHEMA public TO viewer_role;
GRANT viewer_role TO entry_role;
GRANT INSERT ON employees, projects TO entry_role;
GRANT entry_role TO analyst_role;
GRANT UPDATE ON employees, projects TO analyst_role;
GRANT analyst_role TO manager_role;
GRANT DELETE ON employees, projects TO manager_role;

DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'alice') THEN
        CREATE ROLE alice LOGIN PASSWORD 'alice123';
    END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'bob') THEN
        CREATE ROLE bob LOGIN PASSWORD 'bob123';
    END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'charlie') THEN
        CREATE ROLE charlie LOGIN PASSWORD 'charlie123';
    END IF;
END
$$;

GRANT viewer_role TO alice;
GRANT analyst_role TO bob;
GRANT manager_role TO charlie;


-- FINAL CHECKS

SELECT * FROM employee_details;
SELECT * FROM dept_statistics;
SELECT * FROM project_overview;
SELECT * FROM top_performers;
SELECT * FROM dept_summary_mv;
SELECT * FROM project_stats_mv;
SELECT * FROM dept_dashboard;
SELECT * FROM high_budget_projects;
SELECT * FROM hr_employee_view;
SELECT * FROM finance_employee_view;

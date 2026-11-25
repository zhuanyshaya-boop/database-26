-- ============================================================
-- Laboratory Work 9: Stored Procedures and User-Defined Functions
-- Part 1: Database Setup  (CityBike rental network)
-- ============================================================

DROP TABLE IF EXISTS rentals, bikes, members, stations CASCADE;

-- Create table: stations
CREATE TABLE stations (
    station_id   INT PRIMARY KEY,
    station_name VARCHAR(50) NOT NULL,
    city         VARCHAR(40) NOT NULL,
    capacity     INT NOT NULL
);

-- Create table: bikes
CREATE TABLE bikes (
    bike_id    INT PRIMARY KEY,
    model      VARCHAR(50) NOT NULL,
    station_id INT REFERENCES stations(station_id),
    daily_rate NUMERIC(8,2) NOT NULL
);

-- Create table: members
CREATE TABLE members (
    member_id INT PRIMARY KEY,
    full_name VARCHAR(60) NOT NULL,
    city      VARCHAR(40) NOT NULL,
    joined_on DATE NOT NULL
);

-- Create table: rentals
CREATE TABLE rentals (
    rental_id  INT PRIMARY KEY,
    member_id  INT REFERENCES members(member_id),
    bike_id    INT REFERENCES bikes(bike_id),
    start_date DATE NOT NULL,
    end_date   DATE,
    fee        NUMERIC(8,2)
);

INSERT INTO stations VALUES
 (10, 'Central Park', 'Almaty',   4),
 (20, 'Riverside',    'Almaty',   3),
 (30, 'Expo Gate',    'Astana',   5),
 (40, 'Old Town',     'Shymkent', 2),
 (50, 'Depot',        'Astana',   0);

INSERT INTO bikes VALUES
 (101, 'City Cruiser', 10,  4.50),
 (102, 'City Cruiser', 10,  4.50),
 (103, 'Mountain X',   20,  7.00),
 (104, 'Mountain X',   30,  7.00),
 (105, 'Road Sprint',  30,  9.25),
 (106, 'Folding Mini', 40,  3.75),
 (107, 'Cargo Hauler', 20, 12.00),
 (108, 'Road Sprint',  10,  9.25);

INSERT INTO members VALUES
 (1, 'Aisha Nurlanova', 'Almaty',   DATE '2023-03-14'),
 (2, 'Daniyar Serik',   'Almaty',   DATE '2023-07-02'),
 (3, 'Marta Kowalski',  'Astana',   DATE '2024-01-20'),
 (4, 'Chen Wei',        'Astana',   DATE '2024-05-11'),
 (5, 'Omar Haddad',     'Shymkent', DATE '2024-09-30'),
 (6, 'Elena Petrova',   'Almaty',   DATE '2025-02-05');

INSERT INTO rentals VALUES
 ( 1, 1, 101, DATE '2024-04-05', DATE '2024-04-08', 13.50),
 ( 2, 1, 103, DATE '2024-06-11', DATE '2024-06-16', 35.00),
 ( 3, 1, 108, DATE '2025-02-02', DATE '2025-02-04', 18.50),
 ( 4, 1, 102, DATE '2025-05-20', DATE '2025-05-27', 31.50),
 ( 5, 2, 101, DATE '2024-05-01', DATE '2024-05-02',  4.50),
 ( 6, 2, 107, DATE '2024-11-15', DATE '2024-11-19', 48.00),
 ( 7, 2, 107, DATE '2025-03-08', DATE '2025-03-14', 72.00),
 ( 8, 3, 104, DATE '2024-02-14', DATE '2024-02-18', 28.00),
 ( 9, 3, 105, DATE '2024-08-03', DATE '2024-08-06', 27.75),
 (10, 3, 104, DATE '2025-01-09', DATE '2025-01-10',  7.00),
 (11, 3, 105, DATE '2025-06-01', DATE '2025-06-09', 74.00),
 (12, 4, 104, DATE '2024-07-19', DATE '2024-07-21', 14.00),
 (13, 4, 105, DATE '2025-04-12', DATE '2025-04-15', 27.75),
 (14, 4, 103, DATE '2025-07-23', DATE '2025-07-29', 42.00),
 (15, 5, 106, DATE '2024-10-05', DATE '2024-10-12', 26.25),
 (16, 5, 106, DATE '2025-01-18', DATE '2025-01-20',  7.50),
 (17, 5, 106, DATE '2025-08-14', DATE '2025-08-21', 26.25),
 (18, 2, 102, DATE '2025-09-02', DATE '2025-09-05', 13.50),
 (19, 1, 101, DATE '2025-10-10', NULL,              NULL),
 (20, 4, 108, DATE '2024-12-28', DATE '2025-01-03', 55.50),
 (21, 3, 103, DATE '2025-02-26', DATE '2025-03-02', 28.00),
 (22, 5, 104, DATE '2025-05-05', DATE '2025-05-08', 21.00);
-- 2.1
CREATE OR REPLACE FUNCTION rental_days(p_rental_id INT) RETURNS INT AS $$
DECLARE d INT;
BEGIN SELECT end_date-start_date INTO d FROM rentals WHERE rental_id=p_rental_id; RETURN d; END; $$ LANGUAGE plpgsql;
SELECT rental_days(2), rental_days(11), rental_days(19), rental_days(999);
-- 19: NULL из-за отсутствия end_date; 999: NULL из-за отсутствия строки.
-- 2.2
CREATE OR REPLACE FUNCTION member_rental_count(p_member_id INT) RETURNS INT AS $$
BEGIN RETURN (SELECT COUNT(*)::INT FROM rentals WHERE member_id=p_member_id); END; $$ LANGUAGE plpgsql;
SELECT member_rental_count(1), member_rental_count(5), member_rental_count(6), member_rental_count(99);
-- COUNT(*) считает строки, поэтому пустой набор дает 0.
-- 2.3
CREATE OR REPLACE FUNCTION station_city(p_station_id INT) RETURNS VARCHAR AS $$
BEGIN RETURN (SELECT city FROM stations WHERE station_id=p_station_id); END; $$ LANGUAGE plpgsql;
SELECT station_city(30), station_city(77);
-- 2.4
SELECT rental_id, member_id, rental_days(rental_id) AS duration FROM rentals WHERE rental_days(rental_id)>4 ORDER BY duration DESC;
-- 3.1
CREATE OR REPLACE FUNCTION fee_with_discount(p_fee NUMERIC,p_percent NUMERIC) RETURNS NUMERIC AS $$
BEGIN RETURN ROUND(p_fee*(1-p_percent/100),2); END; $$ LANGUAGE plpgsql;
SELECT fee_with_discount(74.00,15);
-- 3.2
CREATE OR REPLACE FUNCTION member_stats(p_member_id INT, OUT rental_cnt INT, OUT total_fee NUMERIC, OUT last_start DATE) AS $$
BEGIN SELECT COUNT(*)::INT,COALESCE(SUM(fee),0),MAX(start_date) INTO rental_cnt,total_fee,last_start FROM rentals WHERE member_id=p_member_id; END; $$ LANGUAGE plpgsql;
SELECT member_stats(3);
SELECT * FROM member_stats(3);
SELECT * FROM member_stats(6);
-- Первый вызов дает составное значение, второй — отдельные столбцы, удобные для JOIN. Для 6: 0, 0, NULL.
-- 3.3
CREATE OR REPLACE FUNCTION apply_late_fee(INOUT p_fee NUMERIC) AS $$
BEGIN p_fee:=p_fee+5; END; $$ LANGUAGE plpgsql;
SELECT apply_late_fee(fee) FROM rentals WHERE rental_id=1;
-- INOUT автоматически возвращает измененное значение.
-- 3.4
CREATE OR REPLACE FUNCTION fee_summary(VARIADIC p_fees NUMERIC[], OUT total NUMERIC, OUT average NUMERIC, OUT largest NUMERIC) AS $$
BEGIN SELECT SUM(p_fees[i]),ROUND(AVG(p_fees[i]),2),MAX(p_fees[i]) INTO total,average,largest FROM generate_subscripts(p_fees,1) g(i); END; $$ LANGUAGE plpgsql;
SELECT * FROM fee_summary(13.50,35.00,18.50,31.50);
DO $$ BEGIN PERFORM fee_summary(); EXCEPTION WHEN undefined_function THEN RAISE NOTICE '%',SQLERRM; END; $$;
SELECT * FROM fee_summary(VARIADIC ARRAY[]::NUMERIC[]);
-- Без аргументов функция не находится; явный пустой массив дает три NULL. VARIADIC должен быть последним входным параметром.
-- 3.5: a) IN — входной ID; b) INOUT — изменяемый баланс; c) VARIADIC — произвольное число ID; d) OUT — два результата.
-- 4.1
DROP FUNCTION IF EXISTS total_fees(INT,DATE);
DROP FUNCTION IF EXISTS total_fees(VARCHAR);
CREATE OR REPLACE FUNCTION total_fees(p_member_id INT) RETURNS NUMERIC AS $$
BEGIN RETURN (SELECT COALESCE(SUM(fee),0) FROM rentals WHERE member_id=p_member_id); END; $$ LANGUAGE plpgsql;
SELECT total_fees(1),total_fees(6);
-- 4.2
CREATE OR REPLACE FUNCTION total_fees(p_member_id INT,p_from_date DATE) RETURNS NUMERIC AS $$
BEGIN RETURN (SELECT COALESCE(SUM(fee),0) FROM rentals WHERE member_id=p_member_id AND start_date>=p_from_date); END; $$ LANGUAGE plpgsql;
SELECT total_fees(1,DATE '2024-01-01'),total_fees(1,DATE '2025-01-01');
SELECT oid::regprocedure FROM pg_proc WHERE proname='total_fees';
-- 4.3
CREATE OR REPLACE FUNCTION total_fees(p_member_id INT,p_from_date DATE DEFAULT DATE '2025-01-01') RETURNS NUMERIC AS $$
BEGIN RETURN (SELECT COALESCE(SUM(fee),0) FROM rentals WHERE member_id=p_member_id AND start_date>=p_from_date); END; $$ LANGUAGE plpgsql;
DO $$ DECLARE h TEXT; BEGIN PERFORM total_fees(1); EXCEPTION WHEN ambiguous_function THEN GET STACKED DIAGNOSTICS h=PG_EXCEPTION_HINT; RAISE NOTICE 'ERROR: %; HINT: %',SQLERRM,h; END; $$;
-- Обе сигнатуры подходят к вызову с одним INT, поэтому выбор неоднозначен.
-- 4.4
DROP FUNCTION total_fees(INT);
SELECT total_fees(1);
-- Версия с DEFAULT возвращает 50.00; если удалить ее вместо первой, результат 98.50.
-- 4.5
CREATE OR REPLACE FUNCTION total_fees(p_name VARCHAR) RETURNS NUMERIC AS $$
BEGIN RETURN (SELECT COALESCE(SUM(r.fee),0) FROM rentals r JOIN members m USING(member_id) WHERE m.full_name=p_name); END; $$ LANGUAGE plpgsql;
SELECT total_fees('Aisha Nurlanova'),total_fees(1);
-- VARCHAR выбирает все даты (98.50), INT — начиная с 2025 (50.00); типы различаются.
-- 5.1
CREATE OR REPLACE FUNCTION find_bikes(p_pattern VARCHAR) RETURNS TABLE(found_id INT,found_model VARCHAR,found_rate NUMERIC) AS $$
BEGIN RETURN QUERY SELECT b.bike_id,b.model,b.daily_rate FROM bikes b WHERE b.model ILIKE p_pattern ORDER BY b.bike_id; END; $$ LANGUAGE plpgsql;
SELECT * FROM find_bikes('%road%');
SELECT * FROM find_bikes('%Mini');
SELECT find_bikes('%road%');
-- Без FROM каждая строка представлена одним составным значением.
-- 5.2
CREATE OR REPLACE FUNCTION member_history(p_member_id INT) RETURNS TABLE(rental_id INT,bike_model VARCHAR,station_name VARCHAR,duration INT,fee NUMERIC) AS $$
BEGIN RETURN QUERY SELECT r.rental_id,b.model,s.station_name,r.end_date-r.start_date,r.fee FROM rentals r JOIN bikes b ON b.bike_id=r.bike_id JOIN stations s ON s.station_id=b.station_id WHERE r.member_id=p_member_id ORDER BY r.start_date; END; $$ LANGUAGE plpgsql;
SELECT * FROM member_history(3);
-- 5.3
DROP FUNCTION IF EXISTS bike_list(INT);
CREATE FUNCTION bike_list(p_station_id INT) RETURNS TABLE(bike_id INT,model VARCHAR) AS $$
BEGIN RETURN QUERY SELECT bike_id,model FROM bikes WHERE station_id=p_station_id; END; $$ LANGUAGE plpgsql;
DO $$ BEGIN PERFORM * FROM bike_list(10); EXCEPTION WHEN ambiguous_column THEN RAISE NOTICE 'ERROR: %',SQLERRM; END; $$;
-- SQL внутри PL/pgSQL анализируется при выполнении; имена OUT совпадают с именами столбцов.
DROP FUNCTION bike_list(INT);
CREATE FUNCTION bike_list(p_station_id INT) RETURNS TABLE(found_id INT,found_model VARCHAR) AS $$
BEGIN RETURN QUERY SELECT bike_id,model FROM bikes WHERE station_id=p_station_id; END; $$ LANGUAGE plpgsql;
SELECT * FROM bike_list(10);
DROP FUNCTION bike_list(INT);
CREATE FUNCTION bike_list(p_station_id INT) RETURNS TABLE(bike_id INT,model VARCHAR) AS $$
BEGIN RETURN QUERY SELECT b.bike_id,b.model FROM bikes b WHERE b.station_id=p_station_id; END; $$ LANGUAGE plpgsql;
SELECT * FROM bike_list(10);
-- 5.4
CREATE OR REPLACE FUNCTION station_board(p_city VARCHAR) RETURNS TABLE(s_name VARCHAR,s_bikes INT,s_free INT) AS $$
BEGIN RETURN QUERY SELECT s.station_name,COUNT(b.bike_id),s.capacity-COUNT(b.bike_id) FROM stations s LEFT JOIN bikes b USING(station_id) WHERE s.city=p_city GROUP BY s.station_id; END; $$ LANGUAGE plpgsql;
DO $$ DECLARE d TEXT; BEGIN PERFORM * FROM station_board('Astana'); EXCEPTION WHEN datatype_mismatch THEN GET STACKED DIAGNOSTICS d=PG_EXCEPTION_DETAIL; RAISE NOTICE 'ERROR: %; DETAIL: %',SQLERRM,d; END; $$;
-- BIGINT не соответствует объявленному INT.
CREATE OR REPLACE FUNCTION station_board(p_city VARCHAR) RETURNS TABLE(s_name VARCHAR,s_bikes INT,s_free INT) AS $$
BEGIN RETURN QUERY SELECT s.station_name,COUNT(b.bike_id)::INT,s.capacity-COUNT(b.bike_id)::INT FROM stations s LEFT JOIN bikes b USING(station_id) WHERE s.city=p_city GROUP BY s.station_id ORDER BY s.station_id; END; $$ LANGUAGE plpgsql;
SELECT * FROM station_board('Astana');
-- 6.1
DO $$ <<rental_report>> DECLARE total_rentals INT:=0; BEGIN SELECT COUNT(*) INTO total_rentals FROM rentals; RAISE NOTICE 'The rentals table holds % rows.',total_rentals; END rental_report; $$;
-- Несовпадение меток BEGIN/END вызывает синтаксическую ошибку.
-- 6.2
DO $$ <<rental_report>> DECLARE fee_total NUMERIC; BEGIN SELECT SUM(fee) INTO fee_total FROM rentals; RAISE NOTICE '%',fee_total; DECLARE fee_total NUMERIC; BEGIN SELECT SUM(fee) INTO fee_total FROM rentals WHERE start_date>=DATE '2025-01-01'; RAISE NOTICE '%',fee_total; RAISE NOTICE '%',rental_report.fee_total; END; RAISE NOTICE '%',fee_total; END rental_report; $$;
-- Внутренняя переменная скрывает внешнюю, но не меняет ее.
-- 6.3
DO $$ BEGIN DECLARE local_value INT:=10; BEGIN RAISE NOTICE '%',local_value; END; BEGIN RAISE NOTICE '%',local_value; EXCEPTION WHEN undefined_column THEN RAISE NOTICE '%',SQLERRM; END; END; $$;
DO $$ DECLARE local_value INT:=10; BEGIN BEGIN RAISE NOTICE '%',local_value; END; BEGIN RAISE NOTICE '%',local_value; END; END; $$;
-- Переменная доступна только в своем блоке и вложенных блоках.
-- 6.4
CREATE OR REPLACE FUNCTION fee_split(p_from_date DATE,OUT before_total NUMERIC,OUT after_total NUMERIC) AS $$
BEGIN SELECT COALESCE(SUM(fee) FILTER(WHERE start_date<p_from_date),0),COALESCE(SUM(fee) FILTER(WHERE start_date>=p_from_date),0) INTO before_total,after_total FROM rentals; END; $$ LANGUAGE plpgsql;
SELECT *,before_total+after_total AS combined,(SELECT SUM(fee) FROM rentals) AS actual FROM fee_split(DATE '2025-01-01');
-- 7.1
CREATE OR REPLACE FUNCTION station_load(p_station_id INT,OUT bikes_parked INT,OUT capacity_pct NUMERIC) AS $$
BEGIN SELECT COUNT(b.bike_id)::INT,ROUND(100.0*COUNT(b.bike_id)/NULLIF(s.capacity,0),1) INTO bikes_parked,capacity_pct FROM stations s LEFT JOIN bikes b USING(station_id) WHERE s.station_id=p_station_id GROUP BY s.capacity; END; $$ LANGUAGE plpgsql;
SELECT s.station_id,s.station_name,l.* FROM stations s,LATERAL station_load(s.station_id) l;
-- При нулевой вместимости процент NULL, поскольку отношение не определено.
-- 7.2
CREATE OR REPLACE FUNCTION top_members(p_limit INT DEFAULT 3) RETURNS TABLE(member_name VARCHAR,rental_count INT,total_spent NUMERIC) AS $$
BEGIN RETURN QUERY SELECT m.full_name,COUNT(r.rental_id)::INT,COALESCE(SUM(r.fee),0) FROM members m LEFT JOIN rentals r USING(member_id) GROUP BY m.member_id ORDER BY 3 DESC,m.member_id LIMIT p_limit; END; $$ LANGUAGE plpgsql;
SELECT * FROM top_members();
SELECT * FROM top_members(6);
-- Aisha имеет 5 аренд, но тратит меньше Chen (4 аренды); сортировка по сумме, не по количеству.
-- 7.3
CREATE OR REPLACE FUNCTION rental_invoice(p_rental_id INT) RETURNS TABLE(member_name VARCHAR,bike_model VARCHAR,days INT,amount NUMERIC,status TEXT) AS $$
BEGIN RETURN QUERY SELECT m.full_name,b.model,COALESCE(r.end_date,CURRENT_DATE)-r.start_date,ROUND((COALESCE(r.end_date,CURRENT_DATE)-r.start_date)*b.daily_rate,2),CASE WHEN r.end_date IS NULL THEN 'OPEN' ELSE 'CLOSED' END FROM rentals r JOIN members m USING(member_id) JOIN bikes b USING(bike_id) WHERE r.rental_id=p_rental_id; END; $$ LANGUAGE plpgsql;
SELECT * FROM rental_invoice(11);
SELECT * FROM rental_invoice(19);
-- 11: 74.00 совпадает. 19: сумма зависит от CURRENT_DATE; функция не IMMUTABLE.
-- 7.4
CREATE OR REPLACE FUNCTION city_report(p_city VARCHAR,OUT member_count INT,OUT rental_count INT,OUT revenue NUMERIC) AS $$
BEGIN SELECT COUNT(DISTINCT m.member_id)::INT,COUNT(r.rental_id)::INT,COALESCE(SUM(r.fee),0) INTO member_count,rental_count,revenue FROM members m LEFT JOIN rentals r USING(member_id) WHERE m.city=p_city; END; $$ LANGUAGE plpgsql;
CREATE OR REPLACE FUNCTION city_report(p_city VARCHAR,p_from_date DATE,OUT member_count INT,OUT rental_count INT,OUT revenue NUMERIC) AS $$
BEGIN SELECT COUNT(DISTINCT m.member_id)::INT,COUNT(r.rental_id)::INT,COALESCE(SUM(r.fee),0) INTO member_count,rental_count,revenue FROM members m LEFT JOIN rentals r ON m.member_id=r.member_id AND r.start_date>=p_from_date WHERE m.city=p_city; END; $$ LANGUAGE plpgsql;
SELECT * FROM city_report('Almaty');
SELECT * FROM city_report('Almaty',DATE '2025-01-01');
SELECT COUNT(DISTINCT m.member_id) FROM members m LEFT JOIN rentals r USING(member_id) WHERE m.city='Almaty' AND r.start_date>=DATE '2025-01-01';
-- ON сохраняет всех 3 участников; WHERE исключает Elena, остается 2.
-- Lab Questions
-- 1. Сигнатура — имя и типы входных аргументов. Она позволяет однозначно удалить перегрузку.
-- 2. $$ позволяет не экранировать одинарные кавычки, например: $$ BEGIN RETURN 'It''s ready'; END; $$.
-- 3. OUT — несколько значений одной записи; RETURNS TABLE — набор строк.
-- 4. VARIADIC поглощает оставшиеся входные аргументы: f(1,2,3) иначе неясно разделять между массивом и последующими параметрами.
-- 5. RETURN завершает функцию и возвращает значение; RETURN QUERY добавляет строки запроса в результат табличной функции.
-- 6. DEFAULT позволяет вызвать несколько перегрузок одинаково. Нужно избегать пересекающихся сигнатур с учетом DEFAULT.
-- 7. Локальная переменная исчезает при выходе из блока. Внешняя доступна через label.variable.
-- 8. Плюс: единая бизнес-логика. Минус: зависимость от СУБД и нагрузка на сервер.
-- 9. Trusted ограничивает доступ к ОС; обычный пользователь с нужными правами может создавать функции. Untrusted требует суперпользователя.
-- 10. Изменение типов входных аргументов создает новую перегрузку, старая остается и может вызывать неоднозначность.

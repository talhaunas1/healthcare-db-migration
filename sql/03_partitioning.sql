-- =============================================================
-- 03_partitioning.sql
-- Range partitioning of the observations table by date
-- Run in pgAdmin (PostgreSQL) against: clinic_new
-- =============================================================

-- Step 1. Understand the data before designing partitions
SELECT MIN(date), MAX(date) FROM observations;
-- Result: 1932-06-21 to 2021-11-19

SELECT (EXTRACT(YEAR FROM date)::int / 10) * 10 AS decade,
       COUNT(*) AS row_count
FROM observations
GROUP BY decade
ORDER BY decade;
-- Result: data is skewed; 2010s hold 340,794 rows (64%)
-- Design: group old decades together, keep recent decades separate

-- Step 2. Partitioned parent table ("front door", holds no data itself)
CREATE TABLE observations_part (
    date         TIMESTAMP,
    patient      VARCHAR(50),
    encounter    VARCHAR(50),
    category     VARCHAR(50),
    code         VARCHAR(50),
    description  TEXT,
    value        TEXT,
    units        VARCHAR(50),
    type         VARCHAR(50)
) PARTITION BY RANGE (date);

-- Step 3. Partitions (FROM is inclusive, TO is exclusive)
CREATE TABLE observations_before_2000 PARTITION OF observations_part
    FOR VALUES FROM (MINVALUE) TO ('2000-01-01');

CREATE TABLE observations_2000s PARTITION OF observations_part
    FOR VALUES FROM ('2000-01-01') TO ('2010-01-01');

CREATE TABLE observations_2010s PARTITION OF observations_part
    FOR VALUES FROM ('2010-01-01') TO ('2020-01-01');

CREATE TABLE observations_2020s PARTITION OF observations_part
    FOR VALUES FROM ('2020-01-01') TO ('2030-01-01');

-- Safety net: catches rows that fit no other partition (should stay empty)
CREATE TABLE observations_default PARTITION OF observations_part DEFAULT;

-- Step 4. Load data (PostgreSQL routes each row to its partition)
INSERT INTO observations_part
SELECT * FROM observations;

-- Step 5. Verify where rows landed
SELECT tableoid::regclass AS partition, COUNT(*) AS row_count
FROM observations_part
GROUP BY partition
ORDER BY partition;
-- Result: before_2000 53,589 | 2000s 37,811 | 2010s 340,794
--         2020s 98,950 | default 0 | total 531,144

-- Step 6. Prove partition pruning
-- A: normal table (scans everything)
EXPLAIN ANALYZE
SELECT COUNT(*) FROM observations
WHERE date >= '2020-01-01';
-- Result: 12,722 pages read, 432,195 rows discarded

-- B: partitioned table (scans only the 2020s partition)
EXPLAIN ANALYZE
SELECT COUNT(*) FROM observations_part
WHERE date >= '2020-01-01';
-- Result: 2,388 pages read, 0 rows discarded (about 5x less I/O)

-- Database size (compare with the 13.8 MB backup file)
SELECT pg_size_pretty(pg_database_size('clinic_new'));
-- Result: 151 MB

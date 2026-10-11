-- =============================================================
-- 01_source_profiling.sql
-- Source data profiling for the legacy clinic database
-- Run in SSMS (SQL Server) against: clinic_legacy
-- =============================================================

USE clinic_legacy;

-- Q1. Row counts per table (source baseline for validation)
SELECT 'patients' AS table_name, COUNT(*) AS row_count FROM patients
UNION ALL SELECT 'encounters', COUNT(*) FROM encounters
UNION ALL SELECT 'conditions', COUNT(*) FROM conditions
UNION ALL SELECT 'medications', COUNT(*) FROM medications
UNION ALL SELECT 'observations', COUNT(*) FROM observations;
-- Result: patients 1,163 | encounters 61,459 | conditions 38,094
--         medications 56,430 | observations 531,144 | total 688,290

-- Q2. Columns and data types (input for schema mapping)
SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
ORDER BY TABLE_NAME, ORDINAL_POSITION;

-- Q3. Primary key check: are patient IDs unique?
SELECT COUNT(*) AS total_rows, COUNT(DISTINCT Id) AS unique_ids
FROM patients;
-- Result: 1,163 = 1,163 (no duplicates)

-- Q4. Orphan checks: child rows pointing to missing parents
SELECT COUNT(*) AS orphan_conditions
FROM conditions c
LEFT JOIN patients p ON c.PATIENT = p.Id
WHERE p.Id IS NULL;
-- Result: 0

SELECT COUNT(*) AS orphan_observations
FROM observations o
LEFT JOIN patients p ON o.PATIENT = p.Id
WHERE p.Id IS NULL;

SELECT COUNT(*) AS conditions_missing_encounter
FROM conditions c
LEFT JOIN encounters e ON c.ENCOUNTER = e.Id
WHERE e.Id IS NULL;

-- Q5. NULL counts in key columns
SELECT COUNT(*) - COUNT(DEATHDATE) AS alive_patients FROM patients;
SELECT COUNT(*) - COUNT(STOP) AS ongoing_conditions FROM conditions;
SELECT COUNT(*) - COUNT(ZIP) AS patients_without_zip FROM patients;
-- Result: 545 patients have no ZIP (confirmed present in original CSV)

-- Q6. Longest text values (to size target columns)
SELECT MAX(LEN(DESCRIPTION)) AS max_desc_len FROM conditions;
SELECT MAX(LEN(DESCRIPTION)) AS max_desc_len FROM observations;
SELECT MAX(LEN(VALUE)) AS max_value_len FROM observations;

-- Q7. Table sizes on disk (identifies tables needing chunked migration)
EXEC sp_spaceused 'observations';
EXEC sp_spaceused 'encounters';

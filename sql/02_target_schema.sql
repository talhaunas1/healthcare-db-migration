-- =============================================================
-- 02_target_schema.sql
-- Target schema for the new clinic database
-- Run in pgAdmin (PostgreSQL) against: clinic_new
--
-- Design decisions:
--   * Lowercase column names (PostgreSQL convention)
--   * Money: float -> NUMERIC(18,2) (exact decimal)
--   * Medical codes stored as text (identifiers, not numbers)
--   * dispenses: text -> INTEGER
--   * Foreign keys added (the source had none)
--   * Create order follows dependencies: patients -> encounters -> children
-- =============================================================

CREATE TABLE IF NOT EXISTS patients (
    id                   VARCHAR(50) PRIMARY KEY,
    birthdate            DATE,
    deathdate            DATE,
    ssn                  VARCHAR(50),
    drivers              VARCHAR(50),
    passport             VARCHAR(50),
    prefix               VARCHAR(50),
    first                VARCHAR(100),
    last                 VARCHAR(100),
    suffix               VARCHAR(50),
    maiden               VARCHAR(100),
    marital              VARCHAR(50),
    race                 VARCHAR(50),
    ethnicity            VARCHAR(50),
    gender               VARCHAR(50),
    birthplace           VARCHAR(255),
    address              VARCHAR(255),
    city                 VARCHAR(100),
    state                VARCHAR(100),
    county               VARCHAR(100),
    zip                  VARCHAR(10),
    lat                  DOUBLE PRECISION,
    lon                  DOUBLE PRECISION,
    healthcare_expenses  NUMERIC(18,2),
    healthcare_coverage  NUMERIC(18,2)
);

CREATE TABLE IF NOT EXISTS encounters (
    id                   VARCHAR(50) PRIMARY KEY,
    start                TIMESTAMP,
    stop                 TIMESTAMP,
    patient              VARCHAR(50) REFERENCES patients(id),
    organization         VARCHAR(50),
    provider             VARCHAR(50),
    payer                VARCHAR(50),
    encounterclass       VARCHAR(50),
    code                 VARCHAR(50),
    description          TEXT,
    base_encounter_cost  NUMERIC(18,2),
    total_claim_cost     NUMERIC(18,2),
    payer_coverage       NUMERIC(18,2),
    reasoncode           VARCHAR(50),
    reasondescription    TEXT
);

CREATE TABLE IF NOT EXISTS conditions (
    start                DATE,
    stop                 DATE,
    patient              VARCHAR(50) REFERENCES patients(id),
    encounter            VARCHAR(50) REFERENCES encounters(id),
    code                 VARCHAR(50),
    description          TEXT
);

CREATE TABLE IF NOT EXISTS medications (
    start                TIMESTAMP,
    stop                 TIMESTAMP,
    patient              VARCHAR(50) REFERENCES patients(id),
    payer                VARCHAR(50),
    encounter            VARCHAR(50) REFERENCES encounters(id),
    code                 VARCHAR(50),
    description          TEXT,
    base_cost            NUMERIC(18,2),
    payer_coverage       NUMERIC(18,2),
    dispenses            INTEGER,
    totalcost            NUMERIC(18,2),
    reasoncode           VARCHAR(50),
    reasondescription    TEXT
);

CREATE TABLE IF NOT EXISTS observations (
    date                 TIMESTAMP,
    patient              VARCHAR(50) REFERENCES patients(id),
    encounter            VARCHAR(50) REFERENCES encounters(id),
    category             VARCHAR(50),
    code                 VARCHAR(50),
    description          TEXT,
    value                TEXT,
    units                VARCHAR(50),
    type                 VARCHAR(50)
);

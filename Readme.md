# Healthcare Database Migration: SQL Server → PostgreSQL

Migrated 688K synthetic patient records (Synthea) from SQL Server to PostgreSQL with Python, including schema conversion, chunked loading, reconciliation, backup/restore testing and table partitioning.

**Tech:** SQL Server, PostgreSQL, Python, pandas, SQLAlchemy, pyodbc, SSMS, pgAdmin

**Read the full write-up:** [MIGRATION_REPORT.md](MIGRATION_REPORT.md)

## Project structure
- `sql/`: source profiling, target schema, partitioning
- `migration.ipynb`: migration pipeline (extract → transform → load → validate)
- `validation_report.csv`: reconciliation results

## How to run
1. Download the Synthea 1K CSV sample into `data/csv/`
2. Import the CSVs into SQL Server (database `clinic_legacy`)
3. Run `sql/02_target_schema.sql` in PostgreSQL (database `clinic_new`)
4. `pip install -r requirements.txt`, then copy `.env.example` to `.env`
5. Run `migration.ipynb`
# Migration Report: Clinic Database (SQL Server → PostgreSQL)

## Summary
Migrated 688,290 synthetic patient records across 5 tables from SQL Server 2025 to PostgreSQL 18. All records were verified with zero data loss.

## Scope
| Table | Rows | Description |
|---|---|---|
| patients | 1,163 | Patient demographics |
| encounters | 61,459 | Doctor visits |
| conditions | 38,094 | Diagnoses |
| medications | 56,430 | Prescriptions |
| observations | 531,144 | Lab results and vitals |

Data: Synthea synthetic patient data (no real patient information).

## Approach
1. Profiled the source: row counts, unique IDs, orphan records, NULLs
2. Designed the target schema with corrected data types and new foreign keys
3. Migrated with Python in 50,000-row chunks inside transactions (all-or-nothing)
4. Reconciled source and target: counts, distinct patients, date ranges, money totals
5. Tested backup and full restore
6. Partitioned the largest table by date for performance

## Issues Found and Resolved
| Issue | Impact | Resolution |
|---|---|---|
| Money stored as float, some in scientific notation (1.26E7) | Rounding errors, failed imports | Converted to NUMERIC(18,2) |
| Medical codes (SNOMED, up to 15 digits) typed as int | Overflow errors | Stored as text |
| Descriptions longer than column size | Truncation errors | Widened columns |
| Dates stored as text (ISO 8601 with UTC 'Z') | Not usable as dates | Converted to TIMESTAMP |
| Import tool option could silently drop values | Risk of hidden data loss | Disabled; verified NULL counts against original CSVs |
| 545 patients (47%) have no ZIP in the source | Incomplete addresses | Confirmed as source issue; migrated as NULL and reported |

## Validation Results
All 5 tables matched on row count, distinct patients and date range.
Money totals matched within $0.10 on $1.46B (explained by rounding to 2 decimals).
Evidence: validation_report.csv

## Backup and Recovery
- Backup: pg_dump custom format, 151 MB database → 13.8 MB file
- Tested: the database was fully dropped and restored; reconciliation passed again

## Performance: Partitioning
The observations table was range-partitioned by date. Partitions were chosen from the data distribution (64% of rows fall in the 2010s).
A query for 2020+ data read 2,388 pages instead of 12,722 (about 5× less I/O).

## Recommendations
- Fix the missing ZIP codes at the source
- Split recent partitions by year as data grows
- Schedule automated backups with regular restore tests
# IPEDS Student Success ETL Pipeline

## Overview
End-to-end data engineering pipeline built to support student success and retention analytics using 12 years of IPEDS (Integrated Postsecondary Education Data System) federal data from 2012 to 2024.

## Tools and Technologies
- **Python** — ETL pipeline, data extraction and transformation
- **Microsoft SQL Server** — data storage and query layer
- **SSIS** — SQL Server Integration Services package for data loading
- **SQL** — views, joins, and data quality fixes
- **Tableau** — interactive dashboard for visualization

## Pipeline Architecture
```
IPEDS Access Databases (.accdb)
        ↓
Python ETL (extract, clean, transform)
        ↓
SSIS Package (load to SQL Server)
        ↓
SQL Server Database (IPEDS_StudentSuccess)
        ↓
SQL Views (vw_GraduationRates, vw_EnrollmentTrends, vw_StudentSuccessSummary)
        ↓
Tableau Dashboard
```

## Database Tables
| Table | Description |
|-------|-------------|
| GR_IPEDS | Graduation rates by institution and year |
| EF_IPEDS | Enrollment figures by institution and year |
| HD_IPEDS | Institutional characteristics |
| DRVGR_IPEDS | Derived graduation rate metrics |

## SQL Views
| View | Description |
|------|-------------|
| vw_GraduationRates | Graduation rates by gender and race across 12 years |
| vw_EnrollmentTrends | Total and FTE enrollment trends over time |
| vw_StudentSuccessSummary | Combined view used for Tableau dashboard |

## Key Findings
- Average graduation rates increased steadily from 2012 to 2024
- Female students consistently graduate at higher rates than male students
- Significant variation in graduation rates across states
- Enrollment peaked around 2019-2020 before declining slightly

## Project Structure
```
├── etl_pipeline.py        # Main ETL script
├── sql_views.sql          # SQL view definitions
├── README.md              # Project documentation
```

## Data Source
IPEDS data is publicly available from the National Center for Education Statistics at nces.ed.gov/ipeds

# INDICATE SPE Scripts Directory

This directory contains all database initialization and management scripts for the INDICATE Secure Processing Environment.

## Directory Structure

```
scripts/
├── README.md                    # This file
├── 01_create_schemas.sql        # Creates cdm, vocab, results schemas
├── 02_omop_cdm_tables.sql       # Creates 32 OMOP CDM v5.4 tables
├── 03_vocabulary_tables.sql     # Creates 9 vocabulary tables
├── 04_results_tables.sql        # Creates results/temp tables
├── 05_primary_keys.sql          # Adds primary keys to all tables
├── 06_indexes.sql               # Creates indexes for performance
├── 07_load_vocabulary.sql       # Loads Athena vocabulary CSV files
├── 08_verify_data.sql           # Data quality verification queries
├── load-vocabulary.sh           # Shell script to execute vocabulary load
├── generate-icu-data.sh         # Shell script to generate dummy ICU data
└── generate_icu_data.py         # Python script for ICU data generation
```

## Script Execution Order

### Phase 1: Database Initialization (Automated via Docker)
Scripts 01-06 run automatically when PostgreSQL container starts for the first time via `/docker-entrypoint-initdb.d/` mount.

1. **01_create_schemas.sql** - Creates three schemas: `cdm`, `vocab`, `results`
2. **02_omop_cdm_tables.sql** - Creates OMOP CDM v5.4 clinical data tables
3. **03_vocabulary_tables.sql** - Creates vocabulary tables for standardized terminologies
4. **04_results_tables.sql** - Creates cohort and results tables
5. **05_primary_keys.sql** - Adds primary key constraints
6. **06_indexes.sql** - Creates indexes for query performance

### Phase 2: Vocabulary Loading (Manual)
After downloading Athena vocabulary bundle:

```bash
# From indicate-spe/scripts/ directory
./load-vocabulary.sh
```

This script:
- Validates vocabulary CSV files are present in `../vocabularies/`
- Copies files into PostgreSQL container
- Executes `07_load_vocabulary.sql` to load all vocabulary tables
- Verifies data integrity and provides summary statistics

Expected runtime: **20-30 minutes**

### Phase 3: ICU Data Generation (Manual)
After vocabulary is loaded:

```bash
# From indicate-spe/scripts/ directory
./generate-icu-data.sh
```

This script:
- Validates PostgreSQL container and Python environment
- Installs Python dependencies (psycopg2) if needed
- Executes `generate_icu_data.py` to create synthetic ICU data
- Generates 100 patients with realistic clinical trajectories

Expected runtime: **5-10 minutes**

#### Generated Data Domains
- **Demographics**: 100 patients (age 18-85, mixed gender)
- **ICU Visits**: 1-21 days length of stay (mean ~5 days)
- **Conditions**: Sepsis, ARDS, respiratory failure, pneumonia, shock
- **Vital Signs**: HR, BP, SpO2, temperature, RR (hourly)
- **Laboratory**: Lactate, creatinine, WBC, hemoglobin, blood gas (daily)
- **Ventilation**: FiO2, PEEP, tidal volume, pressures (hourly for 60% of patients)
- **Medications**: Sedatives, vasopressors, antibiotics
- **Procedures**: Intubation, mechanical ventilation, line placement

#### Verify Generated Data
```bash
docker exec -it indicate-postgres-omop psql -U postgres -d omop_cdm -f /docker-entrypoint-initdb.d/08_verify_data.sql
```

## Key Files

### 02_omop_cdm_tables.sql
Creates 32 core OMOP CDM v5.4 tables:
- **Clinical data**: PERSON, VISIT_OCCURRENCE, CONDITION_OCCURRENCE, PROCEDURE_OCCURRENCE, DRUG_EXPOSURE, DEVICE_EXPOSURE, MEASUREMENT, OBSERVATION
- **Health system**: LOCATION, CARE_SITE, PROVIDER
- **Health economics**: PAYER_PLAN_PERIOD, COST
- **Standardized derived elements**: COHORT, EPISODE, NOTE

### 07_load_vocabulary.sql
Loads 9 vocabulary tables from Athena:
- VOCABULARY (~70 rows)
- DOMAIN (~30 rows)
- CONCEPT_CLASS (~400 rows)
- RELATIONSHIP (~600 rows)
- CONCEPT (~5M rows)
- CONCEPT_RELATIONSHIP (~35M rows)
- CONCEPT_SYNONYM (~3M rows)
- CONCEPT_ANCESTOR (~450M rows)
- DRUG_STRENGTH (~2.5M rows)

## Prerequisites

### For Initial Setup (Scripts 01-06)
- Docker and Docker Compose installed
- PostgreSQL Docker image
- Scripts mounted to `/docker-entrypoint-initdb.d/`

### For Vocabulary Load (Script 07)
- Athena vocabulary bundle downloaded from https://athena.ohdsi.org/
- Required vocabularies: ATC, Gender, ICD10, LOINC, RxNorm, RxNorm Extension, SNOMED
- Files extracted to `../vocabularies/` directory
- PostgreSQL container running

## Troubleshooting

### Scripts not running during container initialization
**Problem**: Init scripts only run on first container start with empty data volume

**Solution**:
```bash
docker-compose -f postgres-compose.yml down -v
rm -rf ./postgres-data
docker-compose -f postgres-compose.yml up -d
```

### Vocabulary load fails with "file not found"
**Problem**: CSV files not accessible to container

**Solution**: Verify files are in `vocabularies/` directory relative to project root

### Out of memory during vocabulary load
**Problem**: Large vocabulary tables (CONCEPT_ANCESTOR) require significant memory

**Solution**: Increase Docker memory allocation or use smaller vocabulary subset for testing

## References
- OMOP CDM Documentation: https://ohdsi.github.io/CommonDataModel/
- Athena Vocabulary: https://athena.ohdsi.org/
- INDICATE Project: https://www.indicate-project.eu/
# indicate-spe
Reference implementation for the Data Provider tools

# Prerequisites
----

# Step 1: Docker Environment Verification
This implementation assumes that you have [Docker Desktop](https://docs.docker.com/get-started/) for Windows and [WSL](https://learn.microsoft.com/en-us/windows/wsl/install) running. 

1. Docker installation

```
bash
# Check Docker version (should be 20.10+)
docker --version

# Check Docker Compose version (should be 2.0+)
docker compose version

# Test Docker is running
docker ps
```

2. Verify WSL Resources
```
bash
# Check available disk space (need at least 50GB free)
df -h

# Check available memory (recommend 8GB+)
free -h
``` 
3. Create Project Directory Structure

```
bash
# Create working directory
mkdir -p ~/indicate-spe
cd ~/indicate-spe

# Create subdirectories
mkdir -p {broadsea,postgres-data,secrets,scripts,vocabularies}
```
### Expected Outcome:

- Docker version 20.10+  
- Docker Compose v2.0+  
- At least 50GB free disk space  
- Project directory structure created  

# Step 2: PostgreSQL OMOP CDM Setup

## Overview
This step sets up PostgreSQL with OMOP CDM v5.4 schema ready for Broadsea deployment.

## File Structure
```
indicate-spe/
├── postgres-compose.yml       # Docker Compose for PostgreSQL
├── scripts/                   # SQL initialization scripts
│   ├── 01_create_schemas.sql
│   ├── 02_omop_cdm_tables.sql
│   ├── 03_vocabulary_tables.sql
│   ├── 04_results_tables.sql
│   ├── 05_primary_keys.sql
│   └── 06_indexes.sql
└── postgres-data/             # Will store PostgreSQL data (created by Docker)
```

## Deployment Steps

### 1. Start PostgreSQL Container in detached mode
```bash
cd /indicate-spe
docker compose -f postgres-compose.yml up -d
```

### 2. Verify Container is Running
```bash
docker ps | grep indicate-postgres
docker logs indicate-postgres-omop
```

Expected output: PostgreSQL should be accepting connections

### 3. Verify Database Schemas
```bash
docker exec -it indicate-postgres-omop psql -U postgres -d omop_cdm -c "\dn"
```

Expected output:
```
  Name   |  Owner   
---------+----------
 cdm     | postgres
 public  | postgres
 results | postgres
 vocab   | postgres
 webapi  | postgres
```

### 4. Verify CDM Tables Created
```bash
docker exec -it indicate-postgres-omop psql -U postgres -d omop_cdm -c "\dt cdm.*"
```

Expected output: List of ~30+ OMOP CDM tables (person, visit_occurrence, measurement, etc.)

### 5. Verify Vocabulary Tables Created
```bash
docker exec -it indicate-postgres-omop psql -U postgres -d omop_cdm -c "\dt vocab.*"
```

Expected output: List of vocabulary tables (concept, vocabulary, domain, etc.)

## Connection Details
- **Host**: localhost
- **Port**: 5432
- **Database**: omop_cdm
- **Username**: postgres
- **Password**: postgres
- **CDM Schema**: cdm
- **Vocabulary Schema**: vocab
- **Results Schema**: results
- **WebAPI Schema**: webapi

## Network
PostgreSQL is connected to `indicate-network` Docker network for communication with Broadsea components.

## Data Persistence
PostgreSQL data is stored in `./postgres-data` directory which persists across container restarts.

## Next Steps
After verifying this step:
1. Download OMOP Vocabulary from Athena
2. Load vocabulary into vocab schema
3. Generate dummy ICU data
4. Proceed to Phase 1: WebAPI deployment
# INDICATE SPE - Reference Implementation

**Data Provider Secure Processing Environment for INDICATE Project**

> ⚠️ **Important**: This implementation is for development and testing purposes. It should NOT be used for production without additional security hardening.

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Quick Start (Automated)](#quick-start-automated)
4. [Manual Deployment](#manual-deployment)
5. [Verification](#verification)
6. [Troubleshooting](#troubleshooting)
7. [References](#references)

---

## Overview

This repository contains a reference implementation of an OHDSI-based Secure Processing Environment (SPE) for the INDICATE project. It includes:

- **PostgreSQL** with OMOP CDM v5.4 schema
- **OHDSI Broadsea** stack (WebAPI + Atlas)
- **Achilles** for descriptive statistics
- **Sample ICU data** (100 synthetic patients)
- **OMOP Vocabulary** (~5M concepts)

### Architecture

```
┌────────────────────────────────────────┐
│         Broadsea Components            │
├────────────────────────────────────────┤
│  ┌──────────┐  ┌──────────┐            │
│  │  Atlas   │→ │  WebAPI  │            │
│  │  (UI)    │  │  (API)   │            │
│  └──────────┘  └────┬─────┘            │
│                     │                  │
│  ┌──────────────────▼─────────────┐    │
│  │   Atlas DB (WebAPI Metadata)   │    │
│  └────────────────────────────────┘    │
└─────────────────┬──────────────────────┘
                  │ JDBC
                  ▼
┌─────────────────────────────────────────┐
│    PostgreSQL OMOP CDM Container        │
├─────────────────────────────────────────┤
│  Database: omop_cdm                     │
│  ├── cdm schema (patient data)          │
│  ├── vocab schema (5M concepts)         │
│  └── results schema (cohorts, achilles) │
└─────────────────────────────────────────┘
```

---

## Prerequisites

### System Requirements

- **Docker Desktop** 20.10+ ([Install Guide](https://docs.docker.com/get-started/))
- **Docker Compose** v2.0+
- **WSL** (Windows users) ([Install Guide](https://learn.microsoft.com/en-us/windows/wsl/install))
- **Disk Space**: 50GB free minimum
- **Memory**: 8GB RAM recommended
- **Network**: Internet connection for downloading images and vocabularies

### Verify Installation

```bash
# Check Docker version (should be 20.10+)
docker --version

# Check Docker Compose version (should be 2.0+)
docker compose version

# Test Docker is running
docker ps

# Check available disk space (need at least 50GB free)
df -h

# Check available memory (recommend 8GB+)
free -h
```

### Create Project Directory

```bash
# Create and navigate to working directory
mkdir -p ~/indicate-spe
cd ~/indicate-spe

# Clone or copy this repository
git clone <repository-url> .
# OR extract the provided archive
```

### Download OMOP Vocabulary

1. Register at https://athena.ohdsi.org/ (free)
2. Download vocabulary bundle with these vocabularies:

| ID | Code | Name |
|---|---|---|
| 82 | RxNorm Extension | OMOP RxNorm Extension |
| 70 | ICD10CM | International Classification of Diseases, 10th Revision |
| 21 | ATC | WHO Anatomic Therapeutic Chemical Classification |
| 12 | Gender | OMOP Gender |
| 8 | RxNorm | RxNorm (NLM) |
| 6 | LOINC | Logical Observation Identifiers Names and Codes |
| 1 | SNOMED | Systematic Nomenclature of Medicine - Clinical Terms |

3. Extract the vocabulary bundle and copy the CSV files into the `vocabularies/` directory in the project root

---

## Quick Start (Automated)

### 🚀 Complete Deployment in One Command

The fastest way to get a fully operational system:

```bash
cd ~/indicate-spe

# Make scripts executable
chmod +x scripts/*.sh

# Step 1: Start PostgreSQL OMOP CDM
docker compose -f postgres-compose.yml up -d

# Step 2: Load vocabulary into PostgreSQL (10 minutes)
bash ./scripts/load-vocabulary.sh

# Step 3: Generate 100 synthetic ICU patients (5-10 minutes)
bash ./scripts/generate-icu-data.sh

# Step 4: Deploy Broadsea, register source, and run Achilles (~10 minutes)
bash ./deploy.sh
```

**What this does:**
1. ✅ Deploys PostgreSQL with OMOP CDM v5.4 schema
2. ✅ Loads vocabulary (~5M concepts) into the database
3. ✅ Generates 100 synthetic ICU patients
4. ✅ Deploys Broadsea stack (Atlas DB, WebAPI, Atlas UI)
5. ✅ Registers OMOP CDM as data source
6. ✅ Runs Achilles analysis for statistics

**Expected timeline:**
- PostgreSQL startup: 1 min
- Vocabulary loading: 10-20 min
- ICU data generation: 5-10 min
- Broadsea deployment: 2-3 min
- WebAPI initialization: 1-2 min
- Source registration: 10 sec
- Achilles analysis: 2-5 min
- **Total: ~20-30 minutes**

### ✅ Verify Deployment

After deployment completes, run automated verification:

```bash
bash ./scripts/verify-deployment.sh
```

**Expected output:**
```
=====================================================
INDICATE SPE: Deployment Verification
=====================================================

Section 1: Container Health
  Testing PostgreSQL container... ✓ PASS
  Testing Atlas DB container... ✓ PASS
  Testing WebAPI container... ✓ PASS
  Testing Atlas UI container... ✓ PASS

Section 2: Database Content
  Testing Person count... ✓ PASS
  Testing Vocabulary concepts... ✓ PASS (value: 4,892,345)
  Testing Measurement count... ✓ PASS (value: 52,143)

Section 3: Achilles Statistics
  Testing Achilles results rows... ✓ PASS (value: 847)

Section 4: WebAPI Endpoints
  Testing WebAPI info endpoint... ✓ PASS
  Testing Data source registered... ✓ PASS

Section 5: Atlas UI
  Testing Atlas UI responds... ✓ PASS

Section 6: Data Consistency
  Testing All persons have observation periods... ✓ PASS

=====================================================
✓ ALL TESTS PASSED - DEPLOYMENT SUCCESSFUL!
=====================================================
```

### 🌐 Access Your System

Once verification passes:

**Atlas UI:** http://localhost:8081/atlas/

Try this:
1. Click **"Data Sources"** in left sidebar
2. Select **"INDICATE OMOP CDM"** from dropdown
3. Click **"Report"** tab
4. Explore statistics and charts!

**WebAPI:** http://localhost:8080/WebAPI/

Test endpoints:
```bash
# Get API info
curl http://localhost:8080/WebAPI/info | jq

# List data sources
curl http://localhost:8080/WebAPI/source/sources | jq

# Search concepts
curl "http://localhost:8080/WebAPI/vocabulary/INDICATE/search?query=sepsis" | jq
```

### 🧹 Clean Slate (Optional)

To remove everything and start fresh:

```bash
./scripts/clean-up.sh
```

Type `yes` when prompted. This removes all containers, volumes, and networks.

---

## Manual Deployment

If you prefer step-by-step control or need to troubleshoot specific components:

### Step 1: PostgreSQL OMOP CDM Setup

#### 1.1 Deploy PostgreSQL

```bash
cd ~/indicate-spe
docker compose -f postgres-compose.yml up -d
```

#### 1.2 Verify Container

```bash
# Check container is running
docker ps | grep indicate-postgres-omop

# Check logs
docker logs indicate-postgres-omop

# Verify schemas created
docker exec -it indicate-postgres-omop psql -U postgres -d omop_cdm -c "\dn"
```

**Expected schemas:** cdm, vocab, results, ohdsi

#### 1.3 Load Vocabulary

```bash
# Ensure vocabulary zip file is in project root
ls -lh vocabulary_download_v5*.zip

# Run vocabulary loader (3-5 minutes)
./scripts/load-vocabulary.sh
```

**Expected output:**
```
=====================================================
INDICATE SPE: Vocabulary Load Process
=====================================================

1. Checking PostgreSQL container status...
   ✓ Container is running

2. Checking vocabulary files...
   ✓ All 9 required vocabulary files present

3. Copying vocabulary files into container...
   ✓ Files copied successfully

4. Loading vocabulary tables (this will take 20-30 minutes)...
   ...

=====================================================
VOCABULARY LOAD COMPLETE!
=====================================================
```

#### 1.4 Generate ICU Data

```bash
# Generate 100 synthetic ICU patients (2-3 minutes)
./scripts/generate-icu-data.sh
```

**What's generated:**
- 100 patients (ages 18-85, mixed gender)
- 100 ICU visits (1-21 days, mean ~5 days)
- ~200 diagnoses (sepsis, respiratory failure, ARDS, pneumonia, shock)
- ~50,000 measurements (vital signs, labs, ventilation parameters)
- ~300 drug exposures (sedatives, vasopressors, antibiotics)
- ~200 procedures (intubation, mechanical ventilation, lines)

#### 1.5 Verify Data

```bash
docker exec indicate-postgres-omop psql -U postgres -d omop_cdm \
  -f /docker-entrypoint-initdb.d/08_verify_data.sql
```

---

### Step 2: Broadsea Stack Deployment

#### 2.1 Deploy Broadsea Services

```bash
cd ~/indicate-spe
docker compose -f broadsea-compose.yml up -d
```

#### 2.2 Wait for WebAPI Initialization

```bash
# Watch WebAPI logs (2-3 minutes for first startup)
docker logs -f broadsea-webapi

# Wait for: "Started Application in X seconds"
# Press Ctrl+C to exit log view
```

#### 2.3 Register OMOP CDM Source

```bash
# Run registration script
./scripts/register-source.sh
```

**Or manually:**
```bash
# Copy SQL script to Atlas DB container
docker cp scripts/09_configure_webapi_source.sql broadsea-atlasdb:/tmp/

# Execute configuration
docker exec -i broadsea-atlasdb psql -U postgres -d postgres \
  -f /tmp/09_configure_webapi_source.sql
```

#### 2.4 Verify Registration

```bash
# Check registered sources
curl http://localhost:8080/WebAPI/source/sources | jq

# Expected: Array with 1 source "INDICATE OMOP CDM"
```

---

### Step 3: Achilles Analysis

#### 3.1 Run Achilles

```bash
# Generate descriptive statistics (2-5 minutes)
./scripts/run-achilles.sh
```

**Or manually:**
```bash
# Pull Achilles image (one-time)
docker pull ohdsi/broadsea-achilles:master

# Run Achilles analysis
docker run --rm \
  --network indicate-network \
  -v "$(pwd)/scripts/10_run_achilles.R:/achilles/run_achilles.R:ro" \
  ohdsi/broadsea-achilles:master \
  Rscript /achilles/run_achilles.R
```

#### 3.2 Verify Achilles Results

```bash
# Check results count
docker exec indicate-postgres-omop psql -U postgres -d omop_cdm -tAc \
  "SELECT COUNT(*) FROM results.achilles_results"

# Expected: 800-1000 rows

# Check key statistics
docker exec indicate-postgres-omop psql -U postgres -d omop_cdm -c \
  "SELECT analysis_id, count_value 
   FROM results.achilles_results 
   WHERE analysis_id IN (1, 2, 401, 701, 1801) 
   ORDER BY analysis_id"
```

---

## Verification

### Container Health Check

```bash
# Check all containers are running
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Expected containers:
# indicate-postgres-omop    Up    0.0.0.0:5432->5432/tcp
# broadsea-atlasdb          Up    0.0.0.0:5433->5432/tcp
# broadsea-webapi           Up    0.0.0.0:8080->8080/tcp
# broadsea-atlas            Up    0.0.0.0:8081->8080/tcp
```

**Note:** WebAPI may show as "unhealthy" but still be functional - this is a known issue with the healthcheck.

### Database Verification

```bash
# Person count
docker exec indicate-postgres-omop psql -U postgres -d omop_cdm -tAc \
  "SELECT COUNT(*) FROM cdm.person"
# Expected: 100

# Vocabulary size
docker exec indicate-postgres-omop psql -U postgres -d omop_cdm -tAc \
  "SELECT COUNT(*) FROM vocab.concept"
# Expected: ~5,000,000

# Measurements
docker exec indicate-postgres-omop psql -U postgres -d omop_cdm -tAc \
  "SELECT COUNT(*) FROM cdm.measurement"
# Expected: ~50,000

# Achilles results
docker exec indicate-postgres-omop psql -U postgres -d omop_cdm -tAc \
  "SELECT COUNT(*) FROM results.achilles_results"
# Expected: 800-1000
```

### WebAPI Endpoint Tests

```bash
# Test 1: API info
curl http://localhost:8080/WebAPI/info | jq
# Expected: {"version":"2.14.0",...}

# Test 2: Data sources
curl http://localhost:8080/WebAPI/source/sources | jq
# Expected: Array with "INDICATE OMOP CDM"

# Test 3: Person count
curl http://localhost:8080/WebAPI/cdmresults/INDICATE/person | jq
# Expected: 100

# Test 4: Concept search
curl "http://localhost:8080/WebAPI/vocabulary/INDICATE/search?query=heart+rate" | jq
# Expected: Array of heart rate concepts
```

### Atlas UI Manual Testing

1. **Access Atlas:** http://localhost:8081/atlas/
2. **Select Data Source:** Data Sources > "INDICATE OMOP CDM"
3. **View Report:** Report tab should show:
   - Person count: 100
   - Gender distribution chart
   - Age distribution chart
   - Record counts by domain
4. **Search Concepts:** Search > "sepsis" (should return results)
5. **Create Cohort:** Cohort Definitions > New Cohort (builder should load)

---

## Troubleshooting

### Issue: WebAPI Won't Start

**Symptoms:**
```
docker logs broadsea-webapi
ERROR: Unable to connect to database
```

**Solution:**
```bash
# Check Atlas DB is healthy
docker ps | grep broadsea-atlasdb

# Check Atlas DB logs
docker logs broadsea-atlasdb

# Verify ohdsi schema exists
docker exec broadsea-atlasdb psql -U postgres -d postgres -c "\dn"
# Should show 'ohdsi' schema
```

### Issue: Atlas Shows "No Sources"

**Symptoms:**
- Atlas UI loads but dropdown is empty
- WebAPI `/source/sources` returns `[]`

**Solution:**
```bash
# Re-run source registration
./scripts/register-source.sh

# Or manually:
docker cp scripts/09_configure_webapi_source.sql broadsea-atlasdb:/tmp/
docker exec -i broadsea-atlasdb psql -U postgres -d postgres \
  -f /tmp/09_configure_webapi_source.sql

# Restart WebAPI to refresh
docker restart broadsea-webapi
```

### Issue: Atlas UI Returns 404

**Symptoms:**
- `http://localhost:8081/` returns 404
- Container is running but not accessible

**Solution:**
```bash
# Check port mapping in docker ps
docker ps | grep broadsea-atlas

# Verify correct URL with /atlas/ path
curl -I http://localhost:8081/atlas/

# Check Atlas container logs
docker logs broadsea-atlas

# Port mapping should be 8081:8080 (not 8081:80)
# If wrong, fix in broadsea-compose.yml and redeploy
```

### Issue: Achilles Tables Empty

**Symptoms:**
- `achilles_results` table exists but has 0 rows
- Atlas report shows "no data"

**Solution:**
```bash
# Verify OMOP CDM has data
docker exec indicate-postgres-omop psql -U postgres -d omop_cdm -tAc \
  "SELECT COUNT(*) FROM cdm.person"

# If 0, generate data first
./scripts/generate-icu-data.sh

# Then run Achilles
./scripts/run-achilles.sh
```

### Issue: Vocabulary Loading Fails

**Symptoms:**
- Error: "vocabulary_download_v5*.zip not found"
- Or: "CSV files missing"

**Solution:**
```bash
# Verify vocabulary file exists
ls -lh vocabulary_download_v5*.zip

# If missing, download from https://athena.ohdsi.org/

# Ensure file is in project root (not in subdirectory)
mv Downloads/vocabulary_*.zip ~/indicate-spe/
```

### Issue: Port Already in Use

**Symptoms:**
```
Error: bind: address already in use
```

**Solution:**
```bash
# Find what's using the port
sudo lsof -i :8080  # WebAPI
sudo lsof -i :8081  # Atlas
sudo lsof -i :5432  # PostgreSQL

# Option 1: Stop conflicting service
sudo systemctl stop <service>

# Option 2: Change port in compose files
# Edit postgres-compose.yml or broadsea-compose.yml
# Change port mapping: "8082:8080" instead of "8080:8080"
```

### Issue: Docker Network Problems

**Symptoms:**
- WebAPI can't connect to PostgreSQL
- Error: "Connection refused" or "Unknown host"

**Solution:**
```bash
# Verify network exists
docker network ls | grep indicate-network

# If missing, create it
docker network create indicate-network

# Connect PostgreSQL to network
docker network connect indicate-network indicate-postgres-omop

# Restart WebAPI
docker restart broadsea-webapi
```

### Issue: Out of Disk Space

**Symptoms:**
- Deployment fails during vocabulary loading
- Docker errors about disk space

**Solution:**
```bash
# Check available space
df -h /var/lib/docker

# Clean up unused Docker resources
docker system prune -a --volumes

# Remove old containers and images
docker rm $(docker ps -a -q -f status=exited)
docker rmi $(docker images -q -f dangling=true)

# Free up WSL disk space (Windows users)
wsl --shutdown
# Then restart Docker Desktop
```

---

## Connection Details

### PostgreSQL OMOP CDM
- **Host:** localhost
- **Port:** 5432
- **Database:** omop_cdm
- **Username:** postgres
- **Password:** postgres
- **CDM Schema:** cdm
- **Vocabulary Schema:** vocab
- **Results Schema:** results

### Atlas DB (WebAPI Metadata)
- **Host:** localhost
- **Port:** 5433
- **Database:** postgres
- **Username:** postgres
- **Password:** mypass
- **WebAPI Schema:** ohdsi

### WebAPI
- **Base URL:** http://localhost:8080/WebAPI/
- **Info Endpoint:** http://localhost:8080/WebAPI/info
- **Sources:** http://localhost:8080/WebAPI/source/sources

### Atlas UI
- **URL:** http://localhost:8081/atlas/
- **Note:** Path `/atlas/` is required

---

## Advanced Usage

### Re-running Achilles

After adding more data or updating existing records:

```bash
./scripts/run-achilles.sh
```

Achilles is idempotent - safe to run multiple times.

### Regenerating ICU Data

To replace existing data with fresh synthetic patients:

```bash
# Clear and regenerate
./scripts/generate-icu-data.sh

# Then re-run Achilles
./scripts/run-achilles.sh
```

### Database Backup

```bash
# Backup entire database
docker exec indicate-postgres-omop pg_dump -U postgres omop_cdm > backup.sql

# Backup specific schema
docker exec indicate-postgres-omop pg_dump -U postgres -n cdm omop_cdm > cdm_backup.sql

# Restore from backup
cat backup.sql | docker exec -i indicate-postgres-omop psql -U postgres omop_cdm
```

### Viewing Container Logs

```bash
# WebAPI logs
docker logs -f broadsea-webapi

# Atlas logs
docker logs -f broadsea-atlas

# PostgreSQL logs
docker logs -f indicate-postgres-omop

# All Broadsea logs
docker compose -f broadsea-compose.yml logs -f
```

### Stopping Services

```bash
# Stop Broadsea only
docker compose -f broadsea-compose.yml down

# Stop PostgreSQL only
docker compose -f postgres-compose.yml down

# Stop everything (keeps data)
docker compose -f broadsea-compose.yml down
docker compose -f postgres-compose.yml down

# Stop everything and remove volumes (deletes data)
docker compose -f broadsea-compose.yml down -v
docker compose -f postgres-compose.yml down -v
```

### Accessing PostgreSQL Directly

```bash
# Interactive psql session
docker exec -it indicate-postgres-omop psql -U postgres -d omop_cdm

# Run single query
docker exec -it indicate-postgres-omop psql -U postgres -d omop_cdm \
  -c "SELECT COUNT(*) FROM cdm.person"

# Execute SQL file
docker exec -it indicate-postgres-omop psql -U postgres -d omop_cdm \
  -f /path/to/script.sql
```

---

## Performance Considerations

### Resource Usage

**Expected resource consumption:**
- PostgreSQL: 2-4 GB RAM, 20-30 GB disk
- Broadsea (all services): 2-3 GB RAM, 5 GB disk
- Vocabulary files: 2-3 GB disk (uncompressed)

**Minimum recommended:**
- 8 GB RAM total
- 50 GB free disk space
- 2+ CPU cores

### Scaling Data Volume

The system can handle more data by adjusting:

```python
# In generate_icu_data.py, lines 734-735
generator.generate_persons(n_patients=1000)
visits = generator.generate_icu_visits(n_patients=1000)

# Expected Achilles runtime:
# 100 patients: 2-5 minutes
# 1,000 patients: 10-15 minutes
# 10,000 patients: 1-2 hours
```

---

## Security Notes

⚠️ **This deployment is NOT production-ready.** Before deploying to production:

1. **Change all default passwords:**
   - PostgreSQL: `postgres`/`postgres`
   - Atlas DB: `postgres`/`mypass`

2. **Implement authentication:**
   - WebAPI: Currently uses `DisabledSecurity` (no authentication)
   - Integrate with Azure AD, LDAP, or other IdP

3. **Enable TLS/SSL:**
   - Add certificates to containers
   - Update connection strings to use SSL

4. **Restrict CORS:**
   - Change `SECURITY_ORIGIN=*` to specific domain
   - Example: `SECURITY_ORIGIN=https://atlas.indicate-project.eu`

5. **Network isolation:**
   - Use firewall rules
   - Limit port exposure
   - Consider VPN for access

6. **Data protection:**
   - Encrypt volumes
   - Implement backup strategy
   - Follow GDPR requirements

---

## References

### OHDSI Resources
- **Broadsea:** https://github.com/OHDSI/Broadsea
- **WebAPI Documentation:** https://github.com/OHDSI/WebAPI/wiki
- **Atlas User Guide:** https://github.com/OHDSI/Atlas/wiki
- **OMOP CDM:** https://ohdsi.github.io/CommonDataModel/
- **OHDSI Forums:** https://forums.ohdsi.org/
- **The Book of OHDSI:** https://ohdsi.github.io/TheBookOfOhdsi/

### INDICATE Project
- **Project Website:** https://www.indicate-project.eu/
- **Data Provider Handbook:** To be added
- **Architecture Documentation:** To be added

### Technical Documentation
- **Docker Documentation:** https://docs.docker.com/
- **PostgreSQL Documentation:** https://www.postgresql.org/docs/
- **Athena Vocabulary:** https://athena.ohdsi.org/

---

## Support

For issues or questions:

1. **Check troubleshooting section** in this README
2. **Review detailed guides** in `docs/` directory
3. **Check container logs** for error messages
4. **Consult OHDSI forums** for OHDSI-specific questions
5. **Contact INDICATE architecture team** for project-specific issues

---

## License

[Specify license here - typically follows INDICATE project licensing]

---

## Acknowledgments

This implementation is based on:
- OHDSI Broadsea project
- OMOP Common Data Model
- INDICATE project requirements

Developed for the INDICATE consortium as a reference implementation for data provider sites.

---

**Version:** 1.0  
**Last Updated:** February 12, 2026  
**Maintainer:** INDICATE Architecture Team
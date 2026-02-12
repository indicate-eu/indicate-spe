#!/bin/bash
# =====================================================
# INDICATE SPE: Run Achilles Analysis
# =====================================================
# Generates descriptive statistics for OMOP CDM
# Populates achilles_* tables in results schema
# Uses OHDSI HADES Docker container
# =====================================================

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "====================================================="
echo "INDICATE SPE: Achilles Analysis"
echo "====================================================="
echo ""

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Check if R script exists
R_SCRIPT="$SCRIPT_DIR/10_run_achilles.R"
if [ ! -f "$R_SCRIPT" ]; then
    echo -e "${YELLOW}⚠${NC} R script not found at $R_SCRIPT"
    echo "Creating it now..."
    
    # If script doesn't exist, user needs to download it
    echo "Please ensure 10_run_achilles.R is in the scripts/ directory"
    exit 1
fi

# =====================================================
# Step 1: Check Prerequisites
# =====================================================
echo -e "${BLUE}Step 1: Checking prerequisites...${NC}"

# Check if OMOP CDM container is running
if ! docker ps | grep -q "indicate-postgres-omop"; then
    echo -e "${YELLOW}⚠${NC} OMOP CDM container not running"
    echo "Starting PostgreSQL container..."
    docker compose -f "$PROJECT_ROOT/postgres-compose.yml" up -d
    echo "Waiting for database to be ready..."
    sleep 5
fi
echo -e "${GREEN}✓${NC} OMOP CDM container running"

# Check if on indicate-network
if ! docker network ls | grep -q "indicate-network"; then
    echo -e "${YELLOW}⚠${NC} indicate-network not found"
    echo "Creating network..."
    docker network create indicate-network
fi
echo -e "${GREEN}✓${NC} Docker network ready"
echo ""

# =====================================================
# Step 2: Pull HADES Docker Image (if needed)
# =====================================================
echo -e "${BLUE}Step 2: Checking HADES Docker image...${NC}"

if ! docker images | grep -q "ohdsi/broadsea-achilles"; then
    echo "Pulling OHDSI Achilles image (this may take a few minutes)..."
    docker pull ohdsi/broadsea-achilles:master
else
    echo -e "${GREEN}✓${NC} Achilles image already available"
fi
echo ""

# =====================================================
# Step 3: Run Achilles Analysis
# =====================================================
echo -e "${BLUE}Step 3: Running Achilles analysis...${NC}"
echo "This will take 2-5 minutes for 100 patients"
echo ""

# Run HADES container with R script
docker run --rm \
  --network indicate-network \
  -v "$R_SCRIPT:/achilles/run_achilles.R:ro" \
  ohdsi/broadsea-achilles:master \
  Rscript /achilles/run_achilles.R

echo ""

# =====================================================
# Step 4: Verify Results
# =====================================================
echo -e "${BLUE}Step 4: Verifying Achilles tables...${NC}"

# Check achilles_results
RESULTS_COUNT=$(docker exec indicate-postgres-omop psql -U postgres -d omop_cdm -tAc \
  "SELECT COUNT(*) FROM results.achilles_results")
echo -e "${GREEN}✓${NC} achilles_results: $RESULTS_COUNT rows"

# Check achilles_results_dist
DIST_COUNT=$(docker exec indicate-postgres-omop psql -U postgres -d omop_cdm -tAc \
  "SELECT COUNT(*) FROM results.achilles_results_dist")
echo -e "${GREEN}✓${NC} achilles_results_dist: $DIST_COUNT rows"

# Check achilles_analysis
ANALYSIS_COUNT=$(docker exec indicate-postgres-omop psql -U postgres -d omop_cdm -tAc \
  "SELECT COUNT(*) FROM results.achilles_analysis")
echo -e "${GREEN}✓${NC} achilles_analysis: $ANALYSIS_COUNT analyses"

echo ""

# =====================================================
# Step 5: Display Key Statistics
# =====================================================
echo -e "${BLUE}Step 5: Key statistics from Achilles...${NC}"

# Person count
PERSON_COUNT=$(docker exec indicate-postgres-omop psql -U postgres -d omop_cdm -tAc \
  "SELECT count_value FROM results.achilles_results WHERE analysis_id = 1 LIMIT 1")
echo "   - Total Persons: $PERSON_COUNT"

# Record counts by domain
echo "   - Record Counts by Domain:"

CONDITION_COUNT=$(docker exec indicate-postgres-omop psql -U postgres -d omop_cdm -tAc \
  "SELECT count_value FROM results.achilles_results WHERE analysis_id = 401 LIMIT 1" || echo "0")
echo "     - Conditions: $CONDITION_COUNT"

DRUG_COUNT=$(docker exec indicate-postgres-omop psql -U postgres -d omop_cdm -tAc \
  "SELECT count_value FROM results.achilles_results WHERE analysis_id = 701 LIMIT 1" || echo "0")
echo "     - Drugs: $DRUG_COUNT"

MEASUREMENT_COUNT=$(docker exec indicate-postgres-omop psql -U postgres -d omop_cdm -tAc \
  "SELECT count_value FROM results.achilles_results WHERE analysis_id = 1801 LIMIT 1" || echo "0")
echo "     - Measurements: $MEASUREMENT_COUNT"

PROCEDURE_COUNT=$(docker exec indicate-postgres-omop psql -U postgres -d omop_cdm -tAc \
  "SELECT count_value FROM results.achilles_results WHERE analysis_id = 601 LIMIT 1" || echo "0")
echo "     - Procedures: $PROCEDURE_COUNT"

echo ""
echo "====================================================="
echo -e "${GREEN}✓ Achilles Analysis Complete!${NC}"
echo "====================================================="
echo ""
echo "Next steps:"
echo "  1. Refresh Atlas UI: http://localhost:8081/atlas/"
echo "  2. Go to Data Sources > INDICATE OMOP CDM"
echo "  3. Click 'Report' tab to see statistics"
echo ""
echo "To re-run Achilles (e.g., after adding more data):"
echo "  ./scripts/run-achilles.sh"
echo ""
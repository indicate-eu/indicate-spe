#!/bin/bash
# =====================================================
# INDICATE SPE: Complete Deployment Script
# =====================================================
# Deploys full OHDSI Broadsea stack with Achilles
# Includes: PostgreSQL, OMOP CDM, WebAPI, Atlas, Achilles
# =====================================================

set -e  # Exit on error

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo "====================================================="
echo "INDICATE SPE: Complete Deployment"
echo "====================================================="
echo ""

# Get project root (directory where this script lives)
PROJECT_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# =====================================================
# Step 1: Deploy PostgreSQL OMOP CDM
# =====================================================
echo -e "${BLUE}Step 1: Deploying PostgreSQL OMOP CDM...${NC}"

if docker ps | grep -q "indicate-postgres-omop"; then
    echo -e "${YELLOW}⚠${NC} OMOP CDM container already running"
else
    cd "$PROJECT_ROOT"
    docker compose -f postgres-compose.yml up -d
    echo "Waiting for PostgreSQL to be ready..."
    sleep 5
fi

# Verify database
PERSON_COUNT=$(docker exec indicate-postgres-omop psql -U postgres -d omop_cdm -tAc \
  "SELECT COUNT(*) FROM cdm.person" 2>/dev/null || echo "0")

if [ "$PERSON_COUNT" -eq "0" ]; then
    echo -e "${RED}❌${NC} No data in OMOP CDM"
    echo "Run: ./scripts/generate-icu-data.sh"
    exit 1
fi

echo -e "${GREEN}✓${NC} OMOP CDM running with $PERSON_COUNT patients"
echo ""

# =====================================================
# Step 2: Deploy Broadsea (WebAPI + Atlas)
# =====================================================
echo -e "${BLUE}Step 2: Deploying Broadsea stack...${NC}"

cd "$PROJECT_ROOT"

if docker ps | grep -q "broadsea-atlas"; then
    echo -e "${YELLOW}⚠${NC} Broadsea already running"
else
    docker compose -f broadsea-compose.yml up -d
    echo "Waiting for WebAPI to initialize..."
    sleep 30
fi

# Wait for WebAPI to be ready
echo "Checking WebAPI health..."
for i in {1..30}; do
    if curl -sf http://localhost:8080/WebAPI/info > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} WebAPI is ready"
        break
    fi
    if [ $i -eq 30 ]; then
        echo -e "${RED}❌${NC} WebAPI failed to start"
        echo "Check logs: docker logs broadsea-webapi"
        exit 1
    fi
    echo "   Waiting... ($i/30)"
    sleep 2
done
echo ""

# =====================================================
# Step 3: Register OMOP CDM Source
# =====================================================
echo -e "${BLUE}Step 3: Registering OMOP CDM source with WebAPI...${NC}"

# Check if already registered
SOURCE_COUNT=$(curl -s http://localhost:8080/WebAPI/source/sources | jq '. | length' 2>/dev/null || echo "0")

if [ "$SOURCE_COUNT" -eq "0" ]; then
    echo "Registering data source..."
    cd "$PROJECT_ROOT"
    docker cp scripts/09_configure_webapi_source.sql broadsea-atlasdb:/tmp/
    docker exec -i broadsea-atlasdb psql -U postgres -d postgres \
      -f /tmp/09_configure_webapi_source.sql > /dev/null

    # Refresh WebAPI source cache so it picks up the new source
    echo "Refreshing WebAPI source cache..."
    curl -sf http://localhost:8080/WebAPI/source/refresh > /dev/null 2>&1 || true
    echo -e "${GREEN}✓${NC} Data source registered"
else
    echo -e "${GREEN}✓${NC} Data source already registered"
fi
echo ""

# =====================================================
# Step 4: Run Achilles Analysis
# =====================================================
echo -e "${BLUE}Step 4: Running Achilles analysis...${NC}"

# Check if Achilles already run
ACHILLES_COUNT=$(docker exec indicate-postgres-omop psql -U postgres -d omop_cdm -tAc \
  "SELECT COUNT(*) FROM results.achilles_results" 2>/dev/null || echo "0")

if [ "$ACHILLES_COUNT" -eq "0" ]; then
    echo "Running Achilles (this takes 2-5 minutes)..."
    cd "$PROJECT_ROOT"
    
    # Run Achilles script
    if [ -f "$PROJECT_ROOT/scripts/run-achilles.sh" ]; then
        bash "$PROJECT_ROOT/scripts/run-achilles.sh"
    else
        echo -e "${YELLOW}⚠${NC} Achilles script not found, skipping..."
    fi
else
    echo -e "${GREEN}✓${NC} Achilles already run ($ACHILLES_COUNT results)"
fi
echo ""

# =====================================================
# Step 5: Verification
# =====================================================
echo -e "${BLUE}Step 5: Verifying deployment...${NC}"

# Check containers
echo "Container Status:"
docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "indicate|broadsea|NAME"
echo ""

# Check WebAPI sources
echo "Registered Data Sources:"
curl -s http://localhost:8080/WebAPI/source/sources | jq -r '.[] | "  - \(.sourceName) (\(.sourceKey))"'
echo ""

# Check Achilles results
RESULTS=$(docker exec indicate-postgres-omop psql -U postgres -d omop_cdm -tAc \
  "SELECT COUNT(*) FROM results.achilles_results")
echo "Achilles Results: $RESULTS rows"
echo ""

# =====================================================
# Success Summary
# =====================================================
echo "====================================================="
echo -e "${GREEN}✓ Deployment Complete!${NC}"
echo "====================================================="
echo ""
echo "Access Points:"
echo "  - Atlas UI:    http://localhost:8081/atlas/"
echo "  - WebAPI:      http://localhost:8080/WebAPI/"
echo "  - PostgreSQL:  localhost:5432 (omop_cdm database)"
echo ""
echo "Quick Commands:"
echo "  - View logs:   docker compose logs -f"
echo "  - Stop all:    docker compose -f broadsea-compose.yml down && \\"
echo "                 docker compose -f postgres-compose.yml down"
echo "  - Re-run Achilles: ./scripts/run-achilles.sh"
echo ""
echo "Next Steps:"
echo "  1. Open Atlas: http://localhost:8081/atlas/"
echo "  2. Select 'Data Sources' > 'INDICATE OMOP CDM'"
echo "  3. View 'Report' tab for data statistics"
echo "  4. Try creating a cohort definition"
echo ""
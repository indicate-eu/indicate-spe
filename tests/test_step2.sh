#!/bin/bash
# Verification script for Step 2: PostgreSQL OMOP CDM Setup

echo "========================================="
echo "INDICATE SPE - Step 2 Verification"
echo "========================================="
echo ""

# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check status
check_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ PASS${NC}"
        return 0
    else
        echo -e "${RED}✗ FAIL${NC}"
        return 1
    fi
}

# Test 1: Check if container is running
echo -n "Test 1: PostgreSQL container running... "
docker ps | grep -q indicate-postgres-omop
check_status

# Test 2: Check database connection
echo -n "Test 2: Database connection... "
docker exec indicate-postgres-omop psql -U postgres -d ohdsi -c "SELECT 1" > /dev/null 2>&1
check_status

# Test 3: Check schemas exist
echo -n "Test 3: Required schemas exist... "
SCHEMA_COUNT=$(docker exec indicate-postgres-omop psql -U postgres -d ohdsi -t -c "SELECT COUNT(*) FROM information_schema.schemata WHERE schema_name IN ('cdm', 'vocab', 'results', 'webapi')")
if [ "$SCHEMA_COUNT" -eq 4 ]; then
    echo -e "${GREEN}✓ PASS${NC} (4/4 schemas)"
else
    echo -e "${RED}✗ FAIL${NC} ($SCHEMA_COUNT/4 schemas)"
fi

# Test 4: Check CDM tables exist
echo -n "Test 4: CDM tables created... "
CDM_TABLE_COUNT=$(docker exec indicate-postgres-omop psql -U postgres -d ohdsi -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='cdm'")
if [ "$CDM_TABLE_COUNT" -ge 30 ]; then
    echo -e "${GREEN}✓ PASS${NC} ($CDM_TABLE_COUNT tables)"
else
    echo -e "${YELLOW}⚠ WARNING${NC} ($CDM_TABLE_COUNT tables, expected ~32)"
fi

# Test 5: Check vocabulary tables exist
echo -n "Test 5: Vocabulary tables created... "
VOCAB_TABLE_COUNT=$(docker exec indicate-postgres-omop psql -U postgres -d ohdsi -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='vocab'")
if [ "$VOCAB_TABLE_COUNT" -ge 9 ]; then
    echo -e "${GREEN}✓ PASS${NC} ($VOCAB_TABLE_COUNT tables)"
else
    echo -e "${YELLOW}⚠ WARNING${NC} ($VOCAB_TABLE_COUNT tables, expected 9)"
fi

# Test 6: Check results tables exist
echo -n "Test 6: Results tables created... "
RESULTS_TABLE_COUNT=$(docker exec indicate-postgres-omop psql -U postgres -d ohdsi -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='results'")
if [ "$RESULTS_TABLE_COUNT" -ge 2 ]; then
    echo -e "${GREEN}✓ PASS${NC} ($RESULTS_TABLE_COUNT tables)"
else
    echo -e "${YELLOW}⚠ WARNING${NC} ($RESULTS_TABLE_COUNT tables, expected 2)"
fi

# Test 7: Check CDM metadata
echo -n "Test 7: CDM metadata exists... "
CDM_SOURCE_COUNT=$(docker exec indicate-postgres-omop psql -U postgres -d ohdsi -t -c "SELECT COUNT(*) FROM cdm.cdm_source")
if [ "$CDM_SOURCE_COUNT" -ge 1 ]; then
    echo -e "${GREEN}✓ PASS${NC}"
else
    echo -e "${RED}✗ FAIL${NC}"
fi

# Test 8: Check primary keys
echo -n "Test 8: Primary keys created... "
PK_COUNT=$(docker exec indicate-postgres-omop psql -U postgres -d ohdsi -t -c "SELECT COUNT(*) FROM information_schema.table_constraints WHERE constraint_type='PRIMARY KEY' AND table_schema IN ('cdm', 'vocab', 'results')")
if [ "$PK_COUNT" -ge 20 ]; then
    echo -e "${GREEN}✓ PASS${NC} ($PK_COUNT primary keys)"
else
    echo -e "${YELLOW}⚠ WARNING${NC} ($PK_COUNT primary keys)"
fi

# Test 9: Check indexes
echo -n "Test 9: Performance indexes created... "
INDEX_COUNT=$(docker exec indicate-postgres-omop psql -U postgres -d ohdsi -t -c "SELECT COUNT(*) FROM pg_indexes WHERE schemaname IN ('cdm', 'vocab', 'results')")
if [ "$INDEX_COUNT" -ge 30 ]; then
    echo -e "${GREEN}✓ PASS${NC} ($INDEX_COUNT indexes)"
else
    echo -e "${YELLOW}⚠ WARNING${NC} ($INDEX_COUNT indexes)"
fi

# Test 10: Check Docker network
echo -n "Test 10: Docker network configured... "
docker network inspect indicate-network > /dev/null 2>&1
check_status

echo ""
echo "========================================="
echo "Verification Complete"
echo "========================================="
echo ""
echo "Connection Details:"
echo "  Host: localhost"
echo "  Port: 5432"
echo "  Database: ohdsi"
echo "  Username: postgres"
echo "  Password: postgres"
echo ""
echo "Next Step: Download OMOP Vocabulary from Athena"
echo "  URL: https://athena.ohdsi.org"
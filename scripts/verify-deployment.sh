#!/bin/bash
# =====================================================
# INDICATE SPE: Deployment Verification Script
# =====================================================
# Automatically checks if deployment is successful
# Run after deploy-complete.sh to verify system health
# =====================================================

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

# Function to check and report
check() {
    local test_name="$1"
    local test_command="$2"
    local expected="$3"
    
    echo -n "  Testing $test_name... "
    
    result=$(eval "$test_command" 2>/dev/null)
    
    if [ "$result" = "$expected" ] || [[ "$result" =~ $expected ]]; then
        echo -e "${GREEN}✓ PASS${NC}"
        ((PASS_COUNT++))
        return 0
    else
        echo -e "${RED}✗ FAIL${NC} (got: $result, expected: $expected)"
        ((FAIL_COUNT++))
        return 1
    fi
}

check_range() {
    local test_name="$1"
    local test_command="$2"
    local min="$3"
    local max="$4"
    
    echo -n "  Testing $test_name... "
    
    result=$(eval "$test_command" 2>/dev/null)
    
    if [ "$result" -ge "$min" ] && [ "$result" -le "$max" ]; then
        echo -e "${GREEN}✓ PASS${NC} (value: $result)"
        ((PASS_COUNT++))
        return 0
    else
        echo -e "${RED}✗ FAIL${NC} (got: $result, expected: $min-$max)"
        ((FAIL_COUNT++))
        return 1
    fi
}

echo "====================================================="
echo "INDICATE SPE: Deployment Verification"
echo "====================================================="
echo ""

# =====================================================
# Section 1: Container Health
# =====================================================
echo -e "${BLUE}Section 1: Container Health${NC}"

check "PostgreSQL container" \
    "docker ps --filter 'name=indicate-postgres-omop' --format '{{.Status}}' | grep -c 'Up'" \
    "1"

check "Atlas DB container" \
    "docker ps --filter 'name=broadsea-atlasdb' --format '{{.Status}}' | grep -c 'Up'" \
    "1"

check "WebAPI container" \
    "docker ps --filter 'name=broadsea-webapi' --format '{{.Status}}' | grep -c 'Up'" \
    "1"

check "Atlas UI container" \
    "docker ps --filter 'name=broadsea-atlas' --format '{{.Names}}' | grep -c '^broadsea-atlas$'" \
    "1"

echo ""

# =====================================================
# Section 2: Database Content
# =====================================================
echo -e "${BLUE}Section 2: Database Content${NC}"

check "Person count" \
    "docker exec indicate-postgres-omop psql -U postgres -d omop_cdm -tAc 'SELECT COUNT(*) FROM cdm.person'" \
    "100"

check_range "Vocabulary concepts" \
    "docker exec indicate-postgres-omop psql -U postgres -d omop_cdm -tAc 'SELECT COUNT(*) FROM vocab.concept'" \
    "4000000" "6000000"

check_range "Measurement count" \
    "docker exec indicate-postgres-omop psql -U postgres -d omop_cdm -tAc 'SELECT COUNT(*) FROM cdm.measurement'" \
    "60000" "150000"

check "Observation periods" \
    "docker exec indicate-postgres-omop psql -U postgres -d omop_cdm -tAc 'SELECT COUNT(*) FROM cdm.observation_period'" \
    "100"

echo ""

# =====================================================
# Section 3: Achilles Results
# =====================================================
echo -e "${BLUE}Section 3: Achilles Statistics${NC}"

check_range "Achilles results rows" \
    "docker exec indicate-postgres-omop psql -U postgres -d omop_cdm -tAc 'SELECT COUNT(*) FROM results.achilles_results'" \
    "500" "3000"

check_range "Achilles analyses" \
    "docker exec indicate-postgres-omop psql -U postgres -d omop_cdm -tAc 'SELECT COUNT(*) FROM results.achilles_analysis'" \
    "200" "350"

check "Person count analysis exists" \
    "docker exec indicate-postgres-omop psql -U postgres -d omop_cdm -tAc 'SELECT COUNT(*) FROM results.achilles_results WHERE analysis_id = 1'" \
    "1"

echo ""

# =====================================================
# Section 4: WebAPI Endpoints
# =====================================================
echo -e "${BLUE}Section 4: WebAPI Endpoints${NC}"

check "WebAPI info endpoint" \
    "curl -s http://localhost:8080/WebAPI/info | jq -r '.version' 2>/dev/null" \
    "2.14.0"

check "Data source registered" \
    "curl -s http://localhost:8080/WebAPI/source/sources | jq '. | length' 2>/dev/null" \
    "1"

check "Source name correct" \
    "curl -s http://localhost:8080/WebAPI/source/sources | jq -r '.[0].sourceName' 2>/dev/null" \
    "INDICATE OMOP CDM"

check "CDM daimon configured" \
    "curl -s http://localhost:8080/WebAPI/source/sources | jq -r '.[0].daimons[] | select(.daimonType==\"CDM\") | .tableQualifier' 2>/dev/null" \
    "cdm"

echo ""

# =====================================================
# Section 5: Atlas UI
# =====================================================
echo -e "${BLUE}Section 5: Atlas UI${NC}"

check "Atlas UI responds" \
    "curl -s -o /dev/null -w '%{http_code}' http://localhost:8081/atlas/" \
    "200"

echo ""

# =====================================================
# Section 6: Data Consistency
# =====================================================
echo -e "${BLUE}Section 6: Data Consistency${NC}"

check "All persons have observation periods" \
    "docker exec indicate-postgres-omop psql -U postgres -d omop_cdm -tAc \
    'SELECT CASE WHEN COUNT(*) = (SELECT COUNT(*) FROM cdm.person) THEN 1 ELSE 0 END FROM cdm.observation_period'" \
    "1"

check "All persons have measurements" \
    "docker exec indicate-postgres-omop psql -U postgres -d omop_cdm -tAc \
    'SELECT CASE WHEN COUNT(DISTINCT person_id) = (SELECT COUNT(*) FROM cdm.person) THEN 1 ELSE 0 END FROM cdm.measurement'" \
    "1"

check "Achilles person count matches" \
    "docker exec indicate-postgres-omop psql -U postgres -d omop_cdm -tAc \
    'SELECT CASE WHEN (SELECT count_value FROM results.achilles_results WHERE analysis_id = 1) = (SELECT COUNT(*) FROM cdm.person) THEN 1 ELSE 0 END'" \
    "1"

echo ""

# =====================================================
# Summary
# =====================================================
echo "====================================================="
echo "Verification Summary"
echo "====================================================="
echo ""

TOTAL=$((PASS_COUNT + FAIL_COUNT))
PASS_PERCENT=$((PASS_COUNT * 100 / TOTAL))

echo "Total Tests: $TOTAL"
echo -e "${GREEN}Passed: $PASS_COUNT${NC}"
echo -e "${RED}Failed: $FAIL_COUNT${NC}"
echo "Success Rate: $PASS_PERCENT%"
echo ""

if [ $FAIL_COUNT -eq 0 ]; then
    echo -e "${GREEN}====================================================="
    echo "✓ ALL TESTS PASSED - DEPLOYMENT SUCCESSFUL!"
    echo "=====================================================${NC}"
    echo ""
    echo "Your INDICATE SPE is fully operational!"
    echo ""
    echo "Access Points:"
    echo "  - Atlas UI:   http://localhost:8081/atlas/"
    echo "  - WebAPI:     http://localhost:8080/WebAPI/"
    echo "  - PostgreSQL: localhost:5432 (database: omop_cdm)"
    echo ""
    echo "Next Steps:"
    echo "  1. Open Atlas UI and explore the data"
    echo "  2. Create a sample cohort definition"
    echo "  3. Review Achilles reports"
    echo ""
    exit 0
else
    echo -e "${RED}====================================================="
    echo "✗ DEPLOYMENT VERIFICATION FAILED"
    echo "=====================================================${NC}"
    echo ""
    echo "Some tests failed. Please review the output above."
    echo ""
    echo "Common fixes:"
    echo "  - Check container logs: docker logs [container-name]"
    echo "  - Verify all services are running: docker ps"
    echo "  - Re-run specific failed components"
    echo ""
    echo "For detailed troubleshooting, see:"
    echo "  - BUILD_FROM_SCRATCH_TEST_PLAN.md"
    echo "  - ACHILLES_SETUP_GUIDE.md"
    echo ""
    exit 1
fi
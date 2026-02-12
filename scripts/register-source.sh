#!/bin/bash
# =====================================================
# INDICATE SPE: Register OMOP CDM Source with WebAPI
# =====================================================
# This script registers your OMOP CDM database as a 
# data source in WebAPI so Atlas can access it.
# =====================================================

set -e  # Exit on error

echo "====================================================="
echo "INDICATE SPE: Registering OMOP CDM Source"
echo "====================================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Check if SQL file exists
SQL_FILE="$SCRIPT_DIR/09_configure_webapi_source.sql"
if [ ! -f "$SQL_FILE" ]; then
    echo "❌ Error: SQL file not found at $SQL_FILE"
    echo "Please ensure 09_configure_webapi_source.sql is in the same directory"
    exit 1
fi

echo "Step 1: Copying SQL script into Atlas DB container..."
docker cp "$SQL_FILE" broadsea-atlasdb:/tmp/configure_source.sql
echo -e "${GREEN}✓${NC} SQL script copied"
echo ""

echo "Step 2: Executing SQL script in Atlas DB..."
docker exec -i broadsea-atlasdb psql -U postgres -d postgres -f /tmp/configure_source.sql
echo ""

echo "Step 3: Verifying registration via WebAPI..."
sleep 2  # Give WebAPI a moment to refresh

# Test WebAPI endpoint
echo "Testing WebAPI sources endpoint..."
curl -s http://localhost:8080/WebAPI/source/sources | jq '.' || {
    echo -e "${YELLOW}⚠${NC} jq not installed, showing raw output:"
    curl -s http://localhost:8080/WebAPI/source/sources
}
echo ""

echo "====================================================="
echo -e "${GREEN}✓ Registration Complete!${NC}"
echo "====================================================="
echo ""
echo "Next steps:"
echo "  1. Open Atlas: http://localhost:8081/atlas/"
echo "  2. Click 'Data Sources' in left sidebar"
echo "  3. Select 'INDICATE OMOP CDM' from dropdown"
echo "  4. Click 'Report' tab to see your data"
echo ""
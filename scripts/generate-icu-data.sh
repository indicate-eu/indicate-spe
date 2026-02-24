#!/bin/bash
# =====================================================
# INDICATE SPE: Generate ICU Dummy Data
# =====================================================
# Purpose: Execute Python script to generate realistic ICU data
# Requires: PostgreSQL container running with vocabulary loaded
#           Python 3 with psycopg2 installed
# Location: Run from indicate-spe/scripts/ directory
# =====================================================

set -e  # Exit on any error

# Dynamically determine script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

CONTAINER_NAME="indicate-postgres-omop"
PYTHON_SCRIPT="$SCRIPT_DIR/generate_icu_data.py"

echo "====================================================="
echo "INDICATE SPE: ICU Data Generation"
echo "====================================================="
echo ""

# Check if container is running
echo "1. Checking PostgreSQL container status..."
if ! docker ps | grep -q $CONTAINER_NAME; then
    echo "ERROR: Container '$CONTAINER_NAME' is not running!"
    echo "Start it with: docker-compose -f postgres-compose.yml up -d"
    exit 1
fi
echo "   ✓ Container is running"
echo ""

# Check if Python 3 is available
echo "2. Checking Python environment..."
if ! command -v python3 &> /dev/null; then
    echo "ERROR: Python 3 not found!"
    echo "Install with: apt-get install python3 python3-pip"
    exit 1
fi
echo "   ✓ Python 3 available: $(python3 --version)"
echo ""

# Check if psycopg2 is installed
echo "3. Checking Python dependencies..."
if ! python3 -c "import psycopg2" 2>/dev/null; then
    echo "Installing psycopg2..."
    pip3 install psycopg2-binary
fi
echo "   ✓ Dependencies installed"
echo ""

# Execute Python script
echo "4. Generating ICU dummy data..."
echo "   This will take 5-10 minutes depending on system performance..."
echo ""

python3 "$PYTHON_SCRIPT"

echo ""
echo "====================================================="
echo "DATA GENERATION COMPLETE!"
echo "====================================================="
echo ""
echo "Next steps:"
echo "  1. Verify data in PostgreSQL: docker exec -it indicate-postgres-omop psql -U postgres -d omop_cdm"
echo "  2. Run sample queries to validate data quality"
echo "  3. Proceed to Phase 1: Deploy Broadsea WebAPI/Atlas"
echo ""
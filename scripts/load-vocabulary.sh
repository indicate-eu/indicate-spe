#!/bin/bash
# =====================================================
# INDICATE SPE: Load Vocabulary into PostgreSQL
# =====================================================
# Purpose: Execute vocabulary load from Athena CSV files
# Requires: Docker container 'indicate-postgres-omop' running
#           Vocabulary files in ../vocabularies/
# Location: Run from indicate-spe/scripts/ directory
# =====================================================

set -e  # Exit on any error

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

CONTAINER_NAME="indicate-postgres-omop"
DB_NAME="omop_cdm"
DB_USER="postgres"
VOCAB_DIR="$SCRIPT_DIR/../vocabularies"
SCRIPT_FILE="$SCRIPT_DIR/07_load_vocabulary.sql"

echo "====================================================="
echo "INDICATE SPE: Vocabulary Load Process"
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

# Check if vocabulary files exist
echo "2. Checking vocabulary files..."
if [ ! -d "$VOCAB_DIR" ]; then
    echo "ERROR: Vocabulary directory '$VOCAB_DIR' not found!"
    echo "Please extract Athena vocabulary files to: $(pwd)/../vocabularies/"
    exit 1
fi

REQUIRED_FILES=(
    "VOCABULARY.csv"
    "DOMAIN.csv"
    "CONCEPT_CLASS.csv"
    "RELATIONSHIP.csv"
    "CONCEPT.csv"
    "CONCEPT_RELATIONSHIP.csv"
    "CONCEPT_SYNONYM.csv"
    "CONCEPT_ANCESTOR.csv"
    "DRUG_STRENGTH.csv"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$VOCAB_DIR/$file" ]; then
        echo "ERROR: Required file '$file' not found in $VOCAB_DIR"
        exit 1
    fi
done
echo "   ✓ All 9 required vocabulary files present"
echo ""

# Copy vocabulary files into container
echo "3. Copying vocabulary files into container..."
docker exec $CONTAINER_NAME mkdir -p /vocabularies
for file in "${REQUIRED_FILES[@]}"; do
    echo "   Copying $file..."
    docker cp "$VOCAB_DIR/$file" "$CONTAINER_NAME:/vocabularies/$file"
done
echo "   ✓ Files copied successfully"
echo ""

# Execute load script
echo "4. Loading vocabulary tables (this will take 20-30 minutes)..."
echo "   Progress will be shown below..."
echo ""

docker exec -i $CONTAINER_NAME psql -U $DB_USER -d $DB_NAME < $SCRIPT_FILE

echo ""
echo "====================================================="
echo "VOCABULARY LOAD COMPLETE!"
echo "====================================================="
echo ""
echo "Next steps:"
echo "  1. Review the vocabulary distribution summary above"
echo "  2. Proceed to Step 2.3: Generate dummy ICU data"
echo ""
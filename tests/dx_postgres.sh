#!/bin/bash

echo "======================================"
echo "INDICATE SPE PostgreSQL Diagnostics"
echo "======================================"
echo ""

echo "1. Checking Docker container status..."
docker ps -a | grep postgres

echo ""
echo "2. Getting PostgreSQL logs (last 50 lines)..."
docker logs indicate-postgres-omop 2>&1 | tail -50

echo ""
echo "3. Checking if SQL file has the fix applied..."
if [ -f ../scripts/02_omop_cdm_tables.sql ]; then
    echo "File exists. Checking for quoted offset..."
    grep -n "\"offset\"" ../scripts/02_omop_cdm_tables.sql || echo "WARNING: Quoted offset not found!"
    grep -n "offset VARCHAR" ../scripts/02_omop_cdm_tables.sql | head -5
else
    echo "ERROR: SQL file not found at ../scripts/02_omop_cdm_tables.sql"
fi

echo ""
echo "4. Checking current table count in database..."
docker exec -it indicate-postgres psql -U postgres -d omop_cdm -c "\dt cdm.*" | wc -l

echo ""
echo "5. Testing direct SQL execution of NOTE_NLP table..."
docker exec -it indicate-postgres psql -U postgres -d omop_cdm << 'EOF'
-- Test creating NOTE_NLP table with quoted offset
DROP TABLE IF EXISTS cdm.note_nlp_test;
CREATE TABLE cdm.note_nlp_test (
  note_nlp_id INTEGER NOT NULL,
  note_id INTEGER NOT NULL,
  "offset" VARCHAR(50) NULL
);
SELECT 'SUCCESS: Table created with quoted offset' as result;
DROP TABLE cdm.note_nlp_test;
EOF

echo ""
echo "6. Checking Docker volume mounts..."
docker inspect indicate-postgres | grep -A 10 "Mounts"

echo ""
echo "======================================"
echo "Diagnostic complete"
echo "======================================"
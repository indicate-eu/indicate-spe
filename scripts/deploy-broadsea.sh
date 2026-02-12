#!/bin/bash
# =====================================================
# INDICATE SPE: Deploy Broadsea WebAPI + Atlas
# =====================================================
# Purpose: Deploy OHDSI Broadsea stack for federated analytics
# Components: Atlas DB, WebAPI, Atlas UI
# Prerequisites: PostgreSQL OMOP CDM running
# =====================================================

set -e  # Exit on any error

# Dynamically determine script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Configuration
COMPOSE_FILE="$PROJECT_ROOT/broadsea-compose.yml"
SQL_CONFIG="$SCRIPT_DIR/09_configure_webapi_source.sql"
OMOP_CONTAINER="indicate-postgres-omop"
ATLAS_DB_CONTAINER="broadsea-atlasdb"
WEBAPI_CONTAINER="broadsea-webapi"
ATLAS_CONTAINER="broadsea-atlas"

echo "====================================================="
echo "INDICATE SPE: Broadsea Deployment"
echo "====================================================="
echo ""
echo "This script will deploy:"
echo "  • Atlas DB (WebAPI metadata)"
echo "  • WebAPI (REST API)"
echo "  • Atlas (Web UI)"
echo ""
echo "Prerequisites:"
echo "  ✓ Docker and Docker Compose installed"
echo "  ✓ PostgreSQL OMOP CDM running ($OMOP_CONTAINER)"
echo "  ✓ Port 8080 (WebAPI) and 8081 (Atlas) available"
echo ""
read -p "Press Enter to continue or Ctrl+C to cancel..."
echo ""

# =====================================================
# Step 1: Verify Prerequisites
# =====================================================
echo "Step 1: Verifying prerequisites..."
echo ""

# Check Docker
if ! command -v docker &> /dev/null; then
    echo "ERROR: Docker not found!"
    exit 1
fi
echo "   ✓ Docker available: $(docker --version)"

# Check Docker Compose
if ! docker compose version &> /dev/null; then
    echo "ERROR: Docker Compose not found!"
    exit 1
fi
echo "   ✓ Docker Compose available"

# Check OMOP PostgreSQL container
if ! docker ps | grep -q $OMOP_CONTAINER; then
    echo "ERROR: PostgreSQL container '$OMOP_CONTAINER' not running!"
    echo "Start it with: docker-compose -f postgres-compose.yml up -d"
    exit 1
fi
echo "   ✓ PostgreSQL OMOP CDM container running"

# Check compose file exists
if [ ! -f "$COMPOSE_FILE" ]; then
    echo "ERROR: Compose file not found: $COMPOSE_FILE"
    exit 1
fi
echo "   ✓ Broadsea compose file found"

# Check ports availability
if lsof -Pi :8080 -sTCP:LISTEN -t >/dev/null 2>&1 ; then
    echo "WARNING: Port 8080 already in use!"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

if lsof -Pi :8081 -sTCP:LISTEN -t >/dev/null 2>&1 ; then
    echo "WARNING: Port 8081 already in use!"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo ""
echo "====================================================="

# =====================================================
# Step 2: Deploy Broadsea Services
# =====================================================
echo "Step 2: Deploying Broadsea services..."
echo ""
echo "This will take 3-5 minutes for initial setup..."
echo ""

cd "$PROJECT_ROOT"

# Pull images first
echo "Pulling Docker images..."
docker compose -f "$COMPOSE_FILE" pull

# Start services
echo ""
echo "Starting services..."
docker compose -f "$COMPOSE_FILE" up -d

echo ""
echo "Waiting for services to initialize..."
echo ""

# Wait for Atlas DB
echo "Waiting for Atlas DB to be ready..."
timeout=60
counter=0
until docker exec $ATLAS_DB_CONTAINER pg_isready -U postgres >/dev/null 2>&1; do
    sleep 2
    counter=$((counter + 2))
    if [ $counter -gt $timeout ]; then
        echo "ERROR: Atlas DB failed to start within $timeout seconds"
        exit 1
    fi
    echo -n "."
done
echo ""
echo "   ✓ Atlas DB ready"

# Wait for WebAPI (longer timeout for first-time initialization)
echo ""
echo "Waiting for WebAPI to be ready (this may take 2-3 minutes)..."
timeout=180
counter=0
until curl -s http://localhost:8080/WebAPI/info >/dev/null 2>&1; do
    sleep 5
    counter=$((counter + 5))
    if [ $counter -gt $timeout ]; then
        echo "ERROR: WebAPI failed to start within $timeout seconds"
        echo "Check logs: docker logs $WEBAPI_CONTAINER"
        exit 1
    fi
    echo -n "."
done
echo ""
echo "   ✓ WebAPI ready"

# Check Atlas
echo ""
echo "Checking Atlas UI..."
if curl -s http://localhost:8081 >/dev/null 2>&1; then
    echo "   ✓ Atlas UI ready"
else
    echo "WARNING: Atlas UI not responding"
fi

echo ""
echo "====================================================="

# =====================================================
# Step 3: Configure WebAPI Source
# =====================================================
echo "Step 3: Configuring OMOP CDM source in WebAPI..."
echo ""

# Copy SQL script into Atlas DB container
docker cp "$SQL_CONFIG" "$ATLAS_DB_CONTAINER:/tmp/configure_source.sql"

# Execute configuration
docker exec -i $ATLAS_DB_CONTAINER psql -U postgres -d postgres -f /tmp/configure_source.sql

echo ""
echo "====================================================="

# =====================================================
# Step 4: Verify Deployment
# =====================================================
echo "Step 4: Verifying deployment..."
echo ""

echo "Testing WebAPI endpoints..."

# Test WebAPI info endpoint
if curl -s http://localhost:8080/WebAPI/info | grep -q "version"; then
    echo "   ✓ WebAPI info endpoint working"
else
    echo "   ✗ WebAPI info endpoint failed"
fi

# Test WebAPI sources endpoint
if curl -s http://localhost:8080/WebAPI/source/sources | grep -q "INDICATE"; then
    echo "   ✓ WebAPI sources endpoint working"
    echo "   ✓ INDICATE OMOP CDM source registered"
else
    echo "   ✗ WebAPI sources endpoint failed or source not registered"
fi

# Test Atlas
if curl -s http://localhost:8081 >/dev/null 2>&1; then
    echo "   ✓ Atlas UI accessible"
else
    echo "   ✗ Atlas UI not accessible"
fi

echo ""
echo "====================================================="
echo "DEPLOYMENT COMPLETE!"
echo "====================================================="
echo ""
echo "Services are now running:"
echo ""
echo "  Atlas DB:   PostgreSQL on port 5433"
echo "  WebAPI:     http://localhost:8080/WebAPI/"
echo "  Atlas UI:   http://localhost:8081/"
echo ""
echo "Useful commands:"
echo ""
echo "  # View logs"
echo "  docker logs broadsea-webapi"
echo "  docker logs broadsea-atlas"
echo ""
echo "  # Stop services"
echo "  docker compose -f broadsea-compose.yml down"
echo ""
echo "  # Restart services"
echo "  docker compose -f broadsea-compose.yml restart"
echo ""
echo "Next steps:"
echo "  1. Open Atlas UI: http://localhost:8081/"
echo "  2. Select 'INDICATE OMOP CDM' as data source"
echo "  3. Explore 'Data Sources' to view vocabulary and patient counts"
echo "  4. Try creating a cohort definition"
echo ""
echo "====================================================="
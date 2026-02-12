#!/bin/bash
# =====================================================
# INDICATE SPE: Complete Cleanup Script
# =====================================================
# WARNING: This removes all containers, volumes, and data
# Use this to start fresh or for testing deployments
# =====================================================

set -e  # Exit on error

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "====================================================="
echo "INDICATE SPE: Complete Cleanup"
echo "====================================================="
echo ""
echo -e "${RED}WARNING: This will remove all INDICATE SPE data!${NC}"
echo ""
echo "This will remove:"
echo "  - All containers (PostgreSQL, Broadsea)"
echo "  - All volumes (database data, Atlas metadata)"
echo "  - Docker network"
echo ""
read -p "Are you sure? (type 'yes' to continue): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Cleanup cancelled."
    exit 0
fi

echo ""
echo "Starting cleanup..."
echo ""

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# =====================================================
# Step 1: Stop and Remove Broadsea Containers
# =====================================================
echo -e "${YELLOW}Step 1: Stopping Broadsea containers...${NC}"

if [ -f "$PROJECT_ROOT/broadsea-compose.yml" ]; then
    cd "$PROJECT_ROOT"
    docker compose -f broadsea-compose.yml down -v 2>/dev/null || true
    echo -e "${GREEN}✓${NC} Broadsea containers stopped"
else
    echo -e "${YELLOW}⚠${NC} broadsea-compose.yml not found, skipping"
fi
echo ""

# =====================================================
# Step 2: Stop and Remove PostgreSQL Container
# =====================================================
echo -e "${YELLOW}Step 2: Stopping PostgreSQL container...${NC}"

if [ -f "$PROJECT_ROOT/postgres-compose.yml" ]; then
    cd "$PROJECT_ROOT"
    docker compose -f postgres-compose.yml down -v 2>/dev/null || true
    echo -e "${GREEN}✓${NC} PostgreSQL container stopped"
else
    echo -e "${YELLOW}⚠${NC} postgres-compose.yml not found, skipping"
fi
echo ""

# =====================================================
# Step 3: Remove Any Orphaned Containers
# =====================================================
echo -e "${YELLOW}Step 3: Checking for orphaned containers...${NC}"

ORPHANED=$(docker ps -a --filter "name=indicate" --filter "name=broadsea" -q)
if [ -n "$ORPHANED" ]; then
    echo "Removing orphaned containers..."
    docker rm -f $ORPHANED
    echo -e "${GREEN}✓${NC} Orphaned containers removed"
else
    echo -e "${GREEN}✓${NC} No orphaned containers found"
fi
echo ""

# =====================================================
# Step 4: Remove Volumes
# =====================================================
echo -e "${YELLOW}Step 4: Removing volumes...${NC}"

# List volumes to remove
VOLUMES=$(docker volume ls -q | grep -E "indicate|broadsea" || true)

if [ -n "$VOLUMES" ]; then
    echo "Found volumes to remove:"
    echo "$VOLUMES" | while read vol; do
        echo "  - $vol"
    done
    echo ""
    docker volume rm $VOLUMES 2>/dev/null || true
    echo -e "${GREEN}✓${NC} Volumes removed"
else
    echo -e "${GREEN}✓${NC} No volumes to remove"
fi
echo ""

# =====================================================
# Step 5: Remove Docker Network
# =====================================================
echo -e "${YELLOW}Step 5: Removing Docker network...${NC}"

if docker network ls | grep -q "indicate-network"; then
    docker network rm indicate-network 2>/dev/null || true
    echo -e "${GREEN}✓${NC} Docker network removed"
else
    echo -e "${GREEN}✓${NC} Docker network doesn't exist"
fi
echo ""

# =====================================================
# Step 6: Clean Docker System (Optional)
# =====================================================
echo -e "${YELLOW}Step 6: Cleaning Docker system...${NC}"
echo "Removing unused images and build cache..."
docker system prune -f > /dev/null 2>&1
echo -e "${GREEN}✓${NC} Docker system cleaned"
echo ""

# =====================================================
# Verification
# =====================================================
echo "====================================================="
echo "Verification"
echo "====================================================="
echo ""

echo "Remaining INDICATE/Broadsea containers:"
CONTAINERS=$(docker ps -a --filter "name=indicate" --filter "name=broadsea" --format "{{.Names}}" || echo "None")
if [ "$CONTAINERS" == "None" ] || [ -z "$CONTAINERS" ]; then
    echo -e "${GREEN}✓${NC} None (clean)"
else
    echo -e "${RED}⚠${NC} Found: $CONTAINERS"
fi
echo ""

echo "Remaining volumes:"
VOLUMES_LEFT=$(docker volume ls -q | grep -E "indicate|broadsea" || echo "None")
if [ "$VOLUMES_LEFT" == "None" ] || [ -z "$VOLUMES_LEFT" ]; then
    echo -e "${GREEN}✓${NC} None (clean)"
else
    echo -e "${RED}⚠${NC} Found: $VOLUMES_LEFT"
fi
echo ""

echo "Docker network:"
NETWORK=$(docker network ls | grep "indicate-network" || echo "None")
if [ "$NETWORK" == "None" ]; then
    echo -e "${GREEN}✓${NC} Not found (clean)"
else
    echo -e "${RED}⚠${NC} Still exists: $NETWORK"
fi
echo ""

echo "====================================================="
echo -e "${GREEN}✓ Cleanup Complete!${NC}"
echo "====================================================="
echo ""
echo "System is now clean and ready for fresh deployment."
echo ""
echo "Next steps:"
echo "  1. Review deployment configuration if needed"
echo "  2. Run: ./scripts/deploy-complete.sh"
echo ""
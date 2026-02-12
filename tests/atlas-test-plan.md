# 🧪 Atlas Testing Plan

## Step 1: Verify Services Are Running ✅
Before we start testing, let's confirm everything is up:
```
# bash
# Check all containers are running
docker ps | grep -E "indicate|broadsea"
```
Expected output:

- `indicate-postgres-omop` (PostgreSQL OMOP CDM)
- `broadsea-atlasdb` (Atlas metadata DB)
- `broadsea-webapi` (REST API)
- `broadsea-atlas` (Web UI)

## Step 2: Access Atlas UI 🌐
Once confirmed, open your browser and navigate to:

Atlas UI: http://localhost:8081/atlas

What you should see:

- Atlas landing page with navigation menu on the left
- Options for: Data Sources, Cohort Definitions, Concept Sets, etc.

# Step 3: Configure Data Source 📊
Before we can use Atlas, we need to verify the OMOP CDM data source is properly registered:

In Atlas UI, click "Data Sources" in the left sidebar
You should see "INDICATE OMOP CDM" in the dropdown at the top
Select it if not already selected
Click the "Report" tab

What you should see:

Person Count: 100
Observation Period Count: 100
Records broken down by domain (Condition, Drug, Measurement, Procedure, etc.)
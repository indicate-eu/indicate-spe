-- =====================================================
-- INDICATE SPE: Configure ohdsi OMOP CDM Source
-- =====================================================
-- Purpose: Register existing OMOP CDM with ohdsi
-- Database: Atlas DB (broadsea-atlasdb)
-- Schema: ohdsi
-- =====================================================

-- Connect to Atlas DB as postgres user
-- Run: docker exec -it broadsea-atlasdb psql -U postgres -d postgres

\echo '====================================================='
\echo 'INDICATE SPE: ohdsi Source Configuration'
\echo '====================================================='
\echo ''

-- Set schema
SET search_path TO ohdsi;

-- =====================================================
-- 1. Register OMOP CDM Source
-- =====================================================
\echo 'Step 1: Registering OMOP CDM source...'

INSERT INTO ohdsi.source (
    source_id, 
    source_name, 
    source_key, 
    source_connection, 
    source_dialect,
    username,
    password
)
VALUES (
    1,
    'INDICATE OMOP CDM',
    'INDICATE',
    'jdbc:postgresql://indicate-postgres-omop:5432/omop_cdm',
    'postgresql',
    'postgres',
    'postgres'
)
ON CONFLICT (source_id) DO UPDATE
SET 
    source_name = EXCLUDED.source_name,
    source_connection = EXCLUDED.source_connection;

\echo '   ✓ Source registered'
\echo ''

-- =====================================================
-- 2. Register Source Daimons (Schema Mappings)
-- =====================================================
\echo 'Step 2: Registering source daimons (schema mappings)...'

-- Daimon types:
-- 0 = CDM (Clinical Data Model)
-- 1 = Vocabulary
-- 2 = Results (cohort tables)
-- 5 = Evidence (for evidence generation)

-- Delete existing daimons for this source
DELETE FROM ohdsi.source_daimon WHERE source_id = 1;

-- CDM Daimon
INSERT INTO ohdsi.source_daimon (
    source_daimon_id,
    source_id,
    daimon_type,
    table_qualifier,
    priority
)
VALUES (1, 1, 0, 'cdm', 0);

\echo '   ✓ CDM daimon registered (schema: cdm)'

-- Vocabulary Daimon
INSERT INTO ohdsi.source_daimon (
    source_daimon_id,
    source_id,
    daimon_type,
    table_qualifier,
    priority
)
VALUES (2, 1, 1, 'vocab', 1);

\echo '   ✓ Vocabulary daimon registered (schema: vocab)'

-- Results Daimon
INSERT INTO ohdsi.source_daimon (
    source_daimon_id,
    source_id,
    daimon_type,
    table_qualifier,
    priority
)
VALUES (3, 1, 2, 'results', 0);

\echo '   ✓ Results daimon registered (schema: results)'

-- Evidence Daimon
INSERT INTO ohdsi.source_daimon (
    source_daimon_id,
    source_id,
    daimon_type,
    table_qualifier,
    priority
)
VALUES (4, 1, 5, 'results', 0);

\echo '   ✓ Evidence daimon registered (schema: results)'
\echo ''

-- =====================================================
-- 3. Verify Configuration
-- =====================================================
\echo '====================================================='
\echo 'VERIFICATION'
\echo '====================================================='
\echo ''

\echo 'Registered Sources:'
SELECT 
    source_id,
    source_name,
    source_key,
    source_connection,
    source_dialect
FROM ohdsi.source
ORDER BY source_id;

\echo ''
\echo 'Source Daimons (Schema Mappings):'
SELECT 
    sd.source_daimon_id,
    s.source_name,
    CASE sd.daimon_type
        WHEN 0 THEN 'CDM'
        WHEN 1 THEN 'Vocabulary'
        WHEN 2 THEN 'Results'
        WHEN 5 THEN 'Evidence'
        ELSE 'Unknown'
    END as daimon_type,
    sd.table_qualifier as schema_name,
    sd.priority
FROM ohdsi.source_daimon sd
JOIN ohdsi.source s ON sd.source_id = s.source_id
ORDER BY sd.source_daimon_id;

\echo ''
\echo '====================================================='
\echo 'CONFIGURATION COMPLETE!'
\echo '====================================================='

-- =====================================================
-- INDICATE SPE: Load OMOP Vocabulary from Athena
-- =====================================================
-- Purpose: Load vocabulary CSV files into vocab schema
-- Tables: 9 core vocabulary tables
-- Source: Athena OHDSI vocabulary bundle (v20250827)
-- =====================================================

SET search_path TO vocab;

-- =====================================================
-- 1. VOCABULARY table
-- =====================================================
TRUNCATE TABLE vocabulary CASCADE;

\COPY vocabulary FROM '/vocabularies/VOCABULARY.csv' WITH DELIMITER E'\t' CSV HEADER QUOTE E'\b';

-- Verify
SELECT COUNT(*) as vocabulary_count FROM vocabulary;
SELECT * FROM vocabulary LIMIT 5;

-- =====================================================
-- 2. DOMAIN table
-- =====================================================
TRUNCATE TABLE domain CASCADE;

\COPY domain FROM '/vocabularies/DOMAIN.csv' WITH DELIMITER E'\t' CSV HEADER QUOTE E'\b';

-- Verify
SELECT COUNT(*) as domain_count FROM domain;
SELECT * FROM domain LIMIT 5;

-- =====================================================
-- 3. CONCEPT_CLASS table
-- =====================================================
TRUNCATE TABLE concept_class CASCADE;

\COPY concept_class FROM '/vocabularies/CONCEPT_CLASS.csv' WITH DELIMITER E'\t' CSV HEADER QUOTE E'\b';

-- Verify
SELECT COUNT(*) as concept_class_count FROM concept_class;
SELECT * FROM concept_class LIMIT 5;

-- =====================================================
-- 4. RELATIONSHIP table
-- =====================================================
TRUNCATE TABLE relationship CASCADE;

\COPY relationship FROM '/vocabularies/RELATIONSHIP.csv' WITH DELIMITER E'\t' CSV HEADER QUOTE E'\b';

-- Verify
SELECT COUNT(*) as relationship_count FROM relationship;
SELECT * FROM relationship LIMIT 5;

-- =====================================================
-- 5. CONCEPT table (LARGEST - may take 5-10 minutes)
-- =====================================================
TRUNCATE TABLE concept CASCADE;

\echo 'Loading CONCEPT table (this may take 5-10 minutes)...'
\COPY concept FROM '/vocabularies/CONCEPT.csv' WITH DELIMITER E'\t' CSV HEADER QUOTE E'\b';

-- Verify
SELECT COUNT(*) as concept_count FROM concept;
SELECT vocabulary_id, COUNT(*) as concepts 
FROM concept 
GROUP BY vocabulary_id 
ORDER BY concepts DESC;

-- =====================================================
-- 6. CONCEPT_RELATIONSHIP table (LARGE - may take 5-10 minutes)
-- =====================================================
TRUNCATE TABLE concept_relationship CASCADE;

\echo 'Loading CONCEPT_RELATIONSHIP table (this may take 5-10 minutes)...'
\COPY concept_relationship FROM '/vocabularies/CONCEPT_RELATIONSHIP.csv' WITH DELIMITER E'\t' CSV HEADER QUOTE E'\b';

-- Verify
SELECT COUNT(*) as concept_relationship_count FROM concept_relationship;

-- =====================================================
-- 7. CONCEPT_SYNONYM table
-- =====================================================
TRUNCATE TABLE concept_synonym CASCADE;

\COPY concept_synonym FROM '/vocabularies/CONCEPT_SYNONYM.csv' WITH DELIMITER E'\t' CSV HEADER QUOTE E'\b';

-- Verify
SELECT COUNT(*) as concept_synonym_count FROM concept_synonym;

-- =====================================================
-- 8. CONCEPT_ANCESTOR table (LARGEST - may take 10-15 minutes)
-- =====================================================
TRUNCATE TABLE concept_ancestor CASCADE;

\echo 'Loading CONCEPT_ANCESTOR table (this may take 10-15 minutes)...'
\COPY concept_ancestor FROM '/vocabularies/CONCEPT_ANCESTOR.csv' WITH DELIMITER E'\t' CSV HEADER QUOTE E'\b';

-- Verify
SELECT COUNT(*) as concept_ancestor_count FROM concept_ancestor;

-- =====================================================
-- 9. DRUG_STRENGTH table
-- =====================================================
TRUNCATE TABLE drug_strength CASCADE;

\COPY drug_strength FROM '/vocabularies/DRUG_STRENGTH.csv' WITH DELIMITER E'\t' CSV HEADER QUOTE E'\b';

-- Verify
SELECT COUNT(*) as drug_strength_count FROM drug_strength;

-- =====================================================
-- Final Verification Queries
-- =====================================================
\echo '====================================================='
\echo 'VOCABULARY LOAD SUMMARY'
\echo '====================================================='

SELECT 'vocabulary' as table_name, COUNT(*) as row_count FROM vocabulary
UNION ALL
SELECT 'domain', COUNT(*) FROM domain
UNION ALL
SELECT 'concept_class', COUNT(*) FROM concept_class
UNION ALL
SELECT 'relationship', COUNT(*) FROM relationship
UNION ALL
SELECT 'concept', COUNT(*) FROM concept
UNION ALL
SELECT 'concept_relationship', COUNT(*) FROM concept_relationship
UNION ALL
SELECT 'concept_synonym', COUNT(*) FROM concept_synonym
UNION ALL
SELECT 'concept_ancestor', COUNT(*) FROM concept_ancestor
UNION ALL
SELECT 'drug_strength', COUNT(*) FROM drug_strength
ORDER BY table_name;

\echo '====================================================='
\echo 'VOCABULARY DISTRIBUTION'
\echo '====================================================='

SELECT 
    vocabulary_id,
    vocabulary_name,
    COUNT(*) as concept_count
FROM concept c
JOIN vocabulary v ON c.vocabulary_id = v.vocabulary_id
GROUP BY c.vocabulary_id, v.vocabulary_name
ORDER BY concept_count DESC;

\echo '====================================================='
\echo 'VERIFY UCUM CONCEPTS (Units of Measure)'
\echo '====================================================='

SELECT vocabulary_id, COUNT(*) as ucum_concepts
FROM concept
WHERE vocabulary_id = 'UCUM'
GROUP BY vocabulary_id;

SELECT concept_id, concept_name, concept_code
FROM concept
WHERE vocabulary_id = 'UCUM'
LIMIT 10;

\echo '====================================================='
\echo 'VERIFY ICU-RELEVANT VOCABULARIES'
\echo '====================================================='

-- Check SNOMED (conditions, procedures)
SELECT COUNT(*) as snomed_concepts FROM concept WHERE vocabulary_id = 'SNOMED';

-- Check LOINC (lab tests, measurements)
SELECT COUNT(*) as loinc_concepts FROM concept WHERE vocabulary_id = 'LOINC';

-- Check RxNorm (medications)
SELECT COUNT(*) as rxnorm_concepts FROM concept WHERE vocabulary_id = 'RxNorm';

\echo '====================================================='
\echo 'VOCABULARY LOAD COMPLETE!'
\echo '====================================================='
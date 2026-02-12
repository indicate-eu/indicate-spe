-- =====================================================
-- INDICATE SPE: Data Quality Verification Queries
-- =====================================================
-- Purpose: Validate generated ICU dummy data
-- Usage: Run after generate-icu-data.sh completes
-- =====================================================

SET search_path TO cdm;

\echo '====================================================='
\echo 'TABLE ROW COUNTS'
\echo '====================================================='

SELECT 
    'person' as table_name, 
    COUNT(*) as row_count,
    'Patient demographics' as description
FROM person
UNION ALL
SELECT 'visit_occurrence', COUNT(*), 'ICU admissions' FROM visit_occurrence
UNION ALL
SELECT 'condition_occurrence', COUNT(*), 'Diagnoses' FROM condition_occurrence
UNION ALL
SELECT 'measurement', COUNT(*), 'Vital signs + Labs + Ventilation' FROM measurement
UNION ALL
SELECT 'drug_exposure', COUNT(*), 'Medications' FROM drug_exposure
UNION ALL
SELECT 'procedure_occurrence', COUNT(*), 'Procedures' FROM procedure_occurrence
ORDER BY table_name;

\echo ''
\echo '====================================================='
\echo 'PATIENT DEMOGRAPHICS'
\echo '====================================================='

SELECT 
    g.concept_name as gender,
    COUNT(*) as patient_count,
    ROUND(AVG(EXTRACT(YEAR FROM CURRENT_DATE) - year_of_birth), 1) as avg_age
FROM person p
JOIN vocab.concept g ON p.gender_concept_id = g.concept_id
GROUP BY g.concept_name
ORDER BY gender;

\echo ''
\echo '====================================================='
\echo 'ICU LENGTH OF STAY DISTRIBUTION'
\echo '====================================================='

SELECT 
    CASE 
        WHEN los_days <= 2 THEN '1-2 days'
        WHEN los_days <= 5 THEN '3-5 days'
        WHEN los_days <= 10 THEN '6-10 days'
        ELSE '>10 days'
    END as los_category,
    COUNT(*) as visit_count,
    ROUND(AVG(los_days), 1) as avg_los
FROM (
    SELECT 
        visit_occurrence_id,
        visit_end_date - visit_start_date as los_days
    FROM visit_occurrence
) los_data
GROUP BY los_category
ORDER BY 
    CASE los_category
        WHEN '1-2 days' THEN 1
        WHEN '3-5 days' THEN 2
        WHEN '6-10 days' THEN 3
        ELSE 4
    END;

\echo ''
\echo '====================================================='
\echo 'TOP 10 CONDITIONS (DIAGNOSES)'
\echo '====================================================='

SELECT 
    c.concept_name,
    COUNT(*) as occurrence_count,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(DISTINCT person_id) FROM condition_occurrence), 1) as percent_patients
FROM condition_occurrence co
JOIN vocab.concept c ON co.condition_concept_id = c.concept_id
GROUP BY c.concept_name
ORDER BY occurrence_count DESC
LIMIT 10;

\echo ''
\echo '====================================================='
\echo 'VITAL SIGNS MEASUREMENTS (Sample)'
\echo '====================================================='

SELECT 
    c.concept_name,
    COUNT(*) as measurement_count,
    ROUND(AVG(m.value_as_number), 2) as avg_value,
    ROUND(MIN(m.value_as_number), 2) as min_value,
    ROUND(MAX(m.value_as_number), 2) as max_value,
    u.concept_name as unit
FROM measurement m
JOIN vocab.concept c ON m.measurement_concept_id = c.concept_id
LEFT JOIN vocab.concept u ON m.unit_concept_id = u.concept_id
WHERE c.concept_name IN ('Heart rate', 'Systolic blood pressure', 'Oxygen saturation')
GROUP BY c.concept_name, u.concept_name
ORDER BY c.concept_name;

\echo ''
\echo '====================================================='
\echo 'LABORATORY MEASUREMENTS (Sample)'
\echo '====================================================='

SELECT 
    c.concept_name,
    COUNT(*) as measurement_count,
    ROUND(AVG(m.value_as_number), 2) as avg_value,
    ROUND(MIN(m.value_as_number), 2) as min_value,
    ROUND(MAX(m.value_as_number), 2) as max_value,
    u.concept_name as unit
FROM measurement m
JOIN vocab.concept c ON m.measurement_concept_id = c.concept_id
LEFT JOIN vocab.concept u ON m.unit_concept_id = u.concept_id
WHERE c.concept_name IN ('Lactate', 'Creatinine', 'Hemoglobin')
GROUP BY c.concept_name, u.concept_name
ORDER BY c.concept_name;

\echo ''
\echo '====================================================='
\echo 'VENTILATION PARAMETERS (Ventilated Patients)'
\echo '====================================================='

SELECT 
    c.concept_name,
    COUNT(*) as measurement_count,
    ROUND(AVG(m.value_as_number), 2) as avg_value,
    ROUND(MIN(m.value_as_number), 2) as min_value,
    ROUND(MAX(m.value_as_number), 2) as max_value,
    u.concept_name as unit
FROM measurement m
JOIN vocab.concept c ON m.measurement_concept_id = c.concept_id
LEFT JOIN vocab.concept u ON m.unit_concept_id = u.concept_id
WHERE c.concept_name LIKE '%FiO2%' 
   OR c.concept_name LIKE '%PEEP%'
   OR c.concept_name LIKE '%tidal volume%'
GROUP BY c.concept_name, u.concept_name
ORDER BY c.concept_name;

\echo ''
\echo '====================================================='
\echo 'TOP MEDICATIONS'
\echo '====================================================='

SELECT 
    c.concept_name,
    COUNT(*) as exposure_count,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(DISTINCT person_id) FROM drug_exposure), 1) as percent_patients
FROM drug_exposure de
JOIN vocab.concept c ON de.drug_concept_id = c.concept_id
GROUP BY c.concept_name
ORDER BY exposure_count DESC
LIMIT 10;

\echo ''
\echo '====================================================='
\echo 'ICU PROCEDURES'
\echo '====================================================='

SELECT 
    c.concept_name,
    COUNT(*) as procedure_count,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(DISTINCT person_id) FROM procedure_occurrence), 1) as percent_patients
FROM procedure_occurrence po
JOIN vocab.concept c ON po.procedure_concept_id = c.concept_id
GROUP BY c.concept_name
ORDER BY procedure_count DESC;

\echo ''
\echo '====================================================='
\echo 'SAMPLE PATIENT TIMELINE (Patient 1)'
\echo '====================================================='

SELECT 
    'Demographics' as data_type,
    NULL as datetime,
    'Age: ' || (EXTRACT(YEAR FROM CURRENT_DATE) - p.year_of_birth) || ', Gender: ' || g.concept_name as details
FROM person p
JOIN vocab.concept g ON p.gender_concept_id = g.concept_id
WHERE p.person_id = 1

UNION ALL

SELECT 
    'Visit',
    v.visit_start_datetime,
    'ICU Admission, LOS: ' || (v.visit_end_date - v.visit_start_date) || ' days'
FROM visit_occurrence v
WHERE v.person_id = 1

UNION ALL

SELECT 
    'Condition',
    co.condition_start_datetime,
    c.concept_name
FROM condition_occurrence co
JOIN vocab.concept c ON co.condition_concept_id = c.concept_id
WHERE co.person_id = 1

UNION ALL

SELECT 
    'Procedure',
    po.procedure_datetime,
    c.concept_name
FROM procedure_occurrence po
JOIN vocab.concept c ON po.procedure_concept_id = c.concept_id
WHERE po.person_id = 1

ORDER BY datetime NULLS FIRST
LIMIT 10;

\echo ''
\echo '====================================================='
\echo 'DATA QUALITY CHECKS'
\echo '====================================================='

-- Check for NULL values in critical fields
SELECT 
    'Persons with NULL gender' as check_name,
    COUNT(*) as issue_count
FROM person WHERE gender_concept_id IS NULL OR gender_concept_id = 0

UNION ALL

SELECT 
    'Visits with NULL dates',
    COUNT(*)
FROM visit_occurrence WHERE visit_start_date IS NULL OR visit_end_date IS NULL

UNION ALL

SELECT 
    'Measurements with NULL values',
    COUNT(*)
FROM measurement WHERE value_as_number IS NULL

UNION ALL

SELECT 
    'Invalid concept IDs (concept_id = 0)',
    COUNT(*)
FROM measurement WHERE measurement_concept_id = 0;

\echo ''
\echo '====================================================='
\echo 'VERIFICATION COMPLETE'
\echo '====================================================='
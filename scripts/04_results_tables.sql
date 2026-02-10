-- Results Schema Tables
-- Used by WebAPI and Atlas for cohort definitions and analysis results

-- COHORT: Contains cohort definitions and membership
CREATE TABLE results.cohort (
    cohort_definition_id INTEGER NOT NULL,
    subject_id INTEGER NOT NULL,
    cohort_start_date DATE NOT NULL,
    cohort_end_date DATE NOT NULL
);

-- COHORT_DEFINITION: Metadata about cohort definitions (populated by WebAPI)
CREATE TABLE results.cohort_definition (
    cohort_definition_id INTEGER NOT NULL,
    cohort_definition_name VARCHAR(255) NOT NULL,
    cohort_definition_description TEXT NULL,
    definition_type_concept_id INTEGER NOT NULL,
    cohort_definition_syntax TEXT NULL,
    subject_concept_id INTEGER NOT NULL,
    cohort_initiation_date DATE NULL
);

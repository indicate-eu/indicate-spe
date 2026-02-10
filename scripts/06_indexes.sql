-- Performance Indexes for OMOP CDM Tables

-- Person table indexes
CREATE INDEX idx_person_id ON cdm.person (person_id);

-- Observation period indexes
CREATE INDEX idx_observation_period_id ON cdm.observation_period (person_id);

-- Visit occurrence indexes
CREATE INDEX idx_visit_person_id ON cdm.visit_occurrence (person_id);
CREATE INDEX idx_visit_concept_id ON cdm.visit_occurrence (visit_concept_id);

-- Visit detail indexes
CREATE INDEX idx_visit_detail_person_id ON cdm.visit_detail (person_id);
CREATE INDEX idx_visit_detail_concept_id ON cdm.visit_detail (visit_detail_concept_id);
CREATE INDEX idx_visit_detail_occurrence_id ON cdm.visit_detail (visit_occurrence_id);

-- Condition occurrence indexes
CREATE INDEX idx_condition_person_id ON cdm.condition_occurrence (person_id);
CREATE INDEX idx_condition_concept_id ON cdm.condition_occurrence (condition_concept_id);
CREATE INDEX idx_condition_visit_id ON cdm.condition_occurrence (visit_occurrence_id);

-- Drug exposure indexes
CREATE INDEX idx_drug_person_id ON cdm.drug_exposure (person_id);
CREATE INDEX idx_drug_concept_id ON cdm.drug_exposure (drug_concept_id);
CREATE INDEX idx_drug_visit_id ON cdm.drug_exposure (visit_occurrence_id);

-- Procedure occurrence indexes
CREATE INDEX idx_procedure_person_id ON cdm.procedure_occurrence (person_id);
CREATE INDEX idx_procedure_concept_id ON cdm.procedure_occurrence (procedure_concept_id);
CREATE INDEX idx_procedure_visit_id ON cdm.procedure_occurrence (visit_occurrence_id);

-- Measurement indexes (CRITICAL FOR ICU DATA - labs, vitals, etc.)
CREATE INDEX idx_measurement_person_id ON cdm.measurement (person_id);
CREATE INDEX idx_measurement_concept_id ON cdm.measurement (measurement_concept_id);
CREATE INDEX idx_measurement_visit_id ON cdm.measurement (visit_occurrence_id);

-- Observation indexes
CREATE INDEX idx_observation_person_id ON cdm.observation (person_id);
CREATE INDEX idx_observation_concept_id ON cdm.observation (observation_concept_id);
CREATE INDEX idx_observation_visit_id ON cdm.observation (visit_occurrence_id);

-- Vocabulary indexes for lookups
CREATE INDEX idx_concept_concept_id ON vocab.concept (concept_id);
CREATE INDEX idx_concept_code ON vocab.concept (concept_code);
CREATE INDEX idx_concept_vocabluary_id ON vocab.concept (vocabulary_id);
CREATE INDEX idx_concept_domain_id ON vocab.concept (domain_id);
CREATE INDEX idx_concept_class_id ON vocab.concept (concept_class_id);

CREATE INDEX idx_concept_relationship_id_1 ON vocab.concept_relationship (concept_id_1);
CREATE INDEX idx_concept_relationship_id_2 ON vocab.concept_relationship (concept_id_2);
CREATE INDEX idx_concept_relationship_id_3 ON vocab.concept_relationship (relationship_id);

CREATE INDEX idx_concept_ancestor_id_1 ON vocab.concept_ancestor (ancestor_concept_id);
CREATE INDEX idx_concept_ancestor_id_2 ON vocab.concept_ancestor (descendant_concept_id);

-- Results schema indexes
CREATE INDEX idx_cohort_subject_id ON results.cohort (subject_id);
CREATE INDEX idx_cohort_definition_id ON results.cohort (cohort_definition_id);

-- Create OMOP CDM schemas
-- This script creates the necessary schemas for OHDSI/OMOP CDM

-- CDM schema (contains standardized clinical data)
CREATE SCHEMA IF NOT EXISTS cdm;

-- Vocabulary schema (contains OMOP vocabulary tables)
CREATE SCHEMA IF NOT EXISTS vocab;

-- Results schema (contains cohort definitions, analysis results)
CREATE SCHEMA IF NOT EXISTS results;

-- WebAPI schema (will be created by Broadsea later)
CREATE SCHEMA IF NOT EXISTS webapi;

-- Grant permissions
GRANT USAGE ON SCHEMA cdm TO postgres;
GRANT USAGE ON SCHEMA vocab TO postgres;
GRANT USAGE ON SCHEMA results TO postgres;
GRANT USAGE ON SCHEMA webapi TO postgres;

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA cdm TO postgres;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA vocab TO postgres;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA results TO postgres;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA webapi TO postgres;

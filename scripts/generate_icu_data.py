#!/usr/bin/env python3
"""
=====================================================
INDICATE SPE: Generate Dummy ICU Data
=====================================================
Purpose: Generate realistic synthetic ICU patient data
Population: 100 patients with mixed severity
Domains: Ventilation, Laboratory, Vital Signs, Medications
OMOP CDM: v5.4 compliant with valid concept_ids
=====================================================
"""

import psycopg2
import random
import datetime
from typing import Dict, List, Tuple
import sys

# Database connection parameters
DB_CONFIG = {
    'host': 'localhost',
    'port': 5432,
    'database': 'omop_cdm',
    'user': 'postgres',
    'password': 'postgres'
}

# Random seed for reproducibility
random.seed(42)

class ICUDataGenerator:
    def __init__(self, db_config: Dict):
        """Initialize generator with database connection."""
        self.conn = psycopg2.connect(**db_config)
        self.cursor = self.conn.cursor()
        self.concept_cache = {}
        
    def get_concept_id(self, concept_code: str, vocabulary_id: str) -> int:
        """Retrieve concept_id from vocabulary."""
        cache_key = f"{vocabulary_id}:{concept_code}"
        if cache_key in self.concept_cache:
            return self.concept_cache[cache_key]
            
        query = """
            SELECT concept_id 
            FROM vocab.concept 
            WHERE concept_code = %s 
            AND vocabulary_id = %s 
            AND invalid_reason IS NULL
            LIMIT 1
        """
        self.cursor.execute(query, (concept_code, vocabulary_id))
        result = self.cursor.fetchone()
        
        if result:
            self.concept_cache[cache_key] = result[0]
            return result[0]
        else:
            print(f"WARNING: Concept not found: {concept_code} ({vocabulary_id})")
            return 0
    
    def search_concept(self, search_term: str, domain_id: str = None) -> int:
        """Search for concept by name."""
        query = """
            SELECT concept_id 
            FROM vocab.concept 
            WHERE LOWER(concept_name) LIKE LOWER(%s)
            AND standard_concept = 'S'
            AND invalid_reason IS NULL
        """
        params = [f"%{search_term}%"]
        
        if domain_id:
            query += " AND domain_id = %s"
            params.append(domain_id)
        
        query += " LIMIT 1"
        self.cursor.execute(query, params)
        result = self.cursor.fetchone()
        return result[0] if result else 0

    def clear_existing_data(self):
        """Clear all existing patient data from CDM tables."""
        print("\n🗑️  Clearing existing data...")

        tables = [
            'cdm.drug_exposure',
            'cdm.procedure_occurrence',
            'cdm.measurement',
            'cdm.observation',
            'cdm.condition_occurrence',
            'cdm.visit_occurrence',
            'cdm.person'
        ]

        for table in tables:
            self.cursor.execute(f"TRUNCATE TABLE {table} CASCADE")
            print(f"   ✓ Cleared {table}")

        self.conn.commit()
        print("   ✓ All tables cleared")

    def generate_persons(self, n_patients: int = 100):
        """Generate PERSON table - patient demographics."""
        print(f"\n1. Generating {n_patients} patients...")
        
        # Get gender concepts
        male_concept = self.get_concept_id('M', 'Gender')
        female_concept = self.get_concept_id('F', 'Gender')
        
        # Get race/ethnicity concepts (using standard concepts)
        white_concept = 8527  # White
        unknown_race_concept = 8552  # Unknown
        
        persons = []
        for i in range(1, n_patients + 1):
            gender_concept = random.choice([male_concept, female_concept])
            birth_year = random.randint(1940, 2005)  # Ages 18-85 in 2025
            birth_month = random.randint(1, 12)
            birth_day = random.randint(1, 28)

            persons.append((
                i,  # person_id
                gender_concept,  # gender_concept_id
                birth_year,  # year_of_birth
                birth_month,  # month_of_birth
                birth_day,  # day_of_birth
                datetime.datetime(birth_year, birth_month, birth_day, 0, 0),  # birth_datetime
                white_concept if random.random() > 0.3 else unknown_race_concept,  # race_concept_id
                0,  # ethnicity_concept_id (0 = unknown)
                None,  # location_id
                None,  # provider_id
                None,  # care_site_id
                f"P{i:05d}",  # person_source_value
                'M' if gender_concept == male_concept else 'F',  # gender_source_value
                None,  # gender_source_concept_id
                None,  # race_source_value
                0,  # race_source_concept_id
                None,  # ethnicity_source_value
                0  # ethnicity_source_concept_id
            ))
        
        insert_query = """
            INSERT INTO cdm.person (
                person_id, gender_concept_id, year_of_birth, month_of_birth, day_of_birth,
                birth_datetime, race_concept_id, ethnicity_concept_id, location_id, provider_id,
                care_site_id, person_source_value, gender_source_value, gender_source_concept_id,
                race_source_value, race_source_concept_id, ethnicity_source_value, 
                ethnicity_source_concept_id
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        """
        self.cursor.executemany(insert_query, persons)
        self.conn.commit()
        print(f"   ✓ Created {n_patients} patients")
    
    def generate_icu_visits(self, n_patients: int = 100):
        """Generate VISIT_OCCURRENCE - ICU admissions."""
        print("\n2. Generating ICU visits...")
        
        # ICU visit concept (Intensive Care)
        icu_concept = 9201  # Inpatient Visit
        
        visits = []
        visit_id = 1
        base_date = datetime.datetime(2024, 1, 1)
        
        for person_id in range(1, n_patients + 1):
            # Random admission date in 2024
            admission_days = random.randint(0, 365)
            admission_date = base_date + datetime.timedelta(days=admission_days)
            
            # ICU length of stay: 1-21 days (skewed toward shorter stays)
            los_days = int(random.expovariate(1/5)) + 1  # Mean ~5 days
            los_days = min(los_days, 21)  # Cap at 21 days
            
            discharge_date = admission_date + datetime.timedelta(days=los_days)
            
            visits.append((
                visit_id,  # visit_occurrence_id
                person_id,  # person_id
                icu_concept,  # visit_concept_id
                admission_date.date(),  # visit_start_date
                admission_date,  # visit_start_datetime
                discharge_date.date(),  # visit_end_date
                discharge_date,  # visit_end_datetime
                32817,  # visit_type_concept_id (EHR)
                None,  # provider_id
                None,  # care_site_id
                f"ICU-{visit_id}",  # visit_source_value
                0,  # visit_source_concept_id
                0,  # admitted_from_concept_id
                None,  # admitted_from_source_value
                32826 if random.random() > 0.1 else 32767,  # discharged_to_concept_id (Patient discharged alive vs. Patient died)
                None  # discharged_to_source_value
            ))
            visit_id += 1
        
        insert_query = """
            INSERT INTO cdm.visit_occurrence (
                visit_occurrence_id, person_id, visit_concept_id, visit_start_date,
                visit_start_datetime, visit_end_date, visit_end_datetime, visit_type_concept_id,
                provider_id, care_site_id, visit_source_value, visit_source_concept_id,
                admitted_from_concept_id, admitted_from_source_value, discharged_to_concept_id,
                discharged_to_source_value
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        """
        self.cursor.executemany(insert_query, visits)
        self.conn.commit()
        print(f"   ✓ Created {len(visits)} ICU visits")
        
        return visits  # Return for use in other generators
    
    def generate_conditions(self, visits: List):
        """Generate CONDITION_OCCURRENCE - ICU diagnoses."""
        print("\n3. Generating ICU conditions (diagnoses)...")
        
        # Common ICU conditions (SNOMED codes)
        icu_conditions = [
            (self.search_concept('sepsis', 'Condition'), 'Sepsis', 0.4),
            (self.search_concept('respiratory failure', 'Condition'), 'Respiratory Failure', 0.6),
            (self.search_concept('acute respiratory distress', 'Condition'), 'ARDS', 0.2),
            (self.search_concept('pneumonia', 'Condition'), 'Pneumonia', 0.35),
            (self.search_concept('shock', 'Condition'), 'Shock', 0.25),
        ]
        
        conditions = []
        condition_id = 1
        
        for visit in visits:
            visit_id = visit[0]
            person_id = visit[1]
            visit_start = visit[3]

            # Each patient gets 1-3 conditions (filtered by probability)
            n_conditions = random.randint(1, 3)
            filtered_conditions = [c for c in icu_conditions if random.random() < c[2]]

            # Only sample if we have conditions available
            if not filtered_conditions:
                continue

            selected_conditions = random.sample(
                filtered_conditions,
                k=min(n_conditions, len(filtered_conditions))
            )
            
            for concept_id, name, prob in selected_conditions:
                if concept_id == 0:
                    continue
                    
                conditions.append((
                    condition_id,  # condition_occurrence_id
                    person_id,  # person_id
                    concept_id,  # condition_concept_id
                    visit_start,  # condition_start_date
                    visit_start,  # condition_start_datetime
                    None,  # condition_end_date
                    None,  # condition_end_datetime
                    32817,  # condition_type_concept_id (EHR)
                    None,  # condition_status_concept_id
                    None,  # stop_reason
                    None,  # provider_id
                    visit_id,  # visit_occurrence_id
                    None,  # visit_detail_id
                    name,  # condition_source_value
                    0,  # condition_source_concept_id
                    None,  # condition_status_source_value
                ))
                condition_id += 1
        
        insert_query = """
            INSERT INTO cdm.condition_occurrence (
                condition_occurrence_id, person_id, condition_concept_id, condition_start_date,
                condition_start_datetime, condition_end_date, condition_end_datetime,
                condition_type_concept_id, condition_status_concept_id, stop_reason,
                provider_id, visit_occurrence_id, visit_detail_id, condition_source_value,
                condition_source_concept_id, condition_status_source_value
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        """
        self.cursor.executemany(insert_query, conditions)
        self.conn.commit()
        print(f"   ✓ Created {len(conditions)} condition records")
    
    def generate_vital_signs(self, visits: List):
        """Generate MEASUREMENT - Vital signs (hourly)."""
        print("\n4. Generating vital signs (hourly measurements)...")
        
        # Vital sign concepts (LOINC)
        vital_signs = [
            (self.search_concept('heart rate', 'Measurement'), 'Heart Rate', 60, 120, 8876),  # beats/min
            (self.search_concept('systolic blood pressure', 'Measurement'), 'Systolic BP', 90, 160, 8876),  # mmHg
            (self.search_concept('diastolic blood pressure', 'Measurement'), 'Diastolic BP', 50, 90, 8876),
            (self.search_concept('oxygen saturation', 'Measurement'), 'SpO2', 88, 100, 8554),  # %
            (self.search_concept('body temperature', 'Measurement'), 'Temperature', 36.0, 39.5, 8653),  # Celsius
            (self.search_concept('respiratory rate', 'Measurement'), 'Respiratory Rate', 12, 30, 8876),  # /min
        ]
        
        measurements = []
        measurement_id = 1
        
        for visit in visits:
            visit_id = visit[0]
            person_id = visit[1]
            visit_start = visit[4]  # datetime
            visit_end = visit[6]
            
            # Calculate hours in ICU
            hours_in_icu = int((visit_end - visit_start).total_seconds() / 3600)
            
            # Generate hourly vital signs
            for hour in range(0, hours_in_icu, 1):  # Hourly
                measurement_time = visit_start + datetime.timedelta(hours=hour)
                
                for concept_id, name, min_val, max_val, unit_concept in vital_signs:
                    if concept_id == 0:
                        continue
                    
                    # Add realistic variation
                    value = random.uniform(min_val, max_val)
                    
                    measurements.append((
                        measurement_id,  # measurement_id
                        person_id,  # person_id
                        concept_id,  # measurement_concept_id
                        measurement_time.date(),  # measurement_date
                        measurement_time,  # measurement_datetime
                        None,  # measurement_time
                        32817,  # measurement_type_concept_id (EHR)
                        None,  # operator_concept_id
                        round(value, 2),  # value_as_number
                        0,  # value_as_concept_id
                        unit_concept,  # unit_concept_id
                        None,  # range_low
                        None,  # range_high
                        None,  # provider_id
                        visit_id,  # visit_occurrence_id
                        None,  # visit_detail_id
                        name,  # measurement_source_value
                        0,  # measurement_source_concept_id
                        None,  # unit_source_value
                        None,  # value_source_value
                    ))
                    measurement_id += 1
                    
                    # Commit in batches to avoid memory issues
                    if len(measurements) >= 10000:
                        self._insert_measurements_batch(measurements)
                        measurements = []
        
        # Insert remaining
        if measurements:
            self._insert_measurements_batch(measurements)
        
        print(f"   ✓ Created ~{measurement_id-1} vital sign measurements")
    
    def generate_laboratory_results(self, visits: List):
        """Generate MEASUREMENT - Laboratory results (daily)."""
        print("\n5. Generating laboratory results (daily)...")
        
        # Lab test concepts (LOINC)
        lab_tests = [
            (self.search_concept('lactate', 'Measurement'), 'Lactate', 0.5, 8.0, 8753),  # mmol/L
            (self.search_concept('creatinine', 'Measurement'), 'Creatinine', 0.5, 3.5, 8840),  # mg/dL
            (self.search_concept('white blood cell', 'Measurement'), 'WBC', 4.0, 25.0, 8848),  # 10*3/uL
            (self.search_concept('hemoglobin', 'Measurement'), 'Hemoglobin', 7.0, 16.0, 8713),  # g/dL
            (self.search_concept('platelets', 'Measurement'), 'Platelets', 50, 400, 8848),  # 10*3/uL
            (self.search_concept('sodium', 'Measurement'), 'Sodium', 130, 150, 8753),  # mmol/L
            (self.search_concept('potassium', 'Measurement'), 'Potassium', 3.0, 5.5, 8753),  # mmol/L
            (self.search_concept('arterial ph', 'Measurement'), 'pH', 7.20, 7.50, 0),  # no unit
            (self.search_concept('pco2', 'Measurement'), 'PaCO2', 30, 60, 8876),  # mmHg
            (self.search_concept('po2', 'Measurement'), 'PaO2', 60, 120, 8876),  # mmHg
        ]
        
        measurements = []
        measurement_id = self._get_max_measurement_id() + 1
        
        for visit in visits:
            visit_id = visit[0]
            person_id = visit[1]
            visit_start = visit[4]
            visit_end = visit[6]
            
            days_in_icu = (visit_end - visit_start).days + 1
            
            # Generate daily labs
            for day in range(0, days_in_icu):
                measurement_time = visit_start + datetime.timedelta(days=day, hours=6)  # Morning labs
                
                for concept_id, name, min_val, max_val, unit_concept in lab_tests:
                    if concept_id == 0:
                        continue
                    
                    value = random.uniform(min_val, max_val)
                    
                    measurements.append((
                        measurement_id,
                        person_id,
                        concept_id,
                        measurement_time.date(),
                        measurement_time,
                        None,
                        32817,  # EHR
                        None,
                        round(value, 2),
                        0,
                        unit_concept,
                        None,
                        None,
                        None,
                        visit_id,
                        None,
                        name,
                        0,
                        None,
                        None,
                    ))
                    measurement_id += 1
                    
                    if len(measurements) >= 5000:
                        self._insert_measurements_batch(measurements)
                        measurements = []
        
        if measurements:
            self._insert_measurements_batch(measurements)
        
        print(f"   ✓ Created laboratory results")
    
    def generate_ventilation_parameters(self, visits: List):
        """Generate MEASUREMENT - Mechanical ventilation parameters (hourly for ventilated patients)."""
        print("\n6. Generating ventilation parameters...")
        
        # Ventilation concepts (LOINC + SNOMED)
        vent_params = [
            (self.search_concept('FiO2', 'Measurement'), 'FiO2', 21, 100, 8554),  # %
            (self.search_concept('PEEP', 'Measurement'), 'PEEP', 5, 15, 8876),  # cmH2O
            (self.search_concept('tidal volume', 'Measurement'), 'Tidal Volume', 300, 600, 8587),  # mL
            (self.search_concept('peak pressure', 'Measurement'), 'Peak Pressure', 15, 35, 8876),  # cmH2O
            (self.search_concept('plateau pressure', 'Measurement'), 'Plateau Pressure', 15, 30, 8876),  # cmH2O
        ]
        
        measurements = []
        measurement_id = self._get_max_measurement_id() + 1
        
        # 60% of patients are mechanically ventilated
        ventilated_visits = random.sample(visits, k=int(len(visits) * 0.6))
        
        for visit in ventilated_visits:
            visit_id = visit[0]
            person_id = visit[1]
            visit_start = visit[4]
            visit_end = visit[6]
            
            hours_ventilated = int((visit_end - visit_start).total_seconds() / 3600)
            
            # Generate hourly ventilation parameters
            for hour in range(0, hours_ventilated, 1):
                measurement_time = visit_start + datetime.timedelta(hours=hour)
                
                for concept_id, name, min_val, max_val, unit_concept in vent_params:
                    if concept_id == 0:
                        continue
                    
                    value = random.uniform(min_val, max_val)
                    
                    measurements.append((
                        measurement_id,
                        person_id,
                        concept_id,
                        measurement_time.date(),
                        measurement_time,
                        None,
                        32817,
                        None,
                        round(value, 2),
                        0,
                        unit_concept,
                        None,
                        None,
                        None,
                        visit_id,
                        None,
                        name,
                        0,
                        None,
                        None,
                    ))
                    measurement_id += 1
                    
                    if len(measurements) >= 10000:
                        self._insert_measurements_batch(measurements)
                        measurements = []
        
        if measurements:
            self._insert_measurements_batch(measurements)
        
        print(f"   ✓ Created ventilation parameters for {len(ventilated_visits)} ventilated patients")
    
    def generate_medications(self, visits: List):
        """Generate DRUG_EXPOSURE - ICU medications."""
        print("\n7. Generating ICU medications...")
        
        # Common ICU drugs (RxNorm concepts)
        icu_drugs = [
            (self.search_concept('propofol', 'Drug'), 'Propofol', 0.7),  # Sedative
            (self.search_concept('fentanyl', 'Drug'), 'Fentanyl', 0.6),  # Analgesic
            (self.search_concept('norepinephrine', 'Drug'), 'Norepinephrine', 0.4),  # Vasopressor
            (self.search_concept('midazolam', 'Drug'), 'Midazolam', 0.5),  # Sedative
            (self.search_concept('vancomycin', 'Drug'), 'Vancomycin', 0.4),  # Antibiotic
            (self.search_concept('piperacillin', 'Drug'), 'Piperacillin-Tazobactam', 0.35),  # Antibiotic
        ]
        
        drug_exposures = []
        drug_exposure_id = 1
        
        for visit in visits:
            visit_id = visit[0]
            person_id = visit[1]
            visit_start = visit[4]
            visit_end = visit[6]
            
            for concept_id, name, probability in icu_drugs:
                if concept_id == 0 or random.random() > probability:
                    continue
                
                # Drug given for portion of ICU stay
                drug_start = visit_start + datetime.timedelta(hours=random.randint(0, 12))
                duration_hours = random.randint(24, int((visit_end - visit_start).total_seconds() / 3600))
                drug_end = drug_start + datetime.timedelta(hours=duration_hours)
                drug_end = min(drug_end, visit_end)
                
                drug_exposures.append((
                    drug_exposure_id,  # drug_exposure_id
                    person_id,  # person_id
                    concept_id,  # drug_concept_id
                    drug_start.date(),  # drug_exposure_start_date
                    drug_start,  # drug_exposure_start_datetime
                    drug_end.date(),  # drug_exposure_end_date
                    drug_end,  # drug_exposure_end_datetime
                    None,  # verbatim_end_date
                    32817,  # drug_type_concept_id (EHR)
                    None,  # stop_reason
                    None,  # refills
                    None,  # quantity
                    None,  # days_supply
                    None,  # sig
                    None,  # route_concept_id
                    None,  # lot_number
                    None,  # provider_id
                    visit_id,  # visit_occurrence_id
                    None,  # visit_detail_id
                    name,  # drug_source_value
                    0,  # drug_source_concept_id
                    None,  # route_source_value
                    None,  # dose_unit_source_value
                ))
                drug_exposure_id += 1
        
        insert_query = """
            INSERT INTO cdm.drug_exposure (
                drug_exposure_id, person_id, drug_concept_id, drug_exposure_start_date,
                drug_exposure_start_datetime, drug_exposure_end_date, drug_exposure_end_datetime,
                verbatim_end_date, drug_type_concept_id, stop_reason, refills, quantity,
                days_supply, sig, route_concept_id, lot_number, provider_id,
                visit_occurrence_id, visit_detail_id, drug_source_value, drug_source_concept_id,
                route_source_value, dose_unit_source_value
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        """
        self.cursor.executemany(insert_query, drug_exposures)
        self.conn.commit()
        print(f"   ✓ Created {len(drug_exposures)} drug exposure records")
    
    def generate_procedures(self, visits: List):
        """Generate PROCEDURE_OCCURRENCE - ICU procedures."""
        print("\n8. Generating ICU procedures...")
        
        # ICU procedures (SNOMED)
        icu_procedures = [
            (self.search_concept('intubation', 'Procedure'), 'Endotracheal Intubation', 0.6),
            (self.search_concept('mechanical ventilation', 'Procedure'), 'Mechanical Ventilation', 0.6),
            (self.search_concept('central venous catheter', 'Procedure'), 'Central Line Placement', 0.5),
            (self.search_concept('arterial catheter', 'Procedure'), 'Arterial Line Placement', 0.4),
        ]
        
        procedures = []
        procedure_id = 1
        
        for visit in visits:
            visit_id = visit[0]
            person_id = visit[1]
            visit_start = visit[3]
            
            for concept_id, name, probability in icu_procedures:
                if concept_id == 0 or random.random() > probability:
                    continue
                
                procedure_date = visit_start + datetime.timedelta(hours=random.randint(0, 24))
                
                procedures.append((
                    procedure_id,  # procedure_occurrence_id
                    person_id,  # person_id
                    concept_id,  # procedure_concept_id
                    procedure_date,  # procedure_date
                    procedure_date,  # procedure_datetime
                    32817,  # procedure_type_concept_id (EHR)
                    None,  # modifier_concept_id
                    None,  # quantity
                    None,  # provider_id
                    visit_id,  # visit_occurrence_id
                    None,  # visit_detail_id
                    name,  # procedure_source_value
                    0,  # procedure_source_concept_id
                    None,  # modifier_source_value
                ))
                procedure_id += 1
        
        insert_query = """
            INSERT INTO cdm.procedure_occurrence (
                procedure_occurrence_id, person_id, procedure_concept_id, procedure_date,
                procedure_datetime, procedure_type_concept_id, modifier_concept_id, quantity,
                provider_id, visit_occurrence_id, visit_detail_id, procedure_source_value,
                procedure_source_concept_id, modifier_source_value
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        """
        self.cursor.executemany(insert_query, procedures)
        self.conn.commit()
        print(f"   ✓ Created {len(procedures)} procedure records")
    
    def _insert_measurements_batch(self, measurements):
        """Helper to insert measurement batches."""
        insert_query = """
            INSERT INTO cdm.measurement (
                measurement_id, person_id, measurement_concept_id, measurement_date,
                measurement_datetime, measurement_time, measurement_type_concept_id,
                operator_concept_id, value_as_number, value_as_concept_id, unit_concept_id,
                range_low, range_high, provider_id, visit_occurrence_id, visit_detail_id,
                measurement_source_value, measurement_source_concept_id, unit_source_value,
                value_source_value
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        """
        self.cursor.executemany(insert_query, measurements)
        self.conn.commit()
    
    def _get_max_measurement_id(self) -> int:
        """Get current max measurement_id."""
        self.cursor.execute("SELECT COALESCE(MAX(measurement_id), 0) FROM cdm.measurement")
        return self.cursor.fetchone()[0]
    
    def verify_data(self):
        """Generate verification report."""
        print("\n" + "="*60)
        print("DATA GENERATION VERIFICATION REPORT")
        print("="*60)
        
        tables = [
            ('person', 'patient demographics'),
            ('visit_occurrence', 'ICU admissions'),
            ('condition_occurrence', 'diagnoses'),
            ('measurement', 'vital signs + labs + ventilation'),
            ('drug_exposure', 'medications'),
            ('procedure_occurrence', 'procedures'),
        ]
        
        for table, description in tables:
            self.cursor.execute(f"SELECT COUNT(*) FROM cdm.{table}")
            count = self.cursor.fetchone()[0]
            print(f"{table:25s} {count:>10,} rows  ({description})")
        
        print("\n" + "="*60)
        print("MEASUREMENT BREAKDOWN")
        print("="*60)
        
        self.cursor.execute("""
            SELECT 
                c.concept_name,
                c.domain_id,
                COUNT(*) as measurement_count
            FROM cdm.measurement m
            JOIN vocab.concept c ON m.measurement_concept_id = c.concept_id
            GROUP BY c.concept_name, c.domain_id
            ORDER BY measurement_count DESC
            LIMIT 15
        """)
        
        for name, domain, count in self.cursor.fetchall():
            print(f"{name:40s} {count:>10,}")
        
        print("\n" + "="*60)
        print("SAMPLE PATIENT DATA")
        print("="*60)
        
        self.cursor.execute("""
            SELECT 
                p.person_id,
                EXTRACT(YEAR FROM CURRENT_DATE) - p.year_of_birth as age,
                g.concept_name as gender,
                v.visit_start_date,
                v.visit_end_date,
                v.visit_end_date - v.visit_start_date as los_days
            FROM cdm.person p
            JOIN cdm.visit_occurrence v ON p.person_id = v.person_id
            JOIN vocab.concept g ON p.gender_concept_id = g.concept_id
            LIMIT 5
        """)
        
        for person_id, age, gender, start, end, los in self.cursor.fetchall():
            print(f"Patient {person_id}: {age}y {gender}, ICU {start} to {end} ({los} days)")
        
        print("\n" + "="*60)
    
    def close(self):
        """Close database connection."""
        self.cursor.close()
        self.conn.close()


def main():
    """Main execution function."""
    print("="*60)
    print("INDICATE SPE: ICU Dummy Data Generator")
    print("="*60)
    print("Configuration:")
    print("  • Patients: 100")
    print("  • Domains: Ventilation, Laboratory, Vital Signs, Medications")
    print("  • OMOP CDM: v5.4")
    print("="*60)
    
    try:
        generator = ICUDataGenerator(DB_CONFIG)

        # Clear existing data before generating new data
        generator.clear_existing_data()

        # Generate data
        generator.generate_persons(n_patients=100)
        visits = generator.generate_icu_visits(n_patients=100)
        generator.generate_conditions(visits)
        generator.generate_vital_signs(visits)
        generator.generate_laboratory_results(visits)
        generator.generate_ventilation_parameters(visits)
        generator.generate_medications(visits)
        generator.generate_procedures(visits)
        
        # Verify
        generator.verify_data()
        
        generator.close()
        
        print("\n" + "="*60)
        print("✓ DATA GENERATION COMPLETE!")
        print("="*60)
        print("\nNext steps:")
        print("  1. Review data quality in PostgreSQL")
        print("  2. Deploy Broadsea WebAPI/Atlas for visualization")
        print("  3. Test federated analytics queries")
        print("")
        
    except Exception as e:
        print(f"\n ERROR: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()
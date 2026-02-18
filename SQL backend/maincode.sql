CREATE TABLE owner (
    owner_id SERIAL PRIMARY KEY,
    owner_first_name VARCHAR(50) NOT NULL,
    owner_last_name VARCHAR(100) NOT NULL,
    owner_email VARCHAR(100) UNIQUE NOT NULL,
    owner_phone_number VARCHAR(15) UNIQUE NOT NULL,
    owner_address1 VARCHAR(100) NOT NULL,
    owner_address2 VARCHAR(100),
    owner_postcode VARCHAR(10) NOT NULL,
    owner_city VARCHAR(30) NOT NULL DEFAULT 'London'
);
--fast login lookup--
CREATE UNIQUE INDEX idx_owner_email_unique ON owner(owner_email); 
CREATE INDEX idx_owner_phone ON owner(owner_phone_number); 
CREATE INDEX idx_owner_full_name ON owner(owner_first_name, owner_last_name);

CREATE TYPE species_type AS ENUM ('Dog', 'Cat', 'Rabbit', 'Hamster', 'Bird', 'Reptile');

CREATE TABLE species_config (
    species_id SERIAL PRIMARY KEY,
    species_name species_type NOT NULL,
    breed_name VARCHAR(20) NOT NULL,
    notes TEXT NOT NULL
);

--Quick lookup for species name--
CREATE INDEX idx_species_config_species_name ON species_config(species_name);

CREATE TABLE pet (
    pet_id SERIAL PRIMARY KEY,
    species_id INT NOT NULL,
    owner_id INT NOT NULL,
    pet_first_name VARCHAR(50) NOT NULL,
    pet_last_name VARCHAR(50),
    pet_address1 VARCHAR(100) NOT NULL,
    pet_address2 VARCHAR(100),
    pet_postcode VARCHAR(10) NOT NULL,
    pet_city VARCHAR(30) NOT NULL,
    FOREIGN KEY (owner_id) REFERENCES owner(owner_id),
    FOREIGN KEY (species_id) REFERENCES species_config(species_id)
);

-- Foreign key lookups--
CREATE INDEX idx_pet_user_id ON pet(owner_id); 
CREATE INDEX idx_pet_species_id ON pet(species_id);
--Name search--
CREATE INDEX idx_pet_first_name ON pet(pet_first_name);

CREATE TABLE owner_pet (
    owner_id INT NOT NULL,
    pet_id INT NOT NULL,
    PRIMARY KEY (owner_id, pet_id),
    FOREIGN KEY (owner_id) REFERENCES owner(owner_id),
    FOREIGN KEY (pet_id) REFERENCES pet(pet_id) 
);

--Fetch pets for a user--
CREATE INDEX idx_owner_pet_user_pet ON owner_pet(owner_id, pet_id); 
-- Fetch users for a pet 
CREATE INDEX idx_owner_pet_pet_user ON owner_pet(pet_id, owner_id);

-- ENUM creation to indicate whether a pet is spayed/neutered or not, 
-- with an option for N/A for cases where this information is not applicable or unknown.
CREATE TYPE spay_neutered_status AS ENUM ('Yes', 'No', 'N/A');

CREATE TABLE medical_detail (
    medical_detail_id SERIAL PRIMARY KEY,
    pet_id INT NOT NULL,
    blood_type VARCHAR(20),
    medical_notes TEXT,
    current_medication TEXT,
    allergies TEXT,
    microchip_id VARCHAR(15)UNIQUE,
    spay_neutered spay_neutered_status NOT NULL DEFAULT 'N/A',
    FOREIGN KEY (pet_id) REFERENCES pet(pet_id)
);

CREATE INDEX idx_medical_detail_pet_id ON medical_detail(pet_id);

-- ENUM creation for a pet's appointment status e.g. scheduled, completed, cancelled, etc.
CREATE TYPE appointment_status AS ENUM ('Scheduled', 'Completed', 'Cancelled');

CREATE TYPE appointment_reminder_frequency AS ENUM ('once','daily','weekly','none');

CREATE TABLE pet_appointment (
    pet_appointment_id SERIAL PRIMARY KEY,
    pet_id INT NOT NULL,
    enable_reminder BOOLEAN NOT NULL DEFAULT TRUE,
    reminder_frequency appointment_reminder_frequency NOT NULL DEFAULT 'daily',
    pet_appointment_date DATE NOT NULL,
    pet_appointment_time TIME NOT NULL,
    appointment_status appointment_status NOT NULL DEFAULT 'Scheduled',
    FOREIGN KEY (pet_id) REFERENCES pet(pet_id)
);

-- Appointments for a pet sorted by date/time-- 
CREATE INDEX idx_pet_appointment_pet_date ON pet_appointment(pet_id, pet_appointment_date);
CREATE INDEX idx_pet_appointment_time ON pet_appointment(pet_appointment_time);

CREATE TABLE feeding_schedule (
    feeding_schedule_id SERIAL PRIMARY KEY,
    pet_id INT NOT NULL,
    feeding_schedule_start DATE NOT NULL,
    feeding_schedule_end DATE NULL,
    feeding_time TIME NOT NULL,
    portion_size INT NOT NULL,
    food_name VARCHAR(100),
    FOREIGN KEY (pet_id) REFERENCES pet(pet_id)
);

CREATE INDEX idx_feeding_schedule_pet_id ON feeding_schedule(pet_id); 
-- Looking up active schedules--
CREATE INDEX idx_feeding_schedule_start ON feeding_schedule(feeding_schedule_start); 
CREATE INDEX idx_feeding_schedule_end ON feeding_schedule(feeding_schedule_end); 
-- Combined lookup-- 
CREATE INDEX idx_feeding_schedule_pet_start ON feeding_schedule(pet_id, feeding_schedule_start);

-- ENUM creation for the reminders e.g. vet appointment, feeding time, medication time, etc.
CREATE TYPE reminder_status AS ENUM ('Pending', 'Sent', 'Dismissed', 'Missed', 'Cancelled');

CREATE TABLE reminder (
    reminder_id SERIAL PRIMARY KEY,
    pet_appointment_id INT,
    feeding_schedule_id INT,
    reminder_date DATE NOT NULL,
    reminder_time TIME NOT NULL,
    reminder_status reminder_status NOT NULL DEFAULT 'Pending',
    reminder_notes TEXT NULL,
    FOREIGN KEY (pet_appointment_id) REFERENCES pet_appointment(pet_appointment_id),
    FOREIGN KEY (feeding_schedule_id) REFERENCES feeding_schedule(feeding_schedule_id)
);

--CREATE INDEX idx_reminder_pet_id ON reminder(pet_id); 
CREATE INDEX idx_reminder_feeding_schedule_id ON reminder(feeding_schedule_id); 
-- Time-based reminders 
CREATE INDEX idx_reminder_time ON reminder(reminder_time); 
-- Upcoming reminder for a pet 
--CREATE INDEX idx_reminder_pet_time ON reminder(pet_id, reminder_time);

-- ENUM creation for the frequency of the pet report e.g. daily, weekly, monthly, one-time, etc.
CREATE TYPE report_type AS ENUM ('Daily', 'Weekly', 'Monthly', 'One-time');

CREATE TABLE pet_report (
    report_id SERIAL PRIMARY KEY,
    pet_id INT NOT NULL,
    report_date TIMESTAMP NOT NULL,
    report_type report_type NOT NULL DEFAULT 'One-time',
    risk_flag BOOLEAN NOT NULL,
    notes TEXT NOT NULL,
    FOREIGN KEY (pet_id) REFERENCES pet(pet_id)
);

CREATE INDEX idx_pet_report_pet_id ON pet_report(pet_id); 
CREATE INDEX idx_pet_report_date ON pet_report(report_date); 
-- looking up flagged risks
CREATE INDEX idx_pet_report_risk_flag ON pet_report(risk_flag);

CREATE TABLE metadata (
    meta_data_id SERIAL PRIMARY KEY,
    pet_id INT NOT NULL,
    notes TEXT NOT NULL,
    FOREIGN KEY (pet_id) REFERENCES pet(pet_id)
);

--Foreign key index--
CREATE INDEX idx_metadata_pet_id ON metadata(pet_id);

CREATE TYPE metric_name AS ENUM ('weight', 'stool_quality', 'energy_level', 'appetite', 'water_intake', 'litter_box_usage',
'grooming_frequency', 'vomit_events', 'feather_condition', 'wing_strength', 'perch_activity',
'vocalisation_level', 'basking_time', 'shedding_quality', 'humidity_level', 'stool_pellets', 'chewing_behaviour', 'wheel_activity', 'custom');

CREATE TYPE metric_unit AS ENUM ( 'kg', 'grams', 'ml', 'scale_1_5',
'count_day', 'minutes_day', 'percent', 'text', 'custom' );

CREATE TABLE metric_definition (
    metric_def_id SERIAL PRIMARY KEY,
    species_id INT NOT NULL,
    metric_name metric_name NOT NULL,
    metric_unit metric_unit NOT NULL,       
    notes TEXT NULL,
    FOREIGN KEY (species_id) REFERENCES species_config(species_id)
);

CREATE INDEX idx_metric_definition_species_id ON metric_definition(species_id); 
CREATE INDEX idx_metric_definition_metric_name ON metric_definition(metric_name);

CREATE TABLE health_metric (
    health_metric_id SERIAL PRIMARY KEY,
    metric_def_id INT NOT NULL,
    pet_id INT NOT NULL,
    metric_value DECIMAL,
    metric_time TIMESTAMP NOT NULL,
    notes TEXT NULL,
    FOREIGN KEY (metric_def_id) REFERENCES metric_definition(metric_def_id),
    FOREIGN KEY (pet_id) REFERENCES pet(pet_id)
);

-- Foreign keys--
CREATE INDEX idx_health_metric_pet_id ON health_metric(pet_id); 
CREATE INDEX idx_health_metric_metric_def_id ON health_metric(metric_def_id); 
-- Time-series queries 
CREATE INDEX idx_health_metric_time ON health_metric(metric_time); 
-- Specified time-- 
CREATE INDEX idx_health_metric_pet_metric_time ON health_metric(pet_id, metric_def_id, metric_time);
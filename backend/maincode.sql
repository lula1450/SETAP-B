

CREATE TABLE user (
    user_id SERIAL PRIMARY KEY,
    user_first_name VARCHAR(50) NOT NULL,
    user_last_name VARCHAR(100) NOT NULL,
    user_email VARCHAR(100) UNIQUE NOT NULL,
    user_phone_number VARCHAR(15) UNIQUE NOT NULL,
    user_address1 VARCHAR(100) NOT NULL,
    user_address2 VARCHAR(100),
    user_postcode VARCHAR(10) NOT NULL,
    user_city VARCHAR(30) NOT NULL DEFAULT 'London'
);

CREATE TABLE pet (
    pet_id SERIAL PRIMARY KEY,
    species_id INT NOT NULL
    user_id INT NOT NULL,
    pet_first_name VARCHAR(50) NOT NULL,
    pet_last_name VARCHAR(50),
    pet_address1 VARCHAR(100) NOT NULL,
    pet_address2 VARCHAR(100),
    pet_postcode VARCHAR(10) NOT NULL,
    pet_city VARCHAR(30) NOT NULL,
    FOREIGN KEY (user_id) REFERENCES user(user_id),
    FOREIGN KEY (species_id) REFERENCES species(species_id)
);

CREATE TABLE user_pet (
    user_id INT NOT NULL,
    pet_id INT NOT NULL,
    PRIMARY KEY (user_id, pet_id),
    FOREIGN KEY (user_id) REFERENCES user(user_id),
    FOREIGN KEY (pet_id) REFERENCES pet(pet_id) 
);

CREATE TYPE spay_neutered_status AS ENUM ('Yes', 'No', 'N/A');

CREATE TABLE medical_detail (
    medical_detail_id SERIAL PRIMARY KEY,
    pet_id INT NOT NULL,
    blood_type VARCHAR(20),
    medical_notes TEXT,
    current_medication TEXT,
    allergies TEXT,
    microchip_id VARCHAR(15),
    spay_neutered spay_neutered_status NOT NULL DEFAULT 'N/A',
);

CREATE TYPE appointment_status AS ENUM ('Scheduled', 'Completed', 'Cancelled');

CREATE TABLE pet_appointment (
    pet_appointment_id SERIAL PRIMARY KEY,
    pet_id INT NOT NULL,
    pet_appointment_date DATE NOT NULL,
    pet_appointment_time TIME NOT NULL,
    appointment_status appointment_status NOT NULL DEFAULT 'Scheduled',
    FOREIGN KEY (pet_id) REFERENCES pet(pet_id)
);

CREATE TABLE feeding_schedule (
    feeding_schedule_id SERIAL PRIMARY KEY,
    pet_id INT NOT NULL,
    fschedule_start DATE NOT NULL,
    fschedule_end DATE NULL,
    feed_time TIME NOT NULL,
    portion_size INT NOT NULL,
    food_name VARCHAR(100),
    FOREIGN KEY (pet_id) REFERENCES pet(pet_id)
);

CREATE TYPE reminder_status AS ENUM ('Pending', 'Sent', 'Dismissed', 'Missed', 'Cancelled');

CREATE TABLE reminder (
    reminder_id SERIAL PRIMARY KEY,
    pet_appointment_id INT NOT NULL,
    feeding_schedule_id INT NOT NULL,
    reminder_date DATE NOT NULL,
    reminder_time TIME NOT NULL,
    reminder_status reminder_status NOT NULL DEFAULT 'Pending',
    reminder_notes TEXT NULL,
    FOREIGN KEY (pet_appointment_id) REFERENCES pet_appointment(pet_appointment_id),
    FOREIGN KEY (feeding_schedule_id) REFERENCES feeding_schedule(feeding_schedule_id)
);

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

CREATE TABLE metadata (
    meta_data_id SERIAL PRIMARY KEY,
    pet_id INT NOT NULL,
    notes TEXT NOT NULL,
    FOREIGN KEY (pet_id) REFERENCES pet(pet_id)
);

CREATE TABLE species_config (
    species_id SERIAL PRIMARY KEY,
    species_name VARCHAR(20) NOT NULL,
    breed_name VARCHAR(20) NOT NULL,
    notes TEXT NOT NULL
);

CREATE TABLE metric_definition (
    metric_def_id SERIAL PRIMARY KEY,
    species_id INT NOT NULL,
    metric_name              ,
    metric_unit           ,
    notes TEXT NULL,
);

CREATE TABLE health_metric (
    health_metric_id SERIAL PRIMARY KEY,
    metric_def_id INT NOT NULL,
    pet_id INT NOT NULL,
    metric_value DECIMAL,
    metric_time TIMESTAMP NOT NULL,
    notes TEXT NULL
)
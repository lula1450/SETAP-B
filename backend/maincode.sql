

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

INSERT INTO user (user_first_name, user_last_name, user_email, user_phone_number, user_address1, user_address2, user_postcode, user_city)
VALUES
('Sarah', 'Williams', 'sarah.williams@example.com', '07123456789', '12 Rose Street', NULL, 'SW1A1AA', 'London'),
('James', 'Turner', 'james.turner@example.com', '07234567890', '44 Oak Avenue', 'Flat 2B', 'E16AB', 'London'),
('Aisha', 'Khan', 'aisha.khan@example.com', '07345678901', '89 Marine Road', NULL, 'PO12EF', 'Portsmouth'),
('Michael', 'Brown', 'michael.brown@example.com', '07456789012', '7 Kingfisher Close', NULL, 'BN11CD', 'Brighton'),
('Emily', 'Clark', 'emily.clark@example.com', '07567890123', '101 Maple Drive', 'Apt 5', 'SE15GH', 'London');

CREATE TABLE user_pet (
    user_id INT NOT NULL,
    pet_id INT NOT NULL,
    PRIMARY KEY (user_id, pet_id),
    FOREIGN KEY (user_id) REFERENCES user(user_id),
    FOREIGN KEY (pet_id) REFERENCES pet(pet_id) 
);

INSERT INTO user_pet (user_id, pet_id) VALUES
(1, 1),   
(1, 2),   
(2, 3),   
(3, 4),   
(4, 5);  

CREATE TABLE pet (
    pet_id SERIAL PRIMARY KEY,
    species_id INT NOT NULL
    user_id INT NOT NULL,
    pet_first_name VARCHAR(50) NOT NULL,
    pet_last_name VARCHAR(50),
    pet_address1 VARCHAR(100) NOT NULL,
    pet_address2 VARCHAR(100),
    pet_postcode VARCHAR(10) NOT NULL,
    pet_city VARCHAR(30) NOT NULL
);




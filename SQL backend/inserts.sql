---OWNER INSERTS---
INSERT INTO owner (
    owner_first_name, owner_last_name, owner_email, owner_phone_number,
    owner_address1, owner_address2, owner_postcode, owner_city
) VALUES
('Alice', 'Johnson', 'alice.j@example.com', '07111111111', '12 River St', NULL, 'PO1 1AA', 'Portsmouth'),
('Mark', 'Turner', 'mark.t@example.com', '07222222222', '44 Hill Road', 'Flat 2', 'PO2 2BB', 'Sheffield'),
('Sarah', 'Coleman', 's.coleman@example.com', '07333333333', '8 Oak Lane', NULL, 'PO3 3CC', 'Portsmouth'),
('David', 'Reed', 'd.reed@example.com', '07444444444', '19 Pine Close', NULL, 'PO4 4DD', 'London'),
('Emma', 'Wells', 'emma.w@example.com', '07555555555', '77 Marine Drive', NULL, 'PO5 5EE', 'Portsmouth'),
('Tom', 'Baker', 'tom.b@example.com', '07666666666', '3 Meadow View', NULL, 'PO6 6FF', 'York'),
('Lucy', 'Adams', 'lucy.a@example.com', '07777777777', '22 Brookside', NULL, 'PO7 7GG', 'Portsmouth'),
('James', 'Frost', 'j.frost@example.com', '07888888888', '10 Elm Street', NULL, 'PO8 8HH', 'Newcastle'),
('Hannah', 'Green', 'h.green@example.com', '07999999999', '5 Willow Way', NULL, 'PO9 9JJ', 'Bournemouth'),
('Oliver', 'Knight', 'o.knight@example.com', '07000000000', '90 Harbour Road', NULL, 'PO10 0KK', 'Southampton');

---SPECIES INSERTS---
INSERT INTO species_config (species_name, breed_name, notes) VALUES
('Dog', 'Labrador', 'Friendly and energetic'),
('Dog', 'Beagle', 'Curious and active'),
('Cat', 'British Shorthair', 'Calm temperament'),
('Bird', 'Cockatiel', 'Social and vocal'),
('Hamster', 'Syrian', 'Nocturnal and solitary');

---PET INSERTS---
INSERT INTO pet (
    species_id, owner_id, pet_first_name, pet_last_name,
    pet_address1, pet_address2, pet_postcode, pet_city
) VALUES
(1, 1, 'Buddy', NULL, '12 River St', NULL, 'PO1 1AA', 'Portsmouth'),
(3, 1, 'Mittens', NULL, '12 River St', NULL, 'PO1 1AA', 'Portsmouth'),
(2, 2, 'Scout', NULL, '44 Hill Road', 'Flat 2', 'PO2 2BB', 'Portsmouth'),
(1, 3, 'Rex', NULL, '8 Oak Lane', NULL, 'PO3 3CC', 'Portsmouth'),
(4, 3, 'Sunny', NULL, '8 Oak Lane', NULL, 'PO3 3CC', 'Portsmouth'),
(5, 4, 'Nibbles', NULL, '19 Pine Close', NULL, 'PO4 4DD', 'Portsmouth'),
(3, 5, 'Whiskers', NULL, '77 Marine Drive', NULL, 'PO5 5EE', 'Portsmouth'),
(1, 6, 'Shadow', NULL, '3 Meadow View', NULL, 'PO6 6FF', 'Portsmouth'),
(2, 6, 'Copper', NULL, '3 Meadow View', NULL, 'PO6 6FF', 'Portsmouth'),
(4, 7, 'Peaches', NULL, '22 Brookside', NULL, 'PO7 7GG', 'Portsmouth'),
(1, 8, 'Bolt', NULL, '10 Elm Street', NULL, 'PO8 8HH', 'Portsmouth'),
(3, 8, 'Snowball', NULL, '10 Elm Street', NULL, 'PO8 8HH', 'Portsmouth'),
(5, 9, 'Pip', NULL, '5 Willow Way', NULL, 'PO9 9JJ', 'Portsmouth'),
(2, 10, 'Hunter', NULL, '90 Harbour Road', NULL, 'PO10 0KK', 'Portsmouth'),
(1, 10, 'Max', NULL, '90 Harbour Road', NULL, 'PO10 0KK', 'Portsmouth');

---OWNER_PET INSERTS---
INSERT INTO owner_pet (owner_id, pet_id) VALUES
(1,1),(1,2),
(2,3),
(3,4),(3,5),
(4,6),
(5,7),
(6,8),(6,9),
(7,10),
(8,11),(8,12),
(9,13),
(10,14),(10,15);

---MEDICAL_DETAIL INSERTS---
INSERT INTO medical_detail (pet_id, blood_type, medical_notes, current_medication, allergies, microchip_id, spay_neutered)
VALUES
(1,'DEA 1.1','Healthy',NULL,'None','MC10001','Yes'),
(2,NULL,'Mild anxiety',NULL,'Fish','MC10002','No'),
(3,'A','Seasonal allergies','Antihistamine','Grass','MC10003','Yes'),
(4,NULL,'Hip check recommended',NULL,NULL,'MC10004','No'),
(5,NULL,'Wing trim needed soon',NULL,NULL,'MC10005','N/A'),
(6,NULL,'Normal','Vitamin drops',NULL,'MC10006','N/A'),
(7,NULL,'Overweight','Diet food','None','MC10007','Yes'),
(8,NULL,'High energy',NULL,NULL,'MC10008','Yes'),
(9,NULL,'Ear infection history','Ear drops','Dust','MC10009','No'),
(10,NULL,'Very vocal',NULL,NULL,'MC10010','N/A'),
(11,NULL,'Strong build',NULL,NULL,'MC10011','Yes'),
(12,NULL,'Shy temperament',NULL,NULL,'MC10012','No'),
(13,NULL,'Healthy',NULL,NULL,'MC10013','N/A'),
(14,NULL,'Active hunter',NULL,NULL,'MC10014','Yes'),
(15,NULL,'Senior dog',NULL,NULL,'MC10015','Yes');

---PET_APPOINTMENT INSERTS---
INSERT INTO pet_appointment (pet_id, pet_appointment_date, pet_appointment_time, appointment_status) VALUES
(1,'2025-03-01','10:00','Scheduled'),
(2,'2025-03-02','14:30','Scheduled'),
(3,'2025-03-03','09:00','Scheduled'),
(4,'2025-03-04','11:15','Scheduled'),
(5,'2025-03-05','13:00','Scheduled'),
(6,'2025-03-06','15:45','Scheduled'),
(7,'2025-03-07','10:30','Scheduled'),
(8,'2025-03-08','09:45','Scheduled'),
(9,'2025-03-09','16:00','Scheduled'),
(10,'2025-03-10','12:00','Scheduled'),
(11,'2025-03-11','08:30','Scheduled'),
(12,'2025-03-12','14:00','Scheduled'),
(13,'2025-03-13','10:00','Scheduled'),
(14,'2025-03-14','11:00','Scheduled'),
(15,'2025-03-15','09:00','Scheduled'),
(1,'2025-04-01','10:00','Scheduled'),
(2,'2025-04-02','14:30','Scheduled'),
(3,'2025-04-03','09:00','Scheduled'),
(4,'2025-04-04','11:15','Scheduled'),
(5,'2025-04-05','13:00','Scheduled');

---FEEDING_SCHEDULE INSERTS---
INSERT INTO feeding_schedule (
    pet_id, feeding_schedule_start, feeding_schedule_end,
    feeding_time, portion_size, food_name
) VALUES
(1,'2025-02-01',NULL,'08:00',200,'Dry Kibble'),
(2,'2025-02-01',NULL,'09:00',100,'Wet Food'),
(3,'2025-02-01',NULL,'07:30',150,'Dry Mix'),
(4,'2025-02-01',NULL,'08:15',250,'Premium Kibble'),
(5,'2025-02-01',NULL,'06:45',50,'Seed Mix'),
(6,'2025-02-01',NULL,'20:00',20,'Hamster Pellets'),
(7,'2025-02-01',NULL,'09:30',120,'Wet Food'),
(8,'2025-02-01',NULL,'08:45',220,'Dry Kibble'),
(9,'2025-02-01',NULL,'19:00',180,'Dry Mix'),
(10,'2025-02-01',NULL,'07:00',40,'Seed Mix'),
(11,'2025-02-01',NULL,'08:00',260,'Dry Kibble'),
(12,'2025-02-01',NULL,'09:00',110,'Wet Food'),
(13,'2025-02-01',NULL,'20:30',15,'Hamster Pellets'),
(14,'2025-02-01',NULL,'08:30',200,'Dry Kibble'),
(15,'2025-02-01',NULL,'07:45',230,'Dry Kibble'),
(1,'2025-03-01',NULL,'18:00',180,'Wet Food'),
(2,'2025-03-01',NULL,'18:30',90,'Wet Food'),
(3,'2025-03-01',NULL,'17:00',140,'Dry Mix'),
(4,'2025-03-01',NULL,'19:00',260,'Premium Kibble'),
(5,'2025-03-01',NULL,'06:30',45,'Seed Mix');

---REMINDER INSERTS---
INSERT INTO reminder (
    pet_appointment_id, feeding_schedule_id,
    reminder_date, reminder_time, reminder_status, reminder_notes
) VALUES
(1,1,'2025-03-01','09:45','Pending','Vet appointment soon'),
(2,2,'2025-03-02','14:00','Pending','Vet appointment soon'),
(3,3,'2025-03-03','08:45','Pending','Vet appointment soon'),
(4,4,'2025-03-04','11:00','Pending','Vet appointment soon'),
(5,5,'2025-03-05','12:45','Pending','Vet appointment soon'),
(6,6,'2025-03-06','15:30','Pending','Vet appointment soon'),
(7,7,'2025-03-07','10:15','Pending','Vet appointment soon'),
(8,8,'2025-03-08','09:30','Pending','Vet appointment soon'),
(9,9,'2025-03-09','15:45','Pending','Vet appointment soon'),
(10,10,'2025-03-10','11:45','Pending','Vet appointment soon'),
(11,11,'2025-03-11','08:15','Pending','Vet appointment soon'),
(12,12,'2025-03-12','13:45','Pending','Vet appointment soon'),
(13,13,'2025-03-13','09:45','Pending','Vet appointment soon'),
(14,14,'2025-03-14','10:45','Pending','Vet appointment soon'),
(15,15,'2025-03-15','08:45','Pending','Vet appointment soon'),
(16,16,'2025-04-01','09:45','Pending','Vet appointment soon'),
(17,17,'2025-04-02','14:00','Pending','Vet appointment soon'),
(18,18,'2025-04-03','08:45','Pending','Vet appointment soon'),
(19,19,'2025-04-04','11:00','Pending','Vet appointment soon'),
(20,20,'2025-04-05','12:45','Pending','Vet appointment soon');

---PET_REPORT INSERTS---
INSERT INTO pet_report (pet_id, report_date, report_type, risk_flag, notes) VALUES
(1,NOW(),'Daily',FALSE,'Normal activity'),
(2,NOW(),'Weekly',TRUE,'Reduced appetite'),
(3,NOW(),'Monthly',FALSE,'Stable condition'),
(4,NOW(),'Daily',FALSE,'Energetic'),
(5,NOW(),'One-time',FALSE,'Routine check'),
(6,NOW(),'Weekly',TRUE,'Low activity'),
(7,NOW(),'Daily',FALSE,'Improving weight'),
(8,NOW(),'Monthly',FALSE,'Healthy'),
(9,NOW(),'Daily',TRUE,'Ear irritation'),
(10,NOW(),'Weekly',FALSE,'Normal'),
(11,NOW(),'Daily',FALSE,'Strong build'),
(12,NOW(),'Weekly',FALSE,'Calm'),
(13,NOW(),'One-time',FALSE,'Healthy'),
(14,NOW(),'Daily',FALSE,'Active'),
(15,NOW(),'Monthly',TRUE,'Senior dog monitoring');

---METADATA INSERTS---
INSERT INTO metadata (pet_id, notes) VALUES
(1,'Adopted from shelter'),
(2,'Indoor-only'),
(3,'Sensitive stomach'),
(4,'Rescue dog'),
(5,'Very social bird'),
(6,'Sleeps during day'),
(7,'On weight-loss plan'),
(8,'High energy'),
(9,'Dust allergy'),
(10,'Very vocal'),
(11,'Strong runner'),
(12,'Shy temperament'),
(13,'Loves tunnels'),
(14,'Hunter instincts'),
(15,'Senior care needed');

---METRIC_DEFINITION INSERTS---
INSERT INTO metric_definition (species_id, metric_name, metric_unit, notes) VALUES
--dog--
(1, 'weight', 'kg', 'Standard body weight'),
(1, 'stool_quality', 'scale_1_5', 'Firmness/colour'),
(1, 'energy_level', 'scale_1_5', 'Activity level'),
(1, 'appetite', 'scale_1_5', 'Eating behaviour'),
(1, 'water_intake', 'ml', 'Optional');
--cat--
INSERT INTO metric_definition (species_id, metric_name, metric_unit, notes) VALUES
(3, 'weight', 'kg', 'Body weight'),
(3, 'litter_box_usage', 'count_day', 'Number of visits'),
(3, 'grooming_frequency', 'scale_1_5', 'Grooming habits'),
(3, 'vomit_events', 'text', 'Colour/texture'),
(3, 'appetite', 'scale_1_5', 'Eating behaviour');
--bird--
INSERT INTO metric_definition (species_id, metric_name, metric_unit, notes) VALUES
(4, 'weight', 'grams', 'Birds are light'),
(4, 'feather_condition', 'scale_1_5', 'Plucking, shine'),
(4, 'wing_strength', 'scale_1_5', 'Flight ability'),
(4, 'perch_activity', 'minutes_day', 'Movement level'),
(4, 'vocalisation_level', 'scale_1_5', 'Optional');
--hamster--
INSERT INTO metric_definition (species_id, metric_name, metric_unit, notes) VALUES
(5, 'weight', 'grams', 'Very small animals'),
(5, 'wheel_activity', 'minutes_day', 'Exercise'),
(5, 'appetite', 'scale_1_5', 'Eating'),
(5, 'grooming_frequency', 'scale_1_5', 'Cleanliness'),
(5, 'stool_quality', 'scale_1_5', 'Digestive health');
--reptile--
INSERT INTO metric_definition (species_id, metric_name, metric_unit, notes) VALUES
(6, 'weight', 'grams', 'Standard'),
(6, 'basking_time', 'minutes_day', 'Time under heat lamp'),
(6, 'shedding_quality', 'scale_1_5', 'Completeness of shed'),
(6, 'appetite', 'scale_1_5', 'Eating behaviour'),
(6, 'humidity_level', 'percent', 'Terrarium humidity');
--rabbit--
INSERT INTO metric_definition (species_id, metric_name, metric_unit, notes) VALUES
(7, 'weight', 'kg', 'Body weight'),
(7, 'stool_pellets', 'count_day', 'Digestive health'),
(7, 'chewing_behaviour', 'scale_1_5', 'Stress indicator'),
(7, 'water_intake', 'ml', 'Hydration'),
(7, 'energy_level', 'scale_1_5', 'Activity level');

---HEALTH_METRIC INSERTS---
INSERT INTO health_metric (metric_def_id, pet_id, metric_value, metric_time, notes) VALUES
(1,1,30.5,NOW(),'Healthy weight'),
(2,1,4,NOW(),'Good appetite'),
(3,3,12.0,NOW(),'Normal weight'),
(4,2,3,NOW(),'Soft stool'),
(5,5,4,NOW(),'Strong wings'),
(6,6,45,NOW(),'Active night'),
(7,4,5,NOW(),'High energy'),
(8,7,3,NOW(),'Normal grooming'),
(9,10,4,NOW(),'Very vocal'),
(10,13,6,NOW(),'Chewing a lot'),
(1,11,28.0,NOW(),'Healthy'),
(2,11,5,NOW(),'Strong appetite'),
(3,14,14.0,NOW(),'Healthy'),
(4,10,2,NOW(),'Quiet today'),
(5,5,5,NOW(),'Excellent wings'),
(6,13,50,NOW(),'Very active'),
(7,8,4,NOW(),'Good energy'),
(8,12,2,NOW(),'Low grooming'),
(9,10,5,NOW(),'Very vocal'),
(10,6,4,NOW(),'Normal chewing');
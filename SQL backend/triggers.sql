---TRIGGER1---
---Set appointment to 'completed' when updated after its time or date.---
CREATE OR REPLACE FUNCTION auto_complete_appointment()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.pet_appointment_status = 'Scheduled'
        AND (NEW.pet_appointment_date < CURRENT_DATE
            OR (NEW.pet_appointment_date = CURRENT_DATE
                AND NEW.pet_appointment_time < CURRENT_TIME
            )
        )
    THEN 
        NEW.appointment_status := 'Completed';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_auto_complete_appointment
BEFORE UPDATE ON pet_appointment
FOR EACH ROW
EXECUTE FUNCTION auto_complete_appointment();

---TRIGGER2---
---After a reminder is sent it is updated to sent---
CREATE OR REPLACE FUNCTION auto_update_reminder_status()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.reminder_status = 'Pending'
        AND (NEW.reminder_date < CURRENT_DATE
            OR (NEW.reminder_date = CURRENT_DATE
                AND NEW.reminder_time <= CURRENT_TIME
            )
        )
    THEN
        NEW.reminder_status := 'Sent';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_auto_update_reminder_status
BEFORE UPDATE ON reminder
FOR EACH ROW
EXECUTE FUNCTION auto_update_reminder_status();

---TRIGGER 3---
---CREATE Feeding reminder for the next day---
CREATE OR REPLACE FUNCTION create_next_feeding_reminder()
RETURNS TRIGGER AS $$
DECLARE
    schedule_end DATE;
    next_date DATE;

BEGIN
---Only act when status changes TO 'Sent'---
    IF NEW.reminder_status = 'Sent'
       AND OLD.reminder_status IS DISTINCT FROM 'Sent'
       AND NEW.feeding_schedule_id IS NOT NULL
    THEN
---Fetch the feeding schedule end date---
        SELECT feeding_schedule_end
        INTO schedule_end
        FROM feeding_schedule
        WHERE feeding_schedule_id = NEW.feeding_schedule_id;

    next_date := NEW.reminder_date + 1;

---Only create next reminder if schedule is still active---
        IF (schedule_end IS NULL OR next_date <= schedule_end)
            AND next_date >= CURRENT_DATE
        THEN
            INSERT INTO reminder (
                pet_appointment_id,
                feeding_schedule_id,
                reminder_date,
                reminder_time,
                reminder_status
            )
            VALUES (
                NULL,
                NEW.feeding_schedule_id,
                next_date,
                NEW.reminder_time,
                'Pending'
            );
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_create_next_feeding_reminder
AFTER UPDATE ON reminder
FOR EACH ROW
EXECUTE FUNCTION create_next_feeding_reminder();

---TRIGGER4---
---Creates appointmnet reminders daily or weekly---
CREATE OR REPLACE FUNCTION create_initial_appointment_reminder()
RETURNS TRIGGER AS $$
DECLARE
    first_date DATE;
BEGIN
---If reminders disabled or frequency = none, do nothing---
    IF NEW.enable_reminder = FALSE OR NEW.reminder_frequency = 'none' THEN
        RETURN NEW;
    END IF;

--- Determine first reminder date---
    IF NEW.reminder_frequency = 'daily' THEN
        first_date := NEW.pet_appointment_date - INTERVAL '1 day';

    ELSIF NEW.reminder_frequency = 'weekly' THEN
        first_date := NEW.pet_appointment_date - INTERVAL '7 days';

    ELSE
        first_date := NEW.pet_appointment_date;
    END IF;

---Create the first reminder---
    INSERT INTO reminder (
        pet_appointment_id,
        feeding_schedule_id,
        reminder_date,
        reminder_time,
        reminder_status
    )
    VALUES (
        NEW.pet_appointment_id,
        NULL,
        first_date,
        NEW.pet_appointment_time,
        'Pending'
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_create_ititial_appointmnet_reminder
AFTER INSERT ON pet_appointment
FOR EACH ROW
EXECUTE FUNCTION create_initial_appointment_reminder();



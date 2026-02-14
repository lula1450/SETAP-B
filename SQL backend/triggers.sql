---Set appointment to 'completed' when updated after its time or date.---
CREATE OR REPLACE FUNCTION auto_complete_appointment()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.pet_appointment_date < CURRENT_DATE
        OR (NEW.pet_appointment_date = CURRENT_DATE
            AND NEW.pet_appointment_time < CURRENT_TIME)

    THEN 
        NEW.appointment_status := 'Completed';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_auto_complete_appointment
BEFORE UPDATE ON pet_appointment
FOR EACH ROW
EXECUTE FUNCTION auto_complete_appointment();

---After a reminder is sent it is updated to sent---
CREATE OR REPLACE FUNCTION auto_update_reminder_status()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.reminder_date < CURRENT_DATE
       OR (NEW.reminder_date = CURRENT_DATE
           AND NEW.reminder_time < CURRENT_TIME)
    THEN
        NEW.reminder_status := 'Sent';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_auto_update_reminder_status
BEFORE UPDATE ON reminder
FOR EACH ROW
EXECUTE FUNCTION auto_update_reminder_status();

---When reminider is updated and set to sent it creates the same feeding schedule same time for the next day---
CREATE OR REPLACE FUNCTION create_next_feeding_reminder()
RETURNS TRIGGER AS $$
DECLARE
    schedule_end DATE;
    reminders_enabled BOOLEAN;
BEGIN
---Only create next reminder when status becomes 'Sent'---
    IF NEW.reminder_status = 'Sent'
       AND OLD.reminder_status <> 'Sent'
       AND NEW.feeding_schedule_id IS NOT NULL
    THEN
---Get schedule end date + enable_reminder flag---
        SELECT feeding_schedule_end, enable_reminder
        INTO schedule_end, reminders_enabled
        FROM feeding_schedule
        WHERE feeding_schedule_id = NEW.feeding_schedule_id;

---If reminders are disabled, stop here---
        IF reminders_enabled IS NOT TRUE THEN
            RETURN NEW;
        END IF;
        
        IF schedule_end IS NULL
           OR (NEW.reminder_date + INTERVAL '1 day') <= schedule_end
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
                NEW.reminder_date + INTERVAL '1 day',
                NEW.reminder_time,
                'Pending'
            );
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;





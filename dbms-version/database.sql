-- =========================================================
-- EVENT RESOURCE CONFLICT DETECTION SYSTEM
-- Complete MySQL 8.0 DBMS Project
-- IMPORTANT: For a fresh installation. If you already created
-- the old database and it contains important data, back it up
-- before running any schema migration or reset.
-- =========================================================

CREATE DATABASE IF NOT EXISTS event_resource_db
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE event_resource_db;

-- 1. MASTER TABLES
CREATE TABLE IF NOT EXISTS resources (
  resource_id INT AUTO_INCREMENT PRIMARY KEY,
  resource_name VARCHAR(100) NOT NULL UNIQUE,
  resource_type VARCHAR(50) DEFAULT 'General',
  location VARCHAR(100),
  capacity INT NOT NULL DEFAULT 0,
  resource_status ENUM('Available','Maintenance','Unavailable')
    NOT NULL DEFAULT 'Available',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT chk_resource_capacity CHECK (capacity >= 0)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS organizers (
  organizer_id INT AUTO_INCREMENT PRIMARY KEY,
  organizer_name VARCHAR(100) NOT NULL UNIQUE,
  email VARCHAR(150),
  phone VARCHAR(20),
  department VARCHAR(100),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS event_categories (
  category_id INT AUTO_INCREMENT PRIMARY KEY,
  category_name VARCHAR(100) NOT NULL UNIQUE,
  description TEXT
) ENGINE=InnoDB;

-- 2. MAIN EVENT TABLE
CREATE TABLE IF NOT EXISTS events (
  event_id INT AUTO_INCREMENT PRIMARY KEY,
  event_name VARCHAR(150) NOT NULL,
  event_description TEXT,
  event_date DATE NOT NULL,
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  resource_id INT NOT NULL,
  organizer_id INT NULL,
  category_id INT NULL,
  expected_attendees INT NOT NULL DEFAULT 0,
  event_status ENUM('Scheduled','Completed','Cancelled')
    NOT NULL DEFAULT 'Scheduled',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_event_resource FOREIGN KEY (resource_id)
    REFERENCES resources(resource_id),
  CONSTRAINT fk_event_organizer FOREIGN KEY (organizer_id)
    REFERENCES organizers(organizer_id) ON DELETE SET NULL,
  CONSTRAINT fk_event_category FOREIGN KEY (category_id)
    REFERENCES event_categories(category_id) ON DELETE SET NULL,
  CONSTRAINT chk_event_time CHECK (start_time < end_time),
  CONSTRAINT chk_event_attendees CHECK (expected_attendees >= 0),
  INDEX idx_event_schedule (event_date, resource_id, start_time, end_time),
  INDEX idx_event_status_date (event_status, event_date),
  INDEX idx_event_name (event_name)
) ENGINE=InnoDB;

-- 3. AUDIT LOGS
CREATE TABLE IF NOT EXISTS event_logs (
  log_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  event_id INT NULL,
  action_type ENUM('INSERT','UPDATE','DELETE') NOT NULL,
  action_description TEXT NOT NULL,
  action_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_log_event (event_id),
  INDEX idx_log_time (action_time)
) ENGINE=InnoDB;

-- 4. DEFAULT MASTER DATA
INSERT IGNORE INTO resources
(resource_name, resource_type, location, capacity) VALUES
('Seminar Hall','Hall','Block A',200),
('Lab 1','Computer Lab','Block B',60),
('Lab 2','Computer Lab','Block B',50),
('Room 101','Classroom','Block C',40),
('Auditorium','Auditorium','Main Block',500),
('Conference Room','Meeting Room','Block A',30),
('Sports Ground','Sports Facility','Sports Complex',1000);

INSERT IGNORE INTO event_categories(category_name, description) VALUES
('Workshop','Technical and practical workshops'),
('Seminar','Educational seminars'),
('Meeting','Official meetings'),
('Cultural','Cultural activities'),
('Sports','Sports activities'),
('Technical','Technical events'),
('Other','Other activities');

-- 5. AUTOMATIC CONFLICT DETECTION BEFORE INSERT
DROP TRIGGER IF EXISTS before_event_insert;
DELIMITER $$
CREATE TRIGGER before_event_insert
BEFORE INSERT ON events
FOR EACH ROW
BEGIN
  DECLARE v_conflicts INT DEFAULT 0;
  DECLARE v_resource_status VARCHAR(20);

  IF NEW.start_time >= NEW.end_time THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Invalid time: end time must be later than start time';
  END IF;

  SELECT resource_status INTO v_resource_status
  FROM resources WHERE resource_id = NEW.resource_id;

  IF v_resource_status IS NULL OR v_resource_status <> 'Available' THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Selected resource is unavailable';
  END IF;

  IF NEW.event_status = 'Scheduled' THEN
    SELECT COUNT(*) INTO v_conflicts
    FROM events
    WHERE resource_id = NEW.resource_id
      AND event_date = NEW.event_date
      AND event_status = 'Scheduled'
      AND NEW.start_time < end_time
      AND NEW.end_time > start_time;

    IF v_conflicts > 0 THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'BOOKING CONFLICT: Resource is already booked';
    END IF;
  END IF;
END$$
DELIMITER ;

-- 6. AUTOMATIC CONFLICT DETECTION BEFORE UPDATE
DROP TRIGGER IF EXISTS before_event_update;
DELIMITER $$
CREATE TRIGGER before_event_update
BEFORE UPDATE ON events
FOR EACH ROW
BEGIN
  DECLARE v_conflicts INT DEFAULT 0;
  DECLARE v_resource_status VARCHAR(20);

  IF NEW.start_time >= NEW.end_time THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Invalid event timing';
  END IF;

  SELECT resource_status INTO v_resource_status
  FROM resources WHERE resource_id = NEW.resource_id;

  IF v_resource_status IS NULL OR v_resource_status <> 'Available' THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Selected resource is unavailable';
  END IF;

  IF NEW.event_status = 'Scheduled' THEN
    SELECT COUNT(*) INTO v_conflicts
    FROM events
    WHERE resource_id = NEW.resource_id
      AND event_date = NEW.event_date
      AND event_id <> OLD.event_id
      AND event_status = 'Scheduled'
      AND NEW.start_time < end_time
      AND NEW.end_time > start_time;

    IF v_conflicts > 0 THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'UPDATE FAILED: Resource booking conflict';
    END IF;
  END IF;
END$$
DELIMITER ;

-- 7. AUDIT TRIGGERS
DROP TRIGGER IF EXISTS after_event_insert;
DELIMITER $$
CREATE TRIGGER after_event_insert
AFTER INSERT ON events
FOR EACH ROW
BEGIN
  INSERT INTO event_logs(event_id, action_type, action_description)
  VALUES(NEW.event_id, 'INSERT',
         CONCAT('New event created: ', NEW.event_name));
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS after_event_update;
DELIMITER $$
CREATE TRIGGER after_event_update
AFTER UPDATE ON events
FOR EACH ROW
BEGIN
  INSERT INTO event_logs(event_id, action_type, action_description)
  VALUES(NEW.event_id, 'UPDATE',
         CONCAT('Event updated: ', OLD.event_name, ' -> ', NEW.event_name));
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS after_event_delete;
DELIMITER $$
CREATE TRIGGER after_event_delete
AFTER DELETE ON events
FOR EACH ROW
BEGIN
  INSERT INTO event_logs(event_id, action_type, action_description)
  VALUES(NULL, 'DELETE',
         CONCAT('Event deleted: ', OLD.event_name,
                ' (Event ID: ', OLD.event_id, ')'));
END$$
DELIMITER ;

-- 8. STORED PROCEDURE: ADD EVENT
DROP PROCEDURE IF EXISTS add_new_event;
DELIMITER $$
CREATE PROCEDURE add_new_event(
  IN p_event_name VARCHAR(150),
  IN p_event_description TEXT,
  IN p_event_date DATE,
  IN p_start_time TIME,
  IN p_end_time TIME,
  IN p_resource_name VARCHAR(100),
  IN p_organizer_name VARCHAR(100),
  IN p_category_name VARCHAR(100),
  IN p_attendees INT
)
BEGIN
  DECLARE v_resource_id INT DEFAULT NULL;
  DECLARE v_organizer_id INT DEFAULT NULL;
  DECLARE v_category_id INT DEFAULT NULL;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  IF p_start_time >= p_end_time THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Invalid event timing';
  END IF;

  IF p_attendees IS NULL OR p_attendees < 0 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Expected attendees cannot be negative';
  END IF;

  SELECT resource_id INTO v_resource_id
  FROM resources
  WHERE resource_name = p_resource_name
    AND resource_status = 'Available'
  LIMIT 1;

  IF v_resource_id IS NULL THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Resource not found or unavailable';
  END IF;

  IF p_organizer_name IS NOT NULL AND TRIM(p_organizer_name) <> '' THEN
    INSERT INTO organizers(organizer_name)
    VALUES(TRIM(p_organizer_name))
    ON DUPLICATE KEY UPDATE organizer_id = LAST_INSERT_ID(organizer_id);
    SET v_organizer_id = LAST_INSERT_ID();
  END IF;

  IF p_category_name IS NOT NULL AND TRIM(p_category_name) <> '' THEN
    SELECT category_id INTO v_category_id
    FROM event_categories
    WHERE category_name = TRIM(p_category_name)
    LIMIT 1;
  END IF;

  INSERT INTO events
    (event_name, event_description, event_date, start_time, end_time,
     resource_id, organizer_id, category_id, expected_attendees)
  VALUES
    (TRIM(p_event_name), p_event_description, p_event_date, p_start_time,
     p_end_time, v_resource_id, v_organizer_id, v_category_id, p_attendees);

  COMMIT;

  SELECT 'SUCCESS' AS status,
         'Event successfully created' AS message,
         LAST_INSERT_ID() AS event_id;
END$$
DELIMITER ;

-- 9. STORED PROCEDURE: DELETE EVENT
DROP PROCEDURE IF EXISTS delete_event;
DELIMITER $$
CREATE PROCEDURE delete_event(IN p_event_id INT)
BEGIN
  DELETE FROM events WHERE event_id = p_event_id;
  SELECT ROW_COUNT() AS deleted_records;
END$$
DELIMITER ;

-- 10. STORED PROCEDURE: CHANGE EVENT STATUS
DROP PROCEDURE IF EXISTS update_event_status;
DELIMITER $$
CREATE PROCEDURE update_event_status(
  IN p_event_id INT,
  IN p_status VARCHAR(20)
)
BEGIN
  IF p_status NOT IN ('Scheduled','Completed','Cancelled') THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Invalid event status';
  END IF;

  UPDATE events SET event_status = p_status
  WHERE event_id = p_event_id;

  SELECT ROW_COUNT() AS affected_records;
END$$
DELIMITER ;

-- 11. VIEW: FULL EVENT DETAILS (used by the Node.js backend)
CREATE OR REPLACE VIEW event_details AS
SELECT
  e.event_id,
  e.event_name,
  e.event_description,
  e.event_date,
  e.start_time,
  e.end_time,
  r.resource_name,
  r.resource_type,
  o.organizer_name,
  o.department,
  c.category_name,
  e.expected_attendees,
  e.event_status,
  e.created_at
FROM events e
JOIN resources r ON r.resource_id = e.resource_id
LEFT JOIN organizers o ON o.organizer_id = e.organizer_id
LEFT JOIN event_categories c ON c.category_id = e.category_id;

-- 12. VIEW: RESOURCE SCHEDULE
CREATE OR REPLACE VIEW resource_schedule AS
SELECT
  r.resource_id,
  r.resource_name,
  e.event_id,
  e.event_name,
  e.event_date,
  e.start_time,
  e.end_time,
  e.event_status
FROM resources r
LEFT JOIN events e ON e.resource_id = r.resource_id;

-- 13. VIEW: DAILY EVENT STATISTICS
CREATE OR REPLACE VIEW daily_event_statistics AS
SELECT
  event_date,
  COUNT(*) AS total_events,
  COUNT(DISTINCT resource_id) AS resources_used,
  SUM(expected_attendees) AS total_expected_attendees
FROM events
WHERE event_status = 'Scheduled'
GROUP BY event_date;

-- 14. VIEW: RESOURCE UTILIZATION
CREATE OR REPLACE VIEW resource_utilization AS
SELECT
  r.resource_id,
  r.resource_name,
  COUNT(e.event_id) AS total_bookings,
  COALESCE(SUM(TIME_TO_SEC(TIMEDIFF(e.end_time,e.start_time))/3600),0)
    AS total_booked_hours
FROM resources r
LEFT JOIN events e
  ON e.resource_id = r.resource_id
  AND e.event_status = 'Scheduled'
GROUP BY r.resource_id, r.resource_name;

-- 15. OPTIONAL SAMPLE ORGANIZERS
INSERT IGNORE INTO organizers(organizer_name,email,department) VALUES
('Shiv Shankar','shiv@example.com','Computer Science'),
('Nitish Kumar','nitish@example.com','Computer Science'),
('Soumya Kumar Singh','soumy@example.com','Computer Science');

-- =========================================================
-- TEST QUERIES (run separately after executing this script)
-- =========================================================
-- SELECT * FROM event_details;
-- SELECT * FROM resources;
-- SELECT * FROM organizers;
-- SELECT * FROM event_logs;
-- SELECT * FROM daily_event_statistics;
-- SELECT * FROM resource_utilization;
--
-- Add a test event:
-- CALL add_new_event(
--   'DBMS Project Presentation',
--   'Event conflict detection demonstration',
--   DATE_ADD(CURDATE(), INTERVAL 1 DAY),
--   '10:00:00','11:00:00',
--   'Seminar Hall','Shiv Shankar','Technical',50
-- );
--
-- Try another event in Seminar Hall on the same date
-- from 10:30 to 11:30. The trigger must reject it:
-- CALL add_new_event(
--   'Conflicting Workshop','Conflict test',
--   DATE_ADD(CURDATE(), INTERVAL 1 DAY),
--   '10:30:00','11:30:00',
--   'Seminar Hall','Nitish Kumar','Workshop',30
-- );
-- =========================================================

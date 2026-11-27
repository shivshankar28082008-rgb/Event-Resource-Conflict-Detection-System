CREATE DATABASE IF NOT EXISTS event_resource_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE event_resource_db;

CREATE TABLE IF NOT EXISTS resources (
  resource_id INT AUTO_INCREMENT PRIMARY KEY,
  resource_name VARCHAR(100) NOT NULL UNIQUE
);
CREATE TABLE IF NOT EXISTS organizers (
  organizer_id INT AUTO_INCREMENT PRIMARY KEY,
  organizer_name VARCHAR(100) NOT NULL UNIQUE
);
CREATE TABLE IF NOT EXISTS events (
  event_id INT AUTO_INCREMENT PRIMARY KEY,
  event_name VARCHAR(150) NOT NULL,
  event_date DATE NOT NULL,
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  resource_id INT NOT NULL,
  organizer_id INT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_event_resource FOREIGN KEY (resource_id) REFERENCES resources(resource_id),
  CONSTRAINT fk_event_organizer FOREIGN KEY (organizer_id) REFERENCES organizers(organizer_id),
  CONSTRAINT chk_event_time CHECK (start_time < end_time),
  INDEX idx_event_schedule (event_date, resource_id, start_time, end_time)
);
INSERT IGNORE INTO resources(resource_name) VALUES
('Seminar Hall'),('Lab 1'),('Lab 2'),('Room 101'),('Auditorium');

CREATE OR REPLACE VIEW event_details AS
SELECT e.event_id,e.event_name,e.event_date,e.start_time,e.end_time,
       r.resource_name,o.organizer_name,e.created_at
FROM events e JOIN resources r ON r.resource_id=e.resource_id
LEFT JOIN organizers o ON o.organizer_id=e.organizer_id;

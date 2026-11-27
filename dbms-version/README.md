# Event Resource Conflict Detection System — DBMS Version

This folder contains the MySQL-backed version of the project. Unlike the original browser demo, event records are stored in a real MySQL database.

## Stack
- Frontend: HTML, CSS, JavaScript
- Backend: Node.js and Express
- Database: MySQL 8
- Driver: mysql2

## DBMS concepts demonstrated
- Database and table creation
- Primary keys and foreign keys
- NOT NULL, UNIQUE and CHECK constraints
- SQL INSERT, SELECT and DELETE
- JOIN through the event_details view
- Indexing for schedule lookups
- Transactions and MySQL named locks
- Parameterized SQL queries

## Run on Windows
1. Open MySQL Workbench or MySQL Command Line and execute `database.sql`.
2. Open a terminal in this folder and run `npm install`.
3. Copy `.env.example` to `.env` and enter your MySQL password.
4. Run `npm start`.
5. Open http://localhost:3000.

## Conflict rule
A booking conflicts when the date and resource are the same and:

```sql
existing.start_time < new.end_time
AND existing.end_time > new.start_time
```

This permits consecutive bookings where one event ends exactly when the next begins.

## API routes
- GET /api/health
- GET /api/resources
- GET /api/events
- POST /api/events
- DELETE /api/events/:id
- GET /api/stats

**Academic title:** Event Resource Conflict Detection System Using MySQL  
**Subject:** Database Management System (DBMS)

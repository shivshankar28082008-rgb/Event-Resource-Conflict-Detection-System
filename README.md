# 📅 Event Resource Conflict Detection System

A simple **C Programming mini project** that manages events and detects resource/room scheduling conflicts.

## 🌐 Live Demo

👉 **[Open Event Resource Conflict Detection System](https://shivshankar28082008-rgb.github.io/Event-Resource-Conflict-Detection-System/)**

## ✨ Features

- ➕ Add Event
- 📅 Enter Event Date
- ⏰ Enter Start and End Time
- 🏫 Select Room / Resource
- ⚠️ Detect Scheduling Conflicts
- 📋 View Event List
- 🔎 Search Events
- 🗑️ Delete Events
- 💾 Browser demo stores events locally

## 🚨 Conflict Rule

A conflict is detected when:

**Same Resource + Same Date + Overlapping Time**

Example:

```
Event 1: DBMS Workshop
Date:     2026-09-25
Time:     10:00 - 12:00
Room:     Seminar Hall

Event 2: C Programming Lab
Date:     2026-09-25
Time:     11:00 - 13:00
Room:     Seminar Hall

Result: ⚠️ RESOURCE CONFLICT
```

## 🧠 C Programming Concepts

- Structures
- Arrays
- Functions
- Loops
- Conditional Statements
- String Handling
- Time Conversion
- Conflict Detection Logic

## 📂 Project Structure

```
Event-Resource-Conflict-Detection-System/
│
├── index.html
├── event_resource_conflict.c
└── README.md
```

## ▶️ C Program

The file **event_resource_conflict.c** is a console-based C implementation with:

1. Add Event
2. View Event List
3. Instructions
4. Conflict detection using date, resource and time
5. Exit

Compile with:

```bash
gcc event_resource_conflict.c -o event_resource_conflict
```

Run:

```bash
./event_resource_conflict
```

## 🎓 Academic Project

**Project Name:** Event Resource Conflict Detection System  
**Subject:** C Programming  
**Project Type:** Mini Project  
**Main Concepts:** Structures, Arrays, Functions, Loops and Conditional Logic

---

### 🔗 Links

**Live Demo:** https://shivshankar28082008-rgb.github.io/Event-Resource-Conflict-Detection-System/  
**GitHub:** https://github.com/shivshankar28082008-rgb/Event-Resource-Conflict-Detection-System

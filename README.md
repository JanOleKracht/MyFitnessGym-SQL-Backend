# 🏋️‍♂️ MyFitnessGym - SQL Backend System

A well-structured relational database backend for a fitness studio, focused on clean schema design, business logic in **T-SQL**, and reliable historical data tracking.  
This project was created as a learning and portfolio project to demonstrate practical SQL Server backend skills.

---

## 🚀 Overview
It focuses on data persistence and core business logic, handling member registrations, class scheduling, and employee management directly at the database level.



### Key Technical Highlights:
* **Modular Architecture:** Organized into logical schemas (`Membership`, `Staff`, `Scheduling`, `App`, `Gym`).
* **Business Logic:** Robust Stored Procedures with validation and error handling.
* **Data Integrity:** Extensive use of constraints (UNIQUE, CHECK, FOREIGN KEY) to ensure data consistency.
* **SCD Type 2:** Professional tracking of salary changes over time without losing historical data.
* **Real-time Reporting:** Views for live class occupancy and payroll snapshots.

---

## 📁 Repository Structure

1. **`01_Database_Setup_&_Tables.sql`**: Database initialization and relational schema design.
2. **`02_Views.sql`**: Reporting layer including occupancy calculations via CTEs.
3. **`03_StoredProcedures.sql`**: Core business logic for memberships, bookings, and HR.
4. **`04_SampleData.sql`**: Seed data and automated test scenarios.

---

## 🛠️ Tech Stack
* **Language:** T-SQL (Transact-SQL)
* **Platform:** Microsoft SQL Server
* **Key Concepts:** ACID Transactions, TRY / CATCH Error Handling, CTEs, SCD Type 2.


---

## 📖 How to Run
Execute the scripts in your SQL Server Management Studio (SSMS) in the following order:
1. `01_Database_Setup_&_Tables.sql`
2. `02_Views.sql`
3. `03_StoredProcedures.sql`
4. `04_SampleData.sql`

---

## 📈 Monitoring & Reliability
The system features a dedicated logging mechanism (`App.ErrorLog`) that captures failed transactions or business rule violations with precise details (error message, line number, procedure name).

---

### 👤 About the Author
I am a **Software Engineer in Training** (Specialist in Application Development) with a primary focus on **C#**. This portfolio project demonstrates my ability to design robust backend architectures and bridge the gap between application logic and relational database systems.

---

## ⚖️ License
This project is licensed under the **MIT License**. Feel free to use and study the code.

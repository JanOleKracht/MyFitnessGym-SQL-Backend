/* ===============================================================================
MY FITNESS GYM - MASTER TEST SCRIPT
Description: Populates seed data and tests business logic/error logging.
===============================================================================
*/

USE [MyFitnessGym];
GO

PRINT '--- 1. LOADING MASTER DATA ---';

-- Departments first
INSERT INTO Staff.JobDepartments (DepartmentName) VALUES ('Management'), ('Training'), ('Maintenance');

-- JobTitles (now with DepartmentIDs: 1=Management, 2=Training)
INSERT INTO Staff.JobTitle (JobName, DepartmentID) VALUES 
('Studio Manager', 1), 
('Personal Trainer', 2), 
('Yoga Instructor', 2);

INSERT INTO Gym.Rooms (RoomName, MaxCapacity, HasAirConditioning) VALUES 
('Power Zone', 20, 1), 
('Zen Garden', 10, 0), 
('Spinning Lab', 15, 1);

INSERT INTO Membership.Types (Name, MonthlyFee, DurationInMonth) VALUES 
('Basic', 19.90, 12), 
('Premium', 49.90, 24);

INSERT INTO Gym.Courses (CourseCode, CourseName, IntensityLevel) VALUES 
('YOGA-01', 'Hatha Yoga', 'Low'), 
('HIT-01', 'High Intensity', 'High'), 
('SPIN-01', 'Cardio Blast', 'Medium');

PRINT '--- 2. EMPLOYEES & CLASSES ---';

INSERT INTO Staff.Employees (EmployeeNumber, FirstName, LastName, DateOfBirth, Email, JobTitleID, HireDate, Status)
VALUES ('STF-001', 'Anna', 'Schmidt', '1988-03-12', 'anna.s@gym.de', 3, '2024-01-01', 'Active');

-- Initial Salary
INSERT INTO Staff.Salary (EmployeeID, PayType, Salary, EffectiveFrom)
VALUES (1, 'Monthly', 3200.00, '2024-01-01');

INSERT INTO Scheduling.Classes (CourseID, TrainerID, RoomID, StartTime, DayOfWeek, MaxParticipants)
VALUES (1, 1, 2, '09:00:00', 1, 10), 
       (2, 1, 1, '18:00:00', 3, 20);

PRINT '--- 3. TESTING PROCEDURES (HAPPY PATH) ---';

-- Testing Registration (Using the correct Schema: Membership)
EXEC Membership.usp_RegisterNewMember 'Tom', 'Tester', '1995-10-10', 'tom@test.de', '0151-111', 'M', 2, 1, 0;
EXEC Membership.usp_RegisterNewMember 'Lisa', 'Logik', '1992-04-05', 'lisa@test.de', '0151-222', 'F', 1, 1, 1;

-- Testing Bookings (Using the correct Schema: Scheduling)
EXEC Scheduling.usp_CreateBooking @MemberID = 1, @ClassID = 1; 
EXEC Scheduling.usp_CreateBooking @MemberID = 2, @ClassID = 1; 

-- Testing Salary Update
EXEC Staff.usp_UpdateEmployeeSalary @EmployeeID = 1, @NewSalary = 3500.00, @PayType = 'Monthly';

PRINT '--- 4. TESTING ERROR LOGGING ---';

-- Provoking error: Member too young
BEGIN TRY
    EXEC Membership.usp_RegisterNewMember 'Baby', 'Groot', '2025-01-01', 'baby@web.de', '000', 'D', 1, 1, 1;
END TRY BEGIN CATCH PRINT 'Captured expected error: Member too young'; END CATCH

-- Provoking error: Duplicate booking
BEGIN TRY
    EXEC Scheduling.usp_CreateBooking @MemberID = 1, @ClassID = 1;
END TRY BEGIN CATCH PRINT 'Captured expected error: Duplicate booking'; END CATCH

PRINT '--- 5. FINAL EVALUATION ---';

-- Verify views (using Schemas)
SELECT * FROM Scheduling.vClassSchedule;
SELECT * FROM Staff.vCurrentSalaries;
SELECT * FROM Staff.Salary WHERE EmployeeID = 1;
SELECT * FROM App.ErrorLog ORDER BY LogTime DESC;
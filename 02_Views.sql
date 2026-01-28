/* ===============================================================================
MY FITNESS GYM - REPORTING VIEWS
Description: Logic for class availability and current payroll snapshots.
===============================================================================
*/

USE [MyFitnessGym];
GO

-- 1. VIEW: CLASS SCHEDULE WITH REAL-TIME AVAILABILITY
-- This view calculates bookings and free spots using a CTE.
CREATE OR ALTER VIEW Scheduling.vClassSchedule AS
WITH Enrollment AS (
    SELECT
        sb.ClassID,
        COUNT(*) AS Bookings,
        sc.MaxParticipants,
        sc.MaxParticipants - COUNT(*) AS FreeSpots
    FROM Scheduling.Bookings sb
    JOIN Scheduling.Classes sc ON sc.ClassID = sb.ClassID
    WHERE sb.Status = 'Booked'
    GROUP BY sb.ClassID, sc.MaxParticipants
)
SELECT 
    sc.ClassID,
    gc.CourseCode,
    gc.CourseName,
    gr.RoomName,
    sc.StartTime,
    -- Converts DayOfWeek (1-7) to a readable Day Name
    CHOOSE(sc.DayOfWeek, 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday') AS DayName,
    se.FirstName + ' ' + se.LastName AS TrainerName,
    ISNULL(e.Bookings, 0) AS CurrentBookings,
    ISNULL(e.FreeSpots, sc.MaxParticipants) AS SpotsLeft    
FROM Scheduling.Classes sc
JOIN Gym.Courses gc ON gc.CourseID = sc.CourseID
JOIN Gym.Rooms gr ON sc.RoomID = gr.RoomID
JOIN Staff.Employees se ON sc.TrainerID = se.EmployeeID
LEFT JOIN Enrollment e ON e.ClassID = sc.ClassID;
GO

-- 2. VIEW: CURRENT STAFF PAYROLL
-- This view shows only active employees and their currently valid salary (SCD Type 2 logic).
CREATE OR ALTER VIEW Staff.vCurrentSalaries AS
SELECT 
    e.EmployeeID,
    e.EmployeeNumber,
    e.FirstName,
    e.LastName,
    j.JobName,      
    s.PayType,
    s.SalaryAmount AS Salary, 
    s.EffectiveFrom AS SalarySince   
FROM Staff.Employees e
JOIN Staff.Salary s ON e.EmployeeID = s.EmployeeID
JOIN Staff.JobTitle j ON e.JobTitleID = j.JobTitleID 
WHERE s.EffectiveTo IS NULL  
  AND e.Status = 'Active';   

GO

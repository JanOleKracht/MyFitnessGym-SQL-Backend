/* ===============================================================================
MY FITNESS GYM - STORED PROCEDURES
Description: Full business logic including Member Management, Bookings, and HR.
===============================================================================
*/

USE [MyFitnessGym];
GO

-- 1. PROCEDURE: REGISTER NEW MEMBER
CREATE OR ALTER PROCEDURE Membership.usp_RegisterNewMember
    @FirstName NVARCHAR(100),
    @LastName NVARCHAR(100),
    @DateOfBirth DATE,
    @Email NVARCHAR(100),
    @PhoneNumber NVARCHAR(100),
    @Gender NVARCHAR(20),
    @MembershipTypeID INT,
    @PrivacyConsent BIT,
    @MarketingConsent BIT
AS
BEGIN   
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
            -- Check Age (Minimum 16)
            IF @DateOfBirth > DATEADD(YEAR, -16, CAST(GETDATE() AS DATE))
                THROW 51000, 'ERROR: Members must be at least 16 years old.', 1;

            -- Check Email Duplicate
            IF EXISTS (SELECT 1 FROM Membership.Members WHERE Email = @Email)
                THROW 51000, 'ERROR: Email is already used!', 1;

            IF @Email NOT LIKE '%@%'
                THROW(51000, 'ERROR: Invalid email format.', 1);

            -- Check MembershipType
            IF NOT EXISTS (SELECT 1 FROM Membership.Types WHERE MembershipTypeID = @MembershipTypeID)
                THROW 51000, 'ERROR: MembershipTypeID does not exist!', 1;

            INSERT INTO Membership.Members (FirstName, LastName, DateOfBirth, Email, PhoneNumber, Gender, MembershipTypeID, Status, JoinDate, PrivacyConsent, MarketingConsent)
            VALUES (@FirstName, @LastName, @DateOfBirth, @Email, @PhoneNumber, @Gender, @MembershipTypeID, 'Active', SYSDATETIME(), @PrivacyConsent, @MarketingConsent);
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        INSERT INTO App.ErrorLog(ProcedureName, ErrorMessage, ErrorNumber, ErrorState, ErrorLine)
        VALUES('Membership.usp_RegisterNewMember', ERROR_MESSAGE(), ERROR_NUMBER(), ERROR_STATE(), ERROR_LINE());
        THROW;
    END CATCH
END;
GO

-- 2. PROCEDURE: CREATE BOOKING
CREATE OR ALTER PROCEDURE Scheduling.usp_CreateBooking
    @MemberID INT,
    @ClassID INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
            IF NOT EXISTS (SELECT 1 FROM Membership.Members WHERE MemberID = @MemberID) 
                THROW 51000, 'ERROR: Member does not exist', 1;

            IF NOT EXISTS (SELECT 1 FROM Scheduling.Classes WHERE ClassID = @ClassID)
                THROW 51000, 'ERROR: Class does not exist', 1;

            DECLARE @MemberStatus NVARCHAR(20);
            SELECT @MemberStatus = Status FROM Membership.Members WHERE MemberID = @MemberID;

            IF @MemberStatus IS NULL OR @MemberStatus != 'Active'
                THROW 51000, 'ERROR: Member status is not Active!', 1;

            IF EXISTS (SELECT 1 FROM Scheduling.Bookings WHERE MemberID = @MemberID AND ClassID = @ClassID AND Status != 'Cancelled')
                THROW 51000, 'ERROR: Member already booked this class.', 1;

            DECLARE @MaxParticipants INT, @CurrentBookings INT;
            SELECT @MaxParticipants = MaxParticipants FROM Scheduling.Classes WHERE ClassID = @ClassID;
            SELECT @CurrentBookings = COUNT(*) FROM Scheduling.Bookings WHERE ClassID = @ClassID AND Status IN ('Booked','Attended','NoShow');

            IF @CurrentBookings >= @MaxParticipants
                THROW 51000, 'ERROR: Class is full capacity reached', 1;
    
            INSERT INTO Scheduling.Bookings(MemberID, ClassID) VALUES(@MemberID, @ClassID);
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        INSERT INTO App.ErrorLog(ProcedureName, ErrorMessage, ErrorNumber, ErrorState, ErrorLine)
        VALUES('Scheduling.usp_CreateBooking', ERROR_MESSAGE(), ERROR_NUMBER(), ERROR_STATE(), ERROR_LINE());
        THROW;
    END CATCH
END;
GO

-- 3. PROCEDURE: CANCEL MEMBERSHIP
CREATE OR ALTER PROCEDURE Membership.usp_CancelMembership
    @MemberID INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
            IF NOT EXISTS (SELECT 1 FROM Membership.Members WHERE MemberID = @MemberID)
                THROW 51000, 'ERROR: Member does not exist', 1;

            IF (SELECT Status FROM Membership.Members WHERE MemberID = @MemberID) = 'Cancelled'
                THROW 51000, 'ERROR: Membership already cancelled!', 1;

            UPDATE Membership.Members SET Status = 'Cancelled' WHERE MemberID = @MemberID;
            UPDATE Scheduling.Bookings SET Status = 'Cancelled' WHERE MemberID = @MemberID AND Status = 'Booked';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        INSERT INTO App.ErrorLog(ProcedureName, ErrorMessage, ErrorNumber, ErrorState, ErrorLine)
        VALUES('Membership.usp_CancelMembership', ERROR_MESSAGE(), ERROR_NUMBER(), ERROR_STATE(), ERROR_LINE());
        THROW;
    END CATCH
END;
GO

-- 4. PROCEDURE: REACTIVATE MEMBERSHIP
CREATE OR ALTER PROCEDURE Membership.usp_ReactivateMembership
    @MemberID INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
            IF NOT EXISTS (SELECT 1 FROM Membership.Members WHERE MemberID = @MemberID)
                THROW 51000, 'ERROR: Member does not exist', 1;

            IF (SELECT Status FROM Membership.Members WHERE MemberID = @MemberID) = 'Active'
                THROW 51000, 'ERROR: Membership already active!', 1;

            UPDATE Membership.Members SET Status = 'Active' WHERE MemberID = @MemberID;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        INSERT INTO App.ErrorLog(ProcedureName, ErrorMessage, ErrorNumber, ErrorState, ErrorLine)
        VALUES('Membership.usp_ReactivateMembership', ERROR_MESSAGE(), ERROR_NUMBER(), ERROR_STATE(), ERROR_LINE());
        THROW;
    END CATCH
END;
GO

-- 5. PROCEDURE: UPDATE EMPLOYEE SALARY (SCD TYPE 2)
CREATE OR ALTER PROCEDURE Staff.usp_UpdateEmployeeSalary
    @EmployeeID INT,
    @NewSalary DECIMAL(10,2),
    @PayType NVARCHAR(50) 
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @Today DATE = CAST(GETDATE() AS DATE);
    DECLARE @Yesterday DATE = DATEADD(DAY, -1, @Today);
    BEGIN TRY
        BEGIN TRANSACTION;
            IF NOT EXISTS (SELECT 1 FROM Staff.Employees WHERE EmployeeID = @EmployeeID)
                THROW 51000, 'ERROR: Employee does not exist.', 1;

            UPDATE Staff.Salary SET EffectiveTo = @Yesterday, UpdatedAt = SYSDATETIME()
            WHERE EmployeeID = @EmployeeID AND EffectiveTo IS NULL; 

            INSERT INTO Staff.Salary (EmployeeID, PayType, SalaryAmount, EffectiveFrom, EffectiveTo, CreatedAt, UpdatedAt)
            VALUES (@EmployeeID, @PayType, @NewSalary, @Today, NULL, SYSDATETIME(), SYSDATETIME());
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        INSERT INTO App.ErrorLog (ProcedureName, ErrorMessage, ErrorNumber, ErrorState, ErrorLine)
        VALUES ('Staff.usp_UpdateEmployeeSalary', ERROR_MESSAGE(), ERROR_NUMBER(), ERROR_STATE(), ERROR_LINE());
        THROW;
    END CATCH
END;

GO


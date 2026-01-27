/* ===============================================================================
MY FITNESS GYM - DATABASE SETUP & SCHEMA
Order: 1. Database -> 2. Schemas -> 3. Tables (by Dependency)
===============================================================================
*/

USE master;
GO

-- 1. DATABASE RESET
IF EXISTS (SELECT * FROM sys.databases WHERE name = 'MyFitnessGym')
BEGIN
    ALTER DATABASE [MyFitnessGym] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE [MyFitnessGym];
END
GO

CREATE DATABASE MyFitnessGym;
GO

USE MyFitnessGym;
GO

-- 2. CREATE SCHEMAS
CREATE SCHEMA App;
GO
CREATE SCHEMA Gym;
GO
CREATE SCHEMA Membership;
GO
CREATE SCHEMA Staff;
GO
CREATE SCHEMA Scheduling;
GO

-- 3. INDEPENDENT TABLES (Level 0 - No Foreign Keys)

CREATE TABLE App.ErrorLog (
    LogID INT IDENTITY (1,1),
    LogTime DATETIME DEFAULT GETDATE(),
    ProcedureName NVARCHAR(128),
    ErrorMessage NVARCHAR(MAX),
    ErrorNumber INT,
    ErrorState INT,
    ErrorLine INT,
    UserName NVARCHAR(128) DEFAULT SUSER_SNAME(),
    CONSTRAINT PK_ErrorLog_LogId PRIMARY KEY (LogID)
);
GO

CREATE TABLE Gym.Rooms (
    RoomID INT IDENTITY(1,1),
    RoomName NVARCHAR(100) NOT NULL,
    RoomType NVARCHAR(50),
    MaxCapacity INT NOT NULL,
    HasAirConditioning BIT DEFAULT 0,
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    UpdatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT PK_Rooms_RoomID PRIMARY KEY(RoomID),
    CONSTRAINT UQ_Rooms_RoomName UNIQUE(RoomName),
    CONSTRAINT CK_Rooms_MaxCapacity CHECK(MaxCapacity > 0)
);
GO

CREATE TABLE Gym.Courses (
    CourseID INT IDENTITY(1,1),
    CourseCode NVARCHAR(100) NOT NULL,
    CourseName NVARCHAR(100) NOT NULL,
    Description NVARCHAR(MAX), 
    IntensityLevel NVARCHAR(20),
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    UpdatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT PK_Courses_CourseID PRIMARY KEY (CourseID),
    CONSTRAINT UQ_Courses_CourseCode UNIQUE(CourseCode),
    CONSTRAINT UQ_Courses_CourseName UNIQUE(CourseName),
    CONSTRAINT CK_Courses_IntensityLevel CHECK(IntensityLevel IN ('Low','Medium','High','Expert'))
);
GO

CREATE TABLE Membership.Types (
    MembershipTypeID INT IDENTITY(1,1),
    Name NVARCHAR(50) NOT NULL,
    Description NVARCHAR(50),
    MonthlyFee DECIMAL (10,2) NOT NULL,
    DurationInMonth INT DEFAULT 1, -- Komma korrigiert!
    CONSTRAINT PK_MembershipTypes_MembershipTypeID PRIMARY KEY (MembershipTypeID),
    CONSTRAINT CK_MembershipTypes_Name CHECK(Name IN('Basic12','Basic24','Silver12','Silver24','Gold12','Gold24','Platinum','Student'))
);
GO

CREATE TABLE Staff.JobDepartments (
    DepartmentID INT IDENTITY(1,1),
    DepartmentName NVARCHAR(100),
    CONSTRAINT PK_JobDepartments_DepartmentID PRIMARY KEY (DepartmentID),
    CONSTRAINT UQ_DepartmentName UNIQUE(DepartmentName)
);
GO

-- 4. DEPENDENT TABLES (Level 1 - One Link)

CREATE TABLE Staff.JobTitle (
    JobTitleID INT IDENTITY(1,1),
    DepartmentID INT,
    JobName NVARCHAR(100) NOT NULL,
    JobDescription NVARCHAR(100),
    CONSTRAINT PK_JobTitle_JobTitleID PRIMARY KEY (JobTitleID),
    CONSTRAINT FK_Jobtitle_JobDepartments_DepartmentID FOREIGN KEY (DepartmentID) REFERENCES Staff.JobDepartments(DepartmentID),
    CONSTRAINT UQ_JobName UNIQUE(JobName)
);
GO

CREATE TABLE Membership.Members (
    MemberID INT IDENTITY(1,1),
    FirstName NVARCHAR(100) NOT NULL,
    LastName NVARCHAR(100) NOT NULL,
    Gender NVARCHAR(20),
    Email NVARCHAR(100) NOT NULL,
    PhoneNumber NVARCHAR(100),
    DateOfBirth DATE NOT NULL,
    JoinDate DATE CONSTRAINT DF_Members_JoinDate DEFAULT (CONVERT(date, GETDATE())) NOT NULL,
    EndDate DATE,
    Status NVARCHAR(20) NOT NULL,
    MembershipTypeID INT NOT NULL,    
    BillingStartDate DATE,
    BillingCycle NVARCHAR(20), 
    PrivacyConsent BIT NOT NULL,
    MarketingConsent BIT NOT NULL,
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    UpdatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT PK_Members_MemberID PRIMARY KEY(MemberID),
    CONSTRAINT FK_Members_MembershipTypes_MembershipTypeID FOREIGN KEY (MembershipTypeID) REFERENCES Membership.Types(MembershipTypeID),
    CONSTRAINT CK_Members_Gender CHECK (Gender IN('M','F','D') OR Gender IS NULL),
    CONSTRAINT UQ_Members_Email UNIQUE(Email),
    CONSTRAINT CK_Members_EndDate CHECK (EndDate IS NULL OR EndDate >= JoinDate),
    CONSTRAINT CK_Members_Status CHECK (Status IN ('Active', 'Paused', 'Cancelled'))
);
GO

-- 5. DEPENDENT TABLES (Level 2 - Employees)

CREATE TABLE Staff.Employees (
    EmployeeID INT IDENTITY(1,1),
    EmployeeNumber NVARCHAR(20) NOT NULL,
    FirstName NVARCHAR(100) NOT NULL,
    LastName NVARCHAR(100) NOT NULL,
    DateOfBirth DATE NOT NULL,
    Gender NVARCHAR(20),
    Email NVARCHAR(100) NOT NULL,
    PhoneNumber NVARCHAR(50),
    JobTitleID INT NOT NULL,
    HireDate DATE NOT NULL DEFAULT CONVERT(date, GETDATE()),
    EndDate DATE NULL,
    Status NVARCHAR(20) NOT NULL,
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    UpdatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT PK_Employees_EmployeeID PRIMARY KEY (EmployeeID),
    CONSTRAINT FK_Emplyees_JobTitle_JobTitleID FOREIGN KEY (JobTitleID) REFERENCES Staff.JobTitle(JobTitleID),
    CONSTRAINT CK_Employees_Gender CHECK (Gender IN('M','F','D') OR Gender IS NULL),
    CONSTRAINT UQ_Employees_Email UNIQUE(Email),
    CONSTRAINT CK_Employeess_EndDate CHECK (EndDate IS NULL OR EndDate >= HireDate),
    CONSTRAINT CK_Employees_Status CHECK(Status IN ('Active','OnLeave','Terminated'))
);
GO

-- 6. DEPENDENT TABLES (Level 3 - Classes & Salary)

CREATE TABLE Staff.Salary (
    SalaryID INT IDENTITY (1,1),
    EmployeeID INT NOT NULL,
    PayType NVARCHAR(50) NOT NULL,
    SalaryMonth DECIMAL(10,2) NOT NULL,
    EffectiveFrom DATE NOT NULL DEFAULT CONVERT(date, GETDATE()),
    EffectiveTo DATE NULL,
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    UpdatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT PK_Salary_SalaryID PRIMARY KEY (SalaryID),
    CONSTRAINT FK_Employees_EmployeeID FOREIGN KEY(EmployeeID) REFERENCES Staff.Employees(EmployeeID),
    CONSTRAINT CK_Salary_PayType CHECK(PayType IN('Hourly','Monthly')),
    CONSTRAINT CK_Slaray_SalaryMonth CHECK(SalaryMonth > 0),
    CONSTRAINT CK_Salary_EffectiveTo CHECK (EffectiveTo IS NULL OR EffectiveTo >= EffectiveFrom)
);
GO

CREATE TABLE Scheduling.Classes (
    ClassID INT IDENTITY (1,1),
    CourseID INT NOT NULL,
    TrainerID INT NOT NULL,
    RoomID INT NOT NUll,
    DayOfWeek TINYINT NOT NULL,
    StartTime TIME(0) NOT NULL,
    DurationInMinutes INT NOT NULL DEFAULT 60,
    MaxParticipants INT NOT NULL,
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    UpdatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT PK_Classes_ClassID PRIMARY KEY (ClassID),
    CONSTRAINT FK_Classes_Courses_CourseID FOREIGN KEY (CourseID) REFERENCES Gym.Courses(CourseID),
    CONSTRAINT FK_Classes_Employees_TrainerID FOREIGN KEY (TrainerID) REFERENCES Staff.Employees(EmployeeID),
    CONSTRAINT FK_Classes_Rooms_RoomID FOREIGN KEY (RoomID) REFERENCES Gym.Rooms(RoomID),
    CONSTRAINT CK_Classes_DayOfWeek CHECK (DayOfWeek BETWEEN 1 AND 7),
    CONSTRAINT CK_Classes_Duration CHECK (DurationInMinutes > 0),
    CONSTRAINT CK_Classes_MaxParticipants CHECK (MaxParticipants > 0)
);
GO

-- 7. DEPENDENT TABLES (Level 4 - Final Link: Bookings)

CREATE TABLE Scheduling.Bookings (
    BookingID INT IDENTITY(1,1),
    MemberID INT,
    ClassID INT,
    BookingDate DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    Status NVARCHAR(20) NOT NULL DEFAULT 'Booked', 
    UpdatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT PK_Bookings_BookingID PRIMARY KEY(BookingID),
    CONSTRAINT FK_Bookings_Members_MEmberID FOREIGN KEY(MemberID) REFERENCES Membership.Members(MemberID),
    CONSTRAINT FK_Bookings_Classes_ClassID FOREIGN KEY (ClassID) REFERENCES Scheduling.Classes(ClassID),
    CONSTRAINT CK_Bookings_Status CHECK(Status IN('Booked', 'Cancelled', 'Attended', 'NoShow')),
    CONSTRAINT UQ_Bookings_Member_Class UNIQUE (MemberID, ClassID)
);
GO
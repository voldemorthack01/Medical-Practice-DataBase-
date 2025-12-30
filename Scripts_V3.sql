/* ========================================================================================
   File: Amir_Sharabiani_CreateMedicalPracticeDatabase_V2.sql
   Part 1 - Task 1: Create MedicalPractice database and all tables
   ======================================================================================== */

-- Drop and recreate the database safely
USE master;
GO
IF DB_ID(N'MedicalPractice') IS NOT NULL
BEGIN
    ALTER DATABASE MedicalPractice SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE MedicalPractice;
END;
GO

CREATE DATABASE MedicalPractice;
GO

USE MedicalPractice;
GO

/* ============================================================
   Reference Tables
   ============================================================ */

-- WeekDays
IF OBJECT_ID('WeekDays', 'U') IS NOT NULL DROP TABLE WeekDays;
CREATE TABLE WeekDays (
    WeekDayName NVARCHAR(9) NOT NULL,
    CONSTRAINT PK_WeekDays PRIMARY KEY (WeekDayName),
    CONSTRAINT CK_WeekDays_Valid CHECK (WeekDayName IN (N'Monday', N'Tuesday', N'Wednesday', N'Thursday', N'Friday'))
);
GO

-- PractitionerType
IF OBJECT_ID('PractitionerType', 'U') IS NOT NULL DROP TABLE PractitionerType;
CREATE TABLE PractitionerType (
    PractitionerType NVARCHAR(50) NOT NULL,
    CONSTRAINT PK_PractitionerType PRIMARY KEY (PractitionerType)
);
GO

/* ============================================================
   Core Tables
   ============================================================ */

-- Patient
IF OBJECT_ID('Patient', 'U') IS NOT NULL DROP TABLE Patient;
CREATE TABLE Patient (
    Patient_ID INT NOT NULL,
    Title NVARCHAR(20),
    FirstName NVARCHAR(50) NOT NULL,
    MiddleInitial NCHAR(1),
    LastName NVARCHAR(50) NOT NULL,
    HouseUnitLotNum NVARCHAR(5) NOT NULL,
    Street NVARCHAR(50) NOT NULL,
    Suburb NVARCHAR(50) NOT NULL,
    State NVARCHAR(3) NOT NULL,
    PostCode NCHAR(4) NOT NULL,
    HomePhone NCHAR(10),
    MobilePhone NCHAR(10),
    MedicareNumber NCHAR(16),
    DateOfBirth DATE NOT NULL,
    Gender NVARCHAR(20) NOT NULL,
    CONSTRAINT PK_Patient PRIMARY KEY (Patient_ID),
    CONSTRAINT CK_Patient_ID_Range CHECK (Patient_ID BETWEEN 10000 AND 99999),
    CONSTRAINT CK_Patient_State_Length CHECK (LEN(State) = 3),
    CONSTRAINT CK_Patient_PostCode_Length CHECK (LEN(PostCode) = 4),
    CONSTRAINT CK_Patient_Gender CHECK (Gender IN (N'male', N'female', N'unspecified', N'indeterminate', N'intersex'))
);
GO

-- Practitioner
IF OBJECT_ID('Practitioner', 'U') IS NOT NULL DROP TABLE Practitioner;
CREATE TABLE Practitioner (
    Practitioner_ID INT NOT NULL,
    Title NVARCHAR(20),
    FirstName NVARCHAR(50) NOT NULL,
    MiddleInitial NCHAR(1),
    LastName NVARCHAR(50) NOT NULL,
    HouseUnitLotNum NVARCHAR(5) NOT NULL,
    Street NVARCHAR(50) NOT NULL,
    Suburb NVARCHAR(50) NOT NULL,
    State NVARCHAR(3) NOT NULL,
    PostCode NCHAR(4) NOT NULL,
    HomePhone NCHAR(10),        -- Changed it from NCAHR(8) to NCHAR(10) to match it with the csv file.
    MobilePhone NCHAR(10),      -- Changed it from NCAHR(8) to NCHAR(10) to match it with the csv file.
    MedicareNumber NCHAR(16),
    MedicalRegistrationNumber NCHAR(11) NOT NULL,       -- Moved it from the second column to 14th column to match it with the csv file.
    DateOfBirth DATE NOT NULL,
    Gender NCHAR(20) NOT NULL,
    PractitionerType_Ref NVARCHAR(50) NOT NULL,
    CONSTRAINT PK_Practitioner PRIMARY KEY (Practitioner_ID),
    CONSTRAINT UQ_Practitioner_MRN UNIQUE (MedicalRegistrationNumber),
    CONSTRAINT CK_Practitioner_ID_Range CHECK (Practitioner_ID BETWEEN 10000 AND 99999),
    CONSTRAINT CK_Practitioner_State_Length CHECK (LEN(State) = 3),
    CONSTRAINT CK_Practitioner_PostCode_Length CHECK (LEN(PostCode) = 4),
    CONSTRAINT CK_Practitioner_Gender CHECK (Gender IN (N'male', N'female', N'unspecified', N'indeterminate', N'intersex')),
    CONSTRAINT FK_Practitioner_Type FOREIGN KEY (PractitionerType_Ref) REFERENCES PractitionerType(PractitionerType)
);
GO

-- Availability
IF OBJECT_ID('Availability', 'U') IS NOT NULL DROP TABLE Availability;
CREATE TABLE Availability (
    Practitioner_Ref INT NOT NULL,
    WeekDayName_Ref NVARCHAR(9) NOT NULL,       -- Moved it from the first column to the second column to match it with the csv file.
    CONSTRAINT PK_Availability PRIMARY KEY (WeekDayName_Ref, Practitioner_Ref),
    CONSTRAINT FK_Availability_WeekDay FOREIGN KEY (WeekDayName_Ref) REFERENCES WeekDays(WeekDayName),
    CONSTRAINT FK_Availability_Practitioner FOREIGN KEY (Practitioner_Ref) REFERENCES Practitioner(Practitioner_ID)
);
GO

-- Appointment
IF OBJECT_ID('Appointment', 'U') IS NOT NULL DROP TABLE Appointment;
CREATE TABLE Appointment (
    Practitioner_Ref INT NOT NULL,
    AppDate DATE NOT NULL,
    AppStartTime TIME(0) NOT NULL,
    Patient_Ref INT NOT NULL,
    CONSTRAINT PK_Appointment PRIMARY KEY (Practitioner_Ref, AppDate, AppStartTime),
    CONSTRAINT UQ_Appointment_PatientSlot UNIQUE (Patient_Ref, AppDate, AppStartTime),
    CONSTRAINT FK_Appointment_Practitioner FOREIGN KEY (Practitioner_Ref) REFERENCES Practitioner(Practitioner_ID),
    CONSTRAINT FK_Appointment_Patient FOREIGN KEY (Patient_Ref) REFERENCES Patient(Patient_ID)
);
GO

/* ============================================================
   Optional Indexes for Performance
   ============================================================ */
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Patient_Name' AND object_id = OBJECT_ID('Patient'))
    DROP INDEX IX_Patient_Name ON Patient;
CREATE INDEX IX_Patient_Name ON Patient (LastName, FirstName);

IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Practitioner_Name' AND object_id = OBJECT_ID('Practitioner'))
    DROP INDEX IX_Practitioner_Name ON Practitioner;
CREATE INDEX IX_Practitioner_Name ON Practitioner (LastName, FirstName);
GO

/* ============================================================
   End of Part 1 Task 1 Script
   ============================================================ */

/* ============================================================
   Part 1 - Task 2: Validate MedicalPractice database schema
   ============================================================ */

USE MedicalPractice;
GO

/* ============================================================
   T6 Verify Tables and Keys
   ============================================================ */
-- Verify that all required tables exist
SELECT name 
FROM sys.tables 
ORDER BY name;

-- Verify that all required constraints exist
SELECT name, type_desc 
FROM sys.objects 
WHERE type IN ('PK','F','UQ')
ORDER BY type_desc, name;
GO

/* ============================================================
   T1 Valid Patient Insert
   ============================================================ */
INSERT INTO Patient (
    Patient_ID, FirstName, LastName, HouseUnitLotNum, Street, Suburb, State, PostCode, DateOfBirth, Gender
)
VALUES (
    10001, 'John', 'Smith', '21', 'Fuller Street', 'Sunshine', 'NSW', '2343', '1980-05-12', 'male'
);
GO

/* ============================================================
   T2 Invalid Gender Constraint
   ============================================================ */
INSERT INTO Patient (
    Patient_ID, FirstName, LastName, HouseUnitLotNum, Street, Suburb, State, PostCode, DateOfBirth, Gender
)
VALUES (
    10002, 'Jane', 'Doe', '10', 'Main Street', 'Sydney', 'NSW', '2000', '1975-03-20', 'unknown'
);
GO

/* ============================================================
   T3 Unique Practitioner MRN
   ============================================================ */
-- Insert practitioner type
INSERT INTO PractitionerType VALUES ('Doctor');

-- Insert valid practitioner
INSERT INTO Practitioner (
    Practitioner_ID, MedicalRegistrationNumber, FirstName, LastName, HouseUnitLotNum, Street, Suburb, State, PostCode, DateOfBirth, Gender, PractitionerType_Ref
)
VALUES (
    20001, 'REG12345678', 'Anne', 'Funsworth', '5', 'King Street', 'Sydney', 'NSW', '2000', '1970-01-01', 'female', 'Doctor'
);

-- Attempt to insert duplicate MRN (should fail)
INSERT INTO Practitioner (
    Practitioner_ID, MedicalRegistrationNumber, FirstName, LastName, HouseUnitLotNum, Street, Suburb, State, PostCode, DateOfBirth, Gender, PractitionerType_Ref
)
VALUES (
    20002, 'REG12345678', 'Bob', 'Jones', '12', 'Queen Street', 'Sydney', 'NSW', '2000', '1985-07-15', 'male', 'Doctor'
);
GO

/* ============================================================
   T4 Valid Appointment Insert
   ============================================================ */
-- Insert weekday
INSERT INTO WeekDays VALUES ('Wednesday');

-- Insert availability
INSERT INTO Availability (WeekDayName_Ref, Practitioner_Ref)
VALUES ('Wednesday', 20001);

-- Insert valid appointment
INSERT INTO Appointment (Practitioner_Ref, AppDate, AppStartTime, Patient_Ref)
VALUES (20001, '2019-09-18', '09:00', 10001);
GO

/* ============================================================
   T5 Invalid Appointment FK
   ============================================================ */
-- Attempt to insert appointment with non-existent patient (should fail)
INSERT INTO Appointment (Practitioner_Ref, AppDate, AppStartTime, Patient_Ref)
VALUES (20001, '2019-09-18', '10:00', 99999);
GO



/* ===================================================================
    Dropping and re-creating the tables
   =================================================================== */
   -- Drop and recreate the database safely
USE master;
GO
IF DB_ID(N'MedicalPractice') IS NOT NULL
BEGIN
    ALTER DATABASE MedicalPractice SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE MedicalPractice;
END;
GO

CREATE DATABASE MedicalPractice;
GO

USE MedicalPractice;
GO

-- WeekDays
IF OBJECT_ID('WeekDays', 'U') IS NOT NULL DROP TABLE WeekDays;
CREATE TABLE WeekDays (
    WeekDayName NVARCHAR(9) NOT NULL,
    CONSTRAINT PK_WeekDays PRIMARY KEY (WeekDayName),
    CONSTRAINT CK_WeekDays_Valid CHECK (WeekDayName IN (N'Monday', N'Tuesday', N'Wednesday', N'Thursday', N'Friday'))
);
GO

-- PractitionerType
IF OBJECT_ID('PractitionerType', 'U') IS NOT NULL DROP TABLE PractitionerType;
CREATE TABLE PractitionerType (
    PractitionerType NVARCHAR(50) NOT NULL,
    CONSTRAINT PK_PractitionerType PRIMARY KEY (PractitionerType)
);
GO

-- Patient
IF OBJECT_ID('Patient', 'U') IS NOT NULL DROP TABLE Patient;
CREATE TABLE Patient (
    Patient_ID INT NOT NULL,
    Title NVARCHAR(20),
    FirstName NVARCHAR(50) NOT NULL,
    MiddleInitial NCHAR(1),
    LastName NVARCHAR(50) NOT NULL,
    HouseUnitLotNum NVARCHAR(5) NOT NULL,
    Street NVARCHAR(50) NOT NULL,
    Suburb NVARCHAR(50) NOT NULL,
    State NVARCHAR(3) NOT NULL,
    PostCode NCHAR(4) NOT NULL,
    HomePhone NCHAR(10),
    MobilePhone NCHAR(10),
    MedicareNumber NCHAR(16),
    DateOfBirth DATE NOT NULL,
    Gender NVARCHAR(20) NOT NULL,
    CONSTRAINT PK_Patient PRIMARY KEY (Patient_ID),
    CONSTRAINT CK_Patient_ID_Range CHECK (Patient_ID BETWEEN 10000 AND 99999),
    CONSTRAINT CK_Patient_State_Length CHECK (LEN(State) = 3),
    CONSTRAINT CK_Patient_PostCode_Length CHECK (LEN(PostCode) = 4),
    CONSTRAINT CK_Patient_Gender CHECK (Gender IN (N'male', N'female', N'unspecified', N'indeterminate', N'intersex'))
);
GO

-- Practitioner
IF OBJECT_ID('Practitioner', 'U') IS NOT NULL DROP TABLE Practitioner;
CREATE TABLE Practitioner (
    Practitioner_ID INT NOT NULL,
    Title NVARCHAR(20),
    FirstName NVARCHAR(50) NOT NULL,
    MiddleInitial NCHAR(1),
    LastName NVARCHAR(50) NOT NULL,
    HouseUnitLotNum NVARCHAR(5) NOT NULL,
    Street NVARCHAR(50) NOT NULL,
    Suburb NVARCHAR(50) NOT NULL,
    State NVARCHAR(3) NOT NULL,
    PostCode NCHAR(4) NOT NULL,
    HomePhone NCHAR(10),        -- Changed it from NCAHR(8) to NCHAR(10) to match it with the csv file.
    MobilePhone NCHAR(10),      -- Changed it from NCAHR(8) to NCHAR(10) to match it with the csv file.
    MedicareNumber NCHAR(16),
    MedicalRegistrationNumber NCHAR(11) NOT NULL,       -- Moved it from the second column to 14th column to match it with the csv file.
    DateOfBirth DATE NOT NULL,
    Gender NCHAR(20) NOT NULL,
    PractitionerType_Ref NVARCHAR(50) NOT NULL,
    CONSTRAINT PK_Practitioner PRIMARY KEY (Practitioner_ID),
    CONSTRAINT UQ_Practitioner_MRN UNIQUE (MedicalRegistrationNumber),
    CONSTRAINT CK_Practitioner_ID_Range CHECK (Practitioner_ID BETWEEN 10000 AND 99999),
    CONSTRAINT CK_Practitioner_State_Length CHECK (LEN(State) = 3),
    CONSTRAINT CK_Practitioner_PostCode_Length CHECK (LEN(PostCode) = 4),
    CONSTRAINT CK_Practitioner_Gender CHECK (Gender IN (N'male', N'female', N'unspecified', N'indeterminate', N'intersex')),
    CONSTRAINT FK_Practitioner_Type FOREIGN KEY (PractitionerType_Ref) REFERENCES PractitionerType(PractitionerType)
);
GO

-- Availability
IF OBJECT_ID('Availability', 'U') IS NOT NULL DROP TABLE Availability;
CREATE TABLE Availability (
    Practitioner_Ref INT NOT NULL,
    WeekDayName_Ref NVARCHAR(9) NOT NULL,       -- Moved it from the first column to the second column to match it with the csv file.
    CONSTRAINT PK_Availability PRIMARY KEY (WeekDayName_Ref, Practitioner_Ref),
    CONSTRAINT FK_Availability_WeekDay FOREIGN KEY (WeekDayName_Ref) REFERENCES WeekDays(WeekDayName),
    CONSTRAINT FK_Availability_Practitioner FOREIGN KEY (Practitioner_Ref) REFERENCES Practitioner(Practitioner_ID)
);
GO

-- Appointment
IF OBJECT_ID('Appointment', 'U') IS NOT NULL DROP TABLE Appointment;
CREATE TABLE Appointment (
    Practitioner_Ref INT NOT NULL,
    AppDate DATE NOT NULL,
    AppStartTime TIME(0) NOT NULL,
    Patient_Ref INT NOT NULL,
    CONSTRAINT PK_Appointment PRIMARY KEY (Practitioner_Ref, AppDate, AppStartTime),
    CONSTRAINT UQ_Appointment_PatientSlot UNIQUE (Patient_Ref, AppDate, AppStartTime),
    CONSTRAINT FK_Appointment_Practitioner FOREIGN KEY (Practitioner_Ref) REFERENCES Practitioner(Practitioner_ID),
    CONSTRAINT FK_Appointment_Patient FOREIGN KEY (Patient_Ref) REFERENCES Patient(Patient_ID)
);
GO


-- Optional: Indexes for Performance

IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Patient_Name' AND object_id = OBJECT_ID('Patient'))
    DROP INDEX IX_Patient_Name ON Patient;
CREATE INDEX IX_Patient_Name ON Patient (LastName, FirstName);

IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Practitioner_Name' AND object_id = OBJECT_ID('Practitioner'))
    DROP INDEX IX_Practitioner_Name ON Practitioner;
CREATE INDEX IX_Practitioner_Name ON Practitioner (LastName, FirstName);
GO

USE MedicalPractice;
GO

-- Verify that all required tables exist
SELECT name 
FROM sys.tables 
ORDER BY name;

-- Verify that all required constraints exist
SELECT name, type_desc 
FROM sys.objects 
WHERE type IN ('PK','F','UQ')
ORDER BY type_desc, name;
GO


/* ============================================================
    End of re-creating the fresh tables
   ============================================================ */
/* ==========================================================================
   Part 1 - Task 4: Bulk load CSV data into MedicalPractice DB          =============
   ========================================================================== */

USE MedicalPractice;
GO

-- Load Patient data
BULK INSERT Patient
FROM 'C:\temp\CSV_DataFiles\PatientData.csv'
WITH (
    FIRSTROW = 1,              -- no header row
    FIELDTERMINATOR = ',',     -- CSV delimiter
    ROWTERMINATOR = '\n',
    TABLOCK
);
GO

-- Load PractitionerType data
BULK INSERT PractitionerType
FROM 'C:\temp\CSV_DataFiles\PractitionerTypeData.csv'
WITH (
    FIRSTROW = 1,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TABLOCK
);
GO

-- Load Practitioner data
BULK INSERT Practitioner
FROM 'C:\temp\CSV_DataFiles\PractitionerData.csv'
WITH (
    FIRSTROW = 1,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TABLOCK
);
GO

-- Load WeekDays data
BULK INSERT WeekDays
FROM 'C:\temp\CSV_DataFiles\WeekDaysData.csv'
WITH (
    FIRSTROW = 1,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TABLOCK
);
GO

-- Load Availability data
BULK INSERT Availability
FROM 'C:\temp\CSV_DataFiles\AvailabilityData.csv'
WITH (
    FIRSTROW = 1,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TABLOCK
);
GO

-- Load Appointment data
BULK INSERT Appointment
FROM 'C:\temp\CSV_DataFiles\AppointmentData.csv'
WITH (
    FIRSTROW = 1,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TABLOCK
);
GO

/* ======================================
   End of Part 1 Script
   ====================================== */

/* ========================================================================================
   File: Amir_Sharabiani_Queries.sql
   Part 2 - Task 2: Write SQL queries
   ======================================================================================== */

USE MedicalPractice;
GO

/* 1. Female patients in St Kilda or Lidcombe */
SELECT
  p.Patient_ID AS 'Patiet ID',
  p.FirstName AS 'First Name',
  p.LastName AS 'Last Name'
FROM Patient AS p
WHERE p.Gender = N'female'
  AND p.Suburb IN (N'St Kilda', N'Lidcombe');

/* 2. Patients not living in NSW (show FirstName, LastName, State, MedicareNumber) */
SELECT
  p.Patient_ID AS 'Patiet ID',
  p.FirstName AS 'First Name',
  p.LastName AS 'Last Name',
  p.State,
  p.MedicareNumber AS 'Medicare Number'
FROM Patient AS p
WHERE p.State <> N'NSW';

/* 3. Patients with MedicareNumber and DOB, youngest first */
SELECT
  p.Patient_ID AS 'Patiet ID',
  p.FirstName AS 'First Name',
  p.LastName AS 'Last Name',
  p.MedicareNumber AS 'Medicare Number',
  p.DateOfBirth AS 'Date Of Birth'
FROM Patient AS p
ORDER BY p.DateOfBirth DESC;  -- youngest first

/* 4. Practitioner weekly availability: total days and hours (9 hours/day) */
SELECT
  pr.Practitioner_ID AS 'Practitioner ID',
  pr.FirstName AS 'First Name',
  pr.LastName AS 'Last Name',
  COUNT(a.WeekDayName_Ref) AS 'Total Days',
  COUNT(a.WeekDayName_Ref) * 9 AS 'Total Hours'
FROM Practitioner AS pr
LEFT JOIN Availability AS a
  ON a.Practitioner_Ref = pr.Practitioner_ID
GROUP BY
  pr.Practitioner_ID,
  pr.FirstName,
  pr.LastName
ORDER BY pr.Practitioner_ID;

/* 5. Appointments on 18/09/2019 by Dr Anne Funsworth (show patient name, date, time) */
SELECT
  p.Patient_ID AS 'Patiet ID',
  p.FirstName AS "Patient's First Name",
  p.LastName  AS "Patient's Last Name",
  ap.AppDate AS 'Appointment Date',
  ap.AppStartTime AS 'Appointment Start Time'
FROM Appointment AS ap
JOIN Practitioner AS pr
  ON pr.Practitioner_ID = ap.Practitioner_Ref
JOIN Patient AS p
  ON p.Patient_ID = ap.Patient_Ref
WHERE ap.AppDate = '2019-09-18'
  AND pr.Title = N'Dr'
  AND pr.FirstName = N'Anne'
  AND pr.LastName  = N'Funsworth'
ORDER BY ap.AppStartTime;

/* 6. Patients with no appointments and born before 1950 */
SELECT
  p.Patient_ID AS 'Patiet ID',
  p.DateOfBirth AS 'Date Of Birth'
FROM Patient AS p
LEFT JOIN Appointment AS ap
  ON ap.Patient_Ref = p.Patient_ID
WHERE ap.Patient_Ref IS NULL
  AND p.DateOfBirth < '1950-01-01'
ORDER BY p.Patient_ID;

/* 7. Patients with at least three appointments, ordered by number desc */
SELECT
  p.Patient_ID AS 'Patiet ID',
  p.FirstName AS 'First Name',
  p.LastName AS 'Last Name',
  COUNT(*) AS 'Number Of Appointments'
FROM Patient AS p
JOIN Appointment AS ap
  ON ap.Patient_Ref = p.Patient_ID
GROUP BY
  p.Patient_ID,
  p.FirstName,
  p.LastName
HAVING COUNT(*) >= 3
ORDER BY 'Number Of Appointments' DESC, p.Patient_ID DESC;

/* 8.	List the first name, last name, gender, and the number of days since the last appointment of each patient and 23/09/2019. */
SELECT
  p.Patient_ID AS 'Patient ID',
  p.FirstName AS 'First Name',
  p.LastName AS 'Last Name',
  p.Gender,
  DATEDIFF(day, (
    SELECT MAX(ap.AppDate)
    FROM Appointment AS ap
    WHERE ap.Patient_Ref = p.Patient_ID
  ), '2019-09-23') AS 'Days Since Last Appointment'
FROM Patient AS p
ORDER BY 'Days Since Last Appointment' DESC,'Patient ID' DESC;

-- Testing one of the patient's appointment date to see if we got a right result.
SELECT
  p.Patient_ID,
  ap.AppDate
FROM Patient as p
JOIN Appointment AS ap
  ON ap.Patient_Ref = p.Patient_ID
WHERE p.Patient_ID = '10000'

/* 9.	List the full name and full address of each practitioner in the following format exactly.
Dr Mark P. Huston. 21 Fuller Street SUNSHINE, NSW 2343
Make sure you include the punctuation and the suburb in upper case.
Sort the list by last name, then first name, then middle initial.
 */
SELECT
  pr.Title + ' ' +
  pr.FirstName + ' ' +
  ISNULL(pr.MiddleInitial + '. ', '') +
  pr.LastName + '. ' +
  pr.HouseUnitLotNum + ' ' + pr.Street + ' ' +
  UPPER(pr.Suburb) + ', ' + pr.State + ' ' + pr.PostCode
    AS 'Practitioner Full Name And Address'
FROM Practitioner AS pr
ORDER BY pr.LastName, pr.FirstName, pr.MiddleInitial;

/* 10.	List the patient id, first name, last name and date of birth of the fifth oldest patient(s).  */
SELECT Patient_ID, FirstName, LastName, DateOfBirth
FROM Patient
WHERE DateOfBirth = (
    SELECT MAX(DateOfBirth)     -- youngest among the top 5 of oldests
    FROM (
        SELECT TOP 5 DateOfBirth
        FROM Patient
        ORDER BY DateOfBirth ASC   -- oldest first
    ) AS Top5
);

-- Checking maually
SELECT Patient_ID, FirstName, LastName, DateOfBirth FROM Patient ORDER BY DateOfBirth ASC;

/* 11.	List the patient ID, first name, last name, appointment date (in the format 
'Tuesday 17 September, 2019') and appointment time (in the format '14:15 PM') for 
all patients who have had appointments on any Tuesday after 10:00 AM. */
SELECT
  p.Patient_ID AS 'Patient ID',
  p.FirstName AS 'First Name',
  p.LastName AS 'Last Name',
  FORMAT(ap.AppDate, 'dddd d MMMM, yyyy') AS 'Appointment Date Formatted', -- dddd = Weekday like Monday, d = Day of the month like 17, MMMM = Full month name, yyyy = Full year; ddd = Mon or Tue
  CASE      -- CASE is like if; (CASE - THEN - ELSE)
    WHEN CAST(LEFT(CONVERT(VARCHAR(8), ap.AppStartTime, 108), 2) AS INT) < 12
      THEN LEFT(CONVERT(VARCHAR(8), ap.AppStartTime, 108), 5) + ' AM'
    ELSE 
      RIGHT('0' + CAST( -- take the 14 and subtract 12 out of it then add a 0 before it to get 02. just in case if the number was like 22 - 12 = 10, only take the 2 right digits of it so 0(10)
        CAST(LEFT(CONVERT(VARCHAR(8), ap.AppStartTime, 108), 2) AS INT) - 12 
        AS VARCHAR(2)), 2) 
      + SUBSTRING(CONVERT(VARCHAR(8), ap.AppStartTime, 108), 3, 3) + ' PM'    -- Add the minutes part from 14:30:00 where start from 3 (:) till 3 after including itself (0). Convert it to VARCHAR to be able to use the add operator.
  END AS 'Appointment Time Formatted'
FROM Appointment AS ap
JOIN Patient AS p
  ON p.Patient_ID = ap.Patient_Ref
WHERE DATENAME(WEEKDAY, ap.AppDate) = 'Tuesday'
  AND ap.AppStartTime > '10:00:00'
ORDER BY ap.AppDate, ap.AppStartTime, p.LastName, p.FirstName;


/* 12.	Create an address list for a special newsletter to all patients 
and practitioners. The mailing list should contain all relevant address 
fields for each household. Note that each household should only receive 
one newsletter. */

-- Create Table --
CREATE TABLE dbo.NewsletterAddresses (
  PersonID INT,
  FirstName NVARCHAR(50),
  LastName NVARCHAR(50),
  HomePhone NCHAR(10),
  MobilePhone NCHAR(10),
  HouseUnitLotNum NVARCHAR(5),
  Street NVARCHAR(50),
  Suburb NVARCHAR(50),
  State NVARCHAR(20),
  PostCode NCHAR(4)
);

-- Insert Data --
INSERT INTO NewsletterAddresses (
  PersonID, FirstName, LastName, HomePhone, MobilePhone,
  HouseUnitLotNum, Street, Suburb, State, PostCode
)
SELECT 
  p.Patient_ID, p.FirstName, p.LastName, p.HomePhone, p.MobilePhone,
  p.HouseUnitLotNum, p.Street, p.Suburb, p.State, p.PostCode
FROM Patient AS p

UNION

SELECT 
  pr.Practitioner_ID, pr.FirstName, pr.LastName, pr.HomePhone, pr.MobilePhone,
  pr.HouseUnitLotNum, pr.Street, pr.Suburb, pr.State, pr.PostCode
FROM Practitioner AS pr;

-- Query the new Table
SELECT
  PersonID AS 'Person ID',
  FirstName AS 'First Name',
  LastName AS 'Last Name',
  HomePhone AS 'Home Phone',
  MobilePhone AS 'Mobile Phone',
  HouseUnitLotNum AS 'House Unit Lot Number',
  Street,
  Suburb,
  State,
  PostCode AS 'Post Code'
FROM dbo.NewsletterAddresses
ORDER BY PostCode, Suburb, Street, HouseUnitLotNum, LastName, FirstName;


/*  ======================================
    End of Part 2 Script
    ====================================== */

/*  ========================================================================================
    File: Amir_Sharabiani_ViewsSP.sql
    Part 3 - Views, Stored Procedures, Triggers, Security, Cleanup
    ======================================================================================== */

USE MedicalPractice;
GO

/* ======================================
   Task 1: Views
   ====================================== */

/* 1. vwNurseDays: name + phone of any nurse (registered or not) and days they work */
CREATE OR ALTER VIEW vwNurseDays
AS
SELECT
  pr.Practitioner_ID,
  pr.Title,
  pr.FirstName,
  pr.MiddleInitial,
  pr.LastName,
  pr.HomePhone,
  pr.MobilePhone,
  a.WeekDayName_Ref AS WorkDay
FROM Practitioner AS pr
JOIN Availability AS a
  ON a.Practitioner_Ref = pr.Practitioner_ID
WHERE pr.PractitionerType_Ref IN ('Nurse', 'Registered nurse', 'Enrolled nurse');
GO

/* 2. Query using vwNurseDays: nurses who work on Wednesday */
SELECT
  FirstName, LastName,
  HomePhone, MobilePhone, WorkDay
FROM vwNurseDays
WHERE WorkDay = 'Wednesday'
ORDER BY LastName, FirstName, MiddleInitial;
GO

/* 3. vwNSWPatients: all patient details where State = NSW */
CREATE OR ALTER VIEW vwNSWPatients
AS SELECT * FROM Patient
WHERE State = 'NSW';
GO

/* ======================================
   Task 2: Stored procedures
   ====================================== */

/* 4. spSelect_vwNSWPatients: select all from view ordered by PostCode ascending */
CREATE OR ALTER PROCEDURE spSelect_vwNSWPatients AS
SELECT * FROM vwNSWPatients ORDER BY PostCode;

/* Execute */
EXEC spSelect_vwNSWPatients;
GO

/* 5. spInsert_vwNSWPatients: insert a new NSW patient via the view */
CREATE OR ALTER PROCEDURE spInsert_vwNSWPatients
  @Title NVARCHAR(20),
  @FirstName NVARCHAR(50),
  @MiddleInitial NCHAR(1) = NULL,
  @LastName NVARCHAR(50),
  @HouseUnitLotNum NVARCHAR(5),
  @Street NVARCHAR(50),
  @Suburb NVARCHAR(50),
  @PostCode NCHAR(4),
  @HomePhone NCHAR(10) = NULL,
  @MobilePhone NCHAR(10) = NULL,
  @MedicareNumber NCHAR(16) = NULL,
  @DateOfBirth DATE,
  @Gender NVARCHAR(20)
AS
BEGIN
  SET NOCOUNT ON;

  /* Generate a new Patient_ID (since not identity) */
  DECLARE @NewPatientID INT =
    (SELECT MAX(Patient_ID)+1 FROM Patient);

  INSERT INTO Patient (
    Patient_ID, Title, FirstName, MiddleInitial, LastName,
    HouseUnitLotNum, Street, Suburb, State, PostCode,
    HomePhone, MobilePhone, MedicareNumber, DateOfBirth, Gender
  )
  VALUES (
    @NewPatientID, @Title, @FirstName, @MiddleInitial, @LastName,
    @HouseUnitLotNum, @Street, @Suburb, 'NSW', @PostCode,
    @HomePhone, @MobilePhone, @MedicareNumber, @DateOfBirth, @Gender
  );
END
GO

/* Execute: Mr Mickey M Mouse at 1 Smith St, Smithville, NSW 2222 */
EXEC spInsert_vwNSWPatients
  @Title = 'Mr',
  @FirstName = 'Mickey',
  @MiddleInitial = 'M',
  @LastName = 'Mouse',
  @HouseUnitLotNum = '1',
  @Street = 'Smith St',
  @Suburb = 'Smithville',
  @PostCode = '2222',
  @HomePhone = NULL,
  @MobilePhone = NULL,
  @MedicareNumber = NULL,
  @DateOfBirth = '1970-01-01',
  @Gender = 'male';
GO

/* 6. spModify_PractitionerMobilePhone: update mobile by Practitioner_ID */
CREATE OR ALTER PROCEDURE spModify_PractitionerMobilePhone
  @Practitioner_ID INT,
  @NewMobile       NCHAR(10)
AS
UPDATE Practitioner SET MobilePhone = @NewMobile 
WHERE Practitioner_ID = @Practitioner_ID;


/* Execute: change Hilda Browns mobile to 0412345678 */
DECLARE @HildaID INT;

SELECT @HildaID = Practitioner_ID
FROM Practitioner
WHERE FirstName = 'Hilda' AND LastName = 'Brown';

EXEC spModify_PractitionerMobilePhone
  @Practitioner_ID = @HildaID,
  @NewMobile = '0412345678';
GO

/* 7. Verify update */
SELECT Practitioner_ID, FirstName, LastName, MobilePhone
FROM Practitioner
WHERE FirstName = 'Hilda' AND LastName = 'Brown';

/* ======================================
   Task 3: Triggers
   ====================================== */

/* 8a. Add LastContactDate (DATE) to Patient with default = record creation date */
ALTER TABLE Patient
ADD LastContactDate DATE
    CONSTRAINT DF_Patient_LastContactDate DEFAULT (CAST(GETDATE() AS DATE));
GO

/* 8b. Trigger: update LastContactDate on Patient when Appointment inserted */
CREATE OR ALTER TRIGGER tr_Appointment_AfterInsert
ON Appointment
AFTER INSERT
AS
UPDATE Patient
SET LastContactDate = CAST(GETDATE() AS DATE)
FROM Patient AS p
JOIN inserted AS i ON p.Patient_ID = i.Patient_Ref;

-- Test trigger: insert a new appointment
INSERT INTO Appointment (Patient_Ref, Practitioner_Ref, AppDate, AppStartTime)
VALUES (10003, 10004, CAST(GETDATE() AS DATE), CAST(GETDATE() AS TIME));

-- See the changes
SELECT Patient_ID, FirstName, LastName, LastContactDate
FROM Patient
WHERE Patient_ID = 10003;

/* ======================================
   Task 4: Security
   ====================================== */

-- 9a. Add DriversLicenceHash column
ALTER TABLE Practitioner ADD DriversLicenceHash VARBINARY(64);

-- 9b. Hash and store "1066AD" for Dr Ludo Vergenargen (ID 10005)
UPDATE Practitioner
SET DriversLicenceHash = HASHBYTES('SHA2_256', N'1066AD')
WHERE Practitioner_ID = 10005;

-- 9c. Display record
SELECT Practitioner_ID, FirstName, LastName, DriversLicenceHash
FROM Practitioner
WHERE Practitioner_ID = 10005;

/* ======================================
   Task 5: Cleanup
   ====================================== */

/* 10. Delete view vwNurseDays */
DROP VIEW IF EXISTS vwNurseDays;
GO

/* 11. Delete stored procedure spSelect_vwNSWPatients */
DROP PROCEDURE IF EXISTS spSelect_vwNSWPatients;
GO

/* ============================================================
   End of Part 3 Script
   ============================================================ */

/* Dropping the whole database so you can easily assess other scripts after this */
USE master;
GO
IF DB_ID(N'MedicalPractice') IS NOT NULL
BEGIN
    ALTER DATABASE MedicalPractice SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE MedicalPractice;
END;
GO

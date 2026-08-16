
CREATE DATABASE Hospital_Analytics_DW;

USE Hospital_Analytics_DW;

SELECT DB_NAME() AS CurrentDatabase;

--Check the row count
SELECT COUNT(*) AS TotalRows
FROM dbo.stg_patient_encounter;

--Check duplicate Patient IDs
SELECT 
    Patient_Id,
    COUNT(*) AS RecordCount
FROM dbo.stg_patient_encounter
GROUP BY Patient_Id
HAVING COUNT(*) > 1;

-- Check NULL values in important columns
SELECT
    SUM(CASE WHEN Patient_Id IS NULL THEN 1 ELSE 0 END) 
        AS Null_Patient_Id,

    SUM(CASE WHEN Department_Referral IS NULL THEN 1 ELSE 0 END) 
        AS Null_Department_Referral,

    SUM(CASE WHEN Patient_Satisfaction_Score IS NULL THEN 1 ELSE 0 END) 
        AS Null_Satisfaction_Score

FROM dbo.stg_patient_encounter;

-- Check Gender values
SELECT 
    Patient_Gender,
    COUNT(*) AS PatientCount
FROM dbo.stg_patient_encounter
GROUP BY Patient_Gender
ORDER BY PatientCount DESC;


-- Check Admission Flag values
SELECT
    Patient_Admission_Flag,
    COUNT(*) AS PatientCount
FROM dbo.stg_patient_encounter
GROUP BY Patient_Admission_Flag
ORDER BY PatientCount DESC;


-- Check Department Referral values
SELECT
    Department_Referral,
    COUNT(*) AS PatientCount
FROM dbo.stg_patient_encounter
GROUP BY Department_Referral
ORDER BY PatientCount DESC;

-- Create Department Dimension
CREATE TABLE dbo.dim_department (
    DepartmentKey INT IDENTITY(1,1) NOT NULL,
    DepartmentReferral NVARCHAR(50) NOT NULL,

    CONSTRAINT PK_dim_department
        PRIMARY KEY (DepartmentKey),

    CONSTRAINT UQ_dim_department_referral
        UNIQUE (DepartmentReferral)
);

-- Load unique departments from staging table
INSERT INTO dbo.dim_department (DepartmentReferral)
SELECT DISTINCT Department_Referral
FROM dbo.stg_patient_encounter;

-- Validate Department Dimension
SELECT *
FROM dbo.dim_department
ORDER BY DepartmentKey;

-- Check admission date range
SELECT
    MIN(Patient_Admission_Date) AS MinAdmissionDate,
    MAX(Patient_Admission_Date) AS MaxAdmissionDate
FROM dbo.stg_patient_encounter;

-- Create Calendar Dimension
CREATE TABLE dbo.dim_calendar (
    DateKey INT NOT NULL,
    [Date] DATE NOT NULL,
    [Year] INT NOT NULL,
    QuarterNumber INT NOT NULL,
    MonthNumber INT NOT NULL,
    MonthName NVARCHAR(20) NOT NULL,
    MonthYear NVARCHAR(20) NOT NULL,
    DayOfMonth INT NOT NULL,
    DayOfWeekNumber INT NOT NULL,
    DayName NVARCHAR(20) NOT NULL,
    DayType NVARCHAR(10) NOT NULL,

    CONSTRAINT PK_dim_calendar
        PRIMARY KEY (DateKey),

    CONSTRAINT UQ_dim_calendar_date
        UNIQUE ([Date])
);

SELECT *
FROM dbo.dim_calendar;

-- Populate Calendar Dimension
WITH DateSeries AS (
    SELECT CAST('2023-01-01' AS DATE) AS [Date]

    UNION ALL

    SELECT DATEADD(DAY, 1, [Date])
    FROM DateSeries
    WHERE [Date] < '2024-12-31'
)
INSERT INTO dbo.dim_calendar (
    DateKey,
    [Date],
    [Year],
    QuarterNumber,
    MonthNumber,
    MonthName,
    MonthYear,
    DayOfMonth,
    DayOfWeekNumber,
    DayName,
    DayType
)
SELECT
    CONVERT(INT, CONVERT(CHAR(8), [Date], 112)) AS DateKey,
    [Date],
    YEAR([Date]) AS [Year],
    DATEPART(QUARTER, [Date]) AS QuarterNumber,
    MONTH([Date]) AS MonthNumber,
    DATENAME(MONTH, [Date]) AS MonthName,
    FORMAT([Date], 'MMM yyyy') AS MonthYear,
    DAY([Date]) AS DayOfMonth,
    DATEPART(WEEKDAY, [Date]) AS DayOfWeekNumber,
    DATENAME(WEEKDAY, [Date]) AS DayName,
    CASE
        WHEN DATENAME(WEEKDAY, [Date]) IN ('Saturday', 'Sunday')
            THEN 'Weekend'
        ELSE 'Weekday'
    END AS DayType
FROM DateSeries
OPTION (MAXRECURSION 1000);

SELECT COUNT(*) AS CalendarRows
FROM dbo.dim_calendar;

SELECT TOP 10 *
FROM dbo.dim_calendar
ORDER BY [Date];

SELECT TOP 10 *
FROM dbo.dim_calendar
ORDER BY [Date] DESC;

-- Create Patient Dimension
CREATE TABLE dbo.dim_patient (
    PatientKey INT IDENTITY(1,1) NOT NULL,
    PatientId NVARCHAR(50) NOT NULL,
    PatientGender NVARCHAR(50) NOT NULL,
    PatientAge TINYINT NOT NULL,
    PatientRace NVARCHAR(50) NOT NULL,
    AgeGroup NVARCHAR(50) NOT NULL,

    CONSTRAINT PK_dim_patient
        PRIMARY KEY (PatientKey),

    CONSTRAINT UQ_dim_patient_id
        UNIQUE (PatientId)
);

SELECT *
FROM dbo.dim_patient;

-- Load Patient Dimension
INSERT INTO dbo.dim_patient (
    PatientId,
    PatientGender,
    PatientAge,
    PatientRace,
    AgeGroup
)
SELECT
    Patient_Id,
    Patient_Gender,
    Patient_Age,
    Patient_Race,
    Age_Group
FROM dbo.stg_patient_encounter;

-- Check Patient Dimension row count
SELECT COUNT(*) AS PatientCount
FROM dbo.dim_patient;

-- View sample patient records
SELECT TOP 10 *
FROM dbo.dim_patient
ORDER BY PatientKey;

-- Check for admission dates missing from Calendar Dimension
SELECT COUNT(*) AS MissingCalendarDates
FROM dbo.stg_patient_encounter s
LEFT JOIN dbo.dim_calendar c
    ON s.Patient_Admission_Date = c.[Date]
WHERE c.DateKey IS NULL;

-- Create Patient Encounter Fact Table
CREATE TABLE dbo.fact_patient_encounter (
    EncounterKey INT IDENTITY(1,1) NOT NULL,

    PatientKey INT NOT NULL,
    AdmissionDateKey INT NOT NULL,
    DepartmentKey INT NOT NULL,

    AdmissionTime TIME NOT NULL,
    AdmissionHour TINYINT NOT NULL,
    AdmissionFlag NVARCHAR(50) NOT NULL,
    WaitTime TINYINT NOT NULL,
    SatisfactionScore FLOAT NULL,

    CONSTRAINT PK_fact_patient_encounter
        PRIMARY KEY (EncounterKey)
);

SELECT *
FROM dbo.fact_patient_encounter;

-- Preview Fact Table Mapping
SELECT TOP 10
    s.Patient_Id,
    p.PatientKey,

    s.Patient_Admission_Date,
    c.DateKey AS AdmissionDateKey,

    s.Department_Referral,
    d.DepartmentKey,

    s.Patient_Admission_Time,
    s.Admission_Hour,
    s.Patient_Admission_Flag,
    s.Patient_Waittime,
    s.Patient_Satisfaction_Score

FROM dbo.stg_patient_encounter s

INNER JOIN dbo.dim_patient p
    ON s.Patient_Id = p.PatientId

INNER JOIN dbo.dim_calendar c
    ON s.Patient_Admission_Date = c.[Date]

INNER JOIN dbo.dim_department d
    ON s.Department_Referral = d.DepartmentReferral;

-- Load Patient Encounter Fact Table
INSERT INTO dbo.fact_patient_encounter (
    PatientKey,
    AdmissionDateKey,
    DepartmentKey,
    AdmissionTime,
    AdmissionHour,
    AdmissionFlag,
    WaitTime,
    SatisfactionScore
)
SELECT
    p.PatientKey,
    c.DateKey,
    d.DepartmentKey,
    s.Patient_Admission_Time,
    s.Admission_Hour,
    s.Patient_Admission_Flag,
    s.Patient_Waittime,
    s.Patient_Satisfaction_Score
FROM dbo.stg_patient_encounter s

INNER JOIN dbo.dim_patient p
    ON s.Patient_Id = p.PatientId

INNER JOIN dbo.dim_calendar c
    ON s.Patient_Admission_Date = c.[Date]

INNER JOIN dbo.dim_department d
    ON s.Department_Referral = d.DepartmentReferral;

-- Validate Fact Table row count
SELECT COUNT(*) AS FactRowCount
FROM dbo.fact_patient_encounter;

-- Foreign Key: Fact → Patient Dimension
ALTER TABLE dbo.fact_patient_encounter
ADD CONSTRAINT FK_fact_patient
FOREIGN KEY (PatientKey)
REFERENCES dbo.dim_patient(PatientKey);

-- Foreign Key: Fact → Calendar Dimension
ALTER TABLE dbo.fact_patient_encounter
ADD CONSTRAINT FK_fact_calendar
FOREIGN KEY (AdmissionDateKey)
REFERENCES dbo.dim_calendar(DateKey);

-- Foreign Key: Fact → Department Dimension
ALTER TABLE dbo.fact_patient_encounter
ADD CONSTRAINT FK_fact_department
FOREIGN KEY (DepartmentKey)
REFERENCES dbo.dim_department(DepartmentKey);

-- Verify Foreign Key Relationships
SELECT
    fk.name AS ForeignKeyName,
    OBJECT_NAME(fk.parent_object_id) AS FactTable,
    COL_NAME(fkc.parent_object_id, fkc.parent_column_id) AS FactColumn,
    OBJECT_NAME(fk.referenced_object_id) AS DimensionTable,
    COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id) AS DimensionColumn
FROM sys.foreign_keys fk
INNER JOIN sys.foreign_key_columns fkc
    ON fk.object_id = fkc.constraint_object_id
WHERE fk.parent_object_id = OBJECT_ID('dbo.fact_patient_encounter');

-- Validate Fact Table
SELECT
    COUNT(*) AS TotalEncounters,
    COUNT(DISTINCT PatientKey) AS UniquePatients,
    MIN(WaitTime) AS MinWaitTime,
    MAX(WaitTime) AS MaxWaitTime,
    AVG(CAST(WaitTime AS DECIMAL(10,2))) AS AvgWaitTime,
    COUNT(SatisfactionScore) AS SatisfactionResponses
FROM dbo.fact_patient_encounter;

-- Validate Fact-to-Dimension Relationships
SELECT
    COUNT(*) AS JoinedRowCount
FROM dbo.fact_patient_encounter f

INNER JOIN dbo.dim_patient p
    ON f.PatientKey = p.PatientKey

INNER JOIN dbo.dim_calendar c
    ON f.AdmissionDateKey = c.DateKey

INNER JOIN dbo.dim_department d
    ON f.DepartmentKey = d.DepartmentKey;

-- Patient Encounters by Department
SELECT
    d.DepartmentReferral,
    COUNT(*) AS TotalEncounters
FROM dbo.fact_patient_encounter f
INNER JOIN dbo.dim_department d
    ON f.DepartmentKey = d.DepartmentKey
GROUP BY d.DepartmentReferral
ORDER BY TotalEncounters DESC;

-- Department Performance Analysis
SELECT
    d.DepartmentReferral,
    COUNT(*) AS TotalEncounters,
    AVG(CAST(f.WaitTime AS DECIMAL(10,2))) AS AvgWaitTime,
    ROUND(AVG(f.SatisfactionScore),2) AS AvgSatisfactionScore,
    COUNT(f.SatisfactionScore) AS SatisfactionResponses
FROM dbo.fact_patient_encounter f
INNER JOIN dbo.dim_department d
    ON f.DepartmentKey = d.DepartmentKey
GROUP BY d.DepartmentReferral
ORDER BY TotalEncounters DESC;

-- Performance by Admission Status
SELECT
    AdmissionFlag,
    COUNT(*) AS TotalEncounters,
    ROUND(
        AVG(CAST(WaitTime AS DECIMAL(10,2))),
        2
    ) AS AvgWaitTime,
    ROUND(
        AVG(SatisfactionScore),
        2
    ) AS AvgSatisfactionScore,
    COUNT(SatisfactionScore) AS SatisfactionResponses
FROM dbo.fact_patient_encounter
GROUP BY AdmissionFlag
ORDER BY TotalEncounters DESC;

-- Performance by Time of Day
SELECT
    CASE
        WHEN AdmissionHour BETWEEN 0 AND 5 THEN 'Night'
        WHEN AdmissionHour BETWEEN 6 AND 11 THEN 'Morning'
        WHEN AdmissionHour BETWEEN 12 AND 17 THEN 'Afternoon'
        ELSE 'Evening'
    END AS TimeOfDay,

    COUNT(*) AS TotalEncounters,

    ROUND(
        AVG(CAST(WaitTime AS DECIMAL(10,2))),
        2
    ) AS AvgWaitTime,

    ROUND(
        AVG(SatisfactionScore),
        2
    ) AS AvgSatisfactionScore

FROM dbo.fact_patient_encounter

GROUP BY
    CASE
        WHEN AdmissionHour BETWEEN 0 AND 5 THEN 'Night'
        WHEN AdmissionHour BETWEEN 6 AND 11 THEN 'Morning'
        WHEN AdmissionHour BETWEEN 12 AND 17 THEN 'Afternoon'
        ELSE 'Evening'
    END

ORDER BY TotalEncounters DESC;

-- Monthly Patient Encounter Trend
SELECT
    c.[Year],
    c.MonthNumber,
    c.MonthName,
    c.MonthYear,
    COUNT(*) AS TotalEncounters,
    ROUND(
        AVG(CAST(f.WaitTime AS DECIMAL(10,2))),
        2
    ) AS AvgWaitTime
FROM dbo.fact_patient_encounter f
INNER JOIN dbo.dim_calendar c
    ON f.AdmissionDateKey = c.DateKey
GROUP BY
    c.[Year],
    c.MonthNumber,
    c.MonthName,
    c.MonthYear
ORDER BY
    c.[Year],
    c.MonthNumber;

-- Weekday vs Weekend Performance
SELECT
    c.DayType,
    COUNT(*) AS TotalEncounters,

    ROUND(
        AVG(CAST(f.WaitTime AS DECIMAL(10,2))),
        2
    ) AS AvgWaitTime,

    ROUND(
        AVG(f.SatisfactionScore),
        2
    ) AS AvgSatisfactionScore,

    COUNT(f.SatisfactionScore) AS SatisfactionResponses

FROM dbo.fact_patient_encounter f

INNER JOIN dbo.dim_calendar c
    ON f.AdmissionDateKey = c.DateKey

GROUP BY c.DayType
ORDER BY TotalEncounters DESC;

-- Performance by Age Group
SELECT
    p.AgeGroup,
    COUNT(*) AS TotalEncounters,

    ROUND(
        AVG(CAST(f.WaitTime AS DECIMAL(10,2))),
        2
    ) AS AvgWaitTime,

    ROUND(
        AVG(f.SatisfactionScore),
        2
    ) AS AvgSatisfactionScore,

    COUNT(f.SatisfactionScore) AS SatisfactionResponses

FROM dbo.fact_patient_encounter f

INNER JOIN dbo.dim_patient p
    ON f.PatientKey = p.PatientKey

GROUP BY p.AgeGroup
ORDER BY TotalEncounters DESC;

-- Overall Hospital Operations KPIs
SELECT
    COUNT(*) AS TotalEncounters,

    SUM(
        CASE WHEN AdmissionFlag = 'Admission'
        THEN 1 ELSE 0 END
    ) AS TotalAdmissions,

    ROUND(
        100.0 *
        SUM(CASE WHEN AdmissionFlag = 'Admission'
                 THEN 1 ELSE 0 END)
        / COUNT(*),
        2
    ) AS AdmissionRatePct,

    ROUND(
        AVG(CAST(WaitTime AS DECIMAL(10,2))),
        2
    ) AS AvgWaitTime,

    ROUND(
        AVG(SatisfactionScore),
        2
    ) AS AvgSatisfactionScore,

    COUNT(SatisfactionScore) AS SatisfactionResponses,

    ROUND(
        100.0 * COUNT(SatisfactionScore) / COUNT(*),
        2
    ) AS SatisfactionResponseRatePct

FROM dbo.fact_patient_encounter;


-- Final Data Warehouse Validation
SELECT 'Staging' AS TableName, COUNT(*) AS TotalRows
FROM dbo.stg_patient_encounter

UNION ALL

SELECT 'Patient Dimension', COUNT(*)
FROM dbo.dim_patient

UNION ALL

SELECT 'Calendar Dimension', COUNT(*)
FROM dbo.dim_calendar

UNION ALL

SELECT 'Department Dimension', COUNT(*)
FROM dbo.dim_department

UNION ALL

SELECT 'Encounter Fact', COUNT(*)
FROM dbo.fact_patient_encounter;








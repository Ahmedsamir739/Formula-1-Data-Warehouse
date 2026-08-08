/*
===============================================================================
Description: Silver Layer Table Creation Script
===============================================================================
This script initializes the schema and tables for the 'silver' layer within the 
Data Warehouse architecture[cite: 4].

Key Architecture & Data Transformations:
-------------------------------------------------------------------------------
1. Idempotency (Safe Table Creation):
   - Every block checks `IF OBJECT_ID('silver.<table_name>', 'U') IS NOT NULL` 
     and drops the existing table before re-creating[cite: 4].

2. Strongly-Typed Data Schema:
   - Unlike the Bronze layer (which stores data raw as VARCHARs), the Silver layer 
     enforces proper data types[cite: 4]:
     * Primary / Foreign Keys & Counts: `INT`[cite: 4]
     * Numerical / Scoring Data: `DECIMAL(6, 2)` & `DECIMAL(6, 3)`[cite: 4]
     * Geographical Coordinates: `DECIMAL(10, 6)`[cite: 4]
     * Strings / Unicode Text: `NVARCHAR`[cite: 4]
     * Dates & Timings: `DATE` and `TIME`[cite: 4]

3. Audit Metadata (`dwh_create_date`):
   - Every table includes a metadata tracking column: 
     `dwh_create_date DATETIME2 DEFAULT SYSUTCDATETIME()`[cite: 4]
   - Captures the exact UTC timestamp when a record is inserted into Silver[cite: 4].
===============================================================================
*/
-- 1. CIRCUITS
IF OBJECT_ID('silver.circuits', 'U') IS NOT NULL
    DROP TABLE silver.circuits;
CREATE TABLE silver.circuits (
    circuitId       INT,
    circuitRef      NVARCHAR(100),
    name            NVARCHAR(200),
    location        NVARCHAR(100),
    country         NVARCHAR(100),
    lat             DECIMAL(10, 6),
    lng             DECIMAL(10, 6),
    alt             INT,
    url             NVARCHAR(500),
    dwh_create_date DATETIME2 DEFAULT SYSUTCDATETIME()
);
GO

-- 2. CONSTRUCTOR_RESULTS
IF OBJECT_ID('silver.constructor_results', 'U') IS NOT NULL
    DROP TABLE silver.constructor_results;
CREATE TABLE silver.constructor_results (
    constructorResultsId    INT,
    raceId                  INT,
    constructorId           INT,
    points                  DECIMAL(6, 2),
    status                  NVARCHAR(20),
    dwh_create_date         DATETIME2 DEFAULT SYSUTCDATETIME()
);
GO

-- 3. CONSTRUCTOR_STANDINGS
IF OBJECT_ID('silver.constructor_standings', 'U') IS NOT NULL
    DROP TABLE silver.constructor_standings;
CREATE TABLE silver.constructor_standings (
    constructorStandingsId  INT,
    raceId                  INT,
    constructorId           INT,
    points                  DECIMAL(6, 2),
    position                INT,
    positionText            NVARCHAR(100),
    wins                    INT,
    dwh_create_date         DATETIME2 DEFAULT SYSUTCDATETIME()
);
GO

-- 4. CONSTRUCTORS
IF OBJECT_ID('silver.constructors', 'U') IS NOT NULL
    DROP TABLE silver.constructors;
CREATE TABLE silver.constructors (
    constructorId   INT,
    constructorRef  NVARCHAR(100),
    name            NVARCHAR(100),
    nationality     NVARCHAR(100),
    url             NVARCHAR(500),
    dwh_create_date DATETIME2 DEFAULT SYSUTCDATETIME()
);
GO

-- 5. DRIVER_STANDINGS
IF OBJECT_ID('silver.driver_standings', 'U') IS NOT NULL
    DROP TABLE silver.driver_standings;
CREATE TABLE silver.driver_standings (
    driverStandingsId   INT,
    raceId              INT,
    driverId            INT,
    points              DECIMAL(6, 2),
    position            INT,
    positionText        NVARCHAR(100),
    wins                INT,
    dwh_create_date     DATETIME2 DEFAULT SYSUTCDATETIME()
);
GO

-- 6. DRIVERS
IF OBJECT_ID('silver.drivers', 'U') IS NOT NULL
    DROP TABLE silver.drivers;
CREATE TABLE silver.drivers (
    driverId        INT,
    driverRef       NVARCHAR(100),
    number          INT,
    code            NVARCHAR(10),
    forename        NVARCHAR(100),
    surname         NVARCHAR(100),
    dob             DATE,
    nationality     NVARCHAR(100),
    url             NVARCHAR(500),
    dwh_create_date DATETIME2 DEFAULT SYSUTCDATETIME()
);
GO

-- 7. LAP_TIMES
IF OBJECT_ID('silver.lap_times', 'U') IS NOT NULL
    DROP TABLE silver.lap_times;
CREATE TABLE silver.lap_times (
    raceId          INT,
    driverId        INT,
    lap             INT,
    position        INT,
    time            NVARCHAR(20),
    milliseconds    INT,
    dwh_create_date DATETIME2 DEFAULT SYSUTCDATETIME()
);
GO

-- 8. PIT_STOPS
IF OBJECT_ID('silver.pit_stops', 'U') IS NOT NULL
    DROP TABLE silver.pit_stops;
CREATE TABLE silver.pit_stops (
    raceId          INT,
    driverId        INT,
    stop            INT,
    lap             INT,
    time            TIME,
    duration        NVARCHAR(20),
    milliseconds    INT,
    dwh_create_date DATETIME2 DEFAULT SYSUTCDATETIME()
);
GO

-- 9. QUALIFYING
IF OBJECT_ID('silver.qualifying', 'U') IS NOT NULL
    DROP TABLE silver.qualifying;
CREATE TABLE silver.qualifying (
    qualifyId       INT,
    raceId          INT,
    driverId        INT,
    constructorId   INT,
    number          INT,
    position        INT,
    q1              NVARCHAR(20),
    q2              NVARCHAR(20),
    q3              NVARCHAR(20),
    dwh_create_date DATETIME2 DEFAULT SYSUTCDATETIME()
);
GO

-- 10. RACES
IF OBJECT_ID('silver.races', 'U') IS NOT NULL
    DROP TABLE silver.races;
CREATE TABLE silver.races (
    raceId          INT,
    year            INT,
    round           INT,
    circuitId       INT,
    name            NVARCHAR(200),
    date            DATE,
    time            TIME,
    url             NVARCHAR(500),
    fp1_date        DATE,
    fp1_time        TIME,
    fp2_date        DATE,
    fp2_time        TIME,
    fp3_date        DATE,
    fp3_time        TIME,
    quali_date      DATE,
    quali_time      TIME,
    sprint_date     DATE,
    sprint_time     TIME,
    dwh_create_date DATETIME2 DEFAULT SYSUTCDATETIME()
);
GO

-- 11. RESULTS
IF OBJECT_ID('silver.results', 'U') IS NOT NULL
    DROP TABLE silver.results;
CREATE TABLE silver.results (
    resultId        INT,
    raceId          INT,
    driverId        INT,
    constructorId   INT,
    number          INT,
    grid            INT,
    position        INT,
    positionText    NVARCHAR(100),
    positionOrder   INT,
    points          DECIMAL(6, 2),
    laps            INT,
    time            NVARCHAR(50),
    milliseconds    INT,
    fastestLap      INT,
    rank            INT,
    fastestLapTime  NVARCHAR(20),
    fastestLapSpeed DECIMAL(6, 3),
    statusId        INT,
    dwh_create_date DATETIME2 DEFAULT SYSUTCDATETIME()
);
GO

-- 12. SEASONS
IF OBJECT_ID('silver.seasons', 'U') IS NOT NULL
    DROP TABLE silver.seasons;
CREATE TABLE silver.seasons (
    year            INT,
    url             NVARCHAR(500),
    dwh_create_date DATETIME2 DEFAULT SYSUTCDATETIME()
);
GO

-- 13. SPRINT_RESULTS
IF OBJECT_ID('silver.sprint_results', 'U') IS NOT NULL
    DROP TABLE silver.sprint_results;
CREATE TABLE silver.sprint_results (
    resultId        INT,
    raceId          INT,
    driverId        INT,
    constructorId   INT,
    number          INT,
    grid            INT,
    position        INT,
    positionText    NVARCHAR(100),
    positionOrder   INT,
    points          DECIMAL(6, 2),
    laps            INT,
    time            NVARCHAR(50),
    milliseconds    INT,
    fastestLap      INT,
    fastestLapTime  NVARCHAR(20),
    statusId        INT,
    dwh_create_date DATETIME2 DEFAULT SYSUTCDATETIME()
);
GO

-- 14. STATUS
IF OBJECT_ID('silver.status', 'U') IS NOT NULL
    DROP TABLE silver.status;
CREATE TABLE silver.status (
    statusId        INT,
    status          NVARCHAR(100),
    dwh_create_date DATETIME2 DEFAULT SYSUTCDATETIME()
);
GO

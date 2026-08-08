/*
===============================================================================
Description: Bronze Layer Table Creation Script
===============================================================================
This script sets up the raw ingestion tables inside the 'bronze' schema for 
Formula 1 data[cite: 2].

Key Operations & Patterns:
-------------------------------------------------------------------------------
1. Safe Re-creation (Idempotency):
   - Every block checks `IF OBJECT_ID('bronze.<table_name>', 'U') IS NOT NULL` 
     and drops the table if it exists before re-creating it[cite: 2].

2. Raw Ingestion Schema (Flexible Data Types):
   - All columns use broad character types (`VARCHAR`)[cite: 2]. 
   - Integers, floats, dates, and times are intentionally stored as strings 
     in the Bronze layer to accept raw source data (e.g., CSV dumps) without 
     ingestion failures or type-casting errors[cite: 2].
   - Data cleanup, validation, and proper type-casting will occur downstream 
     in the Silver layer.
===============================================================================
*/
-- 1. CIRCUITS
IF OBJECT_ID('bronze.circuits', 'U') IS NOT NULL
    DROP TABLE bronze.circuits;
CREATE TABLE bronze.circuits (
    circuitId       VARCHAR(20),
    circuitRef      VARCHAR(100),
    name            VARCHAR(200),
    location        VARCHAR(100),
    country         VARCHAR(100),
    lat             VARCHAR(50),
    lng             VARCHAR(50),
    alt             VARCHAR(20),
    url             VARCHAR(500)
);
Go

-- 2. CONSTRUCTOR_RESULTS
IF OBJECT_ID('bronze.constructor_results', 'U') IS NOT NULL
    DROP TABLE bronze.constructor_results;
CREATE TABLE bronze.constructor_results (
    constructorResultsId    VARCHAR(20),
    raceId                  VARCHAR(20),
    constructorId           VARCHAR(20),
    points                  VARCHAR(20),
    status                  VARCHAR(20)
);
Go

-- 3. CONSTRUCTOR_STANDINGS
IF OBJECT_ID('bronze.constructor_standings', 'U') IS NOT NULL
    DROP TABLE bronze.constructor_standings;
CREATE TABLE bronze.constructor_standings (
    constructorStandingsId  VARCHAR(20),
    raceId                  VARCHAR(20),
    constructorId           VARCHAR(20),
    points                  VARCHAR(20),
    position                VARCHAR(20),
    positionText            VARCHAR(20),
    wins                    VARCHAR(20)
);
Go

-- 4. CONSTRUCTORS
IF OBJECT_ID('bronze.constructors', 'U') IS NOT NULL
    DROP TABLE bronze.constructors;
CREATE TABLE bronze.constructors (
    constructorId   VARCHAR(20),
    constructorRef  VARCHAR(100),
    name            VARCHAR(100),
    nationality     VARCHAR(100),
    url             VARCHAR(500)
);
Go

-- 5. DRIVER_STANDINGS
IF OBJECT_ID('bronze.driver_standings', 'U') IS NOT NULL
    DROP TABLE bronze.driver_standings;
CREATE TABLE bronze.driver_standings (
    driverStandingsId   VARCHAR(20),
    raceId              VARCHAR(20),
    driverId            VARCHAR(20),
    points              VARCHAR(20),
    position            VARCHAR(20),
    positionText        VARCHAR(20),
    wins                VARCHAR(20)
);
Go

-- 6. DRIVERS
IF OBJECT_ID('bronze.drivers', 'U') IS NOT NULL
    DROP TABLE bronze.drivers;
CREATE TABLE bronze.drivers (
    driverId        VARCHAR(20),
    driverRef       VARCHAR(100),
    number          VARCHAR(10),
    code            VARCHAR(10),
    forename        VARCHAR(100),
    surname         VARCHAR(100),
    dob             VARCHAR(20),
    nationality     VARCHAR(100),
    url             VARCHAR(500)
);
Go

-- 7. LAP_TIMES
IF OBJECT_ID('bronze.lap_times', 'U') IS NOT NULL
    DROP TABLE bronze.lap_times;
CREATE TABLE bronze.lap_times (
    raceId          VARCHAR(20),
    driverId        VARCHAR(20),
    lap             VARCHAR(20),
    position        VARCHAR(20),
    time            VARCHAR(50),
    milliseconds    VARCHAR(20)
);
Go

-- 8. PIT_STOPS
IF OBJECT_ID('bronze.pit_stops', 'U') IS NOT NULL
    DROP TABLE bronze.pit_stops;
CREATE TABLE bronze.pit_stops (
    raceId          VARCHAR(20),
    driverId        VARCHAR(20),
    stop            VARCHAR(20),
    lap             VARCHAR(20),
    time            VARCHAR(50),
    duration        VARCHAR(50),
    milliseconds    VARCHAR(20)
);
Go

-- 9. QUALIFYING
IF OBJECT_ID('bronze.qualifying', 'U') IS NOT NULL
    DROP TABLE bronze.qualifying;
CREATE TABLE bronze.qualifying (
    qualifyId       VARCHAR(20),
    raceId          VARCHAR(20),
    driverId        VARCHAR(20),
    constructorId   VARCHAR(20),
    number          VARCHAR(10),
    position        VARCHAR(20),
    q1              VARCHAR(50),
    q2              VARCHAR(50),
    q3              VARCHAR(50)
);
Go

-- 10. RACES
IF OBJECT_ID('bronze.races', 'U') IS NOT NULL
    DROP TABLE bronze.races;
CREATE TABLE bronze.races (
    raceId          VARCHAR(20),
    year            VARCHAR(10),
    round           VARCHAR(10),
    circuitId       VARCHAR(20),
    name            VARCHAR(200),
    date            VARCHAR(20),
    time            VARCHAR(50),
    url             VARCHAR(500),
    fp1_date        VARCHAR(20),
    fp1_time        VARCHAR(50),
    fp2_date        VARCHAR(20),
    fp2_time        VARCHAR(50),
    fp3_date        VARCHAR(20),
    fp3_time        VARCHAR(50),
    quali_date      VARCHAR(20),
    quali_time      VARCHAR(50),
    sprint_date     VARCHAR(20),
    sprint_time     VARCHAR(50)
);
Go

-- 11. RESULTS
IF OBJECT_ID('bronze.results', 'U') IS NOT NULL
    DROP TABLE bronze.results;
CREATE TABLE bronze.results (
    resultId        VARCHAR(20),
    raceId          VARCHAR(20),
    driverId        VARCHAR(20),
    constructorId   VARCHAR(20),
    number          VARCHAR(10),
    grid            VARCHAR(20),
    position        VARCHAR(20),
    positionText    VARCHAR(20),
    positionOrder   VARCHAR(20),
    points          VARCHAR(20),
    laps            VARCHAR(20),
    time            VARCHAR(50),
    milliseconds    VARCHAR(20),
    fastestLap      VARCHAR(20),
    rank            VARCHAR(20),
    fastestLapTime  VARCHAR(50),
    fastestLapSpeed VARCHAR(50),
    statusId        VARCHAR(20)
);
Go

-- 12. SEASONS
IF OBJECT_ID('bronze.seasons', 'U') IS NOT NULL
    DROP TABLE bronze.seasons;
CREATE TABLE bronze.seasons (
    year            VARCHAR(10),
    url             VARCHAR(500)
);
Go

-- 13. SPRINT_RESULTS
IF OBJECT_ID('bronze.sprint_results', 'U') IS NOT NULL
    DROP TABLE bronze.sprint_results;
CREATE TABLE bronze.sprint_results (
    resultId        VARCHAR(20),
    raceId          VARCHAR(20),
    driverId        VARCHAR(20),
    constructorId   VARCHAR(20),
    number          VARCHAR(10),
    grid            VARCHAR(20),
    position        VARCHAR(20),
    positionText    VARCHAR(20),
    positionOrder   VARCHAR(20),
    points          VARCHAR(20),
    laps            VARCHAR(20),
    time            VARCHAR(50),
    milliseconds    VARCHAR(20),
    fastestLap      VARCHAR(20),
    fastestLapTime  VARCHAR(50),
    statusId        VARCHAR(20)
);
Go

-- 14. STATUS
IF OBJECT_ID('bronze.status', 'U') IS NOT NULL
    DROP TABLE bronze.status;
CREATE TABLE bronze.status (
    statusId        VARCHAR(20),
    status          VARCHAR(100)
);


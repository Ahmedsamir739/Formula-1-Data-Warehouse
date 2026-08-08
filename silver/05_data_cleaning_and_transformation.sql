/*
===============================================================================
Description: Bronze-to-Silver Layer ETL Transformation & Loading Script
===============================================================================
This script performs full Data Transformation and Loading (ETL) from the 
raw Bronze schema into the cleansed, strongly-typed Silver schema[cite: 5].

Key Data Cleaning & Transformation Logic:
-------------------------------------------------------------------------------
1. Safe Type Conversion (`TRY_CAST`):
   - Safely converts raw string values from Bronze into numeric (`INT`, `DECIMAL`), 
     `DATE`, and `TIME` types without throwing execution errors if invalid 
     data exists[cite: 5].

2. Handling Missing & Null Source Values (`NULLIF` & `\N`):
   - Eradicates Ergast database `\N` string indicators by converting them into 
     proper SQL `NULL` values before type conversion[cite: 5].

3. String Standardization & Sanitation (`TRIM` & `REPLACE`):
   - Strips unintended double quotes (`"`) and surrounding whitespace across 
     all text fields[cite: 5].

4. Domain-Specific Business Value Mapping (`CASE` Statements):
   - Expands abbreviated race and classification statuses into clear text[cite: 5]:
     * Country abbreviations: 'UK' -> 'United Kingdom', 'US'/'USA' -> 'United States'[cite: 5].
     * Statuses/Positions: 'D' -> 'Disqualified', 'E' -> 'Excluded', 
       'F' -> 'Failed to Qualify', 'N' -> 'Not Classified', 'R' -> 'Retired', 
       'W' -> 'Withdrawn'[cite: 5].

5. Load Strategy (Full Reload & Deterministic Ordering):
   - Uses `TRUNCATE TABLE` prior to inserting into each table to prevent duplicates[cite: 5].
   - Enforces deterministic loading using key-based `ORDER BY` clauses[cite: 5].
===============================================================================
*/
-- 1. CIRCUITS
TRUNCATE TABLE silver.circuits;
INSERT INTO silver.circuits (
    circuitid,
    circuitref,
    name,
    location,
    country,
    lat,
    lng,
    alt,
    url
)
SELECT
    TRY_CAST(circuitId AS INT)                                     AS circuitid,
    TRIM(REPLACE(circuitRef, '"', ''))                             AS circuitref,
    TRIM(REPLACE(name, '"', ''))                                   AS name,
    TRIM(REPLACE(location, '"', ''))                               AS location,
    CASE TRIM(REPLACE(country, '"', ''))
        WHEN 'UK'  THEN 'United Kingdom'
        WHEN 'UAE' THEN 'United Arab Emirates'
        WHEN 'US'  THEN 'United States'
        WHEN 'USA' THEN 'United States'
        ELSE TRIM(REPLACE(country, '"', ''))
    END                                                             AS country,
    TRY_CAST(TRIM(lat) AS DECIMAL(10,6))                            AS lat,
    TRY_CAST(TRIM(lng) AS DECIMAL(10,6))                            AS lng,
    TRY_CAST(NULLIF(TRIM(alt), '\N') AS INT)                        AS alt,
    TRIM(REPLACE(url, '"', ''))                                     AS url
FROM bronze.circuits
ORDER BY circuitId;

-- 2. CONSTRUCTOR_RESULTS
TRUNCATE TABLE silver.constructor_results;
INSERT INTO silver.constructor_results (
    constructorResultsId,
    raceId,
    constructorId,
    points,
    status
)
SELECT
    TRY_CAST(constructorResultsId AS INT)          AS constructorResultsId,
    TRY_CAST(raceId AS INT)                        AS raceId,
    TRY_CAST(constructorId AS INT)                 AS constructorId,
    TRY_CAST(points AS DECIMAL(6,2))               AS points,
    CASE 
        WHEN UPPER(TRIM(REPLACE(REPLACE(status, '"', ''), '''', ''))) = 'D' THEN 'Disqualification'
        ELSE NULLIF(TRIM(status), '\N')
    END AS status
FROM bronze.constructor_results
ORDER BY constructorResultsId;

-- 3. CONSTRUCTOR_STANDINGS
TRUNCATE TABLE silver.constructor_standings;
INSERT INTO silver.constructor_standings (
    constructorStandingsId,
    raceId,
    constructorId,
    points,
    position,
    positionText,
    wins
)
SELECT
    TRY_CAST(constructorStandingsId AS INT)                       AS constructorStandingsId,
    TRY_CAST(raceId AS INT)                                       AS raceId,
    TRY_CAST(constructorId AS INT)                                AS constructorId,
    TRY_CAST(points AS DECIMAL(6,2))                              AS points,
    TRY_CAST(NULLIF(LTRIM(RTRIM(position)), '\N') AS INT)         AS position,
    CASE TRIM(REPLACE(positionText, '"', ''))
        WHEN 'E' THEN 'Excluded'
        ELSE TRIM(REPLACE(positionText, '"', ''))
    END                                                           AS positionText,
    TRY_CAST(wins AS INT)                                         AS wins
FROM bronze.constructor_standings
ORDER BY constructorStandingsId;

-- 4. CONSTRUCTORS
TRUNCATE TABLE silver.constructors;
INSERT INTO silver.constructors (
    constructorId,
    constructorRef,
    name,
    nationality,
    url
)
SELECT
    TRY_CAST(constructorId AS INT)                      AS constructorId,
    TRIM(REPLACE(constructorRef, '"', ''))              AS constructorRef,
    TRIM(REPLACE(name, '"', ''))                        AS name,
    TRIM(REPLACE(nationality, '"', ''))                 AS nationality,
    TRIM(REPLACE(url, '"', ''))                         AS url
FROM bronze.constructors
ORDER BY constructorId;

-- 5. DRIVER_STANDINGS
TRUNCATE TABLE silver.driver_standings;
INSERT INTO silver.driver_standings (
    driverStandingsId,
    raceId,
    driverId,
    points,
    position,
    positionText,
    wins
)
SELECT
    TRY_CAST(driverStandingsId AS INT)                     AS driverStandingsId,
    TRY_CAST(raceId AS INT)                                AS raceId,
    TRY_CAST(driverId AS INT)                              AS driverId,
    TRY_CAST(points AS DECIMAL(6,2))                       AS points,
    TRY_CAST(NULLIF(TRIM(position), '\N') AS INT)          AS position,
    CASE TRIM(REPLACE(positionText, '"', ''))
        WHEN 'D' THEN 'Disqualified'
        ELSE TRIM(REPLACE(positionText, '"', ''))
    END                                                    AS positionText,
    TRY_CAST(wins AS INT)                                  AS wins
FROM bronze.driver_standings
ORDER BY driverStandingsId;

-- 6. DRIVERS
TRUNCATE TABLE silver.drivers;
INSERT INTO silver.drivers (
    driverId,
    driverRef,
    number,
    code,
    forename,
    surname,
    dob,
    nationality,
    url
)
SELECT
    TRY_CAST(driverId AS INT)                                   AS driverId,
    TRIM(REPLACE(driverRef, '"', ''))                           AS driverRef,
    TRY_CAST(NULLIF(TRIM(number), '\N') AS INT)                 AS number,
    NULLIF(TRIM(REPLACE(code, '"', '')), '\N')                  AS code,
    TRIM(REPLACE(forename, '"', ''))                            AS forename,
    TRIM(REPLACE(surname, '"', ''))                             AS surname,
    TRY_CAST(NULLIF(TRIM(REPLACE(dob, '"', '')), '\N') AS DATE) AS dob,
    TRIM(REPLACE(nationality, '"', ''))                         AS nationality,
    TRIM(REPLACE(url, '"', ''))                                 AS url
FROM bronze.drivers
ORDER BY driverId;

-- 7. LAP_TIMES
TRUNCATE TABLE silver.lap_times;
INSERT INTO silver.lap_times (
    raceId,
    driverId,
    lap,
    position,
    time,
    milliseconds
)
SELECT
    TRY_CAST(raceId AS INT)                                     AS raceId,
    TRY_CAST(driverId AS INT)                                   AS driverId,
    TRY_CAST(lap AS INT)                                        AS lap,
    TRY_CAST(NULLIF(TRIM(position), '\N') AS INT)               AS position,
    TRIM(REPLACE(time, '"', ''))                                AS time,
    TRY_CAST(NULLIF(TRIM(milliseconds), '\N') AS INT)           AS milliseconds
FROM bronze.lap_times
ORDER BY raceId, driverId, lap;

-- 8. PIT_STOPS
TRUNCATE TABLE silver.pit_stops;
INSERT INTO silver.pit_stops (
    raceId,
    driverId,
    stop,
    lap,
    time,
    duration,
    milliseconds
)
SELECT
    TRY_CAST(raceId AS INT)                                        AS raceId,
    TRY_CAST(driverId AS INT)                                      AS driverId,
    TRY_CAST(stop AS INT)                                          AS stop,
    TRY_CAST(lap AS INT)                                           AS lap,
    TRY_CAST(NULLIF(TRIM(REPLACE(time, '"', '')), '\N') AS TIME)   AS time,
    NULLIF(TRIM(REPLACE(duration, '"', '')), '\N')                 AS duration,
    TRY_CAST(NULLIF(TRIM(milliseconds), '\N') AS INT)              AS milliseconds
FROM bronze.pit_stops
ORDER BY raceId, driverId, stop;

-- 9. QUALIFYING
TRUNCATE TABLE silver.qualifying;
INSERT INTO silver.qualifying (
    qualifyId,
    raceId,
    driverId,
    constructorId,
    number,
    position,
    q1,
    q2,
    q3
)
SELECT
    TRY_CAST(qualifyId AS INT)                                    AS qualifyId,
    TRY_CAST(raceId AS INT)                                       AS raceId,
    TRY_CAST(driverId AS INT)                                     AS driverId,
    TRY_CAST(constructorId AS INT)                                AS constructorId,
    TRY_CAST(NULLIF(TRIM(number), '\N') AS INT)                   AS number,
    TRY_CAST(NULLIF(TRIM(position), '\N') AS INT)                 AS position,
    NULLIF(TRIM(REPLACE(q1, '"', '')), '\N')                      AS q1,
    NULLIF(TRIM(REPLACE(q2, '"', '')), '\N')                      AS q2,
    NULLIF(TRIM(REPLACE(q3, '"', '')), '\N')                      AS q3
FROM bronze.qualifying
ORDER BY qualifyId;

-- 10. RACES
TRUNCATE TABLE silver.races;
INSERT INTO silver.races (
    raceId, year, round, circuitId, name, date, time, url,
    fp1_date, fp1_time, fp2_date, fp2_time,
    fp3_date, fp3_time, quali_date, quali_time,
    sprint_date, sprint_time
)
SELECT
    TRY_CAST(raceId AS INT)                                                  AS raceId,
    TRY_CAST(year AS INT)                                                    AS year,
    TRY_CAST(round AS INT)                                                   AS round,
    TRY_CAST(circuitId AS INT)                                               AS circuitId,
    TRIM(REPLACE(name, '"', ''))                                             AS name,
    TRY_CAST(NULLIF(TRIM(REPLACE(date, '"', '')), '\N') AS DATE)             AS date,
    TRY_CAST(NULLIF(TRIM(REPLACE(time, '"', '')), '\N') AS TIME)             AS time,
    TRIM(REPLACE(url, '"', ''))                                              AS url,
    TRY_CAST(NULLIF(TRIM(REPLACE(fp1_date, '"', '')), '\N') AS DATE)         AS fp1_date,
    TRY_CAST(NULLIF(TRIM(REPLACE(fp1_time, '"', '')), '\N') AS TIME)         AS fp1_time,
    TRY_CAST(NULLIF(TRIM(REPLACE(fp2_date, '"', '')), '\N') AS DATE)         AS fp2_date,
    TRY_CAST(NULLIF(TRIM(REPLACE(fp2_time, '"', '')), '\N') AS TIME)         AS fp2_time,
    TRY_CAST(NULLIF(TRIM(REPLACE(fp3_date, '"', '')), '\N') AS DATE)         AS fp3_date,
    TRY_CAST(NULLIF(TRIM(REPLACE(fp3_time, '"', '')), '\N') AS TIME)         AS fp3_time,
    TRY_CAST(NULLIF(TRIM(REPLACE(quali_date, '"', '')), '\N') AS DATE)       AS quali_date,
    TRY_CAST(NULLIF(TRIM(REPLACE(quali_time, '"', '')), '\N') AS TIME)       AS quali_time,
    TRY_CAST(NULLIF(TRIM(REPLACE(sprint_date, '"', '')), '\N') AS DATE)      AS sprint_date,
    TRY_CAST(NULLIF(TRIM(REPLACE(sprint_time, '"', '')), '\N') AS TIME)      AS sprint_time
FROM bronze.races
ORDER BY raceId;

-- 11. RESULTS
TRUNCATE TABLE silver.results;
INSERT INTO silver.results (
    resultId, raceId, driverId, constructorId, number, grid,
    position, positionText, positionOrder, points, laps, time,
    milliseconds, fastestLap, [rank], fastestLapTime, fastestLapSpeed, statusId
)
SELECT
    TRY_CAST(resultId AS INT)                                            AS resultId,
    TRY_CAST(raceId AS INT)                                              AS raceId,
    TRY_CAST(driverId AS INT)                                            AS driverId,
    TRY_CAST(constructorId AS INT)                                       AS constructorId,
    TRY_CAST(NULLIF(TRIM(number), '\N') AS INT)                          AS number,
    TRY_CAST(NULLIF(TRIM(grid), '\N') AS INT)                            AS grid,
    TRY_CAST(NULLIF(TRIM(position), '\N') AS INT)                        AS position,
    CASE TRIM(REPLACE(positionText, '"', ''))
        WHEN 'D' THEN 'Disqualified'
        WHEN 'E' THEN 'Excluded'
        WHEN 'F' THEN 'Failed to Qualify'
        WHEN 'N' THEN 'Not Classified'
        WHEN 'R' THEN 'Retired'
        WHEN 'W' THEN 'Withdrawn'
        ELSE TRIM(REPLACE(positionText, '"', ''))
    END                                                                  AS positionText,
    TRY_CAST(positionOrder AS INT)                                       AS positionOrder,
    TRY_CAST(points AS DECIMAL(6,2))                                     AS points,
    TRY_CAST(NULLIF(TRIM(laps), '\N') AS INT)                            AS laps,
    NULLIF(TRIM(REPLACE(time, '"', '')), '\N')                           AS time,
    TRY_CAST(NULLIF(TRIM(milliseconds), '\N') AS INT)                    AS milliseconds,
    TRY_CAST(NULLIF(TRIM(fastestLap), '\N') AS INT)                      AS fastestLap,
    TRY_CAST(NULLIF(TRIM([rank]), '\N') AS INT)                          AS [rank],
    NULLIF(TRIM(REPLACE(fastestLapTime, '"', '')), '\N')                 AS fastestLapTime,
    TRY_CAST(NULLIF(TRIM(fastestLapSpeed), '\N') AS DECIMAL(6,3))        AS fastestLapSpeed,
    TRY_CAST(statusId AS INT)                                            AS statusId
FROM bronze.results
ORDER BY resultId;

-- 12. SEASONS
TRUNCATE TABLE silver.seasons;
INSERT INTO silver.seasons (
    year,
    url
)
SELECT
    TRY_CAST(year AS INT)                     AS year,
    TRIM(REPLACE(url, '"', ''))               AS url
FROM bronze.seasons
ORDER BY year;

-- 13. SPRINT_RESULTS
TRUNCATE TABLE silver.sprint_results;
INSERT INTO silver.sprint_results (
    resultId, raceId, driverId, constructorId, number, grid,
    position, positionText, positionOrder, points, laps, time,
    milliseconds, fastestLap, fastestLapTime, statusId
)
SELECT
    TRY_CAST(resultId AS INT)                                          AS resultId,
    TRY_CAST(raceId AS INT)                                            AS raceId,
    TRY_CAST(driverId AS INT)                                          AS driverId,
    TRY_CAST(constructorId AS INT)                                     AS constructorId,
    TRY_CAST(NULLIF(TRIM(number), '\N') AS INT)                        AS number,
    TRY_CAST(NULLIF(TRIM(grid), '\N') AS INT)                          AS grid,
    TRY_CAST(NULLIF(TRIM(position), '\N') AS INT)                      AS position,
    CASE TRIM(REPLACE(positionText, '"', ''))
        WHEN 'R' THEN 'Retired'
        WHEN 'W' THEN 'Withdrawn'
        WHEN 'N' THEN 'Not Classified'
    ELSE TRIM(REPLACE(positionText, '"', ''))
    END                                                                AS positionText,
    TRY_CAST(positionOrder AS INT)                                     AS positionOrder,
    TRY_CAST(points AS DECIMAL(6,2))                                   AS points,
    TRY_CAST(NULLIF(TRIM(laps), '\N') AS INT)                          AS laps,
    NULLIF(TRIM(REPLACE(time, '"', '')), '\N')                         AS time,
    TRY_CAST(NULLIF(TRIM(milliseconds), '\N') AS INT)                  AS milliseconds,
    TRY_CAST(NULLIF(TRIM(fastestLap), '\N') AS INT)                    AS fastestLap,
    NULLIF(TRIM(REPLACE(fastestLapTime, '"', '')), '\N')               AS fastestLapTime,
    TRY_CAST(statusId AS INT)                                          AS statusId
FROM bronze.sprint_results
ORDER BY resultId;

-- 14. STATUS
TRUNCATE TABLE silver.status;
INSERT INTO silver.status (
    statusId,
    status
)
SELECT
    TRY_CAST(statusId AS INT)              AS statusId,
    TRIM(REPLACE(status, '"', ''))          AS status
FROM bronze.status
ORDER BY statusId;

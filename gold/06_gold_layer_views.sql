
/*
===============================================================================
Description: Gold Layer Creation (Star-Schema Dimensional Model Views)
===============================================================================
This script builds the Gold layer of the Data Warehouse using SQL Views[cite: 6]. 
It transforms cleansed data from the Silver schema into a business-ready Star Schema 
consisting of Dimension (`dim_`) and Fact (`fact_`) models optimized for BI reporting 
and analytics[cite: 6].

Key Operations & Transformations:
-------------------------------------------------------------------------------
1. Business-Friendly Aliasing & Naming:
   - Renames technical database columns into readable, standardized business terms 
     (e.g., `lat` -> `latitude`, `lng` -> `longitude`, `q1` -> `qualifying_1_time`)[cite: 6].

2. Feature Engineering & Enrichment:
   - `dim_drivers`: Combines `forename` and `surname` into a single `full_name` column[cite: 6].
   - `dim_races`: Performs a `LEFT JOIN` between `silver.races` and `silver.circuits` 
     to enrich race schedule records with circuit names[cite: 6].

3. Dimensional Modeling (15 Total Views):
   - Dimension Views (7):
     * `dim_circuits`            : Circuit metadata, location, and coordinates[cite: 6].
     * `dim_constructors`        : Constructor / Team references and nationalities[cite: 6].
     * `dim_drivers`             : Driver details, full names, numbers, codes, and DOBs[cite: 6].
     * `dim_status`              : Lookup definitions for race statuses[cite: 6].
     * `dim_seasons`             : Historical F1 seasons[cite: 6].
     * `dim_races`               : Grand Prix schedules with embedded circuit names[cite: 6].
     * `dim_date`                : Generated calendar date dimension for time intelligence in BI reporting.

   - Fact Views (8):
     * `fact_results`            : Main Grand Prix results, finishing positions, and metrics[cite: 6].
     * `fact_sprint_results`     : Sprint race outcomes, times, and points[cite: 6].
     * `fact_qualifying`         : Qualifying session performance (Q1, Q2, Q3)[cite: 6].
     * `fact_lap_times`          : Granular lap-by-lap timing logs[cite: 6].
     * `fact_pit_stops`          : Pit stop counts, timing, and durations[cite: 6].
     * `fact_driver_standings`   : Cumulative driver championship standings and points[cite: 6].
     * `fact_constructor_standings`: Cumulative team championship standings and points[cite: 6].
     * `fact_constructor_results`: Overall constructor scoring per race[cite: 6].

4. View Verification:
   - Concludes with `SELECT *` queries across all 15 Gold views to audit final presentation models[cite: 6].
===============================================================================
*/

--dim_circuits
IF OBJECT_ID('gold.dim_circuits', 'V') IS NOT NULL
    DROP VIEW gold.dim_circuits;
GO
CREATE VIEW gold.dim_circuits AS
SELECT 
    circuitId       AS circuit_id,
    circuitRef      AS circuit_reference,
    name            AS circuit_name,
    location        AS location,
    country         AS country,
    lat             AS latitude,
    lng             AS longitude,
    alt             AS altitude,
    url             AS wikipedia_url
FROM silver.circuits;
GO

--dim_constructors
IF OBJECT_ID('gold.dim_constructors', 'V') IS NOT NULL
    DROP VIEW gold.dim_constructors;
GO
CREATE VIEW gold.dim_constructors AS
SELECT 
    constructorId   AS constructor_id,
    constructorRef  AS constructor_reference,
    name            AS constructor_name,
    nationality     AS nationality,
    url             AS wikipedia_url
FROM silver.constructors;
GO

--dim_drivers
IF OBJECT_ID('gold.dim_drivers', 'V') IS NOT NULL
    DROP VIEW gold.dim_drivers;
GO
CREATE VIEW gold.dim_drivers AS
SELECT 
    driverId                        AS driver_id,
    driverRef                       AS driver_reference,
    number                          AS driver_number,
    code                            AS driver_code,
    CONCAT(forename, ' ', surname)  AS full_name,
    dob                             AS birth_date,
    nationality                     AS nationality,
    url                             AS wikipedia_url
FROM silver.drivers;
GO

--dim_status
IF OBJECT_ID('gold.dim_status', 'V') IS NOT NULL
    DROP VIEW gold.dim_status;
GO
CREATE VIEW gold.dim_status AS
SELECT 
    statusId    AS status_id,
    status      AS status_description
FROM silver.status;
GO

--dim_seasons
IF OBJECT_ID('gold.dim_seasons', 'V') IS NOT NULL
    DROP VIEW gold.dim_seasons;
GO
CREATE VIEW gold.dim_seasons AS
SELECT 
    year    AS season_year,
    url     AS wikipedia_url
FROM silver.seasons;
GO

--dim_races
IF OBJECT_ID('gold.dim_races', 'V') IS NOT NULL
    DROP VIEW gold.dim_races;
GO
CREATE VIEW gold.dim_races AS
SELECT 
    r.raceId        AS race_id,
    r.year          AS season_year,
    r.circuitId     AS circuit_id,
    c.name          AS circuit_name,
    r.round         AS race_round,
    r.name          AS race_name,
    r.date          AS race_date,
    r.time          AS race_time,
    r.fp1_date      AS free_practice_1_date,
    r.fp1_time      AS free_practice_1_time,
    r.fp2_date      AS free_practice_2_date,
    r.fp2_time      AS free_practice_2_time,
    r.fp3_date      AS free_practice_3_date,
    r.fp3_time      AS free_practice_3_time,
    r.quali_date    AS qualifying_date,
    r.quali_time    AS qualifying_time,
    r.sprint_date   AS sprint_date,
    r.sprint_time   AS sprint_time,
    r.url           AS wikipedia_url
FROM silver.races r
LEFT JOIN silver.circuits c 
    ON r.circuitId = c.circuitId;
GO

--dim_date
IF OBJECT_ID('gold.dim_date', 'V') IS NOT NULL
    DROP VIEW gold.dim_date;
GO
CREATE OR ALTER VIEW gold.dim_date AS
WITH DateBounds AS (
    SELECT 
        MIN(CAST(date AS DATE)) AS minDate,
        DATEADD(YEAR, 1, MAX(CAST(date AS DATE))) AS maxDate
    FROM silver.races
),
Tally AS (
    SELECT TOP (SELECT DATEDIFF(DAY, minDate, maxDate) + 1 FROM DateBounds)
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS rn
    FROM sys.all_objects a
    CROSS JOIN sys.all_objects b
)
SELECT
    CONVERT(INT, FORMAT(DATEADD(DAY, t.rn, d.minDate), 'yyyyMMdd')) AS dateKey,
    DATEADD(DAY, t.rn, d.minDate)                        AS date,
    YEAR(DATEADD(DAY, t.rn, d.minDate))                  AS year,
    DATEPART(QUARTER, DATEADD(DAY, t.rn, d.minDate))      AS quarter,
    MONTH(DATEADD(DAY, t.rn, d.minDate))                  AS month,
    DATENAME(MONTH, DATEADD(DAY, t.rn, d.minDate))        AS monthName,
    DAY(DATEADD(DAY, t.rn, d.minDate))                    AS day,
    DATEPART(WEEKDAY, DATEADD(DAY, t.rn, d.minDate))      AS dayOfWeek,
    DATENAME(WEEKDAY, DATEADD(DAY, t.rn, d.minDate))      AS dayName,
    DATEPART(WEEK, DATEADD(DAY, t.rn, d.minDate))         AS weekOfYear,
    CASE WHEN DATEPART(WEEKDAY, DATEADD(DAY, t.rn, d.minDate)) IN (1,7)
         THEN 1 ELSE 0 END                                AS isWeekend
FROM Tally t
CROSS JOIN DateBounds d;
GO

--fact_results
IF OBJECT_ID('gold.fact_results', 'V') IS NOT NULL
    DROP VIEW gold.fact_results;
GO
CREATE VIEW gold.fact_results AS
SELECT 
    resultId        AS result_id,
    raceId          AS race_id,
    constructorId   AS constructor_id,
    statusId        AS status_id,
    driverId        AS driver_id,
    number          AS driver_number,
    grid            AS starting_grid_position,
    position        AS finishing_position,
    positionText    AS finishing_position_text,
    positionOrder   AS finishing_position_order,
    points          AS points_scored,
    laps            AS laps_completed,
    time            AS total_race_time,
    milliseconds    AS total_race_time_milliseconds,
    fastestLap      AS fastest_lap_number,
    rank            AS fastest_lap_rank,
    fastestLapTime  AS fastest_lap_time,
    fastestLapSpeed AS fastest_lap_speed_kph
FROM silver.results;
GO

--fact_sprint_results
IF OBJECT_ID('gold.fact_sprint_results', 'V') IS NOT NULL
    DROP VIEW gold.fact_sprint_results;
GO
CREATE VIEW gold.fact_sprint_results AS
SELECT 
    resultId        AS sprint_result_id,
    raceId          AS race_id,
    constructorId   AS constructor_id,
    statusId        AS status_id,
    driverId        AS driver_id,
    number          AS driver_number,
    grid            AS starting_grid_position,
    position        AS finishing_position,
    positionText    AS finishing_position_text,
    positionOrder   AS finishing_position_order,
    points          AS points_scored,
    laps            AS laps_completed,
    time            AS total_sprint_time,
    milliseconds    AS total_sprint_time_milliseconds,
    fastestLap      AS fastest_lap_number,
    fastestLapTime  AS fastest_lap_time
FROM silver.sprint_results;
GO

--fact_qualifying
IF OBJECT_ID('gold.fact_qualifying', 'V') IS NOT NULL
    DROP VIEW gold.fact_qualifying;
GO
CREATE VIEW gold.fact_qualifying AS
SELECT 
    qualifyId     AS qualifying_id,
    raceId        AS race_id,
    constructorId AS constructor_id,
    driverId      AS driver_id,
    number        AS driver_number,
    position      AS qualifying_position,
    q1            AS qualifying_1_time,
    q2            AS qualifying_2_time,
    q3            AS qualifying_3_time
FROM silver.qualifying;
GO

--fact_lap_times
IF OBJECT_ID('gold.fact_lap_times', 'V') IS NOT NULL
    DROP VIEW gold.fact_lap_times;
GO
CREATE VIEW gold.fact_lap_times AS
SELECT 
    raceId       AS race_id,
    driverId     AS driver_id,
    lap          AS lap_number,
    position     AS position_in_lap,
    time         AS lap_time,
    milliseconds AS lap_time_milliseconds
FROM silver.lap_times;
GO

--fact_pit_stops
IF OBJECT_ID('gold.fact_pit_stops', 'V') IS NOT NULL
    DROP VIEW gold.fact_pit_stops;
GO
CREATE VIEW gold.fact_pit_stops AS
SELECT 
    raceId       AS race_id,
    driverId     AS driver_id,
    lap          AS lap_number,
    stop         AS stop_number,
    time         AS pit_stop_time,
    duration     AS pit_stop_duration,
    milliseconds AS pit_stop_duration_milliseconds
FROM silver.pit_stops;
GO

--fact_driver_standings
IF OBJECT_ID('gold.fact_driver_standings', 'V') IS NOT NULL
    DROP VIEW gold.fact_driver_standings;
GO
CREATE VIEW gold.fact_driver_standings AS
SELECT 
    driverStandingsId AS driver_standings_id,
    driverId          AS driver_id,
    raceId            AS race_id,
    points            AS total_points,
    position          AS standing_position,
    positionText      AS standing_position_text,
    wins              AS total_wins
FROM silver.driver_standings;
GO

--fact_constructor_standings
IF OBJECT_ID('gold.fact_constructor_standings', 'V') IS NOT NULL
    DROP VIEW gold.fact_constructor_standings;
GO
CREATE VIEW gold.fact_constructor_standings AS
SELECT 
    constructorStandingsId AS constructor_standings_id,
    constructorId          AS constructor_id,
    raceId                 AS race_id,
    points                 AS total_points,
    position               AS standing_position,
    positionText           AS standing_position_text,
    wins                   AS total_wins
FROM silver.constructor_standings;
GO

--fact_constructor_results
IF OBJECT_ID('gold.fact_constructor_results', 'V') IS NOT NULL
    DROP VIEW gold.fact_constructor_results;
GO
CREATE VIEW gold.fact_constructor_results AS
SELECT 
    constructorResultsId AS constructor_results_id,
    constructorId        AS constructor_id,
    raceId               AS race_id,
    points               AS points_scored,
    status               AS result_status
FROM silver.constructor_results;
GO


select * from gold.dim_circuits
select * from gold.dim_constructors
select * from gold.dim_drivers
select * from gold.dim_status
select * from gold.dim_seasons
select * from gold.dim_races
select * from gold.dim_date
select * from gold.fact_results
select * from gold.fact_sprint_results
select * from gold.fact_qualifying
select * from gold.fact_lap_times
select * from gold.fact_pit_stops
select * from gold.fact_driver_standings
select * from gold.fact_constructor_standings
select * from gold.fact_constructor_results
select * from gold.dim_date


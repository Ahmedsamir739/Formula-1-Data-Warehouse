/*
===============================================================================
Description: Stored Procedure & Ingestion Pipeline for Bronze Layer
===============================================================================
This script defines and executes the stored procedure `bronze.load_bronze` 
to populate all 14 tables in the Bronze schema from raw Ergast F1 CSV files[cite: 3].

Key Ingestion Highlights:
-------------------------------------------------------------------------------
1. Stored Procedure Definition:
   - Encapsulates the ETL bulk loading logic inside `bronze.load_bronze`[cite: 3].
   - Drops any prior version before creating or altering[cite: 3].

2. Full Load Pattern (Truncate & Insert):
   - Every table is cleared using `TRUNCATE TABLE` before ingestion[cite: 3].
   - Ensures clean, idempotent re-runs without duplicate records[cite: 3].

3. Bulk Insert Configuration (`BULK INSERT`):
   - Reads flat CSV files directly from local storage[cite: 3].
   - `FIRSTROW = 2`: Skips the CSV header row[cite: 3].
   - `FIELDTERMINATOR = ','`: Parses comma-separated values[cite: 3].
   - `ROWTERMINATOR = '0x0a'`: Handles standard newline characters (`\n`)[cite: 3].
   - `FIELDQUOTE = '"'`: Correctly handles text values wrapped in double quotes[cite: 3].
   - `TABLOCK`: Minimizes transaction logging and speeds up bulk loads[cite: 3].

4. Automated Pipeline & Verification:
   - Triggers `EXEC bronze.load_bronze` to process all 14 files sequentially[cite: 3].
   - Ends with verification `SELECT` queries across all tables to audit row counts and data presence[cite: 3].
===============================================================================
*/

IF OBJECT_ID('bronze.usp_LoadBronzeTables', 'P') IS NOT NULL
    DROP PROCEDURE bronze.load_bronze;
GO

CREATE OR ALTER PROCEDURE bronze.load_bronze
AS
BEGIN

    -- 1. CIRCUITS
    TRUNCATE TABLE bronze.circuits;
    BULK INSERT bronze.circuits
    FROM 'C:\Users\windows 11\Desktop\archive\circuits.csv'
    WITH (
    DATAFILETYPE = 'char',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    FIELDQUOTE = '"',
    TABLOCK
);

    -- 2. CONSTRUCTOR_RESULTS
    TRUNCATE TABLE bronze.constructor_results;
    BULK INSERT bronze.constructor_results
    FROM 'C:\Users\windows 11\Desktop\archive\constructor_results.csv'
    WITH (
    DATAFILETYPE = 'char',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    FIELDQUOTE = '"',
    TABLOCK
    );

    -- 3. CONSTRUCTOR_STANDINGS
    TRUNCATE TABLE bronze.constructor_standings;
    BULK INSERT bronze.constructor_standings
    FROM 'C:\Users\windows 11\Desktop\archive\constructor_standings.csv'
    WITH (
    DATAFILETYPE = 'char',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    FIELDQUOTE = '"',
    TABLOCK
    );

    -- 4. CONSTRUCTORS
    TRUNCATE TABLE bronze.constructors;
    BULK INSERT bronze.constructors
    FROM 'C:\Users\windows 11\Desktop\archive\constructors.csv'
    WITH (
    DATAFILETYPE = 'char',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    FIELDQUOTE = '"',
    TABLOCK
    );

    -- 5. DRIVER_STANDINGS
    TRUNCATE TABLE bronze.driver_standings;
    BULK INSERT bronze.driver_standings
    FROM 'C:\Users\windows 11\Desktop\archive\driver_standings.csv'
    WITH (
    DATAFILETYPE = 'char',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    FIELDQUOTE = '"',
    TABLOCK
    );

    -- 6. DRIVERS
    TRUNCATE TABLE bronze.drivers;
    BULK INSERT bronze.drivers
    FROM 'C:\Users\windows 11\Desktop\archive\drivers.csv'
    WITH (
    DATAFILETYPE = 'char',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    FIELDQUOTE = '"',
    TABLOCK
    );

    -- 7. LAP_TIMES
    TRUNCATE TABLE bronze.lap_times;
    BULK INSERT bronze.lap_times
    FROM 'C:\Users\windows 11\Desktop\archive\lap_times.csv'
    WITH (
    DATAFILETYPE = 'char',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    FIELDQUOTE = '"',
    TABLOCK
    );

    -- 8. PIT_STOPS
    TRUNCATE TABLE bronze.pit_stops;
    BULK INSERT bronze.pit_stops
    FROM 'C:\Users\windows 11\Desktop\archive\pit_stops.csv'
    WITH (
    DATAFILETYPE = 'char',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    FIELDQUOTE = '"',
    TABLOCK
    );

    -- 9. QUALIFYING
    TRUNCATE TABLE bronze.qualifying;
    BULK INSERT bronze.qualifying
    FROM 'C:\Users\windows 11\Desktop\archive\qualifying.csv'
    WITH (
    DATAFILETYPE = 'char',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    FIELDQUOTE = '"',
    TABLOCK
    );

    -- 10. RACES
    TRUNCATE TABLE bronze.races;
    BULK INSERT bronze.races
    FROM 'C:\Users\windows 11\Desktop\archive\races.csv'
    WITH (
    DATAFILETYPE = 'char',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    FIELDQUOTE = '"',
    TABLOCK
    );

    -- 11. RESULTS
    TRUNCATE TABLE bronze.results;
    BULK INSERT bronze.results
    FROM 'C:\Users\windows 11\Desktop\archive\results.csv'
    WITH (
    DATAFILETYPE = 'char',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    FIELDQUOTE = '"',
    TABLOCK
    );

    -- 12. SEASONS
    TRUNCATE TABLE bronze.seasons;
    BULK INSERT bronze.seasons
    FROM 'C:\Users\windows 11\Desktop\archive\seasons.csv'
    WITH (
    DATAFILETYPE = 'char',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    FIELDQUOTE = '"',
    TABLOCK
    );

    -- 13. SPRINT_RESULTS
    TRUNCATE TABLE bronze.sprint_results;
    BULK INSERT bronze.sprint_results
    FROM 'C:\Users\windows 11\Desktop\archive\sprint_results.csv'
    WITH (
    DATAFILETYPE = 'char',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    FIELDQUOTE = '"',
    TABLOCK
    );

    -- 14. STATUS
    TRUNCATE TABLE bronze.status;
    BULK INSERT bronze.status
    FROM 'C:\Users\windows 11\Desktop\archive\status.csv'
    WITH (
    DATAFILETYPE = 'char',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    FIELDQUOTE = '"',
    TABLOCK
    );

END
GO







EXEC bronze.load_bronze

select * from bronze.circuits
select * from bronze.constructor_results
select * from bronze.constructor_standings
select * from bronze.constructors
select * from bronze.driver_standings
select * from bronze.drivers
select * from bronze.lap_times
select * from bronze.pit_stops
select * from bronze.qualifying
select * from bronze.races
select * from bronze.results
select * from bronze.seasons
select * from bronze.sprint_results
select * from bronze.status
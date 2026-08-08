
/*
===============================================================================
Script Name : DataAnalysis7.sql
Purpose     : Exploratory Data Analysis (EDA), Advanced Analytics and 
              ad-hoc reporting queries run against the Gold layer views.
              This is the "notebook" of the project: a collection of 
              standalone SELECT queries used to explore the data, 
              sanity-check the warehouse build, and surface business 
              insights — it does not create or modify any tables, views,
              or procedures.

Dataset     : Formula 1 World Championship (Ergast/Kaggle), covering the 
              full historical record from the first season in 1950 through 
              the 2024 season.
 
How it's organized (run any section independently, top to bottom for a
full walkthrough):
    1.  Database Exploration    - what tables/columns exist in the warehouse
    2.  Dimensions Exploration  - unique values inside dimension tables 
                                  (drivers, constructors, circuits, seasons, status)
    3.  Date Exploration        - the time range the race data covers (1950-2024)
    4.  Measures Exploration    - core numeric totals (races, results, points, laps)
    5.  Magnitude               - totals broken down by group/category 
                                  (points per constructor, wins per driver)
    6.  Ranking                 - best and worst performers (top drivers, 
                                  fastest pit stops)
    7.  Change Over Time        - trends by season (points scored, calendar growth)
    8.  Cumulative Analysis     - running totals and moving averages across seasons
    9.  Performance Analysis    - comparisons vs. own career average / prior season
    10. Part-to-Whole Analysis  - % contribution of each driver/constructor to the total
    11. Segmentation            - grouping drivers/constructors into tiers 
                                  (e.g. Legend, Veteran, Rookie)
===============================================================================
*/

/* ============================================================
   DATABASE EXPLORATION
   Purpose: Get familiar with the database structure itself —
   what tables exist and what columns are inside each one.
   Useful as a starting point for anyone new to the project.
   ============================================================ */

-- List every table in the database (name, schema, type)
SELECT * FROM INFORMATION_SCHEMA.TABLES
-- List every column across every table, with its data type
SELECT * FROM INFORMATION_SCHEMA.COLUMNS

/* ============================================================
   DIMENSIONS EXPLORATION
   Purpose: Look at the unique values inside dimension tables to
   understand what categories/groups exist in the data before
   analyzing anything numeric.
   ============================================================ */

-- dim_circuits: how many unique circuits, and which countries host them
SELECT DISTINCT country FROM gold.dim_circuits ORDER BY country;
-- dim_constructors: how many unique constructors, and their nationalities
SELECT DISTINCT nationality FROM gold.dim_constructors ORDER BY nationality;
-- dim_drivers: nationalities represented (too many drivers to list individually)
SELECT DISTINCT nationality FROM gold.dim_drivers ORDER BY nationality;
-- dim_status: this one IS small enough to list every value directly
SELECT DISTINCT status_description FROM gold.dim_status ORDER BY status_description;
-- dim_seasons: full list of years covered
SELECT DISTINCT season_year FROM gold.dim_seasons ORDER BY season_year;
-- dim_races: how many unique race names (Grand Prix events) exist
SELECT DISTINCT race_name FROM gold.dim_races ORDER BY race_name;
-- number of rows in every dimension
SELECT 'dim_circuits' AS dimension, COUNT(*) AS row_count FROM gold.dim_circuits
UNION ALL
SELECT 'dim_constructors', COUNT(*) FROM gold.dim_constructors
UNION ALL
SELECT 'dim_drivers', COUNT(*) FROM gold.dim_drivers
UNION ALL
SELECT 'dim_status', COUNT(*) FROM gold.dim_status
UNION ALL
SELECT 'dim_seasons', COUNT(*) FROM gold.dim_seasons
UNION ALL
SELECT 'dim_races', COUNT(*) FROM gold.dim_races;

/* ============================================================
   DATE EXPLORATION
   Purpose: Understand the time range the data actually covers —
   important before building any trend/time-based analysis later.
   ============================================================ */

-- Overall date range of the entire dataset
SELECT 
    MIN(race_date) AS earliest_race,
    MAX(race_date) AS latest_race,
    DATEDIFF(YEAR, MIN(race_date), MAX(race_date)) AS years_covered
FROM gold.dim_races;
-- Number of races per season, to spot any gaps or unusual years
SELECT 
    season_year,
    COUNT(*) AS races_in_season
FROM gold.dim_races
GROUP BY season_year
ORDER BY season_year;
-- Confirm which seasons actually had sprint races (a newer F1 format)
SELECT 
    season_year,
    COUNT(*) AS races_with_sprint
FROM gold.dim_races
WHERE sprint_date IS NOT NULL
GROUP BY season_year
ORDER BY season_year;
-- Birth year range of drivers, just as a sanity check on dim_drivers
SELECT 
    MIN(birth_date) AS oldest_driver_dob,
    MAX(birth_date) AS youngest_driver_dob
FROM gold.dim_drivers;

/* ============================================================
   MEASURES EXPLORATION
   Purpose: Get the core numeric totals — the "big picture" numbers
   that every other insight will be compared against.
   ============================================================ */

-- One view of all key measures side by side
SELECT 'Total Races' AS measure_name, COUNT(*) AS measure_value FROM gold.dim_races
UNION ALL
SELECT 'Total Drivers', COUNT(*) FROM gold.dim_drivers
UNION ALL
SELECT 'Total Constructors', COUNT(*) FROM gold.dim_constructors
UNION ALL
SELECT 'Total Race Results', COUNT(*) FROM gold.fact_results
UNION ALL
SELECT 'Total Points Scored (all-time)', SUM(points_scored) FROM gold.fact_results
UNION ALL
SELECT 'Total Laps Completed', SUM(laps_completed) FROM gold.fact_results
UNION ALL
SELECT 'Total Pit Stops', COUNT(*) FROM gold.fact_pit_stops
UNION ALL
SELECT 'Total Lap Time Records', COUNT(*) FROM gold.fact_lap_times;

/* ============================================================
   MAGNITUDE
   Purpose: Break the totals down by group/category
   ============================================================ */

-- Total points scored per constructor (all-time)
SELECT 
    c.constructor_name,
    SUM(r.points_scored) AS total_points
FROM gold.fact_results r
JOIN gold.dim_constructors c ON r.constructor_id = c.constructor_id
GROUP BY c.constructor_name
ORDER BY total_points DESC;
-- Total points scored per driver (all-time)
SELECT 
    d.full_name,
    SUM(r.points_scored) AS total_points
FROM gold.fact_results r
JOIN gold.dim_drivers d ON r.driver_id = d.driver_id
GROUP BY d.full_name
ORDER BY total_points DESC;
-- Number of race wins per driver (finishing_position = 1)
SELECT 
    d.full_name,
    COUNT(*) AS total_wins
FROM gold.fact_results r
JOIN gold.dim_drivers d ON r.driver_id = d.driver_id
WHERE r.finishing_position = 1
GROUP BY d.full_name
ORDER BY total_wins DESC;
-- Number of races held per country (via circuits)
SELECT 
    ci.country,
    COUNT(*) AS races_held
FROM gold.dim_races ra
JOIN gold.dim_circuits ci ON ra.circuit_id = ci.circuit_id
GROUP BY ci.country
ORDER BY races_held DESC;
-- Total pit stops per driver
SELECT 
    d.full_name,
    COUNT(*) AS total_pit_stops
FROM gold.fact_pit_stops p
JOIN gold.dim_drivers d ON p.driver_id = d.driver_id
GROUP BY d.full_name
ORDER BY total_pit_stops DESC;
-- Drivers grouped by nationality — count of drivers per nationality
SELECT 
    nationality,
    COUNT(*) AS driver_count
FROM gold.dim_drivers
GROUP BY nationality
ORDER BY driver_count DESC;
-- Races held per season, alongside total points scored that season
SELECT 
    ra.season_year,
    COUNT(DISTINCT ra.race_id) AS races_that_season,
    SUM(r.points_scored) AS total_points_that_season
FROM gold.dim_races ra
JOIN gold.fact_results r ON ra.race_id = r.race_id
GROUP BY ra.season_year
ORDER BY ra.season_year;

/* ============================================================
   RANKING
   Purpose: Identify the best and worst performers
   ============================================================ */

-- Top 10 drivers by all-time points
SELECT TOP 10
    d.full_name,
    SUM(f.points_scored) AS total_points
FROM gold.fact_results f
JOIN gold.dim_drivers d ON f.driver_id = d.driver_id
GROUP BY d.full_name
ORDER BY total_points DESC;
-- Bottom 5 constructors by all-time points (among those who scored at least 1)
SELECT TOP 5
    c.constructor_name,
    SUM(f.points_scored) AS total_points
FROM gold.fact_results f
JOIN gold.dim_constructors c ON f.constructor_id = c.constructor_id
GROUP BY c.constructor_name
HAVING SUM(f.points_scored) > 0
ORDER BY total_points ASC;
-- Top 10 fastest average pit stops (constructor level, building on last step's query)
SELECT TOP 10
    c.constructor_name,
    AVG(p.pit_stop_duration_milliseconds) AS avg_pit_stop_ms
FROM gold.fact_pit_stops p
JOIN gold.fact_results f ON p.race_id = f.race_id AND p.driver_id = f.driver_id
JOIN gold.dim_constructors c ON f.constructor_id = c.constructor_id
GROUP BY c.constructor_name
ORDER BY avg_pit_stop_ms ASC;
-- Top scoring driver for EACH season (not just all-time)
SELECT season_year, full_name, season_points
FROM (
    SELECT 
        r.season_year,
        d.full_name,
        SUM(f.points_scored) AS season_points,
        ROW_NUMBER() OVER (PARTITION BY r.season_year ORDER BY SUM(f.points_scored) DESC) AS rn
    FROM gold.fact_results f
    JOIN gold.dim_drivers d ON f.driver_id = d.driver_id
    JOIN gold.dim_races r ON f.race_id = r.race_id
    GROUP BY r.season_year, d.full_name
) ranked
WHERE rn = 1
ORDER BY season_year;
-- Top 3 constructors by wins, per season (shows multiple ranks per group, not just #1)
SELECT season_year, constructor_name, season_wins, ranking
FROM (
    SELECT 
        r.season_year,
        c.constructor_name,
        COUNT(*) AS season_wins,
        RANK() OVER (PARTITION BY r.season_year ORDER BY COUNT(*) DESC) AS ranking
    FROM gold.fact_results f
    JOIN gold.dim_constructors c ON f.constructor_id = c.constructor_id
    JOIN gold.dim_races r ON f.race_id = r.race_id
    WHERE f.finishing_position = 1
    GROUP BY r.season_year, c.constructor_name
) ranked
WHERE ranking <= 3
ORDER BY season_year, ranking;

/* ============================================================
   CHANGE OVER TIME ANALYTICS
   Purpose: Analyze historical F1 trends across seasons and eras —
   tracking race volume, driver/constructor dominant streaks, 
   and performance evolution.
   ============================================================ */

   -- Total points scored across the whole grid, per season
SELECT 
    r.season_year,
    SUM(f.points_scored) AS total_points
FROM gold.fact_results f
JOIN gold.dim_races r ON f.race_id = r.race_id
GROUP BY r.season_year
ORDER BY r.season_year;
-- Number of races held per season 
SELECT 
    season_year,
    COUNT(*) AS races_in_season
FROM gold.dim_races
GROUP BY season_year
ORDER BY season_year;
-- Average finishing points per driver per season
SELECT 
    r.season_year,
    AVG(f.points_scored) AS avg_points_per_entry
FROM gold.fact_results f
JOIN gold.dim_races r ON f.race_id = r.race_id
GROUP BY r.season_year
ORDER BY r.season_year;
-- Year-over-year change in total points scored
SELECT 
    season_year,
    total_points,
    LAG(total_points) OVER (ORDER BY season_year) AS previous_year_points,
    total_points - LAG(total_points) OVER (ORDER BY season_year) AS year_over_year_change
FROM (
    SELECT 
        r.season_year,
        SUM(f.points_scored) AS total_points
    FROM gold.fact_results f
    JOIN gold.dim_races r ON f.race_id = r.race_id
    GROUP BY r.season_year
) yearly_totals
ORDER BY season_year;
-- Race count growth year-over-year (shows F1's calendar expansion over decades)
SELECT 
    season_year,
    races_in_season,
    LAG(races_in_season) OVER (ORDER BY season_year) AS previous_season_races,
    races_in_season - LAG(races_in_season) OVER (ORDER BY season_year) AS change_in_races
FROM (
    SELECT season_year, COUNT(*) AS races_in_season
    FROM gold.dim_races
    GROUP BY season_year
) season_counts
ORDER BY season_year;

/* ============================================================
   CUMULATIVE ANALYSIS
   Purpose: Track running totals over time — useful for seeing
   the overall growth trajectory.
   ============================================================ */

-- Running total of points scored across all of F1 history, season by season
SELECT 
    season_year,
    total_points,
    SUM(total_points) OVER (ORDER BY season_year) AS running_total_points
FROM (
    SELECT 
        r.season_year,
        SUM(f.points_scored) AS total_points
    FROM gold.fact_results f
    JOIN gold.dim_races r ON f.race_id = r.race_id
    GROUP BY r.season_year
) yearly_totals
ORDER BY season_year;
-- Running total of races held, showing the calendar's cumulative growth over decades
SELECT 
    season_year,
    races_in_season,
    SUM(races_in_season) OVER (ORDER BY season_year) AS cumulative_races_held
FROM (
    SELECT season_year, COUNT(*) AS races_in_season
    FROM gold.dim_races
    GROUP BY season_year
) season_counts
ORDER BY season_year;
-- 3-season moving average of points scored (smooths out single-year spikes from rule changes)
SELECT 
    season_year,
    total_points,
    AVG(total_points) OVER (
        ORDER BY season_year 
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS moving_avg_3_seasons
FROM (
    SELECT 
        r.season_year,
        SUM(f.points_scored) AS total_points
    FROM gold.fact_results f
    JOIN gold.dim_races r ON f.race_id = r.race_id
    GROUP BY r.season_year
) yearly_totals
ORDER BY season_year;
-- Running total of points for the biggest point scorer driver across his career, race by race
SELECT 
    r.race_date,
    r.race_name,
    f.points_scored,
    SUM(f.points_scored) OVER (ORDER BY r.race_date) AS career_running_total
FROM gold.fact_results f
JOIN gold.dim_races r ON f.race_id = r.race_id
JOIN gold.dim_drivers d ON f.driver_id = d.driver_id
WHERE d.driver_reference = 'hamilton'
ORDER BY r.race_date;

/* ============================================================
   PERFORMANCE ANALYSIS
   Purpose: Compare something against its own baseline — either
   its historical average, or the prior year — to judge whether
   it's over/underperforming.
   ============================================================ */

-- For each season hamilton competed in, compare their points that season vs their career average
SELECT 
    d.full_name,
    r.season_year,
    SUM(f.points_scored) AS season_points,
    AVG(SUM(f.points_scored)) OVER (PARTITION BY d.driver_id) AS career_avg_points,
    SUM(f.points_scored) - AVG(SUM(f.points_scored)) OVER (PARTITION BY d.driver_id) AS diff_from_avg
FROM gold.fact_results f
JOIN gold.dim_drivers d ON f.driver_id = d.driver_id
JOIN gold.dim_races r ON f.race_id = r.race_id
WHERE d.driver_reference = 'hamilton'
GROUP BY d.full_name, d.driver_id, r.season_year
ORDER BY r.season_year;
-- Compare each season's points to the hamilton personal best season
SELECT 
    d.full_name,
    r.season_year,
    SUM(f.points_scored) AS season_points,
    MAX(SUM(f.points_scored)) OVER (PARTITION BY d.driver_id) AS best_ever_season,
    CAST(
        SUM(f.points_scored) * 100.0 / NULLIF(MAX(SUM(f.points_scored)) OVER (PARTITION BY d.driver_id), 0) 
    AS DECIMAL(5,2)) AS percent_of_best_season
FROM gold.fact_results f
JOIN gold.dim_drivers d ON f.driver_id = d.driver_id
JOIN gold.dim_races r ON f.race_id = r.race_id
WHERE d.driver_reference = 'hamilton'
GROUP BY d.full_name, d.driver_id, r.season_year
ORDER BY r.season_year;
-- Flag each season as Above Average, Below Average, or Average vs the driver's career average
SELECT 
    d.full_name,
    r.season_year,
    SUM(f.points_scored) AS season_points,
    AVG(SUM(f.points_scored)) OVER (PARTITION BY d.driver_id) AS career_avg_points,
    CASE 
        WHEN SUM(f.points_scored) > AVG(SUM(f.points_scored)) OVER (PARTITION BY d.driver_id) THEN 'Above Average'
        WHEN SUM(f.points_scored) < AVG(SUM(f.points_scored)) OVER (PARTITION BY d.driver_id) THEN 'Below Average'
        ELSE 'Average'
    END AS performance_flag
FROM gold.fact_results f
JOIN gold.dim_drivers d ON f.driver_id = d.driver_id
JOIN gold.dim_races r ON f.race_id = r.race_id
WHERE d.driver_reference = 'hamilton'
GROUP BY d.full_name, d.driver_id, r.season_year
ORDER BY r.season_year;

/* ============================================================
   PART-TO-WHOLE ANALYSIS
   Purpose: See what percentage each group contributes to the
   total, not just its raw value — useful for understanding
   relative importance, not just size.
   ============================================================ */

-- What % of all-time points does each constructor account for
SELECT 
    c.constructor_name,
    SUM(f.points_scored) AS constructor_points,
    SUM(SUM(f.points_scored)) OVER () AS total_points,
    CAST(
        SUM(f.points_scored) * 100.0 / SUM(SUM(f.points_scored)) OVER () 
    AS DECIMAL(5,2)) AS part_of_total
FROM gold.fact_results f
JOIN gold.dim_constructors c ON f.constructor_id = c.constructor_id
GROUP BY c.constructor_name
ORDER BY part_of_total DESC;
-- What % of all-time wins does each driver account for
SELECT 
    d.full_name,
    COUNT(*) AS driver_wins,
    SUM(COUNT(*)) OVER () AS total_wins_all_drivers,
    CAST(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER () 
    AS DECIMAL(5,2)) AS part_of_all_wins
FROM gold.fact_results f
JOIN gold.dim_drivers d ON f.driver_id = d.driver_id
WHERE f.finishing_position = 1
GROUP BY d.full_name
ORDER BY part_of_all_wins DESC;
-- What % of races each season contributes to the full historical calendar
SELECT 
    season_year,
    COUNT(*) AS races_in_season,
    SUM(COUNT(*)) OVER () AS total_races_all_time,
    CAST(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER () 
    AS DECIMAL(5,2)) AS part_of_all_races
FROM gold.dim_races
GROUP BY season_year
ORDER BY season_year;
-- What % of a hamilton own career points came from each constructor he drove for
SELECT 
    d.full_name,
    c.constructor_name,
    SUM(f.points_scored) AS points_with_constructor,
    SUM(SUM(f.points_scored)) OVER (PARTITION BY d.driver_id) AS driver_career_total,
    CAST(
        SUM(f.points_scored) * 100.0 / SUM(SUM(f.points_scored)) OVER (PARTITION BY d.driver_id) 
    AS DECIMAL(5,2)) AS part_of_career_points
FROM gold.fact_results f
JOIN gold.dim_drivers d ON f.driver_id = d.driver_id
JOIN gold.dim_constructors c ON f.constructor_id = c.constructor_id
WHERE d.driver_reference = 'hamilton'
GROUP BY d.full_name, d.driver_id, c.constructor_name
ORDER BY part_of_career_points DESC;

/* ============================================================
   SEGMENTATION & PERFORMANCE TIERING
   Purpose: Group drivers, constructors, and circuits into 
   meaningful competitive buckets (e.g., Champions, Podium Contenders, 
   Mid-field, Backmarkers) to evaluate broader grid dynamics 
   rather than isolated individual rankings.
   ============================================================ */

-- Segment drivers into career tiers based on total career points
SELECT 
    d.full_name,
    SUM(f.points_scored) AS career_points,
    CASE 
        WHEN SUM(f.points_scored) >= 1500 THEN 'Legend'
        WHEN SUM(f.points_scored) >= 500  THEN 'Veteran'
        WHEN SUM(f.points_scored) >= 50   THEN 'Regular'
        ELSE 'Rookie / Backmarker'
    END AS driver_tier
FROM gold.fact_results f
JOIN gold.dim_drivers d ON f.driver_id = d.driver_id
GROUP BY d.full_name
ORDER BY career_points DESC;
-- Count how many drivers fall into each tier
SELECT 
    driver_tier,
    COUNT(*) AS driver_count
FROM (
    SELECT 
        d.full_name,
        SUM(f.points_scored) AS career_points,
        CASE 
            WHEN SUM(f.points_scored) >= 1500 THEN 'Legend'
            WHEN SUM(f.points_scored) >= 500  THEN 'Veteran'
            WHEN SUM(f.points_scored) >= 50   THEN 'Regular'
            ELSE 'Rookie / Backmarker'
        END AS driver_tier
    FROM gold.fact_results f
    JOIN gold.dim_drivers d ON f.driver_id = d.driver_id
    GROUP BY d.full_name
) tiered_drivers
GROUP BY driver_tier
ORDER BY driver_count DESC;
-- Segment constructors by championship consistency: how many seasons they've scored points in
SELECT 
    c.constructor_name,
    COUNT(DISTINCT r.season_year) AS seasons_active,
    CASE 
        WHEN COUNT(DISTINCT r.season_year) >= 20 THEN 'Long-standing Team'
        WHEN COUNT(DISTINCT r.season_year) >= 5  THEN 'Established Team'
        ELSE 'Short-lived Team'
    END AS team_longevity
FROM gold.fact_results f
JOIN gold.dim_constructors c ON f.constructor_id = c.constructor_id
JOIN gold.dim_races r ON f.race_id = r.race_id
GROUP BY c.constructor_name
ORDER BY seasons_active DESC;

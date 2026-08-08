# F1 Data Warehouse — Gold Layer Catalog

**Schema:** `gold`
**Object type:** All objects below are SQL views built on top of `silver` tables.
**Last updated:** 2026-07-24

---

## Overview

| View | Type | Grain | Source Table(s) |
|---|---|---|---|
| `dim_circuits` | Dimension | One row per circuit | `silver.circuits` |
| `dim_constructors` | Dimension | One row per constructor | `silver.constructors` |
| `dim_drivers` | Dimension | One row per driver | `silver.drivers` |
| `dim_status` | Dimension | One row per status code | `silver.status` |
| `dim_seasons` | Dimension | One row per season/year | `silver.seasons` |
| `dim_races` | Dimension | One row per race | `silver.races`, `silver.circuits` |
| `fact_results` | Fact | One row per driver per race | `silver.results` |
| `fact_sprint_results` | Fact | One row per driver per sprint race | `silver.sprint_results` |
| `fact_qualifying` | Fact | One row per driver per qualifying session | `silver.qualifying` |
| `fact_lap_times` | Fact | One row per driver per lap | `silver.lap_times` |
| `fact_pit_stops` | Fact | One row per pit stop | `silver.pit_stops` |
| `fact_driver_standings` | Fact | One row per driver per race (cumulative snapshot) | `silver.driver_standings` |
| `fact_constructor_standings` | Fact | One row per constructor per race (cumulative snapshot) | `silver.constructor_standings` |
| `fact_constructor_results` | Fact | One row per constructor per race | `silver.constructor_results` |

---

## Dimension Views

### `gold.dim_circuits`

One row per Formula 1 circuit.

| Column | Type (inherited) | Description |
|---|---|---|
| `circuit_id` | INT | Primary key. Uniquely identifies the circuit. |
| `circuit_reference` | NVARCHAR | Short internal reference code for the circuit. |
| `circuit_name` | NVARCHAR | Full display name of the circuit. |
| `location` | NVARCHAR | City/town where the circuit is located. |
| `country` | NVARCHAR | Full country name (standardized — e.g. "United Kingdom", not "UK"). |
| `latitude` | DECIMAL(10,6) | Circuit's geographic latitude. |
| `longitude` | DECIMAL(10,6) | Circuit's geographic longitude. |
| `altitude` | INT | Circuit's altitude in meters. May be NULL if not recorded. |
| `wikipedia_url` | NVARCHAR | Link to the circuit's Wikipedia page. |

---

### `gold.dim_constructors`

One row per constructor (team).

| Column | Type (inherited) | Description |
|---|---|---|
| `constructor_id` | INT | Primary key. Uniquely identifies the constructor. |
| `constructor_reference` | NVARCHAR | Short internal reference code for the constructor. |
| `constructor_name` | NVARCHAR | Full display name of the constructor/team. |
| `nationality` | NVARCHAR | Constructor's nationality. |
| `wikipedia_url` | NVARCHAR | Link to the constructor's Wikipedia page. |

---

### `gold.dim_drivers`

One row per driver.

| Column | Type (inherited) | Description |
|---|---|---|
| `driver_id` | INT | Primary key. Uniquely identifies the driver. |
| `driver_reference` | NVARCHAR | Short internal reference code for the driver. |
| `driver_number` | INT | Driver's permanent race number. May be NULL for older/historical drivers. |
| `driver_code` | NVARCHAR | Three-letter driver code (e.g. "HAM"). May be NULL. |
| `full_name` | NVARCHAR | Driver's forename and surname concatenated. |
| `birth_date` | DATE | Driver's date of birth. |
| `nationality` | NVARCHAR | Driver's nationality. |
| `wikipedia_url` | NVARCHAR | Link to the driver's Wikipedia page. |

---

### `gold.dim_status`

One row per race finishing status code (lookup table).

| Column | Type (inherited) | Description |
|---|---|---|
| `status_id` | INT | Primary key. Uniquely identifies the status. |
| `status_description` | NVARCHAR | Human-readable status (e.g. "Finished", "Retired", "Accident"). |

---

### `gold.dim_seasons`

One row per F1 season.

| Column | Type (inherited) | Description |
|---|---|---|
| `season_year` | INT | Primary key. The season's year. |
| `wikipedia_url` | NVARCHAR | Link to the season's Wikipedia page. |

---

### `gold.dim_races`

One row per race. Enriched with the circuit name via a join back to `silver.circuits`, so consumers don't need an extra join for that field.

| Column | Type (inherited) | Description |
|---|---|---|
| `race_id` | INT | Primary key. Uniquely identifies the race. |
| `season_year` | INT | The season this race belongs to. FK → `dim_seasons.season_year`. |
| `circuit_id` | INT | The circuit hosting the race. FK → `dim_circuits.circuit_id`. |
| `circuit_name` | NVARCHAR | Denormalized circuit name (joined from `silver.circuits`) for convenience. |
| `race_round` | INT | The round number within the season. |
| `race_name` | NVARCHAR | Full name of the race (e.g. "Monaco Grand Prix"). |
| `race_date` | DATE | Date the race was held. |
| `race_time` | TIME | Start time of the race. May be NULL for older races. |
| `free_practice_1_date` / `_time` | DATE / TIME | FP1 session date/time. May be NULL. |
| `free_practice_2_date` / `_time` | DATE / TIME | FP2 session date/time. May be NULL. |
| `free_practice_3_date` / `_time` | DATE / TIME | FP3 session date/time. May be NULL. |
| `qualifying_date` / `qualifying_time` | DATE / TIME | Qualifying session date/time. May be NULL. |
| `sprint_date` / `sprint_time` | DATE / TIME | Sprint race date/time. NULL for races without a sprint format. |
| `wikipedia_url` | NVARCHAR | Link to the race's Wikipedia page. |

---

## Fact Views

### `gold.fact_results`

**Grain: one row per driver's classified result in one Grand Prix race.**
The primary fact table of the warehouse — main driver/constructor race outcomes.

| Column | Type (inherited) | Description |
|---|---|---|
| `result_id` | INT | Primary key. |
| `race_id` | INT | FK → `dim_races.race_id`. |
| `constructor_id` | INT | FK → `dim_constructors.constructor_id`. |
| `status_id` | INT | FK → `dim_status.status_id`. |
| `driver_id` | INT | FK → `dim_drivers.driver_id`. |
| `driver_number` | INT | Car number used in this race. May be NULL. |
| `starting_grid_position` | INT | Grid position the driver started from. |
| `finishing_position` | INT | Final classified position. NULL if not classified (DNF, etc.). |
| `finishing_position_text` | NVARCHAR | Text version of finishing status (numeric position, or "Retired"/"Disqualified"/etc.). |
| `finishing_position_order` | INT | Classification order — always populated, even for DNFs. Use this for full-field sorting. |
| `points_scored` | DECIMAL | Championship points earned in this race. |
| `laps_completed` | INT | Number of laps completed. |
| `total_race_time` | NVARCHAR | Race time as text (e.g. "+5.478" or "1:32:00.123"). NULL for non-finishers. |
| `total_race_time_milliseconds` | INT | Race time in milliseconds. NULL for non-finishers. |
| `fastest_lap_number` | INT | Lap number of the driver's fastest lap. May be NULL (not tracked in older seasons). |
| `fastest_lap_rank` | INT | Rank of this driver's fastest lap vs. the rest of the field. May be NULL. |
| `fastest_lap_time` | NVARCHAR | Fastest lap time as text. May be NULL. |
| `fastest_lap_speed_kph` | DECIMAL | Average speed of the fastest lap, km/h. May be NULL. |

---

### `gold.fact_sprint_results`

**Grain: one row per driver's classified result in one sprint race.**
Structurally similar to `fact_results` but for the shorter sprint format (introduced in recent seasons only). Kept as a separate fact table because sprint races have a distinct points system and don't exist for most of F1 history.

| Column | Type (inherited) | Description |
|---|---|---|
| `sprint_result_id` | INT | Primary key. |
| `race_id` | INT | FK → `dim_races.race_id`. |
| `constructor_id` | INT | FK → `dim_constructors.constructor_id`. |
| `status_id` | INT | FK → `dim_status.status_id`. |
| `driver_id` | INT | FK → `dim_drivers.driver_id`. |
| `driver_number` | INT | Car number used in this sprint. |
| `starting_grid_position` | INT | Grid position for the sprint. |
| `finishing_position` | INT | Final classified sprint position. NULL if not classified. |
| `finishing_position_text` | NVARCHAR | Text version of finishing status. |
| `finishing_position_order` | INT | Classification order, always populated. |
| `points_scored` | DECIMAL | Points earned in the sprint. |
| `laps_completed` | INT | Laps completed in the sprint. |
| `total_sprint_time` | NVARCHAR | Sprint time as text. |
| `total_sprint_time_milliseconds` | INT | Sprint time in milliseconds. |
| `fastest_lap_number` | INT | Lap number of the fastest lap in the sprint. |
| `fastest_lap_time` | NVARCHAR | Fastest lap time as text. |

**Note:** Does not include `fastest_lap_rank` or `fastest_lap_speed_kph` — these aren't tracked for sprint sessions in the source data.

---

### `gold.fact_qualifying`

**Grain: one row per driver's qualifying session in one race.**

| Column | Type (inherited) | Description |
|---|---|---|
| `qualifying_id` | INT | Primary key. |
| `race_id` | INT | FK → `dim_races.race_id`. |
| `constructor_id` | INT | FK → `dim_constructors.constructor_id`. |
| `driver_id` | INT | FK → `dim_drivers.driver_id`. |
| `driver_number` | INT | Car number used in qualifying. |
| `qualifying_position` | INT | Final qualifying position. |
| `qualifying_1_time` | NVARCHAR | Q1 lap time as text. NULL if not set. |
| `qualifying_2_time` | NVARCHAR | Q2 lap time as text. NULL if driver didn't advance to Q2. |
| `qualifying_3_time` | NVARCHAR | Q3 lap time as text. NULL if driver didn't advance to Q3. |

**Note:** A high volume of NULLs in `qualifying_2_time`/`qualifying_3_time` is expected — most drivers are eliminated before Q3.

---

### `gold.fact_lap_times`

**Grain: one row per driver per lap per race.** The most granular fact table in the warehouse.

| Column | Type (inherited) | Description |
|---|---|---|
| `race_id` | INT | FK → `dim_races.race_id`. Part of composite key. |
| `driver_id` | INT | FK → `dim_drivers.driver_id`. Part of composite key. |
| `lap_number` | INT | The lap number. Part of composite key. |
| `position_in_lap` | INT | Driver's track position at the end of this lap. |
| `lap_time` | NVARCHAR | Lap time as text (e.g. "1:23.456"). |
| `lap_time_milliseconds` | INT | Lap time in milliseconds — use this for numeric analysis/aggregation. |

**Composite key:** `(race_id, driver_id, lap_number)` uniquely identifies a row.

---

### `gold.fact_pit_stops`

**Grain: one row per pit stop.**

| Column | Type (inherited) | Description |
|---|---|---|
| `race_id` | INT | FK → `dim_races.race_id`. Part of composite key. |
| `driver_id` | INT | FK → `dim_drivers.driver_id`. Part of composite key. |
| `lap_number` | INT | The lap on which the pit stop occurred. |
| `stop_number` | INT | This driver's Nth stop of the race. Part of composite key. |
| `pit_stop_time` | TIME | Clock time of day the stop occurred. |
| `pit_stop_duration` | NVARCHAR | Duration of the stop as text (seconds, e.g. "23.451"). |
| `pit_stop_duration_milliseconds` | INT | Stop duration in milliseconds — use this for numeric analysis/aggregation. |

**Composite key:** `(race_id, driver_id, stop_number)` uniquely identifies a row.

---

### `gold.fact_driver_standings`

**Grain: one row per driver per race — a cumulative championship snapshot as of that race**, not a per-race event. Points/wins are running totals, not what was earned in that single race.

| Column | Type (inherited) | Description |
|---|---|---|
| `driver_standings_id` | INT | Primary key. |
| `driver_id` | INT | FK → `dim_drivers.driver_id`. |
| `race_id` | INT | FK → `dim_races.race_id`. The race after which this snapshot was taken. |
| `total_points` | DECIMAL | Cumulative championship points as of this race. |
| `standing_position` | INT | Championship position as of this race. NULL if not classified. |
| `standing_position_text` | NVARCHAR | Text version of standing (e.g. "Disqualified"). |
| `total_wins` | INT | Cumulative race wins as of this race. |

---

### `gold.fact_constructor_standings`

**Grain: one row per constructor per race — a cumulative championship snapshot**, same pattern as `fact_driver_standings` but for constructors.

| Column | Type (inherited) | Description |
|---|---|---|
| `constructor_standings_id` | INT | Primary key. |
| `constructor_id` | INT | FK → `dim_constructors.constructor_id`. |
| `race_id` | INT | FK → `dim_races.race_id`. The race after which this snapshot was taken. |
| `total_points` | DECIMAL | Cumulative championship points as of this race. |
| `standing_position` | INT | Championship position as of this race. |
| `standing_position_text` | NVARCHAR | Text version of standing (e.g. "Excluded"). |
| `total_wins` | INT | Cumulative race wins as of this race. |

---

### `gold.fact_constructor_results`

**Grain: one row per constructor per race.** Constructor-level points, kept separate from `fact_results` (which is driver-grain) so constructor-level reporting doesn't require a `GROUP BY` aggregation every time.

| Column | Type (inherited) | Description |
|---|---|---|
| `constructor_results_id` | INT | Primary key. |
| `constructor_id` | INT | FK → `dim_constructors.constructor_id`. |
| `race_id` | INT | FK → `dim_races.race_id`. |
| `points_scored` | DECIMAL | Points earned by the constructor in this race. |
| `result_status` | NVARCHAR | Usually NULL. Populated only for exceptions (e.g. "Disqualification"). |


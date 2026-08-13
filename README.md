# F1 Data Warehouse

A Medallion Architecture (Bronze → Silver → Gold) data warehouse built on Microsoft SQL Server, using the Ergast Formula 1 dataset (1950–2024).

This project was built to practice real-world data engineering patterns — ETL pipeline design, data cleaning, and dimensional modeling — using an original dataset rather than a common tutorial dataset, so the design decisions and data issues encountered are genuinely my own.

**Status: Core warehouse complete.** Bronze, Silver, and Gold layers are built and functional, with a full exploratory and advanced analytics layer on top. A Power BI dashboard layer is in progress — see [Roadmap](#roadmap) below.

---

## Architecture

```
┌─────────────┐      ┌─────────────┐      ┌─────────────┐
│   BRONZE    │  →   │   SILVER    │  →   │    GOLD     │
│ Raw CSV     │      │ Cleaned &   │      │galaxy schema│
│ ingestion   │      │ typed data  │      │ (dims/facts)│
└─────────────┘      └─────────────┘      └─────────────┘
```

- **Bronze** — 14 tables, one per source CSV, loaded via a single stored procedure (`bronze.load_bronze`). All columns kept as `VARCHAR` to guarantee the raw load never fails on a malformed row.
- **Silver** — 14 cleaned, typed tables. Nulls standardized, types cast, quote-stripped text, and business-meaningful letter codes (e.g. driver/constructor status codes) mapped to readable labels. See [Known Data Quirks](#known-data-quirks-worth-knowing) below.
- **Gold** — a galaxy schema exposed as views: 6 dimension tables and 8 fact tables at varying grains (per-race, per-lap, per-pit-stop, championship-standings snapshots). Fully documented in [`docs/gold_layer_catalog.md`](docs/gold_layer_catalog.md).
- **Analytics** — a full SQL-based exploratory and advanced analytics layer on top of the Gold views: database/dimension/date/measures exploration, magnitude and ranking analysis, change-over-time and cumulative analysis using window functions, performance benchmarking, part-to-whole analysis, and driver/constructor segmentation.

---

## Repository Structure

```
├── database/
│   └── 01_database_and_schema_creation.sql
├── bronze/
│   ├── 02_bronze_table_creation.sql
│   └── 03_bulk_insertion_into_tables.sql
├── silver/
│   ├── 04_silver_table_creation.sql
│   └── 05_data_cleaning_and_transformation.sql
├── gold/
│   └── 06_gold_layer_views.sql
├── analytics/
│   └── 07_eda_and_advanced_analytics.sql
├── docs/
|   ├── F1_Data_Warehouse_Power_BI.pbix
│   ├── gold_layer_catalog.md
│   ├── tables_modeling.drawio       (raw table relationships)
│   └── gold_layer_erd.drawio        (galaxy schema: dims + facts, color-coded)
└── README.md
```

---

## Dataset

Source: [Ergast F1 dataset on Kaggle](https://www.kaggle.com/) — 14 CSV files covering circuits, constructors, drivers, races, results, lap times, pit stops, qualifying, and championship standings from 1950 through 2024.

> Raw CSV files are not committed to this repo. Download the dataset from Kaggle and place the CSVs in a local folder before running the bronze load scripts (update the file paths in `03_bulk_insertion_into_tables.sql` to match your local setup).

---

## Known Data Quirks Worth Knowing

A few real issues encountered and solved during this build — documented here both as project notes and as a demonstration of the debugging process:

- **Null convention:** Ergast represents missing values as the literal string `\N`, not a true SQL `NULL`. Every silver transformation applies `NULLIF(..., '\N')` before casting.
- **SQL Server `BULK INSERT` bug:** Combining `FORMAT = 'CSV'` with `FIRSTROW = 2` (or any header-skip) fails with a provider-level error (`IID_IColumnsInfo`). Workaround: load with `FIRSTROW = 1` (including the header row) and delete the header row by matching against its own column name.
- **Reserved keywords:** `results.rank` requires bracket-escaping (`[rank]`) since `RANK` is a reserved SQL Server keyword.
- **Status/position codes:** `positionText` columns across multiple tables use single-letter codes for non-finishers — `D` (Disqualified), `E` (Excluded), `F` (Failed to Qualify), `N` (Not Classified), `R` (Retired), `W` (Withdrawn) — mapped to readable labels during silver cleaning.
- **`position` vs. `positionText` vs. `positionOrder`:** three related but distinct columns in the results tables — `position` is numeric and NULL for non-finishers, `positionText` holds the letter code or number as display text, and `positionOrder` is always populated and represents full-field classification order regardless of finishing status.
- **Composite keys:** `lap_times` and `pit_stops` have no single-column ID — uniqueness comes from `(race_id, driver_id, lap)` and `(race_id, driver_id, stop)` respectively.
- **Free-text vs. coded status:** `fact_constructor_results.result_status` looks similar to `fact_results.status_id` but is actually a plain free-text column (only ever `NULL` or `"Disqualification"`), not a foreign key into `dim_status` — confirmed via `SELECT DISTINCT`, not assumed.

---

## Roadmap

- [x] Bronze layer — raw ingestion, all 14 tables
- [x] Silver layer — cleaning, typing, standardization
- [x] Gold layer — galaxy schema (6 dimensions, 8 facts)
- [x] Exploratory & advanced analytics (SQL-based, 11 categories)
- [x] Power BI Data Modeling and Visual Dashboards
---

## Tools Used

- Microsoft SQL Server / SSMS
- Power BI (data modeling / Visual Dashboards)
- draw.io (data modeling / ER diagrams)
- Ergast F1 dataset (via Kaggle)

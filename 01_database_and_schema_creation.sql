/*
===============================================================================
Description: Data Warehouse Architecture Setup
===============================================================================
This script initializes the foundational database environment for a Formula 1 
Data Warehouse by creating the primary database and defining a multi-tiered 
Medallion Architecture (Bronze, Silver, Gold schemas).

Schema Architecture Breakdown:
-------------------------------------------------------------------------------
1. Database Creation:
   - F1_DataWarehouse: The primary database container for all data assets.

2. Medallion Schemas:
   - Bronze: Raw Data Layer
     Holds unmodified, raw ingestion data direct from source systems (e.g., CSVs, APIs).
   
   - Silver: Cleaned & Transformed Layer
     Stores standardized, cleansed, deduplicated, and validated data ready for analysis.
   
   - Gold: Analytical / Reporting Layer
     Contains business-ready aggregations, star-schema models (facts & dimensions), 
     and data optimized for BI reporting and dashboards.
===============================================================================
*/
create database F1_DataWarehouse
go
create schema Bronze
go
create schema Silver
go
create schema Gold
go
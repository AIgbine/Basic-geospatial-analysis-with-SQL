# Basic-geospatial-analysis-with-SQL
This is an evaluation following lectures on PostgreSQL and Postgis for geospatial analysis

**Geospatial analysis using SQL and Qgis**

**Objective**: Utilise Python and SQL (Postgis) to analyse a dataset. 

**Tools**: An SQL editor, Qgis

**Data**: Shapefile of commune 77

**Activities**: 
* The first step is to create a database (db) using PostgreSQL and enable the Postgis extension on this db.
* With Postgis enabled, we can load the shapefile into the db using Qgis’s PostgreSQL connector to connect to the db.
* Check for polygon validity and make invalid polygons valid
* Import a parquet file using ogr2ogr command line.
* Carry out specified analyses.


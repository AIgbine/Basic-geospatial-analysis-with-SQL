-------------------------
-- ENSG MASTER GDM 2024 |
-------------------------

------------------------------------------------------------------------------------------------------------------
-- SQL and Postgis Evaluation questions
-- Complete this file by adding the SQL queries answering each question
-- below to perform the evaluation.
-- You can copy the result of queries after the query, with comments (-- at the beginning of a line) to show correct
-- result for the question
-- (or create image screenshots as asked in the question)
-- (GIS data needed for this evaluation are provided inside the eval_postgres_2024.zip file)
------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------
-- question 1
-- create a new database called "eval" and install postgis extension on it
-- load the provided shapefile contained in communes_77.zip into the eval database, under a table named "communes_77",
-- either with a command line (ogr2ogr, shp2pgsql) or with QGIS:
--    • If you loaded communes_77.shp with QGIS, provide a screenshot named q1.png or q1.jpg of the QGIS interface allowing to
--      load data into postgis, with suitable fields filled.
--    • If you loaded communes_77.shp with a command line, copy the command line you used here

CREATE DATABASE eval;
CREATE EXTENSION postgis;
select * from communes_77;
------------------------------------------------------------------------------------------------------------------
-- question 2
-- Are the polygons of the communes_77 table valid ?
-- Give the name of invalid communes and the reason for the invalidity:
select id, nomcom, st_isvalidreason(geom)
FROM communes_77
WHERE not st_isvalid(geom);

-----------------------RESULT-----------------------------
-- 516,Beton-Bazoches,Self-intersection[717387.311820743 6848077.87394194]
----------------------------------------------------------

------------------------------------------------------------------------------------------------------------------
-- question 3
-- validate invalid geometries for the commune_77 table and update the table:

-- checking result of make_valid
SELECT id, nomcom, c.geom AS initial_geom, st_makeValid(geom) AS valid_geom
FROM communes_77 c
WHERE not st_isvalid(geom);

--updating invalid geom
update communes_77 set geom = st_collectionextract(st_makeValid(geom), 3)
where not st_isvalid(geom);

-- check that all are valid:
select id, st_isvalidreason(geom)
from communes_77
where not st_isvalid(geom);

------------------------RESULT----------------------------------
--None

------------------------------------------------------------------------------------------------------------------
-- question 4
-- check all communes are valid now by counting the number of invalid geometries in the table:
select count(st_isvalidreason(geom))
from communes_77
where not st_isvalid(geom);

------------------------------------RESULT-------------------------------------
------COUNT
       --0

------------------------------------------------------------------------------------------------------------------
-- question 5
-- load the provided parquet file named "temperature-quotidienne-departementale.parquet" into the eval database,
-- under a table named "daily_temp". Use ogr2ogr command line for that and provide the command line you use here:
--
    -----------COMMAND LINE QUERY-----------------------------------------------------------------
--ogr2ogr -f PostgreSQL PG:"dbname=eval user=postgres password=postgis host=localhost port=5434" temperature-quotidienne-departementale.parquet -nln daily_temp
------------------------------------------------------------------------------------------------------------------
-- question 6
-- modify the type of the date_obs column in the daily_temp table: choose the right postgres data type according to
-- the values you see in the column

    -- modify type from varchar to date format
ALTER TABLE daily_temp
ALTER COLUMN date_obs TYPE DATE
using to_date(date_obs, 'YYYY-MM-DD');
------------------------------------------------------------------------------------------------------------------
-- question 7
-- what is the range of observation dates (column date_obs) in the daily_temp table ?
SELECT
    MIN(date_obs) AS MIN_date,
    MAX(date_obs) AS MAX_date
FROM daily_temp;

------------------RESULT--------------------------------
    -----min_date | max_date
    ---2018-01-01 | 2024-08-31
------------------------------------------------------------------------------------------------------------------
-- question 8
-- what are the maximum and minimum temperatures for each year for the departement 77, ordered by year ?
-- query must return the year, the maximum, the minimum temperatures
-- (tip: read the postgresql documentation for date functions: https://www.postgresql.org/docs/17/functions-datetime.html)
SELECT
    extract(year FROM date_obs) AS year,
    max(tmax) AS max_temp,
    min(tmin) AS min_temp
FROM daily_temp
WHERE
    code_insee_departement = '77'
GROUP BY
    year;
------------------------------------------------------------------------------------------------------------------
-- question 9
-- what is the year, the month (expressed in letter, like january, february, ...),
-- the departement (name) and the maximum temperature across daily_temp table ?
SELECT
    EXTRACT(YEAR FROM date_obs) AS year,
    TO_CHAR(date_obs, 'Month') AS month,
    departement,
    MAX(tmax) AS max_temp
FROM
    daily_temp
GROUP BY
    year, month, departement
ORDER BY
    max_temp DESC
LIMIT 1;

----------------RESULT--------------------------------------
--year | month | department | max_temp
--2019 | June  | Vaucluse   | 42.77

------------------------------------------------------------------------------------------------------------------
-- question 10
-- Find all the commmunes touching the smallest commune in the communes_77 table.
-- query must return the name of the smallest communes, its area in km2, and the
-- names of all touching communes, but not the smallest one
-- use a CTE (with tmp as (...)) to find the smallest commune
WITH smallest_commune AS (
    SELECT
        id,
        nomcom,
        ST_Area(geom)/1000000 AS area,
        geom
    FROM communes_77
    ORDER BY area
    LIMIT 1
)
SELECT
    sc.nomcom AS smallest_commune,
    sc.area AS smallest_commune_area_km2,
    c.nomcom AS touching_communes
FROM
    smallest_commune sc
        JOIN
    communes_77 c
    ON
        ST_Touches(sc.geom, c.geom)
WHERE
    sc.nomcom != c.nomcom;

------------------------------------------------------------------------------------------------------------------
-- question 11
-- Find all the communes that are closer than 15km to "Lumigny-Nesles-Ormeaux"
-- query must return the name of the commune "Lumigny-Nesles-Ormeaux", the distance in meters between this communes
-- and other communes, the name of other communes. Find suitable aliases for the column name to have a nice result.
-- result must be ordered by closest communes and commune name
SELECT
    com.nomcom AS reference_commune,
    ROUND(ST_Distance(com.geom, c.geom)) AS distance_meters,
    c.nomcom AS close_communes
FROM
    communes_77 com
        JOIN
    communes_77 c
    ON
        ST_Distance(com.geom, c.geom) < 15000
WHERE
    com.nomcom = 'Lumigny-Nesles-Ormeaux' and
    com.nomcom != c.nomcom
ORDER BY
    distance_meters, c.nomcom;

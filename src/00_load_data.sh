#!/usr/bin/env bash
# Loads the raw + processed CSVs in this repo into a local PostgreSQL
# database called vancouver_crime. Run from the repo root:
#
#   createdb vancouver_crime
#   bash src/00_load_data.sh
#
# Requires: unzip, psql on PATH, a running local Postgres server you can
# connect to without extra flags (adjust the psql calls below if you use a
# non-default host/user).

set -euo pipefail

echo "Unzipping raw crime data..."
unzip -o data/raw/crimedata_csv_AllNeighbourhoods_AllYears.zip -d data/raw/ > /dev/null

echo "Creating schema..."
psql -d vancouver_crime -f src/01_create_schema.sql

echo "Extracting population-by-local-area from the census export..."
python3 src/00b_extract_population.py

echo "Loading data..."
psql -d vancouver_crime -c "\copy census_population_2016(local_area, population_2016) FROM 'data/processed/census_population_2016.csv' WITH (FORMAT csv, HEADER true)"
psql -d vancouver_crime -c "\copy neighbourhood_crosswalk(vpd_neighbourhood, census_local_area, notes) FROM 'data/processed/neighbourhood_crosswalk.csv' WITH (FORMAT csv, HEADER true, NULL '')"
psql -d vancouver_crime -c "\copy crime_incidents(crime_type, incident_year, incident_month, incident_day, incident_hour, incident_minute, hundred_block, neighbourhood, x_coord, y_coord) FROM 'data/raw/crimedata_csv_AllNeighbourhoods_AllYears.csv' WITH (FORMAT csv, HEADER true, NULL '')"

echo "Done. 926,506 incident rows + 22 population rows + 24 crosswalk rows expected."

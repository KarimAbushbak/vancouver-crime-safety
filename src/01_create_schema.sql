-- Vancouver Crime & Public Safety project — schema
-- Run: psql -d vancouver_crime -f src/01_create_schema.sql

DROP TABLE IF EXISTS crime_incidents;
DROP TABLE IF EXISTS neighbourhood_crosswalk;
DROP TABLE IF EXISTS census_population_2016;

-- Raw VPD incident-level data (Vancouver Police Department GeoDASH open data,
-- "Founded" incidents only, 2003-2026)
CREATE TABLE crime_incidents (
    incident_id     BIGSERIAL PRIMARY KEY,
    crime_type      TEXT NOT NULL,
    incident_year   SMALLINT NOT NULL,
    incident_month  SMALLINT NOT NULL,
    incident_day    SMALLINT NOT NULL,
    incident_hour   SMALLINT NOT NULL,
    incident_minute SMALLINT NOT NULL,
    hundred_block   TEXT,
    neighbourhood   TEXT,
    x_coord         DOUBLE PRECISION,
    y_coord         DOUBLE PRECISION
);

-- City of Vancouver 2016 Census Local Area Profiles — total population by
-- local planning area (Statistics Canada custom order for the City)
CREATE TABLE census_population_2016 (
    local_area      TEXT PRIMARY KEY,
    population_2016 INTEGER NOT NULL
);

-- Manual crosswalk: VPD's 24 policing neighbourhoods -> the census's 22
-- local planning areas (names don't line up 1:1 -- see notes column)
CREATE TABLE neighbourhood_crosswalk (
    vpd_neighbourhood  TEXT PRIMARY KEY,
    census_local_area  TEXT REFERENCES census_population_2016(local_area),
    notes              TEXT
);

CREATE INDEX idx_crime_year ON crime_incidents(incident_year);
CREATE INDEX idx_crime_neighbourhood ON crime_incidents(neighbourhood);
CREATE INDEX idx_crime_type ON crime_incidents(crime_type);

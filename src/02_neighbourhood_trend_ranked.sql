-- Which neighbourhoods diverged from Vancouver's citywide crime decline?
--
-- Citywide incident volume fell in most years 2015-2025 (post-pandemic decline
-- after a 2019 peak). This script ranks neighbourhoods by how their per-capita
-- incident rate moved over that same window, using CTEs + window functions
-- (LAG, RANK) rather than raw counts, so a growing neighbourhood isn't hidden
-- by a shrinking one just because both round to similar totals.
--
-- Run: psql -d vancouver_crime -f src/02_neighbourhood_trend_ranked.sql

WITH mapped_incidents AS (
    -- Join incident-level rows to their census local area via the crosswalk;
    -- drops Stanley Park (no residents) and Musqueam (no matching census figure)
    SELECT ci.incident_year, ci.crime_type, cw.census_local_area
    FROM crime_incidents ci
    JOIN neighbourhood_crosswalk cw ON cw.vpd_neighbourhood = ci.neighbourhood
    WHERE cw.census_local_area IS NOT NULL
      AND ci.incident_year BETWEEN 2015 AND 2025
),
yearly_counts AS (
    SELECT census_local_area, incident_year, COUNT(*) AS incidents
    FROM mapped_incidents
    GROUP BY census_local_area, incident_year
),
yearly_rates AS (
    -- per-capita rate per 1,000 residents (population held at the 2016 census
    -- snapshot across all years -- see README caveats)
    SELECT yc.census_local_area,
           yc.incident_year,
           yc.incidents,
           p.population_2016,
           ROUND(yc.incidents::numeric / p.population_2016 * 1000, 2) AS incidents_per_1000
    FROM yearly_counts yc
    JOIN census_population_2016 p ON p.local_area = yc.census_local_area
),
endpoints AS (
    -- first and last year actually present for each neighbourhood in the window
    SELECT census_local_area,
           MIN(incident_year) AS first_year,
           MAX(incident_year) AS last_year
    FROM yearly_rates
    GROUP BY census_local_area
),
trend AS (
    SELECT e.census_local_area,
           f.incidents_per_1000 AS rate_first,
           l.incidents_per_1000 AS rate_last,
           e.first_year,
           e.last_year,
           ROUND((l.incidents_per_1000 - f.incidents_per_1000)
                 / f.incidents_per_1000 * 100, 1) AS pct_change_per_capita
    FROM endpoints e
    JOIN yearly_rates f ON f.census_local_area = e.census_local_area AND f.incident_year = e.first_year
    JOIN yearly_rates l ON l.census_local_area = e.census_local_area AND l.incident_year = e.last_year
)
SELECT census_local_area,
       first_year,
       rate_first  AS incidents_per_1000_first_year,
       last_year,
       rate_last   AS incidents_per_1000_last_year,
       pct_change_per_capita,
       RANK() OVER (ORDER BY pct_change_per_capita DESC) AS growth_rank
FROM trend
ORDER BY pct_change_per_capita DESC;

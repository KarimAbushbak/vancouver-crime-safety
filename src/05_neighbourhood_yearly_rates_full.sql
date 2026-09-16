-- Full per-capita crime rate series (every neighbourhood x every year,
-- 2015-2025) -- the export this script produces feeds the Power BI line
-- chart directly, since 02_neighbourhood_trend_ranked.sql only keeps the
-- first/last year for each neighbourhood.
--
-- Run: psql -d vancouver_crime -f src/05_neighbourhood_yearly_rates_full.sql

WITH mapped_incidents AS (
    SELECT ci.incident_year, cw.census_local_area
    FROM crime_incidents ci
    JOIN neighbourhood_crosswalk cw ON cw.vpd_neighbourhood = ci.neighbourhood
    WHERE cw.census_local_area IS NOT NULL
      AND ci.incident_year BETWEEN 2015 AND 2025
),
yearly_counts AS (
    SELECT census_local_area, incident_year, COUNT(*) AS incidents
    FROM mapped_incidents
    GROUP BY census_local_area, incident_year
)
SELECT yc.census_local_area,
       yc.incident_year,
       yc.incidents,
       p.population_2016,
       ROUND(yc.incidents::numeric / p.population_2016 * 1000, 2) AS incidents_per_1000
FROM yearly_counts yc
JOIN census_population_2016 p ON p.local_area = yc.census_local_area
ORDER BY yc.census_local_area, yc.incident_year;

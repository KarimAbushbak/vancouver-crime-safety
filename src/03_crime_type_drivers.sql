-- For the neighbourhoods flagged as growing in 02_neighbourhood_trend_ranked.sql
-- (Renfrew-Collingwood, Sunset), which specific crime types are driving that
-- growth, and how does each type's share of that neighbourhood's total change
-- over time? Uses a CTE + window functions (SUM() OVER for a running yearly
-- total per type, and share-of-total via a second window partition).
--
-- Run: psql -d vancouver_crime -f src/03_crime_type_drivers.sql

WITH mapped_incidents AS (
    SELECT ci.incident_year, ci.crime_type, cw.census_local_area
    FROM crime_incidents ci
    JOIN neighbourhood_crosswalk cw ON cw.vpd_neighbourhood = ci.neighbourhood
    WHERE cw.census_local_area IN ('Renfrew-Collingwood', 'Sunset')
      AND ci.incident_year IN (2015, 2025)
),
type_counts AS (
    SELECT census_local_area,
           crime_type,
           incident_year,
           COUNT(*) AS incidents
    FROM mapped_incidents
    GROUP BY census_local_area, crime_type, incident_year
),
pivoted AS (
    SELECT census_local_area,
           crime_type,
           MAX(CASE WHEN incident_year = 2015 THEN incidents ELSE 0 END) AS incidents_2015,
           MAX(CASE WHEN incident_year = 2025 THEN incidents ELSE 0 END) AS incidents_2025
    FROM type_counts
    GROUP BY census_local_area, crime_type
),
deltas AS (
    SELECT census_local_area,
           crime_type,
           incidents_2015,
           incidents_2025,
           incidents_2025 - incidents_2015 AS net_change,
           -- each type's share of this neighbourhood's TOTAL net change (can be
           -- negative for types that fell while the neighbourhood overall rose)
           ROUND(
               (incidents_2025 - incidents_2015)::numeric
               / NULLIF(SUM(incidents_2025 - incidents_2015) OVER (PARTITION BY census_local_area), 0)
               * 100, 1
           ) AS pct_of_neighbourhood_net_change
    FROM pivoted
)
SELECT census_local_area,
       crime_type,
       incidents_2015,
       incidents_2025,
       net_change,
       pct_of_neighbourhood_net_change,
       RANK() OVER (PARTITION BY census_local_area ORDER BY net_change DESC) AS driver_rank
FROM deltas
ORDER BY census_local_area, net_change DESC;

-- Citywide incident trend, year over year, with a running (cumulative) total.
-- Demonstrates LAG() for year-over-year %% change and SUM() OVER for a running
-- total -- and deliberately surfaces a real data-quality issue: VPD's public
-- export has no rows at all for 2022, so a naive "previous row" LAG would
-- silently compare 2023 to 2021 as if they were consecutive years. This query
-- computes the actual year gap so that's visible in the output instead of
-- hidden.
--
-- Run: psql -d vancouver_crime -f src/04_citywide_yearly_trend.sql

WITH yearly AS (
    SELECT incident_year, COUNT(*) AS incidents
    FROM crime_incidents
    WHERE incident_year BETWEEN 2003 AND 2025   -- exclude 2026 (partial year)
    GROUP BY incident_year
),
with_lag AS (
    SELECT incident_year,
           incidents,
           LAG(incident_year) OVER (ORDER BY incident_year) AS prev_year_present,
           LAG(incidents)     OVER (ORDER BY incident_year) AS prev_year_incidents,
           SUM(incidents)     OVER (ORDER BY incident_year) AS running_total_incidents
    FROM yearly
)
SELECT incident_year,
       incidents,
       running_total_incidents,
       prev_year_present,
       (incident_year - prev_year_present) AS year_gap,
       CASE
           WHEN prev_year_incidents IS NULL THEN NULL
           ELSE ROUND((incidents - prev_year_incidents)::numeric / prev_year_incidents * 100, 1)
       END AS pct_change_vs_prev_available_year
FROM with_lag
ORDER BY incident_year;

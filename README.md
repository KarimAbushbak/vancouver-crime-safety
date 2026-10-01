# Vancouver Crime & Public Safety — Neighbourhood Trend Analysis

A SQL + Power BI project: which Vancouver neighbourhoods have crime trends
that are moving in the *opposite* direction from the rest of the city, and
what's actually driving that?

## The question

Vancouver's overall crime volume has fallen substantially over the last
decade. Does every neighbourhood share that decline, or are there specific
areas where crime — on a per-resident basis — is still rising? And if so,
which crime types are responsible?

## Data sources

**VPD GeoDASH Open Data — Crime Incidents**
https://geodash.vpd.ca/opendata/
"Founded" incidents only, all years, all neighbourhoods. 926,506 incidents,
2003–2026 (2026 is partial, through September). 11 crime types, 24 official
VPD policing neighbourhoods. `TYPE, YEAR, MONTH, DAY, HOUR, MINUTE,
HUNDRED_BLOCK, NEIGHBOURHOOD, X, Y` schema.

**City of Vancouver Open Data Portal — Census Local Area Profiles 2016**
https://opendata.vancouver.ca/explore/dataset/census-local-area-profiles-2016/
Statistics Canada's 2016 Census, custom-ordered by the City for its 22 local
planning areas. Used here for total population per area, to convert incident
counts into a per-capita rate.

Both files are small enough to ship directly in `data/raw/` — see
`data/raw/README.md`.

## Method

1. **`src/01_create_schema.sql`** — PostgreSQL schema: `crime_incidents`
   (incident-level, 926,506 rows), `census_population_2016` (22 rows),
   `neighbourhood_crosswalk` (24 rows).
2. **`src/00b_extract_population.py`** — pulls the total-population row out
   of the census portal's wide, report-formatted export into a tidy table.
3. **Neighbourhood crosswalk** (`data/processed/neighbourhood_crosswalk.csv`)
   — VPD's 24 policing neighbourhoods and the census's 22 local planning
   areas don't share one naming scheme. Built a manual crosswalk, the same
   kind of approximation as the FSA-to-zone mapping in the
   [affordability-gap project](https://github.com/KarimAbushbak/vancouver-affordability-gap):
   - `Central Business District` (VPD) ↔ `Downtown` (census) — same area,
     different name.
   - `Stanley Park` and `Musqueam` have no separate census population figure
     (a park with no residents, and a reserve not broken out in the City's
     22-area profile) — both excluded from the per-capita analysis rather
     than assigned a population that would understate their rate.
4. **`src/02_neighbourhood_trend_ranked.sql`** — CTEs joining incident
   counts to population by neighbourhood-year, computing an incidents-per-
   1,000-residents rate, then comparing each neighbourhood's first vs. last
   available year in the 2015–2025 window and ranking the % change with
   `RANK() OVER (...)`.
5. **`src/03_crime_type_drivers.sql`** — for the neighbourhoods flagged as
   growing, breaks the 2015→2025 change down by crime type, with a window
   function computing each type's share of that neighbourhood's *total* net
   change (`SUM() OVER (PARTITION BY ...)` as the denominator).
6. **`src/04_citywide_yearly_trend.sql`** — citywide trend with `LAG()` for
   year-over-year % change and `SUM() OVER (ORDER BY ...)` for a running
   total. Uses the actual year of the previous row (not just "year - 1") so
   the 2022 data gap (see caveats) shows up as a 2-year jump instead of
   silently being treated as consecutive.
7. **`src/05_neighbourhood_yearly_rates_full.sql`** — the full per-capita
   rate series (every neighbourhood × every year) that feeds the Power BI
   line chart.

Re-running `src/00_load_data.sh` against a fresh database reproduces every
number in this README from the raw files in `data/raw/`.

## Findings

**Two neighbourhoods out of 22 are moving against the citywide trend.**
Between 2015 and 2025, Renfrew-Collingwood's per-capita crime rate rose
16.4% (38.33 → 44.61 incidents per 1,000 residents) and Sunset's rose 15.7%
(28.68 → 33.18 per 1,000). Every other neighbourhood fell — most by 25–55%
— over the same window, and the citywide median move was solidly negative.

**In both growing neighbourhoods, one crime type explains the entire
increase.** "Other Theft" (VPD's catch-all category for theft that isn't a
vehicle, bicycle, or break-and-enter) more than doubled in both areas —
+895 incidents in Renfrew-Collingwood (606 → 1,501, or 276% of that
neighbourhood's total net change) and +369 in Sunset (260 → 629, 225% of its
net change). Every other crime type in both neighbourhoods held flat or
fell; without the Other Theft increase, both neighbourhoods would show a
decline in line with the rest of the city.

**Citywide, 2020–2021 was the sharpest drop in the whole 2003–2025 series**
(-22.1% in 2020, a further -14.2% in 2021), consistent with pandemic-era
disruption, followed by a partial rebound and then a renewed decline through
2025.

## Caveats

- Population is held at its 2016 census snapshot for every year in the
  2015–2025 window. Real population has almost certainly shifted since
  (particularly in fast-developing areas), so per-capita rates in the most
  recent years carry more uncertainty than the 2015–2016 end of the series.
- The neighbourhood crosswalk (`data/processed/neighbourhood_crosswalk.csv`)
  is a reasonable approximation, not official geography — see Method above.
- VPD's public export has no incidents at all for 2022. This looks like a
  genuine gap in what's published rather than an actual crime-free year;
  `src/04_citywide_yearly_trend.sql` flags it explicitly rather than hiding
  it inside a year-over-year calculation.
- "Other Theft" is a broad VPD category (not further broken down in the open
  data) — this analysis can say it's driving the increase, not specifically
  what kind of theft.

## Power BI dashboard

`data/processed/neighbourhood_yearly_rates_full.csv` and
`data/processed/crime_type_drivers.csv` are the two files to load into Power
BI. See `docs/power_bi_guide.md` for the step-by-step build (line chart of
per-capita rate by neighbourhood with Renfrew-Collingwood/Sunset highlighted,
plus a crime-type breakdown visual with a filter action).

## Cloud pipeline (Azure)

A separate, automated ingestion path for this same dataset: Azure Data
Factory orchestrates a weekly pull from VPD's GeoDASH source into Data Lake
Storage, Azure Databricks transforms it into a curated Delta table, and Power
BI connects to that table directly via the Databricks connector — no manual
CSV re-export required to keep the dashboard current. See
`docs/azure_pipeline.md` for the full architecture, pipeline steps, and
setup notes/gotchas.

## Setup

```
pip install -r requirements.txt
createdb vancouver_crime
bash src/00_load_data.sh
psql -d vancouver_crime -f src/02_neighbourhood_trend_ranked.sql
psql -d vancouver_crime -f src/03_crime_type_drivers.sql
psql -d vancouver_crime -f src/04_citywide_yearly_trend.sql
```

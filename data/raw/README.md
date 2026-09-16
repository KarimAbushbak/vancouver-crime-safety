# Raw data

Both source files are small enough to include directly in this repo.

## `crimedata_csv_AllNeighbourhoods_AllYears.zip`

Vancouver Police Department GeoDASH open data — "Founded" incidents only,
all years, all neighbourhoods:
https://geodash.vpd.ca/opendata/

Downloaded via the portal's interactive export form (it doesn't expose a
direct-link API). Unzip before use — `src/00_load_data.sh` does this
automatically:

```
unzip crimedata_csv_AllNeighbourhoods_AllYears.zip
```

Yields `crimedata_csv_AllNeighbourhoods_AllYears.csv` (926,506 rows),
`legal_disclaimer.txt`, and `VPD OpenData Crime Incidents Description.pdf`.

**Known data quality note:** the export has no rows at all for 2022 — VPD's
public GeoDASH export appears to have a genuine gap that year (2021 and 2023
are both present and unremarkable in volume, and the description PDF doesn't
document it). All analysis scripts treat this as a real gap rather than
assuming consecutive years.

## `census_local_area_profiles_2016.csv`

City of Vancouver Open Data Portal, "Census local area profiles 2016" —
Statistics Canada 2016 Census custom order for the City's 22 local planning
areas:
https://opendata.vancouver.ca/explore/dataset/census-local-area-profiles-2016/

A wide, report-formatted export (one row per census variable, one column per
local area) rather than a tidy table — `src/00b_extract_population.py` pulls
out just the total population row.

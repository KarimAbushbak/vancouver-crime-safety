# Resume bullet options

For the PROJECTS section, second entry (below Vancouver's Affordability
Gap). Pick one, or use the first as the lead bullet and the second/third as
supporting detail if space allows — same 3-bullet format as the existing
Projects entry.

## Option A — single bullet, most resume space-efficient

> Analyzed 926K+ VPD crime records in PostgreSQL (CTEs, window functions,
> multi-table joins with census population data) to identify 2 of 22
> Vancouver neighbourhoods with rising per-capita crime against a citywide
> decline; built a Power BI dashboard to visualize the trend

## Option B — three bullets (matches the affordability-gap project's format)

> - Modeled a PostgreSQL database from 926K+ Vancouver Police Department
>   crime records (2003–2025) joined to City of Vancouver census population
>   data via a custom neighbourhood crosswalk
> - Wrote CTE- and window-function-based SQL (RANK, LAG, partitioned SUM) to
>   rank neighbourhoods by per-capita crime trend and isolate which crime
>   type drove each trend, surfacing 2 neighbourhoods with rising crime
>   against a citywide decline
> - Built a Power BI dashboard with cross-filtered trend and driver-breakdown
>   visuals; documented findings, data caveats, and a reproducible load
>   script on GitHub

## Option C — one line, tools-forward (if the resume needs to read fast)

> Built a SQL + Power BI project on 926K+ Vancouver crime records —
> multi-table joins, CTEs, and window functions to rank neighbourhood crime
> trends and identify their primary drivers

---

**Numbers used above, for reference:**
- 926,506 incident rows, VPD GeoDASH open data, 2003–2026
- 2 of 22 neighbourhoods (Renfrew-Collingwood +16.4%, Sunset +15.7%) rose in
  per-capita crime rate 2015→2025 while the rest fell
- "Other Theft" accounted for 276% and 225% of each neighbourhood's net
  change respectively (i.e. it's the entire story — every other crime type
  fell or held flat)

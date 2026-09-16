# Power BI dashboard — setup & build guide

This project's SQL output feeds a Power BI dashboard. These are the steps to
build it in Power BI Desktop.

## 1. Install Power BI Desktop

Power BI Desktop is Windows-only and free.
1. Go to https://www.microsoft.com/en-us/power-platform/products/power-bi/downloads
2. Download and install "Power BI Desktop" (via the Microsoft Store link or
   the direct .exe — either works).
3. Open it and sign in with a free Microsoft account if prompted (a work/
   school account isn't required just to build and view a local .pbix file).

## 2. Load the data

Power BI can connect directly to PostgreSQL, but the simplest path — and the
one that keeps this repo fully reproducible without a running database — is
to load the two CSV exports directly:

1. **Home → Get Data → Text/CSV**
2. Load `data/processed/neighbourhood_yearly_rates_full.csv`
3. Repeat for `data/processed/crime_type_drivers.csv`
4. In the Power Query editor, confirm `incident_year` is typed as a **Whole
   Number** (not text) and `incidents_per_1000` as **Decimal Number** —
   Power BI usually infers these correctly, but check before loading.
5. Click **Close & Apply**.

(If you'd rather connect live: **Get Data → PostgreSQL database**, server
`localhost`, database `vancouver_crime`, and point it at the same query in
`src/05_neighbourhood_yearly_rates_full.sql` as a native query.)

## 3. Build the main visual: per-capita trend by neighbourhood

1. Add a **Line chart**.
2. X-axis: `incident_year`. Y-axis: `incidents_per_1000`. Legend:
   `census_local_area`.
3. With 22 lines this is unreadable by default — right-click the legend
   field → **Edit visual interactions**, or simpler: add a **slicer** on
   `census_local_area` so the viewer can pick which neighbourhoods to show.
4. Pre-select Renfrew-Collingwood, Sunset, and 2-3 large-decline
   neighbourhoods (e.g. Downtown, Kitsilano) as the default slicer
   selection, so the "two neighbourhoods bucking the trend" story is visible
   on first load.
5. Format → Data colors: manually set Renfrew-Collingwood and Sunset to a
   distinct warm color (e.g. red/orange) and leave the rest in cooler/gray
   tones, so the diverging pair reads immediately.

## 4. Build the drill-down visual: crime type drivers

1. Add a **Clustered bar chart** using the `crime_type_drivers` table.
2. Axis: `crime_type`. Value: `net_change`. Legend or a slicer:
   `census_local_area` (filtered to Renfrew-Collingwood / Sunset).
3. Add a **Card** visual showing `pct_of_neighbourhood_net_change` for the
   top row (Other Theft) to call out the "single category explains the
   entire increase" finding.

## 5. Wire up the interaction

1. Click a neighbourhood in the trend chart's slicer → confirm the crime
   type bar chart updates via Power BI's default cross-filtering (it does
   this automatically between visuals built from related/matching fields;
   if the two tables aren't related, add a relationship on
   `census_local_area` in **Model view**).
2. Add a text box or a "Findings" page summarizing the two headline numbers
   (16.4% and 15.7%) so the dashboard stands on its own without the README.

## 6. Publish

- **File → Publish → Publish to Power BI** (needs a Power BI account — the
  free tier is enough for a personal workspace).
- From the published report, use **File → Embed → Publish to web** if you
  want a public, no-login link to put in this README and on a resume/
  portfolio site (same pattern as the Tableau dashboard in the
  affordability-gap project). Note: "Publish to web" makes the report
  visible to anyone with the link, so only do this with a project you're
  fine sharing publicly (true here — this is public open data).

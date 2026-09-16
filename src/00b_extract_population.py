"""
Extracts total population per local area from the raw census export (a wide,
report-formatted CSV with metadata rows and one row per census variable) into
a tidy local_area,population_2016 table.

Run from the repo root: python src/00b_extract_population.py
(needs data/raw/census_local_area_profiles_2016.csv)
"""
import pandas as pd

df = pd.read_csv(
    "data/raw/census_local_area_profiles_2016.csv",
    skiprows=4,
    encoding="latin1",
)

# Row ID 1 is "Total - Age groups and average age of the population - 100% data"
row = df[df["ID"] == "1"].iloc[0]

# Every column except ID/Variable/the two citywide totals is a local area
skip = {"ID", "Variable", "Vancouver CSD", "Vancouver CMA"}
areas = [c for c in df.columns if c.strip() not in skip and c not in ("ID", "Variable")]

out = pd.DataFrame(
    [{"local_area": a.strip(), "population_2016": int(row[a].replace(",", ""))} for a in areas]
)
out.to_csv("data/processed/census_population_2016.csv", index=False)
print(f"Wrote data/processed/census_population_2016.csv ({len(out)} local areas)")

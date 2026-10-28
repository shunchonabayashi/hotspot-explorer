# Food–Energy–Infrastructure Hotspot Explorer

[Open the published Explorer](https://shunchonabayashi.github.io/hotspot-explorer/)

An R Shiny / Shinylive real-data pilot for **Sunamganj, Bangladesh**, and four neighbouring Bangladesh districts: Habiganj, Kishoreganj, Netrakona and Sylhet. Prepared 29 October 2026. It replaces the fictional District A demonstration.

## What is real and what is assessed?

The app uses public World Bank Space2Stats ADM2 flood-exposure statistics and World Bank Official Boundaries. All 64 Bangladesh district codes match. Sunamganj was selected because these sources provide complete national coverage and a substantial exposure estimate, with four clearly identifiable domestic neighbours.

The available indicator is **2020 modelled population exposed to flood depth greater than 15 cm for a 1-in-100 return-period hazard** (Fathom v3 / WorldPop). The source is not an observed flood event; the ADM2 CSV does not specify the hazard reference year. The pilot does not claim a 2050 climate projection.

Users can:

- Select a district from the menu or by clicking its actual polygon.
- Screen by exposed population share or exposed population count.
- Compare with all 64 Bangladesh districts (default) or the five pilot districts.
- Change the inclusive percentile cutoff (default 90).
- Download a 64-district CSV with source precision, settings and explicit missing-assessment labels, or a selected-district printable HTML report.

**Exposure screening is not a completed hotspot or investment-gap assessment.** Future climate change, service/network disruption, economic losses, infrastructure needs, AIIB coverage, other providers, investment gaps, responses and costs are not assessed. The remaining pressure components are explicitly marked unassessed; there are no fictional substitute values.

## Methods and limits

- Share = `100 * pop_flood / pop`, using counts from the same flood-exposure table. The source `pop_flood_pct` is retained for audit but is not used because it does not reproduce this district ratio.
- Percentile = `100 * (rank(x, ties.method="max") - 1) / (N - 1)`. Larger values mean higher exposure; ties receive the same highest rank. Flag at `percentile >= cutoff`. The cutoff is arbitrary and adjustable. National ranks are recomputed from all 64 source records, not from the five polygons shown.
- Counts emphasize the number exposed; shares emphasize concentration. Changing the comparison or cutoff never changes exposure estimates. A five-district comparison has 25-point percentile steps and should be interpreted cautiously.
- Space2Stats H3 level 6 cells are approximately 36 km². Detailed outlines do not imply equally detailed exposure estimates. District boundaries and cell assignment can affect estimates. UI counts are rounded to the nearest 1,000; the CSV retains source precision.
- The exposure release is June 2025. Boundary geometry was retrieved in October 2026. Code matching is complete, but exact boundary-vintage equivalence is not established.
- Neighbours share more than 100 m of boundary in UTM 46N, computed before map simplification. Only Bangladesh districts are included. The national inset locates the five-district pilot. Geometry is repaired where necessary and simplified by 180 m for display; no exposure overlay is recalculated from that simplified geometry.
- The choropleth shows district screening, not flood extent. High exposure is not proof of economic loss or an investment gap.

## Sources and attribution

- [World Bank Space2Stats catalog](https://datacatalog.worldbank.org/search/dataset/0066820/space2stats-database), [original ADM2 flood CSV](https://datacatalogfiles.worldbank.org/ddh-published/0066820/DR0095355/adm2_flood_exposure_15cm_1in100.csv).
- [Flood metadata](https://raw.githubusercontent.com/worldbank/DECAT_Space2Stats/main/space2stats_api/src/space2stats_ingest/METADATA/stac/space2stats-collection/flood_exposure_15cm_1in100/flood_exposure_15cm_1in100.json): Fathom 3.0 and WorldPop; Wing et al. (2024), A 30 m Global Flood Inundation Model for Any Climate Scenario, https://doi.org/10.1029/2023WR036460.
- [World Bank Official Boundaries catalog](https://datacatalog.worldbank.org/search/dataset/0038272/world-bank-official-boundaries), [ADM2 feature service](https://services.arcgis.com/iQ1dY19aHwbSDYIF/ArcGIS/rest/services/World_Bank_Global_Administrative_Divisions/FeatureServer/3).

Both World Bank published datasets are licensed **CC BY 4.0**. Attribution: World Bank Space2Stats / WorldPop / Fathom v3; World Bank Official Boundaries. This pilot derives shares and ranks and adapts map geometry. Boundary depiction implies no endorsement. `app/data/provenance.json` records URLs, hashes, preparation time and processing notes; `source_flood_bgd.csv` preserves the source Bangladesh records.

## Run locally

From this repository root in R:

```r
install.packages(c("shiny", "shinylive"))
shiny::runApp("app")
```

Build the browser-only version and preview it:

```r
source("build.R")
httpuv::runStaticServer("site")
```

Open the local HTTP URL printed by R, not the file directly. First load downloads browser-based R and packages and may take about a minute. After startup the assessment runs in the browser, with no external Shiny server or API key. The exported `site/` is ignored by Git. The tested browser assets are pinned to Shinylive 0.10.12; use a fresh output directory when deliberately upgrading them.

## Reproduce the data preparation

With Python and the spatial packages in `data-prep/requirements.txt`:

```text
python -m pip install -r data-prep/requirements.txt
python data-prep/prepare_pilot.py
```

This downloads the source CSV and district boundaries and regenerates the compact data and map paths. It is not required to run the app or the Pages build. Future source revisions can change results; inspect provenance and tests before publishing refreshed data.

Run the R checks from repository root:

```text
Rscript tests/model.R
```

## GitHub Pages

The repository at [shunchonabayashi/hotspot-explorer](https://github.com/shunchonabayashi/hotspot-explorer) publishes through GitHub Actions. The workflow installs R 4.4.3 with system dependencies on Ubuntu 24.04, runs the model checks, exports the app, and deploys `site/`.

For a copy, put this folder's contents at the new repository root, use a `main` branch, and select **Settings → Pages → Source → GitHub Actions**. No secrets or Shiny hosting account are needed. The source and included data are public. Do not upload unrelated project emails, confidential documents or local package libraries.

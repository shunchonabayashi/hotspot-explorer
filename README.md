# Food–Energy–Infrastructure Hotspot Explorer

A small R Shiny prototype, exportable with Shinylive for GitHub Pages. Prepared for team discussion on 29 October 2026.

**All data, projects, costs and boundaries are fictional.** This is a demonstration of the assessment workflow, not a real risk assessment or investment recommendation.

## Features

- Six pressure components, using the values in the team's District A illustration.
- Select a pressure and change the inclusive percentile cutoff (default 90).
- District A highlighted on a schematic map; surrounding districts have no assessment data.
- Separate hotspot identification, infrastructure needs, investment coverage, potential gap assessment and responses.
- All-six-pressure table, CSV export and a printable HTML assessment with settings and generation time. Save the HTML report as PDF through your browser's print dialog.
- Responsive layout. Only the Shiny package is needed by the application; no basemap keys or spatial-package downloads.

## Run locally

In R, with this folder as the working directory:

```r
install.packages(c("shiny", "shinylive"))
shiny::runApp("app")
```

## Build and preview the browser-only version

```r
source("build.R")
httpuv::runStaticServer("site")
```

Open the local URL printed by R. Do not open `site/index.html` directly from the filesystem. The browser downloads R/WebAssembly and packages on first load, so initial startup can take time and requires internet access. Once loaded, assessment calculations run in the browser.

The supplied `site/` folder is already exported for local preview and is excluded from Git. `build.R` selects the tested Shinylive 0.10.12 browser assets. If you deliberately change that version, export into a fresh `site/` directory to avoid mixing runtime files. See `TESTING.md` for the checks performed.

## Publish on GitHub Pages

1. Create a repository for this prototype. Put **the contents of this Explorer folder at its root**, including `.github/workflows/pages.yml`. Do not upload the parent AIIB folder, email files, confidential documents or the local R package library.
2. Use a `main` branch. In the repository, select **Settings → Pages → Source → GitHub Actions**.
3. Push the files to `main`, or run **Actions → Build and publish Explorer → Run workflow**.
4. The workflow installs the build packages, runs the model checks, exports `app/` into a static `site/`, and deploys it. The deployment shows the resulting Pages URL.

No external Shiny server, secrets or API keys are required. Publishing makes the included fictional data and code downloadable by visitors. Repository/organization Pages policies may affect availability. This folder is prepared for publication; no repository has been created and no live site has been published automatically.

## Interpretation and limits

- Comparison is fixed to 100 fictional districts within Country X, using **supplied percentiles**. There is no underlying 100-district distribution. Do not offer alternative comparison areas until their data exist.
- Only one hypothetical 2050 scenario is provided. Baseline/future consequences are fixed; the cutoff changes screening, not flood modelling.
- A hotspot is identified at `percentile >= cutoff`, independently of projects. The default 90 is arbitrary and adjustable.
- For screened hotspots, supplied coverage evidence determines a potential gap or a request to review coverage. Below-cutoff components retain a local-review message; absence of a flag does not establish adequate coverage.
- Neighbouring polygons and routes are schematic. No real coordinates, flood extents or project points are implied.
- Infrastructure-need descriptions are illustrative interpretations. Costs are not appraisals. Different consequence percentiles are not comparable losses; do not sum effects or costs.
- CSV and HTML exports are implemented; native Word export and server-side GIS simulations are outside this prototype.

## Files

`app/app.R`: interface and exports. `app/model.R`: fictional data and screening logic. `app/www/style.css`: styling. `tests/model.R`: threshold and export checks. `build.R`: static export. `.github/workflows/pages.yml`: build/deployment workflow.

## Documentation

- [Shinylive for R](https://posit-dev.github.io/r-shinylive/)
- [GitHub Pages deployment workflows](https://docs.github.com/en/pages/getting-started-with-github-pages/using-custom-workflows-with-github-pages)

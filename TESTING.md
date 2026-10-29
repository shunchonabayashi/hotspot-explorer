# Real-data pilot validation — 29 October 2026

## Source and calculation checks

- 64 unique Bangladesh ADM2 records match the official boundary codes, with five pilot polygons and 64 national locator polygons.
- Every exposed population is between zero and its corresponding source population; shares independently reproduce 100 × source pop_flood / source pop.
- Sunamganj exposure share is 85.7726393404495%; its national share rank is 2 of 64 and its max-rank percentile is 98.4126984126984.
- Its verified domestic neighbours are Habiganj, Kishoreganj, Netrakona and Sylhet. Adjacency is computed before simplification.
- National versus pilot comparison, count versus share, inclusive cutoffs, immutable source values and export metadata are tested in `tests/model.R`.
- Missing climate, service and investment assessments remain explicit, with no invented project counts or costs.

## Application checks

Regular Shiny starts and renders the source-based map and tables. Local browser-only Shinylive checks passed. The [GitHub build and deployment](https://github.com/shunchonabayashi/hotspot-explorer/actions/runs/40788531911) passed its source/calculation checks, static export and Pages deployment.

The public site was checked in a fresh Edge browser session after deployment. All checks passed: real Sunamganj default data and national rank; five selectable district polygons and 64 locator polygons; selecting Sylhet by polygon click; count versus share; national versus five-district comparison; changed cutoff and reset; both downloads; selected-district report settings, HTML metadata and source attribution; 64-row CSV; no page-width overflow at 390 pixels. No District A or Country X substitute data appear in the real-data view.

See `app/data/provenance.json` for exact source URLs, hashes and processing notes. The fictional illustration is restored as an isolated Shiny module, with a clearly labelled switch and its own controls and downloads. It is not mixed into the real-data pilot. Local Shinylive checks passed for both direct links, switching, control isolation, fictional CSV/HTML exports, real 64-district CSV export and mobile widths.

The [two-view deployment](https://github.com/shunchonabayashi/hotspot-explorer/actions/runs/40798548044) passed. The same two-view browser checks also passed on the public GitHub Pages site, including direct selection through `?view=real` and `?view=illustration`. The public HTML retains `noindex, nofollow, noarchive`.

# Real-data pilot validation — 29 October 2026

## Source and calculation checks

- 64 unique Bangladesh ADM2 records match the official boundary codes, with five pilot polygons and 64 national locator polygons.
- Every exposed population is between zero and its corresponding source population; shares independently reproduce 100 × source pop_flood / source pop.
- Sunamganj exposure share is 85.7726393404495%; its national share rank is 2 of 64 and its max-rank percentile is 98.4126984126984.
- Its verified domestic neighbours are Habiganj, Kishoreganj, Netrakona and Sylhet. Adjacency is computed before simplification.
- National versus pilot comparison, count versus share, inclusive cutoffs, immutable source values and export metadata are tested in `tests/model.R`.
- Missing climate, service and investment assessments remain explicit, with no invented project counts or costs.

## Application checks

Regular Shiny starts and renders the source-based map and tables. Browser-only Shinylive interaction and download checks are performed before publication; the public URL is rechecked after deployment. The GitHub workflow runs the source/calculation checks before exporting.

See `app/data/provenance.json` for exact source URLs, hashes and processing notes. The original fictional demonstration remains accessible only through Git history; it is not mixed into the real-data pilot.

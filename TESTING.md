# Prototype checks — 29 October 2026

Passed:

- R model checks: default 90th-percentile flags; inclusive 98th-percentile boundary; below-cutoff behavior; project evidence unchanged by cutoff; six-row export and metadata.
- Regular R Shiny application starts and renders.
- Static Shinylive export loads in a fresh background Microsoft Edge browser, served by a plain static HTTP server with no R backend connection.
- Selecting coastal flooding displays its supplied data; lowering the cutoff to 85 flags the 85th-percentile result.
- Reset restores river flooding and cutoff 90.
- Both CSV and HTML files download successfully; their contents include fictional-data labels and the residual crossing-gap evidence.
- Desktop and mobile layouts inspected; no page-width overflow at 390 pixels. The summary table permits horizontal scrolling within its container.

Browser assets: Shinylive 0.10.12, explicitly selected in `build.R`. The application uses base R and Shiny; no GIS package or API key is needed. The download buttons include Posit's documented Shinylive/Chromium compatibility workaround.

GitHub Pages publication has not been run. The workflow must be tested in the destination repository after Pages is enabled. There are no real-data accuracy claims.

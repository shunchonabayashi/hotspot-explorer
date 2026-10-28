# Run from the Explorer repository root after installing shiny and shinylive.
shinylive::export('app', 'site', assets_version = '0.10.12')
index <- readLines('site/index.html', warn = FALSE)
index <- sub('<title>Shiny App</title>', '<title>Hotspot Explorer | Sunamganj real-data pilot</title>', index, fixed = TRUE)
writeLines(index, 'site/index.html')
file.create('site/.nojekyll')

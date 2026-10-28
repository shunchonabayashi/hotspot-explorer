# Run from the Explorer repository root after installing shiny and shinylive.
shinylive::export('app', 'site', assets_version = '0.10.12')
index <- readLines('site/index.html', warn = FALSE)
index <- sub('<title>Shiny App</title>', '<title>Hotspot Explorer | Sunamganj real-data pilot</title>', index, fixed = TRUE)
writeLines(index, 'site/index.html')
# Discourage search indexing of the app and exported editor pages.
# Keep crawling allowed so search engines can read the noindex directive.
for (page in list.files('site', pattern = '\\.html$', recursive = TRUE, full.names = TRUE)) {
  html <- paste(readLines(page, warn = FALSE), collapse = '\n')
  html <- sub('<head>', '<head>\n<meta name="robots" content="noindex, nofollow, noarchive">', html, fixed = TRUE)
  writeLines(html, page)
}
file.create('site/.nojekyll')

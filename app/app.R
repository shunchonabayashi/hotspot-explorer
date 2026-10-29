library(shiny)
source('model.R', local = TRUE)
# Posit's Shinylive/Chromium download compatibility workaround.
browser_download <- function(...) {
  button <- shiny::downloadButton(...); button$attribs$download <- NULL; button
}
all_districts <- district_data()
pilot <- all_districts[all_districts$pilot_area == 1, ]
default_id <- all_districts$id[all_districts$default_district == 1]
local_geometry <- read.csv('data/local_map.csv', stringsAsFactors = FALSE)
country_geometry <- read.csv('data/country_map.csv', stringsAsFactors = FALSE)
people <- function(x) paste0('~', format(round(x, -3), big.mark = ',', scientific = FALSE, trim = TRUE))
pct <- function(x) sprintf('%.1f%%', x)
escape <- function(x) as.character(htmltools::htmlEscape(x))
stamp <- function() format(Sys.time(), '%Y-%m-%d %H:%M UTC', tz = 'UTC')
source_links <- function() tagList(
  p(a('World Bank Space2Stats: ADM2 flood-exposure data', href = 'https://datacatalog.worldbank.org/search/dataset/0066820/space2stats-database', target = '_blank', rel = 'noopener')),
  p(a('Download source flood-exposure CSV', href = 'https://datacatalogfiles.worldbank.org/ddh-published/0066820/DR0095355/adm2_flood_exposure_15cm_1in100.csv', target = '_blank', rel = 'noopener')),
  p(a('World Bank Official Boundaries', href = 'https://datacatalog.worldbank.org/search/dataset/0038272/world-bank-official-boundaries', target = '_blank', rel = 'noopener')),
  p('Attribution: World Bank Space2Stats / WorldPop / Fathom v3; World Bank Official Boundaries. Both published datasets are CC BY 4.0. This pilot recalculates shares and ranks and simplifies map geometry.'))
ui <- fluidPage(
  tags$head(tags$meta(name = 'viewport', content = 'width=device-width, initial-scale=1'),
    tags$meta(name = 'robots', content = 'noindex, nofollow, noarchive'), tags$link(rel = 'stylesheet', href = 'style.css')),
  div(class = 'masthead', div(class = 'eyebrow', 'REAL-DATA PILOT | BANGLADESH'), h1('Food–Energy–Infrastructure Hotspot Explorer'), p('Sunamganj and neighbouring districts • Public modelled flood-exposure data')),
  div(class = 'demo-banner', strong('Real data, limited assessment'), ' — 2020 population exposed to modelled flooding. Future climate changes, service disruption and investment gaps are not yet assessed.'),
  div(class = 'workspace',
    tags$aside(class = 'controls card', h2('Customize assessment'),
      selectInput('country', 'Country', choices = c('Bangladesh' = 'BGD'), selected = 'BGD'),
      p(class = 'hint', 'Bangladesh is the only country with data in this pilot. Additional countries can be added as their data are prepared.'),
      selectInput('district', 'District', choices = setNames(pilot$id, pilot$district), selected = default_id),
      selectInput('metric', 'Map and screening indicator', choices = c('Population share exposed (%)' = 'share', 'People exposed (count)' = 'count')),
      selectInput('comparison', 'Percentile comparison', choices = c('Bangladesh: all 64 districts' = 'country', 'Pilot area: five districts' = 'pilot')),
      sliderInput('cutoff', 'Exposure cutoff (percentile)', min = 0, max = 100, value = 90, step = 1),
      p(class = 'hint', 'Adjustable screening choice: a percentile at or above the cutoff is flagged. This is not a validated hotspot definition.'), uiOutput('comparison_note'),
      div(class = 'field-label', 'Hazard definition'), p('Flood depth >15 cm; 1-in-100 return period'), p(class = 'hint', 'The source does not separate flood types in this table. No 2050 scenario is included.'),
      actionButton('reset', 'Reset settings', class = 'btn-outline'), hr(), h3('Download assessment'),
      browser_download('csv', '64-district data (CSV)'), browser_download('report', 'Selected district report (HTML)'), p(class = 'hint', 'Open the HTML report in a browser and print or save it as PDF.')),
    tags$main(class = 'results',
      div(class = 'card', h2('Sunamganj and neighbouring districts'), p(class = 'hint', 'Click a district or use the selector. Polygons show district-level screening, not the location or extent of floodwater.'),
        div(class = 'map-layout', div(uiOutput('map')), div(class = 'locator', h3('Location in Bangladesh'), uiOutput('locator'))),
        div(class = 'legend', span(class = 'key high', ''), 'At or above cutoff', span(class = 'key low', ''), 'Below cutoff', span(class = 'selected-key', ''), 'Selected district'),
        p(class = 'hint map-caption', 'North is up. Bangladesh neighbours sharing a boundary with Sunamganj are shown; districts across the international border are outside this pilot.')),
      uiOutput('detail'),
      div(class = 'card', h2('Compare the five pilot districts'), uiOutput('table_note'), div(class = 'table-scroll', tableOutput('overview'))),
      div(class = 'card', h2('Coverage of the wider framework'), p('This first real-data pilot covers population exposure to flooding. It does not replace the full service-disruption and investment assessment.'), div(class = 'table-scroll', tableOutput('coverage'))),
      div(class = 'card methods', h2('Sources and interpretation'), source_links(),
        tags$details(tags$summary('Methods, dates and limitations'),
          p('The exposure table was released in June 2025 and uses 2020 modelled population. Flood depth is greater than 15 cm for a 1-in-100 return-period hazard (about 1% annual exceedance probability). This is neither an observed event nor a 2050 forecast. The ADM2 CSV does not specify a hazard reference year.'),
          p('District share = 100 × exposed population / total population, using both counts from the same flood-exposure table. We do not use its supplied pop_flood_pct field: district shares are recalculated from summed counts.'),
          p('Percentile = 100 × (ascending max rank − 1) / (N − 1). Ties receive the same highest rank. Default comparison: all 64 Bangladesh districts. The optional five-district comparison changes ranks, not exposure estimates. Counts emphasize scale; shares emphasize concentration.'),
          p('Space2Stats aggregates its inputs using H3 level 6 cells (approximately 36 km²). District estimates are approximate, particularly near boundaries. Detailed polygon outlines do not imply equally detailed exposure estimates. Displayed counts are rounded to the nearest 1,000; downloads retain source precision.'),
          p('Data are joined to World Bank district boundaries by ADM2CD_c, with complete 64-district code coverage. Geometry was retrieved in October 2026; exact equivalence to the exposure layer’s boundary vintage is not established. Geometry is repaired where needed and simplified for display. Neighbours are identified from shared boundaries before simplification.'),
          p('High exposure alone does not establish vulnerability, loss, infrastructure need or an investment gap. Validate service networks, project locations, relevant coverage and other providers before making investment claims. Boundaries and names are for visualization and imply no endorsement.'))))),
  div(class = 'footer', 'R Shiny / Shinylive • Real-data pilot prepared 29 October 2026 • World Bank sources, CC BY 4.0'))
server <- function(input, output, session) {
  data <- reactive(assess(all_districts, input$cutoff, input$metric, input$comparison))
  selected <- reactive(data()[match(input$district, data()$id), , drop = FALSE])
  observeEvent(input$district_click, { if (input$district_click %in% pilot$id) updateSelectInput(session, 'district', selected = input$district_click) })
  observeEvent(input$reset, {
    updateSelectInput(session, 'district', selected = default_id); updateSelectInput(session, 'metric', selected = 'share')
    updateSelectInput(session, 'comparison', selected = 'country'); updateSliderInput(session, 'cutoff', value = 90)
  })
  output$comparison_note <- renderUI({
    if (input$comparison == 'pilot') p(class = 'hint', 'Five districts is a small comparison set: percentile steps are 25 points. Use the national comparison for the default screen.')
    else p(class = 'hint', 'Ranks use all 64 districts, even though the main map shows only five.')
  })
  output$map <- renderUI({
    d <- data()
    paths <- vapply(seq_len(nrow(local_geometry)), function(i) {
      g <- local_geometry[i, ]; z <- d[match(g$id, d$id), ]; active <- g$id == input$district
      fill <- if (z$above_cutoff) '#dc8c43' else '#b8d9d4'
      click <- paste0("Shiny.setInputValue('district_click','", g$id, "',{priority:'event'});")
      tooltip <- paste0(z$district, ': ', pct(z$exposed_share_pct), '; ', people(z$exposed_population), ' people exposed. Select district.')
      paste0('<path class="district-polygon" role="button" tabindex="0" aria-label="', escape(tooltip), '" onclick="', click,
        '" onkeydown="if(event.key===\'Enter\'||event.key===\' \'){event.preventDefault();', click, '}" d="', g$path,
        '" fill="', fill, '" fill-rule="evenodd" stroke="', if (active) '#17384b' else '#ffffff', '" stroke-width="', if (active) 4 else 1.5, '"><title>', escape(tooltip), '</title></path>')
    }, character(1))
    labels <- vapply(seq_len(nrow(local_geometry)), function(i) {
      g <- local_geometry[i, ]; z <- d[match(g$id, d$id), ]
      paste0('<text pointer-events="none" x="', g$label_x, '" y="', g$label_y, '" text-anchor="middle" class="map-label">', escape(z$district),
        '</text><text pointer-events="none" x="', g$label_x, '" y="', g$label_y+22, '" text-anchor="middle" class="map-value">',
        if (input$metric == 'share') pct(z$exposed_share_pct) else people(z$exposed_population), '</text>')
    }, character(1))
    HTML(paste0('<svg class="district-map" viewBox="0 0 900 470" role="group" aria-label="Real district boundaries around Sunamganj">', paste(paths, collapse = ''), paste(labels, collapse = ''), '</svg>'))
  })
  output$locator <- renderUI({
    paths <- vapply(seq_len(nrow(country_geometry)), function(i) {
      g <- country_geometry[i, ]; fill <- if (g$id == input$district) '#dc8c43' else if (g$id %in% pilot$id) '#729ead' else '#edf1f3'
      paste0('<path d="', g$path, '" fill="', fill, '" fill-rule="evenodd" stroke="#aebdc5" stroke-width="0.35"/>')
    }, character(1))
    HTML(paste0('<svg viewBox="0 0 240 290" role="img" aria-label="Bangladesh locator: pilot districts in blue, selected district in orange">', paste(paths, collapse = ''), '</svg>'))
  })
  output$detail <- renderUI({
    d <- selected(); item <- function(label, value, cls = '') div(class = paste('assessment-item', cls), h3(label), p(value))
    div(class = 'card', div(class = 'detail-heading', h2(paste0(d$district, ' | ', d$division, ', Bangladesh')),
      span(class = paste('badge', if (d$above_cutoff) 'flag' else 'below'), d$screening)), div(class = 'assessment-grid',
      item('Modelled population (2020)', people(d$population_2020)),
      item('Population exposed to modelled flooding', paste0(people(d$exposed_population), ' people; ', pct(d$exposed_share_pct), ' of district population')),
      item('Exposure screening', paste0(metric_label(input$metric), ': percentile ', sprintf('%.1f', d$percentile), '; rank ', d$rank_high_to_low, ' of ', d$comparison_n, ' (highest first). Cutoff: ', input$cutoff, '. ', comparison_label(input$comparison), '.'), 'wide'),
      item('Future climate changes', 'Not assessed. No projected change or 2050 value is supplied.'),
      item('Service disruption and economic consequences', 'Not assessed. People exposed are not the same as people losing market access, affected people or economic losses.'),
      item('Infrastructure needs', 'Not diagnosed. Validate facilities, routes and service bottlenecks before identifying project needs.'),
      item('AIIB investment coverage and investment gaps', 'Not assessed. Project sites, service areas, status and relevant coverage have not been validated. No gap flag is assigned.'),
      item('Potential responses and costs', 'Not appraised. Exposure screening can guide further investigation; no district-specific response package or cost estimate is claimed.', 'wide')))
  })
  output$table_note <- renderUI(p(class = 'hint', paste0('Indicator: ', metric_label(input$metric), '. Comparison: ', comparison_label(input$comparison), '. Settings change ranks, not exposure estimates.')))
  output$overview <- renderTable({
    d <- data(); d <- d[d$pilot_area == 1, ]; d <- d[order(-d$metric_value), ]
    data.frame(District = d$district, `Exposed people (approx.)` = vapply(d$exposed_population, people, character(1)), `Exposed share` = vapply(d$exposed_share_pct, pct, character(1)),
      Percentile = sprintf('%.1f', d$percentile), `Exposure screen` = ifelse(d$above_cutoff, 'At / above cutoff', 'Below cutoff'), check.names = FALSE)
  }, striped = TRUE, bordered = FALSE, spacing = 'm', rownames = FALSE)
  output$coverage <- renderTable({
    data.frame(Component = c('Water scarcity and drought', 'Extreme heat', 'River and surface flooding', 'Coastal flooding and sea level', 'Soil and land degradation', 'Cyclones and severe winds'),
      `Pilot evidence` = c('Not assessed', 'Not assessed', 'General flood-exposure indicator available; flood types not separated by the source table', 'Not separately assessed; no coastal or sea-level projection', 'Not assessed', 'Not assessed'), check.names = FALSE)
  }, striped = TRUE, spacing = 'm', rownames = FALSE)
  output$csv <- downloadHandler(filename = function() paste0('Bangladesh-flood-exposure-assessment-', Sys.Date(), '.csv'),
    content = function(file) write.csv(assessment_export(data(), input$cutoff, input$metric, input$comparison, input$district, stamp()), file, row.names = FALSE, fileEncoding = 'UTF-8'))
  output$report <- downloadHandler(filename = function() paste0(selected()$district, '-flood-exposure-assessment-', Sys.Date(), '.html'), contentType = 'text/html',
    content = function(file) {
      d <- selected()
      doc <- tags$html(lang = 'en', tags$head(tags$meta(charset = 'UTF-8'), tags$title(paste(d$district, 'flood-exposure assessment')),
        tags$style('body{font:16px/1.6 Arial,sans-serif;max-width:900px;margin:40px auto;color:#17384b;padding:20px}h1{line-height:1.2}')),
        tags$body(h1(paste(d$district, 'Flood Exposure Screening Assessment')), p(d$division, ', Bangladesh'),
          p(strong('Real public modelled data — exposure screening, not a completed hotspot or investment-gap assessment.')),
          p('Generated: ', stamp()), p('2020 population; modelled depth >15 cm; 1-in-100 return-period hazard. Source table released June 2025. Hazard reference year not specified in the ADM2 download. No future climate scenario included.'),
          h2('Population and flood exposure'), p('Modelled district population: ', people(d$population_2020)), p('Exposed population: ', people(d$exposed_population), '; share: ', pct(d$exposed_share_pct)),
          h2('Screening settings and result'), p('Indicator: ', metric_label(input$metric)), p('Comparison: ', comparison_label(input$comparison)),
          p('Percentile: ', sprintf('%.1f', d$percentile), '; rank ', d$rank_high_to_low, ' of ', d$comparison_n, '; cutoff ', input$cutoff, ' (inclusive).'), p('Result: ', d$screening),
          p('Percentile = 100 × (ascending max rank − 1) / (N − 1). Ties receive the same highest rank. The cutoff is arbitrary and adjustable. Changing comparison or indicator changes ranks, not estimates.'),
          h2('Further assessment required'), p('Future climate changes, service/network disruption, losses, infrastructure needs, AIIB coverage, other providers, investment gaps, responses and costs have not been assessed. No fictional values or project counts are used.'),
          h2('Sources and limitations'), source_links(),
          p('Share = 100 × pop_flood / pop from the same table. Space2Stats H3 level 6 cells are approximately 36 km²; boundary effects and model uncertainty limit district precision. Counts shown here are rounded to the nearest 1,000; the CSV retains source precision.'),
          p('Codes match all 64 districts. The map uses the World Bank boundary service retrieved in October 2026; exact equivalence to the exposure layer’s boundary vintage is not established. Exposure is not evidence of losses or inadequate investment. Prepared 29 October 2026.')))
      # Shiny treats tags$head as page metadata; explicitly include it in a standalone download.
      report_html <- as.character(doc)
      report_head <- paste0('<head><meta charset="UTF-8"><title>', escape(d$district),
        ' Flood Exposure Screening Assessment</title><style>body{font:16px/1.6 Arial,sans-serif;max-width:900px;margin:40px auto;color:#17384b;padding:20px}h1{line-height:1.2}h2{break-after:avoid}p{orphans:3;widows:3}</style></head>')
      report_html <- sub('<html lang="en">', paste0('<html lang="en">', report_head), report_html, fixed = TRUE)
      writeLines(paste0('<!DOCTYPE html>\n', report_html), file, useBytes = TRUE)
    })
}
shinyApp(ui, server)

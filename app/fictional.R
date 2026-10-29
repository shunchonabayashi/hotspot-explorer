# Isolated illustration: its data and server do not enter the real-data model.
fictional <- local({
source('fictional_model.R', local = TRUE, encoding = 'UTF-8')

# Shinylive/Chromium download compatibility, following Posit's component example:
# https://shiny.posit.co/r/components/inputs/download-button/
browser_download <- function(...) {
  button <- shiny::downloadButton(...)
  button$attribs$download <- NULL
  button
}

ui <- fluidPage(
  tags$head(tags$meta(name = 'robots', content = 'noindex, nofollow, noarchive'), tags$meta(name = 'viewport', content = 'width=device-width, initial-scale=1'),
            tags$link(rel = 'stylesheet', href = 'style.css')),
  div(class = 'masthead', div(class = 'eyebrow', 'TEAM DISCUSSION PROTOTYPE'),
      h1('Food–Energy–Infrastructure Hotspot Explorer'),
      p('Identify hotspots. Diagnose needs. Assess investment coverage. Explore responses.')),
  div(class = 'demo-banner', strong('Fictional demonstration'),
      ' — District A, Country X. All numbers, projects, costs and map boundaries are invented.'),
  div(class = 'workspace',
    tags$aside(class = 'controls card', h2('Customize assessment'),
      div(class = 'field-label', 'Area of interest'), selectInput('fictional-country', 'Country', c('Country X (fictional)' = 'X')), p('District A / Country X'),
      selectInput('fictional-pressure', 'Pressure component', choices = setNames(district_data()$id, district_data()$pressure), selected = 'river'),
      sliderInput('fictional-cutoff', 'Hotspot cutoff (percentile)', min = 0, max = 100, value = 90, step = 1),
      p(class = 'hint', 'Illustrative, adjustable rule: a consequence percentile at or above the cutoff is flagged.'),
      div(class = 'field-label', 'Scenario and horizon'), p('Hypothetical scenario / 2050'),
      div(class = 'field-label', 'Comparison area'), p('100 districts within Country X'),
      p(class = 'hint', 'This prototype uses the six supplied District A percentiles. Other comparison areas and scenarios are not yet available.'),
      actionButton('fictional-reset', 'Reset settings', class = 'btn-outline'),
      hr(), h3('Download assessment'),
      browser_download('fictional-csv', 'Data (CSV)'), browser_download('fictional-report', 'Report (HTML)'),
      p(class = 'hint', 'Open the HTML report in a browser and print or save it as PDF.')
    ),
    tags$main(class = 'results',
      div(class = 'card', h2('District A and neighbouring districts'),
          p(class = 'hint', 'Illustrative map — not real geography. Only District A has assessment data.'),
          uiOutput('fictional-map'),
          div(class = 'legend', span(class = 'key high', ''), 'At or above cutoff',
              span(class = 'key low', ''), 'Below cutoff', span(class = 'key unknown', ''), 'No data')),
      uiOutput('fictional-detail'),
      div(class = 'card', h2('Assessment across six pressures'),
          p(class = 'hint', 'Select a pressure above to see its full assessment. Each percentile refers to its own consequence indicator.'),
          div(class = 'table-scroll', tableOutput('fictional-overview'))),
      div(class = 'card methods', h2('How to interpret the results'),
          p('Hotspot status depends on service consequences, independently of investment coverage. A project can exist while a residual infrastructure need remains.'),
          p('The cutoff is an arbitrary screening choice, not a validated risk standard. Test sensitivity and validate locally. Absence of an AIIB project does not establish absence of other investment.'),
          p('Percentiles are supplied illustration values, not recalculated from a 100-district dataset. Different consequence indicators are not comparable economic losses. Do not sum overlapping effects or illustrative costs.'),
          p('Source: the fictional District A assessment in Comments on the hotspot analysis. Baseline and future values are fixed; changing the cutoff changes screening only. The map does not represent flood extent or actual project locations.'))
    )
  ),
  div(class = 'footer', 'R Shiny / Shinylive prototype • Prepared 29 October 2026 • No live hazard or project data')
)

server <- function(input, output, session) {
  data <- reactive(assess(district_data(), input$cutoff))
  selected <- reactive(data()[match(input$pressure, data()$id), , drop = FALSE])
  observeEvent(input$reset, { updateSelectInput(session, 'pressure', selected = 'river'); updateSliderInput(session, 'cutoff', value = 90) })
  output$map <- renderUI({
    d <- selected(); fill <- if (d$hotspot) '#dc8c43' else '#b8d9d4'
    HTML(paste0('<svg class="district-map" viewBox="0 0 700 310" role="img" aria-label="Schematic District A and six neighbouring districts. Neighbours have no data.">',
      '<g fill="#eef1f2" stroke="#a3b4bd" stroke-width="2"><polygon points="35,30 210,15 250,95 190,160 30,135"/>',
      '<polygon points="210,15 390,18 395,105 250,95"/><polygon points="390,18 665,45 660,160 505,180 395,105"/>',
      '<polygon points="30,135 190,160 250,240 210,295 30,270"/><polygon points="250,240 395,225 395,295 210,295"/>',
      '<polygon points="395,105 505,180 660,160 660,275 395,295 395,225"/></g>',
      '<polygon points="250,95 395,120 395,225 250,240 190,160" fill="', fill, '" stroke="#17384b" stroke-width="4"/>',
      '<g fill="none" stroke="#65899a" stroke-width="3" stroke-dasharray="8 5"><path d="M55 110 L190 125 L290 195 L450 215 L620 255"/><path d="M290 195 L350 110 L470 65"/></g>',
      '<g fill="#17384b" font-family="Arial,sans-serif" font-size="17" text-anchor="middle"><text x="115" y="80">District B</text><text x="300" y="58">District C</text>',
      '<text x="535" y="100">District D</text><text x="115" y="220">District E</text><text x="535" y="240">District F</text><text x="300" y="278">District G</text>',
      '<text x="300" y="160" font-weight="bold">District A</text><text x="300" y="184" font-size="14">', d$percentile, 'th percentile</text></g>',
      '<text x="35" y="308" fill="#516678" font-family="Arial,sans-serif" font-size="12">Dashed lines: schematic routes only</text></svg>'))
  })
  output$detail <- renderUI({
    d <- selected()
    item <- function(label, value, cls = '') div(class = paste('assessment-item', cls), h3(label), p(value))
    div(class = 'card', div(class = 'detail-heading', h2(d$pressure),
      span(class = paste('badge', if (d$hotspot) 'flag' else 'below'), if (d$hotspot) 'Hotspot identified' else 'Below hotspot cutoff')),
      div(class = 'assessment-grid',
        item('Baseline', d$baseline), item('2050 conditions / change', d$future),
        item('2050 consequences before proposed responses', d$consequence, 'wide'),
        item('Consequence percentile', paste0(d$percentile, 'th — ', d$indicator)),
        item('Hotspot screening', paste0(d$hotspot_status, ': ', d$percentile, 'th percentile; cutoff ', input$cutoff)),
        item('Infrastructure needs', d$need), item('Fictional AIIB investment coverage', d$coverage),
        item('Potential investment-gap assessment', paste(d$investment_gap, d$gap_evidence, sep = '. '), 'wide'),
        item('Potential response and illustrative cost', paste0(d$response, ': US$', d$cost_usd_m, ' million. Not an appraisal or funding proposal.'), 'wide')))
  })
  output$overview <- renderTable({
    d <- data(); data.frame(Pressure = d$pressure, Percentile = d$percentile,
      Hotspot = d$hotspot_status, `Investment-gap assessment` = d$investment_gap, check.names = FALSE)
  }, striped = TRUE, bordered = FALSE, spacing = 'm', rownames = FALSE, digits = 0)
  stamp <- function() format(Sys.time(), '%Y-%m-%d %H:%M UTC', tz = 'UTC')
  output$csv <- downloadHandler(filename = function() paste0('District-A-assessment-', Sys.Date(), '.csv'),
    content = function(file) write.csv(assessment_export(data(), input$cutoff, stamp()), file, row.names = FALSE, fileEncoding = 'UTF-8'))
  output$report <- downloadHandler(filename = function() paste0('District-A-assessment-', Sys.Date(), '.html'),
    content = function(file) {
      d <- data(); rows <- lapply(seq_len(nrow(d)), function(i) {
        z <- d[i, ]; tags$section(h2(z$pressure), p(strong('Baseline: '), z$baseline),
          p(strong('2050 conditions: '), z$future), p(strong('Consequences: '), z$consequence),
          p(strong('Screening: '), paste0(z$percentile, 'th percentile (', z$indicator, '); hotspot: ', z$hotspot_status)),
          p(strong('Infrastructure needs: '), z$need), p(strong('Fictional AIIB coverage: '), z$coverage),
          p(strong('Potential investment gap: '), z$investment_gap, '. ', z$gap_evidence),
          p(strong('Response and illustrative cost: '), z$response, ': US$', z$cost_usd_m, ' million.'))
      })
      doc <- tags$html(lang = 'en', tags$head(tags$meta(charset = 'UTF-8'), tags$title('District A assessment'),
        tags$style('body{font:16px/1.6 Arial,sans-serif;max-width:900px;margin:40px auto;color:#17384b;padding:20px}section{break-inside:avoid;border-top:1px solid #ccc;margin-top:25px}h1{line-height:1.2}')),
        tags$body(h1('District A Hotspot and Investment Assessment'),
          p(strong('FICTIONAL DEMONSTRATION — all data, projects and costs are invented.')),
          p('Generated: ', stamp()), p('Hypothetical 2050 scenario | Country X | 100-district comparison | Cutoff: ', input$cutoff, 'th percentile (inclusive).'),
          p('Uses supplied District A percentiles, not a recalculated national distribution. Screening is independent of investment coverage. Potential gaps require validation, including other providers. Separate consequence indicators are not comparable economic losses; do not sum effects or costs.'),
          rows, p('Source: fictional District A illustration in Comments on the hotspot analysis. Prepared 29 October 2026.')))
      report_html <- sub('<html lang="en">', '<html lang="en"><head><meta charset="UTF-8"><title>District A fictional framework illustration</title><style>body{font:16px/1.6 Arial,sans-serif;max-width:900px;margin:40px auto;color:#17384b;padding:20px}</style></head>', as.character(doc), fixed = TRUE)
      writeLines(paste0('<!DOCTYPE html>\n', report_html), file, useBytes = TRUE)
    }, contentType = 'text/html')
}

list(ui = ui, server = server)


})

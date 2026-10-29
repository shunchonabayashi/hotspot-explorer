# Fictional values transcribed from the team's District A illustration.
district_data <- function() {
  data.frame(
    id = c('water', 'heat', 'river', 'coast', 'soil', 'wind'),
    pressure = c('Water scarcity and drought', 'Extreme heat', 'River and surface flooding',
                 'Coastal flooding and sea level', 'Soil and land degradation', 'Cyclones and severe winds'),
    baseline = c('Water use/supply: 70%; 1 severe drought/decade.', '35 days/year above 35 C.',
                 '18% of cropland in 100-year flood extent.', '8% of land in 100-year coastal flood extent.',
                 'Cropland: 22% degraded; 7% salt-affected.', '2 damaging storms/decade.'),
    future = c('Dry-season water -20%; 2 severe droughts/decade.', '65 days/year above 35 C.',
               'Exposed cropland: 27%, same return period.', 'Sea level +0.25 m; exposed land: 13%.',
               'Cropland: 30% degraded; 11% salt-affected.', 'Design-storm peak wind speed +10%.'),
    consequence = c('25,000 ha: unreliable irrigation; drought-year crop output -18%.',
                    'Heat-year crop output -12%; peak power demand +20%.',
                    '40,000 people lose market access; detour +45 min in selected flood.',
                    '12 stores flooded; port access lost for 5 days in selected flood.',
                    'Output on degraded land 15% below undegraded reference.',
                    '30,000 people lose power for 4 days in selected storm.'),
    percentile = c(96, 93, 98, 85, 92, 88),
    indicator = c('Crop loss', 'Crop loss', 'People losing market access',
                  'Storage facilities inundated', 'Crop loss', 'People losing power'),
    need = c('Reliable irrigation and water availability.', 'Heat-resilient power and cooling.',
             'Resilient crossings and alternative market-access routes.', 'Protection of stores and port access.',
             'Restored land productivity and drainage.', 'Resilient power supply and backup.'),
    coverage = c('0 relevant projects.', '1 active $30m grid project; heat coverage unverified.',
                 '1 completed $50m road project; 2 crossings still vulnerable.',
                 '1 active $45m port project; 12 stores excluded.', '0 relevant projects.',
                 '1 completed $20m power project; hardening unverified.'),
    gap_evidence = c('No relevant coverage identified.', 'Check project alignment.',
                     'Residual crossing gap.', 'Stores excluded from project coverage.',
                     'No relevant coverage identified.', 'Check power-project hardening.'),
    coverage_state = c('gap', 'review', 'gap', 'gap', 'gap', 'review'),
    response = c('Irrigation + reuse', 'Grid + efficient cooling', 'Crossings + alternative routes',
                 'Raised stores + drainage', 'Drainage + restoration', 'Wind-resistant lines + backup'),
    cost_usd_m = c(40, 25, 60, 35, 15, 20),
    stringsAsFactors = FALSE
  )
}

assess <- function(data, cutoff) {
  stopifnot(length(cutoff) == 1L, is.finite(cutoff), cutoff >= 0, cutoff <= 100)
  data$hotspot <- data$percentile >= cutoff
  data$hotspot_status <- ifelse(data$hotspot, 'YES', 'NO')
  data$investment_gap <- ifelse(!data$hotspot, 'Below cutoff; assess locally',
                               ifelse(data$coverage_state == 'gap', 'Potential gap flagged', 'Review coverage'))
  data
}

assessment_export <- function(data, cutoff, generated) {
  out <- data[, c('pressure', 'baseline', 'future', 'consequence', 'indicator', 'percentile',
                 'hotspot_status', 'need', 'coverage', 'investment_gap', 'gap_evidence', 'response', 'cost_usd_m')]
  out$district <- 'District A'; out$country <- 'Country X (fictional)'
  out$scenario <- 'One hypothetical 2050 scenario'
  out$comparison <- '100 fictional districts within Country X; supplied percentiles'
  out$cutoff_percentile <- cutoff; out$generated_utc <- generated
  out$data_status <- 'FICTIONAL: all values, projects, boundaries and costs are invented'
  out
}

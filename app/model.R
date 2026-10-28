# Public World Bank Space2Stats data; see data/provenance.json.
district_data <- function(path = 'data/districts.csv') {
  read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
}

metric_column <- function(metric) {
  stopifnot(metric %in% c('share', 'count'))
  if (metric == 'share') 'exposed_share_pct' else 'exposed_population'
}
metric_label <- function(metric) {
  if (metric == 'share') 'Share of population exposed (%)' else 'People exposed (modelled count)'
}
comparison_label <- function(comparison) {
  if (comparison == 'country') 'All 64 Bangladesh districts' else 'Five-district Sunamganj pilot area'
}

assess <- function(data, cutoff = 90, metric = 'share', comparison = 'country') {
  stopifnot(length(cutoff) == 1L, is.finite(cutoff), cutoff >= 0, cutoff <= 100,
            comparison %in% c('country', 'pilot'))
  column <- metric_column(metric)
  pool <- if (comparison == 'country') rep(TRUE, nrow(data)) else data$pilot_area == 1
  x <- data[[column]][pool]
  stopifnot(length(x) > 1, all(is.finite(x)))
  data$percentile <- NA_real_
  # Inclusive max-rank percentile. Tied values receive the same highest rank.
  data$percentile[pool] <- 100 * (rank(x, ties.method = 'max') - 1) / (length(x) - 1)
  data$rank_high_to_low <- NA_integer_
  data$rank_high_to_low[pool] <- as.integer(rank(-x, ties.method = 'min'))
  data$comparison_n <- sum(pool)
  data$above_cutoff <- !is.na(data$percentile) & data$percentile >= cutoff
  data$screening <- ifelse(is.na(data$percentile), 'Outside comparison set',
                          ifelse(data$above_cutoff, 'At or above exposure cutoff', 'Below exposure cutoff'))
  data$metric_value <- data[[column]]
  data
}

assessment_export <- function(data, cutoff, metric, comparison, district, generated) {
  data$selected_district <- data$id == district
  data$country <- 'Bangladesh'
  data$screening_indicator <- metric_label(metric)
  data$comparison_area <- comparison_label(comparison)
  data$cutoff_percentile <- cutoff
  data$population_reference_year <- 2020
  data$hazard_definition <- 'Modelled flood depth >15 cm; 1-in-100 return period; Fathom v3 / WorldPop'
  data$future_climate_changes <- 'Not assessed'
  data$service_disruption <- 'Not assessed'
  data$infrastructure_needs <- 'Not diagnosed'
  data$aiib_investment_coverage <- 'Not assessed'
  data$investment_gap <- 'Not assessed'
  data$response_cost <- 'Not assessed'
  data$source <- 'World Bank Space2Stats, ADM2 flood exposure, release June 2025; World Bank Official Boundaries'
  data$source_url <- 'https://datacatalog.worldbank.org/search/dataset/0066820/space2stats-database'
  data$boundary_url <- 'https://datacatalog.worldbank.org/search/dataset/0038272/world-bank-official-boundaries'
  data$license <- 'CC BY 4.0; share and rank calculations adapted by this pilot'
  data$generated_utc <- generated
  data
}

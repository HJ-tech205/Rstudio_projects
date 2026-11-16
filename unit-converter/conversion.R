# Libs
library(tidyverse)
library(dplyr)
library(readr)

# Data
df <- read.csv("data/demo_data.csv")

df <- df |>
  mutate(
    quantity_pcs = units_sold,
    quantity_m = units_sold * length,
    price_eur_per_pcs = dollar / quantity_pcs,
    price_eur_per_m = dollar / quantity_m
  )

price_data <- bind_rows(
  df |>
    transmute(
      unit = "M",
      quantity = quantity_m,
      net_amount_eur = dollar,
      unit_price_eur = price_eur_per_m
    ),
  df |>
    transmute(
      unit = "PCS.",
      quantity = quantity_pcs,
      net_amount_eur = dollar,
      unit_price_eur = price_eur_per_pcs
    )
)

# Helpers
weighted_variance <- function(x, weight) {
  avg <- weighted.mean(x, weight)
  sum(weight * (x - avg)^2) / sum(weight)
}

weighted_quantile <- function(x, weight, probability) {
  order_id <- order(x)
  share <- cumsum(weight[order_id]) / sum(weight[order_id])
  x[order_id][which(share >= probability)[1]]
}

commercial_round <- function(x) {
  sign(x) * floor(abs(x) + 0.5)
}

# Prices
conversion_basis <- price_data |>
  group_by(unit) |>
  summarise(
    observation_count = n(),
    total_net_amount_eur = sum(net_amount_eur),
    total_quantity = sum(quantity),
    weighted_unit_price_eur = total_net_amount_eur / total_quantity,
    unweighted_price_variance = var(unit_price_eur),
    weighted_price_variance = weighted_variance(unit_price_eur, quantity),
    weighted_price_sd = sqrt(weighted_price_variance),
    weighted_price_cv = weighted_price_sd / weighted_unit_price_eur,
    weighted_price_q10 = weighted_quantile(unit_price_eur, quantity, 0.10),
    weighted_price_q90 = weighted_quantile(unit_price_eur, quantity, 0.90),
    pearson_revenue_quantity = cor(net_amount_eur, quantity),
    spearman_revenue_quantity = cor(net_amount_eur, quantity, method = "spearman"),
    .groups = "drop"
  ) |>
  mutate(
    diagnostic_quality = case_when(
      weighted_price_cv <= 0.15 ~ "within KFA customer reference",
      weighted_price_cv <= 0.25 ~ "within KFA article reference",
      TRUE ~ "review price variation"
    )
  )

# Conversion
convert_eur_to_quantity <- function(amount_eur, unit) {
  selected <- conversion_basis |>
    filter(.data$unit == .env$unit)

  raw_quantity <- amount_eur / selected$weighted_unit_price_eur
  lower_quantity <- amount_eur / selected$weighted_price_q90
  upper_quantity <- amount_eur / selected$weighted_price_q10

  tibble(
    amount_eur = amount_eur,
    unit = unit,
    weighted_unit_price_eur = selected$weighted_unit_price_eur,
    raw_quantity = raw_quantity,
    plan_quantity = ifelse(unit == "PCS.", commercial_round(raw_quantity), round(raw_quantity, 6)),
    quantity_q10_q90_lower = ifelse(unit == "PCS.", commercial_round(lower_quantity), round(lower_quantity, 6)),
    quantity_q10_q90_upper = ifelse(unit == "PCS.", commercial_round(upper_quantity), round(upper_quantity, 6)),
    diagnostic_quality = selected$diagnostic_quality
  )
}

example_conversion <- bind_rows(
  convert_eur_to_quantity(120, "M"),
  convert_eur_to_quantity(120, "PCS.")
)

# Variance
variables <- c(
  "dollar",
  "units_sold",
  "length",
  "quantity_m",
  "price_eur_per_pcs",
  "price_eur_per_m"
)

variance_summary <- bind_rows(lapply(variables, function(name) {
  x <- df[[name]]

  tibble(
    variable = name,
    mean = mean(x),
    variance = var(x),
    standard_deviation = sd(x),
    coefficient_of_variation = sd(x) / mean(x)
  )
}))

# Correlations
pairs <- combn(variables, 2, simplify = FALSE)

correlations <- bind_rows(lapply(pairs, function(pair) {
  x <- df[[pair[1]]]
  y <- df[[pair[2]]]

  tibble(
    variable_x = pair[1],
    variable_y = pair[2],
    pearson_r = cor(x, y),
    spearman_rho = cor(x, y, method = "spearman")
  )
})) |>
  arrange(desc(abs(pearson_r)))

# Plots
dir.create("plots", showWarnings = FALSE)

price_plot <- ggplot(price_data, aes(x = unit, y = unit_price_eur)) +
  geom_boxplot(width = 0.45, fill = "#d9e4f2", colour = "#263238") +
  theme_minimal(base_size = 12) +
  labs(x = NULL, y = "Unit price (EUR)") +
  theme(panel.grid.minor = element_blank())

correlation_plot <- ggplot(price_data, aes(x = quantity, y = net_amount_eur)) +
  geom_point(colour = "#315b7d", alpha = 0.75, size = 2) +
  geom_smooth(method = "lm", formula = y ~ x, se = FALSE, colour = "#263238", linewidth = 0.7) +
  facet_wrap(vars(unit), scales = "free_x") +
  theme_minimal(base_size = 12) +
  labs(x = "Quantity", y = "Net amount (EUR)") +
  theme(panel.grid.minor = element_blank())

ggsave("plots/price_variation.png", price_plot, width = 7, height = 4.5, dpi = 150)
ggsave("plots/amount_quantity_correlation.png", correlation_plot, width = 8, height = 4.5, dpi = 150)

print(conversion_basis)
print(example_conversion)

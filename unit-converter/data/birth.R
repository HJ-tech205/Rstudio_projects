# Libs
library(tidyverse)
library(dplyr)
library(readr)

# Seed
set.seed(123)

# Data
df <- data.frame(
  customer_id = paste0("id_", 1:30),
  units_sold = sample(1:100, 30, replace = TRUE),
  length = round(runif(30, min = 0.5, max = 5), 2)
)

df$dollar <- round( #Adding currency in a fitting relation to units and length
  df$units_sold * df$length * runif(30, min = 8, max = 15),
  2
)

# Save 
write.csv(df, "demo_data.csv", row.names = FALSE)


# ==============================================================================
# DATA SCIENCE PORTFOLIO: AVIATOR CRASH GAME PROBABILITY SIMULATION
# ==============================================================================
library(tidyverse)
library(gridExtra) 

set.seed(777) # For reproducible random generation
n_rounds <- 15

# 1. Simulate the crash multipliers based on true RTP math
u <- runif(n_rounds)
crash_multipliers <- ifelse(u <= 0.03, 1.00, 0.97 / u)

simulation_data <- data.frame(
  round_id = 1:n_rounds,
  crash_point = crash_multipliers
)

# 2. Evaluate a cash-out strategy (Target: 1.50x)
TARGET_MULTIPLIER <- 1.50
BET_AMOUNT <- 100 # R100 per round, play around with values

simulation_data <- simulation_data %>%
  mutate(
    is_win = crash_point >= TARGET_MULTIPLIER,
    # Calculate gross amounts won or lost per round
    gross_won  = ifelse(is_win, (BET_AMOUNT * TARGET_MULTIPLIER) - BET_AMOUNT, 0),
    gross_lost = ifelse(is_win, 0, BET_AMOUNT),
    profit_loss = ifelse(is_win, gross_won, -gross_lost),
    cumulative_balance = cumsum(profit_loss)
  )

# 3. Measure key performance metrics (Statistics)
actual_win_rate   <- mean(simulation_data$is_win) * 100
expected_win_rate <- (0.97 / TARGET_MULTIPLIER) * 100

total_gross_winnings <- sum(simulation_data$gross_won)
total_gross_losses   <- sum(simulation_data$gross_lost)
total_final_profit   <- last(simulation_data$cumulative_balance)

# 4. Plot the bankroll over time (The visual proof)
performance_plot <- ggplot(simulation_data, aes(x = round_id, y = cumulative_balance)) +
  geom_line(color = "#e74c3c", size = 1) +
  theme_minimal(base_size = 13) +
  labs(
    title = "Aviator Simulation: Bankroll Performance Over Time",
    subtitle = paste("Strategy: Strictly cashing out at", TARGET_MULTIPLIER, "x"),
    x = "Number of Rounds Played",
    y = "Cumulative Profit / Loss (ZAR)"
  )

ggsave("plots/aviator_strategy_trend.png", plot = performance_plot, width = 12, height = 7)

# 5. Restructure data tables with gross winnings and risk warnings
telemetry_table <- data.frame(
  Parameter = c(
    "Target Cash-Out Multiplier", 
    "Base Bet Amount", 
    "Mathematical Expected Win Rate", 
    "Actual Simulated Win Rate", 
    "Total Gross Amount Won",
    "Total Gross Amount Lost",
    "Final Net Bankroll Balance",
    "==========================",
    "RISK ASSESSMENT WARNING"      
  ),
  Value = c(
    paste0(TARGET_MULTIPLIER, "x"),
    paste0("R ", BET_AMOUNT, " ZAR"),
    paste0(round(expected_win_rate, 2), "%"),
    paste0(round(actual_win_rate, 2), "%"),
    paste0("R ", total_gross_winnings, " ZAR"),
    paste0("R ", total_gross_losses, " ZAR"),
    paste0("R ", total_final_profit, " ZAR"),
    "==========================",
    "STOP BEFORE ITS TOO LATE BROER" 
  )
)

# Clean table representation on the Console
cat("\n")
print("=== AVIATOR BEHAVIORAL RISK REPORT ===")
print(telemetry_table, row.names = FALSE)
cat("\n* NOTICE: High win rates (64%) create a psychological illusion of profit,\n  but long-term bankroll destruction is mathematically absolute.\n\n")

# Visualize results using picture
png("plots/aviator_telemetry_table.png", width = 900, height = 280, res = 100)
grid.table(telemetry_table, rows = NULL)
dev.off()
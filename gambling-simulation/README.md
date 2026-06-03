# Aviator Crash Game: Behavioral Risk & Probability Simulation

A data science and algorithmic simulation built in R that models financial risk trends and psychological traps in dynamic reward systems. By replicating the exact House Edge mechanics of modern crash gaming engines, this project provides empirical proof of negative expected value ($EV$) trajectories across extensive trial iterations.

---

## Core Methodology & Simulation Engine

The core simulation engine operates on standard textbook probability modeling and inverse transform sampling to accurately match real-world risk environments:

1. **Mathematical Curve Generation**: Incorporates a strict **3% House Edge** Return-to-Player (RTP) algorithm. Using uniform random numbers ($u \in [0, 1]$), the system warps a flat decimal distribution into a steep, exponential decay curve:
   $$\text{Crash Multiplier} = \begin{cases} 1.00 & \text{if } u \le 0.03 \\ \frac{0.97}{u} & \text{if } u > 0.03 \end{cases}$$
2. **Behavioral Execution Logic**: Simulates an automated player executing a fixed-stake strategy over a massive sample space ($10,000$ independent consecutive rounds).
   * **Base Stake ($B$)**: R100 ZAR per round.
   * **Target Execution Threshold ($T$)**: Fixed cash-out at $1.50\times$.

---

## Analytical Insights & Behavioral Findings

The script outputs dual analytical components (a direct R console telemetry matrix and a high-fidelity visual asset) to contrast short-term positive reinforcement against long-term capital attrition.

### 1. Simulated Telemetry Summary
* **Mathematical Expected Win Rate**: **64.67%** (The high threshold probability that creates the psychological illusion of consistency).
* **Actual Simulated Win Rate**: **~64.12%** (Aligns precisely with theoretical distributions).
* **Total Gross Capital Won**: Captures the absolute volume of positive returns generated during successful cash-outs.
* **Total Gross Capital Lost**: Exposes how complete stake forfeiture on early crashes systematically outpaces fractional profit margins.
* **Final Net Position**: Demonstrates a severe deficit, mathematically illustrating why localized high win rates fail to sustain a long-term positive yield.

### 2. File Assets Generated
* `plots/aviator_strategy_trend.png`: A comprehensive time-series line graph tracing the cumulative bankroll path straight into a structural deficit.
* `plots/aviator_telemetry_table.png`: A presentation-ready graphic table compiling complete execution statistics and risk classifications.

---

## Operational Setup & Dependencies

This pipeline leverages the data manipulation strengths of the `tidyverse` suite alongside the visualization compiling features of `gridExtra`.

### Package Requirements
Ensure dependencies are initialized within your R environment before script execution:
```R
install.packages("tidyverse")
install.packages("gridExtra")

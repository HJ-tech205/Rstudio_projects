# Unit Converter for Forecast Adjustments

This R project builds a simple EUR-to-quantity conversion basis for the Klaus Faber forecast workflow.

```text
EUR adjustment -> unit price -> metres or pieces
```

The script does not change a forecast. It checks how stable the observed unit prices are and how strongly revenue and quantity are related.

## Data

[`data/demo_data.csv`](data/demo_data.csv) contains 30 synthetic rows created by [`data/birth.R`](data/birth.R).

| Column | Meaning |
| --- | --- |
| `customer_id` | Synthetic customer ID |
| `units_sold` | Number of pieces sold |
| `length` | Metres per piece |
| `dollar` | Synthetic amount, treated as EUR in this demo |

The two quantity views are calculated as follows:

```text
pieces = units_sold
metres = units_sold * length
```

Metres and pieces are kept separate. In real KFA data, the unit has to come from the article master data.

## Calculation

The conversion price is quantity weighted:

```text
unit price = sum(amount) / sum(quantity)
quantity   = EUR adjustment / unit price
```

The script also calculates:

- weighted and unweighted price variance
- weighted standard deviation and coefficient of variation
- weighted 10th and 90th price percentiles
- Pearson and Spearman correlations

Pieces are rounded to whole units. Metres use six decimal places.

## Run

Install the packages once:

```r
install.packages("tidyverse")
```

Open `unit-converter` as the working directory and run:

```r
source("conversion.R")
```

The main results stay available in R as:

- `conversion_basis`
- `variance_summary`
- `correlations`
- `example_conversion`

The conversion function can be used directly:

```r
convert_eur_to_quantity(120, "M")
convert_eur_to_quantity(120, "PCS.")
```

## Plots

The script creates two minimal plots in the `plots` folder:

- `price_variation.png`
- `amount_quantity_correlation.png`

No CSV result files are written.

## Demo result

| Check | Metres | Pieces |
| --- | ---: | ---: |
| Weighted unit price | 11.0568 EUR/m | 30.7104 EUR/piece |
| Weighted price CV | 20.14% | 54.35% |
| Amount/quantity correlation | 0.9538 | 0.6076 |
| Quantity from 120 EUR | 10.853041 m | 4 pieces |

The metre relationship is stronger because `birth.R` creates the amount from pieces, length and a random price per metre.

## Limits

The demo data has no articles, product groups, months or forecast quarters. It is therefore suitable for testing the conversion logic, but not for building a production KFA price basis.

Real KFA data needs a fixed unit per article, positive quantities, net position values and enough historical observations. Missing values must be resolved before this calculation is used in the forecast process.

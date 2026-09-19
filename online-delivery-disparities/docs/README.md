# Inside the Delivery Zone

Price, Availability, and Information Disparities Across Neighborhood Food-Access Status in Online Grocery Retail.

## Structure

Extensive/intensive margin design:

- **Extensive margin** — coverage mapping across Amazon, Walmart, Target (which ZIPs are served at all). Currently being reframed as *product curation* — which products each ZIP sees on the first page of search results — scraped weekly across three retailers.
- **Intensive margin** (primary contribution) — whether served ZIPs face equivalent shopping environments, decomposed into three layers:
  1. Posted price and coupons/discounts (delivery fees/free-delivery thresholds found flat across ZIP within a retailer, so focus shifted here)
  2. Product availability (stockout/assortment)
  3. Product information (description/nutrition/ratings)
  - Considering narrowing this comparison to two products — one national brand, one private label.

## Design

- Pure event study with calendar date fixed effects (not staggered DID); SNAPFlow continuous treatment variable for multi-date issuance states.
- Final recommended state/ZIP design: 5 states, unequal allocation — PA (25 ZIPs), MI & OH (15 each), FL & MA (10 each). Florida is the placebo/benchmark state.
- Amazon Fresh county-level coverage was the binding constraint eliminating ND, SD, Utah.
- State/ZIP selection co-authored with Charlotte Ambrozek.

## Folders

- `data/` — raw + processed scrapes (gitignored)
- `code/` — scraping, curation-scraper, analysis
- `docs/` — this file, LaTeX draft

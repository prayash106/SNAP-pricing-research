# Menu Costs Without Menus

Algorithmic Pricing, SNAP Issuance, and Distributional Incidence in Grocery Retail.

Theory + case study on whether algorithmic online pricing removes the menu-cost friction that produced a null result in the offline literature (Goldin, Homonoff & Meckel 2022), and if the response still doesn't converge to the frictionless optimum, what remaining constraint explains the gap.

## Theory

Decision tree nesting three explanations, with four signed propositions (Kong et al. format):
1. Frictionless benchmark — price responds to elasticity shifts, not pure demand-level shocks
2. Menu-cost friction (Golosov-Lucas / Sheshinski-Weiss (S,s) inaction bands)
3. Reputational/fairness cost (Rotemberg-style) that can persist even once menu costs vanish online

## Empirical design

1. Descriptive: repricing frequency by retailer/ZIP/category
2. Foot-traffic event-study confirming the demand shock, then main event-study of log price around SNAP issuance, compared to a simulated rational-benchmark price response
3. Robustness: triple-interaction (IssuanceShare × Freq_r × Eligible_j)

## Data

Daily scraped prices (Amazon, Walmart, Target), 25-product basket (20 SNAP-eligible / 5 non-eligible, national-brand + private-label), 70 ZIPs across 7 states, 6-month window (July–Dec 2026).

## Folders

- `data/` — raw + processed panels (gitignored)
- `code/` — scraping, QC, analysis
- `docs/` — this file, theory notes, LaTeX draft

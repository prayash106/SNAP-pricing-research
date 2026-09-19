# SNAP Pricing Panel

DiD/event-study on ZIP-level grocery pricing around SNAP benefit issuance dates, comparing high- vs. low-SNAP ZIPs.

## Status

- Framing: "does algorithmic/online pricing enable exploitation around predictable demand shocks" — a well-powered null treated as a valid, interesting result (TOST equivalence testing, pre-registration recommended).
- Power: Monte Carlo simulation using the actual staggered issuance calendar; power ranges from adequate to underpowered depending on (a) whether large Walmart price jumps are real repricing or scraper artifacts, and (b) within-state-day price correlation assumptions.

## Data

Daily price panel: Amazon Fresh, Walmart, Target (~44 matched product variants), 70 ZIPs across 7 states.

## Folders

- `data/` — raw + processed panels (gitignored)
- `code/` — scraping, QC, power simulation, event-study/DiD specs
- `docs/` — this file, LaTeX draft

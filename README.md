# SNAP Pricing Research

Two papers built on the same BrightData grocery-price scraping pipeline (scraper code is duplicated in each paper's `code/` folder for self-containment).

```
menu-costs-snap/              "Menu Costs Without Menus" — algorithmic pricing & SNAP issuance cycles
  data/                        Raw + processed price/foot-traffic data (gitignored)
  code/                        Scraping, QC, and analysis scripts
  docs/                        Theory notes, LaTeX draft, writeups

online-delivery-disparities/  "Inside the Delivery Zone" — price, availability & information
                               disparities across neighborhood food-access status
  data/
  code/
  docs/
```

## Shared data facts

- Daily price panel: Amazon Fresh, Walmart, Target (~44 matched product variants)
- 70 ZIPs across 7 states (FL, OH, MA, NC, WA, CA, NJ)
- Dewey/SafeGraph foot traffic as demand proxy
- NielsenIQ RMS scanner elasticities (supplementary)

See each paper's own `docs/README.md` for paper-specific details.

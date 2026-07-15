# presentation-figs — slide re-plots for the ICRS talk

*Created: 2026-07-14*

Clean, single-message, projector-legible re-plots of the modeling results, styled to match
the ICRS deck (ocean-teal + coral). **This folder is additive — it does not modify any of
Raine's code.** It only *reads* `rse_new_scenario_analyses.rmd` / `rse_funs.R` and reproduces
the needed model objects, then re-plots them in ggplot.

## Figures
| File | Slide | Message |
|------|-------|---------|
| `fig4_size.png` | Result 2 | Reef cover over 50 yr by outplant size class — **SC2 (intermediate) wins**, others muted |
| `fig2_decline.png` | Result 1 | Reef cover with vs without restoration — **no restoration stays collapsed** |
| `fig3_tradeoff.png` | Result 3 | Reef cover ↔ total ROI across allocation, at 5 yr (sharp tradeoff) vs 50 yr (**faded**) |

## How it works
- `theme_slide.R` — deck palette + large-font ggplot theme + `save_slide()`.
- `_extracted/` — verbatim setup/data chunks pulled from `rse_new_scenario_analyses.rmd` (so we
  reproduce Raine's exact model without editing her files). Regenerate with the awk extractor if
  her code changes.
- `figN_*.R` — each sources the theme + extracted setup, runs the model, and writes a PNG.

## Regenerate
```r
# from the repo root (needs ../Detmer-2025-coral-parameters alongside)
Rscript presentation-figs/fig4_size.R       # ~seconds (deterministic)
Rscript presentation-figs/fig2_decline.R    # ~1 min (100 param sets x 3 strategies)
Rscript presentation-figs/fig3_tradeoff.R   # ~20 s (100 sets x 11 props, no-disturbance)
```

## Notes
- Fig 3 shows the **no-disturbance** tradeoff only (the disturbance-insurance point is made in the
  slide text). To add the disturbance panel, un-skip `orch_D3_all` in `_extracted/fig3_data.R`.
- Fig 4 uses the code's current `area_out = 1250`; the manuscript figure used 2000. The *winner*
  (SC2) is identical — total area only rescales the y-axis (density dependence is off here).

## Methods-slide figures (data synthesis)
- `fig_survival_size.png` — re-plot of `survival_by_size.csv` (survival climbs SC1→SC5), deck palette.
- `carib_map.png` — cropped panel (a) of the synthesis paper's `Fig1_study_landscape.png` (Caribbean
  site map; corners cleaned). Pulled from `../Detmer-2025-coral-parameters/06_analysis/figures/manuscript/`.

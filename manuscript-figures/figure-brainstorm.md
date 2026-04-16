# RSE Manuscript — Figure Plan

**Target journals:** Nature Ecology & Evolution (submitted), Ecological Applications, Conservation Biology (fallbacks)
**Date:** 2026-04-08
**Species:** *Acropora palmata* (Elkhorn Coral)

---

## Analysis Priorities for Figure Support

The figure targets below will need the following model runs. Roughly in priority order:

1. **Expand prop_main gradient.** Current levels (0.8, 0.9, 1.0) are clustered at the reef-heavy end. For Fig 3 to show a meaningful allocation trade-off, run 0.0–1.0 in 0.1 steps (or finer). If compute time is prohibitive, at least add 0.0, 0.2, 0.4, 0.6.

2. **Run lab grow-out sensitivity sweep.** Fig 4 needs a 2D grid: lab survival (0–1) × lab growth probability (0–1), ~10 levels each. The binary comparison (immediate vs. 1-year) is a starting point but the heatmap surface is the real result.

3. **Run multi-size-class PVA.** Fig 5 needs `popvi_mod()` across all 5 size classes (not just SC1), at outplanting rates 0–100/yr and external recruitment 0–50/yr.

4. **Fix CI label inversion in ts_fun().** `reef_cover_low` = 95th percentile, `reef_cover_up` = 5th. Small fix, easy to forget, will cause plotting errors later.

5. **Clarify prop_main direction.** `prop_main = 1.0` means 100% to reef, 0% to orchard. Add a comment in the analysis code and use "proportion to reef" consistently in all figure labels — avoid "proportion routed through orchard" which inverts the intuition.

---

## Paper Narrative

Five figures, funnel structure:

1. **Here's the system** — model schematic
2. **Restoration accelerates recovery** — dynamics ± restoration under disturbance
3. **Where to allocate effort** — orchard vs. reef ROI
4. **When to outplant** — lab retention trade-off surface
5. **What size to outplant** — outplanting size class optimization

Each figure answers the follow-up question raised by the previous one. After establishing that restoration works (Fig 2), the remaining figures optimize how.

The missing piece: these figures each tune one knob. A synthesis — Pareto frontier or decision surface integrating cost, timing, and size — would answer "so what should a practitioner actually do?" This belongs in main text if the analysis supports it; otherwise cut it entirely. Don't park it in supplement as a hedge.

---

## Figure 1 — Model Schematic

**Depends on:** Illustration work (Illustrator/BioRender + R or D3). No model output needed.

**Goal:** Orient the reader to the RSE framework.

**Panel A — Physical system:**
Illustration showing the real-world pipeline: gamete collection from reference reef → lab larval rearing on settlement tiles → ocean-based orchard nursery (reef stars) → transplant to restoration reef. Include coral imagery. This is the "here's what happens in the field" panel.

**Panel B — Demographic flow diagram:**
Vector diagram showing:

- 3 compartments: Lab → Orchard → Reef
- 5 size classes within each (0–10, 10–100, 100–900, 900–4000, 4000+ cm²)
- Transition arrows: growth (rightward), shrinkage (leftward), survival (loop), fragmentation
- External inputs: wild recruitment (λ), collected settlers (λ_R)
- Core equation: N(t+1) = S·(T+F)·N(t) + R
- Decision points highlighted: proportion to orchard vs. reef (prop_main), lab retention time, outplanting size class — these are the knobs tuned in Figs 3–5

**Design notes:**

- Encode parameter ranges on the diagram (survival rates by size class, transition probabilities) to raise information density above a generic box-and-arrow
- Establish compartment colors (lab / orchard / reef) that carry through all subsequent figures
- Size class color ramp (sequential viridis, 5 stops) also carries to Fig 5
- Target: double-column width (170–180mm)

---

## Figure 2 — Restoration Accelerates Recovery

**Depends on:** `ts_fun()` output from `rse_new_scenario_analyses.rmd`. Data exists — ready to plot.

**Goal:** The "why restore?" figure. Show restoration accelerates reef recovery, especially under disturbance.

**Data:**

- Baseline: λ_R = 0 (no collection), λ = 0 (no external recruitment)
- Restoration: λ_R = 1,255,111 (reference reef larvae, lab-reared, 100% to reef)
- 51 years, 100 parameter replicates, 3 disturbance regimes (D0/D3/D5)
- Metric: reef cover (m²) from `model_summ(metric = "area_m2")`

**Layout — 3 panels (one per disturbance regime):**

| Panel | Disturbance | Content |
|-------|------------|---------|
| A | D0 (none) | Reef cover trajectories: baseline (gray) vs. restoration (accent), 90% CI ribbons |
| B | D5 (every 5 yr) | Same — disturbance dips visible, restoration enables faster recovery |
| C | D3 (every 3 yr) | Same — most stressful regime, largest restoration benefit |

**Design:**

- 90% CI bands from `ts_fun()` (5th–95th quantile). **Note:** labels inverted in code — `reef_cover_low` = 95th, `reef_cover_up` = 5th. Fix before plotting or swap at plot time.
- Two colors: gray (no restoration) vs. teal (#009E73, Okabe-Ito) for restoration
- Annotate the gap at year 50: "X m² additional cover"
- Mark disturbance events with vertical dashed lines or subtle background shading
- Shared y-axis; x-axis labels on bottom panel only
- Target: double-column width

---

## Figure 3 — Orchard vs. Reef Allocation

**Depends on:** Expanded prop_main gradient (see priority #1 above). Can draft with 3 existing levels, but final version needs the full sweep.

**Goal:** Show how dividing effort between orchard nurseries and direct reef outplanting affects cost-effectiveness.

**Data:**

- `prop_main` = proportion outplanted directly to reef. **Current levels: 0.8, 0.9, 1.0 only.**
- External recruitment toggled on/off
- 3 disturbance regimes, 100 parameter replicates
- 6 metrics from `metrics_dt_fun()`: reef cover, orchard function, reef ROI, total ROI, total costs, recruits outplanted

**If prop_main expanded to 0.0–1.0 (recommended):**

**Layout — 2 panels:**

- Panel A: Reef cover (m²) at year 50 vs. proportion to reef (continuous x-axis), one line per disturbance regime, 90% CI ribbons. Shows where the ecological optimum falls.
- Panel B: Reef ROI (m²/$) vs. proportion to reef, same structure. Shows cost-effectiveness optimum — likely peaks at intermediate allocation because orchard compounds recruit production over long horizons.
- Color: disturbance regime (light/medium/dark from design system)
- Direct annotation: mark the optimum in each panel

**If prop_main stays at 3 levels (fallback):**

Dot plot with error bars. Y = metric, X = strategy (0.8, 0.9, 1.0), faceted by disturbance. Honest about what it is: a categorical comparison of 3 strategies, not a continuous optimization. Don't oversell it.

**Do not use petal/radar plots.** They obscure uncertainty, resist precise reading, and will not survive review at any of the target journals.

**Supplementary:** Cost breakdown as stacked bar (fixed, substrate, outplanting, maintenance, lab, spawning costs).

---

## Figure 4 — Lab Retention Trade-off

**Depends on:** Lab survival × growth sensitivity sweep (priority #2 above). Binary comparison exists; the 2D surface is the target.

**Goal:** Show the trade-off between lab retention time and restoration outcomes.

**Data needed:**

- Binary: immediate outplanting ("0_T1", s0 = 0.95) vs. 1-year retention ("1_T1", s1 = 0.70)
- Sensitivity sweep: lab survival (0–1) × lab growth probability (0–1), ~10 levels each
- Lab capacity: 3,100 tiles total, 1,550 allocated for retention
- Run under most policy-relevant disturbance scenario (D5)

**Layout — 2 panels:**

**Panel A — Trade-off surface (the main result):**

- X: lab survival during retention (0–1)
- Y: lab growth probability during retention (0–1)
- Fill: reef cover difference (retention minus immediate, m² at year 50)
- Break-even contour line (where retention = immediate) — the key visual element, make it prominent
- Annotate current empirical estimates (s1 = 0.70, growth from size_props1) with crosshairs
- Message: "retention is worth it only if your lab hits these benchmarks"

**Panel B — Time series at empirical parameter values:**

- Reef cover over 51 years: immediate vs. 1-year retention
- 90% CI ribbons
- Under D5 disturbance
- Shows temporal dynamics: retention starts slower but may overtake

**Design:**

- Viridis fill (sequential, colorblind-safe) for heatmap
- Diverging fill centered on zero could also work (blue = retention worse, red = retention better)
- Target: single-column width (88mm) if the heatmap is clean enough

---

## Figure 5 — Outplanting Size Strategy

**Depends on:** Multi-size-class PVA runs (priority #3 above). Current code tests SC1 only; need SC1–SC5 across outplanting rate and recruitment gradients.

**Goal:** Show how outplanting larger vs. smaller corals affects restoration speed and efficiency.

**Data needed (from `popvi_mod()`):**

- 5 size classes: SC1 (0.1 cm²), SC2 (43 cm²), SC3 (369 cm²), SC4 (2,158 cm²), SC5 (11,171 cm²)
- Outplanting rates: 0–100 individuals/year
- External recruitment: 0–50 larvae/year
- 10-year horizon; threshold: 100,000 cm² total area
- **Note:** uses simplified PVA model, not the full 3-compartment model. Acknowledge in caption. Verify key findings against full model.

**Layout — 2 panels:**

**Panel A — Trajectories by size class:**

- Reef area (m²) over 10 years, one line per outplanting size class (SC1–SC5)
- Fixed outplanting rate (50/year), moderate recruitment
- Sequential viridis palette by size class (light = small, dark = large)
- Shows SC3–SC5 pulling ahead due to higher survival and reproductive contribution

**Panel B — Minimum investment to reach threshold:**

- X: outplanting rate (0–100/yr)
- Y: reef area at year 10 (m²), or time to reach 100,000 cm²
- One curve per size class
- Annotate: "SC3 reaches threshold at X individuals/year"
- The actionable panel — tells practitioners the minimum effort per strategy

**Dropped from original brainstorm:** Panel C (recruitment sensitivity heatmap for SC3 only). This is a third dimension of complexity in an already dense figure. Move to supplement if needed.

**Design consideration:** If growing to SC3 costs more per colony than outplanting at SC1, add a cost annotation connecting back to Fig 3's ROI theme.

---

## Supplementary Figures

| Fig | Content | Status | Rationale |
|-----|---------|--------|-----------|
| S1 | **Sensitivity/elasticity analysis** — elasticity heatmap from `rse_sensitivity.rmd` | Ready (mean parameters only) | Required for a demographic modeling paper. Reviewers will ask. |
| S2 | **Cost breakdown** — stacked bar by strategy | Ready from `metrics_dt_fun()` cost components | Supports Fig 3 ROI interpretation |
| S3 | **Size class composition** — reef population structure at year 50 under different strategies | Needs extraction from model output | Shows whether strategies produce structurally different reefs |
| S4 | **Recruitment sensitivity for SC3** — heatmap: outplanting rate × external recruitment → reef area at year 10 | Not ready (needs PVA runs) | Dropped from Fig 5 Panel C |

**Cut from original brainstorm:**

- Full parameter distributions (S3 in original) → present as appendix table instead
- Orchard dynamics time series (S4 in original) → fold key result into Fig 3 annotation or caption
- Synthesis decision surface → either promote to main text or cut. Don't hedge in supplement.

---

## Cross-Figure Design System

### Color encoding

| Element | Color | Usage |
|---------|-------|-------|
| Baseline / no restoration | Gray (#999999) | Figs 2–5 |
| Restoration / active management | Teal (#009E73, Okabe-Ito) | Fig 2 accent, Fig 1 highlights |
| Disturbance D0 | Light tone | Figs 2–3 |
| Disturbance D3 | Medium tone | Figs 2–3 |
| Disturbance D5 | Dark tone | Figs 2–3 |
| Size classes SC1–SC5 | Sequential viridis (5 stops) | Figs 1, 5 |
| Compartments: Lab / Orchard / Reef | 3 distinct hues (TBD) | Fig 1, sparingly elsewhere |

### Layout and typography

- `theme_pub()` or equivalent with width-appropriate `base_size`
- Double-column (170–180mm): Figs 1, 2, 3
- Single-column (88mm): Figs 4, 5 (if panels are clean)
- Panel tags: uppercase letter only (A, B, C), no subtitles in tag
- Direct annotation on key results — quantify the gap, label the optimum
- Shared axes where panels align; suppress redundant tick labels

### Uncertainty convention

- 90% CI ribbons (5th–95th quantile) on all trajectory plots
- Error bars or bootstrapped CIs on point estimates
- Applied consistently — readers should always know what the band represents
- State in first figure caption; reference thereafter

---

## Suggested Sequencing

1. **Quick fixes:** CI label inversion in `ts_fun()`, prop_main documentation. Small but prevents confusion.
2. **Fig 2 first** — data exists, unblocked, and it's the paper's backbone. Good momentum builder.
3. **Expand prop_main** (0.0–1.0 gradient) → **Fig 3.** This is the highest-priority new model run because it unlocks the central resource allocation result.
4. **Lab sensitivity sweep** → **Fig 4.** The 2D heatmap is analytically the most interesting figure.
5. **Multi-size-class PVA** → **Fig 5.** Lower priority — can be scoped down if time is tight.
6. **Supplementary figures** and sensitivity presentation last.
7. **Fig 1 illustration** can happen in parallel with any of the above.

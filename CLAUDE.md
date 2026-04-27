# Coral Restoration Strategy Evaluation (RSE) Models

Stage-structured demographic models for evaluating coral restoration strategies, focused on *Acropora palmata* (Elkhorn Coral) larval propagation. Core equation: `N(t+1) = S * (T + F) * N(t) + R`.

## Repository Layout

```
├── rse_funs.R                        # Core model library (~3000 lines, all functions)
├── coral_demographic_funs.R          # Growth, survival, reproduction parameter generators
├── rse_new_scenario_analyses.rmd     # PRIMARY manuscript analyses (uses rse_mod1)
├── rse_scenario_analyses.Rmd         # Legacy analyses (uses rse_mod — superseded)
├── rest_pars.rmd                     # Restoration parameter estimation from Fundemar data
├── rse_sensitivity.rmd               # Sensitivity analysis
├── rse_population_viability.Rmd      # Population viability analysis
├── rse_fun_copy.Rmd                  # Function documentation/exploration
├── function_tests.Rmd                # R function unit tests
├── model_description.Rmd             # Model documentation
├── data/Fundemar/                    # Field data (settlement, survival, substrate addition)
├── figure-1/                         # Figure 1 — RSE framework schematic (SVG/HTML + PDF/PNG export)
├── figure-suggestions/               # Figure plan and supplement list
├── literature/                       # Literature database (indexes only — PDFs on Drive)
│   ├── DATABASE.csv                  # 174 papers: author, year, title, journal, DOI, domain tags
│   └── LITERATURE.md                 # Hero paper analysis + manuscript-section mapping
├── model-diagram/                    # Standalone D3 model diagram (separate Vite project)
├── coral-app/                        # Interactive web app (React + Vite + TypeScript)
│   ├── src/lib/model/                # TypeScript port of R model logic
│   ├── src/components/               # UI components (diagram, visualizations)
│   └── src/test/                     # Vitest test setup
└── docs/                             # Architecture specs, design docs, parameter provenance
```

## Literature

174 papers organized by domain. PDFs are too large for git (628MB) so they live on Google Drive:

**PDFs:** [coral-rse/literature/](https://drive.google.com/drive/folders/1PJ_zGH0YfXb1zeJRX-zlaJR4JrUWIYRf) on the shared Drive (astier@ucsb.edu)

**Indexes (in this repo):**
- `literature/DATABASE.csv` — sortable spreadsheet with author, year, title, journal, DOI, domain tags, hero paper flag
- `literature/LITERATURE.md` — hero paper analysis, what to mimic, papers organized by manuscript section

## Model Functions (in rse_funs.R)

| Function | Status | Description |
|----------|--------|-------------|
| `rse_mod1()` | **Current** | Main model with density dependence. Use this. |
| `rse_mod()` | Legacy | Area-based constraints, no density dependence. Superseded. |
| `popvi_mod()` | Active | Simplified model for population viability analysis. |
| `mat_pars_fun()` | Core | Assembles demographic parameters per year. |
| `dist_pars_fun()` | Core | Creates disturbance parameter lists. |
| `par_list_fun()` | Core | Samples parameters from empirical data. |
| `default_pars_fun()` | Core | Builds default parameter sets. |
| `rand_pars_fun()` | Core | Generates random parameter ensembles. |
| `pop_lambda_fun()` | Core | Calculates asymptotic growth rate. |
| `model_summ()` | Core | Summarizes model output. |

## Model Structure

- **4 compartments:** External reefs, lab, orchard, restoration reef
- **5 size classes** (cm²): 0, 10, 100, 900, 4000
- `coral_demographic_funs.R` generates size-specific parameters; `rse_funs.R::mat_pars_fun()` assembles them into year-specific sets
- Works for arbitrary n size classes but all current analyses use n=5

## External Dependency

All R analyses require a sibling repo: `Detmer-2025-coral-parameters/` (empirical demographic data). Expected at `../Detmer-2025-coral-parameters/`.

## Commands

```bash
# R models — open Detmer-2025-coral-RSE.Rproj in RStudio, knit Rmd files
# Recommended execution order:
#   model_description → rest_pars → rse_new_scenario_analyses → rse_sensitivity → rse_population_viability

# Web app
cd coral-app && npm install && npm run dev      # Dev server
cd coral-app && npm run build                   # Production build (tsc + vite)
cd coral-app && npm run test                    # Vitest single run
cd coral-app && npm run test:watch              # Vitest watch mode
cd coral-app && npm run test:ui                 # Vitest UI dashboard
cd coral-app && npm run lint                    # ESLint

# Model diagram (separate project)
cd model-diagram && npm install && npm run dev
```

## Web App Stack

- React 19 + TypeScript 5.9 + Vite 7
- @xyflow/react (node-based diagram UI)
- Remotion (video generation)
- Tailwind CSS 4
- Testing: Vitest + @testing-library/react + happy-dom

Test files: `App.test.tsx`, `useDiagramLayout.test.ts`, `matrices.test.ts`, `simulation.test.ts`

## Key Conventions

- `rse_funs.R` is the single source of truth for model functions — all Rmd files source it
- `rse_new_scenario_analyses.rmd` is the current manuscript analysis file; `rse_scenario_analyses.Rmd` is legacy
- Web app TypeScript in `coral-app/src/lib/model/` must stay in sync with R model logic
- Model description also lives in an external Google Doc (linked in README)

## Gotchas

- Editing `rse_funs.R` or `coral_demographic_funs.R` propagates to all downstream analyses
- R analyses won't run without the sibling `Detmer-2025-coral-parameters` repo
- `model-diagram/` is a standalone project with its own package.json and build — not part of coral-app
- `rse_new_scenario_analyses.rmd` is large (~400KB) — loads slowly, has multiple analysis sections in development

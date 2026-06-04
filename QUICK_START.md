# Coral RSE Model - Quick Start

A short orientation to the Restoration Strategy Evaluation (RSE) model for *Acropora
palmata*, developed with Fundemar (Dominican Republic). For background and full project
structure, see [`README.md`](README.md).

---

## Two ways to use the model

### 1. Interactive web app (no R required)

```bash
cd coral-app
npm install
npm run dev
```

Open the local URL it prints (default http://localhost:5173). The app lets you explore
restoration strategies and scenarios without writing code. See
[`coral-app/README.md`](coral-app/README.md).

### 2. R analyses (the source of the manuscript results)

| File | Purpose |
|------|---------|
| `rse_new_scenario_analyses.rmd` | **Primary** manuscript scenario analyses (current) |
| `rse_funs.R` | RSE model functions (shared dependency) |
| `coral_demographic_funs.R` | Coral demographic functions (shared dependency) |
| `model_description.Rmd` | Model walkthrough with worked examples |
| `rest_pars.rmd` | Restoration / lab parameters derived from Fundemar data |
| `rse_sensitivity.rmd` | Parameter sensitivity analysis |
| `rse_population_viability.Rmd` | Population viability analysis |

The R analyses read demographic parameters from the sibling repo
[`Detmer-2025-coral-parameters`](https://github.com/stier-lab/Detmer-2025-coral-parameters),
which must be cloned alongside this one at `../Detmer-2025-coral-parameters/`.

---

## The model in brief

The model tracks coral through three linked compartments -- **lab**, **orchard**, and
**restoration reef** -- using a stage-structured demographic projection:

```
N(t+1) = S * (T + F) * N(t) + R
```

- **S** survival, **T** growth/shrinkage transitions, **F** fragmentation, **R** recruitment.

### Five size classes (planar live tissue area, cm^2)

| Class | Range | Midpoint | Role |
|-------|-------|----------|------|
| SC1 | 0-10 | 5 | Recruits / settlers |
| SC2 | 10-100 | 55 | Small juveniles |
| SC3 | 100-900 | 500 | Large juveniles |
| SC4 | 900-4,000 | 2,450 | Subadults |
| SC5 | >4,000 | 9,325 | Reproductive adults |

---

## Where to read more

- Model architecture and parameters: [`docs/MODEL_ARCHITECTURE_SPECIFICATION.md`](docs/MODEL_ARCHITECTURE_SPECIFICATION.md), [`docs/model_summary.md`](docs/model_summary.md)
- Parameter values and provenance: [`docs/PARAMETER_PROVENANCE.md`](docs/PARAMETER_PROVENANCE.md)
- Fecundity literature: [`docs/FECUNDITY_LITERATURE_SUMMARY.md`](docs/FECUNDITY_LITERATURE_SUMMARY.md)

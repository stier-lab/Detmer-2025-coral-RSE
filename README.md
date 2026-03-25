# Coral Restoration Strategy Evaluation Models

## Background

*Acropora palmata* (Elkhorn Coral) is a threatened Caribbean reef-builder listed under the U.S. Endangered Species Act. Larval propagation -- collecting gametes, rearing larvae in the lab, settling them onto substrates, and growing them in ocean-based nurseries before transplanting to degraded reefs -- is an emerging restoration technique. However, we currently lack quantitative tools to evaluate the trade-offs inherent in these strategies: How many settlement tiles should we produce? What proportion of corals should go to orchards versus directly to reefs? When is the right time to transplant?

We developed this model in collaboration with Fundemar (Dominican Republic) to answer those questions. The model tracks coral populations through three linked compartments -- lab, orchard, and restoration reef -- using stage-structured demographic matrices. This enables head-to-head comparison of restoration strategies under realistic demographic rates derived from field data, giving practitioners a quantitative basis for decision-making.

See full model description: https://docs.google.com/document/d/1BZKpY6Miuxl-hSjrSZDMMTi1NgYexdEllyUdFK8ZDHY/edit?tab=t.0

---

## Interactive Web Application

An interactive web application is available for exploring the model without writing R code.

### Quick Start

```bash
cd coral-app
npm install
npm run dev
```

Open http://localhost:5173 to use the application.

See [coral-app/README.md](coral-app/README.md) for details.

---

## Project Structure

```
Detmer-2025-coral-RSE/
├── coral_demographic_funs.R         # Coral demographic functions (shared dependency)
├── rse_funs.R                       # RSE model functions (shared dependency)
├── model_description.Rmd            # Model walkthrough with worked examples
├── rest_pars.rmd                    # Restoration parameters from Fundemar data
├── rse_new_scenario_analyses.rmd    # Primary manuscript scenario analyses (current)
├── rse_scenario_analyses.Rmd        # Legacy scenario analyses
├── rse_sensitivity.rmd              # Parameter sensitivity analysis
├── rse_population_viability.Rmd     # Population viability analysis
├── function_tests.Rmd               # Function unit tests
├── rse_fun_copy.Rmd                 # Function documentation/exploration
│
├── coral-app/                       # Interactive web application (React + TypeScript)
│   ├── src/
│   │   ├── lib/model/               # TypeScript model implementation
│   │   ├── components/              # UI components
│   │   └── ...
│   └── README.md
│
└── docs/                            # Technical documentation
    ├── MODEL_ARCHITECTURE_SPECIFICATION.md
    ├── FRONTEND_ARCHITECTURE.md
    ├── VISUAL_DESIGN_SPECIFICATION.md
    ├── FRONTEND_IMPLEMENTATION_SUMMARY.md
    └── README_VISUALIZATIONS.md

# NOTE: All Rmd files depend on the sibling repository Detmer-2025-coral-parameters
# (clone it alongside this repo so they share a parent directory)
```

---

## Getting Started for Researchers

### Required repositories

Clone both of these into the same parent directory:

1. **This repo** -- `Detmer-2025-coral-RSE`
2. **`Detmer-2025-coral-parameters`** -- contains the Fundemar-derived demographic parameter estimates that all analyses read from

```
parent-directory/
├── Detmer-2025-coral-RSE/
└── Detmer-2025-coral-parameters/
```

### R packages

Install these before running any analysis:

```r
install.packages(c("tidyverse", "tictoc", "popbio", "readxl", "janitor"))
```

### File execution order

We recommend working through the files in this order:

1. **`model_description.Rmd`** -- Learn the model. This is a worked example walkthrough of the full demographic framework.
2. **`rest_pars.rmd`** -- Understand the restoration parameters derived from Fundemar field data.
3. **`rse_new_scenario_analyses.rmd`** -- Primary manuscript analysis. This is where we evaluate head-to-head strategy comparisons.
4. **`rse_sensitivity.rmd`** -- Parameter sensitivity analysis.
5. **`rse_population_viability.Rmd`** -- Population viability analysis.
6. **`function_tests.Rmd`** -- Function unit tests. Run these to verify everything works after making changes.

### Key model functions

- **`rse_mod1()`** -- Current model with density dependence (use this for new analyses)
- **`rse_mod()`** -- Legacy model without density dependence
- **`popvi_mod()`** -- Simplified model for population viability analysis

### Core dependency chain

All Rmd files source both `coral_demographic_funs.R` and `rse_funs.R` at the top of their setup chunks. If you modify either of these shared files, every analysis downstream is affected -- coordinate edits carefully.

---

## Model Overview

This is a stage-structured population dynamics model for coral restoration, featuring:

- **5 size classes** (SC1-SC5) based on colony area
- **4 compartments**: External Reefs, Lab, Orchard, Restoration Reef
- **Demographic processes**: Survival, growth, shrinkage, fragmentation, reproduction
- **Management parameters**: Carrying capacity, collection efficiency, outplanting strategies

### Core Equation

```
N(t+1) = S * (T + F) * N(t) + R
```

Where:
- **S**: Survival matrix
- **T**: Transition matrix (growth/shrinkage/stasis)
- **F**: Fragmentation matrix (asexual reproduction)
- **R**: Recruitment vector

---

## Documentation

### For Researchers
- **[docs/MODEL_ARCHITECTURE_SPECIFICATION.md](docs/MODEL_ARCHITECTURE_SPECIFICATION.md)** -- Complete model specification
- **[coral-app/README.md](coral-app/README.md)** -- Web application guide

### For Developers
- **[docs/FRONTEND_ARCHITECTURE.md](docs/FRONTEND_ARCHITECTURE.md)** -- Technical architecture
- **[docs/FRONTEND_IMPLEMENTATION_SUMMARY.md](docs/FRONTEND_IMPLEMENTATION_SUMMARY.md)** -- Implementation summary
- **[docs/VISUAL_DESIGN_SPECIFICATION.md](docs/VISUAL_DESIGN_SPECIFICATION.md)** -- Design system guide

---

## Contributing

This is a research project from the Stier Lab at UCSB. For questions or contributions:

1. Fork the repository
2. Create a feature branch
3. Submit a pull request

---

## Contact

**Stier Lab**
Department of Ecology, Evolution, and Marine Biology
University of California, Santa Barbara

For questions about the model or code, please open an issue on GitHub.

---

**Status**: Active development -- manuscript analyses in progress

**Built with**: R, React, TypeScript, TailwindCSS

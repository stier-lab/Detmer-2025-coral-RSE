# Coral Restoration Strategy Evaluation (RSE) Model Architecture

**Purpose:** Reference document for diagramming and discussing the RSE model structure, components, parameters, and decision points.

**Species:** *Acropora palmata* (Elkhorn Coral)

---

## 1. Model Overview

The RSE model is a **size-structured population dynamics model** that simulates coral populations across three interconnected locations — **reefs**, **orchards** (coral nurseries), and **labs** — to evaluate different restoration strategies. The key innovation is tracking coral **provenance** (origin/treatment pathway) throughout the system, so each restoration pathway can be evaluated independently.

### Core Equation (applied per location, per source)

```
N(t+1) = (T + F) %*% (S * N(t)) + R(t)
```

Implementation: survival is applied **element-wise first** (`S * N(t)`), then the combined transition + fragmentation matrix is applied via **matrix multiplication** (`%*%`).

| Symbol | Meaning |
|--------|---------|
| **N(t)** | Population vector [5 x 1] — individuals in each size class |
| **S** | Survival vector [5] — annual survival probability per size class (applied element-wise) |
| **T** | Transition matrix [5 x 5] — growth, shrinkage, stasis (columns sum to 1; see note below) |
| **F** | Fragmentation matrix [5 x 5] — asexual reproduction (columns can sum > 1) |
| **R(t)** | Recruitment — external settlers + lab outplants added to population |

> **Note on T columns:** Columns normally sum to 1, but in rare edge cases where growth + shrinkage probabilities exceed 1, the diagonal (stasis) is clamped to 0, so the column sum may be < 1.

---

## 2. Size Classes

All populations are structured into 5 size classes based on **planar colony area (cm^2)**:

| Class | Area Range (cm^2) | Midpoint (cm^2) | Ecological Role |
|-------|-------------------|-----------------|-----------------|
| SC1 | 0 -- 10 | 0.1 | Recruits / settlers |
| SC2 | 10 -- 100 | 43 | Small juveniles |
| SC3 | 100 -- 900 | 369 | Large juveniles (begin reproducing) |
| SC4 | 900 -- 4,000 | 2,158 | Subadults (reproduce + fragment) |
| SC5 | > 4,000 | 11,171 | Reproductive adults (max fecundity + fragmentation) |

> **Note:** Midpoint values (`A_mids`) are passed as a parameter to the simulation functions, not hardcoded. The values above are typical values used in analyses.

**Key patterns across size classes:**
- Survival increases with size (SC1 ~ 0.1-0.2, SC5 ~ 0.8-0.95)
- Growth rate decreases with size
- Only SC3-SC5 reproduce sexually (produce larvae)
- Only SC4-SC5 fragment (asexual reproduction)

---

## 3. Three Locations

### 3a. Reef (Wild / Restoration Site)

The target ecosystem. Corals on the reef experience:
- **Full demographic rates** (survival, growth, shrinkage, fragmentation, fecundity)
- **Space limitation** by area — carrying capacity in cm^2 (`reef_areas`)
- **External recruitment** — wild larvae from outside the system (`lambda`)
- **Disturbance** — periodic events (e.g., hurricanes) can modify any demographic rate

**Population sources tracked on reef:**
- Source 0: External wild recruits
- Sources 1-N: One per lab treatment outplanted to reef

### 3b. Orchard (Coral Nursery)

A managed grow-out facility (e.g., underwater coral trees/tables). Corals experience:
- **Enhanced survival** (protected from predation/competition)
- **Faster growth** (managed conditions)
- **No fragmentation** (managed environment, fragments are collected)
- **Colony count limitation** — carrying capacity by number of individuals (`orchard_size`)

**Key role:** Orchards grow corals to reproductive size so they produce larvae for the lab pipeline, and can serve as a source of large transplants to reef.

**Population sources tracked in orchard:**
- Sources 1-N: One per lab treatment outplanted to orchard (no external recruits)

### 3c. Lab (Larval Rearing Facility)

Where collected larvae are settled onto tiles and grown out before outplanting. Characterized by:
- **Settlement** — larvae attach to tiles (settlement rate ~ 15%)
- **Density-dependent survival** — `S = s_base * exp(-m * density)` where density = settlers/tile
- **Two timing pathways:**
  - **0_TX** (immediate): Settle and outplant in the same year
  - **1_TX** (retained): Settle, grow in lab for 1 year, outplant next year
- **Tile types** (e.g., cement T1, ceramic T2) with different settlement rates
- **Capacity constraints** — limited by total tiles (`lab_max`) and retention capacity (`lab_retain_max`)

---

## 4. Annual Cycle — Order of Operations

Each time step (1 year), the following operations occur in sequence:

```
YEAR t -> t+1
|
|-- STEP 1: REEF DYNAMICS
|     For each reef x source:
|       Apply survival (S)
|       Apply transition matrix (T) + fragmentation (F)
|       Record pre-outplant state
|
|-- STEP 2: EXTERNAL RECRUITMENT TO REEF
|     Distribute wild recruits across reefs proportional to reef area
|     Add to SC1 of source 0
|
|-- STEP 3: ORCHARD DYNAMICS
|     For each orchard x source:
|       Apply survival (S)
|       Apply transition matrix (T) only (no fragmentation)
|       Record pre-outplant state
|
|-- STEP 4: REPRODUCTION (Larval Production)
|     Calculate larvae from reef populations (fecundity x population)
|     Calculate larvae from orchard populations (fecundity x population)
|
|-- STEP 5: LARVAL COLLECTION
|     Collect fraction of orchard larvae (orchard_yield)
|     Collect fraction of reference reef larvae (reef_yield)
|     Pool collected larvae (cap at lab_max capacity)
|
|-- STEP 6: LAB PROCESSING
|     Split larvae between immediate (0_TX) and retained (1_TX)
|     Allocate to tile types based on tile_props
|     Apply settlement success (sett_props)
|     Apply density-dependent survival
|     Store retained cohort for next year's outplanting
|
|-- STEP 7: OUTPLANTING
|     Distribute lab cohorts to reef and orchard:
|       reef_prop -> fraction to reef vs orchard
|       reef_out_props -> distribution across reef sites
|       orchard_out_props -> distribution across orchard sites
|     Check space constraints (reef area, orchard count)
|     Spillover: excess orchard recruits -> reef
|     Distribute across size classes via size_props
|
|-- STEP 8: TRANSPLANTING (if scheduled)
|     Move specified colonies from orchard -> reef
|     Direct transfer of large individuals (bypasses lab)
```

---

## 5. Demographic Processes (Detail)

### 5a. Survival

- **Input:** `surv_pars` = vector of 5 baseline probabilities
- **Stochasticity:** Log-normal annual variation: `S_year = surv_pars * exp(N(0, sigma_s))`
- **Bounds:** Clamped to [0, 1]
- **Varies by location:** Reef (field) has lower survival than orchard (nursery)
- **Disturbance:** Can be overridden in disturbance years

### 5b. Growth & Shrinkage (Transition Matrix T)

A 5x5 column-stochastic matrix where:
- **Above diagonal:** Growth — probability of transitioning to a larger class
- **Below diagonal:** Shrinkage — probability of transitioning to a smaller class (partial mortality)
- **Diagonal:** Stasis — probability of remaining in the same class = 1 - sum(growth) - sum(shrinkage)
- **Column sum = 1** (each individual goes somewhere, but see Section 1 note on edge-case clamping)

No annual stochasticity in growth/shrinkage in current implementation.

### 5c. Fragmentation (Matrix F)

A 5x5 matrix representing asexual reproduction:
- Only SC4 and SC5 have non-zero columns
- Fragments can land in any size class <= parent
- **Column sums can exceed 1** (one parent produces multiple fragments = new individuals)
- Set to **zero in orchards** (managed environment)

### 5d. Fecundity (Sexual Reproduction)

- **Input:** `fec_pars` = vector of 5 values (larvae per individual per year)
- SC1-SC2 = 0 (too small to reproduce)
- SC3-SC5 = thousands to hundreds of thousands of larvae
- **Stochasticity:** Log-normal annual variation: `F_year = fec_pars * exp(N(0, sigma_f))`
- **Current estimate:** ~48,273 embryos per colony per spawning event

### 5e. External Recruitment

- Wild larvae from outside the modeled system
- `lambda` = mean recruits/year to reef
- Can be constant or Poisson-distributed (`ext_rand`)
- Distributed across reefs proportional to area

### 5f. Density Dependence

Currently implemented **only in the lab**:
- Formula: `survival = s_base * exp(-m * density)`
- `m0` / `m1` = density-dependent mortality coefficients
- `density` = settlers per tile
- Reef/orchard density dependence framework exists in code but is not active

---

## 6. Restoration Strategy Parameters

These are the **decision variables** — the levers a restoration manager can pull:

### 6a. Collection & Lab Decisions

| Parameter | Description | Typical Range |
|-----------|-------------|---------------|
| `orchard_yield` | Fraction of orchard larvae collected | 0 -- 1 |
| `reef_yield` | Fraction of reference reef larvae collected | 0.001 -- 0.01 |
| `spawn_target` | Target number of larvae to process per year | ~2,000,000 |
| `lab_max` | Total tile capacity in lab | ~3,100 tiles |
| `lab_retain_max` | Tiles reserved for 1-year grow-out | 0 -- 3,100 |
| `tile_props` | Fraction of lab space per tile type (e.g., 50/50 cement/ceramic) | Sums to 1 |
| `sett_props` | Settlement success rate by tile type | ~0.15 |
| `tank_max` / `tank_min` | Larvae per tank bounds | ~14,600 / varies |

### 6b. Allocation Decisions

| Parameter | Description | Typical Range |
|-----------|-------------|---------------|
| `reef_prop[treatment]` | Fraction of each lab treatment sent to reef (vs. orchard) | 0 -- 1 |
| `reef_out_props[treatment, reef]` | Distribution of reef-bound outplants across reef sites | Sums to 1 per treatment |
| `orchard_out_props[treatment, orchard]` | Distribution of orchard-bound outplants across orchards | Sums to 1 per treatment |
| `size_props[treatment, 1:5]` | Size class distribution of outplants from each lab treatment | Sums to 1 |

### 6c. Space & Capacity

| Parameter | Description | Typical Value |
|-----------|-------------|---------------|
| `reef_areas[reef]` | Carrying capacity per reef site (cm^2) | ~78,370,000 (~7,837 m^2) |
| `orchard_size[orchard]` | Max colonies per orchard | ~15,000 (30 tiles/star x 500 stars) |

### 6d. Transplanting

| Parameter | Description |
|-----------|-------------|
| `transplant[year]` | Binary — whether transplanting occurs this year |
| `trans_mats[orchard][source][year, size_class]` | Number of colonies to transplant |
| `trans_reef[orchard][source][year, 1:2]` | Destination reef and source index |

---

## 7. Disturbance System

Disturbances (hurricanes, bleaching, disease) can override any demographic parameter in specified years:

| Parameter | Description |
|-----------|-------------|
| `dist_yrs` | Vector of years when disturbances occur (e.g., every 3 years) |
| `dist_effects` | Which parameters affected per event: "survival", "Tmat", "Fmat", "fecundity" |
| `dist_pars$dist_surv` | Replacement survival values (e.g., 25% of baseline for reef, 40% for orchard) |
| `dist_pars$dist_Tmat` | Replacement transition matrices |
| `dist_pars$dist_Fmat` | Replacement fragmentation matrices |
| `dist_pars$dist_fec` | Replacement fecundity vectors |

Reef and orchard can have **different disturbance effects** (orchards are somewhat protected).

---

## 8. Stochasticity & Uncertainty

| Source | Parameter | Distribution | Notes |
|--------|-----------|-------------|-------|
| Survival variation | `sigma_s` | Log-normal | Year-to-year environmental variation |
| Fecundity variation | `sigma_f` | Log-normal | Year-to-year reproductive variation |
| External recruitment | `ext_rand[1]` | Poisson(lambda) | Wild larval supply |
| Reference reef larvae | `ext_rand[2]` | Poisson(lambda_R) | Reference reef contribution |
| Demographic parameters | `rand_pars_fun()` | Sampled from data | 100 parameter sets per scenario |
| Random seeds | `seeds[1:4]` | — | For reproducibility: surv, fec, ext_rec, ref_larvae |

---

## 9. Model Outputs

### Population Trajectories (primary)

| Output | Dimensions | Description |
|--------|-----------|-------------|
| `reef_pops[reef][source][SC, year]` | 5 x years | Post-outplant reef population |
| `reef_pops_pre[reef][source][SC, year]` | 5 x years | Pre-outplant reef population |
| `orchard_pops[orchard][source][SC, year]` | 5 x years | Post-outplant orchard population |
| `orchard_pops_pre[orchard][source][SC, year]` | 5 x years | Pre-outplant orchard population |
| `lab_pops[treatment][year]` | 1 x years | Settlers retained in lab |

### Reproductive Output

| Output | Description |
|--------|-------------|
| `reef_rep[reef][source][year]` | Larvae produced on reef |
| `orchard_rep[orchard][source][year]` | Larvae produced in orchard |
| `orchard_babies[year]` | Total larvae collected from orchards |
| `reef_babies[year]` | Total larvae collected from reference reef |

### Restoration Tracking

| Output | Description |
|--------|-------------|
| `reef_out[reef][source][year]` | Outplants added to reef |
| `orchard_out[orchard][source][year]` | Outplants added to orchard |
| `tiles_out_tot[year]` | Total tiles outplanted |

---

## 10. Summary Metrics for Strategy Evaluation

The `model_summ()` function computes three metrics across locations:

| Metric | Calculation | Units |
|--------|------------|-------|
| **Individuals** (`"ind"`) | Sum of individuals in specified size classes | Count |
| **Coral cover** (`"area_m2"`) | Sum(individuals x midpoint area) / 10,000 | m^2 |
| **Production** (`"production"`) | Sum of reproductive output | Larvae |

### Scenario Comparison Metrics (from `rse_new_scenario_analyses.rmd`)

| Metric | What It Measures |
|--------|-----------------|
| Reef coral cover (m^2) | Direct restoration goal |
| Orchard function (m^2) | Area of reproductive corals (SC3-SC5) in orchard |
| Reef ROI (m^2/$) | Efficiency of reef investment |
| Total ROI (m^2/$) | Combined reef + orchard efficiency |
| Total costs ($) | Cumulative restoration expenses |
| Reef recruits outplanted | Total recruits outplanted to reef |
| **Strategy score** | Weighted composite of all 6, normalized to [0,1] |

> **Note:** "Reef function" (area of reproductive SC3-SC5 corals on reef) is also tracked and plotted but is not one of the 6 strategy score components.

---

## 11. Key Scenarios Explored

### Scenario A: Orchard Expansion

**Question:** What proportion of lab-produced recruits should go to reef vs. orchard?

- **Decision variable:** `reef_prop` (0 to 1, in 50 steps)
- **Trade-off:** Investing in orchard builds future larval supply but delays direct reef recovery
- **Tested under:** No disturbance (D0) and periodic disturbance every 3 years (D1)
- **Time horizons:** 5 years (short) and 50 years (long)

### Scenario B: Lab Grow-Out (Bet Hedging)

**Question:** Should recruits be outplanted immediately or retained in the lab for 1 year?

- **Decision variable:** `lab_retain_max` (0 to lab_max, in 10 steps)
- **Trade-off:** Retained recruits are larger at outplanting (higher survival) but fewer survive the extra lab year
- **Tested under:** D0 and D1

---

## 12. Function Dependency Graph

```
PARAMETER SETUP
  default_pars_fun() / rand_pars_fun()
    |-- par_list_fun()        [converts data frames -> parameter lists]

DISTURBANCE SETUP
  dist_pars_fun()             [structures disturbance parameters]

DEMOGRAPHIC MATRICES (called inside simulation)
  mat_pars_fun()
    |-- Surv_fun()            [survival with log-normal stochasticity]
    |-- G_fun()               [transition + fragmentation matrices]
    |-- Rep_fun()             [fecundity with log-normal stochasticity]

EXTERNAL RECRUITMENT
  Ext_fun()                   [constant or Poisson recruitment]

SIMULATION (pick one)
  rse_mod1()                  [full model: reef + orchard + lab + tiles]
    |-- mat_pars_fun() x2     [reef params, orchard params]
    |-- Ext_fun() x2          [external recruits, reference reef larvae]
    |-- matrix algebra         [population projection loop]
  rse_mod()                   [simpler: no tile tracking]
  popvi_mod()                 [single-reef PVA]

OUTPUT SUMMARY
  model_summ()                [summarize by location, metric, size classes]
  pop_lambda_fun()            [dominant eigenvalue -> growth rate]
```

---

## 13. Cost Parameters (for ROI calculations)

| Item | Cost |
|------|------|
| Reef stars (substrates) | $84.60 each |
| Lab tiles: cement | $1 each |
| Lab tiles: ceramic | $7 each |
| Lab operations | ~$4,501/year |
| Larval collection | $6,500/event + $400 permits (reef only) |
| Outplanting | $300/day boat + $200/day x 4 divers |
| Orchard maintenance | $230/substrate x 2 visits/year + $300 boat |
| Boat maintenance | $4,800/year |
| Logistics | $6,000/year |

---

## 14. Key Assumptions & Simplifications

1. **Well-mixed populations** — no spatial structure within a reef/orchard
2. **5 discrete size classes** — continuous size distribution is binned
3. **Annual time step** — sub-annual dynamics not modeled
4. **No density dependence on reef/orchard** — only in lab (framework exists but inactive)
5. **No growth stochasticity** — only survival and fecundity vary year-to-year
6. **Orchard has no fragmentation** — managed environment
7. **External recruitment is independent** — not affected by local reef condition
8. **Lab conditions are constant** — no environmental variation in lab
9. **Disturbances are instantaneous** — affect one year's parameters, no carryover
10. **All settlers on a tile type experience same conditions** — no tile-level heterogeneity
11. **Reference reef is constant** — its population doesn't change (in `rse_mod1`)

---

## 15. Suggested Diagram Structure

A diagram of this model could be organized as:

### Top level: Three-location flow diagram
- **Lab** (left) -> **Orchard** (center) -> **Reef** (right)
- With larval flow arrows going: Orchard/Reef -> Lab (collection) -> Orchard/Reef (outplanting)
- And transplant arrows: Orchard -> Reef

### Within each location: Population dynamics box
- 5 size classes (SC1-SC5) connected by growth/shrinkage arrows
- Survival applied to all
- Fragmentation arrows from SC4/SC5 back to smaller classes (reef only)
- Fecundity arrows from SC3-SC5 producing larvae

### Decision points (diamonds)
- `reef_prop`: What fraction goes to reef vs. orchard?
- `lab_retain_max`: What fraction is retained vs. immediately outplanted?
- `transplant`: When to move orchard colonies to reef?

### External inputs
- Wild recruitment (`lambda`) entering reef SC1
- Reference reef larvae (`lambda_R`) entering lab pipeline

### Disturbance overlay
- Periodic events modifying survival/growth/fecundity at reef and orchard

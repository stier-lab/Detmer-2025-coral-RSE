# Coral RSE Model — Comprehensive Component Summary

## Overview

This is a **stage-structured population dynamics model** for *Acropora palmata* (Elkhorn coral) restoration, simulating the integrated management of three linked compartments: **Reef**, **Lab**, and **Orchard**. The model tracks coral populations through 5 size classes over multiple years, incorporating survival, growth, shrinkage, fragmentation, reproduction, and various restoration interventions.

---

## Core Equation

**N(t+1) = [S · (T + F)] · N(t) + R**

Where:
- **N(t)** = Population vector (individuals in each size class at time t)
- **S** = Survival probability vector (diagonal matrix)
- **T** = Transition matrix (growth + shrinkage + stasis)
- **F** = Fragmentation matrix (asexual reproduction via colony breakage)
- **R** = Recruitment (external larvae + lab-reared outplants)

---

## Size Classes

The model uses **5 size classes** based on planar colony area:

| Class | Range (cm²) | Midpoint (cm²) | Description |
|-------|-------------|----------------|-------------|
| SC1 | 0–10 | 0.1 | Recruits/settlers |
| SC2 | 10–100 | 43 | Small juveniles |
| SC3 | 100–900 | 369 | Large juveniles |
| SC4 | 900–4,000 | 2,158 | Subadults |
| SC5 | >4,000 | 11,171 | Reproductive adults |

---

## Compartments

### 1. REEF (Restoration Target)
**Function:** The ultimate restoration target where coral populations are established and monitored.

**Key Dynamics:**
- Receives external recruitment (wild larvae settling naturally)
- Receives lab-reared settlers (outplants)
- Receives transplanted colonies from orchard
- Subject to space constraints based on `reef_areas`
- Populations tracked by size class AND by source (external vs each lab treatment)

**Parameters:**
- `surv_pars.r` — Survival probabilities for each size class (typically 0.4–0.9)
- `growth_pars.r` — Transition probabilities to larger size classes
- `shrink_pars.r` — Transition probabilities to smaller size classes (partial mortality)
- `frag_pars.r` — Fragmentation rates (colony breakage producing new individuals)
- `fec_pars.r` — Fecundity (larvae produced per individual per size class)
- `reef_areas` — Total available area for each reef (carrying capacity)

### 2. LAB (Settlement & Rearing)
**Function:** Processes larvae onto settlement tiles, with options for immediate outplanting or 1-year retention.

**Key Features:**
- Multiple **tile types** (T1 = cement, T2 = ceramic) with different settlement success
- **Timing treatments**:
  - `0_TX` = Outplant immediately after settlement
  - `1_TX` = Retain in lab for 1 year before outplanting
- Settlement success depends on tile type (`sett_props`)
- Density-dependent mortality in lab (`m0`, `m1` parameters)

**Parameters:**
- `sett_props` — Settlement proportion by tile type (e.g., T1: cement, T2: ceramic)
- `s0` — Survival rate for immediate outplanting
- `s1` — Survival rate for 1-year retention
- `m0`, `m1` — Density-dependent mortality coefficients
- `lab_max` — Maximum lab capacity (total larvae that can be processed)
- `lab_retain_max` — Maximum number that can be retained for 1 year
- `tile_props` — Proportion of lab space devoted to each tile type
- `size_props` — Size class distribution of outplants when leaving lab

### 3. ORCHARD (Nursery)
**Function:** Maintains broodstock colonies that produce larvae and can be transplanted to reef.

**Key Features:**
- Grows colonies from lab outplants
- Produces larvae that are collected and sent to lab
- Large colonies can be transplanted directly to reef
- Subject to space constraints (`orchard_size`)
- No fragmentation assumed in orchard (controlled environment)

**Parameters:**
- `surv_pars.o` — Survival probabilities (often higher than field)
- `growth_pars.o` — Growth transition rates (often faster than field)
- `shrink_pars.o` — Shrinkage rates
- `frag_pars.o` — Set to zero (no fragmentation in orchard)
- `fec_pars.o` — Fecundity rates
- `orchard_size` — Maximum number of colonies per orchard
- `orchard_yield` — Fraction of larvae successfully collected

### 4. EXTERNAL (Reference Reefs / Wild Populations)
**Function:** Provides baseline larval recruitment to the restoration reef from wild populations.

**Parameters:**
- `lambda` — Mean number of external recruits per year settling on reef
- `lambda_R` — Mean larvae produced by reference reefs (collected for lab)
- `reef_yield` — Fraction of reference reef larvae successfully collected
- `ext_rand` — Whether recruitment is stochastic (Poisson) or constant

---

## Demographic Functions

### Survival (`Surv_fun`)
**Location:** `coral_demographic_funs.R:13`

Generates survival probabilities with optional stochastic variation:
```
S_i = surv_pars × exp(ε)  where ε ~ N(0, σ_s)
```
Survival capped at 1.0.

### Growth/Shrinkage/Stasis (`G_fun`)
**Location:** `coral_demographic_funs.R:54`

Builds the **transition matrix T** where:
- Above diagonal = growth probabilities (move to larger class)
- Below diagonal = shrinkage probabilities (partial mortality → smaller class)
- Diagonal = stasis (1 - growth - shrinkage)

Also builds the **fragmentation matrix F**:
- Column sums can exceed 1 (new individuals created)
- Only larger size classes (SC4, SC5) produce fragments

### Reproduction (`Rep_fun`)
**Location:** `coral_demographic_funs.R:144`

Generates fecundity values with stochastic variation:
```
F_i = fec_pars × exp(ε)  where ε ~ N(0, σ_f)
```
Typically only SC3+ produce significant larvae.

### External Recruitment (`Ext_fun`)
**Location:** `coral_demographic_funs.R:178`

Either constant (`lambda`) or Poisson-distributed recruitment:
```
recruits ~ Poisson(lambda)  if rand=TRUE
recruits = lambda           if rand=FALSE
```

---

## Restoration Parameters (`rest_pars`)

| Parameter | Description |
|-----------|-------------|
| `reef_areas` | Vector of reef area capacities (cm²) |
| `orchard_size` | Vector of orchard capacities (# colonies) |
| `orchard_yield` | Fraction of orchard larvae collected (0–1) |
| `reef_yield` | Fraction of reference reef larvae collected (0–1) |
| `reef_prop` | Fraction of outplants going to reef vs orchard |
| `reef_out_props` | Distribution of outplants across reef treatments |
| `orchard_out_props` | Distribution of outplants across orchard treatments |
| `tile_props` | Lab space allocation across tile types |
| `transplant` | Binary vector indicating transplant years |
| `trans_mats` | Number of colonies to transplant by size class |
| `trans_reef` | Which reef receives transplants |

---

## Annual Cycle (Model Steps)

Each year `i` proceeds through these steps:

1. **Survival & Growth** — Apply S·(T+F) to existing populations
2. **Reproduction** — Calculate larvae produced by reef and orchard
3. **Larvae Collection** — Collect fraction of larvae (yield parameters)
4. **Lab Processing** — Settle larvae on tiles, apply lab survival
5. **Outplanting** — Move settlers to reef and orchard (immediate or after 1yr)
6. **Transplanting** — Move large orchard colonies to reef (if scheduled)

---

## Space Constraints

The model enforces **carrying capacity** at multiple levels:

**Reef:**
- If `occupied_area >= reef_areas[ss]`, no new recruitment/outplants accepted
- Fragmentation suppressed when reef is full

**Orchard:**
- If `ind_tots >= orchard_size[ss]`, outplants diverted to reef
- Partial acceptance calculated when near capacity

**Lab:**
- Total larvae capped at `lab_max`
- Retained larvae capped at `lab_retain_max`
- Excess assigned to immediate outplanting

---

## Model Outputs

The main function `rse_mod()` returns:

| Output | Description |
|--------|-------------|
| `reef_pops` | Population by size class, reef, source, year |
| `orchard_pops` | Population by size class, orchard, source, year |
| `lab_pops` | Number of retained settlers by treatment, year |
| `reef_rep` | Reproductive output (larvae) by reef/source/year |
| `orchard_rep` | Reproductive output by orchard/source/year |
| `reef_out` | Number outplanted to each reef |
| `orchard_out` | Number outplanted to each orchard |
| `reef_pops_pre` | Reef population before outplanting (for tracking) |
| `orchard_pops_pre` | Orchard population before outplanting |

---

## Disturbance Effects

The model supports **disturbance events** that can modify demographic parameters in specific years:

- `dist_yrs` — Vector of years when disturbances occur
- `dist_effects` — Which parameters affected: "survival", "Tmat", "Fmat", "fecundity"
- `dist_pars` — Replacement parameter values during disturbance years

This allows simulation of hurricanes, bleaching events, disease outbreaks, etc.

---

## Key Model Variants

The codebase includes multiple model versions:

1. **`rse_mod`** — Full model with reef dynamics, reference reefs, and all flows (`rse_funs.R:1438`)
2. **`rse_mod1`** — Simpler model with constant reference reef population (`rse_funs.R:553`)

---

## Parameter Initialization Functions

### `default_pars_fun`
Sets up reef and orchard demographic parameters using summarized data (mean values).

### `rand_pars_fun`
Sets up parameters by randomly sampling from empirical distributions, enabling uncertainty analysis.

### `par_list_fun`
Converts data frames of parameter estimates into list format required by the model.

### `mat_pars_fun`
Generates complete transition matrix parameters for all years, incorporating disturbance effects.

### `dist_pars_fun`
Organizes disturbance parameters by year and effect type.

---

## Summary Metrics (`model_summ`)

Post-processing function that extracts:
- `ind` — Total individuals by location/year
- `area_m2` — Total coral cover in m²
- `production` — Total larval production

---

## Flow Diagram

```
                    ┌──────────────┐
                    │   EXTERNAL   │
                    │ (Wild Reefs) │
                    └──────┬───────┘
                           │ λ_R (larvae to lab)
                           │ λ (recruits to reef)
                           ▼
    ┌──────────────┐   collection   ┌──────────────────────┐
    │     LAB      │◄───────────────│        REEF          │
    │              │                │  (Restoration Target)│
    │  T1 (cement) │                │                      │
    │  T2 (ceramic)│                │  SC1→SC2→SC3→SC4→SC5 │
    │              │                │    ◄──shrinkage──◄   │
    │  0_ = immed. │    outplant    │      ↘frag↘          │
    │  1_ = 1yr    │───────────────►│                      │
    └──────┬───────┘                └──────────────────────┘
           │                                   ▲
           │ outplant                          │ transplant
           ▼                                   │
    ┌──────────────┐    larvae collection      │
    │   ORCHARD    │───────────────────────────┘
    │   (Nursery)  │
    │              │
    │  Broodstock  │
    │  SC2-SC5     │
    └──────────────┘
```

---

This model provides a comprehensive framework for evaluating different coral restoration strategies by comparing outcomes across various combinations of lab treatments, outplanting schedules, and transplant timing.

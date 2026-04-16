# Parameter Provenance

Maps each model parameter to its empirical source. We organize by compartment
(reef, orchard, lab, external) to match the model structure in `rse_mod1()`.

**Companion data repo:** All `.rds` and `.csv` parameter files live in
[Detmer-2025-coral-parameters](https://github.com/stier-lab/Detmer-2025-coral-parameters).
We load them in `rse_new_scenario_analyses.rmd` (lines 39-63) via
`DATA_PATH <- "../Detmer-2025-coral-parameters"`.

---

## Size Class Boundaries

We define 5 size classes based on planar colony area (cm^2) for *Acropora palmata*.

| Parameter | Value | Source | Notes |
|-----------|-------|--------|-------|
| SC1 lower bound | 0 cm^2 | Standardized literature data | Recruits/settlers |
| SC2 lower bound | 10 cm^2 | Standardized literature data | Small juveniles |
| SC3 lower bound | 100 cm^2 | Standardized literature data | Large juveniles |
| SC4 lower bound | 900 cm^2 | Standardized literature data | Subadults |
| SC5 lower bound | 4000 cm^2 | Standardized literature data | Reproductive adults |
| A_mids (SC1-SC4) | 5, 55, 500, 2450 cm^2 | Derived | Midpoint of each size class boundary pair: (SC_lower + SC_upper) / 2 |
| A_mids (SC5) | 9325 cm^2 | Standardized literature data | 50th percentile of observations > 4000 cm^2 in the compiled field data |
| n | 5 | Model structure | Number of size classes |

---

## Demographic Parameters (Reef)

We derive reef demographic parameters from the companion `Detmer-2025-coral-parameters`
repo. Field survival and growth were estimated from six published studies of
*A. palmata* (see that repo's README for full provenance). We use mean summary
statistics via `default_pars_fun()`.

| Parameter | Description | Data File | Source | Notes |
|-----------|-------------|-----------|--------|-------|
| surv_pars.r | Annual survival probability by SC (reef) | `field_surv_pars.rds` | 6 published field studies (NOAA, Pausch 2018, Kuffner 2020, USGS USVI, Mendoza-Quiroz 2023, Fundemar) | Extracted via `par_list_fun(par_type="survival")` using mean values from `$SC_surv_summ_df` |
| growth_pars.r | Growth transition probabilities by SC (reef) | `field_growth_pars.rds` | Same 6 studies | Extracted via `par_list_fun(par_type="growth")` using mean values from `$summ_list` |
| shrink_pars.r | Shrinkage (partial mortality) probabilities by SC (reef) | `field_growth_pars.rds` | Same 6 studies | Shrinkage and growth come from the same transition probability data |
| frag_pars.r | Fragmentation rates by SC (reef) | `apal_fragmentation_summ.csv` | Same 6 studies | Only SC4 and SC5 produce fragments; SC1-SC3 set to zero by construction (small colonies lack branching architecture for storm-driven breakage) |
| dens_pars.r | Density-dependent post-outplanting survival coefficient | 0.02 | **Working estimate** | Ricker-type: survivors = outplants * exp(-0.02 * tile_density). Applied at outplanting time, not to total reef population. Needs empirical validation |
| fec_pars.r (SC1-SC2) | Fecundity, recruits and small juveniles | 0 | Biological assumption | SC1-SC2 do not reproduce |
| fec_pars.r (SC3-SC5) | Fecundity, large juveniles through adults | 48,274 embryos per colony | **Empirical**: Fundemar 2025 annual report, Table 1 | Derived: 1,255,111 total embryos / 26 spawning colonies = 48,274. We assume no size-dependent reproduction because (1) lack of data and (2) Fundemar reports smaller colonies sometimes spawn the most |

---

## Demographic Parameters (Orchard / Nursery)

Nursery data cover only SC1-SC2. For SC3-SC5 we substitute field estimates
(lines 114-118 of `rse_new_scenario_analyses.rmd`). We set fragmentation to
zero in orchards because managed nursery substrates are not subject to
storm-driven breakage.

| Parameter | Description | Data File | Source | Notes |
|-----------|-------------|-----------|--------|-------|
| surv_pars.o (SC1-SC2) | Annual survival in nursery, small size classes | `nurs_surv_pars.rds` | Fundemar nursery monitoring data | Mean values from `$SC_surv_summ_df` |
| surv_pars.o (SC3-SC5) | Annual survival in nursery, large size classes | `field_surv_pars.rds` | Same 6 field studies as reef | Substituted from field data because nursery data unavailable for larger size classes |
| growth_pars.o (SC1-SC2) | Growth transitions in nursery, small size classes | `nurs_growth_pars.rds` | Fundemar nursery monitoring data | Mean values from `$summ_list` |
| growth_pars.o (SC3-SC5) | Growth transitions in nursery, large size classes | `field_growth_pars.rds` | Same 6 field studies as reef | Substituted from field data |
| shrink_pars.o | Shrinkage probabilities in nursery | `nurs_growth_pars.rds` + `field_growth_pars.rds` | Same as growth | SC1-SC2 from nursery, SC3-SC5 from field |
| frag_pars.o | Fragmentation rates in nursery | All zeros | Biological assumption | Managed nursery substrates are not subject to storm-driven breakage |
| dens_pars.o | Density-dependent survival coefficient (orchard) | 0.02 | **Working estimate** | Same mechanism as reef. Needs empirical validation |
| fec_pars.o (SC1-SC2) | Fecundity, small nursery corals | 0 | Biological assumption | SC1-SC2 do not reproduce |
| fec_pars.o (SC3-SC5) | Fecundity, large nursery corals | 48,274 embryos per colony | **Empirical**: Fundemar 2025, Table 1 | Same derivation as reef fecundity |

---

## Lab Parameters

We estimate settlement rates from Fundemar's 2025 APAL spawning data in
`rest_pars.rmd`. Lab survival values are working estimates that need
empirical validation.

| Parameter | Value | Source | Notes |
|-----------|-------|--------|-------|
| sett_props (T1, cement) | 0.15 (15%) | **Empirical**: Fundemar 2025 spawning data | Estimated in `rest_pars.rmd`: mean settlers per tile (~20) x tiles per tank (~100) / embryos per tank (~14,600) = ~0.147, rounded to 0.15. May be an underestimate because denominator uses embryos, not all of which become competent larvae |
| s0 | 0.95 | **Working estimate** | Annual survival from settlement to immediate outplanting, applied uniformly across years and lab treatments. Needs empirical validation |
| s1 | 0.70 | **Working estimate** | Annual survival for 1-year retained settlers. Lower than s0 because colonies are held longer in the lab. Needs empirical validation |
| m0 | 0.02 | **Working estimate** | Density-dependent mortality coefficient for immediate-outplant treatments. Ricker-type: survivors = settlers * s0 * exp(-m0 * density). Needs empirical validation |
| m1 | 0.02 | **Working estimate** | Density-dependent mortality coefficient for 1-year retained treatments. Needs empirical validation |
| size_props (0_T1) | [1, 0, 0, 0, 0] | Biological assumption | All immediately outplanted recruits enter SC1 (smallest size class) |
| size_props1 (retained) | [1, 0, 0, 0, 0] | Biological assumption | Default for retained recruits; can be modified to model lab growth into SC2 |

---

## External Recruitment / Reference Reef Parameters

| Parameter | Value | Source | Notes |
|-----------|-------|--------|-------|
| lambda | 0 | Scenario choice | External wild recruitment to the intervention reef. Set to 0 in default scenario (isolated reef receiving no wild settlers) |
| lambda_R | 1,255,111 embryos | **Empirical**: Fundemar 2025 annual report, Table 1 | Total embryos collected from reference reef colonies in 2025. 26 of 31 monitored colonies spawned over 2 days |
| ext_rand | [FALSE, FALSE] | Scenario choice | Element 1: external recruitment deterministic. Element 2: reference reef reproduction deterministic. Set to TRUE for stochastic (Poisson) draws |

---

## Restoration Strategy Parameters

These parameters define operational constraints of Fundemar's restoration
pipeline and the allocation of recruits across sites.

| Parameter | Value | Source | Notes |
|-----------|-------|--------|-------|
| tile_props (T1) | 1.0 | Scenario choice | All tiles are cement (T1) in the single-treatment default |
| orchard_yield | 1.0 | **Operational assumption** | 100% of orchard larvae successfully collected. Needs empirical validation |
| reef_yield | 1.0 | **Operational assumption** | 100% of reference reef larvae collected and fertilized. Needs empirical validation |
| spawn_target | 2,000,000 embryos | Scenario choice | Target embryos to collect from orchard per year. If orchard cannot meet target, shortfall comes from reference reef |
| reef_prop | 0.5 | Scenario choice | 50% of tiles go to reef, 50% to orchard. Varied in orchard expansion analysis |
| reef_out_props | [1] | Model structure | All reef-bound tiles go to a single intervention reef |
| orchard_out_props | [1] | Model structure | All orchard-bound tiles go to a single orchard |
| A_reef | 7,837 m^2 | **Empirical**: Fundemar KML file | Mean of three Fundemar restoration sites: 4,492 + 10,077 + 8,944 m^2, divided by 3. Rough estimates from acreage (1.11 + 2.49 + 2.21 ac) |
| reef_areas | A_reef * 10,000 cm^2 | Derived | Converted from m^2 to cm^2 for internal model units |
| lab_max | 3,100 tiles | **Operational constraint**: Fundemar facility | Total tile capacity of the lab in a single spawning season |
| lab_retain_max | 0 tiles | Scenario choice | No tiles retained for 1-year grow-out in default scenario. Set > 0 for lab grow-out scenarios |
| tank_min | 14,600 embryos | **Derived**: Fundemar 2025 spawning data | From `rest_pars.rmd`: mean volume per tank (~7,300 mL) x mean embryo density (~2 embryos/mL) = 14,600. We reduce the number of tanks if larval supply falls below this threshold to avoid unrealistically low settlement densities |
| tank_max | 33,333 embryos | **Derived**: operational constraint | Chosen to produce ~50 embryos per tile assuming 15% settlement and 100 tiles per tank: 100 tiles x 50 embryos / 0.15 = 33,333 |
| orchard_size | 15,000 tiles | **Operational constraint**: Fundemar facility | 500 coral stars x 30 tiles per star |
| transplant | rep(0, years) | Scenario choice | No transplants in default scenario. Set element to 1 for years when mature colonies move from orchard to reef |

---

## Disturbance Parameters

| Parameter | Default Value | Source | Notes |
|-----------|---------------|--------|-------|
| dist_yrs | years + 10 (= no disturbance) | Scenario choice | Set to year > simulation length to disable disturbance. Set to e.g. c(10) for a disturbance in year 10 |
| dist_effects | "survival" | Model structure | Which demographic parameters the disturbance affects. Options: "survival", "Tmat", "Fmat", "fecundity" |
| dist_surv0 | surv_pars * 0.1 | **Working estimate** | 90% mortality during disturbance (survival drops to 10% of baseline). Needs empirical calibration against hurricane/bleaching data |

---

## Stochasticity Parameters

| Parameter | Default Value | Source | Notes |
|-----------|---------------|--------|-------|
| sigma_s | 0 | Scenario choice | Standard deviation of environmental noise on survival (log scale). Set to 0 for deterministic runs |
| sigma_f | 0 | Scenario choice | Standard deviation of environmental noise on fecundity (log scale). Set to 0 for deterministic runs |
| seeds | [1000, 5000, 10000, 40000] | Scenario choice | Random seeds for survival, fecundity, external recruitment, and reference reef reproduction |

---

## Simulation Structure

| Parameter | Default Value | Source | Notes |
|-----------|---------------|--------|-------|
| years | 51 | Scenario choice | Number of simulation years (often set to 51 for 50-year projections or 101 for 100-year runs) |
| orchard_treatments | "orchard1" | Model structure | Single orchard in default scenario |
| reef_treatments | "reef1" | Model structure | Single intervention reef in default scenario |
| lab_treatments | "0_T1" | Model structure | Single lab treatment: immediate outplant on cement tiles. Naming convention: "X_TY" where X = 0 (immediate) or 1 (retained 1 year), TY = tile type |
| N0.r, N0.o, N0.l | All zeros | Scenario choice | Empty reef, orchard, and lab at simulation start |

---

## Empirical Data Files

Summary of all data files loaded from the `Detmer-2025-coral-parameters` repo.

| File | Format | Contents | Used For |
|------|--------|----------|----------|
| `parameter_lists/field_surv_pars.rds` | R list | `$SC_surv_summ_df` (summary by SC), `$SC_surv_df` (individual observations) | Reef survival, orchard SC3-SC5 survival |
| `parameter_lists/field_growth_pars.rds` | R list | `$summ_list` (5 transition summaries), `$mat_list` (5 individual-level data frames) | Reef growth/shrinkage, orchard SC3-SC5 growth/shrinkage |
| `parameter_lists/nurs_surv_pars.rds` | R list | Same structure as field_surv | Orchard SC1-SC2 survival |
| `parameter_lists/nurs_growth_pars.rds` | R list | Same structure as field_growth | Orchard SC1-SC2 growth/shrinkage |
| `parameter_lists/lab_surv_pars.rds` | R list | Lab survival data | Loaded but not used in default parameter setup |
| `parameter_lists/lab_growth_pars.rds` | R list | Lab growth data | Loaded but not used in default parameter setup |
| `05_data/standardized/apal_fragmentation_summ.csv` | CSV | Summary fragmentation rates by type (F4_SC1, F5_SC2, etc.) | Reef fragmentation (deterministic runs) |
| `05_data/standardized/apal_fragmentation.csv` | CSV | Individual fragmentation observations | Reef fragmentation (stochastic/Monte Carlo runs via `rand_pars_fun`) |
| `05_data/standardized/apal_surv_lab_short.csv` | CSV | Short-term lab survival | Loaded but not used in default parameter setup |
| `data/Fundemar/Adicion_Sustratos_Unificada.xlsx` | Excel | Tank-level spawning data: embryos/mL, volume, substrate counts | Settlement rate estimation in `rest_pars.rmd` |
| `data/Fundemar/Matriz_Asentamiento_Unificada.xlsx` | Excel | Settler counts per substrate per tank | Settlement rate estimation in `rest_pars.rmd` |
| `data/Fundemar/Matriz_Supervivencia_Reclutas_Unificada.xlsx` | Excel | Recruit survival over time | Not yet used in model parameterization |

---

## Key Derivations

### Fecundity (embryos per adult)

From Fundemar 2025 annual report, Table 1:
- Total embryos collected: 1,255,111 (100% fertilization reported)
- Spawning colonies: 26 out of 31 monitored colonies, spawning over 2 days
- Per-colony fecundity: 1,255,111 / 26 = **48,274 embryos per adult**
- We assume size-independent reproduction (same for SC3, SC4, SC5)

### Settlement rate

From `rest_pars.rmd` analysis of Fundemar 2025 APAL data:
- Mean embryos per mL in tanks: ~7,300 mL at ~2 embryos/mL = ~14,600 embryos per tank
- Mean substrates per tank: ~100
- Mean settlers per substrate: ~20
- Settlement rate: (20 settlers/tile x 100 tiles) / 14,600 embryos = **~0.147, rounded to 0.15**

### Tank minimum (embryos per tank)

From `rest_pars.rmd`:
- Mean volume per tank: ~7,300 mL
- Mean embryo concentration: ~2 embryos/mL
- tank_min = 7,300 x 2 = **14,600 embryos**

### Tank maximum (embryos per tank)

Operational cap to prevent overcrowding:
- Target: ~50 embryos per tile at 15% settlement on 100 tiles per tank
- tank_max = 100 x 50 / 0.15 = **33,333 embryos**

### Reef area

From Fundemar KML file (three restoration sites):
- Site 1: 1.11 ac = 4,492 m^2
- Site 2: 2.49 ac = 10,077 m^2
- Site 3: 2.21 ac = 8,944 m^2
- A_reef = mean = **7,837 m^2** (converted to cm^2 internally)

---

## Parameters Needing Empirical Validation

These parameters are working estimates without direct empirical support. We flag
them here for future data collection.

| Parameter | Current Value | Priority | Why It Matters |
|-----------|---------------|----------|----------------|
| dens_pars.r / dens_pars.o | 0.02 | High | Controls post-outplanting density-dependent survival; strongly affects outplanting efficiency |
| s0 (lab survival, immediate) | 0.95 | High | Determines how many settlers survive to become outplants |
| s1 (lab survival, retained) | 0.70 | Medium | Only matters for lab grow-out scenarios |
| m0, m1 (lab density dependence) | 0.02 | Medium | Interacts with tile stocking density |
| orchard_yield | 1.0 | Medium | Likely < 1 in practice; reduces orchard contribution to lab |
| reef_yield | 1.0 | Medium | Likely < 1 in practice; reduces reference reef contribution |
| dist_surv0 | baseline * 0.1 | Low | Only affects disturbance scenarios; should calibrate against hurricane/bleaching mortality data |

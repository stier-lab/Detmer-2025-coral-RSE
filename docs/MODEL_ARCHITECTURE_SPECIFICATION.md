# Coral Restoration System Dynamics Model
## Complete Architecture Specification for Visual Documentation

**Model Type:** Stage-Structured Population Dynamics Model
**Target Species:** *Acropora palmata* (Elkhorn Coral)
**Purpose:** Evaluate restoration strategies integrating lab rearing, nursery cultivation, and field outplanting

---

## Executive Summary

This is a spatially-explicit, size-structured demographic model simulating coral restoration through three interconnected biological compartments (REEF, ORCHARD, LAB) with feedback loops driven by larval production, collection, settlement, and outplanting. The model uses matrix population projection with asexual reproduction (fragmentation) to forecast coral population dynamics under different management strategies.

**Key Innovation:** Tracks coral origins (provenance) throughout the system, enabling evaluation of which restoration pathways (lab treatments × timing × destination) maximize population growth and coral cover.

---

## 1. MATHEMATICAL FOUNDATION

### 1.1 Core Population Projection Equation

```
N(t+1) = S · (T + F) · N(t) + R
```

**Components:**
- **N(t)**: Population state vector [n × 1] where n = 5 size classes
- **S**: Survival diagonal matrix [n × n] with size-specific survival probabilities
- **T**: Transition matrix [n × n] encoding growth, shrinkage, and stasis
- **F**: Fragmentation matrix [n × n] for asexual reproduction (column sums can exceed 1)
- **R**: Recruitment vector [n × 1] from external larvae and lab outplants

### 1.2 Matrix Structure Details

**Survival Matrix (S):**
```
S = diag(s₁, s₂, s₃, s₄, s₅)
```
Where sᵢ ∈ [0, 1] with optional stochasticity: `sᵢ ~ surv_pars[i] × exp(ε)` where `ε ~ N(0, σₛ)`

**Transition Matrix (T):**
```
       SC1   SC2   SC3   SC4   SC5
SC1  [ p₁₁   p₁₂   p₁₃   p₁₄   p₁₅ ]  ← shrinkage probabilities
SC2  [ p₂₁   p₂₂   p₂₃   p₂₄   p₂₅ ]
SC3  [ 0     p₃₂   p₃₃   p₃₄   p₃₅ ]
SC4  [ 0     0     p₄₃   p₄₄   p₄₅ ]
SC5  [ 0     0     0     p₅₄   p₅₅ ]
                      ↑ growth probabilities
```

**Constraint:** Each column sums to 1 (probabilities must be exhaustive)
- Diagonal = stasis: `pᵢᵢ = 1 - Σ(growth) - Σ(shrinkage)`
- Above diagonal = growth to larger class
- Below diagonal = shrinkage (partial mortality → smaller size)

**Fragmentation Matrix (F):**
```
       SC1   SC2   SC3   SC4   SC5
SC1  [ 0     0     0    f₁₄   f₁₅ ]  ← fragments produced in SC1
SC2  [ 0     0     0    f₂₄   f₂₅ ]
SC3  [ 0     0     0    f₃₄   f₃₅ ]
SC4  [ 0     0     0    f₄₄   f₄₅ ]
SC5  [ 0     0     0     0    f₅₅ ]
```

**Key Property:** Column sums can exceed 1 (one large colony → multiple fragments)
- Only SC4 and SC5 fragment (small colonies don't break apart)
- Fragments can land in any smaller size class (including same class)

---

## 2. SIZE CLASS STRUCTURE

The model divides the population into 5 size classes based on **planar colony area** (cm²):

| Size Class | Range (cm²) | Midpoint (cm²) | Ecological Status | Demographic Role |
|------------|-------------|----------------|-------------------|------------------|
| **SC1** | 0 – 10 | 0.1 | Recruits/settlers | High mortality, no reproduction |
| **SC2** | 10 – 100 | 43 | Small juveniles | Moderate growth, minimal reproduction |
| **SC3** | 100 – 900 | 369 | Large juveniles | Faster growth, begins reproduction |
| **SC4** | 900 – 4,000 | 2,158 | Subadults | Fragments begin, high fecundity |
| **SC5** | > 4,000 | 11,171 | Reproductive adults | Maximum fecundity & fragmentation |

**Rationale for Size-Based Structure:**
- Coral demography depends on colony size, not age (many corals have indeterminate growth)
- Colony area drives competitive ability, fecundity, and fragmentation rates
- Enables tracking of growth trajectories and size-specific management

**Midpoint Calculation:**
- SC1-SC4: Arithmetic mean of boundaries
- SC5: 50th percentile of empirical observations >4,000 cm² (9,325 cm²)

---

## 3. BIOLOGICAL COMPARTMENTS

### 3.1 REEF (Restoration Target Site)

**Function:** The ultimate restoration goal where coral populations establish, grow, reproduce, and experience natural dynamics including disturbances.

**State Variables:**
- Population matrix: `reef_pops[[reef]][source]][size_class, year]`
- Occupied area: `Σ(N[i] × A_mids[i])` in cm²
- Reproductive output: `Σ(N[i] × fec_pars[i])` larvae per year

**Demographic Parameters:**
- **Survival:** `surv_pars.r[[reef]][[source]]` — typically 0.4–0.9 per size class
- **Growth:** `growth_pars.r[[reef]][[source]][[size_class]]` — probability vectors
- **Shrinkage:** `shrink_pars.r[[reef]][[source]][[size_class]]` — partial mortality
- **Fragmentation:** `frag_pars.r[[reef]][[source]][[size_class]]` — asexual reproduction
- **Fecundity:** `fec_pars.r[[reef]][[source]]` — larvae per individual (typically 0, 0, 5k, 50k, 100k)

**Sources Tracked:**
1. External recruits (wild larvae from reference reefs)
2. Lab treatment 1 outplants (e.g., cement tiles, immediate)
3. Lab treatment 2 outplants (e.g., ceramic tiles, immediate)
4. Lab treatment 3 outplants (e.g., cement tiles, 1-year retention)
5. *[Additional treatments as configured]*

**Carrying Capacity:** Enforced via `reef_areas[reef]` in cm²
- When `Σ(occupied_area) ≥ reef_areas`, new recruitment/outplants blocked
- Simulates space limitation and competitive exclusion

**Annual Dynamics:**
```
1. Apply survival: N_tmp = N_prev × S
2. Apply growth/fragmentation: N_new = (T + F) × N_tmp
3. Add external recruitment to SC1 (source 1 only)
4. Calculate larval production for collection
5. Receive lab outplants (added to respective source populations)
6. Receive transplants from orchard (if scheduled)
```

**Key Assumptions:**
- Field survival < nursery survival (exposure to predation, disease, storms)
- Fragmentation occurs naturally (hurricanes, physical disturbance)
- All sources within a reef experience the same environmental conditions (can be relaxed)

---

### 3.2 ORCHARD (Nursery / Broodstock Facility)

**Function:** Protected environment for growing coral colonies to larger sizes, producing larvae for collection, and generating transplants for reef.

**State Variables:**
- Population matrix: `orchard_pops[[orchard]][[source]][size_class, year]`
- Total colonies: `Σ(N[i])` across all size classes and sources
- Reproductive output: `Σ(N[i] × fec_pars[i])` larvae per year

**Demographic Parameters:**
- **Survival:** `surv_pars.o` — often higher than field (0.6–0.95) due to reduced predation/disease
- **Growth:** `growth_pars.o` — often faster than field due to optimal conditions
- **Shrinkage:** `shrink_pars.o` — reduced due to controlled environment
- **Fragmentation:** `frag_pars.o` — **set to zero** (no breakage in protected nursery)
- **Fecundity:** `fec_pars.o` — can exceed field rates with supplemental feeding

**Capacity Constraints:**
- `orchard_size[orchard]` — maximum number of colonies (all size classes combined)
- When capacity approached, excess outplants diverted to reef

**Larval Collection:**
- Larvae produced: `Σ(N[i] × fec_pars.o[i])`
- Larvae collected: `larvae_produced × orchard_yield`
- `orchard_yield` ∈ [0, 1] — collection efficiency (nets, timing, fertilization success)

**Transplanting to Reef:**
- Scheduled via `transplant` vector (binary: 0 = no transplant, 1 = transplant year)
- Number by size class: `trans_mats[[orchard]][[source]][year, size_class]`
- Destination: `trans_reef[[orchard]][[source]][year, c(reef_id, source_id)]`
- Use case: Move large broodstock to reef for rapid cover increase

**Annual Dynamics:**
```
1. Apply survival: N_tmp = N_prev × S
2. Apply growth (no fragmentation): N_new = T × N_tmp
3. Calculate larval production
4. Collect larvae → send to lab
5. Receive lab outplants
6. Execute transplants (if scheduled)
```

**Key Assumptions:**
- No fragmentation in controlled nursery environment
- Higher survival/growth than field conditions
- Colonies remain until transplanted (no natural mortality from space limitation)

---

### 3.3 LAB (Settlement & Early Rearing)

**Function:** Process collected larvae onto artificial substrates (tiles), rear through critical early life stages, and prepare for outplanting.

**Structure:**

The lab operates with a **factorial design**:
- **Tile types:** T1 (cement), T2 (ceramic), etc.
- **Timing treatments:**
  - `0_TX` = Outplant immediately after settlement (~weeks)
  - `1_TX` = Retain in lab for 1 year before outplanting

Example: `"0_T1"` = cement tiles with immediate outplanting, `"1_T2"` = ceramic tiles with 1-year retention

**State Variables:**
- `lab_pops[[treatment]][year]` — number of settlers retained for 1 year
- Immediate outplants are transient (not stored as state variable)

**Parameters:**

| Parameter | Description | Typical Values |
|-----------|-------------|----------------|
| `sett_props[[tile]]` | Settlement success rate by tile type | 0.8–0.95 |
| `s0[treatment]` | Survival to immediate outplanting | 0.85–0.95 |
| `s1[treatment]` | Survival during 1-year retention | 0.6–0.8 |
| `m0[treatment]` | Density-dependent mortality coefficient (immediate) | 0–0.01 |
| `m1[treatment]` | Density-dependent mortality coefficient (1-year) | 0–0.02 |
| `size_props[treatment, size_class]` | Size distribution at outplanting | Typically [1,0,0,0,0] for immediate |
| `lab_max` | Total larvae processing capacity | 10,000–40,000 |
| `lab_retain_max` | Maximum retained for 1 year | 1,200–12,000 |
| `tile_props[[tile]]` | Proportion of lab space per tile type | Sums to 1.0 |

**Density-Dependent Survival Model:**
```
Survival = base_survival × exp(-m × N_settlers)
```
Where:
- `base_survival` = s0 (immediate) or s1 (1-year)
- `m` = density-dependent coefficient
- `N_settlers` = number of larvae on treatment

This creates **Allee-like dynamics at high densities** (crowding reduces survival).

**Annual Processing Workflow:**
```
1. Collect larvae from orchard: orchard_larvae = Σ(orchard_rep × orchard_yield)
2. Collect larvae from reference reefs: ref_larvae = lambda_R × reef_yield
3. Total larvae = min(orchard_larvae + ref_larvae, lab_max)
4. Allocate to immediate vs. 1-year retention:
   - tot_settlers1 = min(total_larvae, lab_retain_max)
   - tot_settlers0 = total_larvae - tot_settlers1
5. Distribute across treatments:
   - settlers[treatment] = total × sett_props[tile] × tile_props[tile]
6. Apply survival:
   - Immediate: out_settlers = settlers × s0 × exp(-m0 × settlers)
   - 1-year: lab_pops[i] = settlers × s1 × exp(-m1 × settlers)
7. Outplant to reef/orchard based on:
   - reef_prop[treatment] — fraction going to reef
   - reef_out_props[treatment, reef] — distribution across reefs
   - orchard_out_props[treatment, orchard] — distribution across orchards
8. Apply size distribution: multiply by size_props[treatment,]
```

**Key Innovations:**
- **Provenance tracking:** Each lab treatment creates a distinct source population
- **Flexible timing:** Compare immediate outplanting vs. 1-year rearing
- **Substrate effects:** Different tile types affect settlement and survival
- **Capacity constraints:** Realistic limits on lab throughput

---

### 3.4 EXTERNAL (Reference Reefs / Wild Populations)

**Function:** Provides baseline recruitment to restoration reef and larvae for lab processing, representing the contribution from nearby wild populations.

**Parameters:**

| Parameter | Description | Typical Values |
|-----------|-------------|----------------|
| `lambda` | Mean recruits settling on restoration reef per year | 0–50 |
| `lambda_R` | Mean larvae available from reference reefs per year | 1,000–100,000 |
| `reef_yield` | Collection efficiency from reference reefs | 0.001–0.01 |
| `ext_rand[1]` | Stochasticity in reef recruitment (TRUE = Poisson) | TRUE/FALSE |
| `ext_rand[2]` | Stochasticity in reference reef larvae (TRUE = Poisson) | TRUE/FALSE |

**Annual Dynamics:**

1. **Direct recruitment to reef:**
   ```
   If ext_rand[1] = TRUE: recruits ~ Poisson(lambda)
   Else: recruits = lambda

   Allocated to reefs proportionally: prop[reef] = reef_areas[reef] / Σ(reef_areas)
   ```

2. **Larvae to lab:**
   ```
   If ext_rand[2] = TRUE: ref_babies ~ Poisson(lambda_R)
   Else: ref_babies = lambda_R

   Collected: new_babies.r = ref_babies × reef_yield
   ```

**Biological Interpretation:**
- `lambda`: Natural recruitment from distant reefs (larval dispersal)
- `lambda_R`: Gamete/larva production by nearby spawning populations
- `reef_yield`: Efficiency of gamete collection, fertilization, and transport to lab

**Model Variants:**
- **No external recruitment:** `lambda = 0, lambda_R = 0` (isolated restoration site)
- **Reference reef only:** `lambda = 0, lambda_R > 0` (lab relies entirely on wild spawning)
- **Dual sources:** `lambda > 0, lambda_R > 0` (natural recruitment + lab supplementation)

---

## 4. PROCESS FLOWS & FEEDBACK LOOPS

### 4.1 Annual Cycle Sequence

Each model year executes the following steps **in order**:

```
┌─────────────────────────────────────────────────────────────────┐
│ YEAR i BEGINS                                                   │
└─────────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────────┐
│ STEP 1: SURVIVAL & GROWTH (REEF)                                │
│ ─────────────────────────────────────────────────────────────   │
│ For each reef subpopulation and source:                         │
│   N_tmp = reef_pops[i-1] × S_i                                  │
│   reef_pops[i] = (T_i + F_i) × N_tmp                            │
│   reef_pops_pre[i] = reef_pops[i]  (record pre-outplant state)  │
│                                                                  │
│ Add external recruits to SC1 (source 1 only):                   │
│   reef_pops[1][1][1, i] += ext_rec[i] × ext_props[reef]         │
└─────────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────────┐
│ STEP 2: SURVIVAL & GROWTH (ORCHARD)                             │
│ ─────────────────────────────────────────────────────────────   │
│ For each orchard subpopulation and source:                      │
│   N_tmp = orchard_pops[i-1] × S_i                               │
│   orchard_pops[i] = (T_i + 0) × N_tmp  (no fragmentation!)      │
│   orchard_pops_pre[i] = orchard_pops[i]                         │
└─────────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────────┐
│ STEP 3: REPRODUCTION                                            │
│ ─────────────────────────────────────────────────────────────   │
│ Reef: reef_rep[reef][source][i] = Σ(N × fec_pars.r)             │
│ Orchard: orchard_rep[orchard][source][i] = Σ(N × fec_pars.o)    │
└─────────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────────┐
│ STEP 4: LARVAL COLLECTION                                       │
│ ─────────────────────────────────────────────────────────────   │
│ new_babies.o = Σ(orchard_rep × orchard_yield)                   │
│ new_babies.r = ref_babies[i] × reef_yield                       │
│ tot_babies = min(new_babies.o + new_babies.r, lab_max)          │
│                                                                  │
│ Allocate to immediate vs. 1-year retention:                     │
│   tot_settlers1 = min(tot_babies, lab_retain_max)               │
│   tot_settlers0 = tot_babies - tot_settlers1                    │
└─────────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────────┐
│ STEP 5: LAB SETTLEMENT & SURVIVAL                               │
│ ─────────────────────────────────────────────────────────────   │
│ For each lab treatment:                                         │
│   If "0_" treatment (immediate):                                │
│     settlers = tot_settlers0 × sett_props[tile] × tile_props    │
│     out_settlers = settlers × s0 × exp(-m0 × settlers)           │
│                                                                  │
│   If "1_" treatment (1-year retention):                         │
│     settlers = tot_settlers1 × sett_props[tile] × tile_props    │
│     lab_pops[treatment][i] = settlers × s1 × exp(-m1 × settlers) │
└─────────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────────┐
│ STEP 6: OUTPLANTING FROM LAB                                    │
│ ─────────────────────────────────────────────────────────────   │
│ For each lab treatment:                                         │
│   Current year settlers: out_settlers[treatment]                │
│   Previous year (if "1_" treatment): lab_pops[treatment][i-1]   │
│                                                                  │
│ Reef outplants:                                                 │
│   reef_outplants[treatment, reef] =                             │
│     (current + previous) × reef_prop × reef_out_props           │
│                                                                  │
│ Orchard outplants:                                              │
│   orchard_outplants[treatment, orchard] =                       │
│     (current + previous) × (1-reef_prop) × orchard_out_props    │
└─────────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────────┐
│ STEP 7: SPACE CONSTRAINTS                                       │
│ ─────────────────────────────────────────────────────────────   │
│ For each reef:                                                  │
│   occupied_area = Σ(reef_pops × A_mids)                         │
│   If occupied_area >= reef_areas:                               │
│     prop_fits = 0  (block all outplants)                        │
│   Else:                                                         │
│     prop_fits = 1  (accept all outplants)                       │
│                                                                  │
│   Apply constraint:                                             │
│     reef_outplants[, reef] *= prop_fits[reef]                   │
│                                                                  │
│ For each orchard:                                               │
│   total_colonies = Σ(orchard_pops)                              │
│   If total_colonies >= orchard_size:                            │
│     Calculate partial acceptance proportionally                 │
└─────────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────────┐
│ STEP 8: ADD OUTPLANTS TO POPULATIONS                            │
│ ─────────────────────────────────────────────────────────────   │
│ For each reef and lab treatment source:                         │
│   reef_pops[reef][source] += outplants × size_props[treatment,] │
│                                                                  │
│ For each orchard and lab treatment source:                      │
│   orchard_pops[orchard][source] += outplants × size_props[,]    │
│                                                                  │
│ Record outplanting events:                                      │
│   reef_out[reef][source][i] = total outplanted                  │
│   orchard_out[orchard][source][i] = total outplanted            │
└─────────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────────┐
│ STEP 9: TRANSPLANTING (if scheduled)                            │
│ ─────────────────────────────────────────────────────────────   │
│ If transplant[i] = 1:                                           │
│   For each orchard and source:                                  │
│     num_to_move = trans_mats[orchard][source][i, size_class]    │
│     destination = trans_reef[orchard][source][i, c(reef, src)]  │
│     Remove from: orchard_pops[orchard][source][size_class, i]   │
│     Add to: reef_pops[destination_reef][destination_src][, i]   │
└─────────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────────┐
│ YEAR i COMPLETE                                                 │
│ Advance to year i+1                                             │
└─────────────────────────────────────────────────────────────────┘
```

---

### 4.2 Feedback Loop Diagram

```
                    ┌──────────────────────────────┐
                    │  EXTERNAL REFERENCE REEFS    │
                    │                              │
                    │  Wild coral populations      │
                    └────────┬─────────────────────┘
                             │
                             │ λ_R larvae/year
                             │ × reef_yield
                             ▼
          ┌────────────────────────────────────────┐
          │            LAB FACILITY                │
          │                                        │
          │  Tile Types: T1, T2, ...              │
          │  ┌─────────────┬──────────────┐       │
          │  │ 0_TX        │  1_TX        │       │
          │  │ Immediate   │  1-Year      │       │
          │  │ Outplant    │  Retention   │       │
          │  └─────┬───────┴──────┬───────┘       │
          │        │              │               │
          │    s0 × exp(-m0N)   s1 × exp(-m1N)   │
          └────────┼──────────────┼────────────────┘
                   │              │
                   │ Year i       │ Year i+1
                   │ outplants    │ outplants
                   ▼              ▼
         reef_prop │          (1-reef_prop)
                   │              │
      ┌────────────┴──────┐       │
      ▼                   ▼       ▼
┌──────────────┐    ┌────────────────────┐
│    REEF      │    │     ORCHARD        │
│              │    │                    │
│ SC1 → SC2    │    │  SC2 → SC3 → SC4   │
│  ↓     ↓     │    │   ↓     ↓     ↓    │
│ SC3 → SC4    │    │  SC5 (broodstock)  │
│  ↓     ↓     │    │                    │
│ SC5 (adult)  │    │  No fragmentation  │
│  │           │    │                    │
│  │ Fragment  │    │                    │
│  ↓           │    │                    │
│ SC1-SC4      │    │                    │
│              │    │  Larval production │
│ Larval       │    │         │          │
│ production   │    │         ▼          │
│ (optional    │    │  orchard_yield     │
│  harvest)    │    │         │          │
└──────────────┘    └─────────┼──────────┘
       ▲                      │
       │                      │
       │ transplant           │
       │ (large colonies)     │
       └──────────────────────┘
                              │
                              │ Larvae collected
                              │ for lab processing
                              └─────────────────────►
                                        │
                                        ▼
                             Back to LAB (top of diagram)


LEGEND:
─────►  Material flow (corals, larvae)
══════► Feedback loop
│       Within-compartment growth
↓       Size class transitions
```

---

### 4.3 Key Feedback Mechanisms

1. **Orchard → Lab → Reef/Orchard**
   - Orchard corals reproduce → larvae collected → lab processing → outplants return to orchard (positive feedback)
   - **Implication:** Successful orchard populations accelerate restoration by producing settlers

2. **Reef → Lab (optional, via `reef_yield`)**
   - Reef corals reproduce → larvae collected (if `reef_yield > 0`) → lab processing → outplants back to reef
   - **Currently disabled in most scenarios** (reef_yield = 0.001 is negligible)

3. **Lab Capacity Constraints**
   - Total larvae capped at `lab_max` → bottleneck on restoration rate
   - When orchard production exceeds capacity, excess larvae lost
   - **Management implication:** Lab expansion increases restoration throughput

4. **Space Competition**
   - As reef populations grow → occupied area increases → outplanting blocked when `area ≥ reef_areas`
   - **Density-dependent regulation** without explicit competition equations

5. **Transplant Pathway**
   - Large orchard colonies → directly transplanted to reef → immediate cover increase & reproduction
   - **Trade-off:** Removes broodstock from orchard vs. gains reef reproduction

---

## 5. PARAMETER STRUCTURE & ORGANIZATION

### 5.1 Demographic Parameter Lists

All demographic parameters follow a **nested list structure**:

```
parameter[[location]][[source]][[size_class_info]]
```

**Example for Reef Survival:**
```R
surv_pars.r[[1]][[2]]
#         │   │
#         │   └─ Source 2 (lab treatment 1 outplants)
#         └───── Reef 1
# Returns: c(s1, s2, s3, s4, s5) — survival for each size class
```

**Example for Growth:**
```R
growth_pars.r[[2]][[1]][[3]]
#             │   │   │
#             │   │   └─ Growth from size class 3
#             │   └───── Source 1 (external recruits)
#             └───────── Reef 2
# Returns: c(p34, p35) — probabilities of growing to SC4 or SC5
```

### 5.2 Complete Parameter Reference

#### 5.2.1 Reef Parameters

| Parameter | Dimensions | Description | Typical Range |
|-----------|------------|-------------|---------------|
| `surv_pars.r` | `[reef][source][5]` | Survival probabilities | 0.4–0.9 |
| `growth_pars.r` | `[reef][source][SC]` | Growth transition probabilities | Varies by SC |
| `shrink_pars.r` | `[reef][source][SC]` | Shrinkage transition probabilities | Varies by SC |
| `frag_pars.r` | `[reef][source][SC]` | Fragmentation probabilities | 0–0.3 (SC4-5 only) |
| `fec_pars.r` | `[reef][source][5]` | Larvae per individual per year | 0–100,000 |
| `dens_pars.r` | `[reef][source]` | Density-dependent mortality coef. | 0–0.01 |

**Disturbance Parameters:**
| Parameter | Description |
|-----------|-------------|
| `dist_yrs` | Vector of years when disturbances occur |
| `dist_effects.r[[reef]][[source]][[event]]` | Which parameters affected: "survival", "Tmat", "Fmat", "fecundity" |
| `dist_pars.r[[reef]][[source]]$dist_surv[[event]]` | Replacement survival during disturbance |
| `dist_pars.r[[reef]][[source]]$dist_Tmat[[event]]` | Replacement transition matrix |
| `dist_pars.r[[reef]][[source]]$dist_Fmat[[event]]` | Replacement fragmentation matrix |
| `dist_pars.r[[reef]][[source]]$dist_fec[[event]]` | Replacement fecundity |

#### 5.2.2 Orchard Parameters

| Parameter | Dimensions | Description | Typical Range |
|-----------|------------|-------------|---------------|
| `surv_pars.o` | `[orchard][source][5]` | Survival probabilities | 0.6–0.95 |
| `growth_pars.o` | `[orchard][source][SC]` | Growth transition probabilities | Higher than field |
| `shrink_pars.o` | `[orchard][source][SC]` | Shrinkage transition probabilities | Lower than field |
| `frag_pars.o` | `[orchard][source][SC]` | **Always zero** (no fragmentation) | 0 |
| `fec_pars.o` | `[orchard][source][5]` | Larvae per individual per year | 0–100,000 |
| `dens_pars.o` | `[orchard][source]` | Density-dependent mortality coef. | 0 (usually disabled) |

#### 5.2.3 Lab Parameters

| Parameter | Dimensions | Description | Typical Range |
|-----------|------------|-------------|---------------|
| `s0` | `[treatment]` | Survival to immediate outplanting | 0.85–0.95 |
| `s1` | `[treatment]` | Survival during 1-year retention | 0.6–0.8 |
| `m0` | `[treatment]` | Density-dependent mortality (immediate) | 0–0.01 |
| `m1` | `[treatment]` | Density-dependent mortality (1-year) | 0–0.02 |
| `sett_props` | Named list by tile | Settlement success rate | 0.8–0.95 |
| `size_props` | `[treatment, 5]` | Size distribution at outplanting | Row sums = 1 |

**Example `sett_props`:**
```R
sett_props = list(T1 = 0.95, T2 = 0.90, T3 = 0.85)
```

**Example `size_props` (immediate outplanting):**
```R
size_props[1, ] = c(1.0, 0.0, 0.0, 0.0, 0.0)  # All in SC1
```

**Example `size_props` (1-year retention, some growth):**
```R
size_props[2, ] = c(0.7, 0.25, 0.05, 0.0, 0.0)  # Most SC1, some SC2-3
```

#### 5.2.4 Restoration Strategy Parameters

| Parameter | Dimensions | Description | Range |
|-----------|------------|-------------|-------|
| `tile_props` | Named list by tile | Lab space allocation | Sums to 1.0 |
| `orchard_yield` | Scalar | Fraction of orchard larvae collected | 0–1 |
| `reef_yield` | Scalar | Fraction of reference reef larvae collected | 0–0.01 |
| `reef_prop` | `[treatment]` | Fraction outplanted to reef (vs. orchard) | 0–1 |
| `reef_out_props` | `[treatment, reef]` | Distribution across reefs | Rows sum to 1 |
| `orchard_out_props` | `[treatment, orchard]` | Distribution across orchards | Rows sum to 1 |
| `reef_areas` | `[reef]` | Carrying capacity (cm²) | 10⁵–10⁷ |
| `lab_max` | Scalar | Max larvae processed per year | 10³–10⁵ |
| `lab_retain_max` | Scalar | Max retained for 1 year | 10³–10⁴ |
| `orchard_size` | `[orchard]` | Max colonies per orchard | 100–10,000 |
| `transplant` | `[year]` | Binary: transplant event? | 0 or 1 |
| `trans_mats` | `[orchard][source][year, SC]` | Number to transplant | Integers |
| `trans_reef` | `[orchard][source][year, c(reef, src)]` | Destination | Integers |

#### 5.2.5 Stochasticity Parameters

| Parameter | Description | Typical Range |
|-----------|-------------|---------------|
| `sigma_s` | SD of log-survival stochasticity | 0–0.5 |
| `sigma_f` | SD of log-fecundity stochasticity | 0–0.5 |
| `ext_rand` | `c(reef_recruitment, ref_reef_larvae)` | TRUE/FALSE |
| `seeds` | `c(surv_seed, fec_seed, ext_seed, ref_seed)` | Any integer |

**Stochastic Formulation:**
```
S_i,t = surv_pars[i] × exp(ε_t)  where ε_t ~ N(0, σ_s)
F_i,t = fec_pars[i] × exp(ε_t)   where ε_t ~ N(0, σ_f)
```

---

## 6. MODEL OUTPUTS

### 6.1 Primary Output Structure

The main function `rse_mod1()` returns a list with these components:

```R
list(
  reef_pops = list,         # Population sizes
  orchard_pops = list,      # Population sizes
  lab_pops = list,          # Retained settlers
  reef_rep = list,          # Reproductive output
  orchard_rep = list,       # Reproductive output
  reef_out = list,          # Outplanting events
  orchard_out = list,       # Outplanting events
  reef_pops_pre = list,     # Pre-outplanting populations
  orchard_pops_pre = list   # Pre-outplanting populations
)
```

**Dimensions:**

| Output | Structure | Interpretation |
|--------|-----------|----------------|
| `reef_pops[[reef]][[source]]` | `[size_class, year]` | Population matrix after outplanting |
| `reef_pops_pre[[reef]][[source]]` | `[size_class, year]` | Population matrix before outplanting |
| `orchard_pops[[orchard]][[source]]` | `[size_class, year]` | Population matrix after outplanting |
| `orchard_pops_pre[[orchard]][[source]]` | `[size_class, year]` | Population matrix before outplanting |
| `lab_pops[[treatment]]` | `[year]` | Number of settlers retained |
| `reef_rep[[reef]][[source]]` | `[year]` | Total larvae produced |
| `orchard_rep[[orchard]][[source]]` | `[year]` | Total larvae produced |
| `reef_out[[reef]][[source]]` | `[year]` | Number outplanted this year |
| `orchard_out[[orchard]][[source]]` | `[year]` | Number outplanted this year |

### 6.2 Derived Metrics (via `model_summ()`)

**Function:** `model_summ(model_sim, location, metric, n_reef, n_orchard, n_lab)`

**Metrics Available:**

1. **`metric = "ind"`** — Total Individuals
   ```
   For each year: Σ(all sources, all size classes) N[i,t]
   Units: Number of colonies
   ```

2. **`metric = "area_m2"`** — Coral Cover
   ```
   For each year: Σ(all sources, all size classes) N[i,t] × A_mids[i] / 10,000
   Units: m²
   ```

3. **`metric = "production"`** — Larval Production
   ```
   For each year: Σ(all sources) total_larvae_produced[t]
   Units: Number of larvae
   ```

**Example Usage:**
```R
reef_total <- model_summ(sim1, location = "reef", metric = "ind",
                         n_reef = 1, n_orchard = 1, n_lab = 2)
# Returns: vector [years] with total reef population each year

reef_cover <- model_summ(sim1, location = "reef", metric = "area_m2",
                         n_reef = 1, n_orchard = 1, n_lab = 2)
# Returns: vector [years] with total coral cover (m²) each year
```

### 6.3 Population Growth Rate (λ)

**Function:** `pop_lambda_fun(surv_pars, growth_pars, shrink_pars, frag_pars)`

**Calculation:**
```R
# Construct projection matrix
T_mat <- G_fun(years=1, n=5, growth_pars, shrink_pars, frag_pars)$G_list[[1]]
F_mat <- G_fun(...)$Fr_list[[1]]
S_mat <- diag(surv_pars)

A <- S_mat %*% (T_mat + F_mat)

# Calculate leading eigenvalue
lambda <- Re(eigen(A)$values[1])
```

**Interpretation:**
- λ > 1: Population growing exponentially
- λ = 1: Population stable
- λ < 1: Population declining toward extinction

**Use Case:** Compare population growth rates under different parameter scenarios (optimistic vs. pessimistic demographic rates)

---

## 7. BIOLOGICAL & ECOLOGICAL ASSUMPTIONS

### 7.1 Core Assumptions

| Assumption | Justification | Potential Violations |
|------------|---------------|---------------------|
| **Size-based demography** | Coral vital rates depend on colony size, not age | Age may matter in early life stages |
| **Discrete size classes** | Simplifies continuous size distribution | Loses within-class variation |
| **Annual timesteps** | Matches spawning cycle of *A. palmata* | Sub-annual dynamics ignored |
| **Deterministic transitions** | Mean-field approximation | Individual variability in growth |
| **No Allee effects** | Small populations can grow | Fertilization may fail at low density |
| **No genetic structure** | All corals within source are identical | Genetic diversity affects fitness |
| **Homogeneous environment** | All corals at a location experience same conditions | Spatial heterogeneity in reef |
| **No disease dynamics** | Disease affects survival but not explicitly modeled | Epidemics can cause mass mortality |
| **Fixed carrying capacity** | Space limitation constant over time | Climate change may alter habitat |
| **No competition** | Space constraint is only limiting factor | Competition for light, nutrients |

### 7.2 Size Class Transition Rules

**Growth:**
- Corals can only grow to the **next larger size class** or stay in current class
- No skipping size classes (e.g., SC1 cannot jump to SC3)
- **Biological basis:** Growth rates constrain maximum annual change

**Shrinkage:**
- Corals can shrink to **any smaller size class**
- Represents partial mortality (tissue loss, breakage)
- **Biological basis:** Storms, disease, predation can cause large tissue loss

**Fragmentation:**
- Only SC4 and SC5 can fragment
- Fragments can be **any size class ≤ parent size**
- **Biological basis:** Large colonies break in storms, creating multiple smaller colonies

**Stasis:**
- Probability of staying in same size class = `1 - Σ(growth) - Σ(shrinkage)`
- **Biological basis:** Not all corals grow or shrink every year

### 7.3 Reproduction Assumptions

**Sexual Reproduction:**
- Only SC3+ produce significant larvae
- Fecundity scales with size class (SC5 >> SC3)
- **Biological basis:** Larger colonies have more polyps, higher gamete production

**Fertilization:**
- External fertilization implicit in `reef_yield` parameter
- No explicit mating dynamics
- **Biological basis:** Broadcast spawning with variable fertilization success

**Larval Dispersal:**
- External recruitment comes from distant sources (λ)
- No self-recruitment from restoration reef to itself
- **Biological basis:** Most larvae disperse away from natal reef

**Settlement:**
- Larvae settle as SC1 (smallest size class)
- Settlement success varies by substrate (`sett_props`)
- **Biological basis:** Substrate type affects larval attachment and early survival

### 7.4 Density Dependence

**Reef:**
- Space limitation enforced at population level (hard carrying capacity)
- No density-dependent survival by default (`dens_pars.r = 0`)
- **Could be activated:** Set `dens_pars.r > 0` for exponential mortality at high density

**Orchard:**
- Colony-count limit (`orchard_size`)
- No density-dependent survival by default

**Lab:**
- **Active density dependence** via `m0` and `m1`
- Survival = `s × exp(-m × N)`
- **Biological basis:** Crowding increases disease, reduces food availability

### 7.5 Environmental Stochasticity

**Survival:**
```
S_i,t = surv_pars[i] × exp(ε_t)  where ε_t ~ N(0, σ_s)
```
- Represents year-to-year variation in environmental conditions
- Affects all size classes simultaneously (environmental correlation)

**Fecundity:**
```
F_i,t = fec_pars[i] × exp(ε_t)  where ε_t ~ N(0, σ_f)
```
- Represents variation in spawning success, larval quality

**Recruitment:**
```
If ext_rand = TRUE: recruits ~ Poisson(λ)
```
- Represents stochastic larval supply

**Disturbances:**
- Discrete events (hurricanes, bleaching) in specified years
- Can affect survival, growth, fragmentation, or fecundity
- **Example:** Hurricane reduces survival to 0.1× baseline

---

## 8. CODE ARCHITECTURE & KEY FUNCTIONS

### 8.1 File Organization

```
Detmer-2025-coral-RSE/
├── coral_demographic_funs.R    # Demographic rate generation functions
│   ├── Surv_fun()             # Stochastic survival
│   ├── G_fun()                # Transition & fragmentation matrices
│   ├── Rep_fun()              # Stochastic fecundity
│   └── Ext_fun()              # External recruitment
│
├── rse_funs.R                 # Main model & parameter functions
│   ├── mat_pars_fun()         # Generate all matrices for simulation
│   ├── dist_pars_fun()        # Organize disturbance parameters
│   ├── par_list_fun()         # Convert data to parameter lists
│   ├── default_pars_fun()     # Mean parameter values
│   ├── rand_pars_fun()        # Random parameter sampling
│   ├── pop_lambda_fun()       # Calculate population growth rate
│   ├── model_summ()           # Post-process model outputs
│   ├── rse_mod1()             # Main simulation function (simplified)
│   └── rse_mod()              # Full simulation function (advanced)
│
├── model_description.Rmd       # Tutorial & examples
├── docs/
│   └── model_summary.md        # Existing component summary
└── figures/
    └── model_documentation.html # Existing interactive documentation
```

### 8.2 Core Function Specifications

#### 8.2.1 `Surv_fun()`
**Location:** `coral_demographic_funs.R:13`

**Purpose:** Generate stochastic survival probabilities for all years

**Inputs:**
- `years`: Number of simulation years
- `n`: Number of size classes (always 5)
- `surv_pars`: Mean survival probabilities `[5]`
- `sigma_s`: SD of log-normal errors
- `seed1`: Random seed for reproducibility

**Output:**
- `S_list`: List of length `years`, each element is vector `[5]` of survival probabilities

**Algorithm:**
```R
1. Generate errors: ε[t] ~ N(0, σ_s) for t=1..years
2. For each year t:
   S[i,t] = surv_pars[i] × exp(ε[t])
   If S[i,t] > 1: S[i,t] = 1  (cap at 100%)
3. Return S_list[[t]] for all t
```

---

#### 8.2.2 `G_fun()`
**Location:** `coral_demographic_funs.R:54`

**Purpose:** Construct transition and fragmentation matrices

**Inputs:**
- `years`: Number of simulation years
- `n`: Number of size classes
- `growth_pars`: List `[[SC]]` where each element is vector of growth probabilities
- `shrink_pars`: List `[[SC]]` where each element is vector of shrinkage probabilities
- `frag_pars`: List `[[SC]]` where each element is vector of fragmentation probabilities

**Outputs:**
- `G_list`: Transition matrices `[n × n]` for each year
- `Fr_list`: Fragmentation matrices `[n × n]` for each year

**Algorithm:**
```R
For each year t:
  Initialize T_mat[n, n] = NA
  Initialize F_mat[n, n] = 0

  For each column c (source size class):
    If c = 1:  # Smallest class, only growth
      T_mat[(c+1):n, c] = growth_pars[[c]]
    Else if c = n:  # Largest class, only shrinkage
      T_mat[1:(c-1), c] = shrink_pars[[c]]
    Else:  # Middle classes, growth and shrinkage
      T_mat[(c+1):n, c] = growth_pars[[c]]  # Above diagonal
      T_mat[1:(c-1), c] = shrink_pars[[c]]  # Below diagonal

    # Diagonal = stasis
    T_mat[c, c] = 1 - sum(T_mat[, c], na.rm=TRUE)

    # Fragmentation (SC2+ can fragment)
    If c >= 2:
      F_mat[1:c, c] = frag_pars[[c]]

  G_list[[t]] = T_mat
  Fr_list[[t]] = F_mat

Return list(G_list, Fr_list)
```

**Critical Detail:** Columns sum to 1 for T_mat (probabilities), but F_mat columns can exceed 1 (asexual reproduction).

---

#### 8.2.3 `rse_mod1()`
**Location:** `rse_funs.R:553`

**Purpose:** Main simulation engine

**Inputs:** (Extensive - see Parameter Structure section)

**Output:** List with `reef_pops`, `orchard_pops`, `lab_pops`, etc.

**High-Level Algorithm:**
```R
# Initialization
1. Generate external recruitment time series: ext_rec[t], ref_babies[t]
2. Initialize holding lists for reef, orchard, lab populations
3. For each location and source:
   - Create population matrices [n × years]
   - Generate demographic parameters using mat_pars_fun()
   - Set initial conditions N0

# Main temporal loop
For i in 2:years:

  # REEF DYNAMICS
  For each reef and source:
    - Apply survival: N_tmp = N[i-1] × S[i]
    - Apply growth/fragmentation: N[i] = (T + F) × N_tmp
    - Record pre-outplant state: N_pre[i] = N[i]
    - Calculate reproduction: rep[i] = N[i] ⋅ fec[i]
    - Add external recruits (source 1 only): N[1,i] += ext_rec[i]

  # ORCHARD DYNAMICS
  For each orchard and source:
    - Apply survival: N_tmp = N[i-1] × S[i]
    - Apply growth (no fragmentation): N[i] = T × N_tmp
    - Record pre-outplant state: N_pre[i] = N[i]
    - Calculate reproduction: rep[i] = N[i] ⋅ fec[i]

  # LARVAE COLLECTION
  - Collect from orchard: new_babies.o = Σ(orchard_rep) × orchard_yield
  - Collect from reference reefs: new_babies.r = ref_babies[i] × reef_yield
  - Total available: tot_babies = min(sum, lab_max)
  - Allocate to immediate vs. 1-year: tot_settlers1, tot_settlers0

  # LAB PROCESSING
  For each lab treatment:
    - Calculate settlers on tile: settlers = total × sett_props × tile_props
    - If immediate (0_TX):
        out_settlers = settlers × s0 × exp(-m0 × settlers)
    - If 1-year (1_TX):
        lab_pops[i] = settlers × s1 × exp(-m1 × settlers)

  # OUTPLANTING
  For each lab treatment:
    - Calculate reef outplants: reef_out = (current + previous) × reef_prop
    - Calculate orchard outplants: orch_out = (current + previous) × (1 - reef_prop)

  # SPACE CONSTRAINTS
  For each reef:
    - Calculate occupied area: Σ(N × A_mids)
    - If occupied ≥ capacity: prop_fits = 0
    - Else: prop_fits = 1
    - Apply to outplants: reef_out *= prop_fits

  For each orchard:
    - Calculate total colonies: Σ(N)
    - If total ≥ capacity: calculate partial acceptance

  # ADD OUTPLANTS TO POPULATIONS
  For each reef and source:
    - N[i] += outplants × size_props[treatment,]
  For each orchard and source:
    - N[i] += outplants × size_props[treatment,]

  # TRANSPLANTING (if scheduled)
  If transplant[i] = 1:
    - Move colonies from orchard to reef per trans_mats
    - Update both populations

# Return outputs
Return list(reef_pops, orchard_pops, lab_pops, reef_rep, orchard_rep,
            reef_out, orchard_out, reef_pops_pre, orchard_pops_pre)
```

---

#### 8.2.4 `model_summ()`
**Location:** `rse_funs.R` (approx. line 1800+)

**Purpose:** Extract summary metrics from model output

**Inputs:**
- `model_sim`: Output from `rse_mod1()` or `rse_mod()`
- `location`: "reef" or "orchard"
- `metric`: "ind", "area_m2", or "production"
- `n_reef`, `n_orchard`, `n_lab`: Dimensions of simulation

**Output:**
- Vector `[years]` with requested metric at each timepoint

**Algorithm:**
```R
If metric = "ind":
  For each year t:
    total[t] = Σ(all reefs, all sources, all size classes) N[i,t]

If metric = "area_m2":
  For each year t:
    total[t] = Σ(all reefs, sources, size classes) N[i,t] × A_mids[i] / 10000

If metric = "production":
  For each year t:
    total[t] = Σ(all reefs, all sources) reproductive_output[t]

Return total
```

---

## 9. VISUALIZATION REQUIREMENTS

### 9.1 Conceptual Flow Diagram

**Objective:** Show the movement of corals and larvae through the system

**Components to Illustrate:**

1. **Compartments** (boxes):
   - EXTERNAL (wild reefs)
   - LAB (with tile types and timing treatments visible)
   - ORCHARD (nursery)
   - REEF (restoration target)

2. **Flows** (arrows):
   - Larvae from external → LAB
   - Larvae from ORCHARD → LAB
   - Lab outplants → REEF
   - Lab outplants → ORCHARD
   - Transplants: ORCHARD → REEF
   - (Optional) Larvae from REEF → LAB

3. **Within-Compartment Processes** (nested elements):
   - **REEF/ORCHARD:**
     - Size class progression (SC1 → SC2 → SC3 → SC4 → SC5)
     - Shrinkage arrows (reverse direction)
     - Fragmentation (SC4/SC5 → smaller classes)
   - **LAB:**
     - Tile types (T1, T2)
     - Timing tracks (0_TX immediate, 1_TX 1-year)

4. **Feedback Loops:**
   - ORCHARD reproduction feeding back to LAB
   - Outplants from LAB growing in ORCHARD, then producing more larvae

5. **Constraints** (visual indicators):
   - LAB: `lab_max`, `lab_retain_max` capacity gauges
   - ORCHARD: `orchard_size` capacity
   - REEF: `reef_areas` carrying capacity

**Visual Style Recommendations:**
- **Color coding:**
  - EXTERNAL: Green (natural)
  - LAB: Blue (controlled, scientific)
  - ORCHARD: Teal (intermediate)
  - REEF: Coral/orange (restoration target)
- **Arrow types:**
  - Solid: Material flow (corals, larvae)
  - Dashed: Optional flows (can be toggled off)
  - Thick: High-volume pathways
- **Annotations:**
  - Parameter names next to flows (e.g., "orchard_yield" on arrow)
  - Size class numbers within boxes

---

### 9.2 Population Projection Matrix Diagram

**Objective:** Visualize the mathematical structure of the transition matrix

**Elements:**

1. **Transition Matrix (T):**
   - 5×5 grid
   - Color-code cells:
     - Diagonal: Gray (stasis)
     - Above diagonal: Green (growth)
     - Below diagonal: Orange (shrinkage)
   - Annotate with parameter names: `growth_pars[[SC]]`, `shrink_pars[[SC]]`

2. **Fragmentation Matrix (F):**
   - 5×5 grid
   - Only SC4 and SC5 columns non-zero
   - Color intensity by probability magnitude

3. **Survival Matrix (S):**
   - Diagonal matrix visualization
   - Show as bar chart alongside matrices

4. **Combined Matrix (A = S · (T + F)):**
   - Show final projection matrix
   - Highlight dominant eigenvalue (λ) calculation

**Interactive Features:**
- Hover over cells to see probability values
- Click to see biological interpretation (e.g., "Probability SC3 grows to SC4")

---

### 9.3 Annual Cycle Timeline

**Objective:** Show the sequence of events within a model year

**Format:** Horizontal timeline with steps

```
Year i
│
├─ STEP 1: Survival & Growth (Reef) ──────────────┐
│                                                  │
├─ STEP 2: Survival & Growth (Orchard) ───────────┤
│                                                  │ Parallel
├─ STEP 3: Reproduction (all locations) ──────────┤ operations
│                                                  │
├─ STEP 4: Larvae Collection ─────────────────────┘
│
├─ STEP 5: Lab Settlement & Survival
│    ├─ Immediate outplants (0_TX)
│    └─ 1-year retention (1_TX)
│
├─ STEP 6: Outplanting Allocation
│    ├─ Reef proportions
│    └─ Orchard proportions
│
├─ STEP 7: Space Constraints Check
│    ├─ Reef capacity enforcement
│    └─ Orchard capacity enforcement
│
├─ STEP 8: Add Outplants to Populations
│
└─ STEP 9: Transplanting (if scheduled)
   │
   └─ Year i+1 begins
```

**Visual Enhancements:**
- Color-code steps by compartment affected
- Show decision points (if/else logic)
- Indicate where parameters are used

---

### 9.4 Parameter Dashboard

**Objective:** Interactive interface for exploring parameter space

**Sections:**

1. **Demographic Rates:**
   - Sliders for survival (SC1-SC5)
   - Growth/shrinkage probability visualizations
   - Fragmentation rate controls

2. **Lab Configuration:**
   - Tile type settings (sett_props)
   - Survival rates (s0, s1)
   - Density dependence (m0, m1)

3. **Restoration Strategy:**
   - Lab capacity (lab_max, lab_retain_max)
   - Orchard yield
   - Outplanting proportions (reef_prop)

4. **Carrying Capacities:**
   - Reef areas (m²)
   - Orchard size (# colonies)

5. **Disturbances:**
   - Year selector
   - Effect type (survival, growth, fragmentation)
   - Magnitude (% reduction)

**Output Display:**
- Real-time population trajectory plot
- Population growth rate (λ)
- Final coral cover (m²)

---

### 9.5 Sensitivity Analysis Visualization

**Objective:** Show how outputs respond to parameter changes

**Plot Types:**

1. **Tornado Diagram:**
   - Horizontal bars showing sensitivity of λ to each parameter
   - Rank parameters by influence

2. **2D Parameter Space:**
   - Heatmap: λ as function of two parameters (e.g., survival × growth)
   - Contour lines for λ = 1 (stability threshold)

3. **Time Series Ensemble:**
   - Spaghetti plot: 100+ simulation runs with random parameter sampling
   - Highlight median and 90% confidence interval

---

## 10. USE CASES & RESEARCH QUESTIONS

### 10.1 Management Questions Addressable by Model

1. **Lab Treatment Optimization:**
   - *Question:* Which tile type (T1 vs. T2) × timing (immediate vs. 1-year) combination maximizes reef population growth?
   - *Approach:* Run simulations with different `lab_treatments`, compare final coral cover

2. **Orchard Value Assessment:**
   - *Question:* Does investing in an orchard improve restoration outcomes compared to relying solely on reference reef larvae?
   - *Approach:* Compare scenarios with `orchard_yield = 0` (no orchard) vs. `orchard_yield = 0.5`

3. **Capacity Bottlenecks:**
   - *Question:* Is lab capacity (`lab_max`) or reef space (`reef_areas`) the limiting factor?
   - *Approach:* Sequentially increase each constraint, measure response

4. **Transplant Timing:**
   - *Question:* When should large orchard colonies be transplanted to maximize reef reproduction?
   - *Approach:* Vary `transplant` year, measure cumulative larval production

5. **Disturbance Resilience:**
   - *Question:* Can restoration populations recover from hurricanes with 90% mortality?
   - *Approach:* Add `dist_yrs` with low survival, measure time to pre-disturbance levels

6. **Cost-Effectiveness:**
   - *Question:* What is the optimal allocation of resources between lab capacity, orchard size, and reef area?
   - *Approach:* Assign costs to each constraint, solve optimization problem (external to model)

---

### 10.2 Biological Hypotheses Testable

1. **Fragmentation Contribution:**
   - *Hypothesis:* Asexual reproduction (fragmentation) is essential for population persistence
   - *Test:* Compare λ with `frag_pars = 0` vs. empirical fragmentation rates

2. **Size Structure Importance:**
   - *Hypothesis:* Maintaining large colonies (SC5) is critical for fecundity
   - *Test:* Simulate selective mortality of SC5 (disturbance targeting large corals)

3. **Density Dependence:**
   - *Hypothesis:* Lab density-dependent mortality (`m1`) limits restoration scalability
   - *Test:* Vary `m1` from 0 (no density dependence) to 0.05, measure total outplants

4. **Source Provenance:**
   - *Hypothesis:* Lab-reared corals perform worse than wild recruits due to reduced genetic diversity
   - *Test:* Assign lower survival/growth to lab sources, compare outcomes

5. **Temporal Environmental Variation:**
   - *Hypothesis:* Stochasticity in survival (`sigma_s`) increases extinction risk even when mean λ > 1
   - *Test:* Monte Carlo simulations with increasing `sigma_s`, measure extinction probability

---

## 11. LIMITATIONS & FUTURE EXTENSIONS

### 11.1 Current Limitations

| Limitation | Impact | Potential Solution |
|------------|--------|-------------------|
| **No spatial structure** | Cannot model larval dispersal networks | Implement metapopulation framework |
| **No genetic diversity** | Cannot assess inbreeding depression | Add genotype tracking, fitness costs |
| **No species interactions** | Ignores competition, facilitation | Multi-species model with interactions |
| **Deterministic growth** | Underestimates variance in outcomes | Add individual-based stochasticity |
| **Fixed parameters** | Ignores climate change, adaptation | Implement time-varying parameters |
| **No explicit nutrients** | Cannot model eutrophication effects | Add resource dynamics |
| **Annual timesteps** | Cannot capture sub-annual events | Implement seasonal time steps |
| **Homogeneous mortality** | All individuals in size class identical | Size-continuous model (integral projection) |

### 11.2 Potential Extensions

1. **Climate Change Module:**
   - Temperature-dependent survival/growth
   - Bleaching events triggered by degree heating weeks
   - Adaptive capacity via genetic parameters

2. **Economic Module:**
   - Costs: Lab operations, orchard maintenance, transplanting
   - Benefits: Ecosystem services (fisheries, tourism)
   - Optimization: Maximize benefit/cost ratio

3. **Multi-Species:**
   - Add herbivores (urchins, parrotfish) affecting algal competition
   - Add corallivores (snails, starfish) causing mortality
   - Food web dynamics

4. **Individual-Based Model (IBM):**
   - Track each coral colony with unique traits
   - Genetic pedigrees, relatedness
   - Fine-scale spatial competition

5. **Machine Learning Integration:**
   - Use model as simulator for training reinforcement learning agents
   - Optimize restoration strategies via deep Q-learning

6. **Uncertainty Quantification:**
   - Bayesian parameter estimation from field data
   - Posterior predictive distributions for forecasts
   - Sensitivity analysis via Sobol indices

---

## 12. GLOSSARY OF TERMS

| Term | Definition |
|------|------------|
| **Asexual reproduction** | Creation of new individuals without fertilization (fragmentation in corals) |
| **Carrying capacity** | Maximum population size sustainable by available resources/space |
| **Demographic stochasticity** | Random variation in individual survival/reproduction |
| **Density dependence** | Vital rates affected by population density |
| **Environmental stochasticity** | Random variation in environmental conditions affecting all individuals |
| **Fecundity** | Number of offspring (larvae) produced per individual |
| **Fragmentation** | Colony breakage creating multiple smaller colonies |
| **Leslie matrix** | Age/stage-structured population projection matrix |
| **Outplanting** | Transfer of lab-reared corals to reef or orchard |
| **Planar area** | Two-dimensional surface area of coral colony viewed from above |
| **Population growth rate (λ)** | Leading eigenvalue of projection matrix; λ>1 = growth |
| **Provenance** | Origin/source of coral (wild vs. lab treatment) |
| **Shrinkage** | Reduction in colony size due to partial mortality |
| **Size class** | Discrete category grouping corals by colony area |
| **Stasis** | Remaining in same size class between timesteps |
| **Transition matrix** | Matrix encoding probabilities of moving between size classes |

---

## 13. PARAMETER QUICK REFERENCE

**Minimum Required Parameters for Basic Simulation:**

```R
# Dimensions
years = 20
n = 5  # size classes
A_mids = c(5, 55, 500, 2450, 9325)  # midpoint areas (cm²)

# Treatments
reef_treatments = c("reef1")
orchard_treatments = c("orchard1")
lab_treatments = c("0_T1", "1_T2")  # Example: immediate cement, 1-year ceramic

# Demographic parameters (use default_pars_fun() to generate)
surv_pars.r, growth_pars.r, shrink_pars.r, frag_pars.r, fec_pars.r
surv_pars.o, growth_pars.o, shrink_pars.o, frag_pars.o, fec_pars.o
dens_pars.r, dens_pars.o  # Usually set to 0

# Lab parameters
lab_pars = list(
  s0 = c(0.9, 0.9),  # Survival: immediate outplanting
  s1 = c(0.7, 0.7),  # Survival: 1-year retention
  m0 = c(0, 0),      # Density dependence: immediate
  m1 = c(0, 0),      # Density dependence: 1-year
  sett_props = list(T1 = 0.95, T2 = 0.90),  # Settlement by tile
  size_props = matrix(c(1,0,0,0,0, 0.7,0.3,0,0,0), nrow=2, byrow=TRUE)
)

# Restoration strategy
rest_pars = list(
  tile_props = list(T1 = 0.5, T2 = 0.5),
  orchard_yield = 0.5,
  reef_yield = 0.001,
  reef_prop = c(0.75, 0.75),
  reef_out_props = matrix(1, nrow=2, ncol=1),
  orchard_out_props = matrix(1, nrow=2, ncol=1),
  reef_areas = c(80000 * 10000),  # 8 hectares in cm²
  lab_max = 40000,
  lab_retain_max = 12000,
  orchard_size = c(2400),
  transplant = rep(0, years),  # No transplanting
  trans_mats = list(list(matrix(0, nrow=years, ncol=5),
                         matrix(0, nrow=years, ncol=5))),
  trans_reef = list(list(matrix(c(1,2), nrow=years, ncol=2, byrow=TRUE),
                         matrix(c(1,3), nrow=years, ncol=2, byrow=TRUE)))
)

# External recruitment
lambda = 0  # Wild recruitment to reef
lambda_R = 10000  # Reference reef larvae

# Stochasticity
sigma_s = 0  # Survival stochasticity
sigma_f = 0  # Fecundity stochasticity
ext_rand = c(FALSE, FALSE)  # Deterministic recruitment
seeds = c(1000, 5000, 10000, 40000)

# Initial conditions
N0.r = list(list(rep(0,5), rep(0,5), rep(0,5)))  # Reef starts empty
N0.o = list(list(rep(0,5), rep(0,5)))  # Orchard starts empty
N0.l = list(0, 0)  # Lab starts empty

# Disturbances
dist_yrs = NA  # No disturbances
dist_effects.r = list(list(list(c("none")), list(c("none")), list(c("none"))))
dist_effects.o = list(list(list(c("none")), list(c("none"))))
dist_pars.r = list(list(
  dist_pars_fun(dist_yrs, dist_effects.r[[1]][[1]], NULL, NULL, NULL, NULL),
  dist_pars_fun(dist_yrs, dist_effects.r[[1]][[2]], NULL, NULL, NULL, NULL),
  dist_pars_fun(dist_yrs, dist_effects.r[[1]][[3]], NULL, NULL, NULL, NULL)
))
dist_pars.o = list(list(
  dist_pars_fun(dist_yrs, dist_effects.o[[1]][[1]], NULL, NULL, NULL, NULL),
  dist_pars_fun(dist_yrs, dist_effects.o[[1]][[2]], NULL, NULL, NULL, NULL)
))
```

---

## 14. RECOMMENDED CITATION

*When using this model, please cite:*

Detmer, R.E., Stier, A.C., et al. (2025). "Stage-structured population dynamics model for evaluating coral restoration strategies integrating lab rearing, nursery cultivation, and field outplanting." *[Journal TBD]*.

*Model code available at:* https://github.com/[repository]

---

## 15. CONTACT & SUPPORT

**Model Development Team:**
- Raine Detmer (lead developer): [email]
- Adrian Stier (ecological advisor): [email]

**Bug Reports:** Submit issues at [GitHub repository]

**Documentation Questions:** See `model_description.Rmd` for worked examples

---

**END OF SPECIFICATION**

---

## Appendix A: Size Class Transition Example

**Scenario:** A coral currently in SC3 (100-900 cm²) with area 400 cm²

**Possible Fates in One Year:**

| Outcome | Probability | New Size Class | Mechanism |
|---------|-------------|----------------|-----------|
| Die | 1 - s₃ | None | Mortality |
| Shrink to SC2 | s₃ × shrink_pars[[3]][1] | SC2 | Partial mortality |
| Shrink to SC1 | s₃ × shrink_pars[[3]][2] | SC1 | Severe partial mortality |
| Stay SC3 | s₃ × T₃₃ | SC3 | Stasis |
| Grow to SC4 | s₃ × growth_pars[[3]][1] | SC4 | Tissue growth |
| Grow to SC5 | s₃ × growth_pars[[3]][2] | SC5 | Rapid growth (rare) |

**Example Values:**
```
s₃ = 0.8
shrink_pars[[3]] = c(0.02, 0.01)  # 2% → SC2, 1% → SC1
growth_pars[[3]] = c(0.15, 0.02)  # 15% → SC4, 2% → SC5
T₃₃ = 1 - 0.02 - 0.01 - 0.15 - 0.02 = 0.80  # 80% stay in SC3

Survival to next year: 80%
If survives:
  - 2.5% shrink to SC2
  - 1.25% shrink to SC1
  - 18.75% grow to SC4
  - 2.5% grow to SC5
  - 75% stay SC3
```

---

## Appendix B: Fragmentation Example

**Scenario:** 10 colonies in SC5 (>4,000 cm²) experience storm fragmentation

**Fragmentation Parameters:**
```
frag_pars[[5]] = c(0.05, 0.10, 0.15, 0.20, 0.10)
```
Interpretation: Each SC5 colony produces (on average):
- 0.05 fragments landing in SC1
- 0.10 fragments landing in SC2
- 0.15 fragments landing in SC3
- 0.20 fragments landing in SC4
- 0.10 fragments remaining in SC5 (splits into two large pieces)

**Population Outcome:**
```
Before fragmentation: N₅ = 10
After fragmentation:
  N₁ += 10 × 0.05 = 0.5 new recruits
  N₂ += 10 × 0.10 = 1.0 new juveniles
  N₃ += 10 × 0.15 = 1.5 new juveniles
  N₄ += 10 × 0.20 = 2.0 new subadults
  N₅ += 10 × 0.10 = 1.0 additional adults

Original 10 colonies still survive (F adds to, not replaces, N)
Total population increased by 6 individuals via fragmentation
```

**Biological Note:** Fragmentation is **additional** to normal growth/shrinkage transitions, representing asexual reproduction that increases total population size.

---

*This specification provides a complete foundation for creating visual documentation, interactive tools, and educational materials about the coral restoration model. All mathematical formulations, biological assumptions, and code structures are explicitly documented.*

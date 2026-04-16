# Postdoc Code Context Improvements — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add documentation to the R codebase so a new postdoc can understand and extend the coral RSE model without reverse-engineering parameter structures or code logic.

**Architecture:** Two phases. Phase A (Tasks 1–3) documents the two critical parameter structures (`rest_pars`, `lab_pars`) and restructures `model_description.Rmd` into a usable walkthrough. Phase B (Tasks 4–7) adds roxygen to undocumented functions, documents magic numbers, and documents the fragmentation biology assumption. All documentation written in Stier writing voice ("we" throughout, active voice, explain WHY not just what, authoritative but measured, no filler).

**Tech Stack:** R, roxygen2-style documentation, Rmd (R Markdown)

**Voice rules (apply to every task):**
- Use "we" — never "I" or "the user"
- Active voice for all framing. Passive only for methods convention ("survival was estimated from...")
- Explain ecological rationale (WHY), not just code mechanics (WHAT)
- One hedge per uncertain claim max. If confident, sound confident.
- No filler words: "novel," "groundbreaking," "importantly," "it should be noted"
- Plain language before and after formalism — narrate model behavior, don't let code stand alone

---

## Phase A: Targeted (unblock the postdoc)

### Task 1: Document `rest_pars` and `lab_pars` structures in rse_funs.R

**Files:**
- Modify: `rse_funs.R:597-604` (existing `@param` lines for `lab_pars` and `rest_pars`)

The `rest_pars` and `lab_pars` lists drive the entire restoration simulation. A postdoc trying to set up a new scenario must currently reverse-engineer their structures from analysis notebooks. We document them inline where they are consumed — in the `rse_mod1()` roxygen block.

- [ ] **Step 1: Read the current `@param` lines for `rest_pars` and `lab_pars`**

Confirm the existing one-liners at `rse_funs.R:600-601`:
```
#' @param lab_pars parameters with lab yields for the different lab treatments
#' @param rest_pars restoration strategy parameters for determining how many recruits go to each treatment lab, reef, and orchard
```

- [ ] **Step 2: Replace the `@param rest_pars` line with a structured description**

Replace the single `@param rest_pars` line (line 601) with:

```r
#' @param rest_pars Named list defining the restoration strategy. Controls how larvae
#'   are allocated across labs, orchards, and reefs each year. Elements:
#'   \describe{
#'     \item{tile_props}{Named list (e.g., \code{list(T1 = 0.25, T2 = 0.75)}). Fraction
#'       of lab tile capacity devoted to each tile type. Names must match tile types in
#'       \code{lab_treatments}. Sums to 1.}
#'     \item{orchard_yield}{Numeric 0–1. Fraction of orchard larvae successfully collected
#'       each spawning season. Set to 0 if the orchard does not contribute larvae to the lab.}
#'     \item{reef_yield}{Numeric 0–1. Fraction of reference reef larvae successfully collected
#'       and fertilized. Represents field collection efficiency.}
#'     \item{spawn_target}{Numeric. Target number of embryos to collect from the orchard each
#'       year. If the orchard cannot meet this target, the shortfall is supplemented from the
#'       reference reef (up to \code{reef_yield * lambda_R}). Set to 0 for no lab settlers.}
#'     \item{reef_prop}{Numeric vector (length = number of lab treatments), each value 0–1.
#'       Fraction of tiles from each lab treatment that go to the reef (remainder goes to orchards).}
#'     \item{reef_out_props}{Matrix (n_lab x n_reef). Row i, column j = fraction of reef-bound
#'       tiles from lab treatment i allocated to reef j. Rows sum to 1.}
#'     \item{orchard_out_props}{Matrix (n_lab x n_orchard). Same logic for orchard allocation.}
#'     \item{reef_areas}{Numeric vector (length = n_reef). Available substrate area for each
#'       reef in cm^2. Determines carrying capacity — once occupied area reaches this limit,
#'       no new recruits or fragments establish.}
#'     \item{lab_max}{Integer. Total tile capacity of the lab (tiles that can be processed
#'       in a single spawning season). We assume 100 tiles per tank.}
#'     \item{lab_retain_max}{Integer. Maximum tiles that can be held in the lab for 1-year
#'       grow-out. Must be <= \code{lab_max}. If > 0, at least one lab treatment must use the
#'       "1_TX" (retained) naming convention.}
#'     \item{tank_min}{Numeric. Minimum embryos per tank. If larval supply falls below
#'       \code{tank_min * lab_max / 100}, we reduce the number of tanks used rather than
#'       spreading larvae too thin (avoids unrealistically low settlement densities).}
#'     \item{tank_max}{Numeric. Maximum embryos per tank. Caps larval loading to prevent
#'       unrealistically high densities. We chose the default (33,333) to produce ~50 embryos
#'       per tile assuming 15\% settlement and 100 tiles per tank.}
#'     \item{orchard_size}{Numeric vector (length = n_orchard). Maximum tiles each orchard
#'       can accommodate. Surplus tiles are redirected to reefs.}
#'     \item{transplant}{Integer vector (length = years). 1 in years when mature colonies are
#'       transplanted from orchards to reefs, 0 otherwise.}
#'     \item{trans_mats}{Nested list: \code{[[orchard]][[source]]} = matrix (years x n size
#'       classes). Maximum colonies of each size class to transplant per year from that
#'       orchard-source combination.}
#'     \item{trans_reef}{Nested list: \code{[[orchard]][[source]]} = matrix (years x 2).
#'       Column 1 = destination reef index, column 2 = destination source index within
#'       that reef.}
#'   }
```

- [ ] **Step 3: Replace the `@param lab_pars` line with a structured description**

Replace the single `@param lab_pars` line (line 600) with:

```r
#' @param lab_pars Named list defining lab settlement and survival. Controls how larvae
#'   become outplantable recruits. Elements:
#'   \describe{
#'     \item{sett_props}{Named list (e.g., \code{list(T1 = 0.15)}). Fraction of larvae
#'       that successfully settle on each tile type. Estimated from Fundemar's 2025 spawning
#'       data (~15\% for cement tiles; see \code{rest_pars.rmd}).}
#'     \item{s0}{Matrix (years x n_lab). Annual survival probability of settled larvae from
#'       settlement to immediate outplanting, for each lab treatment. Allows year-specific
#'       values (e.g., to model lab disturbance events).}
#'     \item{s1}{Matrix (years x n_lab). Annual survival of retained settlers (1-year
#'       grow-out treatments). Typically lower than \code{s0} because colonies are held longer.}
#'     \item{m0}{Numeric vector (length = n_lab). Density-dependent mortality coefficient for
#'       immediate-outplant treatments. Applied as Ricker-type survival:
#'       \code{survivors = settlers * s0 * exp(-m0 * density)}.}
#'     \item{m1}{Numeric vector (length = n_lab). Same as \code{m0} but for 1-year retained
#'       treatments.}
#'     \item{size_props}{Matrix (n_lab x n_size_classes). Size class distribution of recruits
#'       at the time of immediate outplanting. Row i defines where lab treatment i's recruits
#'       land in the size distribution (typically all in SC1).}
#'     \item{size_props1}{Matrix (n_lab x n_size_classes). Same as \code{size_props} but for
#'       1-year retained recruits (may have grown to SC2 during lab retention).}
#'   }
```

- [ ] **Step 4: Add `@param dens_pars.r` and `@param dens_pars.o` (currently missing)**

These parameters are in the function signature but absent from the roxygen block. Insert after the existing `@param surv_pars.r` line (line 576):

```r
#' @param dens_pars.r Post-outplanting density-dependent survival coefficients for reefs.
#'   Nested list: \code{[[reef]][[source]]} = numeric scalar. Applied at outplanting time
#'   as Ricker-type survival: \code{surviving = outplants * exp(-dens_par * tile_density) *
#'   size_props}, where \code{tile_density} = settlers per tile on outplanting day. Higher
#'   density on each tile reduces post-outplanting survival, reflecting competition and
#'   post-settlement mortality on crowded substrates.
#'   NOTE: An earlier version applied DD to SC1 survival based on total reef population
#'   (see commented-out code at ~line 938); the current implementation operates on per-tile
#'   density at the moment of outplanting.
```

And after the `@param surv_pars.o` line (line 581):

```r
#' @param dens_pars.o Post-outplanting density-dependent survival coefficients for orchards.
#'   Same structure and mechanism as \code{dens_pars.r} but indexed as
#'   \code{[[orchard]][[source]]}.
```

- [ ] **Step 5: Verify the file still sources correctly**

Run: `cd /Users/adrianstier/Detmer-2025-coral-RSE && Rscript -e "source('rse_funs.R'); cat('OK\n')"`
Expected: `OK` with no errors

- [ ] **Step 6: Commit**

```bash
git add rse_funs.R
git commit -m "doc: document rest_pars, lab_pars, and dens_pars structures in rse_mod1()"
```

---

### Task 2: Document magic numbers in rse_mod1()

**Files:**
- Modify: `rse_funs.R` (lines ~1152, ~1198, ~1203, and fragmentation zero-vectors)

- [ ] **Step 1: Document the tiles-per-tank constant (100)**

Lines ~1150-1152 already have a comment explaining the safety cap. Replace the existing
comment at lines 1150-1151 with a more explicit version that names the constant:

```r
    # TILES_PER_TANK = 100. Fundemar's standard tank setup holds ~100 settlement tiles.
    # Safety cap: total larvae cannot exceed (max_embryos/tank) * (total_tiles) / (tiles/tank).
    # This prevents unrealistically high embryo densities in the lab.
```

Lines ~1195-1197 already have a comment explaining `prop_use` that is adequate. Add one
clarifying line to the existing comment, after the current "If larvae supply..." line:

```r
    # The magic number 100 = tiles per tank (same constant as the safety cap above).
```

- [ ] **Step 2: Document the fragmentation biology in `par_list_fun`**

At `rse_funs.R:289` (inside `par_list_fun`, the fragmentation branch), add before the `frag_pars <- list(...)` line:

```r
      # WHY: Only size classes 4 and 5 (>900 cm^2) produce fragments in A. palmata.
      # Smaller colonies lack the branching architecture for storm-driven breakage to
      # generate viable fragments. SC1-3 produce zero fragments by construction.
      # "F4_SC1" = fragments from SC4 colonies that land in SC1, etc.
```

- [ ] **Step 3: Document the same assumption in `default_pars_fun`**

At `rse_funs.R:392-393` (`frag_pars2 <- list(NULL, c(0, 0), ...)`), add:

```r
  # No fragmentation in orchards: managed nursery substrates are not subject to
  # storm-driven breakage. We set all fragment production to zero.
```

- [ ] **Step 4: Verify the file still sources correctly**

Run: `cd /Users/adrianstier/Detmer-2025-coral-RSE && Rscript -e "source('rse_funs.R'); cat('OK\n')"`
Expected: `OK`

- [ ] **Step 5: Commit**

```bash
git add rse_funs.R
git commit -m "doc: document tiles-per-tank constant and fragmentation biology assumptions"
```

---

### Task 3: Restructure model_description.Rmd with section headers and narrative

**Files:**
- Modify: `model_description.Rmd`

This file is the natural entry point for a postdoc learning the model, but it currently has zero markdown section headers and ~200 lines of commented-out test code. We restructure it into a guided walkthrough.

- [ ] **Step 1: Clean up the header and add a table of contents**

Replace lines 1–18 with:

```markdown
---
title: "RSE Model Walkthrough"
output:
  html_document:
    toc: true
    toc_float: true
date: "2025-08-23"
---

# Overview

This notebook walks through the core mechanics of the Restoration Strategy
Evaluation (RSE) model for *Acropora palmata*. We set up parameters, run a
baseline simulation, and inspect outputs to verify model behavior.

**What this file is:** A worked example — executable code with explanations.
**What this file is not:** The formal model description (see the
[Google Doc](https://docs.google.com/document/d/1BZKpY6Miuxl-hSjrSZDMMTi1NgYexdEllyUdFK8ZDHY/edit)).

**Model function:** `rse_mod1()` from `rse_funs.R` (current model with density dependence)
**Dependencies:** `coral_demographic_funs.R`, `rse_funs.R`, and the
[Detmer-2025-coral-parameters](https://github.com/stier-lab/Detmer-2025-coral-parameters)
repository (must be cloned as a sibling directory).

**WARNING:** Lambda calculations at lines ~916 and ~948 use row-wise survival
broadcasting, which differs from `pop_lambda_fun()` and the simulation. Use
`pop_lambda_fun()` for consistent lambda values.
```

- [ ] **Step 2: Add section headers throughout the file**

Insert markdown section headers at natural breakpoints. The key sections:

After the `source()` chunk (~line 37), add:
```markdown
# Load empirical parameter data

We load survival, growth, and fragmentation parameters from the companion
`Detmer-2025-coral-parameters` repository. These were estimated from six
published field studies of *A. palmata* (see that repo's README for full
provenance). Nursery data cover only SC1–SC2, so we substitute field estimates
for the larger size classes.
```

Delete the commented-out test code chunks (lines 43–92 — the `fun_test`, `extra_x`, and `max_x` blocks) since these are scratch calculations unrelated to the model walkthrough.

Before the parameter setup chunk (~line 235), add:
```markdown
# Define the simulation structure

We configure a 100-year simulation with 5 size classes matching *A. palmata*
colony area boundaries (0, 10, 100, 900, 4000 cm^2). The model tracks corals
across one reef, one orchard, and two lab tile treatments (cement and ceramic).
```

Before the demographic parameter setup (~line 258), add:
```markdown
## Demographic parameters

We extract mean survival, growth, shrinkage, and fragmentation rates from the
empirical data. All reefs share one set of field-derived parameters; all orchards
share one set of nursery-derived parameters (with field estimates filling in for
the larger size classes where nursery data are unavailable).
```

Before the density dependence setup (~line 285), add:
```markdown
## Density-dependent post-outplanting survival

We apply Ricker-type density dependence at the moment of outplanting: per-tile
settler density reduces post-outplanting survival via `exp(-dens_par * density)`.
The coefficient (0.02) controls how steeply survival declines on crowded tiles,
reflecting competition and post-settlement mortality on substrates with many recruits.
```

Before the fecundity setup (~line 292), add:
```markdown
## Fecundity

Reproductive output per colony comes from Fundemar's 2025 spawning data (Table 1
of their annual report): 1,255,111 total embryos collected from 26 colonies,
giving ~48,274 embryos per reproductive adult. Only SC3–SC5 reproduce.
```

Before the restoration parameters (~line 329), add:
```markdown
## Restoration strategy parameters

These parameters define how the lab, orchard, and reef interact operationally:
how many tiles the lab can process, what fraction of larvae settle, how recruits
are distributed across sites. See the `@param rest_pars` documentation in
`rse_funs.R` for the full structure reference.
```

Before the disturbance setup (~line 358), add:
```markdown
## Disturbance regime

We can overlay discrete disturbance events (hurricanes, bleaching) on any year
by specifying which demographic parameters are affected and replacement values.
Setting `dist_yrs` beyond the simulation length effectively turns disturbances off.
```

Before the lab parameters setup (~line 405), add:
```markdown
## Lab parameters

Settlement, survival, and density-dependent mortality in the lab. Settlement rate
(~15%) comes from Fundemar's 2025 data (see `rest_pars.rmd`). Lab survival rates
(s0 = 0.95 for immediate outplanting, s1 = 0.70 for 1-year retention) and
density-dependent mortality coefficients (m0, m1 = 0.02) are working estimates
that we plan to refine with additional Fundemar monitoring data.
```

Before the simulation call (~line 479), add:
```markdown
# Run the baseline simulation

We call `rse_mod1()` with all parameters defined above. The function returns a
17-element list tracking population sizes, reproductive output, and tile
allocations at each time step (see the return value documentation in `rse_funs.R`).
```

Before the plotting section (~line 534), add:
```markdown
# Inspect outputs

We plot total individuals and coral cover over time for both the reef and orchard
to verify that the model behaves sensibly: the orchard should fill toward capacity,
and the reef should accumulate corals from outplanting plus any natural recruitment.
```

- [ ] **Step 3: Delete scratch and commented-out test code blocks**

**IMPORTANT:** Do deletions AFTER insertions (Step 2), because line numbers in Step 2 reference
pre-deletion positions. After deleting, section headers will shift — that is expected.

Remove the following blocks that add no value to the walkthrough:
- Lines 43–59 (fun_test scratch — all commented out)
- Lines 62–91 (extra_x, max_x scratch — lines 87-91 contain live scratch variables
  `max_x <- 10; xset <- c(1, 11)` that are unused by any downstream code; safe to remove)
- Lines 120–136 (View and commented exploration)
- Lines 140–183 (par_list_fun test calls — all commented out)
- Lines 186–231 (default_pars_fun and rand_pars_fun test calls — all commented out)

These are preserved in git history and replicated in `function_tests.Rmd`.

- [ ] **Step 4: Verify the Rmd knits without errors**

Run: `cd /Users/adrianstier/Detmer-2025-coral-RSE && Rscript -e "rmarkdown::render('model_description.Rmd', quiet = TRUE); cat('OK\n')"`
Expected: `OK` (or warning about missing DATA_PATH if the parameters repo isn't present, which is fine)

- [ ] **Step 5: Commit**

```bash
git add model_description.Rmd
git commit -m "doc: restructure model_description.Rmd with section headers and ecological narrative"
```

---

## Phase B: Systematic (improve discoverability)

### Task 4: Add complete roxygen to default_pars_fun

**Files:**
- Modify: `rse_funs.R:343-350`

- [ ] **Step 1: Replace the partial documentation block (lines 343–349) with full roxygen**

```r
#' @title Default Parameter Assembly
#' @description Assembles demographic parameter sets for all reefs and orchards using
#'   summarized (mean or quantile) values from the empirical data. We assume all reefs
#'   share one set of field-derived parameters, all orchards share one set of nursery-derived
#'   parameters, and all lab treatment sources within a location share the same demographics.
#'   This function is the deterministic counterpart to \code{rand_pars_fun()}.
#' @param n_reef Integer. Number of intervention reefs.
#' @param n_orchard Integer. Number of nursery orchards.
#' @param n_lab Integer. Number of lab treatments (determines how many source subpopulations
#'   each reef tracks: n_lab + 1, where +1 = external/wild recruits).
#' @param summ_metric_list Named list specifying which summary statistic to use for each
#'   parameter type. Names: \code{field_surv}, \code{field_growth}, \code{field_shrink},
#'   \code{field_frag}, \code{nurs_surv}, \code{nurs_growth}, \code{nurs_shrink}. Values:
#'   column names from the summary data frames (typically "mean", "Q05", or "Q95").
#' @param field_surv Field survival data object from the parameters repo
#'   (\code{field_surv_pars.rds}). Must contain \code{$SC_surv_summ_df} (summary by size class).
#' @param field_growth Field growth data object (\code{field_growth_pars.rds}).
#'   Must contain \code{$summ_list} (list of 5 transition summary data frames, one per size class).
#' @param nurs_surv Nursery survival data object (\code{nurs_surv_pars.rds}).
#'   Same structure as \code{field_surv}. Covers only SC1–SC2; caller must fill in SC3–SC5
#'   from field data before passing.
#' @param nurs_growth Nursery growth data object (\code{nurs_growth_pars.rds}).
#'   Same structure as \code{field_growth}. SC3–SC5 must be filled from field data.
#' @param apal_frag_summ Data frame of fragmentation summary statistics
#'   (\code{apal_fragmentation_summ.csv}). Columns include \code{frag_type} (e.g., "F4_SC1")
#'   and summary columns (mean, Q05, Q95).
#' @return Named list with 8 elements, each a nested list:
#'   \code{[[location]][[source]]} = parameter vector or list.
#'   \describe{
#'     \item{surv_pars.r}{\code{[[reef]][[source]]} -> numeric vector (length 5), survival per SC}
#'     \item{growth_pars.r}{\code{[[reef]][[source]]} -> list of growth transition vectors}
#'     \item{shrink_pars.r}{\code{[[reef]][[source]]} -> list of shrinkage vectors}
#'     \item{frag_pars.r}{\code{[[reef]][[source]]} -> list of fragmentation vectors (SC4-5 only)}
#'     \item{surv_pars.o}{\code{[[orchard]][[source]]} -> same as reef survival}
#'     \item{growth_pars.o}{\code{[[orchard]][[source]]} -> same as reef growth}
#'     \item{shrink_pars.o}{\code{[[orchard]][[source]]} -> same as reef shrinkage}
#'     \item{frag_pars.o}{\code{[[orchard]][[source]]} -> all zeros (no fragmentation in orchards)}
#'   }
#' @seealso \code{\link{rand_pars_fun}} for stochastic parameter sampling,
#'   \code{\link{par_list_fun}} for the underlying parameter extraction.
#' @export
```

- [ ] **Step 2: Verify the file sources correctly**

Run: `cd /Users/adrianstier/Detmer-2025-coral-RSE && Rscript -e "source('rse_funs.R'); cat('OK\n')"`

- [ ] **Step 3: Commit**

```bash
git add rse_funs.R
git commit -m "doc: add complete roxygen to default_pars_fun with return value structure"
```

---

### Task 5: Add complete roxygen to rand_pars_fun

**Files:**
- Modify: `rse_funs.R:420-425`

- [ ] **Step 1: Replace the partial documentation block (lines 420–424) with full roxygen**

```r
#' @title Random Parameter Assembly
#' @description Assembles demographic parameter sets by randomly sampling from empirical
#'   distributions. We draw \code{n_sample} independent parameter sets, enabling Monte Carlo
#'   uncertainty analysis. Each draw samples a complete row from the empirical data (preserving
#'   correlations across size classes within a study). All sources within a reef share the same
#'   draw; different reefs can receive different draws.
#' @param n_reef Integer. Number of intervention reefs.
#' @param n_orchard Integer. Number of nursery orchards.
#' @param n_lab Integer. Number of lab treatments.
#' @param n_sample Integer. Number of random parameter sets to generate. Each produces
#'   an independent realization suitable for one model run.
#' @param field_surv Field survival data object. Must contain \code{$SC_surv_df}
#'   (individual-level survival data frame with columns \code{size_class} and
#'   \code{prop_survived}).
#' @param field_growth Field growth data object. Must contain \code{$mat_list}
#'   (list of 5 transition probability data frames, one per size class).
#' @param nurs_surv Nursery survival data object. Same structure as \code{field_surv}.
#'   Caller must fill SC3–SC5 from field data before passing.
#' @param nurs_growth Nursery growth data object. Same structure as \code{field_growth}.
#'   SC3–SC5 must be filled from field data.
#' @param apal_frag Fragmentation data frame (\code{apal_fragmentation.csv}). Each row
#'   is one empirical observation with columns \code{F4_SC1}, \code{F4_SC2}, etc.
#' @return Named list with 8 elements, each a nested list with an outer iteration dimension:
#'   \code{[[iteration]][[location]][[source]]} = parameter vector or list.
#'   \describe{
#'     \item{surv_pars_L.r}{\code{[[iter]][[reef]][[source]]} -> numeric vector (length 5)}
#'     \item{growth_pars_L.r}{\code{[[iter]][[reef]][[source]]} -> list of growth vectors}
#'     \item{shrink_pars_L.r}{\code{[[iter]][[reef]][[source]]} -> list of shrinkage vectors}
#'     \item{frag_pars_L.r}{\code{[[iter]][[reef]][[source]]} -> list of fragmentation vectors}
#'     \item{surv_pars_L.o}{\code{[[iter]][[orchard]][[source]]} -> same as reef}
#'     \item{growth_pars_L.o}{\code{[[iter]][[orchard]][[source]]} -> same as reef}
#'     \item{shrink_pars_L.o}{\code{[[iter]][[orchard]][[source]]} -> same as reef}
#'     \item{frag_pars_L.o}{\code{[[iter]][[orchard]][[source]]} -> all zeros}
#'   }
#'   To use iteration \code{nn}: pass \code{surv_pars_L.r[[nn]]} as \code{surv_pars.r}
#'   to \code{rse_mod1()}, and likewise for all 8 elements.
#' @seealso \code{\link{default_pars_fun}} for deterministic parameter assembly.
#' @export
```

- [ ] **Step 2: Verify and commit**

Run: `cd /Users/adrianstier/Detmer-2025-coral-RSE && Rscript -e "source('rse_funs.R'); cat('OK\n')"`

```bash
git add rse_funs.R
git commit -m "doc: add complete roxygen to rand_pars_fun with return value structure"
```

---

### Task 6: Document par_list_fun return value polymorphism

**Files:**
- Modify: `rse_funs.R:164-177`

- [ ] **Step 1: Add `@return` documentation after the existing `@param` block**

Insert before the function definition (line 177):

```r
#' @return Depends on \code{par_type}:
#'   \describe{
#'     \item{If \code{par_type = "survival"}}{List with one element:
#'       \code{$surv_pars}. If \code{sample_dt = FALSE}: numeric vector (length 5).
#'       If \code{sample_dt = TRUE}: matrix (n_sample x 5), one row per random draw.}
#'     \item{If \code{par_type = "growth"}}{List with two elements:
#'       \code{$growth_pars} and \code{$shrink_pars}. If \code{sample_dt = FALSE}:
#'       each is a list of 5 vectors (growth[k] = transitions FROM size class k to
#'       larger classes; shrink[k] = transitions from k to smaller classes).
#'       If \code{sample_dt = TRUE}: list of n_sample elements, each containing
#'       the 5-vector list structure described above.}
#'     \item{If \code{par_type = "fragmentation"}}{List with one element:
#'       \code{$frag_pars}. Structure: list of 5 elements where SC1-SC3 = NULL or
#'       zero vectors (small colonies do not fragment), SC4 and SC5 = vectors of
#'       fragment production rates to each smaller size class.
#'       If \code{sample_dt = TRUE}: list of n_sample such lists.}
#'   }
#' @details The growth/shrinkage indexing follows the transition matrix convention:
#'   \code{growth_pars[[k]]} contains transition probabilities FROM size class k
#'   TO all larger classes. For example, \code{growth_pars[[1]]} has 4 elements
#'   (SC1 -> SC2, SC1 -> SC3, SC1 -> SC4, SC1 -> SC5), while
#'   \code{growth_pars[[5]]} is NULL (SC5 cannot grow larger). Shrinkage is the
#'   reverse: \code{shrink_pars[[5]]} has 4 elements (SC5 -> SC4, ..., SC5 -> SC1).
#' @export
```

- [ ] **Step 2: Verify and commit**

Run: `cd /Users/adrianstier/Detmer-2025-coral-RSE && Rscript -e "source('rse_funs.R'); cat('OK\n')"`

```bash
git add rse_funs.R
git commit -m "doc: document par_list_fun return values and growth/shrinkage indexing"
```

---

### Task 7: Fix copy-paste artifact in coral_demographic_funs.R

**Files:**
- Modify: `coral_demographic_funs.R:183`

- [ ] **Step 1: Fix the incorrect comment**

Line 183 reads: `# holding list for survival probabilities of each size class`
Replace with: `# holding list for fecundity values of each size class`

- [ ] **Step 2: Add ecological rationale for log-normal error structure**

At `coral_demographic_funs.R:30-31` (before the `surv_errors` line in `Surv_fun`), add:

```r
  # WHY log-normal: multiplicative errors (exp(Normal)) are standard in stochastic
  # demography because they keep rates positive and produce right-skewed "bad year"
  # events — consistent with how environmental variation affects coral survival.
```

Add the same rationale at `coral_demographic_funs.R:188` (before the `fec_errors` line in `Rep_fun`):

```r
  # WHY log-normal: same rationale as survival — multiplicative environmental noise
  # ensures fecundity stays positive and captures occasional high-recruitment years.
```

- [ ] **Step 3: Verify and commit**

Run: `cd /Users/adrianstier/Detmer-2025-coral-RSE && Rscript -e "source('coral_demographic_funs.R'); cat('OK\n')"`

```bash
git add coral_demographic_funs.R
git commit -m "doc: fix copy-paste comment in Rep_fun, add log-normal rationale"
```

---

## Notes for future work (not in this plan)

These items came up in the audit but are better addressed separately:

- **Move inline functions** (`orch_exp_metric_fun`, `ohi_fun`, `ts_plot1`) from Rmds to `rse_funs.R`. This changes the analysis pipeline and should be tested against existing outputs.
- **Add tests for `rse_mod1()`** in `function_tests.Rmd`. Currently only the legacy `rse_mod()` is tested.
- **Investigate size class boundary discrepancy** between repos (parameter repo: 0, 25, 100, 500, 2000 cm² vs. this repo: 0, 10, 100, 900, 4000 cm²).
- **Create a parameter provenance table** mapping each hardcoded value to its empirical source.
- **Update README** to mention the external parameters repo, add scientific motivation, fix stale figure references.

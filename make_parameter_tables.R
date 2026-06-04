#!/usr/bin/env Rscript
# =============================================================================
# make_parameter_tables.R
#
# Single editable source for the three manuscript parameter tables:
#   Table 1  Demographic parameters (components of eqn. 1 + fecundity)
#   Table 2  Restoration parameters (decision points, lab/orchard, disturbance)
#   Table 3  Economic parameters (costs; inflated via eqn. 4)
#
# HOW TO USE
#   1. Edit a value in the "INPUTS" section below.
#   2. Run:  Rscript make_parameter_tables.R
#   3. Tables regenerate in  tables/  as both Markdown (.md, paste into the
#      manuscript) and CSV (.csv, import to Word / Google Sheets).
#
# Derived quantities (size-class midpoints, fecundity schedule, embryo yield,
# orchard capacity, per-tile outplant costs) are COMPUTED from the inputs, so
# changing an input updates every table that depends on it. Values mirror the
# canonical analysis in rse_new_scenario_analyses.rmd; keep them in sync.
#
# Base R only. No package dependencies.
# =============================================================================

# ----------------------------------------------------------------------------
# INPUTS  (edit here)
# ----------------------------------------------------------------------------

## Size structure -------------------------------------------------------------
size_lower   <- c(0, 10, 100, 900, 4000)   # lower bound of each size class (cm^2)
size_upper   <- c(10, 100, 900, 4000, NA)  # upper bound (SC5 open-ended)
sc5_midpoint <- 9325                       # SC5 midpoint: 50th pctile of obs > 4000 cm^2

## Fecundity inputs -----------------------------------------------------------
oocyte_density <- 63.6                      # oocytes per cm^2 (Mendoza-Quiroz et al. 2023)
p_fertility    <- c(0, 0, 0.1, 0.43, 0.88)  # P(colony fertile) by size class (Soong & Lang 1992)
embryos_collected_2025 <- 1255111           # Fundemar 2025: total embryos collected
spawning_colonies_2025 <- 26                # colonies that spawned (assumed SC4) for y_e calibration

## Pooled demographic summary (from coral-parameters meta-analysis) -----------
pooled_survival      <- 0.780               # pooled annual survival
pooled_survival_ci   <- c(0.701, 0.843)     # 95% CI
n_param_sets         <- 100                 # demographic replicate sets drawn
n_bootstrap          <- 2000                # hierarchical bootstrap iterations (upstream)

## Restoration / lab parameters ----------------------------------------------
reef_prop            <- 0.5                 # default proportion of outplants to reef
embryo_yield_collect <- 0.72                # reef_yield / orchard_yield (collection x fertilization)
settlement_rate      <- 0.15                # settlers per embryo on tiles (sett_props)
lab_surv_immediate   <- 0.95                # s0: lab survival, immediate outplants
lab_surv_retained    <- 0.70                # s1: lab survival, 1-year retention
lab_dd_mortality     <- 0.02                # m0/m1: density-dependent lab mortality
lab_max              <- 4000                # lab settlement-tile capacity
lab_retain_max       <- 0                   # tiles retained 1 year (default scenario)
coral_stars          <- 500                 # orchard reef-star units
tiles_per_star       <- 30                  # settlement tiles per reef star
spawn_target         <- 2000000             # e_T: target orchard embryos per year
tank_min             <- 14600               # min embryos per tank
tank_max             <- 33333               # max embryos per tank
reef_area_m2         <- 7837                # mean restoration-site area (3 Fundemar sites)
quasi_ext_threshold  <- 100                 # quasi-extinction threshold (m^2)
dist_sev_severe      <- 0.2                 # severe disturbance: survival x 0.2 (80% reduction)
dist_sev_extreme     <- 0.1                 # extreme disturbance: survival x 0.1 (90% reduction)
dist_freq_years      <- 3                   # disturbance return interval (main scenarios)
sim_years            <- 50                  # projection horizon

## Economic inputs (2025 USD, base costs before inflation) --------------------
inflation_rate       <- 0.056               # r_inf, mean 2022-2024
cost_star            <- 84.6                # $ per reef star
cost_install_boat    <- 1200                # $ one-time boat rental for orchard install
cost_permit_yr       <- 400                 # $ per year, collection permits
cost_boat_maint      <- 1200                # $ per boat-maintenance event
boat_maint_per_yr    <- 4                   # boat maintenance events per year
cost_logistics_mo    <- 500                 # $ per month, logistics/personnel
cost_cement_tile     <- 1                   # $ per cement substrate
cost_ceramic_tile    <- 7                   # $ per ceramic substrate
cost_boat_day        <- 300                 # $ per boat-day (outplanting/transplanting)
cost_diver_day       <- 200                 # $ per diver-day
reef_tiles_per_day   <- 1250                # reef outplanting rate (tiles/day)
orch_tiles_per_day   <- 800                 # orchard outplanting rate (tiles/day)
cost_reef_per_tile   <- 380 / 2000          # incidental reef outplant cost per tile
cost_orch_per_tile   <- 250 / 2000          # incidental orchard outplant cost per tile
cost_lab_aquaria_day <- 432                 # $ per day, lab aquaria
cost_lab_labor_day   <- 200                 # $ per day, lab labor
cost_spawn_reef      <- 6500                # $ per reef spawn-collection event
cost_spawn_orchard   <- 3250                # $ per orchard spawn-collection event

# ----------------------------------------------------------------------------
# DERIVED QUANTITIES  (computed; do not edit)
# ----------------------------------------------------------------------------
A_mids <- c((size_lower[1:4] + size_upper[1:4]) / 2, sc5_midpoint)   # midpoint areas
fec_pars <- floor(A_mids * oocyte_density * p_fertility)            # embryos/colony (max), matches code
embryo_yield_calc <- embryos_collected_2025 /
  (A_mids[4] * p_fertility[4] * oocyte_density * spawning_colonies_2025)  # y_e
orchard_size <- coral_stars * tiles_per_star                         # tiles
substrate_mean_cost <- 0.5 * cost_cement_tile + 0.5 * cost_ceramic_tile
logistics_yr <- cost_logistics_mo * 12

fmt_vec <- function(x) paste(formatC(x, format = "fg", big.mark = ","), collapse = ", ")

# ----------------------------------------------------------------------------
# TABLE 1  Demographic parameters
# ----------------------------------------------------------------------------
demographic <- data.frame(
  Symbol = c("n", "-", "A", "S", "T", "F", "d_ooc", "p_fec", "w", "y_e", "m"),
  Parameter = c(
    "Number of size classes",
    "Size-class boundaries (cm^2)",
    "Midpoint area of each size class (cm^2)",
    "Annual survival (per size class)",
    "Growth / shrinkage transitions",
    "Fragmentation rates",
    "Oocyte density (oocytes/cm^2)",
    "Probability a colony is fertile (per size class)",
    "Fecundity, embryos per colony (per size class)",
    "Embryo yield (collection x fertilization)",
    "Density-dependent recruit mortality coefficient"
  ),
  Value = c(
    length(size_lower),
    fmt_vec(size_lower),
    fmt_vec(A_mids),
    sprintf("pooled %.1f%% (95%% CI %.1f-%.1f%%); %d bootstrapped sets",
            100 * pooled_survival, 100 * pooled_survival_ci[1],
            100 * pooled_survival_ci[2], n_param_sets),
    sprintf("literature-derived; %d bootstrapped sets", n_param_sets),
    "size-based (Vardi 2011, 2012); SC1 fragments split 10/90 into SC1/SC2",
    sprintf("%.1f", oocyte_density),
    fmt_vec(p_fertility),
    fmt_vec(fec_pars),
    sprintf("%.2f", embryo_yield_calc),
    sprintf("%.2f", lab_dd_mortality)
  ),
  Source = c(
    "Model structure",
    "Vardi et al. 2012 size scheme",
    "Computed: arithmetic midpoints (SC1-SC4); 50th pctile > 4000 cm^2 (SC5)",
    "Caribbean meta-analysis (Detmer-2025-coral-parameters); hierarchical bootstrap",
    "Caribbean meta-analysis; hierarchical bootstrap",
    "Vardi 2011, Vardi et al. 2012",
    "Mendoza-Quiroz et al. 2023",
    "Soong & Lang 1992",
    "Computed: A x d_ooc x p_fec (theoretical maxima)",
    "Calibrated to Fundemar 2025 collection (assumed SC4 colonies)",
    "Fundemar outplant monitoring (density-dependent)"
  ),
  stringsAsFactors = FALSE
)

# ----------------------------------------------------------------------------
# TABLE 2  Restoration parameters
# ----------------------------------------------------------------------------
restoration <- data.frame(
  Symbol = c("reef_prop", "y_collect", "sett", "s_l", "s_l(1yr)", "m_l",
             "lab_max", "lab_retain", "orchard_size", "e_T",
             "tank_min/max", "A_reef", "transplant",
             "dist_sev", "dist_freq", "ext_thresh", "n_sets", "T_sim"),
  Parameter = c(
    "Proportion of outplants to reef (default strategy)",
    "Embryo yield, reef & orchard collection",
    "Settlement rate (settlers per embryo on tiles)",
    "Recruit lab survival, immediate outplants",
    "Recruit lab survival, 1-year retention",
    "Density-dependent lab mortality",
    "Lab settlement-tile capacity (tiles)",
    "Tiles retained 1 year (default)",
    "Orchard capacity (tiles)",
    "Target orchard embryos per year",
    "Tank embryo min / max",
    "Restoration reef area (m^2)",
    "Transplant from orchard to reef (default)",
    "Disturbance severity (severe / extreme)",
    "Disturbance return interval (yr)",
    "Quasi-extinction threshold (m^2)",
    "Demographic parameter sets (drawn from bootstrap)",
    "Simulation horizon (yr)"
  ),
  Value = c(
    sprintf("%.2f", reef_prop),
    sprintf("%.2f", embryo_yield_collect),
    sprintf("%.2f", settlement_rate),
    sprintf("%.2f", lab_surv_immediate),
    sprintf("%.2f", lab_surv_retained),
    sprintf("%.2f", lab_dd_mortality),
    format(lab_max, big.mark = ","),
    as.character(lab_retain_max),
    sprintf("%s (%d stars x %d tiles)", format(orchard_size, big.mark = ","),
            coral_stars, tiles_per_star),
    format(spawn_target, big.mark = ","),
    sprintf("%s / %s", format(tank_min, big.mark = ","),
            format(tank_max, big.mark = ",")),
    format(reef_area_m2, big.mark = ","),
    "0 (none)",
    sprintf("x%.1f (%.0f%%) / x%.1f (%.0f%%)", dist_sev_severe,
            100 * (1 - dist_sev_severe), dist_sev_extreme,
            100 * (1 - dist_sev_extreme)),
    as.character(dist_freq_years),
    as.character(quasi_ext_threshold),
    sprintf("%d (of %s)", n_param_sets, format(n_bootstrap, big.mark = ",")),
    as.character(sim_years)
  ),
  Source = c(
    "Strategy variable (varied 0-1)", "Fundemar 2025; calibrated",
    "Fundemar 2025 spawning data", "Calibrated to Fundemar 2025 outplant data",
    "Calibrated", "Calibrated", "Fundemar facility constraint",
    "Scenario choice", "Fundemar facility (500 reef stars)",
    "~2x 2025 reference-reef collection", "Fundemar 2025 spawning data",
    "Mean of 3 Fundemar restoration sites", "Scenario choice",
    "Working estimate (needs calibration)", "Scenario choice",
    "Model choice", "Hierarchical bootstrap", "Scenario choice"
  ),
  stringsAsFactors = FALSE
)

# ----------------------------------------------------------------------------
# TABLE 3  Economic parameters  (2025 USD; inflated via eqn. 4)
# ----------------------------------------------------------------------------
economic <- data.frame(
  Category = c("-", rep("Fixed", 4), rep("Variable", 8)),
  Parameter = c(
    "Inflation rate (applied to all costs except initial orchard setup)",
    "Reef stars + installation (initial, one-time)",
    "Collection permits",
    "Boat maintenance",
    "Logistics / personnel",
    "Substrate purchase (50% cement / 50% ceramic)",
    "Reef outplanting (boat + diver + per-tile)",
    "Orchard outplanting (boat + diver + per-tile)",
    "Orchard maintenance",
    "Lab, first 2 weeks (aquaria + labor)",
    "Lab, 1-year retention",
    "Spawn collection, reference reef",
    "Spawn collection, orchard"
  ),
  Value = c(
    sprintf("%.3f (%.1f%%/yr)", inflation_rate, 100 * inflation_rate),
    sprintf("$%.2f/star + $%s boat", cost_star, format(cost_install_boat, big.mark = ",")),
    sprintf("$%d/yr", cost_permit_yr),
    sprintf("$%s x %d/yr", format(cost_boat_maint, big.mark = ","), boat_maint_per_yr),
    sprintf("$%d/mo (= $%s/yr)", cost_logistics_mo, format(logistics_yr, big.mark = ",")),
    sprintf("$%d / $%d per tile (mean $%.2f)", cost_cement_tile, cost_ceramic_tile, substrate_mean_cost),
    sprintf("$%d boat/day (%s/day) + $%d diver/day + $%.2f/tile",
            cost_boat_day, format(reef_tiles_per_day, big.mark = ","), cost_diver_day, cost_reef_per_tile),
    sprintf("$%d boat/day (%d/day) + $%d diver/day + $%.3f/tile",
            cost_boat_day, orch_tiles_per_day, cost_diver_day, cost_orch_per_tile),
    "per-reef-star scaling, 2x/yr (~$265 base + per-star)",
    sprintf("$%d/day aquaria + $%d/day labor, 7 days", cost_lab_aquaria_day, cost_lab_labor_day),
    sprintf("$%d/day labor x ~346 days", cost_lab_labor_day),
    sprintf("$%s per collection event", format(cost_spawn_reef, big.mark = ",")),
    sprintf("$%s per collection event", format(cost_spawn_orchard, big.mark = ","))
  ),
  Source = c(
    "Mean of 2022-2024 rates", rep("Fundemar", 4),
    "Fundemar", "Fundemar (rate estimated)", "Fundemar (rate estimated)",
    "Estimated", "Fundemar", "Estimated", "Fundemar", "Fundemar"
  ),
  stringsAsFactors = FALSE
)

# ----------------------------------------------------------------------------
# RENDER  (Markdown + CSV)
# ----------------------------------------------------------------------------
out_dir <- file.path(dirname(sub("--file=", "",
            grep("--file=", commandArgs(FALSE), value = TRUE)[1])), "tables")
if (is.na(out_dir) || out_dir == "tables" || !nzchar(out_dir)) out_dir <- "tables"
if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)

write_md <- function(df, title, file) {
  cols <- names(df)
  lines <- c(
    paste0("**", title, "**"), "",
    paste0("| ", paste(cols, collapse = " | "), " |"),
    paste0("| ", paste(rep("---", length(cols)), collapse = " | "), " |"),
    apply(df, 1, function(r) paste0("| ", paste(r, collapse = " | "), " |"))
  )
  writeLines(lines, file)
}

render <- function(df, title, stub) {
  write_md(df, title, file.path(out_dir, paste0(stub, ".md")))
  write.csv(df, file.path(out_dir, paste0(stub, ".csv")), row.names = FALSE)
}

render(demographic, "Table 1. Demographic parameters.", "Table1_demographic_parameters")
render(restoration, "Table 2. Restoration parameters.", "Table2_restoration_parameters")
render(economic,    "Table 3. Economic parameters (2025 USD).", "Table3_economic_parameters")

cat("Parameter tables written to:", normalizePath(out_dir), "\n")
cat("  Table1_demographic_parameters.{md,csv}\n")
cat("  Table2_restoration_parameters.{md,csv}\n")
cat("  Table3_economic_parameters.{md,csv}\n")
cat(sprintf("\nDerived check: A_mids = %s\n", fmt_vec(A_mids)))
cat(sprintf("Derived check: fecundity = %s\n", fmt_vec(fec_pars)))
cat(sprintf("Derived check: embryo yield y_e = %.3f\n", embryo_yield_calc))

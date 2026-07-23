# fig5_bars.R — Conference-talk figure: equal-budget 3-strategy comparison.
# Recomputes the model on the fly (no stored outputs). Mirrors the "Figure 5"
# pipeline in rse_new_scenario_analyses.rmd (~lines 5346-6130).
#
# Strategies (5yr & 50yr, no disturbance):
#   Default        = current mixed strategy (immediate outplant, 50% to reef)
#   More recruits  = increase SC1 lab capacity (extra small recruits; budget-matched)
#   Transplant SC2 = move intermediate orchard colonies to the reef
# Outcomes: reef coral cover (reef_cover_mean), total ROI (tot_ROI_mean), cost (tot_costs)
#
# Run: Rscript presentation-figs/fig5_bars.R   (from repo root)
# Created: 2026-07-17

setwd(path.expand("~/Detmer-2025-coral-RSE"))
source("presentation-figs/theme_slide.R")
source("presentation-figs/engine/setup_base.R")     # defines all_pars_R, n_sample1, years, n,
                                                        # orchard_size, rest_pars_def, N0.o_def, lab_pars(_def), etc.
source("presentation-figs/engine/functions.R")      # orch_exp_fun1/2, full_dt_fun, metrics_dt_fun

suppressMessages({library(tidyverse)})

# ---------------------------------------------------------------------------
# Objects NOT provided by setup_base.R (defined later in the Rmd) — reconstruct
# exactly as in rse_new_scenario_analyses.rmd.
# ---------------------------------------------------------------------------

# NOTE: n_sample1 = 100 (from setup_base.R) — kept at 100 to match the manuscript
# exactly. Runtime is a few minutes. To subsample for speed you would regenerate
# all_pars_R AND SC2_lists with a smaller n_sample1; not done here.

lambda_Rs <- c(0, 1255111)   # Rmd line 1714 (0 = no reef reproduction, [2] = 100% reef investment scenario)
prop_set1 <- c(0.5)          # 50% of lab recruits to reef

# SC2 uncertain-parameter draws (Rmd lines 385-395)
trans_surv_list  <- list(); lab_growth1_list <- list()
lab_surv1_list   <- list(); lab_out_surv1_list <- list()
set.seed(1000)
for (i in 1:n_sample1) {
  trans_surv_list[[i]]    <- runif(1, min = 0.5,  max = 1)
  lab_growth1_list[[i]]   <- runif(1, min = 0.36, max = 0.8)
  lab_surv1_list[[i]]     <- runif(1, min = 0.5,  max = 1)
  lab_out_surv1_list[[i]] <- runif(1, min = 0.5,  max = 1.5)
}
SC2_lists <- list(trans_surv_list = trans_surv_list, lab_growth1_list = lab_growth1_list,
                  lab_surv1_list = lab_surv1_list, lab_out_surv1_list = lab_out_surv1_list)

# absolute means across parameter sets (for speaker-note tables)
summ_fun <- function(dt_i) {
  tibble(
    reef_cover = mean(dt_i$reef_cover_mean),
    tot_ROI    = mean(dt_i$tot_ROI_mean),
    cost       = mean(dt_i$tot_costs)
  )
}

# Manuscript's effect-size method (Rmd lines 5605-5631): for EACH parameter set,
# take the ratio strategy/Default, THEN average the ratios. This is the source of
# the reported headline multipliers (e.g. ~37x reef cover) — it differs from a
# ratio-of-means because the reef-cover distribution is right-skewed.
relative_metrics_fun <- function(dt2, dt_def, n_sample1) {
  reef_coral <- dt2$reef_cover_mean / dt_def$reef_cover_mean
  tot_ROI    <- dt2$tot_ROI_mean    / dt_def$tot_ROI_mean
  tot_costs  <- dt2$tot_costs        / dt_def$tot_costs
  list(reef_coral = reef_coral, tot_ROI = tot_ROI, tot_costs = tot_costs)
}
mean_ratio <- function(dt2, dt_def) {
  r <- relative_metrics_fun(dt2, dt_def, n_sample1)
  tibble(reef_cover_x = mean(r$reef_coral), tot_ROI_x = mean(r$tot_ROI), cost_x = mean(r$tot_costs))
}

# ===========================================================================
# STRATEGY 1: DEFAULT  (Rmd lines 5352-5367)
# ===========================================================================
N0.o <- list(); N0.o[[1]] <- list()
N0.o[[1]][[1]] <- c(0.25 * orchard_size, 0.5 * orchard_size, rep(0, 3))  # seed orchard w/ SC1+SC2
N0.o[[1]][[2]] <- rep(0, n)
rest_pars <- rest_pars_def

message("Running DEFAULT ...")
orch_D0_def_50   <- orch_exp_fun2(dem_pars_all = all_pars_R, n_pars = n_sample1, prop_set = prop_set1,
                                  par_set2 = lambda_Rs[2], par2_name = "lambda_R", dist = F)
orch_D0_def_dt5  <- full_dt_fun(sim_list = orch_D0_def_50, max_yr = 6,  n_pars = n_sample1,
                                prop_set = prop_set1, par_set2 = lambda_Rs[2], par2_name = "lambda_R", annual_costs = T)
orch_D0_def_dt50 <- full_dt_fun(sim_list = orch_D0_def_50, max_yr = 51, n_pars = n_sample1,
                                prop_set = prop_set1, par_set2 = lambda_Rs[2], par2_name = "lambda_R", annual_costs = T)

# ===========================================================================
# STRATEGY 3: TRANSPLANT SC2  (Rmd lines 5380-5394) — run before SC1L (needed for budget match)
# ===========================================================================
rest_pars <- rest_pars_def
rest_pars$transplant <- rep(1, years)   # transplant orchard colonies every year

message("Running TRANSPLANT SC2 ...")
orch_D0_SC2_50   <- orch_exp_fun2(dem_pars_all = all_pars_R, n_pars = n_sample1, prop_set = prop_set1,
                                  par_set2 = lambda_Rs[2], par2_name = "lambda_R", dist = F, SC2_lists = SC2_lists)
orch_D0_SC2_dt5  <- full_dt_fun(sim_list = orch_D0_SC2_50, max_yr = 6,  n_pars = n_sample1,
                                prop_set = prop_set1, par_set2 = lambda_Rs[2], par2_name = "lambda_R", annual_costs = T)
orch_D0_SC2_dt50 <- full_dt_fun(sim_list = orch_D0_SC2_50, max_yr = 51, n_pars = n_sample1,
                                prop_set = prop_set1, par_set2 = lambda_Rs[2], par2_name = "lambda_R", annual_costs = T)
rest_pars <- rest_pars_def

# ===========================================================================
# BUDGET MATCHING (Rmd lines 5419-5510): find extra lab substrates the "More
# recruits" strategy can afford using the budget freed vs. the transplant run.
# ===========================================================================
subs_cost_fun <- function(prop_choice, lab_max_set, yr_set) {
  cost_mat <- matrix(NA, nrow = length(yr_set), ncol = length(lab_max_set))
  r_inf <- 0.056
  for (i in 1:length(yr_set)) {
    for (j in 1:length(lab_max_set)) {
      reef_tiles    <- prop_choice * lab_max_set[j]
      orchard_tiles <- (1 - prop_choice) * lab_max_set[j]
      c_subs <- (reef_tiles + orchard_tiles) * (0.5 * 1 + 0.5 * 7) * (1 + r_inf)^(yr_set[i])
      c_reef <- 300 * ceiling(reef_tiles / 1250) + 200 * reef_tiles / 1250 + 380 / 2000 * reef_tiles
      c_reef <- c_reef * (1 + r_inf)^(yr_set[i])
      c_orch <- 300 * ceiling(orchard_tiles / 800) + 200 * orchard_tiles / 800 + 250 / 2000 * orchard_tiles
      c_orch <- c_orch * (1 + r_inf)^(yr_set[i])
      cost_mat[i, j] <- c_subs + (c_reef + c_orch)
    }
  }
  cost_mat
}

cost_mat_fun <- function(dt_list, max_year) {
  cost_mat <- matrix(NA, nrow = n_sample1, ncol = max_year)
  for (i in 1:n_sample1) cost_mat[i, ] <- dt_list[[i]][[1]][[1]]
  cost_mat
}

subs_cost1        <- subs_cost_fun(prop_choice = 1, lab_max_set = seq(1, 10000, 1), yr_set = 1:50)
costs_D0_def_50   <- cost_mat_fun(orch_D0_def_dt50$costs_list, 50)
costs_D0_SC2_50   <- cost_mat_fun(orch_D0_SC2_dt50$costs_list, 50)
budget_diff       <- apply(costs_D0_SC2_50, 2, mean) - apply(costs_D0_def_50, 2, mean)
extra_subs        <- rep(NA, length(budget_diff))
for (i in seq_along(extra_subs)) {
  cost_vals <- subs_cost1[i, ]
  extra_subs[i] <- which(abs(cost_vals - budget_diff[i]) == min(abs(cost_vals - budget_diff[i])))
}
extra_subs <- c(0, extra_subs)   # first (setup) year gets 0

# ===========================================================================
# STRATEGY 2: MORE RECRUITS / INCREASE SC1 CAPACITY  (Rmd lines 5521-5548)
# ===========================================================================
rest_pars <- rest_pars_def
rest_pars$lab_max        <- rep(rest_pars$lab_max, years) + extra_subs
rest_pars$lab_retain_max <- rep(0, years)

N0.o <- list(); N0.o[[1]] <- list()
N0.o[[1]][[1]] <- c(0.25 * orchard_size, 0.5 * orchard_size, rep(0, 3))
N0.o[[1]][[2]] <- rep(0, n)

message("Running MORE RECRUITS (SC1L) ...")
orch_D0_SC1L_50   <- orch_exp_fun2(dem_pars_all = all_pars_R, n_pars = n_sample1, prop_set = c(0.5),
                                   par_set2 = lambda_Rs[2], par2_name = "lambda_R", dist = F)
orch_D0_SC1L_dt5  <- full_dt_fun(sim_list = orch_D0_SC1L_50, max_yr = 6,  n_pars = n_sample1,
                                 prop_set = prop_set1, par_set2 = lambda_Rs[2], par2_name = "lambda_R", annual_costs = T)
orch_D0_SC1L_dt50 <- full_dt_fun(sim_list = orch_D0_SC1L_50, max_yr = 51, n_pars = n_sample1,
                                 prop_set = prop_set1, par_set2 = lambda_Rs[2], par2_name = "lambda_R", annual_costs = T)

# reset globals
rest_pars <- rest_pars_def
N0.o <- N0.o_def

# ===========================================================================
# ASSEMBLE RESULTS
# ===========================================================================
strat_levels <- c("Default", "More recruits", "Transplant SC2")

res <- bind_rows(
  cbind(strategy = "Default",        horizon = "5yr",  summ_fun(orch_D0_def_dt5$dt_i)),
  cbind(strategy = "More recruits",  horizon = "5yr",  summ_fun(orch_D0_SC1L_dt5$dt_i)),
  cbind(strategy = "Transplant SC2", horizon = "5yr",  summ_fun(orch_D0_SC2_dt5$dt_i)),
  cbind(strategy = "Default",        horizon = "50yr", summ_fun(orch_D0_def_dt50$dt_i)),
  cbind(strategy = "More recruits",  horizon = "50yr", summ_fun(orch_D0_SC1L_dt50$dt_i)),
  cbind(strategy = "Transplant SC2", horizon = "50yr", summ_fun(orch_D0_SC2_dt50$dt_i))
) |>
  mutate(strategy = factor(strategy, levels = strat_levels))

cat("\n\n==================== ABSOLUTE VALUES (speaker notes) ====================\n")
print(as.data.frame(res), digits = 5)

# Multipliers vs Default = mean of per-parameter-set ratios (manuscript method).
mult <- bind_rows(
  cbind(strategy = "Default",        horizon = "5yr",  tibble(reef_cover_x = 1, tot_ROI_x = 1, cost_x = 1)),
  cbind(strategy = "More recruits",  horizon = "5yr",  mean_ratio(orch_D0_SC1L_dt5$dt_i,  orch_D0_def_dt5$dt_i)),
  cbind(strategy = "Transplant SC2", horizon = "5yr",  mean_ratio(orch_D0_SC2_dt5$dt_i,   orch_D0_def_dt5$dt_i)),
  cbind(strategy = "Default",        horizon = "50yr", tibble(reef_cover_x = 1, tot_ROI_x = 1, cost_x = 1)),
  cbind(strategy = "More recruits",  horizon = "50yr", mean_ratio(orch_D0_SC1L_dt50$dt_i, orch_D0_def_dt50$dt_i)),
  cbind(strategy = "Transplant SC2", horizon = "50yr", mean_ratio(orch_D0_SC2_dt50$dt_i,  orch_D0_def_dt50$dt_i))
) |>
  mutate(strategy = factor(strategy, levels = strat_levels))

cat("\n============ MULTIPLIERS vs DEFAULT (mean of per-set ratios, x Default) ============\n")
print(as.data.frame(mult), digits = 4)
cat("\n(sanity checks: reef_cover_x SC2 @5yr ~37; tot_ROI_x SC2 @50yr ~2.3; cost_x SC2 ~1.15-1.17)\n\n")

# ===========================================================================
# FIGURE — 5yr no-disturbance, normalized to Default = 1 (x Default)
# ===========================================================================
outcome_labs <- c(reef_cover_x = "Reef cover",
                  tot_ROI_x    = "Total ROI",
                  cost_x       = "Cost")

plot_dat <- mult |>
  filter(horizon == "5yr") |>
  select(strategy, reef_cover_x, tot_ROI_x, cost_x) |>
  pivot_longer(-strategy, names_to = "outcome", values_to = "value") |>
  mutate(outcome = factor(outcome, levels = names(outcome_labs), labels = outcome_labs))

STRAT_COLS <- c("Default" = DECK$mute, "More recruits" = DECK$teal, "Transplant SC2" = DECK$coral)

lab_fmt <- function(v) ifelse(v >= 10, paste0(round(v), "×"),
                       ifelse(v >= 1, paste0(sprintf("%.1f", v), "×"),
                                      paste0(sprintf("%.2f", v), "×")))

p <- ggplot(plot_dat, aes(x = strategy, y = value, fill = strategy)) +
  geom_col(width = 0.78, color = NA) +
  geom_text(aes(label = lab_fmt(value)),
            vjust = -0.35, size = 5.6, color = DECK$ink, fontface = "bold") +
  facet_wrap(~outcome, scales = "free_y") +
  scale_fill_manual(values = STRAT_COLS) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.18))) +
  labs(x = NULL, y = "× Default (5-yr, no disturbance)") +
  theme_slide(base_size = 19, legend = "none") +
  theme(
    panel.grid.major.y = element_line(color = "grey90", linewidth = 0.4),
    panel.grid.major.x = element_blank(),
    strip.text        = element_text(size = 18, face = "bold", color = DECK$ink,
                                     margin = margin(b = 4)),
    axis.text.x       = element_blank(),
    axis.ticks.x      = element_blank(),
    legend.text       = element_text(size = 16),
    legend.key.size   = unit(1.0, "lines"),
    panel.spacing     = unit(1.3, "lines")
  )

save_slide(p, "fig5_bars.png", w = 8.2, h = 5.1)

cat("\nWrote presentation-figs/fig5_bars.png\n")

# fig_where_data.R — builds the reef-vs-orchard ALLOCATION SWEEP used by the Q1 figures
# (fig_where_invest.R, fig_where_tradeoff.R) and the backup frontier (fig3_frontier.R).
# Reproduces the manuscript Fig 3 sweep INLINE from the real analysis
# (rse_new_scenario_analyses.rmd, "# Figure 3 & SM") — NO auto-extract scripts.
# Outputs: orch_D0_all_dt5 / orch_D0_all_dt50 in the environment, and the cache
#          /tmp/orch_sweep.rds = list(dt5, dt50, lr).  ~2,200 sims; a few minutes.
# Created: 2026-07-20
setwd(path.expand("~/Detmer-2025-coral-RSE"))
suppressMessages(source("presentation-figs/engine/setup_base.R"))  # engine + params (sources real rse_funs.R)
suppressMessages(source("presentation-figs/engine/functions.R"))   # orch_exp_fun2, full_dt_fun

prop_all  <- seq(from = 0, to = 1, length.out = 11)   # share of recruits to the reef
lambda_Rs <- c(0, 1255111)                            # no restoration / with restoration

cat("running allocation sweep (", n_sample1, "param sets x", length(prop_all), "allocations x",
    length(lambda_Rs), "lambda)...\n")
orch_D0_all <- orch_exp_fun2(dem_pars_all = all_pars_R, n_pars = n_sample1, prop_set = prop_all,
                             par_set2 = lambda_Rs, par2_name = "lambda_R", dist = F,
                             dist_yrs = NULL, dist_pars_list = NULL)

orch_D0_all_dt5  <- full_dt_fun(sim_list = orch_D0_all, max_yr = 6,  n_pars = n_sample1,
                                prop_set = prop_all, par_set2 = lambda_Rs, par2_name = "lambda_R")
orch_D0_all_dt50 <- full_dt_fun(sim_list = orch_D0_all, max_yr = 51, n_pars = n_sample1,
                                prop_set = prop_all, par_set2 = lambda_Rs, par2_name = "lambda_R")

saveRDS(list(dt5 = orch_D0_all_dt5, dt50 = orch_D0_all_dt50, lr = lambda_Rs), "/tmp/orch_sweep.rds")
cat("wrote /tmp/orch_sweep.rds\n")

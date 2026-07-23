# fig5_transplant_ocean.R — DARK "Deep Current" restyle of manuscript Figure 5.
# Reproduces the 2x2 base-R comparison (SC1-capacity vs Transplant-SC2, relative
# to Default; rows = ROI / cost, cols = 5yr / 50yr, with & without disturbance)
# from rse_new_scenario_analyses.rmd "# Figure 5 & SM" (~lines 5340-5820), then
# renders it on deep navy (#0B1F33) with light text + teal/coral points for the
# Ocean Recoveries dark slide theme. DATA/model identical — styling only.
#
# Run: Rscript presentation-figs/fig5_transplant_ocean.R   (from repo root)
# Created: 2026-07-21

setwd(path.expand("~/Detmer-2025-coral-RSE"))
source("presentation-figs/engine/setup_base.R")   # all_pars_R, n_sample1, years, n, orchard_size, rest_pars_def, N0.o_def, lambda etc.
source("presentation-figs/engine/functions.R")    # orch_exp_fun2, full_dt_fun, ...
suppressMessages({library(tidyverse)})

# ---- dark theme tokens ----
BG   <- "#0B1F33"; TXT <- "#F4F6F8"; AXT <- "#AEC0D0"; GRID <- "#8CA0B3"
TEAL <- "#56B4E9"; CORAL <- "#F0A24E"

# ---- scenario constants (verbatim from Rmd) ----
lambda_Rs <- c(0, 1255111)
prop_set1 <- c(0.5)

# SC2 uncertain-parameter draws (Rmd lines 385-395; seed matches fig5_bars.R)
trans_surv_list <- list(); lab_growth1_list <- list()
lab_surv1_list  <- list(); lab_out_surv1_list <- list()
set.seed(1000)
for (i in 1:n_sample1) {
  trans_surv_list[[i]]    <- runif(1, 0.5,  1)
  lab_growth1_list[[i]]   <- runif(1, 0.36, 0.8)
  lab_surv1_list[[i]]     <- runif(1, 0.5,  1)
  lab_out_surv1_list[[i]] <- runif(1, 0.5,  1.5)
}
SC2_lists <- list(trans_surv_list = trans_surv_list, lab_growth1_list = lab_growth1_list,
                  lab_surv1_list = lab_surv1_list, lab_out_surv1_list = lab_out_surv1_list)

# disturbance parameters (Rmd lines 695-706): once every 3 years
dist_yrs3  <- c(1:max(years))[c(F, T, F)]
dist_mat.r <- matrix(0.2, nrow = length(dist_yrs3), ncol = 5)
dist.r     <- list(dist_mat.r, dist_mat.r, dist_mat.r)
dist_mat.o <- matrix(1,   nrow = length(dist_yrs3), ncol = 5)
dist.o     <- list(dist_mat.o, dist_mat.o)
dist_pars_list3 <- list(dist.r = dist.r, dist.o = dist.o)

# =====================================================================
# STRATEGY 1: DEFAULT (D0 = no disturbance, D3 = disturbance)
# =====================================================================
N0.o <- list(); N0.o[[1]] <- list()
N0.o[[1]][[1]] <- c(0.25 * orchard_size, 0.5 * orchard_size, rep(0, 3))
N0.o[[1]][[2]] <- rep(0, n)
rest_pars <- rest_pars_def

message("DEFAULT (no disturbance) ...")
orch_D0_def_50   <- orch_exp_fun2(dem_pars_all = all_pars_R, n_pars = n_sample1, prop_set = prop_set1, par_set2 = lambda_Rs[2], par2_name = "lambda_R", dist = F)
orch_D0_def_dt5  <- full_dt_fun(orch_D0_def_50, max_yr = 6,  n_pars = n_sample1, prop_set = prop_set1, par_set2 = lambda_Rs[2], par2_name = "lambda_R", annual_costs = T)
orch_D0_def_dt50 <- full_dt_fun(orch_D0_def_50, max_yr = 51, n_pars = n_sample1, prop_set = prop_set1, par_set2 = lambda_Rs[2], par2_name = "lambda_R", annual_costs = T)

message("DEFAULT (disturbance) ...")
orch_D3_def_50   <- orch_exp_fun2(dem_pars_all = all_pars_R, n_pars = n_sample1, prop_set = prop_set1, par_set2 = lambda_Rs[2], par2_name = "lambda_R", dist = T, dist_yrs3, dist_pars_list = dist_pars_list3)
orch_D3_def_dt5  <- full_dt_fun(orch_D3_def_50, max_yr = 6,  n_pars = n_sample1, prop_set = prop_set1, par_set2 = lambda_Rs[2], par2_name = "lambda_R", annual_costs = T)
orch_D3_def_dt50 <- full_dt_fun(orch_D3_def_50, max_yr = 51, n_pars = n_sample1, prop_set = prop_set1, par_set2 = lambda_Rs[2], par2_name = "lambda_R", annual_costs = T)

# =====================================================================
# STRATEGY 3: TRANSPLANT SC2 (run before SC1L for budget match)
# =====================================================================
rest_pars <- rest_pars_def
rest_pars$transplant <- rep(1, years)

message("TRANSPLANT SC2 (no disturbance) ...")
orch_D0_SC2_50   <- orch_exp_fun2(dem_pars_all = all_pars_R, n_pars = n_sample1, prop_set = prop_set1, par_set2 = lambda_Rs[2], par2_name = "lambda_R", dist = F, SC2_lists = SC2_lists)
orch_D0_SC2_dt5  <- full_dt_fun(orch_D0_SC2_50, max_yr = 6,  n_pars = n_sample1, prop_set = prop_set1, par_set2 = lambda_Rs[2], par2_name = "lambda_R", annual_costs = T)
orch_D0_SC2_dt50 <- full_dt_fun(orch_D0_SC2_50, max_yr = 51, n_pars = n_sample1, prop_set = prop_set1, par_set2 = lambda_Rs[2], par2_name = "lambda_R", annual_costs = T)

message("TRANSPLANT SC2 (disturbance) ...")
orch_D3_SC2_50   <- orch_exp_fun2(dem_pars_all = all_pars_R, n_pars = n_sample1, prop_set = prop_set1, par_set2 = lambda_Rs[2], par2_name = "lambda_R", dist = T, dist_yrs3, dist_pars_list = dist_pars_list3, SC2_lists = SC2_lists)
orch_D3_SC2_dt5  <- full_dt_fun(orch_D3_SC2_50, max_yr = 6,  n_pars = n_sample1, prop_set = prop_set1, par_set2 = lambda_Rs[2], par2_name = "lambda_R", annual_costs = T)
orch_D3_SC2_dt50 <- full_dt_fun(orch_D3_SC2_50, max_yr = 51, n_pars = n_sample1, prop_set = prop_set1, par_set2 = lambda_Rs[2], par2_name = "lambda_R", annual_costs = T)
rest_pars <- rest_pars_def

# =====================================================================
# BUDGET MATCHING (Rmd 5419-5510)
# =====================================================================
subs_cost_fun <- function(prop_choice, lab_max_set, yr_set) {
  cost_mat <- matrix(NA, nrow = length(yr_set), ncol = length(lab_max_set)); r_inf <- 0.056
  for (i in seq_along(yr_set)) for (j in seq_along(lab_max_set)) {
    reef_tiles <- prop_choice * lab_max_set[j]; orchard_tiles <- (1 - prop_choice) * lab_max_set[j]
    c_subs <- (reef_tiles + orchard_tiles) * (0.5 * 1 + 0.5 * 7) * (1 + r_inf)^(yr_set[i])
    c_reef <- (300 * ceiling(reef_tiles / 1250) + 200 * reef_tiles / 1250 + 380 / 2000 * reef_tiles) * (1 + r_inf)^(yr_set[i])
    c_orch <- (300 * ceiling(orchard_tiles / 800) + 200 * orchard_tiles / 800 + 250 / 2000 * orchard_tiles) * (1 + r_inf)^(yr_set[i])
    cost_mat[i, j] <- c_subs + c_reef + c_orch
  }
  cost_mat
}
cost_mat_fun <- function(dt_list, max_year) {
  cost_mat <- matrix(NA, nrow = n_sample1, ncol = max_year)
  for (i in 1:n_sample1) cost_mat[i, ] <- dt_list[[i]][[1]][[1]]
  cost_mat
}
subs_cost1      <- subs_cost_fun(1, seq(1, 10000, 1), 1:50)
costs_D0_def_50 <- cost_mat_fun(orch_D0_def_dt50$costs_list, 50)
costs_D0_SC2_50 <- cost_mat_fun(orch_D0_SC2_dt50$costs_list, 50)
budget_diff     <- apply(costs_D0_SC2_50, 2, mean) - apply(costs_D0_def_50, 2, mean)
extra_subs      <- rep(NA, length(budget_diff))
for (i in seq_along(extra_subs)) {
  cv <- subs_cost1[i, ]; extra_subs[i] <- which(abs(cv - budget_diff[i]) == min(abs(cv - budget_diff[i])))
}
extra_subs <- c(0, extra_subs)

# =====================================================================
# STRATEGY 2: MORE RECRUITS / INCREASE SC1 CAPACITY (Rmd 5521-5548)
# =====================================================================
rest_pars <- rest_pars_def
rest_pars$lab_max        <- rep(rest_pars$lab_max, years) + extra_subs
rest_pars$lab_retain_max <- rep(0, years)
N0.o <- list(); N0.o[[1]] <- list()
N0.o[[1]][[1]] <- c(0.25 * orchard_size, 0.5 * orchard_size, rep(0, 3))
N0.o[[1]][[2]] <- rep(0, n)

message("MORE RECRUITS / SC1L (no disturbance) ...")
orch_D0_SC1L_50   <- orch_exp_fun2(dem_pars_all = all_pars_R, n_pars = n_sample1, prop_set = c(0.5), par_set2 = lambda_Rs[2], par2_name = "lambda_R", dist = F)
orch_D0_SC1L_dt5  <- full_dt_fun(orch_D0_SC1L_50, max_yr = 6,  n_pars = n_sample1, prop_set = prop_set1, par_set2 = lambda_Rs[2], par2_name = "lambda_R", annual_costs = T)
orch_D0_SC1L_dt50 <- full_dt_fun(orch_D0_SC1L_50, max_yr = 51, n_pars = n_sample1, prop_set = prop_set1, par_set2 = lambda_Rs[2], par2_name = "lambda_R", annual_costs = T)

message("MORE RECRUITS / SC1L (disturbance) ...")
orch_D3_SC1L_50   <- orch_exp_fun2(dem_pars_all = all_pars_R, n_pars = n_sample1, prop_set = c(0.5), par_set2 = lambda_Rs[2], par2_name = "lambda_R", dist = T, dist_yrs3, dist_pars_list = dist_pars_list3)
orch_D3_SC1L_dt5  <- full_dt_fun(orch_D3_SC1L_50, max_yr = 6,  n_pars = n_sample1, prop_set = prop_set1, par_set2 = lambda_Rs[2], par2_name = "lambda_R", annual_costs = T)
orch_D3_SC1L_dt50 <- full_dt_fun(orch_D3_SC1L_50, max_yr = 51, n_pars = n_sample1, prop_set = prop_set1, par_set2 = lambda_Rs[2], par2_name = "lambda_R", annual_costs = T)
rest_pars <- rest_pars_def; N0.o <- N0.o_def

# =====================================================================
# RELATIVE METRICS (Rmd 5605-5631)
# =====================================================================
relative_metrics_fun <- function(dt2, dt_def, n_sample1) {
  dt2$par_rep <- 1:n_sample1; dt_def$par_rep <- 1:n_sample1
  reef_coral <- tot_ROI <- tot_costs <- rep(NA, n_sample1)
  for (i in 1:n_sample1) {
    d0 <- dt_def[dt_def$par_rep == i, ]; d2 <- dt2[dt2$par_rep == i, ]
    reef_coral[i] <- d2$reef_cover_mean / d0$reef_cover_mean
    tot_ROI[i]    <- d2$tot_ROI_mean    / d0$tot_ROI_mean
    tot_costs[i]  <- d2$tot_costs        / d0$tot_costs
  }
  list(reef_coral = reef_coral, tot_ROI = tot_ROI, tot_costs = tot_costs)
}

# =====================================================================
# FIGURE — base R 2x2 on deep navy
# =====================================================================
pch_set  <- c(16, 17); pch_setD <- c(1, 2); pt_cex <- c(1.5, 1.25)
col_set  <- c(TEAL, CORAL)   # [1]=Increase SC1 capacity, [2]=Transplant SC2
xmax <- 90; ymax <- 6

out_png <- "presentation-figs/fig5_transplant_ocean.png"
# type="cairo": quartz applies color management that shifts #0B1F33 -> (11,23,38);
# cairo renders the exact hex so this matches the ggplot dark figures.
png(out_png, width = 1743, height = 1374, res = 190, bg = BG, type = "cairo")
par(bg = BG, fg = AXT, col.axis = TXT, col.lab = TXT, col.main = TXT, col.sub = TXT,
    cex.axis = 1.4)
layout(matrix(c(1, 2, 3, 4), nrow = 2, byrow = TRUE))
par(mar = c(0, 0.5, 0.5, 0), oma = c(5.5, 5.2, 2.2, 1))

# ---- panel a: ROI, 5yr ----
plot(c(0, xmax), c(0, ymax), type = "l", col = NA, las = 1, xlab = NA, ylab = NA, xaxt = "n")
axis(1, at = seq(0, 90, 15), labels = NA, col = AXT, col.ticks = AXT)
mtext("5 years", 3, line = 0.1, cex = 1.35, col = TXT)
mtext("a)", 3, adj = 0.075, line = -1.2, cex = 1.35, col = TXT)
mtext("Proportional change \nin total ROI", 2, line = 2.3, cex = 1.2, col = TXT)
S1 <- relative_metrics_fun(orch_D0_SC1L_dt5$dt_i, orch_D0_def_dt5$dt_i, n_sample1)
S2 <- relative_metrics_fun(orch_D0_SC2_dt5$dt_i,  orch_D0_def_dt5$dt_i, n_sample1)
drawpt <- function(S, k, pch, cex) {
  points(mean(S$reef_coral), mean(S$tot_ROI), pch = pch, col = col_set[k], cex = cex)
  arrows(mean(S$reef_coral), quantile(S$tot_ROI, .05), y1 = quantile(S$tot_ROI, .95), code = 3, angle = 90, length = .025, col = col_set[k])
  arrows(quantile(S$reef_coral, .05), mean(S$tot_ROI), x1 = quantile(S$reef_coral, .95), code = 3, angle = 90, length = .025, col = col_set[k])
}
drawpt(S1, 1, pch_set[1], pt_cex[1]); drawpt(S2, 2, pch_set[2], pt_cex[1])
abline(h = 1, lty = 2, col = GRID); abline(v = 1, lty = 2, col = GRID)
legend("topright", legend = c("Increase SC1 capacity", "Transplant SC2"), col = col_set, pch = pch_set, bty = "n", pt.cex = 1.7, cex = 1.25, text.col = TXT, inset = c(0, 0.01))
legend("topright", legend = c("No disturbance", "Disturbance"), col = AXT, pch = c(pch_set[1], pch_setD[1]), bty = "n", pt.cex = 1.7, cex = 1.25, text.col = TXT, inset = c(0, 0.30))
S1 <- relative_metrics_fun(orch_D3_SC1L_dt5$dt_i, orch_D3_def_dt5$dt_i, n_sample1)
S2 <- relative_metrics_fun(orch_D3_SC2_dt5$dt_i,  orch_D3_def_dt5$dt_i, n_sample1)
drawpt(S1, 1, pch_setD[1], pt_cex[2]); drawpt(S2, 2, pch_setD[2], pt_cex[2])

# ---- panel b: ROI, 50yr ----
plot(c(0, xmax), c(0, ymax), type = "l", col = NA, las = 1, xlab = NA, ylab = NA, xaxt = "n", yaxt = "n")
axis(1, at = seq(0, 90, 15), labels = NA, col = AXT, col.ticks = AXT)
axis(2, at = seq(0, 6, 1), labels = NA, col = AXT, col.ticks = AXT)
mtext("b)", 3, adj = 0.075, line = -1.2, cex = 1.35, col = TXT); mtext("50 years", 3, line = 0.1, cex = 1.35, col = TXT)
S1 <- relative_metrics_fun(orch_D0_SC1L_dt50$dt_i, orch_D0_def_dt50$dt_i, n_sample1)
S2 <- relative_metrics_fun(orch_D0_SC2_dt50$dt_i,  orch_D0_def_dt50$dt_i, n_sample1)
drawpt(S1, 1, pch_set[1], pt_cex[1]); drawpt(S2, 2, pch_set[2], pt_cex[1])
abline(h = 1, lty = 2, col = GRID); abline(v = 1, lty = 2, col = GRID)
S1 <- relative_metrics_fun(orch_D3_SC1L_dt50$dt_i, orch_D3_def_dt50$dt_i, n_sample1)
S2 <- relative_metrics_fun(orch_D3_SC2_dt50$dt_i,  orch_D3_def_dt50$dt_i, n_sample1)
drawpt(S1, 1, pch_setD[1], pt_cex[2]); drawpt(S2, 2, pch_setD[2], pt_cex[2])

# ---- panel c: cost, 5yr ----
ymax <- 1.5; ymin <- 0.5
drawptC <- function(S, k, pch, cex) {
  points(mean(S$reef_coral), mean(S$tot_costs), pch = pch, col = col_set[k], cex = cex)
  arrows(mean(S$reef_coral), quantile(S$tot_costs, .05), y1 = quantile(S$tot_costs, .95), code = 3, angle = 90, length = .025, col = col_set[k])
  arrows(quantile(S$reef_coral, .05), mean(S$tot_costs), x1 = quantile(S$reef_coral, .95), code = 3, angle = 90, length = .025, col = col_set[k])
}
plot(c(0, xmax), c(ymin, ymax), type = "l", col = NA, las = 1, xlab = NA, ylab = NA, xaxt = "n")
axis(1, at = seq(0, 90, 15), col = AXT, col.ticks = AXT)
mtext("Proportional change \nin total costs", 2, line = 2.5, cex = 1.2, col = TXT)
mtext("Proportional change in reef coral cover", 1, line = 3.0, cex = 1.25, outer = TRUE, col = TXT)
mtext("c)", 3, adj = 0.075, line = -1.2, cex = 1.35, col = TXT)
S1 <- relative_metrics_fun(orch_D0_SC1L_dt5$dt_i, orch_D0_def_dt5$dt_i, n_sample1)
S2 <- relative_metrics_fun(orch_D0_SC2_dt5$dt_i,  orch_D0_def_dt5$dt_i, n_sample1)
drawptC(S1, 1, pch_set[1], pt_cex[1]); drawptC(S2, 2, pch_set[2], pt_cex[1])
abline(h = 1, lty = 2, col = GRID); abline(v = 1, lty = 2, col = GRID)
S1 <- relative_metrics_fun(orch_D3_SC1L_dt5$dt_i, orch_D3_def_dt5$dt_i, n_sample1)
S2 <- relative_metrics_fun(orch_D3_SC2_dt5$dt_i,  orch_D3_def_dt5$dt_i, n_sample1)
drawptC(S1, 1, pch_setD[1], pt_cex[2]); drawptC(S2, 2, pch_setD[2], pt_cex[2])

# ---- panel d: cost, 50yr ----
plot(c(0, xmax), c(ymin, ymax), type = "l", col = NA, las = 1, xlab = NA, ylab = NA, yaxt = "n", xaxt = "n")
axis(1, at = seq(0, 90, 15), col = AXT, col.ticks = AXT)
axis(2, at = seq(0, 1.2, 0.2), labels = NA, col = AXT, col.ticks = AXT)
mtext("d)", 3, adj = 0.075, line = -1.2, cex = 1.35, col = TXT)
S1 <- relative_metrics_fun(orch_D0_SC1L_dt50$dt_i, orch_D0_def_dt50$dt_i, n_sample1)
S2 <- relative_metrics_fun(orch_D0_SC2_dt50$dt_i,  orch_D0_def_dt50$dt_i, n_sample1)
drawptC(S1, 1, pch_set[1], pt_cex[1]); drawptC(S2, 2, pch_set[2], pt_cex[1])
abline(h = 1, lty = 2, col = GRID); abline(v = 1, lty = 2, col = GRID)
S1 <- relative_metrics_fun(orch_D3_SC1L_dt50$dt_i, orch_D3_def_dt50$dt_i, n_sample1)
S2 <- relative_metrics_fun(orch_D3_SC2_dt50$dt_i,  orch_D3_def_dt50$dt_i, n_sample1)
drawptC(S1, 1, pch_setD[1], pt_cex[2]); drawptC(S2, 2, pch_setD[2], pt_cex[2])

dev.off()
cat("\nWrote", out_png, "\n")

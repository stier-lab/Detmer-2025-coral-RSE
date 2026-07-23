# fig_qext_surface.R — Quasi-extinction surface: P(A. palmata reef cover < 100 m^2 at yr 50)
#   as a joint function of (a) major-disturbance regime (frequency x severity) and
#   (b) restoration effort (reference-reef embryo collection / outplanting rate, lambda_R, 100% to reef).
#
# EXTENDS the manuscript quasi-extinction analysis in rse_new_scenario_analyses.rmd,
#   section "# Figure 2 & SM" (~lines 1707-2320): the stochastic-disturbance + random-initial-condition
#   ensemble that computes P(reef cover < 100 m^2 threshold) at year 50, plus the severity x frequency
#   heatmap block (~lines 1951-2137). Scenario logic inlined VERBATIM from that section (no _extracted
#   result scripts). Real model engine only: setup_base.R + functions.R source the real rse_funs.R
#   (rse_mod1, model_summ) + coral_demographic_funs.R.
#
# Restoration lever  = lambda_R (embryos collected from the reference reef each year; setup_base default
#                      1,255,111 = the paper's strongest "100% to reef" case), with prop_set = 1 (all lab
#                      recruits outplanted to reef = strongest reef allocation). lambda_R = 0 = no restoration.
# Disturbance lever  = dist.r survival-retention multiplier on reef survival in disturbance years
#                      (0.5 = 50% mortality, 0.2 = severe/80%, 0.1 = extreme/90%); orchard NOT hit
#                      (dist.o = 1), exactly as Fig 2 / the heatmap. Frequency = stochastic disturbance
#                      years drawn at a target MEAN return interval (Bernoulli(1/interval) per year).
#
# Run from repo root:  OCEAN_THEME=1 Rscript presentation-figs/fig_qext_surface.R
# Created: 2026-07-21

setwd(path.expand("~/Detmer-2025-coral-RSE"))
Sys.setenv(OCEAN_THEME = "1")
suppressMessages(source("presentation-figs/theme_slide.R"))
suppressMessages(source("presentation-figs/engine/setup_base.R"))  # engine + base params (sources real rse_funs.R)
suppressMessages(source("presentation-figs/engine/functions.R"))   # orch_exp_fun2 / orch_exp_fun1 (verbatim from rmd)
suppressMessages(library(tidyverse))

LOG <- function(...) cat(sprintf(...), "\n")
RESULTS_RDS <- "presentation-figs/qext_surface_results.rds"

## ============================================================================
## Shared helpers (match the rmd exactly)
## ============================================================================
# reef cover (m^2) at year 50 for one simulation object, all 5 size classes
cover50 <- function(sim_obj) {
  model_summ(model_sim = sim_obj, location = "reef", metric = "area_m2",
             n_reef = length(reef_treatments), n_orchard = length(orchard_treatments),
             n_lab = length(lab_treatments), size_classes = c(1:5))[50]
}
EXT_THRESH <- 100  # m^2 quasi-extinction threshold (rmd line 1825)

# build the dist_pars_list exactly like the rmd: dist.r (3 reef sources) + dist.o (2 orchard sources),
# NO dist.rc (recruit survival left undisturbed, as in the published Fig 2 / heatmap blocks)
make_dpl <- function(dist_yrs, sev_r, sev_o = 1) {
  nd <- length(dist_yrs)
  dm.r <- matrix(sev_r, nrow = nd, ncol = 5); dist.r <- list(dm.r, dm.r, dm.r)
  dm.o <- matrix(sev_o, nrow = nd, ncol = 5); dist.o <- list(dm.o, dm.o)
  list(dist.r = dist.r, dist.o = dist.o)
}

## ============================================================================
## STEP 3 — VALIDATION: reproduce the manuscript Fig 2 quasi-extinction endpoints
##   (verbatim from rmd lines 1711-1855: n_init random ICs, each with a random disturbance
##    frequency + severity; P = fraction of param x IC trajectories below 100 m^2 at yr 50)
## ============================================================================
run_validation <- function() {
  prop_main <- c(0.5, 1)
  lambda_Rs <- c(0, 1255111)
  n_init <- 50
  N0_50 <- N0_100 <- N0_0 <- matrix(NA, nrow = n_sample1, ncol = n_init)
  LOG("[VALIDATION] paper Fig 2 ensemble: n_init=%d ICs x %d param sets x 3 strategies ...", n_init, n_sample1)
  t0 <- Sys.time()
  set.seed(1000)
  for (i in 1:n_init) {
    N0.r <<- list(); N0.r[[1]] <<- list()
    N0.r[[1]][[1]] <<- rep(0, n)
    N0.r[[1]][[2]] <<- sample(c(0:20), 5, replace = TRUE)
    N0.r[[1]][[3]] <<- rep(0, n)
    n_dist_i  <- sample(c(1:round(years/2)), 1, replace = FALSE)
    dist_yrs_i <- sort(sample(c(1:years), n_dist_i, replace = FALSE))
    dist_sev.r <- runif(1, min = 0.001, max = 1)   # random severity, exactly as rmd
    dpl <- make_dpl(dist_yrs_i, sev_r = dist_sev.r, sev_o = 1)
    o50  <- orch_exp_fun2(all_pars_R, n_sample1, prop_main[1], lambda_Rs[2], "lambda_R", TRUE, dist_yrs_i, dpl)
    o100 <- orch_exp_fun2(all_pars_R, n_sample1, prop_main[2], lambda_Rs[2], "lambda_R", TRUE, dist_yrs_i, dpl)
    o0   <- orch_exp_fun2(all_pars_R, n_sample1, prop_main[2], lambda_Rs[1], "lambda_R", TRUE, dist_yrs_i, dpl)
    for (j in 1:n_sample1) {
      N0_50[j, i]  <- cover50(o50[[j]][[1]][[1]])
      N0_100[j, i] <- cover50(o100[[j]][[1]][[1]])
      N0_0[j, i]   <- cover50(o0[[j]][[1]][[1]])
    }
    if (i %% 10 == 0) LOG("  ...IC %d/%d", i, n_init)
  }
  N0.r <<- N0.r_def
  val <- c(
    no_restoration = mean(as.vector(N0_0)   < EXT_THRESH),
    reef_50        = mean(as.vector(N0_50)  < EXT_THRESH),
    reef_100       = mean(as.vector(N0_100) < EXT_THRESH)
  )
  LOG("[VALIDATION] elapsed %.0f s", as.numeric(Sys.time() - t0, units = "secs"))
  LOG("[VALIDATION] P(quasi-ext) no-restoration = %.3f  | 50%%-to-reef = %.3f  | 100%%-to-reef (strongest) = %.3f",
      val["no_restoration"], val["reef_50"], val["reef_100"])
  val
}

## ============================================================================
## STEP 2 — SWEEP: quasi-extinction surface over restoration x frequency x severity
## ============================================================================
run_sweep <- function() {
  ## --- grid ---
  LR_MAX     <- 1255111                                  # paper's strongest lambda_R
  rest_frac  <- c(0, 1/8, 1/4, 1/2, 1)                   # restoration effort as fraction of max
  rest_lev   <- rest_frac * LR_MAX                        # actual lambda_R values (embryos/yr)
  rest_lab   <- c("0 (none)", "157k", "314k", "628k", "1.26M (max)")
  intervals  <- c(30, 15, 10, 6, 4, 2)                   # target MEAN return interval (yr): benign -> severe
  sevs       <- c(0.50, 0.20, 0.10)                       # survival multiplier: moderate/severe/extreme
  sev_lab    <- c("Moderate (50% mortality)", "Severe (80% mortality)", "Extreme (90% mortality)")
  N_PARAM    <- n_sample1                                 # 100 bootstrapped demographic sets (FULL, no downsample)
  N_REAL     <- 20                                        # stochastic disturbance x IC realizations per cell

  LOG("[SWEEP] grid: %d restoration x %d interval x %d severity = %d cells",
      length(rest_lev), length(intervals), length(sevs), length(rest_lev)*length(intervals)*length(sevs))
  LOG("[SWEEP] per cell: %d param sets x %d realizations = %d trajectories; total model runs ~ %s",
      N_PARAM, N_REAL, N_PARAM*N_REAL,
      format(length(rest_lev)*length(intervals)*length(sevs)*N_PARAM*N_REAL, big.mark=","))

  # accumulators: below-threshold count and total, indexed [rest, interval, sev]
  below <- array(0, dim = c(length(rest_lev), length(intervals), length(sevs)))
  total <- array(0, dim = c(length(rest_lev), length(intervals), length(sevs)))

  t0 <- Sys.time()
  set.seed(2025)
  for (fi in seq_along(intervals)) {
    m <- intervals[fi]
    for (r in 1:N_REAL) {
      # random initial conditions (matched across severity x restoration within this realization)
      N0.r <<- list(); N0.r[[1]] <<- list()
      N0.r[[1]][[1]] <<- rep(0, n)
      N0.r[[1]][[2]] <<- sample(c(0:20), 5, replace = TRUE)
      N0.r[[1]][[3]] <<- rep(0, n)
      # stochastic disturbance years at target mean return interval m
      dist_yrs <- which(stats::runif(years) < 1/m)
      use_dist <- length(dist_yrs) > 0
      for (si in seq_along(sevs)) {
        dpl <- if (use_dist) make_dpl(dist_yrs, sev_r = sevs[si], sev_o = 1) else NULL
        for (li in seq_along(rest_lev)) {
          sim <- orch_exp_fun2(dem_pars_all = all_pars_R, n_pars = N_PARAM, prop_set = 1,
                               par_set2 = rest_lev[li], par2_name = "lambda_R",
                               dist = use_dist, dist_yrs = if (use_dist) dist_yrs else NULL,
                               dist_pars_list = dpl)
          cv <- vapply(1:N_PARAM, function(j) cover50(sim[[j]][[1]][[1]]), numeric(1))
          below[li, fi, si] <- below[li, fi, si] + sum(cv < EXT_THRESH)
          total[li, fi, si] <- total[li, fi, si] + length(cv)
        }
      }
    }
    LOG("  [SWEEP] interval %2d yr done (%d/%d)  elapsed %.0f s",
        m, fi, length(intervals), as.numeric(Sys.time() - t0, units = "secs"))
  }
  N0.r <<- N0.r_def
  P <- below / total

  # tidy long data frame
  df <- expand.grid(rest = seq_along(rest_lev), freq = seq_along(intervals), sev = seq_along(sevs))
  df$P             <- mapply(function(a,b,c) P[a,b,c], df$rest, df$freq, df$sev)
  df$rest_lambdaR  <- rest_lev[df$rest]
  df$rest_frac     <- rest_frac[df$rest]
  df$rest_lab      <- factor(rest_lab[df$rest], levels = rest_lab)
  df$interval_yr   <- intervals[df$freq]
  df$severity_mult <- sevs[df$sev]
  df$sev_lab       <- factor(sev_lab[df$sev], levels = sev_lab)
  LOG("[SWEEP] elapsed %.0f s total", as.numeric(Sys.time() - t0, units = "secs"))
  list(df = df, rest_lev = rest_lev, rest_lab = rest_lab, intervals = intervals,
       sevs = sevs, sev_lab = sev_lab, N_PARAM = N_PARAM, N_REAL = N_REAL)
}

## ============================================================================
## RUN (cache to RDS so re-plotting is instant)
## ============================================================================
if (file.exists(RESULTS_RDS)) {
  LOG("[CACHE] loading %s", RESULTS_RDS)
  res <- readRDS(RESULTS_RDS)
} else {
  val   <- run_validation()
  sweep <- run_sweep()
  res <- list(validation = val, sweep = sweep, date = Sys.Date())
  saveRDS(res, RESULTS_RDS)
}
val   <- res$validation
sweep <- res$sweep
df    <- sweep$df

## ---- print the full result grid as a compact table ----
LOG("\n================ RESULT GRID: P(quasi-extinction at 50 yr, cover < 100 m^2) ================")
tab <- df %>%
  mutate(interval = interval_yr) %>%
  select(sev_lab, rest_lab, interval, P) %>%
  pivot_wider(names_from = interval, values_from = P) %>%
  arrange(sev_lab, rest_lab)
print(as.data.frame(tab), digits = 2)
write.csv(df[, c("sev_lab","rest_lab","rest_lambdaR","interval_yr","severity_mult","P")],
          "presentation-figs/qext_surface_grid.csv", row.names = FALSE)
LOG("[VALIDATION endpoints] no-restoration = %.1f%%  | 100%%-to-reef strongest = %.1f%%",
    100*val["no_restoration"], 100*val["reef_100"])

## ============================================================================
## STEP 4 — FIGURE (dark "Deep Current" deck theme)
## ============================================================================
# 5-level restoration ramp: grey (none) -> slate -> teal -> gold -> amber (strongest)
REST5 <- c("0 (none)"   = "#6E7A85",
           "157k"       = "#5C88A8",
           "314k"       = "#56B4E9",
           "628k"       = "#E0B25A",
           "1.26M (max)"= "#F0A24E")
REST_LW <- c("0 (none)"=2.4, "157k"=1.5, "314k"=1.5, "628k"=1.5, "1.26M (max)"=2.6)
REST_LT <- c("0 (none)"="22", "157k"="solid", "314k"="solid", "628k"="solid", "1.26M (max)"="solid")

dplot <- df %>% mutate(Ppct = 100*P)

# direct labels for the two anchor lines, placed at the most-frequent (right) edge of the moderate panel
lab_df <- dplot %>%
  filter(sev_lab == levels(dplot$sev_lab)[1], rest_lab %in% c("0 (none)", "1.26M (max)")) %>%
  group_by(rest_lab) %>% filter(interval_yr == min(interval_yr)) %>% ungroup() %>%
  mutate(txt = ifelse(rest_lab == "0 (none)", "no restoration", "strongest\nrestoration"))

p <- ggplot(dplot, aes(x = interval_yr, y = Ppct, color = rest_lab, group = rest_lab)) +
  geom_hline(yintercept = c(25, 50), linetype = "13", color = "#3A506B", linewidth = 0.5) +
  geom_line(aes(linetype = rest_lab, linewidth = rest_lab), lineend = "round") +
  geom_point(size = 2.1) +
  facet_wrap(~ sev_lab, nrow = 1) +
  scale_color_manual(values = REST5, name = "Restoration effort  (reference-reef embryos yr⁻¹, 100% to reef)") +
  scale_linetype_manual(values = REST_LT, guide = "none") +
  scale_linewidth_manual(values = REST_LW, guide = "none") +
  scale_x_reverse(breaks = c(30, 15, 10, 6, 4, 2)) +   # left = benign (30 yr), right = frequent (2 yr)
  scale_y_continuous(limits = c(0, 100), breaks = seq(0, 100, 25),
                     expand = expansion(mult = c(0.01, 0.03))) +
  labs(x = "Mean disturbance return interval (yr)     ← less frequent      more frequent →",
       y = "P(quasi-extinction) at 50 yr  (%)",
       title = "How often can the reef be hit before restoration can't save it?") +
  guides(color = guide_legend(nrow = 1, override.aes = list(linewidth = 3, shape = NA))) +
  theme_slide(base_size = 18, legend = "bottom") +
  theme(panel.spacing = unit(1.4, "lines"),
        strip.text = element_text(color = "#F4F6F8", size = 17, face = "bold",
                                  margin = margin(b = 6, t = 2)),
        legend.title = element_text(size = 14, color = "#9DB0C2"),
        legend.text = element_text(size = 14),
        plot.title = element_text(size = 21, face = "bold", color = "#F0A24E",
                                  margin = margin(b = 10)))

# annotate the two anchor lines directly in the first (moderate) facet
p <- p + geom_text(data = lab_df,
                   aes(x = interval_yr, y = Ppct, label = txt, color = rest_lab),
                   hjust = -0.05, vjust = ifelse(lab_df$rest_lab == "0 (none)", 1.4, -0.4),
                   size = 4.4, fontface = "bold", lineheight = 0.9, show.legend = FALSE) +
  annotate("text", x = 30, y = 52.5, label = "50%", color = "#6C7F97", size = 3.6, hjust = 0, vjust = -0.2) +
  annotate("text", x = 30, y = 27.5, label = "25%", color = "#6C7F97", size = 3.6, hjust = 0, vjust = -0.2)

OUT <- "presentation-figs/img/fig_qext_surface.png"
if (!dir.exists("presentation-figs/img")) dir.create("presentation-figs/img", recursive = TRUE)
ggsave(OUT, plot = p, width = 10, height = 4, units = "in", dpi = 300, bg = OCEAN_TOK$bg)
LOG("wrote %s (3000x1200 px)", OUT)

# copy to the talk deck build folder
HUB <- path.expand("~/coral-rse-hub/talks/ocean-deck-build/img/fig_qext_surface.png")
if (!dir.exists(dirname(HUB))) dir.create(dirname(HUB), recursive = TRUE)
file.copy(OUT, HUB, overwrite = TRUE)
LOG("copied to %s", HUB)
LOG("DONE.")

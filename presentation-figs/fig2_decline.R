# fig2_decline.R — Stakes-slide trajectory (manuscript Fig 2, no-disturbance base case).
# Reef coral cover over 50 yr: no restoration (grey) vs with restoration / 100%-to-reef (coral).
# Scenario reproduced INLINE from the real analysis (rse_new_scenario_analyses.rmd, "# Figure 2 & SM",
# ~line 1707) — NO auto-extract scripts. Engine loaded from setup_base.R / functions.R (which source
# the real rse_funs.R). Run from repo root:  Rscript presentation-figs/fig2_decline.R
# Created: 2026-07-19 · Refactored off _extracted result scripts: 2026-07-20
setwd(path.expand("~/Detmer-2025-coral-RSE"))
suppressMessages(source("presentation-figs/theme_slide.R"))
suppressMessages(source("presentation-figs/engine/setup_base.R"))  # engine + params (sources real rse_funs.R)
suppressMessages(source("presentation-figs/engine/functions.R"))   # orch_exp_fun2, ts_fun
suppressMessages(library(tidyverse))

## ---- Fig 2 scenario, inlined verbatim from the rmd (no disturbance) ----
prop_main <- c(0.5, 1)              # orchard-investment strategies (0.5 = 50% reef, 1 = 100% reef)
lambda_Rs <- c(0, 1255111)          # reference-reef recruitment: 0 = no restoration, 1.26M = with restoration

N0.r <- list(); N0.r[[1]] <- list()
N0.r[[1]][[1]] <- rep(0, n)         # external recruits
N0.r[[1]][[2]] <- rep(10, n)        # start with some corals
N0.r[[1]][[3]] <- rep(0, n)

cat("running Fig 2 ensembles (", n_sample1, "param sets x 2 strategies)...\n")
orch_D0_100 <- orch_exp_fun2(dem_pars_all = all_pars_R, n_pars = n_sample1, prop_set = prop_main[2],
                             par_set2 = lambda_Rs[2], par2_name = "lambda_R", dist = F,
                             dist_yrs = NULL, dist_pars_list = NULL)   # with restoration
orch_D0_0   <- orch_exp_fun2(dem_pars_all = all_pars_R, n_pars = n_sample1, prop_set = prop_main[2],
                             par_set2 = lambda_Rs[1], par2_name = "lambda_R", dist = F,
                             dist_yrs = NULL, dist_pars_list = NULL)   # no restoration
N0.r <- N0.r_def

## ---- tidy + plot (unchanged) ----
grab <- function(sim, lab) {
  ts <- ts_fun(sim, n_pars = n_sample1, max_yr = 51, prop_choice = 1, par2_choice = 1)
  tibble(year = 2025 + 0:50, strategy = lab,
         mean = ts$reef_cover_mn, lo = ts$reef_cover_up, hi = ts$reef_cover_low)  # up=0.05, low=0.95
}
COLS2 <- c("No restoration" = DECK$mute, "With restoration" = DECK$coral)
df <- bind_rows(grab(orch_D0_0, "No restoration"), grab(orch_D0_100, "With restoration")) |>
  mutate(strategy = factor(strategy, levels = names(COLS2)))
## ---- "stakes" version: log y-axis so the quasi-extinction threshold is visible ----
FLOOR  <- 5      # m^2 axis floor (log can't show 0)
THRESH <- 100    # m^2 quasi-extinction threshold (manuscript, Fig 2b)
YTOP   <- 2200   # m^2 axis top

nr <- df$mean[df$strategy == "No restoration"]; wr <- df$mean[df$strategy == "With restoration"]
cat(sprintf("no-restoration cover m2: start %.0f  end %.0f  |  with-restoration end %.0f\n",
            nr[1], tail(nr,1), tail(wr,1)))

dfl <- df |> mutate(m = pmax(mean, FLOOR), lo2 = pmax(lo, FLOOR), hi2 = pmin(pmax(hi, FLOOR), YTOP))

p <- ggplot(dfl, aes(year, m, color = strategy, fill = strategy)) +
  # quasi-extinction danger zone + threshold
  annotate("rect", xmin = -Inf, xmax = Inf, ymin = FLOOR, ymax = THRESH, fill = DECK$coral, alpha = 0.07) +
  geom_hline(yintercept = THRESH, linetype = "21", color = DECK$coral, linewidth = 0.8) +
  annotate("text", x = 2074.5, y = 55, label = "quasi-extinction threshold  (100 m²)",
           hjust = 1, vjust = 0.5, color = DECK$coral, fontface = "bold", size = 4.6) +
  # starting-point context
  annotate("text", x = 2025.2, y = YTOP*0.94, label = "2025 start · reef already ~95% below 1980s",
           hjust = 0, vjust = 1, color = DECK$mute, fontface = "italic", size = 4.1) +
  geom_ribbon(aes(ymin = lo2, ymax = hi2), color = NA, alpha = 0.13) +
  geom_line(aes(linetype = strategy, linewidth = strategy), lineend = "round") +
  # direct line labels, placed in empty regions
  annotate("text", x = 2074.2, y = 1250, label = "with restoration",
           hjust = 1, vjust = 0.5, color = DECK$coral, fontface = "bold", size = 6.0) +
  annotate("text", x = 2049, y = 23, label = "no restoration",
           hjust = 0.5, vjust = 0.5, color = DECK$mute, fontface = "bold", size = 6.0) +
  scale_color_manual(values = COLS2, guide = "none") +
  scale_fill_manual(values = COLS2, guide = "none") +
  scale_linetype_manual(values = c("No restoration" = "22", "With restoration" = "solid"), guide = "none") +
  scale_linewidth_manual(values = c("No restoration" = 1.4, "With restoration" = 2.1), guide = "none") +
  scale_x_continuous(breaks = seq(2025, 2075, 25), expand = expansion(mult = c(0.01, 0.02))) +
  scale_y_log10(breaks = c(10, 100, 1000), labels = scales::comma, expand = expansion(mult = c(0.02, 0.06))) +
  coord_cartesian(ylim = c(FLOOR, YTOP), clip = "off") +
  labs(x = "Year", y = expression("Reef coral cover  ("*m^2*", log scale)")) +
  theme_slide(base_size = 21)

save_slide(p, "fig2_decline.png", w = 8.9, h = 4.7)
cat("done fig2\n")

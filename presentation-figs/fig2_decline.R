# fig2_decline.R — slide re-plot of "without intervention the population declines"
# (manuscript Fig 2a). Reef coral cover over 50 yr, no disturbance, three strategies:
# no restoration (grey, stays collapsed) / 50% to reef (teal) / 100% to reef (coral).
# ~100 parameter sets each. Run from repo root: Rscript presentation-figs/fig2_decline.R

setwd(path.expand("~/Detmer-2025-coral-RSE"))
suppressMessages(source("presentation-figs/theme_slide.R"))
suppressMessages(source("presentation-figs/_extracted/setup_base.R"))
suppressMessages(source("presentation-figs/_extracted/functions.R"))
suppressMessages(source("presentation-figs/_extracted/fig2_ctx.R"))
cat("running 3 trajectory ensembles (100 sets each)...\n")
suppressMessages(source("presentation-figs/_extracted/fig2_traj.R"))

library(tidyverse)
grab <- function(sim, lab) {
  ts <- ts_fun(sim, n_pars = n_sample1, max_yr = 51, prop_choice = 1, par2_choice = 1)
  tibble(year = 2025 + 0:50, strategy = lab,
         mean = ts$reef_cover_mn, lo = ts$reef_cover_up, hi = ts$reef_cover_low)  # up=0.05, low=0.95
}
# two-line contrast for a clean slide: no restoration vs with restoration (100% case)
COLS2 <- c("No restoration" = DECK$mute, "With restoration" = DECK$coral)
df <- bind_rows(
  grab(orch_D0_0,   "No restoration"),
  grab(orch_D0_100, "With restoration")
) |> mutate(strategy = factor(strategy, levels = names(COLS2)))
ycap <- 1.6  # focus on the means + lower band (upper parameter tail is extreme)

p <- ggplot(df, aes(year, mean/1000, color = strategy, fill = strategy)) +
  geom_ribbon(aes(ymin = lo/1000, ymax = pmin(hi/1000, ycap)), color = NA, alpha = 0.14) +
  geom_line(linewidth = 2.4, lineend = "round") +
  scale_color_manual(values = COLS2, guide = "none") +
  scale_fill_manual(values = COLS2, guide = "none") +
  scale_x_continuous(breaks = seq(2025, 2075, 25), expand = expansion(mult = c(0.01, 0.02))) +
  scale_y_continuous(expand = expansion(mult = c(0.01, 0.06))) +
  coord_cartesian(ylim = c(0, ycap), clip = "off") +
  annotate("text", x = 2029, y = 1.15, hjust = 0, vjust = 1,
           label = "with restoration", color = DECK$coral, fontface = "bold", size = 6.4) +
  annotate("text", x = 2052, y = 0.15, hjust = 0, vjust = 0,
           label = "no restoration", color = "grey45", fontface = "bold", size = 6) +
  labs(x = "Year", y = expression("Reef coral cover  ("*10^3~m^2*")")) +
  theme_slide(base_size = 21)

save_slide(p, "fig2_decline.png", w = 7.6, h = 5.1)
cat("done fig2\n")

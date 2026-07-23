# fig_where_invest.R — Q1 INVESTMENT result (real Detmer model output, cached sweep).
# The non-obvious finding: orchard investment's reef-cover cost is large at 5 yr but
# small by 50 yr. Reef cover NORMALIZED within each parameter set to the all-reef
# strategy (reef cover as % of all-reef), so the two horizons are comparable and the
# convergence is honest & clearly labeled. Median + IQR across 100 parameter sets.
# Created: 2026-07-20
setwd(path.expand("~/Detmer-2025-coral-RSE"))
suppressMessages(source("presentation-figs/theme_slide.R"))
suppressMessages(library(tidyverse))
S <- readRDS("/tmp/orch_sweep.rds"); lr <- S$lr[2]
CC <- DECK$coral; MU <- DECK$mute; INK <- DECK$ink

rel <- function(dt, h){
  d <- dt |> filter(par2 == lr) |> select(par_rep, prop_out, reef = reef_cover_mean)
  base <- d |> filter(prop_out == 1) |> select(par_rep, ref = reef)   # all-reef, within param set
  d |> left_join(base, by = "par_rep") |>
    mutate(r = reef/ref, to_orch = 1 - prop_out) |>
    group_by(to_orch) |>
    summarise(med = median(r, na.rm = TRUE),
              lo = quantile(r, .25, na.rm = TRUE),
              hi = quantile(r, .75, na.rm = TRUE), .groups = "drop") |>
    mutate(horizon = h)
}
lv <- c("5 YEARS", "50 YEARS")
df <- bind_rows(rel(S$dt5, "5 YEARS"), rel(S$dt50, "50 YEARS")) |>
  mutate(horizon = factor(horizon, levels = lv))

ann <- tibble(horizon = factor(c("5 YEARS", "50 YEARS"), levels = lv),
              x = c(1.0, 0.5), y = c(0.97, 0.40), hj = c(1, 0.5),
              txt = c("orchard investment carries\nan upfront reef-cover cost",
                      "by 50 yr, reef outcomes\nlargely converge (~85% of all-reef)"))

p <- ggplot(df, aes(to_orch, med)) +
  geom_ribbon(aes(ymin = lo, ymax = hi), fill = CC, alpha = 0.16) +
  geom_line(color = CC, linewidth = 2.7, lineend = "round") +
  facet_wrap(~horizon) +
  geom_text(data = ann, aes(x, y, label = txt, hjust = hj), inherit.aes = FALSE,
            vjust = 1, size = 4.4, fontface = "bold", color = INK, lineheight = .9) +
  scale_x_continuous(breaks = c(0, .5, 1),
                     labels = c("all\nreef", "50:50", "all\norchard"),
                     expand = expansion(mult = c(.07, .07))) +
  scale_y_continuous(labels = scales::percent, limits = c(0, 1.03),
                     expand = expansion(mult = c(0, .01))) +
  labs(x = NULL, y = "reef coral cover\n(% of all-reef strategy)") +
  theme_slide(base_size = 18) +
  theme(strip.text = element_text(face = "bold", size = 16, color = INK),
        axis.text.x = element_text(face = "bold", lineheight = .9),
        panel.spacing = unit(1.9, "lines"))

save_slide(p, "fig_where_invest.png", w = 8.8, h = 3.55)
cat("done fig_where_invest\n")

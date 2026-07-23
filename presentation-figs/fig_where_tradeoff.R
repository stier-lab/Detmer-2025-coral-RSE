# fig_where_tradeoff.R — Q1 allocation trade-off (real Detmer model output, cached sweep).
# Two panels across the allocation continuum (all reef -> all orchard):
#   (a) reef coral cover NOW (5 yr) falls as more goes to the orchard
#   (b) protected broodstock (orchard adult area) rises as more goes to the orchard
# Honest real m^2 units, separate y-scales (no false crossing / no single optimum).
# Created: 2026-07-19
setwd(path.expand("~/Detmer-2025-coral-RSE"))
suppressMessages(source("presentation-figs/theme_slide.R"))
suppressMessages(library(tidyverse))
S <- readRDS("/tmp/orch_sweep.rds"); lr <- S$lr[2]
CC <- DECK$coral; TT <- DECK$teal; INK <- DECK$ink; MU <- DECK$mute

d5 <- S$dt5 |> filter(par2 == lr) |> group_by(prop_out) |>
  summarise(`Reef coral cover (m²)  ↓`     = mean(reef_cover_mean,   na.rm = TRUE),
            `Protected broodstock (m²)  ↑` = mean(orch_function_mean, na.rm = TRUE),
            .groups = "drop") |>
  mutate(to_orch = 1 - prop_out) |>
  pivot_longer(-c(prop_out, to_orch), names_to = "metric", values_to = "val") |>
  mutate(metric = factor(metric, levels = c("Reef coral cover (m²)  ↓",
                                            "Protected broodstock (m²)  ↑")))
MET <- c("Reef coral cover (m²)  ↓" = CC, "Protected broodstock (m²)  ↑" = TT)

p <- ggplot(d5, aes(to_orch, val, color = metric)) +
  geom_line(linewidth = 2.5, lineend = "round") +
  facet_wrap(~metric, scales = "free_y") +
  scale_color_manual(values = MET, guide = "none") +
  scale_x_continuous(breaks = c(0, .5, 1), labels = c("all\nreef", "50:50", "all\norchard"),
                     expand = expansion(mult = c(.08, .08))) +
  scale_y_continuous(expand = expansion(mult = c(.03, .10))) +
  labs(x = NULL, y = NULL) +
  theme_slide(base_size = 19) +
  theme(strip.text = element_text(face = "bold", size = 15, color = INK),
        axis.text.x = element_text(face = "bold", lineheight = .9))

save_slide(p, "fig_where_tradeoff.png", w = 9.0, h = 2.95)
cat("done fig_where_tradeoff\n")

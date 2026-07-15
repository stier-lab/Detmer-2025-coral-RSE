# fig3_tradeoff.R — slide re-plot of "the nursery-reef tradeoff depends on time"
# (manuscript Fig 3b). Reef coral cover vs total ROI across the reef-vs-nursery
# allocation, at 5 years (sharp tradeoff) and 50 years (fades). No disturbance.
# Slower: ~100 sets x 11 props x 2 lambda_R. Run: Rscript presentation-figs/fig3_tradeoff.R

setwd(path.expand("~/Detmer-2025-coral-RSE"))
suppressMessages(source("presentation-figs/theme_slide.R"))
suppressMessages(source("presentation-figs/_extracted/setup_base.R"))
suppressMessages(source("presentation-figs/_extracted/functions.R"))
suppressMessages(source("presentation-figs/_extracted/fig2_ctx.R"))   # prop_main, lambda_Rs
cat("running orchard-investment sweep (100 sets x 11 props x 2 lambda_R)...\n")
suppressMessages(source("presentation-figs/_extracted/fig3_data.R"))  # orch_D0_all_dt5 / _dt50

library(tidyverse)
summ <- function(dt, horizon) {
  dt |> filter(par2 == lambda_Rs[2]) |>                     # with reference-reef larval supply
    group_by(prop_out) |>
    summarise(cover = mean(reef_cover_mean, na.rm = TRUE),
              roi   = mean(tot_ROI_mean,   na.rm = TRUE), .groups = "drop") |>
    mutate(horizon = horizon)
}
d <- bind_rows(summ(orch_D0_all_dt5, "5 years"),
               summ(orch_D0_all_dt50, "50 years")) |>
  mutate(horizon = factor(horizon, levels = c("5 years", "50 years")))

# scale each metric to its max WITHIN each horizon, so each panel shows the SHAPE:
# 5 yr = steep opposing lines (sharp tradeoff); 50 yr = flat lines (tradeoff faded).
d <- d |>
  group_by(horizon) |>
  mutate(`Reef coral cover` = cover / max(cover),
         `Total ROI`        = roi   / max(roi)) |>
  ungroup() |>
  pivot_longer(c(`Reef coral cover`, `Total ROI`), names_to = "metric", values_to = "rel")

MET <- c("Reef coral cover" = DECK$coral, "Total ROI" = DECK$teal)

p <- ggplot(d, aes(prop_out, rel, color = metric)) +
  geom_line(linewidth = 2.1, lineend = "round") +
  facet_wrap(~horizon) +
  scale_color_manual(values = MET, name = NULL) +
  scale_x_continuous(breaks = c(0, 0.5, 1), labels = c("0", "0.5", "1"),
                     expand = expansion(mult = c(0.02, 0.02))) +
  scale_y_continuous(breaks = c(0, 0.5, 1), expand = expansion(mult = c(0.03, 0.06))) +
  labs(x = "Proportion outplanted to reef", y = "Relative value") +
  theme_slide(base_size = 20, legend = "bottom") +
  theme(strip.text = element_text(size = 21, face = "bold", color = DECK$ink,
                                  margin = margin(b = 4)),
        panel.spacing = unit(1.4, "lines"),
        legend.position = "bottom",
        legend.text = element_text(size = 17))

save_slide(p, "fig3_tradeoff.png", w = 8.4, h = 5.0)
cat("done fig3\n")

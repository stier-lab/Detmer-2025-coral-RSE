# fig_survival_size.R — slide figure for the DATA SYNTHESIS methods:
# "survival climbs steeply with colony size" (the mechanistic reason larger outplants win).
# Re-plots the synthesis output survival_by_size.csv in the deck palette.
# Run: Rscript presentation-figs/fig_survival_size.R

setwd(path.expand("~/Detmer-2025-coral-RSE"))
suppressMessages(source("presentation-figs/theme_slide.R"))
suppressMessages(library(tidyverse))

d <- read.csv("../Detmer-2025-coral-parameters/06_analysis/output/survival_by_size.csv") |>
  mutate(sc = factor(size_class, levels = paste0("SC", 1:5)),
         idx = as.integer(sc),
         hero = size_class == "SC2")
rng <- c("0–10", "10–100", "100–900", "900–4,000", ">4,000")

p <- ggplot(d, aes(idx, survival)) +
  geom_line(linewidth = 1.8, color = DECK$coral, alpha = 0.55, lineend = "round") +
  geom_errorbar(aes(ymin = ci_lower, ymax = ci_upper), width = 0.10,
                linewidth = 1.1, color = DECK$coral) +
  geom_point(aes(size = hero), color = DECK$coral) +
  scale_size_manual(values = c(`FALSE` = 4.6, `TRUE` = 7), guide = "none") +
  scale_x_continuous(breaks = 1:5, labels = paste0("SC", 1:5),
                     sec.axis = dup_axis(labels = rng, name = expression("colony area  (cm"^2*")")),
                     expand = expansion(add = 0.35)) +
  scale_y_continuous(labels = scales::percent_format(accuracy = 1),
                     limits = c(0.45, 1.0), expand = expansion(mult = c(0.02, 0.05))) +
  annotate("text", x = 1.05, y = 0.50, hjust = 0, label = "small colonies\ndie",
           color = "grey40", size = 5, lineheight = 0.9, fontface = "italic") +
  annotate("text", x = 4.95, y = 0.985, hjust = 1, label = "large colonies\npersist",
           color = "grey40", size = 5, lineheight = 0.9, fontface = "italic") +
  labs(x = NULL, y = "Annual survival") +
  theme_slide(base_size = 21) +
  theme(axis.title.x.top = element_text(size = 15, color = "grey40", margin = margin(b = 6)),
        axis.text.x.top  = element_text(size = 13, color = "grey45"),
        panel.grid.major.x = element_blank())

save_slide(p, "fig_survival_size.png", w = 7.8, h = 5.2)
cat("survival by size:\n"); print(d[, c("size_class","survival")])

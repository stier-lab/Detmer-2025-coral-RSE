# fig_bottleneck.R — the survival bottleneck: annual survival by life stage.
# Newly-outplanted recruits die at extreme rates; survival jumps once colonies
# pass ~10 cm2 (the SC1 boundary). Fully backed by stored synthesis data.
# Run from repo root:  Rscript presentation-figs/fig_bottleneck.R

setwd(path.expand("~/Detmer-2025-coral-RSE"))
suppressMessages(source("presentation-figs/theme_slide.R"))
suppressMessages(library(tidyverse))

DATA <- "../Detmer-2025-coral-parameters"

## SC1-SC5 survival synthesis
size <- readr::read_csv(file.path(DATA, "06_analysis/output/survival_by_size.csv"),
                        show_col_types = FALSE)
## newly-outplanted recruit survival (microscopic settlers, ~0.006 cm2)
rec  <- readRDS(file.path(DATA, "parameter_lists/recruit_surv_pars.rds"))
s_rec <- rec$s_recruit; rec_lo <- rec$s_recruit_ci[1]; rec_hi <- rec$s_recruit_ci[2]
cat("recruit survival:", round(s_rec,3), " SC:", round(size$survival,2), "\n")

df <- tibble(
  stage = c("Recruit", size$size_class),
  surv  = c(s_rec, size$survival),
  lo    = c(rec_lo, size$ci_lower),
  hi    = c(rec_hi, size$ci_upper)
) |>
  mutate(stage = factor(stage, levels = c("Recruit", paste0("SC", 1:5))),
         danger = stage == "Recruit")

lab <- c("Recruit" = "New\nrecruit",
         "SC1" = "SC1\n<10 cm²", "SC2" = "SC2\n10–100", "SC3" = "SC3\n100–900",
         "SC4" = "SC4\n900–4,000", "SC5" = "SC5\n>4,000")

p <- ggplot(df, aes(stage, surv, fill = danger)) +
  geom_col(width = 0.70) +
  geom_errorbar(aes(ymin = lo, ymax = hi), width = 0.18, color = "grey40", linewidth = 0.6) +
  geom_text(aes(y = hi, label = scales::percent(surv, accuracy = 1)),
            vjust = -0.6, size = 5.6, fontface = "bold",
            color = ifelse(df$danger, DECK$coral, "grey30")) +
  # threshold marker between Recruit/SC1 and the rest (~10 cm2)
  annotate("segment", x = 1.5, xend = 1.5, y = 0, yend = 1.02,
           linetype = "22", color = DECK$mute, linewidth = 0.7) +
  annotate("text", x = 1.5, y = 1.05, label = "the bottleneck",
           color = DECK$coral, fontface = "bold", size = 5.6, hjust = 0.5) +
  scale_fill_manual(values = c(`TRUE` = DECK$coral, `FALSE` = DECK$teal), guide = "none") +
  scale_x_discrete(labels = lab) +
  scale_y_continuous(labels = scales::percent, limits = c(0, 1.12),
                     breaks = seq(0, 1, 0.25), expand = expansion(mult = c(0.01, 0))) +
  labs(x = NULL, y = "Annual survival") +
  theme_slide(base_size = 20) +
  theme(panel.grid.major.x = element_blank(),
        axis.text.x = element_text(size = 15, lineheight = 0.9))

save_slide(p, "fig_bottleneck.png", w = 8.0, h = 5.1)
cat("done bottleneck\n")

# fig4_size.R — slide re-plot of "an intermediate outplant size wins" (manuscript Fig 4a).
# Reef coral cover over 50 yr when outplanting a fixed AREA of a single size class each year.
# SC2 (intermediate) highlighted; others muted. Deterministic — runs in seconds.
# Run from the repo root:  Rscript presentation-figs/fig4_size.R

setwd(path.expand("~/Detmer-2025-coral-RSE"))
suppressMessages(source("presentation-figs/theme_slide.R"))

## --- reproduce the model data (Raine's code, extracted verbatim) ---
suppressMessages(source("presentation-figs/_extracted/setup_base.R"))
suppressMessages(source("presentation-figs/_extracted/fig4_data.R"))

cat("mod_area dim:", dim(mod_area), " max cover:", round(max(mod_area)), "m2\n")

## --- tidy: reef cover (m2) x year x size class ---
library(tidyverse)
n_out <- c("SC1"=2500000,"SC2"=227273,"SC3"=25000,"SC4"=5102,"SC5"=1340)
df <- as.data.frame(mod_area) |>
  setNames(paste0("SC", 1:5)) |>
  mutate(year = 2025 + (row_number() - 1)) |>
  pivot_longer(-year, names_to = "sc", values_to = "cover")

## SC2 is the story: bold coral; others muted, thin
df <- df |> mutate(hero = sc == "SC2")
lab_pos <- df |> group_by(sc) |> slice_max(year) |> ungroup()

p <- ggplot(df, aes(year, cover/1000, color = sc, linewidth = hero, group = sc)) +
  geom_line(lineend = "round") +
  scale_color_manual(values = SC_COLS, guide = "none") +
  scale_linewidth_manual(values = c(`FALSE` = 1.0, `TRUE` = 2.6), guide = "none") +
  scale_x_continuous(breaks = seq(2025, 2075, 25), expand = expansion(mult = c(0.01, 0.10))) +
  scale_y_continuous(expand = expansion(mult = c(0.01, 0.06))) +
  # direct labels at the right end
  annotate("text", x = 2076, y = max(df$cover[df$sc=="SC2"])/1000, label = "SC2",
           hjust = 0, color = DECK$coral, fontface = "bold", size = 7.5) +
  annotate("text", x = 2076, y = max(df$cover[df$sc=="SC3"])/1000 + 7, label = "SC3",
           hjust = 0, color = "grey45", size = 5) +
  annotate("text", x = 2076, y = 4, label = "SC1, 4, 5",
           hjust = 0, color = "grey55", size = 4.6) +
  labs(x = "Year", y = expression("Reef coral cover  ("*10^3~m^2*")")) +
  theme_slide(base_size = 21) +
  theme(plot.margin = margin(14, 62, 12, 12)) +
  coord_cartesian(clip = "off")

save_slide(p, "fig4_size.png", w = 7.6, h = 5.1)
cat("done fig4\n")

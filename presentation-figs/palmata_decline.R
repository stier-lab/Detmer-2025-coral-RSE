# palmata_decline.R — "a century of decline" stakes chart for the Ocean deck.
# Proportion of Caribbean reef sites where *A. palmata* is DOMINANT (amber) vs
# merely PRESENT (grey), Pleistocene -> 2005-11. Dominance falls ~78% -> ~6%.
#
# PROVENANCE: there was NO source R script for the deck's palmata_decline.png
# (it was a pre-made light-cream image with no generator). The category values
# below are digitized from that existing figure so the DARK version reproduces
# it faithfully. The underlying data trace to the Caribbean *A. palmata*
# dominance/occurrence decline synthesis (sensu Aronson & Precht; the "78% -> 6%"
# dominance collapse used in the FUNDEMAR RSE stakes slide). Re-point `dom`/`pres`
# at the primary source table if the exact series is recovered.
# Run: Rscript presentation-figs/palmata_decline.R
# Created dark (Deep Current) for the Ocean Recoveries deck: 2026-07-21

setwd(path.expand("~/Detmer-2025-coral-RSE"))
Sys.setenv(OCEAN_THEME = "1")
suppressMessages(source("presentation-figs/theme_slide.R"))
suppressMessages({library(ggplot2); library(dplyr); library(tidyr)})

eras <- c("Pleistocene","Holocene","1500–1949","1950–59","1960–69",
          "1970–79","1980–84","1985–89","1990–94","1995–99",
          "2000–04","2005–11")
pres <- c(0.94,0.92,0.91,0.86,0.64,0.73,0.59,0.49,0.29,0.24,0.155,0.185)  # present at reefs
dom  <- c(0.78,0.855,0.785,0.49,0.45,0.61,0.42,0.23,0.105,0.14,0.04,0.06)  # dominant

GREY  <- "#8CA0B3"   # "present" series (faint slate)
CORAL <- "#F0A24E"   # "dominant" series (amber highlight)
INK   <- "#F4F6F8"

df <- tibble(era = factor(eras, levels = eras), Present = pres, Dominant = dom) |>
  pivot_longer(-era, names_to = "series", values_to = "p")

p <- ggplot(df, aes(era, p, group = series, color = series)) +
  geom_line(aes(linewidth = series), lineend = "round") +
  geom_point(aes(size = series)) +
  scale_color_manual(values = c(Present = GREY, Dominant = CORAL), guide = "none") +
  scale_linewidth_manual(values = c(Present = 1.4, Dominant = 2.6), guide = "none") +
  scale_size_manual(values = c(Present = 2.4, Dominant = 3.6), guide = "none") +
  scale_x_discrete(expand = expansion(add = c(0.6, 0.9))) +
  scale_y_continuous(limits = c(0, 1.0), breaks = seq(0, 1, 0.25),
                     labels = sprintf("%.2f", seq(0, 1, 0.25)),
                     expand = expansion(mult = c(0.01, 0.03))) +
  # endpoint call-outs
  annotate("text", x = 1.05, y = 0.905, label = "78%", color = CORAL,
           fontface = "bold", size = 9, hjust = 0) +
  annotate("text", x = 12, y = 0.135, label = "6%", color = CORAL,
           fontface = "bold", size = 9, hjust = -0.35) +
  # series labels (direct)
  annotate("text", x = 8.0, y = 0.62, label = "Present at reefs", color = GREY,
           fontface = "italic", size = 6.2, hjust = 0.5) +
  annotate("text", x = 5.5, y = 0.325, label = "Dominant", color = CORAL,
           fontface = "bold", size = 6.6, hjust = 0.5) +
  # white-band disease event marker (arrow up to the 1970-79 dominance bump)
  annotate("segment", x = 6, xend = 6, y = 0.42, yend = 0.55,
           color = INK, linewidth = 0.6,
           arrow = grid::arrow(length = unit(0.13, "inches"), type = "closed")) +
  annotate("text", x = 6, y = 0.245, label = "white-band disease", color = "#AEC0D0",
           size = 5.0, hjust = 0.5) +
  labs(x = NULL, y = "Proportion of reef sites") +
  coord_cartesian(clip = "off") +
  theme_slide(base_size = 21) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, vjust = 1, size = 15),
        panel.grid.major.x = element_blank(),
        plot.margin = margin(14, 22, 10, 12))

save_slide(p, "palmata_decline.png", w = 6.6, h = 4.7)
cat("done palmata_decline\n")

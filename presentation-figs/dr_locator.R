# dr_locator.R — Caribbean locator for the "Meet FUNDEMAR" slide.
# DARK "Deep Current" theme: navy ocean, muted-grey land, coral-pinned Bayahibe.
# Dominican Republic highlighted in deck amber/coral; Bayahibe labelled in light text.
# Run: Rscript presentation-figs/dr_locator.R
# Restyled dark for the Ocean Recoveries deck: 2026-07-21

setwd(path.expand("~/Detmer-2025-coral-RSE"))
suppressMessages({library(rnaturalearth); library(sf); library(ggplot2); library(dplyr)})

# ---- Deep Current palette (exact deck hex) ----
SEA    <- "#0B1F33"   # navy ocean = plot/panel background
LAND   <- "#2A3D52"   # muted desaturated land fill
LANDB  <- "#3A5169"   # land edges
CORAL  <- "#F0A24E"   # amber/coral highlight (DR + Bayahibe pin)
INK    <- "#F4F6F8"   # near-white primary text
MUTE   <- "#AEC0D0"   # muted secondary text
FAINT  <- "#8CA0B3"   # faint tertiary text

w <- ne_countries(scale="medium", returnclass="sf")
w$isDR <- w$admin == "Dominican Republic"
bay <- data.frame(lon=-68.84, lat=18.37)   # Bayahibe, SE Dominican Republic

p <- ggplot(w) +
  geom_sf(aes(fill=isDR), color=LANDB, linewidth=0.25) +
  scale_fill_manual(values=c(`FALSE`=LAND, `TRUE`=CORAL), guide="none") +
  geom_point(data=bay, aes(lon,lat), color=INK, size=4.6) +
  geom_point(data=bay, aes(lon,lat), color=CORAL, size=1.7) +
  annotate("text", x=-67.7, y=16.9, label="Bayahibe", hjust=0, vjust=1,
           size=6, color=INK, fontface="bold") +
  annotate("segment", x=-68.7, xend=-67.9, y=18.1, yend=17.2, color=MUTE, linewidth=0.5) +
  annotate("text", x=-81.5, y=25.4, label="Caribbean", hjust=0, size=5, color=FAINT, fontface="italic") +
  coord_sf(xlim=c(-89,-59.5), ylim=c(9.3,26.6), expand=FALSE) +
  theme_void() +
  theme(panel.background=element_rect(fill=SEA, color=NA),
        plot.background=element_rect(fill=SEA, color=NA),
        plot.margin=margin(2,2,2,2))

ggsave("presentation-figs/dr_locator.png", p, width=5.6, height=3.15, units="in", dpi=300, bg=SEA)
cat("wrote presentation-figs/dr_locator.png\n")

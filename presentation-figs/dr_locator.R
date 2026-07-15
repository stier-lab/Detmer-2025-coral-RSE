# dr_locator.R — clean Caribbean locator for the "Meet FUNDEMAR" slide.
# Dominican Republic highlighted in the deck coral; Bayahibe pinned. Deck palette.
# Run: Rscript presentation-figs/dr_locator.R

setwd(path.expand("~/Detmer-2025-coral-RSE"))
suppressMessages({library(rnaturalearth); library(sf); library(ggplot2); library(dplyr)})

DARK<-"#0C3A44"; CORAL<-"#D9603A"; INK<-"#1E2A2E"
w <- ne_countries(scale="medium", returnclass="sf")
w$isDR <- w$admin == "Dominican Republic"
bay <- data.frame(lon=-68.84, lat=18.37)   # Bayahibe, SE Dominican Republic

p <- ggplot(w) +
  geom_sf(aes(fill=isDR), color="white", linewidth=0.25) +
  scale_fill_manual(values=c(`FALSE`="#CBD4D3", `TRUE`=CORAL), guide="none") +
  geom_point(data=bay, aes(lon,lat), color=DARK, size=4.6) +
  geom_point(data=bay, aes(lon,lat), color="white", size=1.7) +
  annotate("text", x=-67.7, y=16.9, label="Bayahibe", hjust=0, vjust=1,
           size=6, color=DARK, fontface="bold") +
  annotate("segment", x=-68.7, xend=-67.9, y=18.1, yend=17.2, color=DARK, linewidth=0.5) +
  annotate("text", x=-81.5, y=25.4, label="Caribbean", hjust=0, size=5, color="#7C8A88", fontface="italic") +
  coord_sf(xlim=c(-89,-59.5), ylim=c(9.3,26.6), expand=FALSE) +
  theme_void() +
  theme(panel.background=element_rect(fill="#E7EFF0", color="#CBD4D3"),
        plot.background=element_rect(fill="white", color=NA),
        plot.margin=margin(2,2,2,2))

ggsave("presentation-figs/dr_locator.png", p, width=5.6, height=3.15, units="in", dpi=300, bg="white")
cat("wrote presentation-figs/dr_locator.png\n")

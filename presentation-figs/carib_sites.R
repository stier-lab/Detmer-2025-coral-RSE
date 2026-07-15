# carib_sites.R — deck-styled Caribbean synthesis site map for the ICRS slide.
# Wide aspect (~1.95:1) so it FILLS the slide slot (the paper's Fig1a letterboxed).
# One point per region, sized by sample size; Dominican Republic (FUNDEMAR) highlighted.
# Reads the synthesis CSVs directly (does NOT touch Raine's figure code).
# Run: Rscript presentation-figs/carib_sites.R

suppressMessages({
  library(rnaturalearth); library(sf); library(ggplot2)
  library(dplyr); library(ggrepel); library(scales)
})

PAR <- path.expand("~/Detmer-2025-coral-parameters")
DARK<-"#0C3A44"; CORAL<-"#D9603A"; TEAL<-"#2E8C86"; INK<-"#1E2A2E"; MUTE<-"#66736F"

ind  <- read.csv(file.path(PAR,"05_data/standardized/apal_surv_ind.csv"))
summ <- read.csv(file.path(PAR,"05_data/standardized/apal_surv_summ.csv"))

# per-region coordinates + observation counts, from both data tiers
t1 <- ind  |> filter(!is.na(latitude), !is.na(longitude)) |>
  group_by(region) |> summarise(lat=mean(latitude), lon=mean(longitude), n=n(), .groups="drop")
t2 <- summ |> filter(!is.na(latitude), !is.na(longitude)) |>
  group_by(region) |> summarise(lat=mean(latitude), lon=mean(longitude),
                                n=sum(n_initial, na.rm=TRUE), .groups="drop")

reg <- bind_rows(t1, t2) |>
  mutate(region = dplyr::recode(region, "USVI"="US Virgin Islands")) |>
  group_by(region) |>
  summarise(lat=weighted.mean(lat, n), lon=weighted.mean(lon, n), n=sum(n), .groups="drop") |>
  filter(n > 0)

reg$isDR <- grepl("Dominican", reg$region)
reg$lab  <- ifelse(reg$isDR, "Dominican Republic\n(FUNDEMAR)", reg$region)
cat(sprintf("regions: %d   total obs: %s\n", nrow(reg), comma(sum(reg$n))))

world <- ne_countries(scale="medium", returnclass="sf")
xlim <- c(-91, -58); ylim <- c(11, 27.2)

p <- ggplot() +
  geom_rect(aes(xmin=xlim[1], xmax=xlim[2], ymin=ylim[1], ymax=ylim[2]),
            fill="#E7EFF0") +
  geom_sf(data=world, fill="#CBD4D3", color="white", linewidth=0.3) +
  # non-focal regions
  geom_point(data=subset(reg,!isDR), aes(lon,lat,size=n),
             shape=21, fill=TEAL, color=DARK, stroke=0.6, alpha=0.9) +
  # Dominican Republic (FUNDEMAR) — highlighted
  geom_point(data=subset(reg,isDR), aes(lon,lat,size=n),
             shape=21, fill=CORAL, color=DARK, stroke=1.0) +
  geom_text_repel(data=subset(reg,!isDR), aes(lon,lat,label=region),
                  size=4.1, color=INK, family="Helvetica",
                  segment.color=MUTE, segment.size=0.3,
                  min.segment.length=0, box.padding=0.5, max.overlaps=20, seed=7) +
  geom_text_repel(data=subset(reg,isDR), aes(lon,lat,label=lab),
                  size=4.6, fontface="bold", color=CORAL, family="Helvetica",
                  segment.color=CORAL, segment.size=0.5,
                  nudge_y=-2.1, nudge_x=1.0, box.padding=0.6, seed=7) +
  scale_size_area(name="Colony\nobservations", max_size=13,
                  breaks=c(100,1000,4000), labels=comma) +
  coord_sf(xlim=xlim, ylim=ylim, expand=FALSE, datum=NA) +
  guides(size=guide_legend(override.aes=list(fill=TEAL, color=DARK))) +
  theme_void(base_family="Helvetica") +
  theme(
    legend.position=c(0.085,0.24), legend.justification=c(0,0.5),
    legend.title=element_text(size=10.5, color=INK, face="bold"),
    legend.text=element_text(size=9.5, color=INK),
    legend.key.height=unit(13,"pt"), legend.background=element_blank(),
    plot.background=element_rect(fill="white", color=NA),
    plot.margin=margin(4,6,4,6))

ggsave("presentation-figs/carib_sites.png", p, width=10.0, height=5.15,
       units="in", dpi=300, bg="white")
cat("wrote presentation-figs/carib_sites.png\n")

# carib_sites.R — deck-styled Caribbean synthesis site map for the ICRS slide.
# DARK "Deep Current" theme: navy ocean, muted-grey land, teal bubbles, coral DR.
# Wide aspect (~1.95:1) so it FILLS the slide slot (the paper's Fig1a letterboxed).
# One point per region, sized by sample size; Dominican Republic (FUNDEMAR) highlighted.
# Reads the synthesis CSVs directly (does NOT touch Raine's figure code).
# Run: Rscript presentation-figs/carib_sites.R
# Restyled dark for the Ocean Recoveries deck: 2026-07-21

suppressMessages({
  library(rnaturalearth); library(sf); library(ggplot2)
  library(dplyr); library(ggrepel); library(scales)
})

PAR <- path.expand("~/Detmer-2025-coral-parameters")
# ---- Deep Current palette (exact deck hex) ----
SEA   <- "#0B1F33"   # navy ocean = plot background
LAND  <- "#2A3D52"   # muted desaturated land fill
LANDB <- "#3A5169"   # land edges
CORAL <- "#F0A24E"   # amber/coral highlight (DR / FUNDEMAR)
TEAL  <- "#56B4E9"   # secondary series (bubbles)
INK   <- "#F4F6F8"   # near-white primary text
MUTE  <- "#AEC0D0"   # muted secondary text / label leaders
FAINT <- "#8CA0B3"   # faint tertiary text
STROKE<- "#AEC0D0"   # bubble outline (light, reads on navy)

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

# Explicit directional label nudges (deg) — fan the crowded eastern trio
# (USVI/BVI/Virgin Gorda) and the Jamaica/Navassa pair into open ocean.
NX <- c("Mexican Caribbean"=-2.0,"Dry Tortugas"=-3.2,"Cuba"=-1.5,"Florida Keys"=-0.6,
        "Bahamas"=2.8,"Jamaica"=-2.6,"Navassa"=0.4,"Curacao"=-1.6,"Puerto Rico"=1.4,
        "US Virgin Islands"=4.0,"British Virgin Islands"=4.4,"Virgin Gorda"=6.2)
NY <- c("Mexican Caribbean"=2.0,"Dry Tortugas"=1.6,"Cuba"=-2.4,"Florida Keys"=2.6,
        "Bahamas"=1.6,"Jamaica"=-2.4,"Navassa"=-2.9,"Curacao"=-1.4,"Puerto Rico"=-3.9,
        "US Virgin Islands"=-2.6,"British Virgin Islands"=1.4,"Virgin Gorda"=3.4)
reg$nx <- unname(NX[reg$region]); reg$ny <- unname(NY[reg$region])

world <- ne_countries(scale="medium", returnclass="sf")
xlim <- c(-91, -56); ylim <- c(11, 27.2)

p <- ggplot() +
  geom_rect(aes(xmin=xlim[1], xmax=xlim[2], ymin=ylim[1], ymax=ylim[2]),
            fill=SEA) +
  geom_sf(data=world, fill=LAND, color=LANDB, linewidth=0.3) +
  # non-focal regions
  geom_point(data=subset(reg,!isDR), aes(lon,lat,size=n),
             shape=21, fill=TEAL, color=STROKE, stroke=0.6, alpha=0.9) +
  # Dominican Republic (FUNDEMAR) — highlighted
  geom_point(data=subset(reg,isDR), aes(lon,lat,size=n),
             shape=21, fill=CORAL, color=INK, stroke=1.0) +
  geom_text_repel(data=subset(reg,!isDR), aes(lon,lat,label=region),
                  nudge_x=subset(reg,!isDR)$nx, nudge_y=subset(reg,!isDR)$ny,
                  size=5.4, color=INK, family="Helvetica",
                  segment.color=MUTE, segment.size=0.3, force=0.8, force_pull=0.5,
                  min.segment.length=0, box.padding=0.6, point.padding=0.35,
                  max.overlaps=Inf, seed=7) +
  geom_text_repel(data=subset(reg,isDR), aes(lon,lat,label=lab),
                  size=6.0, fontface="bold", color=CORAL, family="Helvetica",
                  segment.color=CORAL, segment.size=0.5, lineheight=0.9,
                  nudge_y=-2.7, nudge_x=-1.2, box.padding=0.7, seed=7) +
  scale_size_area(name="Colony\nobservations", max_size=13,
                  breaks=c(100,1000,4000), labels=comma) +
  coord_sf(xlim=xlim, ylim=ylim, expand=FALSE, datum=NA) +
  guides(size=guide_legend(override.aes=list(fill=TEAL, color=STROKE))) +
  theme_void(base_family="Helvetica") +
  theme(
    legend.position=c(0.085,0.24), legend.justification=c(0,0.5),
    legend.title=element_text(size=13.5, color=INK, face="bold"),
    legend.text=element_text(size=12.5, color=MUTE),
    legend.key.height=unit(16,"pt"), legend.background=element_blank(),
    panel.background=element_rect(fill=SEA, color=NA),
    plot.background=element_rect(fill=SEA, color=NA),
    plot.margin=margin(4,6,4,6))

ggsave("presentation-figs/carib_sites.png", p, width=10.0, height=5.15,
       units="in", dpi=300, bg=SEA)
cat("wrote presentation-figs/carib_sites.png\n")

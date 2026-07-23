# fig3_frontier.R — the reef-vs-nursery tradeoff as a Pareto frontier that COLLAPSES
# with time. x = reef cover, y = total ROI (each relative to its horizon's best), one
# point per allocation. 5 yr = taut diagonal (must choose); 50 yr = pulled into the
# "have both" corner (tradeoff gone). No disturbance. Run: Rscript presentation-figs/fig3_frontier.R
setwd(path.expand("~/Detmer-2025-coral-RSE"))
suppressMessages(source("presentation-figs/theme_slide.R"))
suppressMessages(source("presentation-figs/fig_where_data.R"))  # engine + real Fig 3 sweep + lambda_Rs (was _extracted extracts)
suppressMessages(library(tidyverse))

summ <- function(dt,h) dt |> filter(par2==lambda_Rs[2]) |> group_by(prop_out) |>
  summarise(cover=mean(reef_cover_mean,na.rm=T), roi=mean(tot_ROI_mean,na.rm=T), .groups="drop") |>
  mutate(cover=cover/max(cover), roi=roi/max(roi), horizon=h)          # per-horizon normalize -> compare shapes
d <- bind_rows(summ(orch_D0_all_dt5,"5 years"), summ(orch_D0_all_dt50,"50 years")) |>
  mutate(horizon=factor(horizon, levels=c("5 years","50 years")))
COL <- c("5 years"=DECK$coral, "50 years"=DECK$teal)
ends <- d |> group_by(horizon) |> filter(prop_out %in% c(0,1)) |> ungroup()

p <- ggplot(d, aes(cover, roi, color=horizon)) +
  # ideal "have both" corner
  annotate("point", x=1, y=1, shape=21, size=6, stroke=1.1, fill="white", color="grey55") +
  annotate("text", x=1, y=1.045, label="ideal: have both", hjust=1, vjust=0,
           size=4.3, color="grey45", fontface="italic") +
  geom_path(linewidth=2.3, lineend="round") +
  geom_point(size=3.2) +
  # horizon labels (direct, off the lines)
  annotate("text", x=.30, y=.90, label="5 years", color=DECK$coral, size=6.6, fontface="bold", hjust=0) +
  annotate("text", x=.86, y=.46, label="50 years", color=DECK$teal, size=6.6, fontface="bold", hjust=1) +
  # allocation orientation
  annotate("text", x=.04, y=.985, label="← all to nursery", color="grey40", size=4.1, hjust=0, vjust=1) +
  annotate("text", x=1.0, y=.115, label="all to reef →", color="grey40", size=4.1, hjust=1, vjust=1) +
  scale_color_manual(values=COL, guide="none") +
  scale_x_continuous(limits=c(0,1.02), breaks=c(0,.5,1), expand=expansion(mult=c(.03,.02))) +
  scale_y_continuous(limits=c(0,1.10), breaks=c(0,.5,1), expand=expansion(mult=c(.02,.0))) +
  labs(x="Reef coral cover  (relative to best)", y="Total ROI  (relative to best)") +
  theme_slide(base_size=20)
save_slide(p, "fig3_frontier.png", w=7.8, h=5.5)
cat("done frontier\n")

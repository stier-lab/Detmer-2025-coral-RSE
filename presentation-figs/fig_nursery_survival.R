# fig_nursery_survival.R — simple 2-bar motivator for Q1: small corals survive far better
# reared in the nursery (~84%, synthesis SC1) than on FUNDEMAR's own field tiles (~1%).
# Created: 2026-07-20
setwd(path.expand("~/Detmer-2025-coral-RSE"))
suppressMessages(source("presentation-figs/theme_slide.R"))
suppressMessages(library(tidyverse))
CC<-DECK$coral; TT<-DECK$teal; INK<-DECK$ink; MU<-DECK$mute

L1<-"On FUNDEMAR's\nfield tiles"; L2<-"Reared in\nthe nursery"
d <- tibble(where=factor(c(L1,L2),levels=c(L1,L2)), surv=c(0.009,0.84), lab=c("~1%","~84%"))

p <- ggplot(d, aes(where, surv, fill=where)) +
  geom_col(width=0.60) +
  geom_text(aes(label=lab, color=where), vjust=-0.5, size=11, fontface="bold", show.legend=FALSE) +
  scale_fill_manual(values=setNames(c(CC,TT),c(L1,L2)), guide="none") +
  scale_color_manual(values=setNames(c(CC,TT),c(L1,L2)), guide="none") +
  scale_y_continuous(labels=scales::percent, limits=c(0,0.98), breaks=seq(0,0.75,.25),
                     expand=expansion(mult=c(0,.04))) +
  labs(x=NULL, y="Annual survival of small corals") +
  theme_slide(base_size=20) +
  theme(panel.grid.major.x=element_blank(),
        axis.text.x=element_text(size=17, face="bold", lineheight=0.92))

save_slide(p, "fig_nursery_survival.png", w=5.7, h=5.0)
cat("done fig_nursery_survival\n")

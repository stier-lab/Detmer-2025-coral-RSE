# fig_survival_regression.R — annual survival vs colony size, fitted from the RAW
# individual-colony records (Detmer-2025-coral-parameters, apal_surv_ind.csv, n=7,802),
# NOT the summarized size-class means. Pooled proportional-hazards regression:
# cloglog(died) = spline(log10 size) + log(interval) offset -> annual survival. Pooled (not (1|study))
# so the fitted line describes the pooled data shown as dots; a study-adjusted GLMM floats ~15pp above
# them because mid-size colonies come mostly from low-survival studies (Neely 2022, Pausch 2018).
# Recruit (settler) point from recruit_surv_pars.rds (separate source, n=16,479).
setwd(path.expand("~/Detmer-2025-coral-RSE"))
suppressMessages(source("presentation-figs/theme_slide.R"))
suppressMessages({library(tidyverse); library(splines)})
DATA <- path.expand("~/Detmer-2025-coral-parameters")

d <- readr::read_csv(file.path(DATA,"05_data/standardized/apal_surv_ind.csv"), show_col_types=FALSE) |>
  filter(!is.na(size_cm2), size_cm2>0, !is.na(survived), !is.na(time_interval_yr), time_interval_yr>0) |>
  mutate(died = 1L - as.integer(survived), logsize = log10(size_cm2))

# pooled cloglog regression of ANNUAL survival vs size (offset annualizes to t=1)
m <- glm(died ~ ns(logsize, 3) + offset(log(time_interval_yr)), family=binomial("cloglog"), data=d)
gx <- tibble(logsize=seq(log10(1), log10(120000), length=260), time_interval_yr=1)
pr <- predict(m, newdata=gx, type="link", se.fit=TRUE)   # eta = cloglog(P die) at t=1
gx <- gx |> mutate(size=10^logsize, surv=exp(-exp(pr$fit)),
                   lo=exp(-exp(pr$fit+1.96*pr$se.fit)), hi=exp(-exp(pr$fit-1.96*pr$se.fit)))

## raw data, binned (~annual observations) — the data behind the curve
bins <- d |> filter(time_interval_yr>=0.8, time_interval_yr<=1.3) |>
  mutate(bin=ntile(logsize,12)) |> group_by(bin) |>
  summarise(size=10^mean(logsize), surv=mean(survived), n=n(), .groups="drop")

## recruit / settler survival (microscopic, separate source)
rec <- readRDS(file.path(DATA,"parameter_lists/recruit_surv_pars.rds"))
rec_df <- tibble(size=0.008, surv=rec$s_recruit, lo=rec$s_recruit_ci[1], hi=rec$s_recruit_ci[2])
cat(sprintf("curve @1cm2 %.0f%%  @10 %.0f%%  @100 %.0f%%  @1000 %.0f%%  @10000 %.0f%% | recruit %.0f%%\n",
  100*gx$surv[which.min(abs(gx$size-1))],100*gx$surv[which.min(abs(gx$size-10))],
  100*gx$surv[which.min(abs(gx$size-100))],100*gx$surv[which.min(abs(gx$size-1000))],
  100*gx$surv[which.min(abs(gx$size-10000))],100*rec_df$surv))

CC<-DECK$coral; TL<-DECK$teal; INK<-DECK$ink; MU<-DECK$mute
scb <- c(10,100,900,4000)                 # SC boundaries
sclab <- tibble(x=c(3.2,31.6,300,1900,25000), lab=c("SC1","SC2","SC3","SC4","SC5"))

p <- ggplot() +
  # unmeasured size gap: no size-resolved survival data between settlers and the smallest censused colony
  annotate("rect", xmin=0.013, xmax=1, ymin=-0.02, ymax=1.10,
           fill=if(exists("OCEAN_TOK")&&OCEAN_TOK$ocean) "#17293D" else "#DBE1E0", alpha=0.7) +
  annotate("text", x=0.115, y=0.86, label="no size-resolved\ndata", color="#AEC0D0", fontface="italic", size=5.2, lineheight=0.86) +
  # size-class boundary guides + labels
  geom_vline(xintercept=scb, linetype="dotted", color="#CBD3D1", linewidth=0.5) +
  geom_text(data=sclab, aes(x=x, y=1.055, label=lab), size=5.0, fontface="bold", color="#AEC0D0") +
  # regression: fit + 95% CI ribbon
  geom_ribbon(data=gx, aes(size, ymin=lo, ymax=hi), fill=TL, alpha=0.15) +
  geom_line(data=gx, aes(size, surv), color=TL, linewidth=2.3, lineend="round") +
  # raw binned data (point area ~ n)
  geom_point(data=bins, aes(size, surv, size=n), color=TL, alpha=0.55, stroke=0) +
  scale_size_area(max_size=7, guide="none") +
  # recruit point (separate source)
  geom_errorbar(data=rec_df, aes(size, ymin=lo, ymax=hi), width=0.18, color=CC, linewidth=0.9) +
  geom_point(data=rec_df, aes(size, surv), color=CC, size=3.4) +
  annotate("text", x=0.0052, y=0.255, label="new recruit\n(settler) ~2.7%", color=CC, fontface="bold", size=5.3, lineheight=0.9, hjust=0) +
  annotate("text", x=0.0052, y=0.13, label="n = 16,479 · 3 studies", color="#AEC0D0", fontface="bold", size=4.4, hjust=0) +
  # the bottleneck: the survival cliff between settler (~3%) and the smallest colony (~60%)
  annotate("segment", x=0.011, xend=0.78, y=rec_df$surv, yend=rec_df$surv, color=CC, linetype="dotted", linewidth=0.6) +
  annotate("segment", x=0.78, xend=0.78, y=rec_df$surv+0.02, yend=0.575, color=CC, linewidth=1.2,
           arrow=arrow(ends="last", length=unit(0.12,"in"), type="closed")) +
  annotate("text", x=0.60, y=0.37, label="the\nbottleneck", color=CC, fontface="bold", size=5.8, hjust=1, lineheight=0.88) +
  scale_x_log10(breaks=c(0.01,1,100,10000), labels=c("0.01","1","100","10,000"),
                limits=c(0.004,140000), expand=expansion(mult=c(0.02,0.02))) +
  scale_y_continuous(labels=scales::percent, limits=c(-0.02,1.10), breaks=seq(0,1,0.25),
                     expand=expansion(mult=c(0.01,0))) +
  labs(x=expression("Colony size  ("*cm^2*", log scale)"), y="Annual survival") +
  theme_slide(base_size=21) +
  theme(panel.grid.minor=element_blank())

save_slide(p, "fig_survival_regression.png", w=10.4, h=5.2)
cat("done\n")

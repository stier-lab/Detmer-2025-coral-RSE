# fig_invest_time.R — allocation story (manuscript Fig 3 / Q2) as a TIME series, 2 stacked panels.
# TOP: orchard stock fills to capacity (~2036) then overflows — the mechanism.
# BOTTOM: reef cover of the half-to-orchard strategy as % of the all-to-reef strategy —
#   dips (short-term tradeoff) then recovers (long-term convergence), tracking the orchard fill.
# Source of truth: rse_new_scenario_analyses.rmd "# Figure 3 & SM". Real model, no extracts.
setwd(path.expand("~/Detmer-2025-coral-RSE"))
suppressMessages(source("presentation-figs/theme_slide.R"))
suppressMessages(source("presentation-figs/engine/setup_base.R"))
suppressMessages(source("presentation-figs/engine/functions.R"))
suppressMessages({library(tidyverse); library(patchwork)})

LR <- 1255111
N0.r <- list(); N0.r[[1]] <- list()
N0.r[[1]][[1]] <- rep(0, n); N0.r[[1]][[2]] <- rep(10, n); N0.r[[1]][[3]] <- rep(0, n)
sim_reef <- orch_exp_fun2(dem_pars_all=all_pars_R, n_pars=n_sample1, prop_set=1,   par_set2=LR, par2_name="lambda_R", dist=F, dist_yrs=NULL, dist_pars_list=NULL)
sim_half <- orch_exp_fun2(dem_pars_all=all_pars_R, n_pars=n_sample1, prop_set=0.5, par_set2=LR, par2_name="lambda_R", dist=F, dist_yrs=NULL, dist_pars_list=NULL)
N0.r <- N0.r_def
ts_reef <- ts_fun(sim_reef, n_pars=n_sample1, max_yr=51, prop_choice=1, par2_choice=1)
ts_half <- ts_fun(sim_half, n_pars=n_sample1, max_yr=51, prop_choice=1, par2_choice=1)

yr <- 2025:2075
orch <- ts_half$orch_fun_mn
full_year <- yr[which(orch >= 0.95*max(orch,na.rm=TRUE))[1]]
rel <- pmin(100*ts_half$reef_cover_mn/ts_reef$reef_cover_mn, 100)
dip_year <- yr[which.min(rel)]
cat(sprintf("orchard full ~%d | reef rel: start %.0f%%, min %.0f%% (yr %d), end %.0f%%\n",
            full_year, rel[1], min(rel), dip_year, tail(rel,1)))

VL <- function() annotate("segment", x=full_year, xend=full_year, y=-Inf, yend=Inf, linetype="21", color=DECK$mute, linewidth=0.7)
XSC <- scale_x_continuous(breaks=seq(2025,2075,25), limits=c(2025,2077), expand=expansion(mult=c(0.01,0.02)))

# LEFT — the single reef story: cover as % of the all-to-reef strategy; dip then recover
d_r <- tibble(year=yr, pct=rel)
p_reef <- ggplot(d_r, aes(year, pct)) + VL() +
  geom_hline(yintercept=100, linetype="22", color=DECK$mute, linewidth=0.7) +
  annotate("text", x=2026.5, y=100, hjust=0, vjust=-0.5, color=DECK$mute, fontface="italic", size=4.2, label="all-to-reef benchmark (100%)") +
  annotate("text", x=full_year+0.8, y=91, hjust=0, vjust=0.5, color=DECK$mute, fontface="italic", size=4.0,
           label=paste0("orchard fills (~",full_year,") → reef recovers")) +
  geom_line(color=DECK$coral, linewidth=2.7, lineend="round") +
  annotate("point", x=dip_year, y=min(rel), color=DECK$coral, size=2.9) +
  annotate("text", x=dip_year+1, y=min(rel)-4, hjust=0, vjust=1, color=DECK$ink, fontface="bold", size=4.9,
           label=paste0("worst gap:\nreef at ", round(min(rel)), "% of all-to-reef")) +
  annotate("text", x=2074, y=tail(rel,1)-4, hjust=1, vjust=1, color=DECK$ink, fontface="bold", size=4.9,
           label=paste0(round(tail(rel,1)), "% of all-to-reef\nby year 50")) +
  XSC + scale_y_continuous(limits=c(0,112), breaks=seq(0,100,25), labels=function(x) paste0(x,"%"), expand=c(0,0)) +
  labs(x="Year", y="Reef cover  (% of all-to-reef)") +
  theme_slide(base_size=20)

# ---- RIGHT — year-50 cost + total coral: the ROI point as "same budget, more coral" ----
cost_at <- function(sim, h=51){ v <- numeric(n_sample1)
  for(i in 1:n_sample1) v[i] <- metrics_dt_fun(sim[[i]][[1]][[1]], h)$tot_costs
  median(v, na.rm=TRUE) }
cost_reef <- cost_at(sim_reef); cost_half <- cost_at(sim_half)
reef50_a <- tail(ts_reef$reef_cover_mn,1); orch50_a <- tail(ts_reef$orch_fun_mn,1)
reef50_h <- tail(ts_half$reef_cover_mn,1); orch50_h <- tail(ts_half$orch_fun_mn,1)
tot_a <- reef50_a+orch50_a; tot_h <- reef50_h+orch50_h
cat(sprintf("cost 50yr: allreef $%.2fM half $%.2fM (%.0f%%) | total coral: allreef %.0f half %.0f (%.1fx)\n",
    cost_reef/1e6, cost_half/1e6, 100*cost_half/cost_reef, tot_a, tot_h, tot_h/tot_a))

SL <- c("All to\nreef","Half to\norchard")
d_bar <- tibble(strat=factor(rep(SL,2), levels=SL),
                part =factor(c("Reef","Reef","Orchard","Orchard"), levels=c("Orchard","Reef")),
                cover=c(reef50_a, reef50_h, orch50_a, orch50_h))
costs  <- tibble(strat=factor(SL, levels=SL), tot=c(tot_a, tot_h),
                 lab=paste0("$", sprintf("%.1f", c(cost_reef,cost_half)/1e6), "M"))
p_bars <- ggplot(d_bar, aes(strat, cover, fill=part)) +
  geom_col(width=0.66, color="white", linewidth=0.5) +
  geom_text(data=costs, aes(strat, tot, label=lab), inherit.aes=FALSE, vjust=-0.7, fontface="bold", size=4.3, color=DECK$ink) +
  annotate("text", x=1.5, y=max(costs$tot)*1.16, label="≈ same budget", fontface="italic", color=DECK$mute, size=4.2) +
  scale_fill_manual(values=c(Orchard=DECK$teal, Reef=DECK$coral), name=NULL) +
  scale_y_continuous(expand=expansion(mult=c(0,0.22))) +
  labs(x=NULL, y=expression("Total living coral, yr 50  ("*m^2*")")) +
  theme_slide(base_size=19) +
  theme(legend.position="top", legend.direction="horizontal", legend.margin=margin(0,0,-2,0),
        panel.grid.major.x=element_blank())

p <- (p_reef | p_bars) + plot_layout(widths=c(1.55,1)) & theme(plot.background=element_rect(fill=OCEAN_TOK$bg, color=NA))
save_slide(p, "fig_invest_time.png", w=12.4, h=4.4)
cat("done fig_invest_time (reef % + cost/coral)\n")

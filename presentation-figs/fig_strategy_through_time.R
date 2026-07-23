# Slide 15 "THE STRATEGY THROUGH TIME" — deck-styled orchard/reef trajectory.
# NEW (closed-loop / "future RSE") analysis: runs the V2 policy-aware model
# (rse-v2/, proven bit-identical to Raine's rse_mod1 with policy=NULL) with the
# capacity-expansion + grow-out-harvest policy, on the CANONICAL real parameters.
# Styled to the ICRS deck (theme_slide + DECK palette: reef = coral headline, orchard = teal).
#
# Run from the Detmer-2025-coral-RSE repo root:
#   Rscript presentation-figs/fig_strategy_through_time.R
# then: cp presentation-figs/fig_strategy_through_time.png \
#          ~/coral-rse-hub/talks/icrs-deck-build/img/

setwd("/Users/adrianstier/Detmer-2025-coral-RSE")
RNGkind("Mersenne-Twister","Inversion","Rejection")
suppressMessages({library(ggplot2); library(patchwork)})
source("coral_demographic_funs.R"); source("rse_funs.R")
source("presentation-figs/theme_slide.R")
source("rse-v2/fixtures/make_fixtures.R"); source("rse-v2/R/rse_state.R")
source("rse-v2/R/rse_policy.R"); source("rse-v2/R/rse_mod1_v2.R")

YEARS <- 80; STORM <- 45
p <- fixture_canonical(); p$rest_pars$orchard_yield <- 0.72; p$rest_pars$lab_max <- 1200
osize <- p$rest_pars$orchard_size; A_mids <- p$A_mids; p$years <- YEARS
reef_m2 <- p$rest_pars$reef_areas/10000
p$lab_pars$s0 <- p$lab_pars$s0[1:YEARS,,drop=FALSE]; p$lab_pars$s1 <- p$lab_pars$s1[1:YEARS,,drop=FALSE]
p$dist_yrs <- STORM
p$dist_effects.r <- list(lapply(seq_along(p$N0.r[[1]]),function(rr) list(c("survival"))))
p$dist_pars.r <- list(lapply(seq_along(p$N0.r[[1]]),function(rr) dist_pars_fun(dist_yrs=STORM,p$dist_effects.r[[1]][[rr]],
  dist_surv0=list(p$surv_pars.r[[1]][[rr]]*0.3), dist_surv_rc0=list(p$surv_pars.rc[[1]][[rr]]*0.3),
  dist_Tmat0=NULL,dist_Fmat0=NULL,dist_fec0=NULL)))
p$dist_effects.o <- list(lapply(seq_along(p$N0.o[[1]]),function(rr) list(c("survival"))))
p$dist_pars.o <- list(lapply(seq_along(p$N0.o[[1]]),function(rr) dist_pars_fun(dist_yrs=STORM,p$dist_effects.o[[1]][[rr]],
  dist_surv0=list(p$surv_pars.o[[1]][[rr]]*0.3), dist_Tmat0=NULL,dist_Fmat0=NULL,dist_fec0=NULL)))

policy <- policy_F(list(F=0.3, grow_out_sc=2, orchard_size=osize, orchard_inflow=1,
                        harvest_n=500, init_cap=60, expand_tiles_per_yr=120, target_cap=osize))
sim <- do.call(rse_mod1_v2, c(p, list(policy=policy)))
yr <- 1:YEARS; cap <- orchard_capacity_trajectory(policy, YEARS)
sm <- function(x){ y<-x; for(i in 1:4) y<-as.numeric(stats::filter(c(y[1],y,y[length(y)]),rep(1/3,3)))[2:(length(y)+1)]; y }
brood <- sm(sapply(yr,function(t) sum(sapply(seq_along(sim$orchard_pops[[1]]),function(rr) sum(sim$orchard_pops[[1]][[rr]][3:5,t])))))
cover <- sm(model_summ(sim,"reef","area_m2",1,1,length(p$lab_treatments))[1:YEARS])
GUIDE <- which(cap>=osize)[1]; yr_out <- { w<-which(sim$trans_colonies_tot[1:YEARS]>0); if(length(w)) min(w) else 8 }

TEAL<-DECK$teal; CORAL<-DECK$coral; INK<-DECK$ink
oc <- OCEAN_TOK$ocean
G15<-if(oc)"#E6EDF3" else "grey15"; G25<-if(oc)"#CFDAE6" else "grey25"; G30<-if(oc)"#B9C6D4" else "grey30"
G35<-if(oc)"#AEBECD" else "grey35"; G55<-if(oc)"#5E7183" else "grey55"
th <- theme_slide(base_size=20) + theme(plot.margin=margin(3,10,2,8),
        plot.title=element_text(size=20, face="bold", color=INK))
gl <- function() geom_vline(xintercept=GUIDE, linetype=3, color=G55, linewidth=0.8)
ARR<-arrow(length=unit(8,"pt"),type="closed")
ICE2 <- "#AEC0D0"
cal <- function(x,y,l,col,sz=6.3,hj=0) annotate("text",x=x,y=y,label=l,color=col,fontface=2,size=sz,hjust=hj,lineheight=0.9)
ld  <- function(x,y,xe,ye,col=G35) annotate("curve",x=x,y=y,xend=xe,yend=ye,curvature=0.25,arrow=ARR,color=col,linewidth=0.8)

p1 <- ggplot() +
  geom_ribbon(data=data.frame(year=yr,y=brood),aes(year,ymin=0,ymax=y),fill=TEAL,alpha=0.85) +
  geom_line(data=data.frame(year=yr,y=cap),aes(year,y),color=INK,linewidth=1.1) + gl() +
  cal(27,1620,"self-sufficient in\na few years",ICE2,6.5,0) + ld(26,1440,10,760) +
  cal(GUIDE+1.2,2770,"orchard ready ~yr 20",G25,6.0) +
  cal(52,560,"broodstock","white",6.6) +
  scale_y_continuous(limits=c(0,2900),breaks=c(0,1000,2000)) + scale_x_continuous(breaks=c(0,10,20,40,60,80)) +
  labs(title="THE ORCHARD  (the engine)", y="Colonies", x=NULL) + coord_cartesian(xlim=c(1,YEARS),expand=FALSE) + th

ry <- max(cover)*1.34
p2 <- ggplot() +
  geom_ribbon(data=data.frame(year=yr,y=cover),aes(year,ymin=0,ymax=y),fill=CORAL,alpha=0.22) +
  geom_line(data=data.frame(year=yr,y=cover),aes(year,y),color=CORAL,linewidth=1.9) + gl() +
  cal(20,ry*0.90,"the reef takes\n~40 years to fill",CORAL,6.3) + ld(27,ry*0.78,40,cover[40]+12) +
  cal(3,ry*0.56,"outplanting\nbegins",G25,6.0,0) + ld(9,ry*0.49,yr_out,cover[yr_out]+7) +
  # disturbance: clean dashed event marker + label, arrows off the data
  annotate("segment",x=STORM,xend=STORM,y=0,yend=ry*0.84,linetype="dashed",color=G30,linewidth=1.0) +
  cal(STORM+1,ry*0.93,"storm, yr 45",G15,6.0,0) +
  cal(50,ry*0.76,"orchard restocks →\nreef recovers",ICE2,6.2,0) + ld(58,ry*0.68,62,cover[62]+10,CORAL) +
  annotate("segment",x=77,xend=77,y=0,yend=cover[77],color=CORAL,linewidth=0.8) +
  cal(75.5,cover[77]*0.5,"bare reef →\n~5% cover",ICE2,6.1,1) +
  scale_y_continuous(name="Reef coral cover (m²)",limits=c(0,ry),sec.axis=sec_axis(~./reef_m2*100,name="% reef")) +
  scale_x_continuous(breaks=c(0,10,20,40,60,80)) +
  labs(title="THE REEF  (the outcome)", x="Year") +
  coord_cartesian(xlim=c(1,YEARS),expand=FALSE) + th

fig <- p1/p2 + plot_layout(heights=c(0.8,1.2)) & theme(plot.background=element_rect(fill=OCEAN_TOK$bg, color=NA))
OUTDIR <- if(oc) "presentation-figs/ocean" else "presentation-figs"; if(oc && !dir.exists(OUTDIR)) dir.create(OUTDIR, recursive=TRUE)
ggsave(file.path(OUTDIR, if(oc) "fig_strategy_time.png" else "fig_strategy_through_time.png"), fig, width=8.8, height=5.5, units="in", dpi=300, bg=OCEAN_TOK$bg)
cat(sprintf("cover max %.0f m2 = %.1f%% of reef | guide yr %d | outplant yr %d\n", max(cover), 100*max(cover)/reef_m2, GUIDE, yr_out))
cat("wrote presentation-figs/fig_strategy_through_time.png\n")

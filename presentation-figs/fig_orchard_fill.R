# fig_orchard_fill.R — "How long to a FUNCTIONING orchard (spawn source), while
# still outplanting to the reef?"  Real model output (orch_exp_fun2 sweep).
# y = orchard embryo production (model_summ metric="production" = $orchard_rep).
# Thresholds: 2e6 spawn self-sufficiency (spawn_target); 1.255e6 wild-reef eq (lambda_R);
#             90% of orchard's own long-run capacity (all-orchard plateau).
# Created: 2026-07-19
setwd(path.expand("~/Detmer-2025-coral-RSE"))
suppressMessages(source("presentation-figs/theme_slide.R"))
suppressMessages(source("presentation-figs/engine/setup_base.R"))
suppressMessages(source("presentation-figs/engine/functions.R"))
prop_main <- c(0.5, 1); lambda_Rs <- c(0, 1255111)  # inlined (was _extracted/fig2_ctx.R)
suppressMessages(library(tidyverse))

CC<-DECK$coral; TT<-DECK$teal; GG<-DECK$gold; INK<-DECK$ink; MU<-DECK$mute

## ---- run a focused sweep: 5 allocations, real lambda_R -------------------
MY_PROPS <- c(0, 0.25, 0.50, 0.75, 1.0)   # prop_out = fraction of recruits sent to REEF
cat("running orchard-fill sweep (", n_sample1, "param sets x", length(MY_PROPS), "allocations)...\n")
S <- orch_exp_fun2(dem_pars_all = all_pars_R, n_pars = n_sample1,
                   prop_set = MY_PROPS, par_set2 = lambda_Rs, par2_name = "lambda_R")
saveRDS(list(S=S, props=MY_PROPS), "/tmp/orch_fill.rds")

nR<-length(reef_treatments); nO<-length(orchard_treatments); nL<-length(lab_treatments)
LR <- which(lambda_Rs == 1255111)         # real reference-reef index

# mean per-year trajectory (across param sets) of a model_summ metric, for allocation k
traj <- function(k, metric, sc=NULL){
  M <- sapply(1:n_sample1, function(i){
    sim <- S[[i]][[LR]][[k]]
    if(is.null(sc)) model_summ(sim,"orchard",metric,nR,nO,nL)
    else            model_summ(sim,"orchard",metric,nR,nO,nL,size_classes=sc)
  })
  rowMeans(M, na.rm=TRUE)
}
YRS <- length(traj(1,"production")); yr <- 0:(YRS-1)

# tidy: production (embryos/yr) and standing area (m2) per allocation over time
prod_by_k <- lapply(seq_along(MY_PROPS), function(k) traj(k,"production"))
area_by_k <- lapply(seq_along(MY_PROPS), function(k) traj(k,"area_m2"))          # all sizes (tank fill)
rep_by_k  <- lapply(seq_along(MY_PROPS), function(k) traj(k,"area_m2",c(4,5)))   # mature SC4-5 area

reef_pct <- MY_PROPS*100
alloc_lab <- paste0(round((1-MY_PROPS)*100),"% to orchard")

D <- map_dfr(seq_along(MY_PROPS), function(k) tibble(
  yr=yr, prop_out=MY_PROPS[k], reef_pct=reef_pct[k],
  alloc=factor(alloc_lab[k], levels=alloc_lab),
  prod=prod_by_k[[k]], area=area_by_k[[k]], reparea=rep_by_k[[k]]))

## ---- thresholds ----------------------------------------------------------
T_self <- 2000000            # spawn_target: orchard self-sufficient
T_wild <- 1255111            # lambda_R: matches wild reference reef
cap    <- max(D$prod, na.rm=TRUE)         # orchard capacity (all-orchard plateau)
T_full <- 0.90*cap
cat(sprintf("orchard production capacity ~%.2f M embryos/yr; 90%% = %.2f M\n", cap/1e6, T_full/1e6))

# first year each allocation crosses a threshold (NA if never)
cross <- function(v, thr){ i<-which(v>=thr)[1]; if(is.na(i)) NA_real_ else yr[i] }
tt <- D |> group_by(reef_pct, alloc, prop_out) |>
  summarise(t_self=cross(prod,T_self), t_wild=cross(prod,T_wild),
            t_full=cross(prod,T_full), reef_out=NA_real_, .groups="drop")
print(tt)

## =========================================================================
## F1 — the maturation LAG (all-orchard): tank fills early, spawn turns on late
## =========================================================================
k1 <- 1  # all orchard
f1 <- tibble(yr=yr,
             `Tank fills (orchard coral cover)` = area_by_k[[k1]]/max(area_by_k[[k1]]),
             `Spawn switches on (embryo output)`= prod_by_k[[k1]]/max(prod_by_k[[k1]])) |>
  pivot_longer(-yr)
pl_lab <- tibble(name=c("Tank fills (orchard coral cover)","Spawn switches on (embryo output)"),
                 x=c(9, 30), y=c(1.03, 0.62))
pF1 <- ggplot(f1, aes(yr,value,color=name))+
  geom_line(linewidth=2.4,lineend="round")+
  geom_text(data=pl_lab,aes(x,y,label=str_wrap(name,20),color=name),
            inherit.aes=FALSE,fontface="bold",size=5,lineheight=.9,hjust=0)+
  scale_color_manual(values=c("Tank fills (orchard coral cover)"=TT,
                              "Spawn switches on (embryo output)"=CC),guide="none")+
  scale_y_continuous(labels=NULL,breaks=NULL,limits=c(0,1.12))+
  scale_x_continuous(limits=c(0,50),breaks=seq(0,50,10))+
  labs(x="years since orchard started", y="share of maximum",
       title="Full ≠ functioning: spawn lags the fill")+
  theme_slide(base_size=17)+
  theme(plot.title=element_text(size=19,face="bold",color=INK,margin=margin(b=6)))
save_slide(pF1,"fig_orchfill_lag.png",w=7.0,h=4.7)

## =========================================================================
## F2 — allocation x time: orchard spawn output vs 3 thresholds, crossing marks
## =========================================================================
thr <- tibble(y=c(T_self,T_wild,T_full)/1e6,
              lab=c("self-sufficient (2.0M)","matches wild reef (1.26M)",
                    "90% of capacity"))
mk <- tt |> filter(!is.na(t_self)) |>
  left_join(D, by=c("reef_pct","alloc","prop_out")) |>
  filter(yr==t_self) |> transmute(yr, prod=prod/1e6, alloc)
pF2 <- ggplot(D, aes(yr, prod/1e6, color=alloc))+
  geom_hline(data=thr, aes(yintercept=y), linetype=c("solid","31","13"),
             color=c(INK,MU,MU), linewidth=c(.9,.7,.7))+
  geom_text(data=thr, aes(x=50,y=y,label=lab), inherit.aes=FALSE, hjust=1,
            vjust=-0.5, size=4.1, color=c(INK,MU,MU), fontface="bold")+
  geom_line(linewidth=2.2,lineend="round")+
  geom_point(data=mk, aes(yr,prod), size=4.2, shape=21, fill="white", stroke=1.7)+
  scale_color_manual(values=colorRampPalette(c(TT,GG,CC))(length(MY_PROPS)),name=NULL)+
  scale_x_continuous(limits=c(0,50),breaks=seq(0,50,10))+
  scale_y_continuous(limits=c(0,NA))+
  labs(x="years since orchard started",
       y="orchard spawn output (M embryos / yr)",
       title="How soon the orchard becomes a spawn source")+
  theme_slide(base_size=17,legend="bottom")+
  theme(plot.title=element_text(size=19,face="bold",color=INK,margin=margin(b=6)))
save_slide(pF2,"fig_orchfill_time.png",w=8.4,h=5.0)

## =========================================================================
## F3 — decision curve: years-to-functioning vs % kept for the reef
## =========================================================================
dF3 <- tt |> mutate(reef_share=reef_pct)
pF3 <- ggplot(dF3, aes(reef_share, t_self))+
  geom_line(linewidth=2.2,color=MU,lineend="round")+
  geom_point(aes(color=reef_share),size=5)+
  ggrepel::geom_text_repel(aes(label=ifelse(is.na(t_self),"never",paste0(t_self," yr"))),
                           size=4.6,fontface="bold",color=INK,box.padding=.6,seg.color=NA)+
  scale_color_gradient(low=TT,high=CC,guide="none")+
  scale_x_continuous(breaks=seq(0,100,25),labels=function(x)paste0(x,"%"))+
  scale_y_continuous(limits=c(0,NA))+
  labs(x="share of recruits kept for the reef",
       y="years to a self-sufficient orchard",
       title="You don't have to choose: keep feeding the reef, still build the orchard")+
  theme_slide(base_size=17)+
  theme(plot.title=element_text(size=17,face="bold",color=INK,margin=margin(b=6)))
save_slide(pF3,"fig_orchfill_decision.png",w=7.4,h=4.9)

cat("done: fig_orchfill_lag / fig_orchfill_time / fig_orchfill_decision\n")

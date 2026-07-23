# fig_orchard_fill2.R — rebuild from cached sweep (/tmp/orch_fill.rds).
# Corrected framing after seeing the model:
#   * spawn self-sufficiency (collect 2e6) is reached ~yr 2 — NOT the constraint
#   * the real clock = time to a FULL MATURE broodstock (SC4-5 standing stock)
# Metric for "functioning": orchard mature (SC4-5) coral area, m2, over time.
# Common target = 90% of the max achievable (all-orchard) equilibrium stock.
# Created: 2026-07-19
setwd(path.expand("~/Detmer-2025-coral-RSE"))
suppressMessages(source("presentation-figs/theme_slide.R"))
suppressMessages(source("presentation-figs/engine/setup_base.R"))
suppressMessages(source("presentation-figs/engine/functions.R"))
prop_main <- c(0.5, 1); lambda_Rs <- c(0, 1255111)  # inlined (was _extracted/fig2_ctx.R)
suppressMessages(library(tidyverse))
CC<-DECK$coral; TT<-DECK$teal; GG<-DECK$gold; INK<-DECK$ink; MU<-DECK$mute

X <- readRDS("/tmp/orch_fill.rds"); S <- X$S; MY_PROPS <- X$props
nR<-length(reef_treatments); nO<-length(orchard_treatments); nL<-length(lab_treatments)
LR <- which(lambda_Rs == 1255111)

traj <- function(k, metric, sc=NULL){
  M <- sapply(1:n_sample1, function(i){ sim<-S[[i]][[LR]][[k]]
    if(is.null(sc)) model_summ(sim,"orchard",metric,nR,nO,nL)
    else            model_summ(sim,"orchard",metric,nR,nO,nL,size_classes=sc)})
  rowMeans(M, na.rm=TRUE)
}
# cumulative reef recruits outplanted (per allocation, over full sim)
reef_cum <- function(k){ mean(sapply(1:n_sample1, function(i) sum(S[[i]][[LR]][[k]]$reef_out[[1]][[2]], na.rm=TRUE))) }

YRS <- length(traj(1,"production")); yr <- 0:(YRS-1)
mat_l <- lapply(seq_along(MY_PROPS), function(k) traj(k,"area_m2",c(4,5)))  # SC4-5 area m2
prodM  <- lapply(seq_along(MY_PROPS), function(k) traj(k,"production"))
reefR  <- sapply(seq_along(MY_PROPS), reef_cum)

alloc_lab <- paste0(round((1-MY_PROPS)*100),"% to orchard")
D <- map_dfr(seq_along(MY_PROPS), function(kk) tibble(
  yr=yr, prop_out=MY_PROPS[kk], reef_pct=round(MY_PROPS[kk]*100),
  alloc=factor(alloc_lab[kk],levels=alloc_lab),
  mature=mat_l[[kk]], prod=prodM[[kk]]))

## common target = 90% of the max achievable mature stock (all-orchard equilibrium yrs 40-50)
equil <- function(v) mean(v[(YRS-10):YRS])
cap_mature <- max(sapply(mat_l, equil)); TARGET <- 0.90*cap_mature
cat(sprintf("max mature broodstock ~%.0f m2; functioning target (90%%) = %.0f m2\n", cap_mature, TARGET))
cross <- function(v,thr){ i<-which(v>=thr)[1]; if(is.na(i)) NA_real_ else yr[i] }
tt <- tibble(k=seq_along(MY_PROPS), reef_pct=round(MY_PROPS*100), alloc=factor(alloc_lab,levels=alloc_lab),
             t_fun=sapply(mat_l,function(v) cross(v,TARGET)), reefR=round(reefR))
print(tt)
COLS <- setNames(colorRampPalette(c(TT,GG,CC))(length(MY_PROPS)), alloc_lab)

## =========================================================================
## F2 (core) — time to a full mature broodstock, per allocation
## =========================================================================
mk <- tt |> filter(!is.na(t_fun)) |> mutate(y=TARGET)
pF2 <- ggplot(D, aes(yr, mature, color=alloc))+
  geom_hline(yintercept=TARGET, linetype="31", color=INK, linewidth=.8)+
  annotate("text", x=48, y=TARGET, label="full mature broodstock", hjust=1, vjust=1.9,
           size=4.2, fontface="bold", color=INK)+
  geom_line(linewidth=2.2, lineend="round")+
  geom_point(data=mk, aes(t_fun,y), size=4.4, shape=21, fill="white", stroke=1.8)+
  scale_color_manual(values=COLS, name=NULL)+
  scale_x_continuous(limits=c(0,50), breaks=seq(0,50,10))+
  scale_y_continuous(limits=c(0,NA), labels=scales::comma)+
  labs(x="years since orchard started", y=expression("mature (spawning) coral in orchard (m"^2*")"),
       title="How long to fill a functioning orchard")+
  theme_slide(base_size=17, legend="bottom")+
  theme(plot.title=element_text(size=19,face="bold",color=INK,margin=margin(b=6)))
save_slide(pF2,"fig_orchfill_time.png",w=8.4,h=5.0)

## =========================================================================
## F1 (context) — spawn is never the bottleneck (log scale vs collection target)
## =========================================================================
k50 <- which(MY_PROPS==0.5)
f1 <- tibble(yr=yr, prod=pmax(prodM[[k50]],1))
pF1 <- ggplot(f1, aes(yr,prod))+
  geom_hline(yintercept=2e6, linetype="solid", color=CC, linewidth=1)+
  annotate("text", x=1, y=2e6, label="collection target: 2M embryos / yr", hjust=0, vjust=-0.7,
           size=4.3, fontface="bold", color=CC)+
  annotate("text", x=1, y=2e6, label="how many they aim to scoop up & settle each year\n(≈ what they now collect from one wild reef, 1.26M)",
           hjust=0, vjust=1.55, size=3.3, fontface="italic", color=CC, lineheight=.95)+
  geom_line(linewidth=2.4, color=TT, lineend="round")+
  annotate("text", x=30, y=6e8, label="what a 50:50 orchard produces", hjust=0.5,
           size=4.6, fontface="bold", color=TT)+
  annotate("segment", x=27, xend=27, y=2.3e6, yend=6.5e8, color=MU, linewidth=.7,
           arrow=arrow(ends="both",length=unit(.16,"cm")))+
  annotate("text", x=28.3, y=2.2e7, label="~350× to spare", hjust=0, size=4, color=MU, fontface="italic")+
  scale_y_log10(labels=function(x) ifelse(x>=1e6, paste0(x/1e6,"M"), scales::comma(x)),
                breaks=c(1e5,1e6,1e7,1e8,1e9))+
  scale_x_continuous(limits=c(0,50), breaks=seq(0,50,10))+
  labs(x="years since orchard started", y="orchard spawn output (embryos / yr, log)",
       title="Spawn is never the bottleneck")+
  theme_slide(base_size=17)+
  theme(plot.title=element_text(size=19,face="bold",color=INK,margin=margin(b=6)))
save_slide(pF1,"fig_orchfill_lag.png",w=7.4,h=4.9)

## =========================================================================
## F3 (decision) — years-to-functioning vs % kept for the reef (+ reef corals delivered)
## =========================================================================
dF3   <- tt |> filter(!is.na(t_fun)) |> mutate(lab=paste0(t_fun," yr"))
never <- tt |> filter(is.na(t_fun))
reef_lo <- round(min(tt$reefR)/1e6,2); reef_hi <- round(max(tt$reefR)/1e6,2)
pF3 <- ggplot(dF3, aes(reef_pct, t_fun))+
  geom_line(linewidth=2.2, color=MU, lineend="round")+
  geom_point(aes(color=alloc), size=5.5, show.legend=FALSE)+
  geom_text(aes(label=lab), vjust=-1.3, size=4.6, fontface="bold", color=INK)+
  geom_point(data=never, aes(x=reef_pct, y=1), shape=4, size=5, stroke=2.2, color=CC)+
  geom_text(data=never, aes(x=reef_pct, y=1, label="orchard\nnever builds"), hjust=1.15,
            size=4, fontface="bold", color=CC, lineheight=.9)+
  annotate("text", x=0, y=23,
           label=paste0("The reef still gets ", reef_lo, "–", reef_hi,
                        "M recruits over 50 yr\nin every case — within 11% (overflow feeds it)"),
           hjust=0, vjust=1, size=4.2, fontface="bold", color=TT, lineheight=.95)+
  scale_color_manual(values=COLS)+
  scale_x_continuous(breaks=seq(0,100,25), labels=function(x)paste0(x,"%"), limits=c(-8,108))+
  scale_y_continuous(limits=c(0,24))+
  labs(x="share of recruits kept for the reef",
       y="years to a full mature orchard",
       title="Keep feeding the reef and still build the orchard")+
  theme_slide(base_size=17)+
  theme(plot.title=element_text(size=18,face="bold",color=INK,margin=margin(b=6)))
save_slide(pF3,"fig_orchfill_decision.png",w=7.6,h=4.9)

cat("done v2\n")

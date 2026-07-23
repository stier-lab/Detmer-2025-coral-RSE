# fig_where_alts.R — 5 angles on the reef-vs-orchard result (real model output, cached sweep)
setwd(path.expand("~/Detmer-2025-coral-RSE"))
suppressMessages(source("presentation-figs/theme_slide.R"))
suppressMessages(library(tidyverse))
S <- readRDS("/tmp/orch_sweep.rds"); lr <- S$lr[2]
CC<-DECK$coral; TT<-DECK$teal; GG<-DECK$gold; INK<-DECK$ink; MU<-DECK$mute
sm <- function(dt,h) dt |> filter(par2==lr) |> group_by(prop_out) |>
  summarise(reef=mean(reef_cover_mean,na.rm=T), roi=mean(tot_ROI_mean,na.rm=T),
            orch=mean(orch_function_mean,na.rm=T), cost=mean(tot_costs,na.rm=T),
            recr=mean(reef_recruits_out_tot,na.rm=T), .groups="drop") |> mutate(h=h)
d5<-sm(S$dt5,"5 years"); d50<-sm(S$dt50,"50 years")
both<-bind_rows(d5,d50)|>mutate(h=factor(h,levels=c("5 years","50 years")))
xsc <- scale_x_continuous(breaks=c(0,.5,1),labels=c("all\norchard","50:50","all\nreef"),expand=expansion(mult=c(.06,.06)))
th  <- function(...) theme_slide(base_size=17,...)+theme(plot.title=element_text(size=19,face="bold",color=INK,margin=margin(b=6)),axis.text.x=element_text(face="bold",lineheight=.9))

## A — the 5-yr tradeoff (reef cover up vs coral-per-$ down)
dA<-d5|>transmute(prop_out,`Reef coral cover`=reef/max(reef),`Coral per dollar`=roi/max(roi))|>pivot_longer(-prop_out)
pA<-ggplot(dA,aes(prop_out,value,color=name))+geom_line(linewidth=2.4,lineend="round")+
  scale_color_manual(values=c("Reef coral cover"=CC,"Coral per dollar"=TT),name=NULL)+xsc+
  scale_y_continuous(labels=NULL,breaks=NULL)+labs(x=NULL,y="relative value",title="A · The 5-year tradeoff")+
  th(legend="bottom")
save_slide(pA,"fig_whereA.png",w=6.2,h=4.7)

## B — time collapses the tradeoff (5 vs 50 yr)
dB<-both|>transmute(prop_out,h,`Reef coral cover`=reef,`Coral per dollar`=roi)|>
  pivot_longer(c(`Reef coral cover`,`Coral per dollar`),names_to="m")|>
  group_by(m)|>mutate(rel=value/max(value))|>ungroup()
pB<-ggplot(dB,aes(prop_out,rel,color=m))+geom_line(linewidth=2.2,lineend="round")+facet_wrap(~h)+
  scale_color_manual(values=c("Reef coral cover"=CC,"Coral per dollar"=TT),name=NULL)+xsc+
  scale_y_continuous(labels=NULL,breaks=NULL,limits=c(0,1))+labs(x=NULL,y="relative value",title="B · Time collapses the tradeoff")+
  th(legend="bottom")+theme(strip.text=element_text(size=17,face="bold"))
save_slide(pB,"fig_whereB.png",w=8.6,h=4.6)

## C — cost is nearly flat across allocation (their cost data)
dC<-both|>mutate(cost=cost/1000)
pC<-ggplot(dC,aes(prop_out,cost,color=h))+geom_line(linewidth=2.4,lineend="round")+
  geom_point(size=2.6)+scale_color_manual(values=c("5 years"=GG,"50 years"=INK),name=NULL)+xsc+
  scale_y_continuous(limits=c(0,NA),labels=scales::comma)+
  labs(x=NULL,y="total cost (thousands $)",title="C · Cost barely changes across the choice")+
  th(legend="bottom")
save_slide(pC,"fig_whereC.png",w=6.6,h=4.7)

## D — you can have both (reef cover + orchard stock, stacked; total coral stays high)
dD<-d50|>transmute(prop_out,`On the reef`=reef,`In the orchard`=orch)|>
  pivot_longer(-prop_out,names_to="where",values_to="m2")|>
  mutate(where=factor(where,levels=c("In the orchard","On the reef")))
pD<-ggplot(dD,aes(prop_out,m2,fill=where))+geom_area(alpha=.92)+
  scale_fill_manual(values=c("On the reef"=CC,"In the orchard"=TT),name=NULL)+xsc+
  scale_y_continuous(labels=scales::comma)+labs(x=NULL,y=expression("living coral (m"^2*", 50 yr)"),title="D · You can have both")+
  th(legend="bottom")
save_slide(pD,"fig_whereD.png",w=6.6,h=4.7)

## E — the menu of choices (efficiency frontier: reef cover vs orchard stock, 5 yr)
dE<-d5|>mutate(lab=ifelse(prop_out %in% c(0,.5,1),c("all orchard","50:50","all reef")[match(prop_out,c(0,.5,1))],NA))
pE<-ggplot(dE,aes(reef,orch))+geom_path(color=MU,linewidth=1.1)+
  geom_point(aes(color=prop_out),size=4)+
  ggrepel::geom_text_repel(aes(label=lab),size=5,fontface="bold",color=INK,na.rm=TRUE,seg.color=NA,box.padding=.6)+
  scale_color_gradient(low=TT,high=CC,guide="none")+
  labs(x=expression("reef coral cover (m"^2*")"),y=expression("orchard stock (m"^2*")"),title="E · The menu of choices")+
  th()
save_slide(pE,"fig_whereE.png",w=6.4,h=4.7)
cat("done: A B C D E\n")

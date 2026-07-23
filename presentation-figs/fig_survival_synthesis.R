# fig_survival_synthesis.R — the synthesis data that MOTIVATES the model's orchard result.
# Annual survival by stage, REEF (field) vs ORCHARD (nursery). The orchard rescues the
# smallest, most vulnerable corals (recruits ~2.7% on the reef); the advantage narrows
# as colonies grow. All values from the Caribbean survival synthesis + FUNDEMAR.
# Created: 2026-07-20
setwd(path.expand("~/Detmer-2025-coral-RSE"))
suppressMessages(source("presentation-figs/theme_slide.R"))
suppressMessages(library(tidyverse))
DATA <- "../Detmer-2025-coral-parameters"
CC<-DECK$coral; TT<-DECK$teal; MU<-DECK$mute; INK<-DECK$ink; GREY<-"9AA3A0"

field <- readr::read_csv(file.path(DATA,"06_analysis/output/survival_by_size.csv"), show_col_types=FALSE)
rec   <- readRDS(file.path(DATA,"parameter_lists/recruit_surv_pars.rds"))
nur   <- readRDS(file.path(DATA,"parameter_lists/nurs_surv_pars.rds"))
ns <- map_dfr(paste0("SC",1:5), function(sc){r<-nur$SC_surv_results[[sc]]
  if(is.null(r)) return(NULL); tibble(stage=sc, surv=r$mean, lo=r$ci_lower, hi=r$ci_upper, n=r$n)})

df <- bind_rows(
  tibble(stage="Recruit", surv=rec$s_recruit, lo=rec$s_recruit_ci[1], hi=rec$s_recruit_ci[2],
         n=rec$n_observations, ctx="On the reef (field)"),
  tibble(stage=field$size_class, surv=field$survival, lo=field$ci_lower, hi=field$ci_upper,
         n=field$n, ctx="On the reef (field)"),
  ns |> mutate(ctx="In the orchard (nursery)")
) |>
  mutate(stage=factor(stage, levels=c("Recruit",paste0("SC",1:5))),
         ctx=factor(ctx, levels=c("On the reef (field)","In the orchard (nursery)")))

lab <- c("Recruit"="New\nrecruit","SC1"="SC1\n<10 cm²","SC2"="SC2\n10–100",
         "SC3"="SC3\n100–900","SC4"="SC4\n900–4,000","SC5"="SC5\n>4,000")
COL <- c("On the reef (field)"=CC, "In the orchard (nursery)"=TT)

p <- ggplot(df, aes(stage, surv, fill=ctx)) +
  geom_col(position=position_dodge(width=0.74, preserve="single"), width=0.68) +
  geom_errorbar(aes(ymin=lo, ymax=hi), position=position_dodge(width=0.74, preserve="single"),
                width=0.16, color="grey45", linewidth=0.55) +
  # flag the reef recruit bottleneck
  annotate("text", x=1, y=rec$s_recruit_ci[2]+0.055, label="2.7%", fontface="bold", size=5.6, color=INK) +
  annotate("text", x=1, y=rec$s_recruit_ci[2]+0.135, label="reef recruits die", fontface="bold", size=4.2, color=INK) +
  # the SC1 rescue
  annotate("segment", x=1.5, xend=1.5, y=0, yend=1.06, linetype="22", color=MU, linewidth=0.6) +
  annotate("text", x=2, y=1.02,
           label="the orchard protects the\nsmallest corals →", size=4.3, fontface="bold",
           color=TT, hjust=0, lineheight=0.9) +
  scale_fill_manual(values=COL, name=NULL) +
  scale_x_discrete(labels=lab) +
  scale_y_continuous(labels=scales::percent, limits=c(0,1.14), breaks=seq(0,1,.25),
                     expand=expansion(mult=c(0.01,0))) +
  labs(x=NULL, y="Annual survival") +
  theme_slide(base_size=18, legend="bottom") +
  theme(panel.grid.major.x=element_blank(),
        axis.text.x=element_text(size=13.5, lineheight=0.9))

save_slide(p, "fig_survival_synthesis.png", w=9.2, h=4.6)
cat("done fig_survival_synthesis\n")

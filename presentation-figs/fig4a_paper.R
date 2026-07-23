# fig4a_paper.R — faithful recreation of MAIN-TEXT Figure 4a, in the deck palette.
# Source of truth: rse_new_scenario_analyses.rmd, "# Figure 4 & SM" (line ~4424):
#   outplant a FIXED AREA (2,000 m^2) of a single size class each year for 50 yr,
#   real (size-increasing) survival, reef density-dependence OFF. SC2 wins.
# (Not presentation-figs/engine/fig4_data.R, which used a different area.)
# Created: 2026-07-20
setwd(path.expand("~/Detmer-2025-coral-RSE"))
suppressMessages(source("presentation-figs/theme_slide.R"))
suppressMessages(source("presentation-figs/engine/setup_base.R"))
suppressMessages(library(tidyverse))

## ---- reproduce the main-text Fig 4 model loop (verbatim params) ----
area_out <- 2000                                   # avg area covered by a full orchard (m^2)
lambda_R_12345 <- round(area_out/(A_mids*0.0001))  # # individuals of each SC to keep area fixed
out_sizes <- c(1,2,3,4,5)

rest_pars <- rest_pars_def
rest_pars$reef_prop <- c(1,1)
rest_pars$reef_yield <- 1

dens_pars.r <- list(); dens_pars.r[[1]] <- list()
dens_pars.r[[1]][[1]] <- 0; dens_pars.r[[1]][[2]] <- 0; dens_pars.r[[1]][[3]] <- 0

N0.l <- list(); N0.l[[1]] <- 0; N0.l[[2]] <- 0

mod_area <- matrix(NA, nrow = years, ncol = 5)
for(j in 1:5){
  lambda_R_j <- lambda_R_12345[j]
  size_props <- matrix(NA, nrow = length(lab_treatments), ncol = n)
  size_props[1, ] <- rep(0, 5); size_props[1, out_sizes[j]] <- 1
  size_props[2, ] <- size_props[1, ]                # mirror (2nd lab treatment inactive here)
  lab_pars <- list(s0 = matrix(1, nrow = years, ncol = 2), s1 = matrix(1, nrow = years, ncol = 2),
                   m0 = 0, m1 = 0, sett_props = list(T1 = 1),
                   size_props = size_props, size_props1 = size_props1)
  sim_j <- rse_mod1(years, n, A_mids, surv_pars.rc, surv_pars.r, dens_pars.r, growth_pars.r,
                    shrink_pars.r, frag_pars.r, fec_pars.r, surv_pars.o, dens_pars.o, growth_pars.o,
                    shrink_pars.o, frag_pars.o, fec_pars.o, lambda, lambda_R = lambda_R_j, sigma_s,
                    sigma_f, ext_rand, seeds, dist_yrs, dist_pars.r, dist_effects.r, dist_pars.o,
                    dist_effects.o, orchard_treatments, reef_treatments, lab_treatments, lab_pars,
                    rest_pars, N0.r, N0.o, N0.l)
  mod_area[,j] <- model_summ(model_sim = sim_j, location = "reef", metric = "area_m2",
                             n_reef = length(reef_treatments), n_orchard = length(orchard_treatments),
                             n_lab = length(lab_treatments))
}
cat("winner (max 50-yr cover):", paste0("SC", which.max(mod_area[nrow(mod_area),])),
    " | SC cover @50yr (m2):", paste(round(mod_area[nrow(mod_area),]), collapse=", "), "\n")

## ---- tidy + plot in deck palette ----
n_out <- setNames(lambda_R_12345, paste0("SC", 1:5))
df <- as.data.frame(mod_area) |> setNames(paste0("SC", 1:5)) |>
  mutate(year = 2025 + (row_number()-1)) |>
  pivot_longer(-year, names_to = "sc", values_to = "cover") |>
  mutate(hero = sc == "SC2")

CC <- DECK$coral; INK <- DECK$ink; MU <- DECK$mute
SC_COLS <- c(SC1="#B9C2BE", SC2=CC, SC3="#8AA6A1", SC4="#B9C2BE", SC5="#6E7F7B")
ends <- df |> group_by(sc) |> slice_max(year) |> ungroup() |> mutate(k=paste0(sc,"  (",scales::comma(n_out[sc]),")"))

p <- ggplot(df, aes(year, cover/1000, color = sc, linewidth = hero, group = sc)) +
  geom_line(lineend = "round") +
  scale_color_manual(values = SC_COLS, guide = "none") +
  scale_linewidth_manual(values = c(`FALSE`=1.0, `TRUE`=2.8), guide = "none") +
  scale_x_continuous(breaks = seq(2025,2075,25), expand = expansion(mult = c(0.01, 0.24))) +
  scale_y_continuous(expand = expansion(mult = c(0.01, 0.06))) +
  # direct end labels (size class + number outplanted)
  ggrepel::geom_text_repel(data = ends, aes(label = k, color = sc), hjust = 0, nudge_x = 1.5,
                           direction = "y", segment.color = NA, size = 4.6, fontface = "bold",
                           box.padding = 0.12, seed = 1) +
  labs(x = "Year", y = expression("Reef coral cover  ("*10^3~m^2*")")) +
  theme_slide(base_size = 20) +
  theme(plot.margin = margin(14, 10, 12, 12)) +
  coord_cartesian(clip = "off")

save_slide(p, "fig4a_paper.png", w = 8.2, h = 5.0)
cat("done fig4a_paper\n")

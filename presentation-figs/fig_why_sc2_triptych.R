# fig_why_sc2_triptych.R
# ---------------------------------------------------------------------------
# Three-panel small-multiples: "size class 2 is best outplant" is an INTERACTION
# between size-dependent survival and finite nursery space, not an artifact.
# Regenerated from the REAL model + scenario code (rse_new_scenario_analyses.rmd),
# starting from the verified fig4a_paper.R template. Only the scenario knobs change.
#
# Panels reproduce:
#   A  "IF survival were equal across sizes"  -> SC1 wins
#        rmd "for supplement ... equal survival" chunk, lines ~5088-5182
#        (FigS11_EqSout): fixed AREA 2000 m^2/yr, survival AVERAGED across all
#        size classes incl. recruit survival (surv_pars.rc), dens_pars.r = 0.
#   B  "Real size-increasing survival"        -> SC2 wins   (manuscript Fig 4a)
#        rmd "# Figure 4 & SM" chunk, lines ~4424-4515 (== fig4a_paper.R):
#        fixed AREA 2000 m^2/yr of one size class, REAL survival, dens_pars.r = 0.
#   C  "IF equal NUMBERS outplanted (no space cap)" -> SC5 wins
#        rmd "for supplement ... equal numbers" chunk, lines ~4926-5002
#        (FigS12_Nout): lambda_R = 880,000 individuals/yr for EVERY size class,
#        real survival, dens_pars.r = 0.
# Created: 2026-07-21
# ---------------------------------------------------------------------------
setwd(path.expand("~/Detmer-2025-coral-RSE"))
suppressMessages(source("presentation-figs/theme_slide.R"))
suppressMessages(source("presentation-figs/engine/setup_base.R"))
suppressMessages(library(tidyverse))

## ---- shared scenario scaffolding (verbatim from the rmd chunks) ----------
area_out  <- 2000                         # avg area covered by a full orchard (m^2/yr)
out_sizes <- c(1, 2, 3, 4, 5)

# no orchard investment; all embryos included; density-dependence OFF on reef
rest_pars <- rest_pars_def
rest_pars$reef_prop  <- c(1, 1)
rest_pars$reef_yield <- 1

dens_pars.r <- list(); dens_pars.r[[1]] <- list()
dens_pars.r[[1]][[1]] <- 0
dens_pars.r[[1]][[2]] <- 0
dens_pars.r[[1]][[3]] <- 0

N0.l <- list(); N0.l[[1]] <- 0; N0.l[[2]] <- 0

# runner: outplant one size class each year, return reef area_m2 timeseries (years x 5)
run_scenario <- function(lambda_R_12345, surv_r, surv_rc) {
  out <- matrix(NA, nrow = years, ncol = 5)
  for (j in 1:5) {
    size_props <- matrix(NA, nrow = length(lab_treatments), ncol = n)
    size_props[1, ] <- rep(0, 5)
    size_props[1, out_sizes[j]] <- 1
    lab_pars <- list(s0 = matrix(1, nrow = years, ncol = 2),
                     s1 = matrix(1, nrow = years, ncol = 2),
                     m0 = 0, m1 = 0, sett_props = list(T1 = 1),
                     size_props = size_props, size_props1 = size_props1)
    sim_j <- rse_mod1(years, n, A_mids, surv_rc, surv_r, dens_pars.r, growth_pars.r,
                      shrink_pars.r, frag_pars.r, fec_pars.r, surv_pars.o, dens_pars.o,
                      growth_pars.o, shrink_pars.o, frag_pars.o, fec_pars.o, lambda,
                      lambda_R = lambda_R_12345[j], sigma_s, sigma_f, ext_rand, seeds,
                      dist_yrs, dist_pars.r, dist_effects.r, dist_pars.o, dist_effects.o,
                      orchard_treatments, reef_treatments, lab_treatments, lab_pars,
                      rest_pars, N0.r, N0.o, N0.l)
    out[, j] <- model_summ(model_sim = sim_j, location = "reef", metric = "area_m2",
                           n_reef = length(reef_treatments),
                           n_orchard = length(orchard_treatments),
                           n_lab = length(lab_treatments))
  }
  colnames(out) <- paste0("SC", 1:5)
  out
}

## ---- Panel B: real, size-increasing survival, fixed AREA (Fig 4a) --------
lambda_area <- round(area_out / (A_mids * 0.0001))     # # individuals to fix area
modB <- run_scenario(lambda_area, surv_pars.r_def, surv_pars.rc_def)

## ---- Panel A: EQUAL survival across sizes, fixed AREA (FigS11) ------------
# average survival across all size classes AND recruit survival, then apply to all
surv_r_eq  <- surv_pars.r_def
surv_rc_eq <- surv_pars.rc_def
surv_mean.r <- mean(c(surv_pars.r_def[[1]][[1]], surv_pars.rc_def[[1]][[1]]))
surv_r_eq[[1]][[1]] <- rep(surv_mean.r, 5)
surv_r_eq[[1]][[2]] <- surv_r_eq[[1]][[1]]
surv_r_eq[[1]][[3]] <- surv_r_eq[[1]][[1]]
surv_rc_eq[[1]][[1]] <- surv_mean.r
surv_rc_eq[[1]][[2]] <- surv_rc_eq[[1]][[1]]
surv_rc_eq[[1]][[3]] <- surv_rc_eq[[1]][[1]]
modA <- run_scenario(lambda_area, surv_r_eq, surv_rc_eq)

## ---- Panel C: EQUAL NUMBERS outplanted, no space cap (FigS12) -------------
lambda_num <- rep(880000, 5)
modC <- run_scenario(lambda_num, surv_pars.r_def, surv_pars.rc_def)

## ---- verify winners ------------------------------------------------------
winner <- function(m) paste0("SC", which.max(m[nrow(m), ]))
cat("Panel A (equal survival) winner:", winner(modA),
    "| 50-yr cover (m2):", paste(round(modA[nrow(modA), ]), collapse = ", "), "\n")
cat("Panel B (real survival)  winner:", winner(modB),
    "| 50-yr cover (m2):", paste(round(modB[nrow(modB), ]), collapse = ", "), "\n")
cat("Panel C (equal numbers)  winner:", winner(modC),
    "| 50-yr cover (m2):", paste(round(modC[nrow(modC), ]), collapse = ", "), "\n")

stopifnot(winner(modA) == "SC1", winner(modB) == "SC2", winner(modC) == "SC5")

## ---- tidy for plotting ---------------------------------------------------
panel_levels <- c(
  A = "IF survival were equal across sizes",
  B = "Real size-increasing survival",
  C = "IF equal numbers outplanted (no cap)"
)
win_of <- c(A = "SC1", B = "SC2", C = "SC5")

tidy_panel <- function(m, key) {
  as.data.frame(m) |>
    mutate(year = 2025 + (row_number() - 1)) |>
    pivot_longer(-year, names_to = "sc", values_to = "cover") |>
    mutate(panel = factor(panel_levels[[key]], levels = unname(panel_levels)),
           hero  = sc == win_of[[key]])
}
df <- bind_rows(tidy_panel(modA, "A"), tidy_panel(modB, "B"), tidy_panel(modC, "C"))

ends <- df |> group_by(panel, sc) |> slice_max(year) |> ungroup()

CORAL <- "#F0A24E"          # winner
GREY  <- "#AEB8B6"          # the other four

p <- ggplot(df, aes(year, cover / 1000, group = sc,
                    color = hero, linewidth = hero)) +
  geom_line(lineend = "round") +
  facet_wrap(~ panel, nrow = 1, scales = "free_y",
             labeller = label_wrap_gen(width = 22)) +
  scale_color_manual(values = c(`FALSE` = GREY, `TRUE` = CORAL), guide = "none") +
  scale_linewidth_manual(values = c(`FALSE` = 1.0, `TRUE` = 3.0), guide = "none") +
  scale_x_continuous(breaks = seq(2025, 2075, 25),
                     expand = expansion(mult = c(0.02, 0.22))) +
  scale_y_continuous(expand = expansion(mult = c(0.02, 0.10))) +
  ggrepel::geom_text_repel(
    data = ends, aes(label = sc),
    hjust = 0, nudge_x = 2.5, direction = "y",
    segment.color = "#5E7183", segment.size = 0.3, min.segment.length = 0,
    force = 2.2, force_pull = 0.3, point.padding = 0.15, max.overlaps = Inf,
    size = 5.4, fontface = "bold", box.padding = 0.42, seed = 1) +
  labs(x = "Year", y = expression("Reef coral cover  ("*10^3~m^2*")")) +
  theme_slide(base_size = 20) +
  theme(
    strip.text   = element_text(size = 15, face = "bold", color = OCEAN_TOK$txt,
                                margin = margin(6, 2, 8, 2), lineheight = 1.05),
    panel.spacing = unit(2.0, "lines"),
    plot.margin  = margin(16, 14, 12, 14)
  ) +
  coord_cartesian(clip = "off")

out_png <- "presentation-figs/img/fig_why_sc2_triptych.png"
dir.create(dirname(out_png), showWarnings = FALSE, recursive = TRUE)
ggsave(out_png, plot = p, width = 10, height = 4, units = "in", dpi = 300,
       bg = OCEAN_TOK$bg)
cat("wrote", out_png, "\n")

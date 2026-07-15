# theme_slide.R — slide-optimized ggplot theme matching the ICRS deck palette.
# Standalone (does not touch Raine's code). Figures are drawn large-font for a
# conference room and colored to match the deck (ocean teal + coral on cream).
# Usage: source("presentation-figs/theme_slide.R")

suppressMessages({library(ggplot2)})

## ---- deck palette (from the pptx build) ----
DECK <- list(
  dark    = "#0C3A44",  # deep ocean teal (title/closing bg)
  ink     = "#1E2A2E",  # near-black text
  cream   = "#F6F3ED",  # slide background
  coral   = "#D9603A",  # primary accent  (the "winner"/headline series)
  coral_s = "#F3E0D5",  # soft coral fill
  teal    = "#2E8C86",  # secondary accent
  mute    = "#8A9694",  # muted grey (de-emphasised series / "no restoration")
  ice     = "#CFE3E1"
)

## restoration levels (Fig 2 / Fig 3): no restoration = grey, 50% = teal, 100% = coral
REST_COLS <- c("No restoration" = DECK$mute, "50% to reef" = DECK$teal, "100% to reef" = DECK$coral)

## size classes (Fig 4): highlight SC2 (the winner) in coral, mute the rest
SC_COLS <- c("SC1" = "#C9CFCE", "SC2" = DECK$coral, "SC3" = "#AEB8B6",
             "SC4" = "#93A09E", "SC5" = "#6E7B79")

## theme: large fonts for projection, minimal chrome, white panel (sits on white card)
theme_slide <- function(base_size = 21, legend = "none") {
  theme_minimal(base_size = base_size) %+replace%
    theme(
      text            = element_text(color = DECK$ink),
      plot.background  = element_rect(fill = "white", color = NA),
      panel.background = element_rect(fill = "white", color = NA),
      axis.title   = element_text(size = base_size, color = DECK$ink),
      axis.title.x = element_text(margin = margin(t = 8)),
      axis.title.y = element_text(margin = margin(r = 8), angle = 90),
      axis.text    = element_text(size = base_size - 4, color = "grey35"),
      axis.line    = element_line(color = "grey55", linewidth = 0.5),
      axis.ticks   = element_line(color = "grey55", linewidth = 0.5),
      panel.grid.minor = element_blank(),
      panel.grid.major = element_line(color = "grey90", linewidth = 0.4),
      panel.grid.major.x = element_blank(),
      legend.position = legend,
      legend.title    = element_blank(),
      legend.text     = element_text(size = base_size - 4),
      legend.key.height = unit(1.1, "lines"),
      plot.title    = element_text(size = base_size + 1, face = "bold", hjust = 0,
                                   margin = margin(b = 6)),
      plot.margin   = margin(14, 16, 12, 12)
    )
}

## save helper — slide-figure defaults (white bg, 300 dpi)
save_slide <- function(p, file, w = 7.4, h = 5.0) {
  ggsave(file.path("presentation-figs", file), plot = p,
         width = w, height = h, units = "in", dpi = 300, bg = "white")
  message("wrote presentation-figs/", file, "  (", w, "x", h, " in)")
}

## thick geom defaults for legibility
LW  <- 1.6   # line width
PT  <- 3.4   # point size

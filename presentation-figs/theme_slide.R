# theme_slide.R — slide-optimized ggplot theme.
# TWO SKINS via env var OCEAN_THEME:
#   unset/"0" → ICRS deck (light cream + coral/teal)
#   "1"       → Ocean Recoveries "Deep Current" (dark navy #0B1F33 + amber #F0A24E)
# OCEAN save_slide() writes to presentation-figs/ocean/ so the two figure sets never clobber.
suppressMessages({library(ggplot2)})

OCEAN <- Sys.getenv("OCEAN_THEME") == "1"

if (OCEAN) {
  DECK <- list(
    dark    = "#0B1F33",   # deepest navy
    ink     = "#F4F6F8",   # off-white text on navy
    cream   = "#0B1F33",   # "background" = navy
    coral   = "#F0A24E",   # AMBER accent = headline / focal series
    coral_s = "#3A2E1C",   # dark amber-tinted fill (was soft coral)
    teal    = "#56B4E9",   # secondary series (Okabe-Ito sky blue)
    mute    = "#8CA0B3",   # slate muted
    ice     = "#22394F"    # hairline / faint fill
  )
  .BG <- "#0B1F33"; .TXT <- "#F4F6F8"; .AXT <- "#9DB0C2"; .GRID <- "#22394F"; .AXIS <- "#4A6076"
  REST_COLS <- c("No restoration"="#6E7A85", "50% to reef"="#56B4E9", "100% to reef"="#F0A24E")
  SC_COLS   <- c("SC1"="#556472","SC2"="#F0A24E","SC3"="#6E7E8D","SC4"="#8A99A8","SC5"="#A7B5C2")
} else {
  DECK <- list(dark="#0C3A44", ink="#1E2A2E", cream="#F6F3ED", coral="#D9603A", coral_s="#F3E0D5",
               teal="#2E8C86", mute="#8A9694", ice="#CFE3E1")
  .BG <- "white"; .TXT <- DECK$ink; .AXT <- "grey35"; .GRID <- "grey90"; .AXIS <- "grey55"
  REST_COLS <- c("No restoration"=DECK$mute, "50% to reef"=DECK$teal, "100% to reef"=DECK$coral)
  SC_COLS   <- c("SC1"="#C9CFCE","SC2"=DECK$coral,"SC3"="#AEB8B6","SC4"="#93A09E","SC5"="#6E7B79")
}

theme_slide <- function(base_size = 21, legend = "none") {
  theme_minimal(base_size = base_size) %+replace%
    theme(
      text            = element_text(color = .TXT),
      plot.background  = element_rect(fill = .BG, color = NA),
      panel.background = element_rect(fill = .BG, color = NA),
      axis.title   = element_text(size = base_size, color = .TXT),
      axis.title.x = element_text(margin = margin(t = 8)),
      axis.title.y = element_text(margin = margin(r = 8), angle = 90),
      axis.text    = element_text(size = base_size - 4, color = .AXT),
      axis.line    = element_line(color = .AXIS, linewidth = 0.5),
      axis.ticks   = element_line(color = .AXIS, linewidth = 0.5),
      panel.grid.minor = element_blank(),
      panel.grid.major = element_line(color = .GRID, linewidth = 0.4),
      panel.grid.major.x = element_blank(),
      legend.position = legend,
      legend.title    = element_blank(),
      legend.text     = element_text(size = base_size - 4, color = .TXT),
      legend.key.height = unit(1.1, "lines"),
      plot.title    = element_text(size = base_size + 1, face = "bold", hjust = 0,
                                   margin = margin(b = 6), color = .TXT),
      plot.margin   = margin(14, 16, 12, 12)
    )
}

save_slide <- function(p, file, w = 7.4, h = 5.0) {
  dir <- if (OCEAN) "presentation-figs/ocean" else "presentation-figs"
  if (OCEAN && !dir.exists(dir)) dir.create(dir, recursive = TRUE)
  ggsave(file.path(dir, file), plot = p, width = w, height = h, units = "in", dpi = 300, bg = .BG)
  message("wrote ", file.path(dir, file), "  (", w, "x", h, " in)")
}

LW  <- 1.6   # line width
PT  <- 3.4   # point size

## expose the resolved skin tokens for scripts that hard-code neutrals (dark-mode fixes)
OCEAN_TOK <- list(bg=.BG, txt=.TXT, axtxt=.AXT, grid=.GRID, axis=.AXIS, ocean=OCEAN)

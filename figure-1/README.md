# Figure 1 — RSE Model Schematic

Demographic flow diagram for the Restoration Strategy Evaluation (RSE) model, showing how *Acropora palmata* colonies move through Laboratory → Nursery Orchard → Restoration Reef.

## Files

| File | What it is |
|------|-----------|
| `fig1.html` | **Source file** — edit this. Open in any browser to preview. |
| `elkhorn_coral_ian.svg` | Coral silhouette art (Tracey Saxby, IAN/UMCES, CC BY-SA 4.0). Referenced by fig1.html for the size class strip. |
| `export.mjs` | Node script to generate PDF + PNG from fig1.html. |
| `fig1.pdf` | Submission-ready PDF (180 × 161 mm). |
| `fig1_600dpi.png` | High-res raster (600 DPI, 4252 × 3803 px). |

## How to edit

1. Open `fig1.html` in a browser (Chrome/Firefox/Safari)
2. Edit the SVG code in any text editor
3. Refresh the browser to see changes
4. Re-export when done: `node export.mjs`

The file is a single SVG embedded in a minimal HTML wrapper. The HTML is only needed for Google Fonts loading and the export script — all the figure content is in the `<svg>` element.

## How to export

Requires Node.js and Playwright (`npx playwright install chromium` if first time):

```bash
cd figure-1
node export.mjs
# → fig1.pdf (180 × 161 mm, vector)
# → fig1_600dpi.png (4252 × 3803 px)
```

## Structure of the SVG

The figure has these sections (marked with `<!-- ========== -->` comments):

1. **Background** — ivory fill, paper grain texture, watercolor wash zones
2. **Reference reef larvae** — external larval source (top left)
3. **Laboratory** — card with parameters (top center)
4. **Nursery orchard** — card with parameters (bottom left)
5. **Restoration reef** — card with parameters (bottom right)
6. **Inter-compartment flows** — curved arrows between compartments
7. **Decision points** — amber `prop`, `retain`, `size` pills
8. **Size class strip** — SC1–SC5 with IAN coral silhouettes
9. **Equation** — N(t+1) = (T + F) · (S ⊙ N(t)) + R
10. **Legend** — flow types + equation variable definitions
11. **Output metrics** — 6 tracked metrics with colored squares

## Design system

**Fonts:** Source Sans 3 (body) + DM Mono (parameters/equation), loaded from Google Fonts.

**Colors:**

| Element | Color | Hex |
|---------|-------|-----|
| Lab accent | Sand/buff | `#D4A66A` |
| Orchard accent | Cambridge green | `#3D8B6E` |
| Reef accent | Prussian blue | `#1B4965` |
| Transplant arrows | Terra cotta | `#E07A5F` / `#B85A40` |
| Larvae feedback | Dark sand | `#9A7340` |
| External input | Slate | `#6B7680` |
| Decision pills | Amber on cream | `#92400E` on `#FEF3C7` |
| Body text | Dark liver | `#3D405B` |
| Background | Ivory | `#FAFAF7` |

**Print specs:** At 180 mm width, smallest text is ~5.2 pt (meets Nature's 5 pt minimum).

## Attribution

Coral silhouette illustration by Tracey Saxby, Integration and Application Network (ian.umces.edu/media-library), CC BY-SA 4.0. Must be credited in figure caption.

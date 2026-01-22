# Visual Design Specification for Coral Restoration Model
## Guide for Frontend Development & Data Visualization

**Prepared by:** Data Science Team
**For:** Frontend/Visualization Specialist
**Date:** January 2026
**Model:** Stage-Structured Coral Population Dynamics

---

## 1. VISUALIZATION OBJECTIVES

### Primary Goals
1. **Educational:** Help stakeholders understand complex ecological-restoration dynamics
2. **Decision Support:** Enable managers to compare restoration strategies visually
3. **Scientific Communication:** Present model assumptions and mechanics transparently
4. **Interactive Exploration:** Allow users to manipulate parameters and see real-time results

### Target Audiences
- **Restoration Practitioners:** Need intuitive flow diagrams and outcome comparisons
- **Research Scientists:** Need mathematical accuracy and parameter transparency
- **Funding Agencies:** Need cost-benefit visualizations and success metrics
- **General Public:** Need simplified conceptual overviews

---

## 2. CORE VISUALIZATION COMPONENTS

### 2.1 System Architecture Diagram (Primary Visualization)

**Type:** Interactive network/flow diagram
**Purpose:** Show how corals and larvae move through the restoration system

#### Layout Recommendation

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│         EXTERNAL REFERENCE REEFS (Wild Populations)             │
│                                                                 │
│              ┌──────────────────────────┐                       │
│              │  Spawning Event          │                       │
│              │  λ_R larvae/year         │                       │
│              │  Collection: reef_yield  │                       │
│              └───────────┬──────────────┘                       │
└──────────────────────────┼──────────────────────────────────────┘
                           │
                           │ Wild larvae collected
                           ▼
┌──────────────────────────────────────────────────────────────────┐
│                      LAB FACILITY                                │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  Tile Settlement & Rearing                                 │ │
│  │  ┌──────────────────────┬────────────────────────────┐    │ │
│  │  │  IMMEDIATE (0_TX)    │  1-YEAR RETENTION (1_TX)   │    │ │
│  │  │                      │                            │    │ │
│  │  │  ┌────────────────┐  │  ┌──────────────────────┐  │    │ │
│  │  │  │ T1 (Cement)    │  │  │ T1 (Cement)          │  │    │ │
│  │  │  │ Survival: s0   │  │  │ Survival: s1         │  │    │ │
│  │  │  │ Settlement: 95%│  │  │ Density-dep: exp(-m) │  │    │ │
│  │  │  └───────┬────────┘  │  └──────────┬───────────┘  │    │ │
│  │  │          │           │             │              │    │ │
│  │  │  ┌───────▼────────┐  │  ┌──────────▼───────────┐  │    │ │
│  │  │  │ T2 (Ceramic)   │  │  │ T2 (Ceramic)         │  │    │ │
│  │  │  │ Survival: s0   │  │  │ Survival: s1         │  │    │ │
│  │  │  │ Settlement: 90%│  │  │ Density-dep: exp(-m) │  │    │ │
│  │  │  └───────┬────────┘  │  └──────────┬───────────┘  │    │ │
│  │  │          │           │             │              │    │ │
│  │  │          │ Year i    │             │ Year i+1     │    │ │
│  │  └──────────┼───────────┴─────────────┼──────────────┘    │ │
│  │             │ Outplant immediately    │ Outplant after   │ │
│  │             │                         │ 1 year growth    │ │
│  └─────────────┼─────────────────────────┼──────────────────┘ │
│                │                         │                    │
│         reef_prop (75%)        (1-reef_prop) (25%)            │
│                │                         │                    │
└────────────────┼─────────────────────────┼────────────────────┘
                 │                         │
    ┌────────────┴────────┐       ┌────────▼────────┐
    ▼                     ▼       ▼                 ▼
┌─────────────────┐   ┌────────────────────────────────┐
│  REEF (Target)  │   │  ORCHARD (Nursery/Broodstock)  │
│                 │   │                                │
│  Size Structure │   │  Protected Environment         │
│  ┌────────────┐ │   │  ┌──────────────────────────┐ │
│  │ SC1 (0-10) │ │   │  │ SC2 → SC3 → SC4 → SC5    │ │
│  │  ↓   ↗     │ │   │  │  │    │     │     │      │ │
│  │ SC2 (10+)  │ │   │  │  └────┴─────┴─────┘      │ │
│  │  ↓   ↗     │ │   │  │  Growth (faster)         │ │
│  │ SC3 (100+) │ │   │  │  Survival (higher)       │ │
│  │  ↓   ↗     │ │   │  │  No fragmentation        │ │
│  │ SC4 (900+) │ │   │  └──────────┬───────────────┘ │
│  │  ↓ ↘ ↗     │ │   │             │                 │
│  │ SC5 (4k+)  │ │   │  ┌──────────▼───────────────┐ │
│  │  ↘ Frag ↗  │ │   │  │ Larval Production        │ │
│  └────────────┘ │   │  │ Collected: orchard_yield │ │
│                 │   │  └──────────┬───────────────┘ │
│  Space limited  │   │             │                 │
│  reef_areas cm² │   │             │ Larvae to LAB   │
│                 │   │             └─────────────────┼──┐
│  Carrying       │   │                               │  │
│  Capacity       │   │  Transplant large colonies    │  │
│  Enforcement    │   │  to REEF (optional)           │  │
└─────────────────┘   └───────────────────────────────┘  │
        ▲                         │                       │
        └─────────────────────────┘                       │
          Transplant pathway                              │
                                                          │
                    Feedback loop: Orchard reproduction   │
                    feeds back to lab for more outplants  │
                    ◄─────────────────────────────────────┘
```

#### Visual Elements

**Compartment Boxes:**
- **EXTERNAL:** `#2ECC71` (green) — natural, wild
- **LAB:** `#3498DB` (blue) — controlled, scientific
- **ORCHARD:** `#1ABC9C` (teal) — intermediate, semi-controlled
- **REEF:** `#E74C3C` (coral red) — restoration target

**Arrow Styles:**
```css
.flow-arrow-material {
  stroke: #34495E;
  stroke-width: 3px;
  fill: none;
  marker-end: url(#arrowhead);
}

.flow-arrow-feedback {
  stroke: #9B59B6;
  stroke-width: 2px;
  stroke-dasharray: 5, 5;
  fill: none;
  marker-end: url(#arrowhead-dashed);
}

.flow-arrow-optional {
  stroke: #95A5A6;
  stroke-width: 1.5px;
  stroke-dasharray: 2, 2;
  fill: none;
  opacity: 0.6;
}
```

**Interactive Features:**
1. **Hover on Compartments:**
   - Highlight all incoming/outgoing flows
   - Show capacity constraints as progress bars
   - Display current population size (if simulation running)

2. **Hover on Arrows:**
   - Show parameter name (e.g., "orchard_yield = 0.5")
   - Display quantity of flow (e.g., "2,500 larvae/year")
   - Animate flow direction with particles

3. **Click on Compartments:**
   - Expand to show size class distribution (bar chart)
   - Show demographic parameters in sidebar
   - Plot population trajectory over time

4. **Click on Lab Tile Types:**
   - Show settlement success rate
   - Compare survival curves (s0 vs. s1)
   - Display size distribution at outplanting

**Animation:**
- Use **particle flow** along arrows to show larvae/coral movement
- Particle speed proportional to flow magnitude
- Color particles by source (e.g., external = green, orchard = teal)

---

### 2.2 Size Class Transition Matrix

**Type:** Interactive heatmap grid
**Purpose:** Visualize demographic transition probabilities

#### Layout

```
TRANSITION MATRIX (T) + FRAGMENTATION (F)
Size Classes: SC1 (0-10cm²) → SC5 (>4,000cm²)

        FROM (columns)
      SC1    SC2    SC3    SC4    SC5
TO  ┌─────┬──────┬──────┬──────┬──────┐
SC1 │ 0.80│ 0.02 │ 0.01 │ 0.00 │ 0.00 │ ← Stasis & Shrinkage
SC2 │ 0.15│ 0.75 │ 0.03 │ 0.00 │ 0.00 │
SC3 │ 0.05│ 0.18 │ 0.78 │ 0.05 │ 0.00 │
SC4 │ 0.00│ 0.05 │ 0.15 │ 0.82 │ 0.10 │
SC5 │ 0.00│ 0.00 │ 0.03 │ 0.13 │ 0.90 │ ← Growth
    └─────┴──────┴──────┴──────┴──────┘
                                      ↑ Column sums = 1.0

FRAGMENTATION MATRIX (F) - Overlaid
      SC1    SC2    SC3    SC4    SC5
    ┌─────┬──────┬──────┬──────┬──────┐
SC1 │ 0.00│ 0.00 │ 0.00 │ 0.05 │ 0.05 │
SC2 │ 0.00│ 0.00 │ 0.00 │ 0.10 │ 0.10 │
SC3 │ 0.00│ 0.00 │ 0.00 │ 0.15 │ 0.15 │
SC4 │ 0.00│ 0.00 │ 0.00 │ 0.20 │ 0.20 │
SC5 │ 0.00│ 0.00 │ 0.00 │ 0.10 │ 0.10 │
    └─────┴──────┴──────┴──────┴──────┘
    Only SC4 & SC5 fragment →  ↑    ↑
```

#### Color Scheme

```javascript
// Transition probabilities
const colorScale = d3.scaleSequential()
  .domain([0, 1])
  .interpolator((t) => {
    if (diagonal) return d3.interpolateGreys(t);  // Stasis
    if (aboveDiagonal) return d3.interpolateGreens(t);  // Growth
    if (belowDiagonal) return d3.interpolateOranges(t);  // Shrinkage
  });

// Fragmentation probabilities (overlay)
const fragColorScale = d3.scaleSequential()
  .domain([0, 0.3])
  .interpolator(d3.interpolatePurples);
```

**Visual Treatment:**
- **Cell size:** 60px × 60px
- **Border:** Diagonal cells have thick border (2px) to highlight stasis
- **Text:** Show probability value if > 0.01
- **Fragmentation:** Add striped pattern overlay to cells with fragmentation

**Interactive Features:**
1. **Hover on Cell:**
   - Tooltip: "Probability of transition from SC3 to SC4: 0.15"
   - Highlight entire row and column
   - Show biological interpretation ("Growth")

2. **Toggle View:**
   - Switch between T, F, and combined (T+F) matrices
   - Animate transitions between views

3. **Parameter Editing (Advanced):**
   - Click cell to open slider for editing probability
   - Real-time validation (column must sum to 1.0)
   - Reset to defaults button

---

### 2.3 Population Dynamics Trajectory Plot

**Type:** Multi-series line chart with uncertainty bands
**Purpose:** Show population growth over time for different restoration strategies

#### Layout

```
Population Trajectory: Reef Restoration Scenarios

Total Coral Cover (m²)
    400│                                  ┌─ Scenario A: High orchard yield
       │                                 ╱
    300│                              ╱╱
       │                           ╱╱╱
    200│                        ╱╱╱          ┌─ Scenario B: Immediate outplant
       │                     ╱╱╱           ╱╱
    100│                  ╱╱╱           ╱╱╱
       │               ╱╱╱           ╱╱╱        ┌─ Scenario C: 1-year retention
     50│            ╱╱╱           ╱╱╱        ╱╱╱
       │         ╱╱╱           ╱╱╱        ╱╱╱
       │═══════════════════════════════════════════════
     0 └──────┬─────┬─────┬─────┬─────┬─────┬─────┬───
            0     5    10    15    20    25    30   Year

       ░░░░░ = 90% Confidence Interval (Monte Carlo uncertainty)
       ▓▓▓▓▓ = Management target (200 m²)
```

#### Visual Specifications

**Color Palette (Colorblind-Friendly):**
```javascript
const scenarios = [
  { name: "Scenario A", color: "#0072B2", dashArray: "none" },
  { name: "Scenario B", color: "#009E73", dashArray: "5,5" },
  { name: "Scenario C", color: "#D55E00", dashArray: "2,2" },
  { name: "Baseline", color: "#999999", dashArray: "1,1" }
];
```

**Line Styles:**
- **Median trajectory:** Solid line, 2.5px width
- **Uncertainty bands:** Semi-transparent fill (opacity: 0.2)
- **Management target:** Horizontal dashed line (#CC79A7, 2px)
- **Disturbance events:** Vertical red band with annotation

**Axes:**
- **X-axis:** Year (0–30), gridlines every 5 years
- **Y-axis:** Coral cover (m²), log scale optional for wide range
- **Dual Y-axis:** Population size (# individuals) on right

**Interactive Features:**
1. **Hover on Line:**
   - Vertical crosshair snaps to nearest year
   - Tooltip shows all scenarios' values at that year
   - Highlight selected line

2. **Click on Legend:**
   - Toggle scenario visibility
   - Isolate single scenario (click + Shift)

3. **Zoom & Pan:**
   - Mouse wheel to zoom
   - Click-drag to pan
   - Reset button to original view

4. **Data Export:**
   - Download CSV of time series data
   - Export plot as SVG or PNG

---

### 2.4 Parameter Dashboard

**Type:** Interactive control panel with real-time feedback
**Purpose:** Allow users to explore parameter space and see immediate effects

#### Layout (3-Column Grid)

```
┌─────────────────────────────────────────────────────────────────────┐
│  PARAMETER DASHBOARD                                                │
├───────────────────┬───────────────────┬─────────────────────────────┤
│                   │                   │                             │
│  DEMOGRAPHIC      │  LAB SETTINGS     │  RESTORATION STRATEGY       │
│  PARAMETERS       │                   │                             │
│                   │                   │                             │
│  Survival (SC1)   │  Lab Capacity     │  Orchard Yield              │
│  ├─────●──────┤   │  ├───────●────┤  │  ├───────●──────┤          │
│  0.4    0.8   1.0 │  0    20k   40k  │  0.0   0.5    1.0           │
│                   │                   │                             │
│  Growth (SC3→4)   │  Tile: T1 vs T2   │  Outplant Timing            │
│  ├──────●─────┤   │  ○ T1 (Cement)   │  ○ Immediate (0_TX)         │
│  0.0   0.15  0.3  │  ◉ T2 (Ceramic)  │  ◉ 1-Year (1_TX)            │
│                   │                   │                             │
│  Fragmentation    │  Settlement Rate  │  Reef vs. Orchard           │
│  ├────●──────┤    │  ├──────●─────┤  │  ├─────────●───┤           │
│  0.0   0.1   0.3  │  0.7  0.95  1.0  │  0%(O)  75%(R)  100%(R)     │
│                   │                   │                             │
│  Fecundity (SC5)  │  Density-Dep (m1)│  Reef Capacity              │
│  ├───────●────┤   │  ├●──────────┤   │  ├──────────●──┤           │
│  0   100k   200k  │  0.0  0.02  0.05 │  1 ha    8 ha   20 ha       │
│                   │                   │                             │
└───────────────────┴───────────────────┴─────────────────────────────┘
│                                                                     │
│  SIMULATION OUTPUT (Real-Time Update)                              │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  Population Growth Rate (λ): 1.23  ✓ Growing                │  │
│  │  Final Coral Cover (Year 20): 187 m²                         │  │
│  │  Time to Target (200 m²): 22 years                           │  │
│  │  [▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░] Population Trajectory Chart           │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                     │
│  [Reset to Defaults]  [Run Monte Carlo]  [Export Parameters]       │
└─────────────────────────────────────────────────────────────────────┘
```

#### Widget Specifications

**Sliders:**
```css
.parameter-slider {
  width: 180px;
  height: 8px;
  border-radius: 4px;
  background: linear-gradient(to right, #E8F5E9, #4CAF50);
}

.slider-thumb {
  width: 20px;
  height: 20px;
  border-radius: 50%;
  background: #2196F3;
  box-shadow: 0 2px 4px rgba(0,0,0,0.3);
  cursor: grab;
}

.slider-label {
  font-size: 12px;
  color: #546E7A;
  margin-top: 4px;
}
```

**Radio Buttons (Tile Type, Timing):**
```css
.radio-option {
  display: flex;
  align-items: center;
  padding: 8px;
  border-radius: 4px;
  cursor: pointer;
  transition: background 0.2s;
}

.radio-option:hover {
  background: #F5F5F5;
}

.radio-option.selected {
  background: #E3F2FD;
  border-left: 3px solid #2196F3;
}
```

**Output Metrics:**
```css
.metric-card {
  padding: 12px;
  background: white;
  border-radius: 8px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
  margin-bottom: 8px;
}

.metric-value {
  font-size: 24px;
  font-weight: 600;
  color: #2C3E50;
}

.metric-label {
  font-size: 12px;
  color: #7F8C8D;
  text-transform: uppercase;
}

.metric-status {
  display: inline-block;
  padding: 2px 8px;
  border-radius: 12px;
  font-size: 11px;
  font-weight: 500;
}

.status-growing { background: #C8E6C9; color: #2E7D32; }
.status-stable { background: #FFF9C4; color: #F57F17; }
.status-declining { background: #FFCDD2; color: #C62828; }
```

**Interactive Behavior:**
1. **Slider Adjustment:**
   - Debounce updates (300ms delay)
   - Show current value above thumb while dragging
   - Snap to meaningful increments (e.g., 0.05 for probabilities)

2. **Radio Toggle:**
   - Instant update (no debounce)
   - Show comparison tooltip ("T1 vs T2: 5% better settlement")

3. **Output Updates:**
   - Smooth number transitions (CountUp.js or similar)
   - Flash green when improvement detected
   - Sparkline showing trend if parameter changed recently

4. **Constraint Validation:**
   - Disable invalid combinations (e.g., growth > 1.0)
   - Show warning icon with explanation tooltip

---

### 2.5 Scenario Comparison Table

**Type:** Sortable data table with embedded visualizations
**Purpose:** Compare multiple restoration strategies side-by-side

#### Layout

```
Restoration Strategy Comparison

┌──────────────────┬───────────┬───────────┬───────────┬───────────┐
│ Strategy         │ Scenario A│ Scenario B│ Scenario C│ Baseline  │
├──────────────────┼───────────┼───────────┼───────────┼───────────┤
│ Lab Capacity     │ 40,000    │ 20,000    │ 40,000    │ 10,000    │
│ Tile Type        │ T1        │ T2        │ T1        │ T1        │
│ Outplant Timing  │ 1-Year    │ Immediate │ Immediate │ Immediate │
│ Orchard Yield    │ 0.8       │ 0.5       │ 0.0       │ 0.0       │
├──────────────────┼───────────┼───────────┼───────────┼───────────┤
│ λ (Growth Rate)  │ 1.28 ⭐   │ 1.15 ✓    │ 1.05 ✓    │ 0.92 ✗    │
│ Final Cover (m²) │ 287       │ 195       │ 142       │ 45        │
│ Time to Target   │ 18 years  │ 24 years  │ 32 years  │ Never     │
│ Cost (Estimate)  │ $$$       │ $$        │ $$        │ $         │
├──────────────────┼───────────┼───────────┼───────────┼───────────┤
│ Population       │ ▂▃▅▇█     │ ▂▃▅▆▇     │ ▂▃▄▅▆     │ ▂▃▃▃▃     │
│ Trajectory       │           │           │           │           │
└──────────────────┴───────────┴───────────┴───────────┴───────────┘

Click column header to sort | ✓ = Growing | ✗ = Declining | ⭐ = Best
```

#### Visual Specifications

**Table Styling:**
```css
.comparison-table {
  width: 100%;
  border-collapse: collapse;
  font-family: 'Inter', sans-serif;
}

.comparison-table th {
  background: #37474F;
  color: white;
  padding: 12px;
  text-align: left;
  font-weight: 600;
  cursor: pointer;
}

.comparison-table th:hover {
  background: #455A64;
}

.comparison-table td {
  padding: 10px 12px;
  border-bottom: 1px solid #ECEFF1;
}

.comparison-table tr:hover {
  background: #F5F5F5;
}

.best-scenario {
  background: #E8F5E9 !important;
  border-left: 4px solid #4CAF50;
}
```

**Embedded Sparklines:**
- Use mini line charts (40px × 20px) for trajectory
- Color by performance: green (growing), yellow (stable), red (declining)

**Status Indicators:**
```css
.status-icon {
  display: inline-block;
  width: 16px;
  height: 16px;
  border-radius: 50%;
  margin-right: 4px;
}

.status-best { background: #4CAF50; content: "⭐"; }
.status-good { background: #8BC34A; content: "✓"; }
.status-poor { background: #F44336; content: "✗"; }
```

**Interactive Features:**
1. **Sort by Column:**
   - Click header to toggle ascending/descending
   - Visual indicator (▲▼) for sort direction

2. **Row Hover:**
   - Highlight entire row
   - Show detailed tooltip with parameter justification

3. **Cell Click:**
   - Drill down to see full time series for that scenario
   - Open parameter details in modal

4. **Export:**
   - Download as CSV
   - Generate PDF report with embedded charts

---

## 3. COLOR PALETTE & DESIGN SYSTEM

### 3.1 Primary Colors

```css
:root {
  /* Compartment Colors */
  --color-external: #2ECC71;  /* Green - Natural/Wild */
  --color-lab: #3498DB;       /* Blue - Scientific/Controlled */
  --color-orchard: #1ABC9C;   /* Teal - Semi-Controlled */
  --color-reef: #E74C3C;      /* Coral Red - Restoration Target */

  /* Demographic Process Colors */
  --color-growth: #27AE60;    /* Green - Growth transitions */
  --color-shrinkage: #E67E22; /* Orange - Shrinkage/mortality */
  --color-stasis: #95A5A6;    /* Gray - Staying in same class */
  --color-fragmentation: #9B59B6; /* Purple - Asexual reproduction */

  /* Status Colors */
  --color-growing: #4CAF50;   /* Green - λ > 1 */
  --color-stable: #FFC107;    /* Yellow - λ ≈ 1 */
  --color-declining: #F44336; /* Red - λ < 1 */

  /* UI Colors */
  --color-primary: #2196F3;
  --color-secondary: #607D8B;
  --color-background: #FAFAFA;
  --color-surface: #FFFFFF;
  --color-text: #212121;
  --color-text-secondary: #757575;
}
```

### 3.2 Typography

```css
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap');

body {
  font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
  font-size: 14px;
  line-height: 1.5;
  color: var(--color-text);
}

h1 { font-size: 28px; font-weight: 700; margin-bottom: 16px; }
h2 { font-size: 22px; font-weight: 600; margin-bottom: 12px; }
h3 { font-size: 18px; font-weight: 600; margin-bottom: 8px; }

.label { font-size: 12px; font-weight: 500; text-transform: uppercase; letter-spacing: 0.5px; }
.caption { font-size: 11px; color: var(--color-text-secondary); }
.monospace { font-family: 'Fira Code', monospace; }
```

### 3.3 Iconography

**Recommended Icon Library:** Feather Icons or Material Design Icons

**Key Icons:**
- **Compartments:** `box`, `database`, `layers`, `target`
- **Actions:** `arrow-right`, `repeat`, `shuffle`, `trending-up`
- **Controls:** `sliders`, `settings`, `play`, `pause`, `refresh`
- **Status:** `check-circle`, `alert-circle`, `x-circle`
- **Data:** `bar-chart-2`, `pie-chart`, `activity`, `download`

---

## 4. INTERACTIVE FEATURES

### 4.1 Animation Specifications

**Particle Flow Animation (Larvae/Coral Movement):**
```javascript
// Particle system for visualizing flows
const particleConfig = {
  particleSize: 4,          // px
  particleColor: "#3498DB", // Lab-sourced particles
  particleSpeed: 2,         // px/frame (60fps)
  particleSpawnRate: 5,     // particles/second
  particleLifetime: 3000,   // ms
  flowPath: "M10,50 Q50,10 90,50", // SVG path
};

// Scale spawn rate by flow magnitude
const spawnRate = baseRate * (flowMagnitude / maxFlow);
```

**Transition Animations:**
```javascript
// When changing between views (e.g., T matrix → F matrix)
const transitionConfig = {
  duration: 600,       // ms
  easing: "cubicInOut",
  stagger: 50,        // ms delay between cells
};

// Animate cell color changes
d3.selectAll(".matrix-cell")
  .transition()
  .duration(transitionConfig.duration)
  .ease(d3.easeCubicInOut)
  .style("fill", (d) => colorScale(d.value));
```

**Number Count-Up Animation:**
```javascript
// When metric values update (e.g., population size)
const countUpOptions = {
  startVal: previousValue,
  endVal: newValue,
  duration: 1.5,      // seconds
  useEasing: true,
  easingFn: (t, b, c, d) => c * (t /= d) * t + b, // easeInQuad
  separator: ",",
  decimal: ".",
  decimals: (newValue < 1 ? 2 : 0),
};

new CountUp("metric-value", newValue, countUpOptions).start();
```

### 4.2 Responsiveness

**Breakpoints:**
```css
/* Mobile: < 640px */
@media (max-width: 639px) {
  .system-diagram {
    transform: scale(0.7);
    transform-origin: top left;
  }
  .parameter-dashboard {
    grid-template-columns: 1fr; /* Stack vertically */
  }
}

/* Tablet: 640px - 1024px */
@media (min-width: 640px) and (max-width: 1023px) {
  .parameter-dashboard {
    grid-template-columns: repeat(2, 1fr);
  }
}

/* Desktop: ≥ 1024px */
@media (min-width: 1024px) {
  .parameter-dashboard {
    grid-template-columns: repeat(3, 1fr);
  }
}
```

**Touch Interactions:**
- **Sliders:** Increase touch target size to 44px × 44px
- **Hover states:** Replace with tap-to-show on mobile
- **Zoom/Pan:** Enable pinch-to-zoom on charts

### 4.3 Accessibility

**WCAG 2.1 AA Compliance:**

1. **Color Contrast:**
   - Minimum ratio 4.5:1 for normal text
   - Minimum ratio 3:1 for large text (≥18px)
   - Use tools like Stark or Contrast Checker

2. **Keyboard Navigation:**
   ```javascript
   // Tab index for interactive elements
   <button class="scenario-toggle" tabindex="0" aria-label="Toggle Scenario A">

   // Keyboard event handlers
   element.addEventListener('keydown', (e) => {
     if (e.key === 'Enter' || e.key === ' ') {
       // Trigger action
     }
   });
   ```

3. **Screen Reader Support:**
   ```html
   <!-- Semantic HTML -->
   <nav aria-label="Parameter controls">
     <h2 id="demographic-heading">Demographic Parameters</h2>
     <div role="group" aria-labelledby="demographic-heading">
       <label for="survival-sc1">Survival (SC1)</label>
       <input type="range" id="survival-sc1"
              aria-valuemin="0" aria-valuemax="1"
              aria-valuenow="0.8" aria-valuetext="0.8 or 80%">
     </div>
   </nav>

   <!-- Live regions for dynamic updates -->
   <div role="status" aria-live="polite" aria-atomic="true">
     Population growth rate updated to 1.28
   </div>
   ```

4. **Alt Text for Visualizations:**
   ```html
   <svg role="img" aria-labelledby="flow-diagram-title flow-diagram-desc">
     <title id="flow-diagram-title">Coral Restoration System Flow Diagram</title>
     <desc id="flow-diagram-desc">
       Diagram showing movement of corals and larvae through four compartments:
       External reefs provide wild larvae, Lab processes larvae onto tiles,
       Orchard grows nursery corals, and Reef is the restoration target.
       Arrows show flow directions with feedback loops.
     </desc>
     <!-- SVG content -->
   </svg>
   ```

---

## 5. TECHNICAL IMPLEMENTATION RECOMMENDATIONS

### 5.1 Technology Stack

**Recommended Libraries:**

1. **Visualization:**
   - **D3.js v7** — Core data binding, SVG manipulation, transitions
   - **Plotly.js** — High-level charting (population trajectories)
   - **Cytoscape.js** (Alternative) — If preferring network graph library for flow diagram

2. **UI Framework:**
   - **React** — Component architecture, state management
   - **Svelte** (Alternative) — Lighter weight, reactive
   - **Vue 3** (Alternative) — Progressive framework

3. **Styling:**
   - **Tailwind CSS** — Utility-first CSS framework
   - **Styled Components** (if React) — CSS-in-JS
   - **SCSS/Sass** — Preprocessor for custom styles

4. **Animation:**
   - **Framer Motion** (React) — Declarative animations
   - **GSAP** — Advanced timeline animations
   - **CountUp.js** — Number animations

5. **State Management:**
   - **Zustand** (React, lightweight) — Simple state store
   - **Redux Toolkit** (React, complex apps) — Robust state management
   - **Pinia** (Vue) — Intuitive state management

6. **Data Handling:**
   - **Lodash** — Utility functions
   - **Math.js** — Matrix operations (if computing locally)
   - **Papaparse** — CSV parsing for data export

### 5.2 Component Architecture (React Example)

```
src/
├── components/
│   ├── SystemDiagram/
│   │   ├── SystemDiagram.jsx
│   │   ├── Compartment.jsx
│   │   ├── FlowArrow.jsx
│   │   ├── ParticleSystem.jsx
│   │   └── SystemDiagram.module.css
│   ├── TransitionMatrix/
│   │   ├── TransitionMatrix.jsx
│   │   ├── MatrixCell.jsx
│   │   ├── ColorLegend.jsx
│   │   └── TransitionMatrix.module.css
│   ├── TrajectoryPlot/
│   │   ├── TrajectoryPlot.jsx
│   │   ├── UncertaintyBand.jsx
│   │   └── TrajectoryPlot.module.css
│   ├── ParameterDashboard/
│   │   ├── ParameterDashboard.jsx
│   │   ├── Slider.jsx
│   │   ├── RadioGroup.jsx
│   │   ├── MetricCard.jsx
│   │   └── ParameterDashboard.module.css
│   └── ComparisonTable/
│       ├── ComparisonTable.jsx
│       ├── Sparkline.jsx
│       └── ComparisonTable.module.css
├── hooks/
│   ├── useSimulation.js       // Run model simulation
│   ├── useParameters.js       // Parameter state management
│   └── useDebounce.js         // Debounce slider updates
├── utils/
│   ├── modelRunner.js         // Interface to R model or JS port
│   ├── colorScales.js         // D3 color scale generators
│   └── exportData.js          // CSV/PNG export functions
└── store/
    └── simulationStore.js     // Global state (Zustand/Redux)
```

### 5.3 Model Integration Options

**Option 1: R Backend with API (Recommended for Prototyping)**
```javascript
// Frontend calls R model via REST API (Plumber)
async function runSimulation(parameters) {
  const response = await fetch('/api/simulate', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(parameters),
  });
  return await response.json();
}
```

**Backend (R + Plumber):**
```R
# api.R
library(plumber)

#* @post /simulate
function(req, res) {
  params <- jsonlite::fromJSON(req$postBody)

  # Run model
  result <- rse_mod1(
    years = params$years,
    surv_pars.r = params$surv_pars_r,
    # ... other parameters
  )

  # Return JSON
  list(
    reef_pops = result$reef_pops,
    summary = model_summ(result, "reef", "ind", 1, 1, 2)
  )
}
```

**Option 2: WebAssembly (R via Webr)**
```javascript
// Run R model entirely in browser (no backend needed)
import { WebR } from 'webr';

const webR = new WebR();
await webR.init();

// Load model functions
await webR.evalRVoid(`source('rse_funs.R')`);
await webR.evalRVoid(`source('coral_demographic_funs.R')`);

// Run simulation
const result = await webR.evalR(`
  rse_mod1(years=20, n=5, ...)
`);

const trajectory = await result.toArray();
```

**Option 3: JavaScript Port (Best Performance)**
- Translate core model functions to JavaScript
- Use numeric.js or mathjs for matrix operations
- Trade-off: Development effort vs. performance

**Recommendation:** Start with **Option 1** (R backend API) for rapid prototyping, migrate to **Option 2** (WebR) for public deployment if no server available.

---

## 6. DELIVERABLES CHECKLIST

### Phase 1: Core Visualizations (Week 1-2)
- [ ] System architecture flow diagram (static)
- [ ] Size class transition matrix heatmap
- [ ] Population trajectory line chart
- [ ] Basic parameter sliders (survival, growth)

### Phase 2: Interactivity (Week 3-4)
- [ ] Parameter dashboard with real-time updates
- [ ] Hover tooltips on all visualizations
- [ ] Scenario comparison table
- [ ] Animation: particle flow on system diagram

### Phase 3: Advanced Features (Week 5-6)
- [ ] Monte Carlo uncertainty visualization
- [ ] Export functionality (CSV, PNG)
- [ ] Accessibility audit and fixes
- [ ] Responsive design for mobile/tablet

### Phase 4: Polish & Documentation (Week 7-8)
- [ ] User guide / tutorial overlay
- [ ] Performance optimization
- [ ] Browser compatibility testing
- [ ] Deployment and hosting setup

---

## 7. EXAMPLE MOCKUPS

### 7.1 Landing Page Mockup

```
┌─────────────────────────────────────────────────────────────────┐
│  Coral Restoration Model Explorer                    [Login] │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│       ╔════════════════════════════════════════════╗           │
│       ║  Interactive Population Dynamics Model     ║           │
│       ║  for Acropora palmata Restoration          ║           │
│       ╚════════════════════════════════════════════╝           │
│                                                                 │
│   Explore restoration strategies by simulating coral           │
│   populations through lab rearing, nursery cultivation,        │
│   and field outplanting.                                       │
│                                                                 │
│   ┌───────────────┐  ┌───────────────┐  ┌───────────────┐    │
│   │ 🔬 Explore    │  │ 📊 Compare    │  │ 📚 Learn      │    │
│   │ Model         │  │ Scenarios     │  │ About Model   │    │
│   └───────────────┘  └───────────────┘  └───────────────┘    │
│                                                                 │
│   Quick Start: [Run Default Simulation] ─────────────────────► │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 7.2 Main Dashboard Mockup

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ ☰ Menu    Coral Restoration Model     [Scenario: Default] [Run] [Reset]    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌───────────────────────────────────┬───────────────────────────────────┐ │
│  │  SYSTEM FLOW DIAGRAM              │  POPULATION TRAJECTORY            │ │
│  │                                   │                                   │ │
│  │  [Interactive flow visualization] │  [Line chart with uncertainty]    │ │
│  │                                   │                                   │ │
│  │  ⚙ External                       │  Coral Cover (m²)                 │ │
│  │     ↓ Larvae                      │    300│         ╱╱╱               │ │
│  │  ⚙ Lab → ⚙ Orchard                │       │      ╱╱╱                  │ │
│  │     ↓        ↓                    │    200│   ╱╱╱                     │ │
│  │  ⚙ Reef ←────┘                    │       │╱╱╱                        │ │
│  │                                   │       └────────────────────       │ │
│  │  Hover for details                │       0    10    20    30 Year    │ │
│  └───────────────────────────────────┴───────────────────────────────────┘ │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  PARAMETER CONTROLS                                                 │   │
│  │  ┌──────────────┬──────────────┬──────────────┬──────────────────┐  │   │
│  │  │ Demographic  │ Lab Settings │ Restoration  │ [Live Updates]   │  │   │
│  │  │              │              │ Strategy     │                  │  │   │
│  │  │ [Sliders]    │ [Toggles]    │ [Sliders]    │ λ = 1.15 ✓       │  │   │
│  │  └──────────────┴──────────────┴──────────────┴──────────────────┘  │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  [💾 Save Scenario] [📥 Export Data] [📖 Help] [🔬 Advanced Mode]          │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 8. TESTING & VALIDATION

### 8.1 Visual Testing

**Cross-Browser Testing:**
- Chrome/Edge (Chromium) — Latest 2 versions
- Firefox — Latest 2 versions
- Safari — Latest 2 versions (macOS, iOS)

**Device Testing:**
- Desktop: 1920×1080, 1366×768
- Tablet: iPad (1024×768), Android tablets
- Mobile: iPhone 12/13/14, Galaxy S21/S22

### 8.2 Performance Benchmarks

**Target Metrics:**
- **Initial Load:** < 3 seconds (3G connection)
- **Simulation Run:** < 500ms (20-year simulation)
- **Parameter Update:** < 100ms (slider to chart update)
- **Animation Frame Rate:** 60fps (no dropped frames)

**Optimization Strategies:**
- Lazy load heavy visualizations
- Debounce slider updates (300ms)
- Use Web Workers for simulation computation
- Implement virtual scrolling for large tables
- Compress SVG assets

### 8.3 Accessibility Audit

**Tools:**
- **axe DevTools** — Automated accessibility testing
- **WAVE** — Web accessibility evaluation
- **Lighthouse** — Performance + accessibility scores

**Manual Testing:**
- Keyboard-only navigation
- Screen reader testing (NVDA, JAWS, VoiceOver)
- Color blindness simulation (Stark, Color Oracle)
- Text resizing (up to 200%)

---

## 9. DEPLOYMENT RECOMMENDATIONS

### 9.1 Hosting Options

**Static Site Hosting (If using WebR, no backend):**
- **Netlify** — Free tier, CI/CD from GitHub, great DX
- **Vercel** — Similar to Netlify, optimized for React/Next.js
- **GitHub Pages** — Free, good for open-source projects

**Full-Stack Hosting (If using R backend API):**
- **Heroku** — Easy R deployment (Heroku buildpack)
- **DigitalOcean App Platform** — Affordable, scalable
- **AWS Elastic Beanstalk** — Enterprise-grade, more complex
- **Google Cloud Run** — Containerized apps, pay-per-use

### 9.2 CI/CD Pipeline

**Example GitHub Actions Workflow:**
```yaml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  build-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: 18
      - run: npm install
      - run: npm run build
      - run: npm test
      - uses: netlify/actions/cli@master
        with:
          args: deploy --prod
        env:
          NETLIFY_AUTH_TOKEN: ${{ secrets.NETLIFY_TOKEN }}
```

---

## 10. FUTURE ENHANCEMENTS

### 10.1 Phase 2 Features

1. **3D Visualization:**
   - Use Three.js to show coral colonies in 3D space
   - Size class represented by model height/volume
   - Camera controls for exploration

2. **Storytelling Mode:**
   - Guided tour through model components
   - Scrollytelling with scroll-triggered animations
   - Narrative explanations for each section

3. **Machine Learning Integration:**
   - Train surrogate model (neural network) for instant predictions
   - Parameter optimization via reinforcement learning
   - Display confidence intervals from ensemble models

4. **Collaborative Features:**
   - Share scenarios via URL (parameter state in query string)
   - Cloud save/load scenarios (user accounts)
   - Community scenario library

5. **Mobile App:**
   - React Native or Flutter port
   - Offline mode with local simulation
   - Field data collection integration

### 10.2 Research Extensions

1. **Sensitivity Analysis Dashboard:**
   - Tornado charts showing parameter influence
   - Sobol indices for global sensitivity
   - Monte Carlo simulation visualizations

2. **Multi-Objective Optimization:**
   - Pareto frontier visualization (cost vs. cover)
   - Interactive trade-off exploration
   - Constraint satisfaction highlighting

3. **Climate Scenarios:**
   - Toggle future climate projections
   - Bleaching event simulator
   - Temperature-dependent vital rates

---

## APPENDIX: DETAILED SPECIFICATIONS

### A. SVG Path Syntax for Flow Arrows

**Curved Arrow (Bezier):**
```svg
<path d="M10,50 Q30,10 50,50"
      stroke="#34495E"
      stroke-width="2"
      fill="none"
      marker-end="url(#arrow)" />

<defs>
  <marker id="arrow" markerWidth="10" markerHeight="10"
          refX="8" refY="3" orient="auto" markerUnits="strokeWidth">
    <path d="M0,0 L0,6 L9,3 z" fill="#34495E" />
  </marker>
</defs>
```

**Animated Dashed Flow:**
```css
@keyframes dash-flow {
  to {
    stroke-dashoffset: -100;
  }
}

.flow-arrow {
  stroke-dasharray: 10 5;
  animation: dash-flow 2s linear infinite;
}
```

### B. D3.js Code Snippet for Transition Matrix

```javascript
const data = [
  { from: "SC1", to: "SC1", value: 0.80, type: "stasis" },
  { from: "SC1", to: "SC2", value: 0.15, type: "growth" },
  // ... more cells
];

const colorScale = (d) => {
  if (d.type === "stasis") return d3.interpolateGreys(d.value);
  if (d.type === "growth") return d3.interpolateGreens(d.value);
  if (d.type === "shrinkage") return d3.interpolateOranges(d.value);
};

svg.selectAll("rect")
  .data(data)
  .enter()
  .append("rect")
  .attr("x", d => xScale(d.from))
  .attr("y", d => yScale(d.to))
  .attr("width", cellSize)
  .attr("height", cellSize)
  .attr("fill", colorScale)
  .on("mouseover", showTooltip)
  .on("mouseout", hideTooltip);
```

### C. React Component Example (Parameter Slider)

```jsx
import React, { useState, useEffect } from 'react';
import { useDebounce } from '../hooks/useDebounce';

function ParameterSlider({
  label,
  min,
  max,
  step,
  initialValue,
  onChange
}) {
  const [value, setValue] = useState(initialValue);
  const debouncedValue = useDebounce(value, 300);

  useEffect(() => {
    onChange(debouncedValue);
  }, [debouncedValue, onChange]);

  return (
    <div className="parameter-slider">
      <label>
        {label}
        <span className="value-display">{value.toFixed(2)}</span>
      </label>
      <input
        type="range"
        min={min}
        max={max}
        step={step}
        value={value}
        onChange={(e) => setValue(parseFloat(e.target.value))}
        aria-label={label}
        aria-valuemin={min}
        aria-valuemax={max}
        aria-valuenow={value}
      />
      <div className="range-labels">
        <span>{min}</span>
        <span>{max}</span>
      </div>
    </div>
  );
}

export default ParameterSlider;
```

---

**END OF VISUAL DESIGN SPECIFICATION**

This document provides complete guidance for frontend development. For technical questions about the model itself, refer to `MODEL_ARCHITECTURE_SPECIFICATION.md`. For implementation details, see the R code in `rse_funs.R` and `coral_demographic_funs.R`.

**Contact:** [Data Science Team]
**Last Updated:** January 2026

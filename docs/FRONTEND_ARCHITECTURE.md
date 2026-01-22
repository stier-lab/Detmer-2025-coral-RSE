# Coral Restoration Model - Frontend Architecture Specification

## Executive Summary

This document specifies the production-ready frontend architecture for the Coral Restoration System Dynamics Model web application. The application will enable ecologists, restoration practitioners, and researchers to interact with, visualize, and analyze complex coral population dynamics without requiring programming knowledge.

**Technology Stack:** React 18 + TypeScript + Vite + D3.js + TailwindCSS
**Deployment Target:** Static hosting (Netlify/Vercel) with optional R backend via Plumber API
**Performance Target:** Lighthouse score 90+, FCP < 2s, TTI < 4s

---

## 1. APPLICATION ARCHITECTURE

### 1.1 Tech Stack Rationale

| Technology | Purpose | Justification |
|------------|---------|---------------|
| **React 18** | UI Framework | Industry standard, excellent ecosystem, concurrent rendering for smooth interactions |
| **TypeScript** | Type Safety | Catch errors early, better IDE support, self-documenting code |
| **Vite** | Build Tool | Fast HMR, optimized builds, modern dev experience |
| **D3.js v7** | Data Visualization | Best-in-class for complex scientific visualizations, SVG manipulation |
| **TailwindCSS** | Styling | Rapid development, consistent design system, excellent performance |
| **Recharts** | Chart Library | React-native charts, accessible, responsive out-of-box |
| **Zustand** | State Management | Lightweight, simple API, perfect for mid-size apps |
| **React Query** | Data Fetching | Caching, background updates, optimistic UI for API calls |
| **Vitest** | Unit Testing | Vite-native, fast, compatible with Jest API |
| **Playwright** | E2E Testing | Cross-browser, reliable, great debugging experience |

### 1.2 Project Structure

```
coral-restoration-app/
├── public/
│   ├── favicon.ico
│   └── model-diagram.svg
├── src/
│   ├── assets/
│   │   ├── icons/
│   │   └── images/
│   ├── components/
│   │   ├── ui/                    # Design system components
│   │   │   ├── Button.tsx
│   │   │   ├── Card.tsx
│   │   │   ├── Input.tsx
│   │   │   ├── Slider.tsx
│   │   │   ├── Tabs.tsx
│   │   │   └── Tooltip.tsx
│   │   ├── visualizations/        # D3.js visualization components
│   │   │   ├── SystemFlowDiagram.tsx
│   │   │   ├── TransitionMatrix.tsx
│   │   │   ├── PopulationTrajectory.tsx
│   │   │   ├── SizeClassDistribution.tsx
│   │   │   └── ParameterSensitivity.tsx
│   │   ├── features/              # Feature-specific components
│   │   │   ├── ParameterPanel.tsx
│   │   │   ├── ScenarioComparison.tsx
│   │   │   ├── SimulationControls.tsx
│   │   │   └── ResultsExport.tsx
│   │   └── layout/                # Layout components
│   │       ├── Header.tsx
│   │       ├── Sidebar.tsx
│   │       └── Footer.tsx
│   ├── hooks/                     # Custom React hooks
│   │   ├── useSimulation.ts
│   │   ├── useParameters.ts
│   │   └── useVisualization.ts
│   ├── lib/                       # Core logic
│   │   ├── model/                 # Model calculations
│   │   │   ├── matrices.ts
│   │   │   ├── population.ts
│   │   │   ├── demographics.ts
│   │   │   └── simulation.ts
│   │   ├── utils/                 # Utility functions
│   │   │   ├── formatting.ts
│   │   │   ├── validation.ts
│   │   │   └── export.ts
│   │   └── constants.ts           # Constants and defaults
│   ├── store/                     # Zustand stores
│   │   ├── parameterStore.ts
│   │   ├── simulationStore.ts
│   │   └── uiStore.ts
│   ├── types/                     # TypeScript definitions
│   │   ├── model.ts
│   │   ├── parameters.ts
│   │   └── visualization.ts
│   ├── pages/                     # Page components
│   │   ├── Home.tsx
│   │   ├── ModelExplorer.tsx
│   │   ├── ScenarioBuilder.tsx
│   │   └── Documentation.tsx
│   ├── styles/
│   │   └── globals.css
│   ├── App.tsx
│   └── main.tsx
├── tests/
│   ├── unit/
│   ├── integration/
│   └── e2e/
├── package.json
├── tsconfig.json
├── vite.config.ts
├── tailwind.config.js
└── README.md
```

### 1.3 Component Architecture

#### Atomic Design Principles

```
Atoms (Basic UI)
├── Button, Input, Slider, Badge, Icon, Tooltip
│
Molecules (Simple combinations)
├── ParameterInput (Label + Slider + Value display)
├── CompartmentCard (Icon + Title + Description)
├── SizeClassChip (Badge + Icon + Label)
│
Organisms (Complex features)
├── ParameterPanel (Multiple ParameterInputs + Reset button)
├── SystemFlowDiagram (SVG container + Compartments + Arrows)
├── SimulationControls (Play/Pause + Speed + Timeline)
│
Templates (Page layouts)
├── DashboardLayout (Header + Sidebar + Main + Footer)
├── FullScreenVisualization (Header + Viz + Controls)
│
Pages (Complete views)
└── ModelExplorer, ScenarioBuilder, Documentation
```

---

## 2. CORE FEATURES & IMPLEMENTATION

### 2.1 Feature: Interactive System Flow Diagram

**User Story:** As a restoration practitioner, I want to see how corals and larvae move through the system so I can understand restoration pathways.

**Component:** `SystemFlowDiagram.tsx`

**Technical Requirements:**
- SVG-based D3.js visualization
- Responsive layout (adapts to viewport)
- Animated particle flows along arrows
- Click to expand compartment details
- Hover to highlight connected flows

**Implementation Details:**

```typescript
// src/types/model.ts
export interface Compartment {
  id: 'external' | 'lab' | 'orchard' | 'reef';
  label: string;
  color: string;
  position: { x: number; y: number };
  size: { width: number; height: number };
  population?: PopulationVector;
  capacity?: number;
}

export interface Flow {
  id: string;
  source: string;
  target: string;
  label: string;
  value: number;
  type: 'material' | 'feedback' | 'optional';
}

// src/components/visualizations/SystemFlowDiagram.tsx
interface Props {
  compartments: Compartment[];
  flows: Flow[];
  onCompartmentClick?: (id: string) => void;
  highlightPath?: string[];
  showAnimation?: boolean;
}
```

**Accessibility:**
- Keyboard navigation (Tab through compartments)
- ARIA labels for each compartment and flow
- Screen reader announces flow values on focus
- Color contrast meets WCAG AA (4.5:1)

**Performance:**
- Use `React.memo` for expensive renders
- Debounce window resize events
- Virtual scrolling for large datasets
- RequestAnimationFrame for smooth animations

---

### 2.2 Feature: Parameter Dashboard

**User Story:** As a researcher, I want to adjust model parameters and see real-time impacts on population dynamics.

**Component:** `ParameterPanel.tsx`

**Parameters Organized by Category:**

```typescript
interface ParameterCategory {
  id: string;
  label: string;
  description: string;
  parameters: Parameter[];
}

interface Parameter {
  id: string;
  label: string;
  description: string;
  value: number;
  min: number;
  max: number;
  step: number;
  unit?: string;
  category: 'survival' | 'growth' | 'reproduction' | 'capacity' | 'management';
}

// Example categories
const categories: ParameterCategory[] = [
  {
    id: 'reef-survival',
    label: 'Reef Survival Rates',
    description: 'Size-specific annual survival probabilities on restoration reefs',
    parameters: [
      { id: 'mu_r_sc1', label: 'SC1 Survival', value: 0.4, min: 0, max: 1, step: 0.05, unit: 'proportion' },
      { id: 'mu_r_sc2', label: 'SC2 Survival', value: 0.6, min: 0, max: 1, step: 0.05, unit: 'proportion' },
      // ... SC3-SC5
    ]
  },
  {
    id: 'capacity',
    label: 'Carrying Capacity',
    description: 'Space limitations for each compartment',
    parameters: [
      { id: 'reef_area', label: 'Reef Area', value: 10000000, min: 1e6, max: 1e8, step: 1e6, unit: 'cm²' },
      { id: 'orchard_size', label: 'Orchard Capacity', value: 1000, min: 100, max: 5000, step: 100, unit: 'colonies' }
    ]
  }
];
```

**UI Features:**
- Grouped accordion layout (expand/collapse categories)
- Range sliders with live value display
- Reset to default button per parameter and globally
- Parameter presets ("Conservative", "Optimistic", "Field-Calibrated")
- Visual indicators when values deviate from defaults

**State Management:**

```typescript
// src/store/parameterStore.ts
import create from 'zustand';

interface ParameterStore {
  parameters: Record<string, number>;
  defaults: Record<string, number>;
  updateParameter: (id: string, value: number) => void;
  resetParameter: (id: string) => void;
  resetAll: () => void;
  loadPreset: (preset: string) => void;
}

export const useParameterStore = create<ParameterStore>((set) => ({
  parameters: DEFAULT_PARAMETERS,
  defaults: DEFAULT_PARAMETERS,
  updateParameter: (id, value) =>
    set((state) => ({
      parameters: { ...state.parameters, [id]: value }
    })),
  resetParameter: (id) =>
    set((state) => ({
      parameters: { ...state.parameters, [id]: state.defaults[id] }
    })),
  resetAll: () =>
    set((state) => ({ parameters: { ...state.defaults } })),
  loadPreset: (preset) =>
    set({ parameters: PRESETS[preset] })
}));
```

---

### 2.3 Feature: Population Trajectory Visualization

**User Story:** As a manager, I want to see projected coral populations over time to evaluate restoration success.

**Component:** `PopulationTrajectory.tsx`

**Chart Types:**
1. **Stacked Area Chart** - Total population by size class over time
2. **Line Chart** - Individual size class trajectories
3. **Compartment Comparison** - Reef vs. Orchard populations

**Implementation with Recharts:**

```typescript
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts';

interface TrajectoryData {
  year: number;
  sc1: number;
  sc2: number;
  sc3: number;
  sc4: number;
  sc5: number;
  total: number;
}

const PopulationTrajectory: React.FC<{ data: TrajectoryData[] }> = ({ data }) => {
  return (
    <ResponsiveContainer width="100%" height={400}>
      <LineChart data={data} margin={{ top: 5, right: 30, left: 20, bottom: 5 }}>
        <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
        <XAxis
          dataKey="year"
          label={{ value: 'Year', position: 'insideBottom', offset: -5 }}
        />
        <YAxis
          label={{ value: 'Population Size (colonies)', angle: -90, position: 'insideLeft' }}
          tickFormatter={(value) => value.toLocaleString()}
        />
        <Tooltip
          formatter={(value: number) => value.toLocaleString()}
          contentStyle={{ backgroundColor: 'rgba(255, 255, 255, 0.95)', border: '1px solid #d1d5db' }}
        />
        <Legend verticalAlign="top" height={36} />
        <Line type="monotone" dataKey="sc1" stroke="#10b981" strokeWidth={2} name="SC1 (0-10cm²)" />
        <Line type="monotone" dataKey="sc2" stroke="#3b82f6" strokeWidth={2} name="SC2 (10-100cm²)" />
        <Line type="monotone" dataKey="sc3" stroke="#8b5cf6" strokeWidth={2} name="SC3 (100-900cm²)" />
        <Line type="monotone" dataKey="sc4" stroke="#f59e0b" strokeWidth={2} name="SC4 (900-4000cm²)" />
        <Line type="monotone" dataKey="sc5" stroke="#ef4444" strokeWidth={2} name="SC5 (>4000cm²)" />
      </LineChart>
    </ResponsiveContainer>
  );
};
```

**Interactive Features:**
- Toggle size classes on/off
- Zoom/pan on time axis
- Hover to see exact values
- Export chart as PNG/SVG

---

### 2.4 Feature: Scenario Comparison

**User Story:** As a decision-maker, I want to compare multiple restoration strategies side-by-side.

**Component:** `ScenarioComparison.tsx`

**Functionality:**
- Create named scenarios with different parameter sets
- Run simulations for each scenario
- Display results in comparison table
- Visual diff highlighting (green = better, red = worse)

**Data Structure:**

```typescript
interface Scenario {
  id: string;
  name: string;
  description: string;
  parameters: Record<string, number>;
  results?: SimulationResults;
  createdAt: Date;
}

interface SimulationResults {
  finalPopulation: number;
  peakPopulation: number;
  timeToTarget: number | null;
  coralCover: number[];
  reproductiveOutput: number[];
  extinctionRisk: number;
}

interface ComparisonMetric {
  label: string;
  accessor: (results: SimulationResults) => number;
  format: (value: number) => string;
  higherIsBetter: boolean;
}

const COMPARISON_METRICS: ComparisonMetric[] = [
  {
    label: 'Final Population (Year 50)',
    accessor: (r) => r.finalPopulation,
    format: (v) => v.toLocaleString(),
    higherIsBetter: true
  },
  {
    label: 'Peak Population',
    accessor: (r) => r.peakPopulation,
    format: (v) => v.toLocaleString(),
    higherIsBetter: true
  },
  {
    label: 'Years to 5000 colonies',
    accessor: (r) => r.timeToTarget ?? Infinity,
    format: (v) => v === Infinity ? 'Never' : v.toString(),
    higherIsBetter: false
  },
  {
    label: 'Extinction Risk',
    accessor: (r) => r.extinctionRisk,
    format: (v) => `${(v * 100).toFixed(1)}%`,
    higherIsBetter: false
  }
];
```

**UI Layout:**

```
┌─────────────────────────────────────────────────────────┐
│  Scenario Comparison                    [+ New Scenario] │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  Metric                Baseline   Optimistic   Cautious  │
│  ───────────────────────────────────────────────────────│
│  Final Population      12,450     18,921        8,234    │
│                        (base)     +52% ↑        -34% ↓   │
│                                                           │
│  Peak Population       15,622     22,109       11,458    │
│                        (base)     +42% ↑        -27% ↓   │
│                                                           │
│  Years to Target       18         12            Never    │
│                        (base)     -6 yrs ✓      ✗        │
│                                                           │
│  Extinction Risk       2.3%       0.8%          8.7%     │
│                        (base)     -1.5% ✓       +6.4% ✗  │
│                                                           │
├─────────────────────────────────────────────────────────┤
│  [Export Table]  [Clone Scenario]  [Delete Selected]    │
└─────────────────────────────────────────────────────────┘
```

---

## 3. MODEL COMPUTATION LAYER

### 3.1 Core Model Implementation in TypeScript

Since we're building a client-side app initially, we'll implement the population model in TypeScript for fast, interactive simulations.

```typescript
// src/lib/model/types.ts
export type SizeClass = 'sc1' | 'sc2' | 'sc3' | 'sc4' | 'sc5';

export interface PopulationVector {
  sc1: number;
  sc2: number;
  sc3: number;
  sc4: number;
  sc5: number;
}

export type Matrix5x5 = number[][];

export interface DemographicMatrices {
  survival: Matrix5x5;        // S - diagonal matrix
  transition: Matrix5x5;      // T - growth/shrinkage/stasis
  fragmentation: Matrix5x5;   // F - asexual reproduction
}

export interface CompartmentParameters {
  survival: number[];         // [s1, s2, s3, s4, s5]
  growth: number[][];         // 5x5 transition probabilities
  fragmentation: number[][];  // 5x5 fragmentation rates
  fecundity: number[];        // [f1, f2, f3, f4, f5]
}

// src/lib/model/matrices.ts
export function createSurvivalMatrix(survivalRates: number[]): Matrix5x5 {
  return [
    [survivalRates[0], 0, 0, 0, 0],
    [0, survivalRates[1], 0, 0, 0],
    [0, 0, survivalRates[2], 0, 0],
    [0, 0, 0, survivalRates[3], 0],
    [0, 0, 0, 0, survivalRates[4]]
  ];
}

export function multiplyMatrices(A: Matrix5x5, B: Matrix5x5): Matrix5x5 {
  const result: Matrix5x5 = Array(5).fill(0).map(() => Array(5).fill(0));
  for (let i = 0; i < 5; i++) {
    for (let j = 0; j < 5; j++) {
      for (let k = 0; k < 5; k++) {
        result[i][j] += A[i][k] * B[k][j];
      }
    }
  }
  return result;
}

export function multiplyMatrixVector(M: Matrix5x5, v: PopulationVector): PopulationVector {
  const vec = [v.sc1, v.sc2, v.sc3, v.sc4, v.sc5];
  const result = Array(5).fill(0);

  for (let i = 0; i < 5; i++) {
    for (let j = 0; j < 5; j++) {
      result[i] += M[i][j] * vec[j];
    }
  }

  return {
    sc1: result[0],
    sc2: result[1],
    sc3: result[2],
    sc4: result[3],
    sc5: result[4]
  };
}

// src/lib/model/simulation.ts
export interface SimulationConfig {
  years: number;
  initialPopulation: PopulationVector;
  compartmentParams: {
    reef: CompartmentParameters;
    orchard: CompartmentParameters;
    lab: CompartmentParameters;
  };
  managementParams: {
    reefArea: number;           // cm²
    orchardCapacity: number;    // number of colonies
    reefYield: number;          // proportion
    orchardYield: number;       // proportion
    reefProp: number;           // proportion outplanted to reef
  };
}

export interface SimulationState {
  year: number;
  reef: PopulationVector;
  orchard: PopulationVector;
  lab: number;                  // larval count
  totalPopulation: number;
  coralCover: number;           // cm²
  larvaeProduced: number;
}

export function runSimulation(config: SimulationConfig): SimulationState[] {
  const history: SimulationState[] = [];

  let reefPop = config.initialPopulation;
  let orchardPop: PopulationVector = { sc1: 0, sc2: 0, sc3: 0, sc4: 0, sc5: 0 };

  for (let year = 0; year < config.years; year++) {
    // 1. Apply survival
    const reefSurvival = createSurvivalMatrix(config.compartmentParams.reef.survival);
    reefPop = multiplyMatrixVector(reefSurvival, reefPop);

    // 2. Apply growth + fragmentation
    const T = config.compartmentParams.reef.growth;
    const F = config.compartmentParams.reef.fragmentation;
    const TplusF = addMatrices(T, F);
    reefPop = multiplyMatrixVector(TplusF, reefPop);

    // 3. Calculate larval production
    const larvaeProduced = calculateLarvae(reefPop, config.compartmentParams.reef.fecundity);

    // 4. Apply carrying capacity constraints
    const currentArea = calculateArea(reefPop);
    if (currentArea > config.managementParams.reefArea) {
      reefPop = applyCarryingCapacity(reefPop, config.managementParams.reefArea);
    }

    // 5. Record state
    history.push({
      year,
      reef: reefPop,
      orchard: orchardPop,
      lab: larvaeProduced * config.managementParams.reefYield,
      totalPopulation: sumPopulation(reefPop) + sumPopulation(orchardPop),
      coralCover: currentArea,
      larvaeProduced
    });
  }

  return history;
}

function calculateLarvae(pop: PopulationVector, fecundity: number[]): number {
  return (
    pop.sc1 * fecundity[0] +
    pop.sc2 * fecundity[1] +
    pop.sc3 * fecundity[2] +
    pop.sc4 * fecundity[3] +
    pop.sc5 * fecundity[4]
  );
}

function sumPopulation(pop: PopulationVector): number {
  return pop.sc1 + pop.sc2 + pop.sc3 + pop.sc4 + pop.sc5;
}
```

---

## 4. DESIGN SYSTEM

### 4.1 Color Palette

```typescript
// tailwind.config.js
module.exports = {
  theme: {
    extend: {
      colors: {
        // Brand colors
        primary: {
          50: '#f0f4ff',
          100: '#e0e9ff',
          500: '#667eea',    // Main brand
          600: '#5568d3',
          700: '#4553b8'
        },
        secondary: {
          500: '#764ba2',    // Accent
          600: '#613c87'
        },

        // Compartment colors
        external: {
          light: '#6ee7b7',
          DEFAULT: '#10b981',  // Green
          dark: '#059669'
        },
        lab: {
          light: '#93c5fd',
          DEFAULT: '#3b82f6',  // Blue
          dark: '#2563eb'
        },
        orchard: {
          light: '#5eead4',
          DEFAULT: '#06b6d4',  // Teal
          dark: '#0891b2'
        },
        reef: {
          light: '#fca5a5',
          DEFAULT: '#f43f5e',  // Coral red
          dark: '#dc2626'
        },

        // Size class colors (gradient)
        sizeclass: {
          sc1: '#10b981',
          sc2: '#3b82f6',
          sc3: '#8b5cf6',
          sc4: '#f59e0b',
          sc5: '#ef4444'
        }
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
        mono: ['JetBrains Mono', 'monospace']
      }
    }
  }
}
```

### 4.2 Component Design Tokens

```typescript
// src/lib/design-tokens.ts
export const SPACING = {
  xs: '0.25rem',    // 4px
  sm: '0.5rem',     // 8px
  md: '1rem',       // 16px
  lg: '1.5rem',     // 24px
  xl: '2rem',       // 32px
  '2xl': '3rem'     // 48px
};

export const TYPOGRAPHY = {
  h1: { fontSize: '2.5rem', fontWeight: 700, lineHeight: 1.2 },
  h2: { fontSize: '2rem', fontWeight: 600, lineHeight: 1.3 },
  h3: { fontSize: '1.5rem', fontWeight: 600, lineHeight: 1.4 },
  body: { fontSize: '1rem', fontWeight: 400, lineHeight: 1.6 },
  small: { fontSize: '0.875rem', fontWeight: 400, lineHeight: 1.5 },
  caption: { fontSize: '0.75rem', fontWeight: 400, lineHeight: 1.4 }
};

export const SHADOWS = {
  sm: '0 1px 2px 0 rgb(0 0 0 / 0.05)',
  md: '0 4px 6px -1px rgb(0 0 0 / 0.1)',
  lg: '0 10px 15px -3px rgb(0 0 0 / 0.1)',
  xl: '0 20px 25px -5px rgb(0 0 0 / 0.1)'
};

export const TRANSITIONS = {
  fast: '150ms ease-in-out',
  normal: '250ms ease-in-out',
  slow: '350ms ease-in-out'
};
```

---

## 5. ACCESSIBILITY STRATEGY

### 5.1 WCAG 2.1 AA Compliance

**Requirements:**
- ✅ Color contrast ratio ≥ 4.5:1 for normal text
- ✅ Color contrast ratio ≥ 3:1 for large text and UI components
- ✅ All interactive elements keyboard accessible
- ✅ Focus indicators visible and high contrast
- ✅ No content flashing more than 3 times per second
- ✅ Proper heading hierarchy (h1 → h2 → h3)
- ✅ Alternative text for all images and icons
- ✅ Form labels associated with inputs
- ✅ ARIA labels for complex widgets

### 5.2 Keyboard Navigation

```typescript
// Example: Accessible tab component
const Tabs: React.FC<TabsProps> = ({ tabs, activeTab, onChange }) => {
  const handleKeyDown = (e: React.KeyboardEvent, index: number) => {
    if (e.key === 'ArrowRight') {
      const next = (index + 1) % tabs.length;
      onChange(tabs[next].id);
      // Focus next tab
    } else if (e.key === 'ArrowLeft') {
      const prev = (index - 1 + tabs.length) % tabs.length;
      onChange(tabs[prev].id);
    } else if (e.key === 'Home') {
      onChange(tabs[0].id);
    } else if (e.key === 'End') {
      onChange(tabs[tabs.length - 1].id);
    }
  };

  return (
    <div role="tablist" aria-label="Model sections">
      {tabs.map((tab, index) => (
        <button
          key={tab.id}
          role="tab"
          aria-selected={activeTab === tab.id}
          aria-controls={`panel-${tab.id}`}
          tabIndex={activeTab === tab.id ? 0 : -1}
          onClick={() => onChange(tab.id)}
          onKeyDown={(e) => handleKeyDown(e, index)}
          className="tab-button"
        >
          {tab.label}
        </button>
      ))}
    </div>
  );
};
```

### 5.3 Screen Reader Support

**Best Practices:**
- Use semantic HTML (`<nav>`, `<main>`, `<section>`, `<article>`)
- Announce dynamic content changes with ARIA live regions
- Provide skip links for keyboard users
- Label all form controls and interactive elements
- Use `aria-describedby` for parameter descriptions

```html
<!-- Example: Accessible slider -->
<div className="parameter-input">
  <label htmlFor="survival-sc1" className="parameter-label">
    SC1 Survival Rate
    <span id="survival-sc1-desc" className="parameter-description">
      Annual survival probability for size class 1 (0-10 cm²)
    </span>
  </label>
  <input
    type="range"
    id="survival-sc1"
    min="0"
    max="1"
    step="0.05"
    value={value}
    onChange={handleChange}
    aria-describedby="survival-sc1-desc"
    aria-valuetext={`${(value * 100).toFixed(0)}%`}
  />
  <output htmlFor="survival-sc1" className="parameter-value">
    {(value * 100).toFixed(0)}%
  </output>
</div>
```

---

## 6. PERFORMANCE OPTIMIZATION

### 6.1 Performance Budgets

| Metric | Target | Budget |
|--------|--------|--------|
| **First Contentful Paint** | < 1.5s | 2.0s |
| **Time to Interactive** | < 3.5s | 4.0s |
| **Largest Contentful Paint** | < 2.5s | 3.0s |
| **Cumulative Layout Shift** | < 0.1 | 0.15 |
| **Total Bundle Size** | < 200KB | 250KB (gzipped) |

### 6.2 Code Splitting Strategy

```typescript
// Lazy load heavy visualization components
const SystemFlowDiagram = lazy(() => import('./components/visualizations/SystemFlowDiagram'));
const PopulationTrajectory = lazy(() => import('./components/visualizations/PopulationTrajectory'));
const ScenarioComparison = lazy(() => import('./features/ScenarioComparison'));

// Route-based code splitting
const routes = [
  { path: '/', component: lazy(() => import('./pages/Home')) },
  { path: '/explorer', component: lazy(() => import('./pages/ModelExplorer')) },
  { path: '/scenarios', component: lazy(() => import('./pages/ScenarioBuilder')) },
  { path: '/docs', component: lazy(() => import('./pages/Documentation')) }
];
```

### 6.3 Rendering Optimizations

```typescript
// Memoize expensive calculations
const demographicMatrices = useMemo(() => {
  return {
    survival: createSurvivalMatrix(parameters.survival),
    transition: createTransitionMatrix(parameters.growth),
    fragmentation: createFragmentationMatrix(parameters.fragmentation)
  };
}, [parameters]);

// Debounce parameter changes
const debouncedRunSimulation = useMemo(
  () => debounce((params) => {
    const results = runSimulation(params);
    setSimulationResults(results);
  }, 500),
  []
);

// Virtualize long lists
import { FixedSizeList } from 'react-window';

const ParameterList = ({ parameters }) => (
  <FixedSizeList
    height={600}
    itemCount={parameters.length}
    itemSize={80}
    width="100%"
  >
    {({ index, style }) => (
      <div style={style}>
        <ParameterInput parameter={parameters[index]} />
      </div>
    )}
  </FixedSizeList>
);
```

---

## 7. TESTING STRATEGY

### 7.1 Unit Tests (Vitest)

```typescript
// tests/unit/model/matrices.test.ts
import { describe, it, expect } from 'vitest';
import { createSurvivalMatrix, multiplyMatrices } from '@/lib/model/matrices';

describe('Matrix Operations', () => {
  it('should create diagonal survival matrix', () => {
    const survival = [0.4, 0.6, 0.7, 0.8, 0.9];
    const matrix = createSurvivalMatrix(survival);

    expect(matrix[0][0]).toBe(0.4);
    expect(matrix[1][1]).toBe(0.6);
    expect(matrix[0][1]).toBe(0);  // Off-diagonal should be 0
  });

  it('should multiply matrices correctly', () => {
    const A = [[1, 0], [0, 1]];
    const B = [[2, 3], [4, 5]];
    const result = multiplyMatrices(A, B);

    expect(result).toEqual([[2, 3], [4, 5]]);
  });
});
```

### 7.2 Integration Tests

```typescript
// tests/integration/simulation.test.ts
import { describe, it, expect } from 'vitest';
import { runSimulation } from '@/lib/model/simulation';
import { DEFAULT_PARAMETERS } from '@/lib/constants';

describe('Simulation Integration', () => {
  it('should run 50-year simulation without errors', () => {
    const config = {
      years: 50,
      initialPopulation: { sc1: 100, sc2: 50, sc3: 20, sc4: 5, sc5: 1 },
      compartmentParams: DEFAULT_PARAMETERS,
      managementParams: {
        reefArea: 10000000,
        orchardCapacity: 1000,
        reefYield: 0.5,
        orchardYield: 0.5,
        reefProp: 0.75
      }
    };

    const results = runSimulation(config);

    expect(results).toHaveLength(50);
    expect(results[0].totalPopulation).toBeGreaterThan(0);
    expect(results[49].year).toBe(49);
  });

  it('should enforce carrying capacity', () => {
    const config = {
      years: 10,
      initialPopulation: { sc1: 0, sc2: 0, sc3: 0, sc4: 0, sc5: 10000 },
      compartmentParams: DEFAULT_PARAMETERS,
      managementParams: {
        reefArea: 1000000,  // Small reef
        orchardCapacity: 1000,
        reefYield: 0.5,
        orchardYield: 0.5,
        reefProp: 0.75
      }
    };

    const results = runSimulation(config);
    const finalArea = results[results.length - 1].coralCover;

    expect(finalArea).toBeLessThanOrEqual(config.managementParams.reefArea);
  });
});
```

### 7.3 E2E Tests (Playwright)

```typescript
// tests/e2e/model-explorer.spec.ts
import { test, expect } from '@playwright/test';

test.describe('Model Explorer', () => {
  test('should load and display system flow diagram', async ({ page }) => {
    await page.goto('/explorer');

    // Wait for diagram to render
    await page.waitForSelector('[data-testid="system-flow-diagram"]');

    // Check compartments are visible
    await expect(page.locator('[data-compartment="reef"]')).toBeVisible();
    await expect(page.locator('[data-compartment="orchard"]')).toBeVisible();
    await expect(page.locator('[data-compartment="lab"]')).toBeVisible();
  });

  test('should update visualization when parameters change', async ({ page }) => {
    await page.goto('/explorer');

    // Adjust survival parameter
    await page.fill('[data-parameter="survival-sc1"]', '0.8');
    await page.click('[data-action="run-simulation"]');

    // Check population trajectory updated
    await expect(page.locator('[data-viz="population-trajectory"]')).toContainText('Population');
  });

  test('should be keyboard navigable', async ({ page }) => {
    await page.goto('/explorer');

    // Tab through interface
    await page.keyboard.press('Tab');
    await expect(page.locator(':focus')).toHaveAttribute('role', 'tab');

    // Arrow key navigation
    await page.keyboard.press('ArrowRight');
    await expect(page.locator('[aria-selected="true"]')).toContainText('Parameters');
  });
});
```

### 7.4 Accessibility Tests

```typescript
// tests/a11y/accessibility.test.ts
import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

test.describe('Accessibility', () => {
  test('should not have WCAG violations on home page', async ({ page }) => {
    await page.goto('/');

    const results = await new AxeBuilder({ page })
      .withTags(['wcag2a', 'wcag2aa'])
      .analyze();

    expect(results.violations).toEqual([]);
  });

  test('should have proper ARIA labels', async ({ page }) => {
    await page.goto('/explorer');

    // Check slider has label
    const slider = page.locator('input[type="range"]').first();
    const labelId = await slider.getAttribute('aria-labelledby');
    expect(labelId).toBeTruthy();

    // Check label exists
    const label = page.locator(`#${labelId}`);
    await expect(label).toBeVisible();
  });
});
```

---

## 8. DEPLOYMENT & CI/CD

### 8.1 Build Configuration

```typescript
// vite.config.ts
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'path';

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src')
    }
  },
  build: {
    target: 'es2020',
    outDir: 'dist',
    sourcemap: true,
    rollupOptions: {
      output: {
        manualChunks: {
          'react-vendor': ['react', 'react-dom'],
          'd3-vendor': ['d3'],
          'charts-vendor': ['recharts']
        }
      }
    }
  },
  server: {
    port: 3000,
    open: true
  }
});
```

### 8.2 GitHub Actions Workflow

```yaml
# .github/workflows/ci.yml
name: CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Run linter
        run: npm run lint

      - name: Run unit tests
        run: npm run test:unit

      - name: Run integration tests
        run: npm run test:integration

      - name: Run E2E tests
        run: npm run test:e2e

      - name: Run accessibility tests
        run: npm run test:a11y

      - name: Build application
        run: npm run build

      - name: Upload build artifacts
        uses: actions/upload-artifact@v3
        with:
          name: dist
          path: dist/

  deploy:
    needs: test
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Download build artifacts
        uses: actions/download-artifact@v3
        with:
          name: dist
          path: dist/

      - name: Deploy to Netlify
        uses: netlify/actions/cli@master
        with:
          args: deploy --prod --dir=dist
        env:
          NETLIFY_SITE_ID: ${{ secrets.NETLIFY_SITE_ID }}
          NETLIFY_AUTH_TOKEN: ${{ secrets.NETLIFY_AUTH_TOKEN }}
```

---

## 9. DOCUMENTATION REQUIREMENTS

### 9.1 User Documentation

**In-App Help:**
- Tooltips on every parameter with ecological interpretation
- Interactive tutorial (first-time user flow)
- Contextual help panels in each section
- FAQ page covering common questions

**External Documentation:**
- User guide (markdown + screenshots)
- Video tutorials (5-10 minutes each)
- Example scenarios with explanations
- Troubleshooting guide

### 9.2 Developer Documentation

**Code Documentation:**
- JSDoc comments on all public functions
- Type definitions exported and documented
- Storybook for component library
- Architecture decision records (ADRs)

**API Documentation:**
- If backend API needed, OpenAPI/Swagger spec
- Authentication flow documentation
- Rate limits and error handling
- Example requests/responses

---

## 10. FUTURE ENHANCEMENTS (Post-MVP)

### Phase 2 Features
1. **Real-time collaboration** - Multiple users editing scenarios
2. **User accounts** - Save scenarios, share with team
3. **Advanced analytics** - Sensitivity analysis, Monte Carlo simulations
4. **Mobile app** - React Native version for field work
5. **R integration** - Call actual R model via Plumber API for validation

### Phase 3 Features
1. **Machine learning** - Parameter optimization using genetic algorithms
2. **GIS integration** - Map-based reef selection
3. **Cost modeling** - Budget constraints and optimization
4. **Report generation** - Automated PDF reports with charts
5. **Data import/export** - CSV, Excel, JSON formats

---

## Success Metrics

### Technical Metrics
- ✅ Lighthouse score 90+ (all categories)
- ✅ Zero critical accessibility violations
- ✅ Test coverage > 80%
- ✅ Build time < 30 seconds
- ✅ Bundle size < 250KB gzipped

### User Metrics
- ✅ User can understand model structure in < 5 minutes
- ✅ User can run first simulation in < 2 minutes
- ✅ 90% of users complete tutorial without help
- ✅ Average session duration > 15 minutes
- ✅ Return user rate > 40%

---

**Next Steps:**
1. Review and approve this architecture
2. Set up project repository and CI/CD
3. Implement core model logic in TypeScript
4. Build design system components
5. Develop interactive visualizations
6. Comprehensive testing and optimization
7. Deploy to production

**Timeline Estimate:** 6-8 weeks for MVP (Phase 1)

**Questions for Product Owner:**
1. Do we need user authentication for MVP?
2. Should we integrate with R backend or keep client-side only?
3. What are the top 3 must-have features for launch?
4. Who are the first beta testers?
5. What's the deadline for initial release?

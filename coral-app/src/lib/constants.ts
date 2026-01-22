import type { CompartmentInfo, SizeClassInfo, CompartmentParameters, ManagementParameters } from '../types/model';

/**
 * Compartment definitions with metadata
 */
export const COMPARTMENTS: Record<string, CompartmentInfo> = {
  external: {
    id: 'external',
    label: 'External Reefs',
    color: '#10b981',
    description: 'Wild reference reefs providing larvae for collection',
    icon: '🌍'
  },
  lab: {
    id: 'lab',
    label: 'Lab Facility',
    color: '#3b82f6',
    description: 'Settlement facility for larvae rearing on artificial substrates',
    icon: '🔬'
  },
  orchard: {
    id: 'orchard',
    label: 'Orchard Nursery',
    color: '#06b6d4',
    description: 'Protected nursery for growing corals to transplantable sizes',
    icon: '🌿'
  },
  reef: {
    id: 'reef',
    label: 'Restoration Reef',
    color: '#f43f5e',
    description: 'Target restoration site for coral outplanting',
    icon: '🪸'
  }
} as const;

/**
 * Size class definitions with metadata
 */
export const SIZE_CLASSES: Record<string, SizeClassInfo> = {
  sc1: {
    id: 'sc1',
    label: 'SC1',
    range: '0-10 cm²',
    rangeNumeric: [0, 10],
    midpoint: 0.1,
    color: '#10b981',
    description: 'Recruits and settlers - highest mortality, no reproduction'
  },
  sc2: {
    id: 'sc2',
    label: 'SC2',
    range: '10-100 cm²',
    rangeNumeric: [10, 100],
    midpoint: 43,
    color: '#3b82f6',
    description: 'Small juveniles - moderate growth, minimal reproduction'
  },
  sc3: {
    id: 'sc3',
    label: 'SC3',
    range: '100-900 cm²',
    rangeNumeric: [100, 900],
    midpoint: 369,
    color: '#8b5cf6',
    description: 'Large juveniles - faster growth, begins reproduction'
  },
  sc4: {
    id: 'sc4',
    label: 'SC4',
    range: '900-4000 cm²',
    rangeNumeric: [900, 4000],
    midpoint: 2158,
    color: '#f59e0b',
    description: 'Subadults - fragmentation begins, high fecundity'
  },
  sc5: {
    id: 'sc5',
    label: 'SC5',
    range: '>4000 cm²',
    rangeNumeric: [4000, Infinity],
    midpoint: 11171,
    color: '#ef4444',
    description: 'Reproductive adults - maximum fecundity and fragmentation'
  }
} as const;

/**
 * Default reef compartment parameters (field-calibrated)
 */
export const DEFAULT_REEF_PARAMS: CompartmentParameters = {
  survival: [0.4, 0.6, 0.7, 0.8, 0.85],
  growth: [
    [0.80, 0.02, 0.01, 0.00, 0.00],  // SC1
    [0.15, 0.75, 0.03, 0.00, 0.00],  // SC2
    [0.05, 0.18, 0.78, 0.05, 0.00],  // SC3
    [0.00, 0.05, 0.15, 0.82, 0.10],  // SC4
    [0.00, 0.00, 0.03, 0.13, 0.90]   // SC5
  ],
  shrinkage: [
    [0.00, 0.02, 0.01, 0.00, 0.00],
    [0.00, 0.00, 0.03, 0.00, 0.00],
    [0.00, 0.00, 0.00, 0.05, 0.00],
    [0.00, 0.00, 0.00, 0.00, 0.10],
    [0.00, 0.00, 0.00, 0.00, 0.00]
  ],
  fragmentation: [
    [0, 0, 0, 0.5, 1.0],   // SC4 and SC5 fragment
    [0, 0, 0, 0.3, 0.6],
    [0, 0, 0, 0.2, 0.4],
    [0, 0, 0, 0.1, 0.2],
    [0, 0, 0, 0.0, 0.1]
  ],
  fecundity: [0, 0, 5000, 50000, 100000]  // larvae per individual per year
};

/**
 * Default orchard compartment parameters (nursery conditions)
 */
export const DEFAULT_ORCHARD_PARAMS: CompartmentParameters = {
  survival: [0.7, 0.8, 0.85, 0.9, 0.95],  // Higher survival in protected nursery
  growth: [
    [0.70, 0.01, 0.00, 0.00, 0.00],
    [0.25, 0.70, 0.02, 0.00, 0.00],
    [0.05, 0.25, 0.75, 0.03, 0.00],
    [0.00, 0.04, 0.20, 0.80, 0.08],
    [0.00, 0.00, 0.03, 0.17, 0.92]
  ],
  shrinkage: [
    [0.00, 0.01, 0.00, 0.00, 0.00],
    [0.00, 0.00, 0.02, 0.00, 0.00],
    [0.00, 0.00, 0.00, 0.03, 0.00],
    [0.00, 0.00, 0.00, 0.00, 0.08],
    [0.00, 0.00, 0.00, 0.00, 0.00]
  ],
  fragmentation: [  // No fragmentation in nursery
    [0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0]
  ],
  fecundity: [0, 0, 6000, 60000, 120000]  // Slightly higher with optimal conditions
};

/**
 * Default management parameters
 */
export const DEFAULT_MANAGEMENT_PARAMS: ManagementParameters = {
  reefArea: 10000000,        // 10 million cm² (1000 m²)
  orchardCapacity: 1000,     // 1000 colonies
  reefYield: 0.5,            // 50% collection efficiency
  orchardYield: 0.5,         // 50% collection efficiency
  reefProp: 0.75             // 75% outplanted to reef, 25% to orchard
};

/**
 * Parameter presets for quick scenario creation
 */
export const PARAMETER_PRESETS = {
  baseline: {
    name: 'Baseline (Field-Calibrated)',
    description: 'Default parameters based on field observations',
    reef: DEFAULT_REEF_PARAMS,
    orchard: DEFAULT_ORCHARD_PARAMS,
    management: DEFAULT_MANAGEMENT_PARAMS
  },
  optimistic: {
    name: 'Optimistic Scenario',
    description: 'Higher survival and growth rates',
    reef: {
      ...DEFAULT_REEF_PARAMS,
      survival: [0.5, 0.7, 0.8, 0.85, 0.9]
    },
    orchard: {
      ...DEFAULT_ORCHARD_PARAMS,
      survival: [0.8, 0.85, 0.9, 0.93, 0.97]
    },
    management: {
      ...DEFAULT_MANAGEMENT_PARAMS,
      reefYield: 0.7,
      orchardYield: 0.7
    }
  },
  conservative: {
    name: 'Conservative Scenario',
    description: 'Lower survival rates, accounting for worst-case conditions',
    reef: {
      ...DEFAULT_REEF_PARAMS,
      survival: [0.3, 0.5, 0.6, 0.7, 0.75]
    },
    orchard: {
      ...DEFAULT_ORCHARD_PARAMS,
      survival: [0.6, 0.7, 0.75, 0.8, 0.85]
    },
    management: {
      ...DEFAULT_MANAGEMENT_PARAMS,
      reefYield: 0.3,
      orchardYield: 0.3
    }
  }
} as const;

/**
 * Area calculations - midpoint areas for each size class
 */
export const SIZE_CLASS_AREAS = [0.1, 43, 369, 2158, 11171];

/**
 * Animation and UI constants
 */
export const UI_CONSTANTS = {
  DEBOUNCE_MS: 500,
  ANIMATION_DURATION_MS: 300,
  TOOLTIP_DELAY_MS: 200,
  MAX_SIMULATION_YEARS: 100,
  DEFAULT_SIMULATION_YEARS: 50
} as const;

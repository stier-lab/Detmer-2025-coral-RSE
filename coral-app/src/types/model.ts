/**
 * Core type definitions for the coral restoration model
 */

export type SizeClass = 'sc1' | 'sc2' | 'sc3' | 'sc4' | 'sc5';

export type Compartment = 'external' | 'lab' | 'orchard' | 'reef';

export interface PopulationVector {
  sc1: number;
  sc2: number;
  sc3: number;
  sc4: number;
  sc5: number;
}

export type Matrix5x5 = [
  [number, number, number, number, number],
  [number, number, number, number, number],
  [number, number, number, number, number],
  [number, number, number, number, number],
  [number, number, number, number, number]
];

export interface DemographicMatrices {
  survival: Matrix5x5;
  transition: Matrix5x5;
  fragmentation: Matrix5x5;
}

export interface CompartmentParameters {
  survival: number[];         // [s1, s2, s3, s4, s5]
  growth: number[][];         // 5x5 transition probabilities
  shrinkage: number[][];      // 5x5 shrinkage probabilities
  fragmentation: number[][];  // 5x5 fragmentation rates
  fecundity: number[];        // [f1, f2, f3, f4, f5] larvae per individual
}

export interface ManagementParameters {
  reefArea: number;          // cm² - carrying capacity
  orchardCapacity: number;   // number of colonies
  reefYield: number;         // proportion [0-1]
  orchardYield: number;      // proportion [0-1]
  reefProp: number;          // proportion outplanted to reef [0-1]
}

export interface SimulationConfig {
  years: number;
  initialPopulation: {
    reef: PopulationVector;
    orchard: PopulationVector;
  };
  compartmentParams: {
    reef: CompartmentParameters;
    orchard: CompartmentParameters;
  };
  managementParams: ManagementParameters;
  stochastic?: boolean;
  stochasticitySD?: number;
}

export interface SimulationState {
  year: number;
  reef: PopulationVector;
  orchard: PopulationVector;
  lab: number;                // larval count
  totalPopulation: number;
  coralCover: number;         // cm²
  larvaeProduced: number;
}

export interface Scenario {
  id: string;
  name: string;
  description: string;
  config: SimulationConfig;
  results?: SimulationState[];
  createdAt: Date;
  updatedAt: Date;
}

export interface CompartmentInfo {
  id: Compartment;
  label: string;
  color: string;
  description: string;
  icon: string;
}

export interface SizeClassInfo {
  id: SizeClass;
  label: string;
  range: string;
  rangeNumeric: [number, number];
  midpoint: number;
  color: string;
  description: string;
}

export interface Flow {
  id: string;
  source: Compartment;
  target: Compartment;
  label: string;
  type: 'material' | 'feedback' | 'optional';
  getValue?: (state: SimulationState) => number;
}

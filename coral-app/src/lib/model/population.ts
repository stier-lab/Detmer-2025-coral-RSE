import type { PopulationVector } from '../../types/model';
import { SIZE_CLASS_AREAS } from '../constants';

/**
 * Population vector operations
 */

/**
 * Create an empty population vector
 */
export function createEmptyPopulation(): PopulationVector {
  return { sc1: 0, sc2: 0, sc3: 0, sc4: 0, sc5: 0 };
}

/**
 * Sum all individuals across size classes
 */
export function sumPopulation(pop: PopulationVector): number {
  return pop.sc1 + pop.sc2 + pop.sc3 + pop.sc4 + pop.sc5;
}

/**
 * Calculate total coral cover (planar area) in cm²
 */
export function calculateCoralCover(pop: PopulationVector): number {
  return (
    pop.sc1 * SIZE_CLASS_AREAS[0] +
    pop.sc2 * SIZE_CLASS_AREAS[1] +
    pop.sc3 * SIZE_CLASS_AREAS[2] +
    pop.sc4 * SIZE_CLASS_AREAS[3] +
    pop.sc5 * SIZE_CLASS_AREAS[4]
  );
}

/**
 * Calculate larval production given population and fecundity rates
 */
export function calculateLarvalProduction(
  pop: PopulationVector,
  fecundity: number[]
): number {
  return (
    pop.sc1 * fecundity[0] +
    pop.sc2 * fecundity[1] +
    pop.sc3 * fecundity[2] +
    pop.sc4 * fecundity[3] +
    pop.sc5 * fecundity[4]
  );
}

/**
 * Apply carrying capacity constraint by reducing population proportionally
 */
export function applyCarryingCapacity(
  pop: PopulationVector,
  maxArea: number
): PopulationVector {
  const currentArea = calculateCoralCover(pop);

  if (currentArea <= maxArea) {
    return pop;  // No constraint needed
  }

  // Reduce population proportionally to fit capacity
  const scaleFactor = maxArea / currentArea;

  return {
    sc1: pop.sc1 * scaleFactor,
    sc2: pop.sc2 * scaleFactor,
    sc3: pop.sc3 * scaleFactor,
    sc4: pop.sc4 * scaleFactor,
    sc5: pop.sc5 * scaleFactor
  };
}

/**
 * Add two population vectors element-wise
 */
export function addPopulations(
  a: PopulationVector,
  b: PopulationVector
): PopulationVector {
  return {
    sc1: a.sc1 + b.sc1,
    sc2: a.sc2 + b.sc2,
    sc3: a.sc3 + b.sc3,
    sc4: a.sc4 + b.sc4,
    sc5: a.sc5 + b.sc5
  };
}

/**
 * Multiply population vector by a scalar
 */
export function scalePopulation(
  pop: PopulationVector,
  scalar: number
): PopulationVector {
  return {
    sc1: pop.sc1 * scalar,
    sc2: pop.sc2 * scalar,
    sc3: pop.sc3 * scalar,
    sc4: pop.sc4 * scalar,
    sc5: pop.sc5 * scalar
  };
}

/**
 * Get population size for a specific size class
 */
export function getSizeClass(
  pop: PopulationVector,
  sizeClass: 'sc1' | 'sc2' | 'sc3' | 'sc4' | 'sc5'
): number {
  return pop[sizeClass];
}

/**
 * Set population size for a specific size class
 */
export function setSizeClass(
  pop: PopulationVector,
  sizeClass: 'sc1' | 'sc2' | 'sc3' | 'sc4' | 'sc5',
  value: number
): PopulationVector {
  return {
    ...pop,
    [sizeClass]: Math.max(0, value)  // Ensure non-negative
  };
}

/**
 * Convert population vector to array for easier iteration
 */
export function populationToArray(pop: PopulationVector): number[] {
  return [pop.sc1, pop.sc2, pop.sc3, pop.sc4, pop.sc5];
}

/**
 * Convert array to population vector
 */
export function arrayToPopulation(arr: number[]): PopulationVector {
  if (arr.length !== 5) {
    throw new Error('Array must have exactly 5 elements');
  }

  return {
    sc1: arr[0],
    sc2: arr[1],
    sc3: arr[2],
    sc4: arr[3],
    sc5: arr[4]
  };
}

/**
 * Calculate size class distribution as percentages
 */
export function getSizeDistribution(pop: PopulationVector): {
  sc1: number;
  sc2: number;
  sc3: number;
  sc4: number;
  sc5: number;
} {
  const total = sumPopulation(pop);

  if (total === 0) {
    return { sc1: 0, sc2: 0, sc3: 0, sc4: 0, sc5: 0 };
  }

  return {
    sc1: (pop.sc1 / total) * 100,
    sc2: (pop.sc2 / total) * 100,
    sc3: (pop.sc3 / total) * 100,
    sc4: (pop.sc4 / total) * 100,
    sc5: (pop.sc5 / total) * 100
  };
}

/**
 * Check if population is extinct (all size classes have < 1 individual)
 */
export function isExtinct(pop: PopulationVector): boolean {
  return sumPopulation(pop) < 1;
}

/**
 * Calculate mean size class (weighted average)
 */
export function meanSizeClass(pop: PopulationVector): number {
  const total = sumPopulation(pop);

  if (total === 0) return 0;

  return (
    (pop.sc1 * 1 + pop.sc2 * 2 + pop.sc3 * 3 + pop.sc4 * 4 + pop.sc5 * 5) / total
  );
}

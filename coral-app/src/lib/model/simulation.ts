import type {
  SimulationConfig,
  SimulationState,
  Matrix5x5
} from '../../types/model';

import {
  createSurvivalMatrix,
  multiplyMatrixVector,
  createTransitionMatrix,
  addMatrices
} from './matrices';

import {
  sumPopulation,
  calculateCoralCover,
  calculateLarvalProduction,
  applyCarryingCapacity,
  scalePopulation
} from './population';

/**
 * Core simulation engine for coral restoration model
 */

/**
 * Run a complete simulation for the specified number of years
 */
export function runSimulation(config: SimulationConfig): SimulationState[] {
  const history: SimulationState[] = [];

  // Initialize populations
  let reefPop = { ...config.initialPopulation.reef };
  let orchardPop = { ...config.initialPopulation.orchard };
  let labLarvae = 0;

  // Pre-compute demographic matrices
  const reefMatrices = computeDemographicMatrices(config.compartmentParams.reef);
  const orchardMatrices = computeDemographicMatrices(config.compartmentParams.orchard);

  // Run annual time steps
  for (let year = 0; year < config.years; year++) {
    // ===== REEF COMPARTMENT =====

    // 1. Apply survival
    reefPop = multiplyMatrixVector(reefMatrices.survival, reefPop);

    // 2. Apply growth + fragmentation
    reefPop = multiplyMatrixVector(reefMatrices.projection, reefPop);

    // 3. Calculate larval production
    const reefLarvae = calculateLarvalProduction(
      reefPop,
      config.compartmentParams.reef.fecundity
    );

    // 4. Apply carrying capacity
    const reefArea = calculateCoralCover(reefPop);
    if (reefArea > config.managementParams.reefArea) {
      reefPop = applyCarryingCapacity(reefPop, config.managementParams.reefArea);
    }

    // ===== ORCHARD COMPARTMENT =====

    // 1. Apply survival
    orchardPop = multiplyMatrixVector(orchardMatrices.survival, orchardPop);

    // 2. Apply growth (no fragmentation in nursery)
    orchardPop = multiplyMatrixVector(orchardMatrices.transition, orchardPop);

    // 3. Calculate larval production
    const orchardLarvae = calculateLarvalProduction(
      orchardPop,
      config.compartmentParams.orchard.fecundity
    );

    // 4. Collect larvae for lab
    const larvaeCollected =
      reefLarvae * config.managementParams.reefYield +
      orchardLarvae * config.managementParams.orchardYield;

    labLarvae = larvaeCollected;

    // ===== LAB COMPARTMENT =====
    // Simplified: assume larvae settle and are outplanted to SC1
    // In reality, this would involve settlement success rates and timing

    if (labLarvae > 0) {
      const settlers = labLarvae * 0.5;  // Simplified settlement success

      // Distribute settlers between reef and orchard
      const toReef = settlers * config.managementParams.reefProp;
      const toOrchard = settlers * (1 - config.managementParams.reefProp);

      reefPop.sc1 += toReef;
      orchardPop.sc1 += toOrchard;
    }

    // Apply orchard capacity constraint
    const orchardTotal = sumPopulation(orchardPop);
    if (orchardTotal > config.managementParams.orchardCapacity) {
      const scaleFactor = config.managementParams.orchardCapacity / orchardTotal;
      orchardPop = scalePopulation(orchardPop, scaleFactor);
    }

    // ===== RECORD STATE =====
    const totalPop = sumPopulation(reefPop) + sumPopulation(orchardPop);
    const coralCover = calculateCoralCover(reefPop);

    history.push({
      year,
      reef: { ...reefPop },
      orchard: { ...orchardPop },
      lab: labLarvae,
      totalPopulation: totalPop,
      coralCover,
      larvaeProduced: reefLarvae + orchardLarvae
    });
  }

  return history;
}

/**
 * Pre-compute demographic matrices for a compartment
 */
function computeDemographicMatrices(params: {
  survival: number[];
  growth: number[][];
  shrinkage: number[][];
  fragmentation: number[][];
}) {
  const S = createSurvivalMatrix(params.survival);
  const T = createTransitionMatrix(params.growth, params.shrinkage);
  const F = params.fragmentation as Matrix5x5;

  // Create T + F matrix (combined growth and fragmentation)
  const TplusF = addMatrices(T, F);

  // Create full projection matrix: S * (T + F)
  const projection: Matrix5x5 = [
    [0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0]
  ];

  for (let i = 0; i < 5; i++) {
    for (let j = 0; j < 5; j++) {
      for (let k = 0; k < 5; k++) {
        projection[i][j] += S[i][k] * TplusF[k][j];
      }
    }
  }

  return {
    survival: S,
    transition: T,
    fragmentation: F,
    projection  // S * (T + F)
  };
}

/**
 * Run a stochastic simulation with environmental variability
 */
export function runStochasticSimulation(
  config: SimulationConfig,
  numReplica: number = 100
): SimulationState[][] {
  const allRuns: SimulationState[][] = [];

  for (let rep = 0; rep < numReplica; rep++) {
    const stochasticConfig: SimulationConfig = {
      ...config,
      compartmentParams: {
        reef: addStochasticity(config.compartmentParams.reef, config.stochasticitySD || 0.1),
        orchard: addStochasticity(config.compartmentParams.orchard, config.stochasticitySD || 0.1)
      }
    };

    const result = runSimulation(stochasticConfig);
    allRuns.push(result);
  }

  return allRuns;
}

/**
 * Add environmental stochasticity to demographic parameters
 */
function addStochasticity(
  params: {
    survival: number[];
    growth: number[][];
    shrinkage: number[][];
    fragmentation: number[][];
    fecundity: number[];
  },
  sd: number
) {
  // Apply lognormal variation to survival rates
  const newSurvival = params.survival.map(s => {
    const epsilon = (Math.random() - 0.5) * 2 * sd;  // Simplified uniform random in range [-sd, sd] (not normal distribution)
    return Math.max(0, Math.min(1, s * Math.exp(epsilon)));
  });

  return {
    ...params,
    survival: newSurvival
  };
}

/**
 * Calculate summary statistics from simulation results
 */
export interface SimulationSummary {
  finalPopulation: number;
  peakPopulation: number;
  peakYear: number;
  minPopulation: number;
  timeToTarget: number | null;
  finalCoralCover: number;
  meanGrowthRate: number;
  extinctionRisk: number;
}

export function calculateSummaryStats(
  results: SimulationState[],
  targetPopulation: number = 5000
): SimulationSummary {
  if (results.length === 0) {
    return {
      finalPopulation: 0,
      peakPopulation: 0,
      peakYear: 0,
      minPopulation: 0,
      timeToTarget: null,
      finalCoralCover: 0,
      meanGrowthRate: 0,
      extinctionRisk: 1
    };
  }

  const finalState = results[results.length - 1];
  const finalPop = finalState.totalPopulation;

  let peakPop = 0;
  let peakYear = 0;
  let minPop = Infinity;
  let timeToTarget: number | null = null;

  for (let i = 0; i < results.length; i++) {
    const pop = results[i].totalPopulation;

    if (pop > peakPop) {
      peakPop = pop;
      peakYear = i;
    }

    if (pop < minPop) {
      minPop = pop;
    }

    if (timeToTarget === null && pop >= targetPopulation) {
      timeToTarget = i;
    }
  }

  // Calculate mean annual growth rate
  const growthRates: number[] = [];
  for (let i = 1; i < results.length; i++) {
    const prev = results[i - 1].totalPopulation;
    const curr = results[i].totalPopulation;
    if (prev > 0) {
      growthRates.push((curr - prev) / prev);
    }
  }

  const meanGrowthRate =
    growthRates.length > 0
      ? growthRates.reduce((sum, r) => sum + r, 0) / growthRates.length
      : 0;

  // Extinction risk: 1 if population < 1 at end, 0 otherwise
  const extinctionRisk = finalPop < 1 ? 1 : 0;

  return {
    finalPopulation: finalPop,
    peakPopulation: peakPop,
    peakYear,
    minPopulation: minPop,
    timeToTarget,
    finalCoralCover: finalState.coralCover,
    meanGrowthRate,
    extinctionRisk
  };
}

/**
 * Calculate ensemble statistics from multiple stochastic runs
 */
export function calculateEnsembleStats(allRuns: SimulationState[][]) {
  const numYears = allRuns[0].length;
  const numRuns = allRuns.length;

  // For each year, calculate mean and percentiles across runs
  const ensemble: {
    year: number;
    mean: number;
    median: number;
    p5: number;
    p95: number;
  }[] = [];

  for (let year = 0; year < numYears; year++) {
    const populations = allRuns.map(run => run[year].totalPopulation).sort((a, b) => a - b);

    const mean = populations.reduce((sum, p) => sum + p, 0) / numRuns;
    const median = populations[Math.floor(numRuns / 2)];
    const p5 = populations[Math.floor(numRuns * 0.05)];
    const p95 = populations[Math.floor(numRuns * 0.95)];

    ensemble.push({ year, mean, median, p5, p95 });
  }

  return ensemble;
}

import { describe, it, expect } from 'vitest';
import { runSimulation, calculateSummaryStats } from './simulation';
import { DEFAULT_REEF_PARAMS, DEFAULT_ORCHARD_PARAMS, DEFAULT_MANAGEMENT_PARAMS } from '../constants';
import type { SimulationConfig, PopulationVector } from '../../types/model';

describe('Simulation', () => {
  const initialReefPop: PopulationVector = {
    sc1: 100,
    sc2: 50,
    sc3: 25,
    sc4: 10,
    sc5: 5
  };

  const initialOrchardPop: PopulationVector = {
    sc1: 0,
    sc2: 0,
    sc3: 0,
    sc4: 0,
    sc5: 0
  };

  const defaultConfig: SimulationConfig = {
    years: 10,
    initialPopulation: {
      reef: initialReefPop,
      orchard: initialOrchardPop
    },
    compartmentParams: {
      reef: DEFAULT_REEF_PARAMS,
      orchard: DEFAULT_ORCHARD_PARAMS
    },
    managementParams: DEFAULT_MANAGEMENT_PARAMS
  };

  it('runs simulation without errors', () => {
    const result = runSimulation(defaultConfig);

    expect(result).toBeDefined();
    expect(result).toHaveLength(10); // 10 years of results
  });

  it('returns non-negative population values', () => {
    const result = runSimulation({
      ...defaultConfig,
      years: 5
    });

    result.forEach(state => {
      expect(state.reef.sc1).toBeGreaterThanOrEqual(0);
      expect(state.reef.sc2).toBeGreaterThanOrEqual(0);
      expect(state.reef.sc3).toBeGreaterThanOrEqual(0);
      expect(state.reef.sc4).toBeGreaterThanOrEqual(0);
      expect(state.reef.sc5).toBeGreaterThanOrEqual(0);
      expect(state.totalPopulation).toBeGreaterThanOrEqual(0);
    });
  });

  it('calculates summary statistics', () => {
    const result = runSimulation(defaultConfig);
    const summary = calculateSummaryStats(result);

    expect(summary).toBeDefined();
    expect(summary.finalPopulation).toBeDefined();
    expect(typeof summary.finalPopulation).toBe('number');
    expect(summary.peakPopulation).toBeDefined();
    expect(summary.meanGrowthRate).toBeDefined();
  });

  it('tracks coral cover over time', () => {
    const result = runSimulation(defaultConfig);

    result.forEach(state => {
      expect(state.coralCover).toBeDefined();
      expect(typeof state.coralCover).toBe('number');
      expect(state.coralCover).toBeGreaterThanOrEqual(0);
    });
  });
});

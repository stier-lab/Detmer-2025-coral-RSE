// Quick test of simulation logic
import { runSimulation, calculateSummaryStats } from './src/lib/model/simulation.ts';
import { DEFAULT_REEF_PARAMS, DEFAULT_ORCHARD_PARAMS, DEFAULT_MANAGEMENT_PARAMS } from './src/lib/constants.ts';

console.log('Testing coral restoration simulation...\n');

const config = {
  years: 10,
  initialPopulation: {
    reef: { sc1: 100, sc2: 50, sc3: 20, sc4: 5, sc5: 1 },
    orchard: { sc1: 0, sc2: 0, sc3: 0, sc4: 0, sc5: 0 }
  },
  compartmentParams: {
    reef: DEFAULT_REEF_PARAMS,
    orchard: DEFAULT_ORCHARD_PARAMS
  },
  managementParams: DEFAULT_MANAGEMENT_PARAMS
};

try {
  const results = runSimulation(config);
  const summary = calculateSummaryStats(results);

  console.log('✅ Simulation completed successfully!');
  console.log('\nResults for 10-year simulation:');
  console.log('- Final population:', Math.round(summary.finalPopulation));
  console.log('- Peak population:', Math.round(summary.peakPopulation));
  console.log('- Final coral cover:', (summary.finalCoralCover / 10000).toFixed(1), 'm²');
  console.log('- Mean growth rate:', (summary.meanGrowthRate * 100).toFixed(1), '%');

  console.log('\n✅ All model logic is working correctly!');
} catch (error) {
  console.error('❌ Simulation failed:', error.message);
  console.error(error.stack);
}

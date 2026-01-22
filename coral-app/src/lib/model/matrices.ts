import type { Matrix5x5, PopulationVector } from '../../types/model';

/**
 * Matrix operations for population projection models
 */

/**
 * Create a diagonal survival matrix from survival rates
 */
export function createSurvivalMatrix(survivalRates: number[]): Matrix5x5 {
  if (survivalRates.length !== 5) {
    throw new Error('Survival rates must have exactly 5 elements');
  }

  return [
    [survivalRates[0], 0, 0, 0, 0],
    [0, survivalRates[1], 0, 0, 0],
    [0, 0, survivalRates[2], 0, 0],
    [0, 0, 0, survivalRates[3], 0],
    [0, 0, 0, 0, survivalRates[4]]
  ];
}

/**
 * Add two 5x5 matrices
 */
export function addMatrices(A: Matrix5x5, B: Matrix5x5): Matrix5x5 {
  const result: Matrix5x5 = [
    [0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0]
  ];

  for (let i = 0; i < 5; i++) {
    for (let j = 0; j < 5; j++) {
      result[i][j] = A[i][j] + B[i][j];
    }
  }

  return result;
}

/**
 * Multiply two 5x5 matrices
 */
export function multiplyMatrices(A: Matrix5x5, B: Matrix5x5): Matrix5x5 {
  const result: Matrix5x5 = [
    [0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0]
  ];

  for (let i = 0; i < 5; i++) {
    for (let j = 0; j < 5; j++) {
      for (let k = 0; k < 5; k++) {
        result[i][j] += A[i][k] * B[k][j];
      }
    }
  }

  return result;
}

/**
 * Multiply a matrix by a population vector
 */
export function multiplyMatrixVector(M: Matrix5x5, v: PopulationVector): PopulationVector {
  const vec = [v.sc1, v.sc2, v.sc3, v.sc4, v.sc5];
  const result = [0, 0, 0, 0, 0];

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

/**
 * Create a transition matrix from growth and shrinkage probabilities
 * Ensures each column sums to 1
 */
export function createTransitionMatrix(
  growth: number[][],
  shrinkage: number[][]
): Matrix5x5 {
  const T: Matrix5x5 = [
    [0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0]
  ];

  for (let i = 0; i < 5; i++) {
    for (let j = 0; j < 5; j++) {
      if (i > j) {
        // Growth (above diagonal)
        T[i][j] = growth[i][j];
      } else if (i < j) {
        // Shrinkage (below diagonal)
        T[i][j] = shrinkage[i][j];
      }
    }
  }

  // Calculate stasis (diagonal) to ensure column sums = 1
  for (let j = 0; j < 5; j++) {
    let colSum = 0;
    for (let i = 0; i < 5; i++) {
      if (i !== j) {
        colSum += T[i][j];
      }
    }
    T[j][j] = Math.max(0, 1 - colSum);  // Stasis = 1 - growth - shrinkage
  }

  return T;
}

/**
 * Validate that a transition matrix has proper structure
 */
export function validateTransitionMatrix(T: Matrix5x5): boolean {
  // Check column sums
  for (let j = 0; j < 5; j++) {
    let colSum = 0;
    for (let i = 0; i < 5; i++) {
      colSum += T[i][j];
      if (T[i][j] < 0) return false;  // No negative probabilities
    }
    if (Math.abs(colSum - 1) > 0.001) return false;  // Column must sum to 1
  }

  return true;
}

/**
 * Calculate eigenvalues for matrix (used for population growth rate)
 * Simplified implementation for dominant eigenvalue only
 */
export function dominantEigenvalue(M: Matrix5x5, iterations: number = 100): number {
  // Power iteration method
  let v = [1, 1, 1, 1, 1];

  for (let iter = 0; iter < iterations; iter++) {
    const newV = [0, 0, 0, 0, 0];

    // Multiply M * v
    for (let i = 0; i < 5; i++) {
      for (let j = 0; j < 5; j++) {
        newV[i] += M[i][j] * v[j];
      }
    }

    // Normalize
    const norm = Math.sqrt(newV.reduce((sum, val) => sum + val * val, 0));
    v = newV.map(val => val / norm);
  }

  // Calculate eigenvalue (Rayleigh quotient)
  const Mv = [0, 0, 0, 0, 0];
  for (let i = 0; i < 5; i++) {
    for (let j = 0; j < 5; j++) {
      Mv[i] += M[i][j] * v[j];
    }
  }

  let numerator = 0;
  let denominator = 0;
  for (let i = 0; i < 5; i++) {
    numerator += Mv[i] * v[i];
    denominator += v[i] * v[i];
  }

  return numerator / denominator;
}

import { describe, it, expect } from 'vitest';
import {
  createSurvivalMatrix,
  addMatrices,
  multiplyMatrices,
  createTransitionMatrix,
  validateTransitionMatrix,
  dominantEigenvalue
} from './matrices';
import type { Matrix5x5 } from '../../types/model';

describe('Matrix Operations', () => {
  describe('createSurvivalMatrix', () => {
    it('creates diagonal survival matrix', () => {
      const survivalRates = [0.4, 0.6, 0.7, 0.8, 0.85];
      const S = createSurvivalMatrix(survivalRates);

      // Check diagonal has survival rates
      for (let i = 0; i < 5; i++) {
        expect(S[i][i]).toBe(survivalRates[i]);
      }

      // Check off-diagonal is 0
      expect(S[0][1]).toBe(0);
      expect(S[1][0]).toBe(0);
      expect(S[2][4]).toBe(0);
    });

    it('throws error for wrong array length', () => {
      expect(() => createSurvivalMatrix([0.5, 0.6])).toThrow();
    });
  });

  describe('addMatrices', () => {
    it('adds matrices correctly', () => {
      const A: Matrix5x5 = [
        [1, 0, 0, 0, 0],
        [0, 1, 0, 0, 0],
        [0, 0, 1, 0, 0],
        [0, 0, 0, 1, 0],
        [0, 0, 0, 0, 1]
      ];
      const B: Matrix5x5 = [
        [1, 0, 0, 0, 0],
        [0, 1, 0, 0, 0],
        [0, 0, 1, 0, 0],
        [0, 0, 0, 1, 0],
        [0, 0, 0, 0, 1]
      ];
      const result = addMatrices(A, B);

      expect(result[0][0]).toBe(2);
      expect(result[1][1]).toBe(2);
      expect(result[4][4]).toBe(2);
      expect(result[0][1]).toBe(0);
    });
  });

  describe('multiplyMatrices', () => {
    it('multiplies identity matrices correctly', () => {
      const identity: Matrix5x5 = [
        [1, 0, 0, 0, 0],
        [0, 1, 0, 0, 0],
        [0, 0, 1, 0, 0],
        [0, 0, 0, 1, 0],
        [0, 0, 0, 0, 1]
      ];
      const result = multiplyMatrices(identity, identity);

      // Identity * Identity = Identity
      expect(result[0][0]).toBe(1);
      expect(result[1][1]).toBe(1);
      expect(result[0][1]).toBe(0);
      expect(result[4][4]).toBe(1);
    });
  });

  describe('createTransitionMatrix', () => {
    it('creates valid transition matrix', () => {
      const growth = [
        [0, 0, 0, 0, 0],
        [0.2, 0, 0, 0, 0],
        [0, 0.15, 0, 0, 0],
        [0, 0, 0.1, 0, 0],
        [0, 0, 0, 0.05, 0]
      ];
      const shrinkage = [
        [0, 0.05, 0, 0, 0],
        [0, 0, 0.05, 0, 0],
        [0, 0, 0, 0.05, 0],
        [0, 0, 0, 0, 0.05],
        [0, 0, 0, 0, 0]
      ];

      const T = createTransitionMatrix(growth, shrinkage);

      // Validate matrix structure
      expect(validateTransitionMatrix(T)).toBe(true);
    });
  });

  describe('dominantEigenvalue', () => {
    it('calculates eigenvalue for identity matrix', () => {
      const identity: Matrix5x5 = [
        [1, 0, 0, 0, 0],
        [0, 1, 0, 0, 0],
        [0, 0, 1, 0, 0],
        [0, 0, 0, 1, 0],
        [0, 0, 0, 0, 1]
      ];

      const lambda = dominantEigenvalue(identity);

      // Dominant eigenvalue of identity is 1
      expect(lambda).toBeCloseTo(1, 5);
    });
  });
});

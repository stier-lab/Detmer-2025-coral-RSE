import { describe, it, expect } from 'vitest';
import { buildDiagramLayout } from './useDiagramLayout';

describe('buildDiagramLayout', () => {
  const defaultLayers = { costs: false, disturbance: false, stochasticity: false };

  describe('story mode', () => {
    it('returns 6 nodes: 3 compartments + 2 external + 1 decision', () => {
      const { nodes } = buildDiagramLayout('story', defaultLayers);
      expect(nodes).toHaveLength(6);
      const types = nodes.map((n) => n.type);
      expect(types.filter((t) => t === 'compartment')).toHaveLength(3);
      expect(types.filter((t) => t === 'external')).toHaveLength(2);
      expect(types.filter((t) => t === 'decision')).toHaveLength(1);
    });

    it('returns 7 edges connecting all compartments', () => {
      const { edges } = buildDiagramLayout('story', defaultLayers);
      expect(edges).toHaveLength(7);
    });

    it('all edges are type flow', () => {
      const { edges } = buildDiagramLayout('story', defaultLayers);
      edges.forEach((e) => expect(e.type).toBe('flow'));
    });
  });

  describe('decision mode', () => {
    it('compartment nodes include parameters', () => {
      const { nodes } = buildDiagramLayout('decision', defaultLayers);
      const compartments = nodes.filter((n) => n.type === 'compartment');
      compartments.forEach((n) => {
        const data = n.data as Record<string, unknown>;
        expect(data.parameters).toBeDefined();
        expect(Array.isArray(data.parameters)).toBe(true);
      });
    });

    it('decision node shows parameter name and value', () => {
      const { nodes } = buildDiagramLayout('decision', defaultLayers);
      const decision = nodes.find((n) => n.type === 'decision');
      const data = decision!.data as Record<string, unknown>;
      expect(data.parameter).toBe('reef_prop');
      expect(data.value).toBe('0.75');
    });
  });

  describe('full mode', () => {
    it('compartment nodes include size class data', () => {
      const { nodes } = buildDiagramLayout('full', defaultLayers);
      const compartments = nodes.filter((n) => n.type === 'compartment');
      const withSC = compartments.filter((n) => {
        const data = n.data as Record<string, unknown>;
        return Array.isArray(data.sizeClasses) && (data.sizeClasses as unknown[]).length > 0;
      });
      expect(withSC).toHaveLength(2);
    });
  });

  describe('layer toggles', () => {
    it('cost layer enables showCost on cost-bearing edges', () => {
      const { edges } = buildDiagramLayout('decision', { ...defaultLayers, costs: true });
      const flowEdges = edges.filter((e) => {
        const data = e.data as Record<string, unknown>;
        return data && typeof data.cost === 'string' && data.cost !== '';
      });
      expect(flowEdges.length).toBeGreaterThan(0);
      flowEdges.forEach((e) => {
        const data = e.data as Record<string, unknown>;
        expect(data.showCost).toBe(true);
      });
    });
  });
});

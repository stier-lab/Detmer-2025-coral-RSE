export const COLORS = {
  bg: '#070E1A',
  bgLight: '#0C1929',
  lab: '#F59E0B',
  orchard: '#10B981',
  reef: '#38BDF8',
  collection: '#67E8F9',
  outplanting: '#FBBF24',
  transplanting: '#2DD4BF',
  external: '#64748B',
  decision: '#FDE047',
  text: '#FFFFFF',
  textMuted: 'rgba(255,255,255,0.6)',
  textDim: 'rgba(255,255,255,0.3)',
};

export const FONTS = {
  display: "'Crimson Pro', Georgia, serif",
  mono: "'JetBrains Mono', 'Consolas', monospace",
  body: "'Inter', system-ui, sans-serif",
};

export const SIZE_CLASSES = [
  { id: 'SC1', range: '0-10 cm2', color: '#10b981', fecundity: 0 },
  { id: 'SC2', range: '10-100 cm2', color: '#3b82f6', fecundity: 0 },
  { id: 'SC3', range: '100-900 cm2', color: '#8b5cf6', fecundity: 5000 },
  { id: 'SC4', range: '900-4k cm2', color: '#f59e0b', fecundity: 50000 },
  { id: 'SC5', range: '>4000 cm2', color: '#ef4444', fecundity: 100000 },
];

/**
 * Convert hex color to r,g,b string for use in rgba().
 */
export function hexToRgb(hex: string): string {
  const r = parseInt(hex.slice(1, 3), 16);
  const g = parseInt(hex.slice(3, 5), 16);
  const b = parseInt(hex.slice(5, 7), 16);
  return `${r}, ${g}, ${b}`;
}

/**
 * Deterministic pseudo-random number generator.
 * Returns a value in [0, 1).
 */
export function seededRandom(seed: number): number {
  const x = Math.sin(seed * 9301 + 49297) * 49297;
  return x - Math.floor(x);
}

/**
 * Deterministic noise in [-1, 1].
 */
export function seededNoise(seed: number): number {
  return seededRandom(seed) * 2 - 1;
}

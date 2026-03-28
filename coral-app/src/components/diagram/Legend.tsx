import type { DetailLevel } from './types';

interface Props {
  detailLevel: DetailLevel;
}

const EDGE_LEGEND = [
  { color: '#67E8F9', label: 'Larvae collection', style: 'solid' },
  { color: '#FBBF24', label: 'Outplanting', style: 'solid' },
  { color: '#2DD4BF', label: 'Transplanting', style: 'solid' },
  { color: '#64748B', label: 'External input', style: 'dashed' },
];

const NODE_LEGEND = [
  { color: '#F59E0B', label: 'Lab' },
  { color: '#10B981', label: 'Orchard' },
  { color: '#38BDF8', label: 'Reef' },
];

export default function Legend({ detailLevel }: Props) {
  return (
    <div className="legend-panel" style={{ minWidth: 140 }}>
      <div style={{ fontWeight: 700, marginBottom: 6, fontSize: 12, fontFamily: 'Crimson Pro, serif' }}>
        Legend
      </div>
      <div style={{ marginBottom: 8 }}>
        {NODE_LEGEND.map(({ color, label }) => (
          <div key={label} style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 3 }}>
            <div style={{ width: 10, height: 10, borderRadius: 3, background: color, opacity: 0.8 }} />
            <span>{label}</span>
          </div>
        ))}
      </div>
      <div>
        {EDGE_LEGEND.map(({ color, label, style }) => (
          <div key={label} style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 3 }}>
            <svg width="16" height="4">
              <line x1="0" y1="2" x2="16" y2="2" stroke={color} strokeWidth={2} strokeDasharray={style === 'dashed' ? '4 2' : undefined} />
            </svg>
            <span>{label}</span>
          </div>
        ))}
      </div>
      {detailLevel !== 'story' && (
        <div style={{ marginTop: 8, paddingTop: 6, borderTop: '1px solid rgba(255,255,255,0.1)', fontSize: 10, opacity: 0.6 }}>
          {detailLevel === 'decision' ? 'Showing parameters & costs' : 'Showing full demographic model'}
        </div>
      )}
    </div>
  );
}

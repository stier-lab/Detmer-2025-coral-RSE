import type { DetailLevel } from './types';

interface Props {
  value: DetailLevel;
  onChange: (level: DetailLevel) => void;
}

const LEVELS: { id: DetailLevel; label: string }[] = [
  { id: 'story', label: 'Story' },
  { id: 'decision', label: 'Decision' },
  { id: 'full', label: 'Full Model' },
];

export default function DetailToggle({ value, onChange }: Props) {
  return (
    <div className="legend-panel" style={{ display: 'flex', gap: 4 }}>
      {LEVELS.map((level) => (
        <button
          key={level.id}
          onClick={() => onChange(level.id)}
          style={{
            padding: '4px 10px',
            borderRadius: 6,
            border: 'none',
            fontSize: 11,
            fontWeight: value === level.id ? 700 : 400,
            background: value === level.id ? 'rgba(255,255,255,0.15)' : 'transparent',
            color: value === level.id ? '#fff' : 'rgba(255,255,255,0.5)',
            cursor: 'pointer',
            transition: 'all 0.2s',
          }}
        >
          {level.label}
        </button>
      ))}
    </div>
  );
}

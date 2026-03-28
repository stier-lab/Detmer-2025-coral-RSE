import type { LayerState } from './types';

interface Props {
  layers: LayerState;
  onChange: (layers: LayerState) => void;
}

const LAYER_CONFIG: { key: keyof LayerState; label: string; color: string }[] = [
  { key: 'costs', label: 'Costs', color: '#4ADE80' },
  { key: 'disturbance', label: 'Disturbance', color: '#F87171' },
  { key: 'stochasticity', label: 'Stochasticity', color: '#C084FC' },
];

export default function LayerToggles({ layers, onChange }: Props) {
  const toggle = (key: keyof LayerState) => {
    onChange({ ...layers, [key]: !layers[key] });
  };

  return (
    <div className="legend-panel" style={{ display: 'flex', gap: 4 }}>
      {LAYER_CONFIG.map(({ key, label, color }) => (
        <button
          key={key}
          onClick={() => toggle(key)}
          style={{
            padding: '3px 8px',
            borderRadius: 4,
            border: `1px solid ${layers[key] ? color : 'rgba(255,255,255,0.15)'}`,
            fontSize: 10,
            background: layers[key] ? `${color}22` : 'transparent',
            color: layers[key] ? color : 'rgba(255,255,255,0.4)',
            cursor: 'pointer',
            transition: 'all 0.2s',
          }}
        >
          {label}
        </button>
      ))}
    </div>
  );
}

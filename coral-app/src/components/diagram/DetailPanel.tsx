import type { CompartmentNodeData } from './types';

interface Props {
  nodeData: CompartmentNodeData | null;
  onClose: () => void;
}

export default function DetailPanel({ nodeData, onClose }: Props) {
  if (!nodeData) return null;

  return (
    <div className="detail-panel">
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
        <div style={{ color: nodeData.color, fontWeight: 700, fontSize: 18, fontFamily: 'Crimson Pro, serif' }}>
          {nodeData.label}
        </div>
        <button onClick={onClose} style={{ background: 'rgba(255,255,255,0.1)', border: 'none', color: 'rgba(255,255,255,0.6)', borderRadius: 6, padding: '4px 8px', cursor: 'pointer', fontSize: 12 }}>
          Close
        </button>
      </div>
      <div style={{ color: 'rgba(255,255,255,0.5)', fontSize: 13, marginBottom: 16 }}>{nodeData.subtitle}</div>

      {nodeData.parameters && (
        <div style={{ marginBottom: 16 }}>
          <div style={{ color: 'rgba(255,255,255,0.4)', fontSize: 10, textTransform: 'uppercase', letterSpacing: 1, marginBottom: 8 }}>Parameters</div>
          {nodeData.parameters.map((p) => (
            <div key={p.name} style={{ display: 'flex', justifyContent: 'space-between', padding: '6px 0', borderBottom: '1px solid rgba(255,255,255,0.06)' }}>
              <div>
                <span style={{ color: '#FDE047', fontFamily: 'JetBrains Mono, monospace', fontSize: 12 }}>{p.name}</span>
                <span style={{ color: 'rgba(255,255,255,0.35)', fontSize: 11, marginLeft: 8 }}>{p.description}</span>
              </div>
              <span style={{ color: 'rgba(255,255,255,0.7)', fontFamily: 'JetBrains Mono, monospace', fontSize: 12 }}>{p.value}</span>
            </div>
          ))}
        </div>
      )}

      {nodeData.sizeClasses && (
        <div>
          <div style={{ color: 'rgba(255,255,255,0.4)', fontSize: 10, textTransform: 'uppercase', letterSpacing: 1, marginBottom: 8 }}>Size Classes</div>
          {nodeData.sizeClasses.map((sc) => (
            <div key={sc.id} style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '6px 0', borderBottom: '1px solid rgba(255,255,255,0.06)' }}>
              <div style={{ width: 4, height: 24, borderRadius: 2, background: sc.color }} />
              <div style={{ flex: 1 }}>
                <div style={{ fontWeight: 600, fontSize: 12 }}>{sc.id}</div>
                <div style={{ color: 'rgba(255,255,255,0.4)', fontSize: 11 }}>{sc.range}</div>
              </div>
              <div style={{ textAlign: 'right', fontSize: 11, fontFamily: 'JetBrains Mono, monospace' }}>
                <div style={{ color: 'rgba(255,255,255,0.6)' }}>surv: {sc.survival}</div>
                {sc.fecundity > 0 && <div style={{ color: '#FB923C' }}>fec: {sc.fecundity.toLocaleString()}</div>}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

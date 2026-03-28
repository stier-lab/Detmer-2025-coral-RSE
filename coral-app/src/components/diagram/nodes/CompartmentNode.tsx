import { memo } from 'react';
import { Handle, Position, type NodeProps } from '@xyflow/react';
import type { CompartmentNodeData } from '../types';

const COMPARTMENT_STYLES: Record<string, { border: string; bg: string; glow: string }> = {
  lab: {
    border: 'rgba(245, 158, 11, 0.6)',
    bg: 'rgba(245, 158, 11, 0.08)',
    glow: 'glow-amber',
  },
  orchard: {
    border: 'rgba(16, 185, 129, 0.6)',
    bg: 'rgba(16, 185, 129, 0.08)',
    glow: 'glow-emerald',
  },
  reef: {
    border: 'rgba(56, 189, 248, 0.6)',
    bg: 'rgba(56, 189, 248, 0.08)',
    glow: 'glow-sky',
  },
};

function CompartmentNode({ data }: NodeProps) {
  const nodeData = data as unknown as CompartmentNodeData;
  const style = COMPARTMENT_STYLES[nodeData.compartmentId] ?? COMPARTMENT_STYLES.lab;

  return (
    <div
      className={`compartment-node ${style.glow} ${nodeData.layers.disturbance && nodeData.compartmentId !== 'lab' ? 'disturbance-overlay' : ''}`}
      style={{
        background: style.bg,
        border: `1.5px solid ${style.border}`,
      }}
      title={`${nodeData.label}: ${nodeData.subtitle}`}
    >
      <Handle type="target" position={Position.Left} id="left" style={{ background: style.border }} />
      <Handle type="target" position={Position.Top} id="top" style={{ background: style.border }} />

      <div style={{ color: nodeData.color, fontWeight: 700, fontSize: 15, fontFamily: 'Crimson Pro, serif' }}>
        {nodeData.label}
      </div>
      <div style={{ color: 'rgba(255,255,255,0.5)', fontSize: 11, marginTop: 2 }}>
        {nodeData.subtitle}
      </div>

      {nodeData.detailLevel !== 'story' && nodeData.parameters && (
        <div style={{ marginTop: 10, display: 'flex', flexDirection: 'column', gap: 4 }}>
          {nodeData.parameters.map((p) => (
            <div key={p.name} style={{ display: 'flex', justifyContent: 'space-between', gap: 12 }}>
              <span style={{ color: '#FDE047', fontFamily: 'JetBrains Mono, monospace', fontSize: 10 }}>
                {p.name}
              </span>
              <span style={{ color: 'rgba(255,255,255,0.6)', fontFamily: 'JetBrains Mono, monospace', fontSize: 10 }}>
                {p.value}
              </span>
            </div>
          ))}
        </div>
      )}

      {nodeData.detailLevel === 'full' && nodeData.sizeClasses && (
        <div style={{ marginTop: 10, display: 'flex', flexDirection: 'column', gap: 3 }}>
          {nodeData.sizeClasses.map((sc) => (
            <div key={sc.id} className="size-class-row" title={`${sc.id}: ${sc.range}, survival=${sc.survival}`}>
              <div className="size-class-accent" style={{ background: sc.color }} />
              <span style={{ fontWeight: 600, width: 28 }}>{sc.id}</span>
              <span style={{ color: 'rgba(255,255,255,0.5)', flex: 1 }}>{sc.range}</span>
              {sc.fecundity > 0 && (
                <span style={{ color: '#FB923C', fontSize: 9 }} title="Reproduces">F</span>
              )}
            </div>
          ))}
        </div>
      )}

      {nodeData.layers.stochasticity && nodeData.compartmentId !== 'lab' && (
        <div style={{ marginTop: 6 }}>
          <span className="stochasticity-badge">sigma_s, sigma_f</span>
        </div>
      )}

      <Handle type="source" position={Position.Right} id="right" style={{ background: style.border }} />
      <Handle type="source" position={Position.Bottom} id="bottom" style={{ background: style.border }} />
      <Handle type="source" position={Position.Left} id="left-source" style={{ background: style.border }} />
    </div>
  );
}

export default memo(CompartmentNode);

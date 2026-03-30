import React, { memo } from 'react';
import { Handle, Position, type NodeProps } from '@xyflow/react';
import type { CompartmentNodeData } from '../types';
import { LabIcon, OrchardIcon, ReefIcon } from './NodeIcons';

const ICON_MAP: Record<string, React.FC<{ size?: number; color?: string }>> = {
  lab: LabIcon,
  orchard: OrchardIcon,
  reef: ReefIcon,
};

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
  const Icon = ICON_MAP[nodeData.compartmentId];
  const isHighlighted = (nodeData as any).isHighlighted !== false;

  return (
    <div
      className={`compartment-node ${style.glow} ${nodeData.layers.disturbance && nodeData.compartmentId !== 'lab' ? 'disturbance-overlay' : ''}`}
      style={{
        background: style.bg,
        border: `1.5px solid ${style.border}`,
        opacity: isHighlighted ? 1 : 0.25,
        transition: 'opacity 0.3s ease',
      }}
      title={`${nodeData.label}: ${nodeData.subtitle}`}
    >
      <Handle type="target" position={Position.Left} id="left" style={{ background: style.border }} />
      <Handle type="target" position={Position.Top} id="top" style={{ background: style.border }} />

      <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
        {Icon && <Icon size={20} color={nodeData.color} />}
        <div style={{ color: nodeData.color, fontWeight: 700, fontSize: 17, fontFamily: 'Crimson Pro, serif' }}>
          {nodeData.label}
        </div>
      </div>
      <div style={{ color: 'rgba(255,255,255,0.5)', fontSize: 13, marginTop: 2 }}>
        {nodeData.subtitle}
      </div>

      {nodeData.detailLevel !== 'story' && nodeData.parameters && (
        <div style={{ marginTop: 10, display: 'flex', flexDirection: 'column', gap: 4 }}>
          {nodeData.parameters.map((p) => (
            <div key={p.name} style={{ display: 'flex', justifyContent: 'space-between', gap: 12 }}>
              <span style={{ color: '#FDE047', fontFamily: 'JetBrains Mono, monospace', fontSize: 11 }}>
                {p.name}
              </span>
              <span style={{ color: 'rgba(255,255,255,0.6)', fontFamily: 'JetBrains Mono, monospace', fontSize: 11 }}>
                {p.value}
              </span>
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

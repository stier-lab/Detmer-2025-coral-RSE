import { memo } from 'react';
import { Handle, Position, type NodeProps } from '@xyflow/react';
import type { ExternalNodeData } from '../types';
import { WavesIcon } from './NodeIcons';

function ExternalNode({ data }: NodeProps) {
  const nodeData = data as unknown as ExternalNodeData;
  const isHighlighted = (nodeData as any).isHighlighted !== false;

  return (
    <div
      className="external-node"
      style={{
        opacity: isHighlighted ? 1 : 0.25,
        transition: 'opacity 0.3s ease',
      }}
    >
      <Handle type="source" position={Position.Right} id="right" style={{ background: '#64748B' }} />
      <Handle type="source" position={Position.Bottom} id="bottom" style={{ background: '#64748B' }} />
      <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
        <WavesIcon size={16} color="#64748B" />
        <div style={{ fontWeight: 600, fontSize: 14, fontFamily: 'Crimson Pro, serif' }}>
          {nodeData.label}
        </div>
      </div>
      <div style={{ fontSize: 12, opacity: 0.6, marginTop: 1 }}>
        {nodeData.subtitle}
      </div>
    </div>
  );
}

export default memo(ExternalNode);

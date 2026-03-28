import { memo } from 'react';
import { Handle, Position, type NodeProps } from '@xyflow/react';
import type { ExternalNodeData } from '../types';

function ExternalNode({ data }: NodeProps) {
  const nodeData = data as unknown as ExternalNodeData;

  return (
    <div className="external-node">
      <Handle type="source" position={Position.Right} id="right" style={{ background: '#64748B' }} />
      <Handle type="source" position={Position.Bottom} id="bottom" style={{ background: '#64748B' }} />
      <div style={{ fontWeight: 600, fontSize: 12, fontFamily: 'Crimson Pro, serif' }}>
        {nodeData.label}
      </div>
      <div style={{ fontSize: 10, opacity: 0.6, marginTop: 1 }}>
        {nodeData.subtitle}
      </div>
    </div>
  );
}

export default memo(ExternalNode);

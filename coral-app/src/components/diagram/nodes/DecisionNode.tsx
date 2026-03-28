import { memo } from 'react';
import { Handle, Position, type NodeProps } from '@xyflow/react';
import type { DecisionNodeData } from '../types';

function DecisionNode({ data }: NodeProps) {
  const nodeData = data as unknown as DecisionNodeData;

  return (
    <div className="decision-node">
      <Handle type="target" position={Position.Left} id="left" style={{ background: '#FDE047' }} />
      <Handle type="source" position={Position.Top} id="top" style={{ background: '#FDE047' }} />
      <Handle type="source" position={Position.Right} id="right" style={{ background: '#FDE047' }} />
      <Handle type="source" position={Position.Bottom} id="bottom" style={{ background: '#FDE047' }} />

      <div className="decision-node-content">
        <div style={{ fontSize: 10, opacity: 0.7 }}>{nodeData.label}</div>
        {nodeData.detailLevel !== 'story' && (
          <>
            <div style={{ fontFamily: 'JetBrains Mono, monospace', fontSize: 11, marginTop: 2 }}>
              {nodeData.parameter}
            </div>
            <div style={{ fontSize: 13, fontWeight: 700, marginTop: 1 }}>
              {nodeData.value}
            </div>
          </>
        )}
      </div>
    </div>
  );
}

export default memo(DecisionNode);

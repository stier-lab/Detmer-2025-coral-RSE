import { BaseEdge, getBezierPath, type EdgeProps } from '@xyflow/react';
import type { FlowEdgeData } from '../types';

export default function FlowEdge({
  id,
  sourceX,
  sourceY,
  targetX,
  targetY,
  sourcePosition,
  targetPosition,
  data,
  markerEnd,
}: EdgeProps) {
  const edgeData = data as unknown as FlowEdgeData;
  const color = edgeData?.color ?? '#64748B';
  const isDashed = edgeData?.flowType === 'external';
  const dimmed = edgeData?.dimmed ?? false;

  const [edgePath, labelX, labelY] = getBezierPath({
    sourceX,
    sourceY,
    sourcePosition,
    targetX,
    targetY,
    targetPosition,
  });

  return (
    <>
      <path d={edgePath} fill="none" stroke={color} strokeWidth={8} strokeOpacity={dimmed ? 0.02 : 0.1} />
      <BaseEdge
        id={id}
        path={edgePath}
        markerEnd={markerEnd}
        style={{
          stroke: color,
          strokeWidth: 2,
          strokeDasharray: isDashed ? '6 4' : undefined,
          opacity: dimmed ? 0.15 : 1,
          transition: 'opacity 0.3s ease',
        }}
      />
      {edgeData?.animated && !dimmed && (
        <>
          <circle r="3" fill={color}>
            <animateMotion dur="3s" repeatCount="indefinite" path={edgePath} />
          </circle>
          <circle r="3" fill={color}>
            <animateMotion dur="3s" repeatCount="indefinite" path={edgePath} begin="1s" />
          </circle>
          <circle r="3" fill={color}>
            <animateMotion dur="3s" repeatCount="indefinite" path={edgePath} begin="2s" />
          </circle>
        </>
      )}
      {edgeData?.label && (
        <foreignObject
          x={labelX - 50}
          y={labelY - 12}
          width={100}
          height={32}
          style={{ overflow: 'visible', pointerEvents: 'none' }}
        >
          <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
            <span className="edge-label-pill">{edgeData.label}</span>
            {edgeData.showCost && edgeData.cost && (
              <span className="cost-badge">{edgeData.cost}</span>
            )}
          </div>
        </foreignObject>
      )}
    </>
  );
}

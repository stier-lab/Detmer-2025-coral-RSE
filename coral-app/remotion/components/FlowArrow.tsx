import React from 'react';
import { interpolate, useCurrentFrame } from 'remotion';
import { FONTS } from '../styles';

interface Props {
  fromX: number;
  fromY: number;
  toX: number;
  toY: number;
  color: string;
  label?: string;
  delay?: number;
  dashed?: boolean;
  particleCount?: number;
}

export const FlowArrow: React.FC<Props> = ({
  fromX,
  fromY,
  toX,
  toY,
  color,
  label,
  delay = 0,
  dashed = false,
  particleCount = 3,
}) => {
  const frame = useCurrentFrame();
  const opacity = interpolate(frame - delay, [0, 20], [0, 1], {
    extrapolateRight: 'clamp',
    extrapolateLeft: 'clamp',
  });

  const midX = (fromX + toX) / 2;
  const midY = (fromY + toY) / 2;
  const dx = toX - fromX;
  const dy = toY - fromY;
  const curvature = 0.15;
  const cpX = midX - dy * curvature;
  const cpY = midY + dx * curvature;

  const pathD = `M ${fromX} ${fromY} Q ${cpX} ${cpY} ${toX} ${toY}`;
  const angle = Math.atan2(toY - cpY, toX - cpX) * (180 / Math.PI);

  return (
    <svg
      style={{
        position: 'absolute',
        top: 0,
        left: 0,
        width: 1920,
        height: 1080,
        pointerEvents: 'none',
        opacity,
      }}
    >
      {/* Glow */}
      <path
        d={pathD}
        fill="none"
        stroke={color}
        strokeWidth={8}
        strokeOpacity={0.1}
      />
      {/* Main line */}
      <path
        d={pathD}
        fill="none"
        stroke={color}
        strokeWidth={2.5}
        strokeDasharray={dashed ? '8 5' : undefined}
      />
      {/* Arrow head */}
      <polygon
        points="-8,-5 0,0 -8,5"
        fill={color}
        transform={`translate(${toX},${toY}) rotate(${angle})`}
      />
      {/* Animated particles */}
      {Array.from({ length: particleCount }).map((_, i) => {
        const progress = ((frame - delay + i * 20) % 60) / 60;
        if (frame < delay) return null;
        const t = progress;
        const px =
          (1 - t) * (1 - t) * fromX + 2 * (1 - t) * t * cpX + t * t * toX;
        const py =
          (1 - t) * (1 - t) * fromY + 2 * (1 - t) * t * cpY + t * t * toY;
        const particleOpacity = interpolate(
          t,
          [0, 0.2, 0.8, 1],
          [0.2, 0.9, 0.9, 0.2],
          { extrapolateRight: 'clamp', extrapolateLeft: 'clamp' }
        );
        return (
          <circle
            key={i}
            cx={px}
            cy={py}
            r={4}
            fill={color}
            opacity={particleOpacity}
          />
        );
      })}
      {/* Label */}
      {label && (
        <foreignObject x={cpX - 70} y={cpY - 16} width={140} height={32}>
          <div
            style={{
              textAlign: 'center',
              background: 'rgba(7,14,26,0.85)',
              border: '1px solid rgba(255,255,255,0.15)',
              borderRadius: 6,
              padding: '3px 10px',
              fontSize: 12,
              fontFamily: FONTS.mono,
              color: 'rgba(255,255,255,0.8)',
              whiteSpace: 'nowrap',
            }}
          >
            {label}
          </div>
        </foreignObject>
      )}
    </svg>
  );
};

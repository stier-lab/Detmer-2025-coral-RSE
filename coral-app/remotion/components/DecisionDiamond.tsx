import React from 'react';
import { spring, useCurrentFrame, useVideoConfig, interpolate } from 'remotion';
import { COLORS, FONTS } from '../styles';

interface Props {
  x: number;
  y: number;
  label: string;
  value: string;
  delay?: number;
}

export const DecisionDiamond: React.FC<Props> = ({
  x,
  y,
  label,
  value,
  delay = 0,
}) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const scale = spring({
    frame,
    fps,
    from: 0,
    to: 1,
    delay,
    config: { damping: 10, stiffness: 100 },
  });

  const opacity = interpolate(frame - delay, [0, 10], [0, 1], {
    extrapolateRight: 'clamp',
    extrapolateLeft: 'clamp',
  });

  return (
    <div
      style={{
        position: 'absolute',
        left: x - 55,
        top: y - 55,
        width: 110,
        height: 110,
        opacity,
        transform: `scale(${scale}) rotate(45deg)`,
        background: 'rgba(253, 224, 71, 0.12)',
        border: '2px solid rgba(253, 224, 71, 0.6)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
      }}
    >
      <div style={{ transform: 'rotate(-45deg)', textAlign: 'center' }}>
        <div
          style={{
            color: COLORS.decision,
            fontSize: 12,
            fontFamily: FONTS.mono,
          }}
        >
          {label}
        </div>
        <div
          style={{
            color: COLORS.decision,
            fontSize: 22,
            fontWeight: 700,
            fontFamily: FONTS.mono,
          }}
        >
          {value}
        </div>
      </div>
    </div>
  );
};

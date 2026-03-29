import React from 'react';
import { interpolate, useCurrentFrame, spring, useVideoConfig } from 'remotion';
import { COLORS, FONTS, hexToRgb } from '../styles';

interface Props {
  label: string;
  subtitle: string;
  color: string;
  x: number;
  y: number;
  width?: number;
  height?: number;
  delay?: number;
  opacity?: number;
  scale?: number;
  showGlow?: boolean;
}

export const CompartmentBox: React.FC<Props> = ({
  label,
  subtitle,
  color,
  x,
  y,
  width = 240,
  height = 100,
  delay = 0,
  opacity = 1,
  scale = 1,
  showGlow = true,
}) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const springScale = spring({
    frame,
    fps,
    from: 0.8,
    to: scale,
    delay,
    config: { damping: 12, stiffness: 80 },
  });

  const fadeIn = interpolate(frame - delay, [0, 15], [0, opacity], {
    extrapolateRight: 'clamp',
    extrapolateLeft: 'clamp',
  });

  return (
    <div
      style={{
        position: 'absolute',
        left: x - width / 2,
        top: y - height / 2,
        width,
        height,
        opacity: fadeIn,
        transform: `scale(${springScale})`,
        background: `rgba(${hexToRgb(color)}, 0.08)`,
        border: `2px solid rgba(${hexToRgb(color)}, 0.6)`,
        borderRadius: 16,
        backdropFilter: 'blur(12px)',
        display: 'flex',
        flexDirection: 'column',
        justifyContent: 'center',
        alignItems: 'center',
        padding: 16,
      }}
    >
      {showGlow && (
        <div
          style={{
            position: 'absolute',
            inset: -20,
            background: `radial-gradient(ellipse, rgba(${hexToRgb(color)}, 0.15) 0%, transparent 70%)`,
            borderRadius: 30,
            pointerEvents: 'none',
          }}
        />
      )}
      <div
        style={{
          color,
          fontSize: 24,
          fontWeight: 700,
          fontFamily: FONTS.display,
          zIndex: 1,
        }}
      >
        {label}
      </div>
      <div
        style={{
          color: COLORS.textMuted,
          fontSize: 14,
          fontFamily: FONTS.body,
          marginTop: 4,
          zIndex: 1,
        }}
      >
        {subtitle}
      </div>
    </div>
  );
};

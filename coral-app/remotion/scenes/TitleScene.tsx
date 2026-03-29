import React from 'react';
import {
  AbsoluteFill,
  useCurrentFrame,
  useVideoConfig,
  interpolate,
  spring,
  Easing,
} from 'remotion';
import { COLORS, FONTS, hexToRgb } from '../styles';

export const TitleScene: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  // Title spring-animated scale entrance
  const titleScale = spring({
    frame,
    fps,
    from: 0.6,
    to: 1,
    config: { damping: 12, stiffness: 80 },
  });

  const titleOpacity = interpolate(frame, [0, 15], [0, 1], {
    extrapolateRight: 'clamp',
    extrapolateLeft: 'clamp',
  });

  // Subtitle fades in after 0.5s (15 frames at 30fps)
  const subtitleOpacity = interpolate(frame, [15, 30], [0, 1], {
    extrapolateRight: 'clamp',
    extrapolateLeft: 'clamp',
  });

  const subtitleTranslateY = interpolate(frame, [15, 30], [12, 0], {
    extrapolateRight: 'clamp',
    extrapolateLeft: 'clamp',
    easing: Easing.inOut(Easing.quad),
  });

  // "Elkhorn Coral" fades in at bottom (around frame 40)
  const elkhornOpacity = interpolate(frame, [40, 55], [0, 1], {
    extrapolateRight: 'clamp',
    extrapolateLeft: 'clamp',
  });

  // Subtle pulsing glow behind the title text
  const glowPulse = interpolate(
    frame % 60,
    [0, 30, 60],
    [0.15, 0.3, 0.15],
    {
      extrapolateRight: 'clamp',
      extrapolateLeft: 'clamp',
    },
  );

  const glowScale = interpolate(frame % 60, [0, 30, 60], [1, 1.08, 1], {
    extrapolateRight: 'clamp',
    extrapolateLeft: 'clamp',
  });

  return (
    <AbsoluteFill
      style={{
        background: `radial-gradient(ellipse at 50% 50%, ${COLORS.bgLight} 0%, ${COLORS.bg} 70%)`,
        display: 'flex',
        flexDirection: 'column',
        justifyContent: 'center',
        alignItems: 'center',
      }}
    >
      {/* Pulsing glow behind title */}
      <div
        style={{
          position: 'absolute',
          top: '50%',
          left: '50%',
          width: 800,
          height: 200,
          transform: `translate(-50%, -60%) scale(${glowScale})`,
          background: `radial-gradient(ellipse, rgba(${hexToRgb(COLORS.reef)}, ${glowPulse}) 0%, transparent 70%)`,
          pointerEvents: 'none',
        }}
      />

      {/* Main title */}
      <div
        style={{
          opacity: titleOpacity,
          transform: `scale(${titleScale})`,
          fontFamily: FONTS.display,
          fontSize: 72,
          fontWeight: 700,
          color: COLORS.text,
          textAlign: 'center',
          lineHeight: 1.15,
          maxWidth: 1200,
          zIndex: 1,
        }}
      >
        Coral Restoration{'\n'}Strategy Evaluation
      </div>

      {/* Subtitle */}
      <div
        style={{
          opacity: subtitleOpacity,
          transform: `translateY(${subtitleTranslateY}px)`,
          fontFamily: FONTS.body,
          fontSize: 28,
          color: COLORS.textMuted,
          textAlign: 'center',
          marginTop: 24,
          zIndex: 1,
        }}
      >
        A Demographic Model for <em>Acropora palmata</em>
      </div>

      {/* Elkhorn Coral text at bottom */}
      <div
        style={{
          position: 'absolute',
          bottom: 80,
          opacity: elkhornOpacity,
          fontFamily: FONTS.mono,
          fontSize: 18,
          color: COLORS.textDim,
          letterSpacing: 3,
          textTransform: 'uppercase',
          zIndex: 1,
        }}
      >
        Elkhorn Coral
      </div>
    </AbsoluteFill>
  );
};

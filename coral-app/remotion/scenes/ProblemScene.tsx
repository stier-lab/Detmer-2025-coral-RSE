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

export const ProblemScene: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  // "The Challenge" title fades in
  const titleOpacity = interpolate(frame, [0, 20], [0, 1], {
    extrapolateRight: 'clamp',
    extrapolateLeft: 'clamp',
  });

  const titleTranslateY = interpolate(frame, [0, 20], [-15, 0], {
    extrapolateRight: 'clamp',
    extrapolateLeft: 'clamp',
    easing: Easing.inOut(Easing.quad),
  });

  // Stat counter: counts from 0 to 97 over frames 15-90 (~0.5s to 3s)
  const counterRaw = interpolate(frame, [15, 90], [0, 97], {
    extrapolateRight: 'clamp',
    extrapolateLeft: 'clamp',
  });
  const counterValue = Math.round(counterRaw);

  // Counter opacity
  const counterOpacity = interpolate(frame, [10, 25], [0, 1], {
    extrapolateRight: 'clamp',
    extrapolateLeft: 'clamp',
  });

  // Counter scale with spring for emphasis when it arrives
  const counterScale = spring({
    frame,
    fps,
    from: 0.8,
    to: 1,
    delay: 10,
    config: { damping: 14, stiffness: 60 },
  });

  // "coral cover lost..." text opacity (appears with counter)
  const lostTextOpacity = interpolate(frame, [20, 35], [0, 1], {
    extrapolateRight: 'clamp',
    extrapolateLeft: 'clamp',
  });

  // "Can strategic restoration..." fades in after counter finishes (frame 100)
  const questionOpacity = interpolate(frame, [100, 120], [0, 1], {
    extrapolateRight: 'clamp',
    extrapolateLeft: 'clamp',
  });

  const questionTranslateY = interpolate(frame, [100, 120], [15, 0], {
    extrapolateRight: 'clamp',
    extrapolateLeft: 'clamp',
    easing: Easing.inOut(Easing.quad),
  });

  // Red-tinted ambient gradient intensity builds with the counter
  const redIntensity = interpolate(frame, [15, 90], [0.03, 0.12], {
    extrapolateRight: 'clamp',
    extrapolateLeft: 'clamp',
  });

  return (
    <AbsoluteFill
      style={{
        background: COLORS.bg,
        display: 'flex',
        flexDirection: 'column',
        justifyContent: 'center',
        alignItems: 'center',
      }}
    >
      {/* Red-tinted ambient gradient */}
      <div
        style={{
          position: 'absolute',
          inset: 0,
          background: `radial-gradient(ellipse at 50% 40%, rgba(220, 38, 38, ${redIntensity}) 0%, transparent 70%)`,
          pointerEvents: 'none',
        }}
      />

      {/* Title */}
      <div
        style={{
          position: 'absolute',
          top: 120,
          opacity: titleOpacity,
          transform: `translateY(${titleTranslateY}px)`,
          fontFamily: FONTS.display,
          fontSize: 48,
          fontWeight: 700,
          color: COLORS.text,
          zIndex: 1,
        }}
      >
        The Challenge
      </div>

      {/* Large animated stat counter */}
      <div
        style={{
          opacity: counterOpacity,
          transform: `scale(${counterScale})`,
          textAlign: 'center',
          zIndex: 1,
        }}
      >
        <div
          style={{
            fontFamily: FONTS.mono,
            fontSize: 180,
            fontWeight: 700,
            color: '#EF4444',
            lineHeight: 1,
          }}
        >
          {counterValue}%
        </div>
        <div
          style={{
            opacity: lostTextOpacity,
            fontFamily: FONTS.body,
            fontSize: 28,
            color: COLORS.textMuted,
            marginTop: 12,
            maxWidth: 600,
          }}
        >
          coral cover lost in the Caribbean since 1970
        </div>
      </div>

      {/* Question text */}
      <div
        style={{
          position: 'absolute',
          bottom: 160,
          opacity: questionOpacity,
          transform: `translateY(${questionTranslateY}px)`,
          fontFamily: FONTS.display,
          fontSize: 32,
          fontStyle: 'italic',
          color: COLORS.reef,
          textAlign: 'center',
          maxWidth: 800,
          zIndex: 1,
        }}
      >
        Can strategic restoration accelerate recovery?
      </div>
    </AbsoluteFill>
  );
};

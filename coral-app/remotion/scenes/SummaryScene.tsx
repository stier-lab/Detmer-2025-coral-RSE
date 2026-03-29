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

const BULLET_POINTS = [
  {
    text: 'Orchard-based strategies maximize long-term coral cover',
    color: COLORS.orchard,
  },
  {
    text: 'Stochastic environments favor diversified restoration',
    color: '#C084FC', // purple / stochasticity color
  },
  {
    text: 'Model-guided decisions outperform intuition',
    color: COLORS.reef,
  },
];

export const SummaryScene: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  // Title spring entrance
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

  // Bullet points: fade in sequentially at 1s, 2s, 3s (frames 30, 60, 90)
  const bulletData = BULLET_POINTS.map((bullet, i) => {
    const startFrame = 30 + i * 30;
    const opacity = interpolate(frame, [startFrame, startFrame + 20], [0, 1], {
      extrapolateRight: 'clamp',
      extrapolateLeft: 'clamp',
    });
    const translateX = interpolate(
      frame,
      [startFrame, startFrame + 20],
      [30, 0],
      {
        extrapolateRight: 'clamp',
        extrapolateLeft: 'clamp',
      },
    );
    return { ...bullet, opacity, translateX };
  });

  // "Explore the interactive model" at 4s (frame 120)
  const exploreOpacity = interpolate(frame, [120, 140], [0, 1], {
    extrapolateRight: 'clamp',
    extrapolateLeft: 'clamp',
  });

  const exploreTranslateY = interpolate(frame, [120, 140], [12, 0], {
    extrapolateRight: 'clamp',
    extrapolateLeft: 'clamp',
    easing: Easing.inOut(Easing.quad),
  });

  // Subtle glow pulse on explore text
  const glowPulse = interpolate(
    Math.max(0, frame - 120) % 60,
    [0, 30, 60],
    [0.15, 0.35, 0.15],
    {
      extrapolateRight: 'clamp',
      extrapolateLeft: 'clamp',
    },
  );

  // Credits at 5s (frame 150)
  const creditsOpacity = interpolate(frame, [150, 170], [0, 1], {
    extrapolateRight: 'clamp',
    extrapolateLeft: 'clamp',
  });

  // Ambient gradient — calm blue like title scene
  const ambientOpacity = interpolate(frame, [0, 30], [0, 0.1], {
    extrapolateRight: 'clamp',
    extrapolateLeft: 'clamp',
  });

  return (
    <AbsoluteFill
      style={{
        background: `radial-gradient(ellipse at 50% 50%, ${COLORS.bgLight} 0%, ${COLORS.bg} 70%)`,
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
      }}
    >
      {/* Calm blue ambient glow */}
      <div
        style={{
          position: 'absolute',
          top: '50%',
          left: '50%',
          width: 1200,
          height: 600,
          transform: 'translate(-50%, -50%)',
          background: `radial-gradient(ellipse, rgba(${hexToRgb(COLORS.reef)}, ${ambientOpacity}) 0%, transparent 70%)`,
          pointerEvents: 'none',
        }}
      />

      {/* Title */}
      <div
        style={{
          opacity: titleOpacity,
          transform: `scale(${titleScale})`,
          fontFamily: FONTS.display,
          fontSize: 60,
          fontWeight: 700,
          color: COLORS.text,
          textAlign: 'center',
          marginBottom: 60,
          zIndex: 1,
        }}
      >
        Key Insights
      </div>

      {/* Bullet points */}
      <div
        style={{
          display: 'flex',
          flexDirection: 'column',
          gap: 32,
          zIndex: 1,
          maxWidth: 1000,
        }}
      >
        {bulletData.map((bullet, i) => (
          <div
            key={i}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: 20,
              opacity: bullet.opacity,
              transform: `translateX(${bullet.translateX}px)`,
            }}
          >
            {/* Colored dot */}
            <div
              style={{
                width: 18,
                height: 18,
                borderRadius: '50%',
                background: bullet.color,
                boxShadow: `0 0 12px rgba(${hexToRgb(bullet.color)}, 0.5)`,
                flexShrink: 0,
              }}
            />
            <div
              style={{
                fontFamily: FONTS.body,
                fontSize: 28,
                color: COLORS.text,
                lineHeight: 1.4,
              }}
            >
              {bullet.text}
            </div>
          </div>
        ))}
      </div>

      {/* Explore the interactive model */}
      <div
        style={{
          position: 'absolute',
          bottom: 160,
          width: '100%',
          textAlign: 'center',
          opacity: exploreOpacity,
          transform: `translateY(${exploreTranslateY}px)`,
          zIndex: 1,
        }}
      >
        <span
          style={{
            fontFamily: FONTS.body,
            fontSize: 30,
            fontWeight: 600,
            color: COLORS.reef,
            textShadow: `0 0 20px rgba(${hexToRgb(COLORS.reef)}, ${glowPulse})`,
          }}
        >
          Explore the interactive model
        </span>
      </div>

      {/* Credits */}
      <div
        style={{
          position: 'absolute',
          bottom: 70,
          width: '100%',
          textAlign: 'center',
          opacity: creditsOpacity,
          fontFamily: FONTS.mono,
          fontSize: 20,
          color: COLORS.textDim,
          letterSpacing: 2,
          zIndex: 1,
        }}
      >
        Detmer et al. 2025
      </div>
    </AbsoluteFill>
  );
};

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
import { DecisionDiamond } from '../components/DecisionDiamond';
import { FlowArrow } from '../components/FlowArrow';

export const DecisionPointScene: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  // Title entrance
  const titleOpacity = interpolate(frame, [0, 15], [0, 1], {
    extrapolateRight: 'clamp',
    extrapolateLeft: 'clamp',
  });

  const titleScale = spring({
    frame,
    fps,
    from: 0.7,
    to: 1,
    config: { damping: 12, stiffness: 80 },
  });

  // Diamond value animates from "0.0" to "0.5" over frames 20-90
  const valueProgress = interpolate(frame, [20, 90], [0, 0.5], {
    extrapolateRight: 'clamp',
    extrapolateLeft: 'clamp',
  });
  const displayValue = valueProgress.toFixed(1);

  // Golden glow pulse on the diamond
  const glowPulse = interpolate(frame % 60, [0, 30, 60], [0.1, 0.35, 0.1], {
    extrapolateRight: 'clamp',
    extrapolateLeft: 'clamp',
  });

  const glowScale = interpolate(frame % 60, [0, 30, 60], [1, 1.12, 1], {
    extrapolateRight: 'clamp',
    extrapolateLeft: 'clamp',
  });

  // Diverging arrows appear at ~1.5s (frame 45)
  const arrowDelay = 45;

  // Bottom annotation fades in at ~3s (frame 90)
  const annotationOpacity = interpolate(frame, [90, 110], [0, 1], {
    extrapolateRight: 'clamp',
    extrapolateLeft: 'clamp',
  });

  const annotationTranslateY = interpolate(frame, [90, 110], [16, 0], {
    extrapolateRight: 'clamp',
    extrapolateLeft: 'clamp',
    easing: Easing.inOut(Easing.quad),
  });

  return (
    <AbsoluteFill
      style={{
        background: `radial-gradient(ellipse at 50% 50%, ${COLORS.bgLight} 0%, ${COLORS.bg} 70%)`,
      }}
    >
      {/* Title */}
      <div
        style={{
          position: 'absolute',
          top: 60,
          width: '100%',
          textAlign: 'center',
          opacity: titleOpacity,
          transform: `scale(${titleScale})`,
          fontFamily: FONTS.display,
          fontSize: 56,
          fontWeight: 700,
          color: COLORS.text,
          zIndex: 2,
        }}
      >
        The Key Decision
      </div>

      {/* Pulsing golden glow behind diamond */}
      <div
        style={{
          position: 'absolute',
          left: 960 - 120,
          top: 450 - 120,
          width: 240,
          height: 240,
          transform: `scale(${glowScale})`,
          background: `radial-gradient(ellipse, rgba(${hexToRgb(COLORS.decision)}, ${glowPulse}) 0%, transparent 70%)`,
          pointerEvents: 'none',
          zIndex: 0,
        }}
      />

      {/* Decision Diamond */}
      <DecisionDiamond
        x={960}
        y={450}
        label="reef_prop"
        value={displayValue}
        delay={10}
      />

      {/* Diverging arrows */}
      <FlowArrow
        fromX={905}
        fromY={450}
        toX={500}
        toY={580}
        color={COLORS.orchard}
        label="To Orchard"
        delay={arrowDelay}
        particleCount={3}
      />

      <FlowArrow
        fromX={1015}
        fromY={450}
        toX={1420}
        toY={580}
        color={COLORS.reef}
        label="To Reef"
        delay={arrowDelay}
        particleCount={3}
      />

      {/* Bottom annotation */}
      <div
        style={{
          position: 'absolute',
          bottom: 100,
          width: '100%',
          textAlign: 'center',
          opacity: annotationOpacity,
          transform: `translateY(${annotationTranslateY}px)`,
          fontFamily: FONTS.body,
          fontSize: 26,
          color: COLORS.textMuted,
          zIndex: 2,
        }}
      >
        What fraction of production goes directly to reef?
      </div>
    </AbsoluteFill>
  );
};

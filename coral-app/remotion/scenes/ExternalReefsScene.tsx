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
import { CompartmentBox } from '../components/CompartmentBox';
import { FlowArrow } from '../components/FlowArrow';

const PARTICLE_COUNT = 12;

interface LarvaParticle {
  startFrame: number;
  duration: number;
  yOffset: number;
  size: number;
}

// Pre-compute particle trajectories for consistency
const particles: LarvaParticle[] = Array.from(
  { length: PARTICLE_COUNT },
  (_, i) => ({
    startFrame: 20 + i * 8,
    duration: 40 + (i % 3) * 10,
    yOffset: -60 + (i % 5) * 30,
    size: 3 + (i % 3) * 1.5,
  }),
);

export const ExternalReefsScene: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  // Title fade in
  const titleOpacity = interpolate(frame, [0, 20], [0, 1], {
    extrapolateRight: 'clamp',
    extrapolateLeft: 'clamp',
  });

  const titleTranslateY = interpolate(frame, [0, 20], [-12, 0], {
    extrapolateRight: 'clamp',
    extrapolateLeft: 'clamp',
    easing: Easing.inOut(Easing.quad),
  });

  // Text annotation fades in around frame 50
  const annotationOpacity = interpolate(frame, [50, 70], [0, 1], {
    extrapolateRight: 'clamp',
    extrapolateLeft: 'clamp',
  });

  // Wild Recruitment node appears at frame 80
  const recruitmentScale = spring({
    frame,
    fps,
    from: 0,
    to: 1,
    delay: 80,
    config: { damping: 12, stiffness: 80 },
  });

  const recruitmentOpacity = interpolate(frame, [80, 95], [0, 1], {
    extrapolateRight: 'clamp',
    extrapolateLeft: 'clamp',
  });

  // Positions
  const reefX = 550;
  const reefY = 450;
  const recruitX = 1300;
  const recruitY = 650;

  return (
    <AbsoluteFill
      style={{
        background: `radial-gradient(ellipse at 30% 50%, ${COLORS.bgLight} 0%, ${COLORS.bg} 70%)`,
      }}
    >
      {/* Title */}
      <div
        style={{
          position: 'absolute',
          top: 80,
          left: 0,
          right: 0,
          textAlign: 'center',
          opacity: titleOpacity,
          transform: `translateY(${titleTranslateY}px)`,
          fontFamily: FONTS.display,
          fontSize: 48,
          fontWeight: 700,
          color: COLORS.text,
          zIndex: 2,
        }}
      >
        Wild Larvae Supply
      </div>

      {/* External Reefs compartment box */}
      <CompartmentBox
        label="External Reefs"
        subtitle="Wild reef populations"
        color={COLORS.external}
        x={reefX}
        y={reefY}
        width={280}
        height={120}
        delay={5}
        showGlow
      />

      {/* Animated larvae particles emanating from reef node toward the right */}
      <svg
        style={{
          position: 'absolute',
          top: 0,
          left: 0,
          width: 1920,
          height: 1080,
          pointerEvents: 'none',
          zIndex: 1,
        }}
      >
        {particles.map((p, i) => {
          // Each particle loops through its trajectory
          const elapsed = frame - p.startFrame;
          if (elapsed < 0) return null;

          const loopFrame = elapsed % (p.duration + 20);
          const progress = interpolate(loopFrame, [0, p.duration], [0, 1], {
            extrapolateRight: 'clamp',
            extrapolateLeft: 'clamp',
          });

          // Particle travels from reef box right edge toward the right side
          const startX = reefX + 150;
          const endX = reefX + 550;
          const px = interpolate(progress, [0, 1], [startX, endX], {
            extrapolateRight: 'clamp',
            extrapolateLeft: 'clamp',
          });

          // Gentle sinusoidal vertical drift
          const py =
            reefY +
            p.yOffset +
            Math.sin(progress * Math.PI * 2 + i) * 15;

          const particleOpacity = interpolate(
            progress,
            [0, 0.15, 0.7, 1],
            [0, 0.8, 0.7, 0],
            {
              extrapolateRight: 'clamp',
              extrapolateLeft: 'clamp',
            },
          );

          return (
            <circle
              key={i}
              cx={px}
              cy={py}
              r={p.size}
              fill={COLORS.collection}
              opacity={particleOpacity}
            />
          );
        })}
      </svg>

      {/* Text annotation */}
      <div
        style={{
          position: 'absolute',
          top: reefY - 100,
          left: reefX - 140,
          width: 400,
          textAlign: 'center',
          opacity: annotationOpacity,
          fontFamily: FONTS.body,
          fontSize: 22,
          color: COLORS.textMuted,
          zIndex: 2,
        }}
      >
        Larvae from existing reef populations
      </div>

      {/* Wild Recruitment node */}
      <div
        style={{
          position: 'absolute',
          left: recruitX - 130,
          top: recruitY - 55,
          width: 260,
          height: 110,
          opacity: recruitmentOpacity,
          transform: `scale(${recruitmentScale})`,
          background: `rgba(${hexToRgb(COLORS.external)}, 0.08)`,
          border: `2px solid rgba(${hexToRgb(COLORS.external)}, 0.5)`,
          borderRadius: 16,
          backdropFilter: 'blur(12px)',
          display: 'flex',
          flexDirection: 'column',
          justifyContent: 'center',
          alignItems: 'center',
          padding: 16,
          zIndex: 2,
        }}
      >
        <div
          style={{
            color: COLORS.external,
            fontSize: 22,
            fontWeight: 700,
            fontFamily: FONTS.display,
          }}
        >
          Wild Recruitment
        </div>
        <div
          style={{
            color: COLORS.textMuted,
            fontSize: 13,
            fontFamily: FONTS.body,
            marginTop: 4,
          }}
        >
          Settlers on reef substrate
        </div>
      </div>

      {/* Dashed FlowArrow connecting External Reefs to Wild Recruitment */}
      <FlowArrow
        fromX={reefX + 140}
        fromY={reefY + 50}
        toX={recruitX - 130}
        toY={recruitY}
        color={COLORS.external}
        label="natural settlement"
        delay={85}
        dashed
        particleCount={2}
      />
    </AbsoluteFill>
  );
};

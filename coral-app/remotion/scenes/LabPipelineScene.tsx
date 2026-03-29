import React from 'react';
import {
  AbsoluteFill,
  useCurrentFrame,
  useVideoConfig,
  interpolate,
  spring,
} from 'remotion';
import { COLORS, FONTS, hexToRgb } from '../styles';
import { CompartmentBox } from '../components/CompartmentBox';
import { FlowArrow } from '../components/FlowArrow';

const LARVAE_COUNT = 8;

interface LarvaParticle {
  offset: number;
  yJitter: number;
  size: number;
}

const larvae: LarvaParticle[] = Array.from(
  { length: LARVAE_COUNT },
  (_, i) => ({
    offset: i * 7,
    yJitter: -30 + (i % 5) * 15,
    size: 3 + (i % 3),
  }),
);

export const LabPipelineScene: React.FC = () => {
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
  });

  // --- Phase 1: Lab box appears via spring (frames 0-30) ---
  // Handled by CompartmentBox's built-in spring with delay=5

  // --- Phase 2: "Settlement" text + larvae at 1s (frame 30) ---
  const settlementOpacity = interpolate(frame, [30, 45], [0, 1], {
    extrapolateRight: 'clamp',
    extrapolateLeft: 'clamp',
  });

  // --- Phase 3: "Growing coral fragments" text at 3s (frame 90) ---
  const growingOpacity = interpolate(frame, [90, 110], [0, 1], {
    extrapolateRight: 'clamp',
    extrapolateLeft: 'clamp',
  });

  const growingTranslateY = interpolate(frame, [90, 110], [10, 0], {
    extrapolateRight: 'clamp',
    extrapolateLeft: 'clamp',
  });

  // --- Phase 4: Two paths diverge at 5s (frame 150) ---
  const pathsOpacity = interpolate(frame, [150, 170], [0, 1], {
    extrapolateRight: 'clamp',
    extrapolateLeft: 'clamp',
  });

  // 0TX label
  const otxScale = spring({
    frame,
    fps,
    from: 0.7,
    to: 1,
    delay: 155,
    config: { damping: 12, stiffness: 80 },
  });

  // 1TX label
  const oneTxScale = spring({
    frame,
    fps,
    from: 0.7,
    to: 1,
    delay: 170,
    config: { damping: 12, stiffness: 80 },
  });

  // Parameter annotations fade in at frame 200
  const paramsOpacity = interpolate(frame, [200, 225], [0, 1], {
    extrapolateRight: 'clamp',
    extrapolateLeft: 'clamp',
  });

  // Positions
  const labX = 700;
  const labY = 380;
  const outplantX = 1300;
  const outplantY = 300;
  const orchardX = 1050;
  const orchardY = 680;

  return (
    <AbsoluteFill
      style={{
        background: `radial-gradient(ellipse at 40% 40%, rgba(${hexToRgb(COLORS.lab)}, 0.04) 0%, ${COLORS.bg} 60%)`,
      }}
    >
      {/* Title */}
      <div
        style={{
          position: 'absolute',
          top: 60,
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
        The Lab
      </div>

      {/* Lab CompartmentBox - center */}
      <CompartmentBox
        label="Lab"
        subtitle="Coral propagation facility"
        color={COLORS.lab}
        x={labX}
        y={labY}
        width={300}
        height={130}
        delay={5}
        showGlow
      />

      {/* Settlement text + animated larvae arriving from left */}
      <div
        style={{
          position: 'absolute',
          top: labY - 130,
          left: labX - 180,
          width: 360,
          textAlign: 'center',
          opacity: settlementOpacity,
          fontFamily: FONTS.body,
          fontSize: 22,
          color: COLORS.collection,
          zIndex: 2,
        }}
      >
        Settlement
      </div>

      {/* Larvae particles arriving from left */}
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
        {frame >= 30 &&
          larvae.map((l, i) => {
            const elapsed = frame - 30 - l.offset;
            if (elapsed < 0) return null;

            const loopFrame = elapsed % 50;
            const progress = interpolate(loopFrame, [0, 45], [0, 1], {
              extrapolateRight: 'clamp',
              extrapolateLeft: 'clamp',
            });

            const startX = 100;
            const endX = labX - 160;
            const px = interpolate(progress, [0, 1], [startX, endX], {
              extrapolateRight: 'clamp',
              extrapolateLeft: 'clamp',
            });

            const py =
              labY + l.yJitter + Math.sin(progress * Math.PI * 1.5 + i) * 10;

            const particleOpacity = interpolate(
              progress,
              [0, 0.15, 0.75, 1],
              [0, 0.7, 0.6, 0],
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
                r={l.size}
                fill={COLORS.collection}
                opacity={particleOpacity}
              />
            );
          })}
      </svg>

      {/* "Growing coral fragments on tiles" text */}
      <div
        style={{
          position: 'absolute',
          top: labY + 90,
          left: labX - 200,
          width: 400,
          textAlign: 'center',
          opacity: growingOpacity,
          transform: `translateY(${growingTranslateY}px)`,
          fontFamily: FONTS.body,
          fontSize: 20,
          color: COLORS.textMuted,
          zIndex: 2,
        }}
      >
        Growing coral fragments on tiles
      </div>

      {/* --- Two diverging paths --- */}

      {/* 0TX path label - going right */}
      <div
        style={{
          position: 'absolute',
          left: outplantX - 130,
          top: outplantY - 50,
          width: 260,
          height: 100,
          opacity: pathsOpacity,
          transform: `scale(${otxScale})`,
          background: `rgba(${hexToRgb(COLORS.outplanting)}, 0.08)`,
          border: `2px solid rgba(${hexToRgb(COLORS.outplanting)}, 0.5)`,
          borderRadius: 16,
          backdropFilter: 'blur(12px)',
          display: 'flex',
          flexDirection: 'column',
          justifyContent: 'center',
          alignItems: 'center',
          padding: 12,
          zIndex: 2,
        }}
      >
        <div
          style={{
            fontFamily: FONTS.mono,
            fontSize: 26,
            fontWeight: 700,
            color: COLORS.outplanting,
          }}
        >
          0TX
        </div>
        <div
          style={{
            fontFamily: FONTS.body,
            fontSize: 14,
            color: COLORS.textMuted,
            marginTop: 4,
          }}
        >
          Direct outplant to reef
        </div>
      </div>

      {/* 1TX path label - going down */}
      <div
        style={{
          position: 'absolute',
          left: orchardX - 130,
          top: orchardY - 50,
          width: 260,
          height: 100,
          opacity: pathsOpacity,
          transform: `scale(${oneTxScale})`,
          background: `rgba(${hexToRgb(COLORS.orchard)}, 0.08)`,
          border: `2px solid rgba(${hexToRgb(COLORS.orchard)}, 0.5)`,
          borderRadius: 16,
          backdropFilter: 'blur(12px)',
          display: 'flex',
          flexDirection: 'column',
          justifyContent: 'center',
          alignItems: 'center',
          padding: 12,
          zIndex: 2,
        }}
      >
        <div
          style={{
            fontFamily: FONTS.mono,
            fontSize: 26,
            fontWeight: 700,
            color: COLORS.orchard,
          }}
        >
          1TX
        </div>
        <div
          style={{
            fontFamily: FONTS.body,
            fontSize: 14,
            color: COLORS.textMuted,
            marginTop: 4,
          }}
        >
          To orchard first
        </div>
      </div>

      {/* FlowArrow: Lab -> 0TX (right) */}
      <FlowArrow
        fromX={labX + 150}
        fromY={labY - 20}
        toX={outplantX - 130}
        toY={outplantY}
        color={COLORS.outplanting}
        label="0TX"
        delay={155}
        particleCount={2}
      />

      {/* FlowArrow: Lab -> 1TX (down-right) */}
      <FlowArrow
        fromX={labX + 100}
        fromY={labY + 65}
        toX={orchardX - 130}
        toY={orchardY}
        color={COLORS.orchard}
        label="1TX"
        delay={170}
        dashed
        particleCount={2}
      />

      {/* Parameter annotations in mono font */}
      <div
        style={{
          position: 'absolute',
          left: 120,
          bottom: 100,
          opacity: paramsOpacity,
          display: 'flex',
          flexDirection: 'column',
          gap: 12,
          zIndex: 2,
        }}
      >
        <div
          style={{
            fontFamily: FONTS.mono,
            fontSize: 16,
            color: COLORS.lab,
            background: `rgba(${hexToRgb(COLORS.lab)}, 0.08)`,
            border: `1px solid rgba(${hexToRgb(COLORS.lab)}, 0.25)`,
            borderRadius: 8,
            padding: '6px 16px',
          }}
        >
          lab_capacity
        </div>
        <div
          style={{
            fontFamily: FONTS.mono,
            fontSize: 16,
            color: COLORS.lab,
            background: `rgba(${hexToRgb(COLORS.lab)}, 0.08)`,
            border: `1px solid rgba(${hexToRgb(COLORS.lab)}, 0.25)`,
            borderRadius: 8,
            padding: '6px 16px',
          }}
        >
          settlement_rate
        </div>
      </div>

      {/* "Key Parameters" label above the parameter annotations */}
      <div
        style={{
          position: 'absolute',
          left: 120,
          bottom: 200,
          opacity: paramsOpacity,
          fontFamily: FONTS.body,
          fontSize: 14,
          color: COLORS.textDim,
          letterSpacing: 1.5,
          textTransform: 'uppercase',
          zIndex: 2,
        }}
      >
        Key Parameters
      </div>
    </AbsoluteFill>
  );
};

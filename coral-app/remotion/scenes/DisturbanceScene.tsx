import React from 'react';
import {
  AbsoluteFill,
  Easing,
  useCurrentFrame,
  useVideoConfig,
  interpolate,
  spring,
} from 'remotion';
import { COLORS, FONTS, hexToRgb, seededNoise } from '../styles';
import { ChartFrame } from '../components/ChartFrame';

/**
 * Generate the pre-hurricane trajectory (years 0-30, trending up to ~60%).
 * We only show first ~30 points but generate more for the recovery portion.
 */
function generatePreHurricaneTrajectory(numPoints: number): number[] {
  const points: number[] = [];
  let value = 8;
  for (let i = 0; i < numPoints; i++) {
    const drift = 1.8;
    const noise = seededNoise(i * 7 + 3) * 1.5;
    value += drift + noise;
    value = Math.max(2, Math.min(95, value));
    points.push(value);
  }
  return points;
}

/**
 * Generate recovery trajectory from the drop point.
 */
function generateRecoveryTrajectory(startVal: number, numPoints: number): number[] {
  const points: number[] = [];
  let value = startVal;
  for (let i = 0; i < numPoints; i++) {
    const drift = 0.8;
    const noise = seededNoise(i * 13 + 200) * 1.2;
    value += drift + noise;
    value = Math.max(2, Math.min(95, value));
    points.push(value);
  }
  return points;
}

// Pre-generate trajectories
const preHurricane = generatePreHurricaneTrajectory(30);
const hurricaneYear = 30;
const dropTo = 15;
const recovery = generateRecoveryTrajectory(dropTo, 20);

export const DisturbanceScene: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  // Chart area
  const chartLeft = 360;
  const chartTop = 180;
  const chartWidth = 1200;
  const chartHeight = 500;
  const chartBottom = chartTop + chartHeight;
  const totalYears = 50;

  const xScale = (year: number) => chartLeft + (year / totalYears) * chartWidth;
  const yScale = (cover: number) => chartBottom - (cover / 100) * chartHeight;

  // Title
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

  // Axes fade in
  const axisOpacity = interpolate(frame, [0, 20], [0, 1], {
    extrapolateRight: 'clamp',
    extrapolateLeft: 'clamp',
  });

  // Phase 1: Pre-hurricane line draws over frames 10-90 (0-3s)
  const preLineProgress = interpolate(frame, [10, 90], [0, 1], {
    extrapolateRight: 'clamp',
    extrapolateLeft: 'clamp',
  });

  // Phase 2: Hurricane flash at 3s (frame 90)
  const flashOpacity = interpolate(
    frame,
    [88, 93, 100, 110],
    [0, 0.4, 0.25, 0],
    {
      extrapolateRight: 'clamp',
      extrapolateLeft: 'clamp',
    },
  );

  // "HURRICANE" text appears at 3s
  const hurricaneTextOpacity = interpolate(
    frame,
    [90, 95, 120, 135],
    [0, 1, 1, 0],
    {
      extrapolateRight: 'clamp',
      extrapolateLeft: 'clamp',
    },
  );

  const hurricaneTextScale = spring({
    frame,
    fps,
    from: 1.5,
    to: 1,
    delay: 90,
    config: { damping: 8, stiffness: 120 },
  });

  // Phase 3: Drop line at 3.5s (frame 105)
  const dropProgress = interpolate(frame, [105, 115], [0, 1], {
    extrapolateRight: 'clamp',
    extrapolateLeft: 'clamp',
  });

  // Phase 4: Annotations at 4s (frame 120)
  const annotationOpacity = interpolate(frame, [120, 140], [0, 1], {
    extrapolateRight: 'clamp',
    extrapolateLeft: 'clamp',
  });

  // Phase 5: Recovery line from 5s (frame 150)
  const recoveryProgress = interpolate(frame, [150, 210], [0, 1], {
    extrapolateRight: 'clamp',
    extrapolateLeft: 'clamp',
  });

  // Phase 6: Bottom text at 6s (frame 180)
  const bottomTextOpacity = interpolate(frame, [180, 200], [0, 1], {
    extrapolateRight: 'clamp',
    extrapolateLeft: 'clamp',
  });

  const bottomTextTranslateY = interpolate(frame, [180, 200], [16, 0], {
    extrapolateRight: 'clamp',
    extrapolateLeft: 'clamp',
    easing: Easing.inOut(Easing.quad),
  });

  // Red ambient pulse during hurricane
  const redAmbient = interpolate(
    frame,
    [85, 95, 110, 130],
    [0, 0.12, 0.08, 0],
    {
      extrapolateRight: 'clamp',
      extrapolateLeft: 'clamp',
    },
  );

  // Build pre-hurricane path
  const buildPrePath = (): string => {
    const visiblePoints = Math.max(2, Math.floor(preLineProgress * preHurricane.length));
    const parts = preHurricane.slice(0, visiblePoints).map((val, i) => {
      const x = xScale(i);
      const y = yScale(val);
      return i === 0 ? `M ${x} ${y}` : `L ${x} ${y}`;
    });
    return parts.join(' ');
  };

  // Build drop line segment
  const preEndVal = preHurricane[preHurricane.length - 1];
  const dropStartX = xScale(hurricaneYear);
  const dropStartY = yScale(preEndVal);
  const dropEndY = yScale(dropTo);
  const currentDropY = dropStartY + (dropEndY - dropStartY) * dropProgress;

  // Build recovery path
  const buildRecoveryPath = (): string => {
    const visiblePoints = Math.max(1, Math.floor(recoveryProgress * recovery.length));
    const parts: string[] = [];
    for (let i = 0; i < visiblePoints; i++) {
      const x = xScale(hurricaneYear + 1 + i);
      const y = yScale(recovery[i]);
      if (i === 0) {
        parts.push(`M ${xScale(hurricaneYear)} ${yScale(dropTo)} L ${x} ${y}`);
      } else {
        parts.push(`L ${x} ${y}`);
      }
    }
    return parts.join(' ');
  };

  // Y-axis ticks
  const yTicks = [0, 20, 40, 60, 80, 100];
  const xTicks = [0, 10, 20, 30, 40, 50];

  return (
    <AbsoluteFill
      style={{
        background: `radial-gradient(ellipse at 50% 50%, ${COLORS.bgLight} 0%, ${COLORS.bg} 70%)`,
      }}
    >
      {/* Red flash overlay */}
      <div
        style={{
          position: 'absolute',
          inset: 0,
          background: `rgba(${hexToRgb('#F87171')}, ${flashOpacity})`,
          pointerEvents: 'none',
          zIndex: 10,
        }}
      />

      {/* Red ambient overlay */}
      <div
        style={{
          position: 'absolute',
          inset: 0,
          background: `radial-gradient(ellipse at 50% 50%, rgba(${hexToRgb('#F87171')}, ${redAmbient}) 0%, transparent 70%)`,
          pointerEvents: 'none',
        }}
      />

      {/* Title */}
      <div
        style={{
          position: 'absolute',
          top: 40,
          width: '100%',
          textAlign: 'center',
          opacity: titleOpacity,
          transform: `scale(${titleScale})`,
          fontFamily: FONTS.display,
          fontSize: 52,
          fontWeight: 700,
          color: COLORS.text,
          zIndex: 2,
        }}
      >
        Hurricane Disturbance
      </div>

      {/* HURRICANE flash text */}
      <div
        style={{
          position: 'absolute',
          top: '50%',
          left: '50%',
          transform: `translate(-50%, -50%) scale(${hurricaneTextScale})`,
          opacity: hurricaneTextOpacity,
          fontFamily: FONTS.display,
          fontSize: 96,
          fontWeight: 700,
          color: '#F87171',
          textShadow: `0 0 40px rgba(${hexToRgb('#F87171')}, 0.6), 0 0 80px rgba(${hexToRgb('#F87171')}, 0.3)`,
          zIndex: 15,
          letterSpacing: 8,
        }}
      >
        HURRICANE
      </div>

      {/* Chart SVG */}
      <svg
        style={{
          position: 'absolute',
          top: 0,
          left: 0,
          width: 1920,
          height: 1080,
          pointerEvents: 'none',
        }}
      >
        {/* Axes */}
        <ChartFrame
          chartLeft={chartLeft}
          chartTop={chartTop}
          chartWidth={chartWidth}
          chartHeight={chartHeight}
          xLabel="Years"
          yLabel="Coral Cover (%)"
          xTicks={xTicks}
          yTicks={yTicks}
          opacity={axisOpacity}
          xMax={totalYears}
        />

        {/* Pre-hurricane trajectory */}
        <path
          d={buildPrePath()}
          fill="none"
          stroke={COLORS.reef}
          strokeWidth={6}
          strokeOpacity={0.15}
          strokeLinecap="round"
          strokeLinejoin="round"
        />
        <path
          d={buildPrePath()}
          fill="none"
          stroke={COLORS.reef}
          strokeWidth={2.5}
          strokeLinecap="round"
          strokeLinejoin="round"
        />

        {/* Drop line */}
        {dropProgress > 0 && (
          <>
            <line
              x1={dropStartX}
              y1={dropStartY}
              x2={dropStartX}
              y2={currentDropY}
              stroke="#F87171"
              strokeWidth={6}
              strokeOpacity={0.2}
              strokeLinecap="round"
            />
            <line
              x1={dropStartX}
              y1={dropStartY}
              x2={dropStartX}
              y2={currentDropY}
              stroke="#F87171"
              strokeWidth={3}
              strokeLinecap="round"
            />
          </>
        )}

        {/* Recovery trajectory */}
        {recoveryProgress > 0 && (
          <>
            <path
              d={buildRecoveryPath()}
              fill="none"
              stroke={COLORS.orchard}
              strokeWidth={6}
              strokeOpacity={0.15}
              strokeLinecap="round"
              strokeLinejoin="round"
            />
            <path
              d={buildRecoveryPath()}
              fill="none"
              stroke={COLORS.orchard}
              strokeWidth={2.5}
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeDasharray="6 4"
            />
          </>
        )}

        {/* Annotations: Category 4, 85% mortality */}
        <g opacity={annotationOpacity}>
          {/* Category 4 label */}
          <foreignObject
            x={xScale(hurricaneYear) + 20}
            y={yScale(preEndVal) - 50}
            width={180}
            height={40}
          >
            <div
              style={{
                background: 'rgba(248, 113, 113, 0.15)',
                border: '1px solid rgba(248, 113, 113, 0.5)',
                borderRadius: 8,
                padding: '6px 14px',
                fontFamily: FONTS.mono,
                fontSize: 16,
                fontWeight: 700,
                color: '#F87171',
                textAlign: 'center',
              }}
            >
              Category 4
            </div>
          </foreignObject>
          {/* 85% mortality label */}
          <foreignObject
            x={xScale(hurricaneYear) + 20}
            y={yScale(dropTo) - 10}
            width={180}
            height={40}
          >
            <div
              style={{
                background: 'rgba(248, 113, 113, 0.15)',
                border: '1px solid rgba(248, 113, 113, 0.5)',
                borderRadius: 8,
                padding: '6px 14px',
                fontFamily: FONTS.mono,
                fontSize: 16,
                fontWeight: 700,
                color: '#F87171',
                textAlign: 'center',
              }}
            >
              85% mortality
            </div>
          </foreignObject>
        </g>
      </svg>

      {/* Bottom text */}
      <div
        style={{
          position: 'absolute',
          bottom: 70,
          width: '100%',
          textAlign: 'center',
          opacity: bottomTextOpacity,
          transform: `translateY(${bottomTextTranslateY}px)`,
          fontFamily: FONTS.body,
          fontSize: 26,
          color: COLORS.textMuted,
          zIndex: 2,
        }}
      >
        Recovery depends on restoration strategy
      </div>
    </AbsoluteFill>
  );
};

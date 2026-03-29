import React from 'react';
import {
  AbsoluteFill,
  Easing,
  useCurrentFrame,
  useVideoConfig,
  interpolate,
  spring,
} from 'remotion';
import { COLORS, FONTS, hexToRgb, seededRandom } from '../styles';
import { ChartFrame } from '../components/ChartFrame';

/**
 * Generate a deterministic trajectory for a given line index.
 * Generally trends upward with random-walk variation.
 */
function generateTrajectory(lineIndex: number, numPoints: number): number[] {
  const points: number[] = [];
  let value = 5 + lineIndex * 3; // starting value varies by line
  for (let i = 0; i < numPoints; i++) {
    const noise = seededRandom(lineIndex * 1000 + i) * 2 - 1; // [-1, 1]
    const drift = 0.6 + lineIndex * 0.08; // upward trend
    const volatility = 3.5 + seededRandom(lineIndex * 500 + i) * 2;
    value += drift + noise * volatility;
    // Clamp to [2, 95]
    value = Math.max(2, Math.min(95, value));
    points.push(value);
  }
  return points;
}

const NUM_POINTS = 50;
const LINE_COLORS = ['#38BDF8', '#67E8F9', '#2DD4BF', '#7DD3FC', '#22D3EE'];

// Pre-generate all trajectories (deterministic)
const trajectories = LINE_COLORS.map((_, i) => generateTrajectory(i, NUM_POINTS));

export const StochasticityScene: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  // Chart area dimensions
  const chartLeft = 360;
  const chartTop = 180;
  const chartWidth = 1200;
  const chartHeight = 500;
  const chartRight = chartLeft + chartWidth;
  const chartBottom = chartTop + chartHeight;

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

  // Lines animate over first 4s (0-120 frames)
  const lineDrawProgress = interpolate(frame, [10, 120], [0, 1], {
    extrapolateRight: 'clamp',
    extrapolateLeft: 'clamp',
  });

  // Confidence interval fades in at 4s (frame 120)
  const bandOpacity = interpolate(frame, [120, 150], [0, 0.25], {
    extrapolateRight: 'clamp',
    extrapolateLeft: 'clamp',
  });

  // Bottom text at 5s (frame 150)
  const bottomTextOpacity = interpolate(frame, [150, 170], [0, 1], {
    extrapolateRight: 'clamp',
    extrapolateLeft: 'clamp',
  });

  const bottomTextTranslateY = interpolate(frame, [150, 170], [16, 0], {
    extrapolateRight: 'clamp',
    extrapolateLeft: 'clamp',
    easing: Easing.inOut(Easing.quad),
  });

  // Ambient purple overlay
  const ambientOpacity = interpolate(frame, [0, 30], [0, 0.06], {
    extrapolateRight: 'clamp',
    extrapolateLeft: 'clamp',
  });

  // Axis fade in
  const axisOpacity = interpolate(frame, [0, 20], [0, 1], {
    extrapolateRight: 'clamp',
    extrapolateLeft: 'clamp',
  });

  // Convert data coordinates to SVG coordinates
  const xScale = (year: number) => chartLeft + (year / NUM_POINTS) * chartWidth;
  const yScale = (cover: number) =>
    chartBottom - (cover / 100) * chartHeight;

  // Build SVG path for a trajectory up to current progress
  const buildPath = (trajectory: number[]): string => {
    const visiblePoints = Math.floor(lineDrawProgress * trajectory.length);
    if (visiblePoints < 2) return '';
    const parts = trajectory.slice(0, visiblePoints).map((val, i) => {
      const x = xScale(i);
      const y = yScale(val);
      return i === 0 ? `M ${x} ${y}` : `L ${x} ${y}`;
    });
    return parts.join(' ');
  };

  // Compute confidence band (min/max across all trajectories at each point)
  const buildBandPath = (): string => {
    const upperPoints: string[] = [];
    const lowerPoints: string[] = [];
    for (let i = 0; i < NUM_POINTS; i++) {
      const values = trajectories.map((t) => t[i]);
      const minVal = Math.min(...values);
      const maxVal = Math.max(...values);
      const x = xScale(i);
      upperPoints.push(`${x},${yScale(maxVal)}`);
      lowerPoints.unshift(`${x},${yScale(minVal)}`);
    }
    return `M ${upperPoints.join(' L ')} L ${lowerPoints.join(' L ')} Z`;
  };

  // Y-axis tick values
  const yTicks = [0, 20, 40, 60, 80, 100];
  // X-axis tick values
  const xTicks = [0, 10, 20, 30, 40, 50];

  return (
    <AbsoluteFill
      style={{
        background: `radial-gradient(ellipse at 50% 50%, ${COLORS.bgLight} 0%, ${COLORS.bg} 70%)`,
      }}
    >
      {/* Purple ambient overlay */}
      <div
        style={{
          position: 'absolute',
          inset: 0,
          background: `radial-gradient(ellipse at 50% 50%, rgba(${hexToRgb('#C084FC')}, ${ambientOpacity}) 0%, transparent 70%)`,
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
        Environmental Stochasticity
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
          xMax={NUM_POINTS}
        />

        {/* Confidence interval band */}
        <path
          d={buildBandPath()}
          fill={`rgba(${hexToRgb('#C084FC')}, ${bandOpacity})`}
        />

        {/* Trajectory lines */}
        {trajectories.map((trajectory, i) => {
          const pathD = buildPath(trajectory);
          if (!pathD) return null;
          return (
            <g key={i}>
              {/* Glow */}
              <path
                d={pathD}
                fill="none"
                stroke={LINE_COLORS[i]}
                strokeWidth={6}
                strokeOpacity={0.15}
                strokeLinecap="round"
                strokeLinejoin="round"
              />
              {/* Main line */}
              <path
                d={pathD}
                fill="none"
                stroke={LINE_COLORS[i]}
                strokeWidth={2.5}
                strokeOpacity={0.85}
                strokeLinecap="round"
                strokeLinejoin="round"
              />
            </g>
          );
        })}
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
        Each simulation run produces a different trajectory
      </div>
    </AbsoluteFill>
  );
};

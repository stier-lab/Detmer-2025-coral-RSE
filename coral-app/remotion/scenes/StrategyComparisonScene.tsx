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
 * Low reef_prop trajectory: slower start, higher eventual cover.
 * Orchard investment pays off long-term.
 */
function generateLowReefProp(numYears: number): number[] {
  const points: number[] = [];
  let value = 5;
  for (let i = 0; i < numYears; i++) {
    // Slow early growth, accelerating after year 15
    const drift = i < 15 ? 0.8 : 2.2;
    const noise = seededNoise(i * 7 + 100) * 1.0;
    value += drift + noise;
    value = Math.max(2, Math.min(95, value));
    points.push(value);
  }
  return points;
}

/**
 * High reef_prop trajectory: faster initial boost, lower long-term cover.
 */
function generateHighReefProp(numYears: number): number[] {
  const points: number[] = [];
  let value = 5;
  for (let i = 0; i < numYears; i++) {
    // Fast early growth that tapers off and plateaus
    const drift = i < 10 ? 2.5 : i < 20 ? 0.8 : 0.3;
    const noise = seededNoise(i * 11 + 200) * 1.0;
    value += drift + noise;
    value = Math.max(2, Math.min(85, value));
    points.push(value);
  }
  return points;
}

const NUM_YEARS = 40;
const lowReefData = generateLowReefProp(NUM_YEARS);
const highReefData = generateHighReefProp(NUM_YEARS);

export const StrategyComparisonScene: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  // Mini chart dimensions (each side)
  const leftChartLeft = 80;
  const rightChartLeft = 990;
  const chartTop = 220;
  const chartWidth = 780;
  const chartHeight = 420;
  const chartBottom = chartTop + chartHeight;

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

  // Side labels fade in at 0.5s
  const labelOpacity = interpolate(frame, [15, 30], [0, 1], {
    extrapolateRight: 'clamp',
    extrapolateLeft: 'clamp',
  });

  // Axes fade in
  const axisOpacity = interpolate(frame, [10, 25], [0, 1], {
    extrapolateRight: 'clamp',
    extrapolateLeft: 'clamp',
  });

  // Both trajectories animate from 1s (frame 30) to 5s (frame 150)
  const lineProgress = interpolate(frame, [30, 150], [0, 1], {
    extrapolateRight: 'clamp',
    extrapolateLeft: 'clamp',
  });

  // Crossover line at 5s (frame 150)
  const crossoverOpacity = interpolate(frame, [150, 170], [0, 1], {
    extrapolateRight: 'clamp',
    extrapolateLeft: 'clamp',
  });

  // Bottom text at 7s (frame 210)
  const bottomTextOpacity = interpolate(frame, [210, 230], [0, 1], {
    extrapolateRight: 'clamp',
    extrapolateLeft: 'clamp',
  });

  const bottomTextTranslateY = interpolate(frame, [210, 230], [16, 0], {
    extrapolateRight: 'clamp',
    extrapolateLeft: 'clamp',
    easing: Easing.inOut(Easing.quad),
  });

  // Golden highlight at 8s (frame 240)
  const highlightOpacity = interpolate(frame, [240, 260], [0, 1], {
    extrapolateRight: 'clamp',
    extrapolateLeft: 'clamp',
  });

  // Divider line between panels
  const dividerOpacity = interpolate(frame, [5, 20], [0, 0.2], {
    extrapolateRight: 'clamp',
    extrapolateLeft: 'clamp',
  });

  // Scale helpers for each mini chart
  const xScaleLeft = (year: number) =>
    leftChartLeft + (year / NUM_YEARS) * chartWidth;
  const xScaleRight = (year: number) =>
    rightChartLeft + (year / NUM_YEARS) * chartWidth;
  const yScale = (cover: number) =>
    chartBottom - (cover / 100) * chartHeight;

  // Build path for a trajectory
  const buildPath = (
    data: number[],
    xScaleFn: (y: number) => number,
  ): string => {
    const visiblePoints = Math.max(2, Math.floor(lineProgress * data.length));
    const parts = data.slice(0, visiblePoints).map((val, i) => {
      const x = xScaleFn(i);
      const y = yScale(val);
      return i === 0 ? `M ${x} ${y}` : `L ${x} ${y}`;
    });
    return parts.join(' ');
  };

  const yTicks = [0, 25, 50, 75, 100];
  const xTicks = [0, 10, 20, 30, 40];
  const crossoverYear = 20;


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
        Comparing Strategies
      </div>

      {/* Side labels */}
      <div
        style={{
          position: 'absolute',
          top: 140,
          left: leftChartLeft,
          width: chartWidth,
          textAlign: 'center',
          opacity: labelOpacity,
          zIndex: 2,
        }}
      >
        <span
          style={{
            fontFamily: FONTS.mono,
            fontSize: 20,
            fontWeight: 700,
            color: COLORS.orchard,
          }}
        >
          Low reef_prop (0.2)
        </span>
        <span
          style={{
            fontFamily: FONTS.body,
            fontSize: 16,
            color: COLORS.textDim,
            marginLeft: 12,
          }}
        >
          More coral through orchard
        </span>
      </div>
      <div
        style={{
          position: 'absolute',
          top: 140,
          left: rightChartLeft,
          width: chartWidth,
          textAlign: 'center',
          opacity: labelOpacity,
          zIndex: 2,
        }}
      >
        <span
          style={{
            fontFamily: FONTS.mono,
            fontSize: 20,
            fontWeight: 700,
            color: COLORS.reef,
          }}
        >
          High reef_prop (0.8)
        </span>
        <span
          style={{
            fontFamily: FONTS.body,
            fontSize: 16,
            color: COLORS.textDim,
            marginLeft: 12,
          }}
        >
          More coral directly to reef
        </span>
      </div>

      {/* Golden highlight border around left chart */}
      <div
        style={{
          position: 'absolute',
          left: leftChartLeft - 16,
          top: chartTop - 16,
          width: chartWidth + 32,
          height: chartHeight + 32,
          border: `3px solid rgba(${hexToRgb(COLORS.lab)}, ${highlightOpacity * 0.7})`,
          borderRadius: 16,
          boxShadow: `0 0 30px rgba(${hexToRgb(COLORS.lab)}, ${highlightOpacity * 0.2})`,
          pointerEvents: 'none',
          zIndex: 3,
        }}
      />

      {/* Center divider */}
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
        <line
          x1={960}
          y1={chartTop - 30}
          x2={960}
          y2={chartBottom + 60}
          stroke={`rgba(255,255,255,${dividerOpacity})`}
          strokeWidth={1}
          strokeDasharray="6 6"
        />
      </svg>

      {/* Charts SVG */}
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
        {/* Left chart axes */}
        <ChartFrame
          chartLeft={leftChartLeft}
          chartTop={chartTop}
          chartWidth={chartWidth}
          chartHeight={chartHeight}
          xLabel="Years"
          yLabel="Coral Cover (%)"
          xTicks={xTicks}
          yTicks={yTicks}
          opacity={axisOpacity}
          xMax={NUM_YEARS}
        />

        {/* Right chart axes */}
        <ChartFrame
          chartLeft={rightChartLeft}
          chartTop={chartTop}
          chartWidth={chartWidth}
          chartHeight={chartHeight}
          xLabel="Years"
          yLabel="Coral Cover (%)"
          xTicks={xTicks}
          yTicks={yTicks}
          opacity={axisOpacity}
          xMax={NUM_YEARS}
          showYLabels={false}
        />

        {/* Left trajectory (orchard - low reef_prop) */}
        <path
          d={buildPath(lowReefData, xScaleLeft)}
          fill="none"
          stroke={COLORS.orchard}
          strokeWidth={6}
          strokeOpacity={0.15}
          strokeLinecap="round"
          strokeLinejoin="round"
        />
        <path
          d={buildPath(lowReefData, xScaleLeft)}
          fill="none"
          stroke={COLORS.orchard}
          strokeWidth={2.5}
          strokeLinecap="round"
          strokeLinejoin="round"
        />

        {/* Right trajectory (reef - high reef_prop) */}
        <path
          d={buildPath(highReefData, xScaleRight)}
          fill="none"
          stroke={COLORS.reef}
          strokeWidth={6}
          strokeOpacity={0.15}
          strokeLinecap="round"
          strokeLinejoin="round"
        />
        <path
          d={buildPath(highReefData, xScaleRight)}
          fill="none"
          stroke={COLORS.reef}
          strokeWidth={2.5}
          strokeLinecap="round"
          strokeLinejoin="round"
        />

        {/* Crossover line on left chart */}
        <g opacity={crossoverOpacity}>
          <line
            x1={xScaleLeft(crossoverYear)}
            y1={chartTop}
            x2={xScaleLeft(crossoverYear)}
            y2={chartBottom}
            stroke={COLORS.textMuted}
            strokeWidth={1.5}
            strokeDasharray="8 5"
          />
          <foreignObject
            x={xScaleLeft(crossoverYear) - 60}
            y={chartTop - 30}
            width={120}
            height={28}
          >
            <div
              style={{
                textAlign: 'center',
                fontFamily: FONTS.mono,
                fontSize: 13,
                color: COLORS.textMuted,
                background: `rgba(${hexToRgb(COLORS.bg)}, 0.85)`,
                borderRadius: 4,
                padding: '2px 8px',
              }}
            >
              Year 20
            </div>
          </foreignObject>
        </g>

        {/* Crossover line on right chart */}
        <g opacity={crossoverOpacity}>
          <line
            x1={xScaleRight(crossoverYear)}
            y1={chartTop}
            x2={xScaleRight(crossoverYear)}
            y2={chartBottom}
            stroke={COLORS.textMuted}
            strokeWidth={1.5}
            strokeDasharray="8 5"
          />
          <foreignObject
            x={xScaleRight(crossoverYear) - 70}
            y={chartTop - 30}
            width={140}
            height={28}
          >
            <div
              style={{
                textAlign: 'center',
                fontFamily: FONTS.mono,
                fontSize: 13,
                color: COLORS.textMuted,
                background: `rgba(${hexToRgb(COLORS.bg)}, 0.85)`,
                borderRadius: 4,
                padding: '2px 8px',
              }}
            >
              Crossover point
            </div>
          </foreignObject>
        </g>
      </svg>

      {/* Bottom text */}
      <div
        style={{
          position: 'absolute',
          bottom: 60,
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
        Orchard investment pays off in the long run
      </div>
    </AbsoluteFill>
  );
};

import React from 'react';
import { COLORS, FONTS } from '../styles';

interface ChartFrameProps {
  chartLeft: number;
  chartTop: number;
  chartWidth: number;
  chartHeight: number;
  xLabel: string;
  yLabel: string;
  xTicks: number[];
  yTicks: number[];
  opacity: number;
  xMax?: number;
  yMax?: number;
  showYLabels?: boolean;
}

/**
 * Shared SVG chart axes, grid lines, and labels used across
 * Stochasticity, Disturbance, and StrategyComparison scenes.
 */
export const ChartFrame: React.FC<ChartFrameProps> = ({
  chartLeft,
  chartTop,
  chartWidth,
  chartHeight,
  xLabel,
  yLabel,
  xTicks,
  yTicks,
  opacity,
  xMax,
  yMax = 100,
  showYLabels = true,
}) => {
  const chartRight = chartLeft + chartWidth;
  const chartBottom = chartTop + chartHeight;
  const effectiveXMax = xMax ?? xTicks[xTicks.length - 1];

  const xScale = (val: number) => chartLeft + (val / effectiveXMax) * chartWidth;
  const yScale = (val: number) => chartBottom - (val / yMax) * chartHeight;

  return (
    <g opacity={opacity}>
      {/* Y axis */}
      <line
        x1={chartLeft}
        y1={chartTop}
        x2={chartLeft}
        y2={chartBottom}
        stroke="rgba(255,255,255,0.3)"
        strokeWidth={1.5}
      />
      {/* X axis */}
      <line
        x1={chartLeft}
        y1={chartBottom}
        x2={chartRight}
        y2={chartBottom}
        stroke="rgba(255,255,255,0.3)"
        strokeWidth={1.5}
      />
      {/* Y ticks, grid, and labels */}
      {yTicks.map((tick) => (
        <g key={`ytick-${tick}-${chartLeft}`}>
          <line
            x1={chartLeft - 6}
            y1={yScale(tick)}
            x2={chartLeft}
            y2={yScale(tick)}
            stroke="rgba(255,255,255,0.3)"
            strokeWidth={1}
          />
          <line
            x1={chartLeft}
            y1={yScale(tick)}
            x2={chartRight}
            y2={yScale(tick)}
            stroke="rgba(255,255,255,0.06)"
            strokeWidth={1}
          />
          {showYLabels && (
            <text
              x={chartLeft - 14}
              y={yScale(tick) + 5}
              fill={COLORS.textDim}
              fontSize={14}
              fontFamily={FONTS.mono}
              textAnchor="end"
            >
              {tick}
            </text>
          )}
        </g>
      ))}
      {/* X ticks and labels */}
      {xTicks.map((tick) => (
        <g key={`xtick-${tick}-${chartLeft}`}>
          <line
            x1={xScale(tick)}
            y1={chartBottom}
            x2={xScale(tick)}
            y2={chartBottom + 6}
            stroke="rgba(255,255,255,0.3)"
            strokeWidth={1}
          />
          <text
            x={xScale(tick)}
            y={chartBottom + 24}
            fill={COLORS.textDim}
            fontSize={14}
            fontFamily={FONTS.mono}
            textAnchor="middle"
          >
            {tick}
          </text>
        </g>
      ))}
      {/* Axis labels */}
      <text
        x={(chartLeft + chartRight) / 2}
        y={chartBottom + 50}
        fill={COLORS.textMuted}
        fontSize={18}
        fontFamily={FONTS.body}
        textAnchor="middle"
      >
        {xLabel}
      </text>
      {showYLabels && (
        <text
          x={chartLeft - 60}
          y={(chartTop + chartBottom) / 2}
          fill={COLORS.textMuted}
          fontSize={18}
          fontFamily={FONTS.body}
          textAnchor="middle"
          transform={`rotate(-90, ${chartLeft - 60}, ${(chartTop + chartBottom) / 2})`}
        >
          {yLabel}
        </text>
      )}
    </g>
  );
};

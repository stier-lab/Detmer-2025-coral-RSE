import React from 'react';
import {
  AbsoluteFill,
  useCurrentFrame,
  useVideoConfig,
  interpolate,
  spring,
  Easing,
} from 'remotion';
import { COLORS, FONTS, SIZE_CLASSES, hexToRgb } from '../styles';
import { CompartmentBox } from '../components/CompartmentBox';
import { FlowArrow } from '../components/FlowArrow';

export const OrchardGrowthScene: React.FC = () => {
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

  // Size class bars: proportional max heights
  const maxBarHeights = [40, 60, 100, 140, 180];
  const barWidth = 50;
  const barGap = 16;
  const totalBarsWidth =
    SIZE_CLASSES.length * barWidth + (SIZE_CLASSES.length - 1) * barGap;
  const barsStartX = 960 - totalBarsWidth / 2;
  // Bars are drawn inside the orchard box area, bottom-aligned
  const barsBottomY = 400 + 130; // below center, leaves room for label at top

  // Text "Corals grow through size classes..." at 5s = frame 150
  const growTextOpacity = interpolate(frame, [150, 170], [0, 1], {
    extrapolateRight: 'clamp',
    extrapolateLeft: 'clamp',
  });

  const growTextTranslateY = interpolate(frame, [150, 170], [12, 0], {
    extrapolateRight: 'clamp',
    extrapolateLeft: 'clamp',
    easing: Easing.inOut(Easing.quad),
  });

  // Fecundity values appear at 7s = frame 210
  const fecundityOpacity = interpolate(frame, [210, 230], [0, 1], {
    extrapolateRight: 'clamp',
    extrapolateLeft: 'clamp',
  });

  // Transplanting arrow exits left side at ~4s
  const arrowDelay = 120;

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
        The Orchard
      </div>

      {/* Orchard CompartmentBox */}
      <CompartmentBox
        label="Orchard"
        subtitle="Grow-out facility"
        color={COLORS.orchard}
        x={960}
        y={400}
        width={400}
        height={300}
        delay={5}
      />

      {/* Size class bars growing sequentially inside the box */}
      {SIZE_CLASSES.map((sc, i) => {
        // Each bar starts growing 20 frames apart, beginning at frame 30
        const barDelay = 30 + i * 20;
        const barHeight = spring({
          frame,
          fps,
          from: 0,
          to: maxBarHeights[i],
          delay: barDelay,
          config: { damping: 14, stiffness: 60 },
        });

        const barOpacity = interpolate(frame - barDelay, [0, 10], [0, 1], {
          extrapolateRight: 'clamp',
          extrapolateLeft: 'clamp',
        });

        const barX = barsStartX + i * (barWidth + barGap);

        return (
          <React.Fragment key={sc.id}>
            {/* Bar */}
            <div
              style={{
                position: 'absolute',
                left: barX,
                top: barsBottomY - barHeight,
                width: barWidth,
                height: barHeight,
                opacity: barOpacity,
                background: `linear-gradient(to top, rgba(${hexToRgb(sc.color)}, 0.3), rgba(${hexToRgb(sc.color)}, 0.7))`,
                border: `1.5px solid rgba(${hexToRgb(sc.color)}, 0.8)`,
                borderRadius: 6,
                zIndex: 3,
              }}
            />

            {/* Size class label below bar */}
            <div
              style={{
                position: 'absolute',
                left: barX,
                top: barsBottomY + 6,
                width: barWidth,
                textAlign: 'center',
                opacity: barOpacity,
                fontFamily: FONTS.mono,
                fontSize: 12,
                fontWeight: 700,
                color: sc.color,
                zIndex: 3,
              }}
            >
              {sc.id}
            </div>

            {/* Range label */}
            <div
              style={{
                position: 'absolute',
                left: barX - 4,
                top: barsBottomY + 22,
                width: barWidth + 8,
                textAlign: 'center',
                opacity: barOpacity,
                fontFamily: FONTS.mono,
                fontSize: 9,
                color: COLORS.textDim,
                zIndex: 3,
              }}
            >
              {sc.range}
            </div>

            {/* Fecundity values for SC3-SC5 */}
            {sc.fecundity > 0 && (
              <div
                style={{
                  position: 'absolute',
                  left: barX - 10,
                  top: barsBottomY - maxBarHeights[i] - 22,
                  width: barWidth + 20,
                  textAlign: 'center',
                  opacity: fecundityOpacity,
                  fontFamily: FONTS.mono,
                  fontSize: 11,
                  fontWeight: 600,
                  color: COLORS.decision,
                  zIndex: 4,
                }}
              >
                {sc.fecundity.toLocaleString()}
              </div>
            )}
          </React.Fragment>
        );
      })}

      {/* Transplanting arrow exits left side */}
      <FlowArrow
        fromX={760}
        fromY={420}
        toX={300}
        toY={500}
        color={COLORS.transplanting}
        label="Transplant"
        delay={arrowDelay}
        particleCount={3}
      />

      {/* "Corals grow through size classes..." text at 5s */}
      <div
        style={{
          position: 'absolute',
          bottom: 120,
          width: '100%',
          textAlign: 'center',
          opacity: growTextOpacity,
          transform: `translateY(${growTextTranslateY}px)`,
          fontFamily: FONTS.body,
          fontSize: 24,
          color: COLORS.textMuted,
          zIndex: 2,
        }}
      >
        Corals grow through size classes, gaining fecundity
      </div>
    </AbsoluteFill>
  );
};

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

export const ReefOutplantingScene: React.FC = () => {
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

  // Arrow timings: Lab→Reef at 1s (frame 30), Orchard→Reef at 3s (frame 90)
  const labArrowDelay = 30;
  const orchardArrowDelay = 90;

  // Size class bars inside reef at 5s = frame 150
  const maxBarHeights = [30, 45, 75, 105, 135];
  const barWidth = 40;
  const barGap = 10;
  const totalBarsWidth =
    SIZE_CLASSES.length * barWidth + (SIZE_CLASSES.length - 1) * barGap;
  // Reef box: center at x=1400, y=400, width=300, height=200
  const reefBarsStartX = 1400 - totalBarsWidth / 2;
  const reefBarsBottomY = 400 + 80; // below center, room for label

  // Text at 7s = frame 210
  const textOpacity = interpolate(frame, [210, 230], [0, 1], {
    extrapolateRight: 'clamp',
    extrapolateLeft: 'clamp',
  });

  const textTranslateY = interpolate(frame, [210, 230], [14, 0], {
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
        Outplanting to Reef
      </div>

      {/* Lab CompartmentBox (left) */}
      <CompartmentBox
        label="Lab"
        subtitle="Production"
        color={COLORS.lab}
        x={300}
        y={400}
        width={200}
        height={80}
        delay={5}
      />

      {/* Orchard CompartmentBox (left-center) */}
      <CompartmentBox
        label="Orchard"
        subtitle="Grow-out"
        color={COLORS.orchard}
        x={600}
        y={550}
        width={200}
        height={80}
        delay={10}
      />

      {/* Reef CompartmentBox (right) */}
      <CompartmentBox
        label="Reef"
        subtitle="Wild population"
        color={COLORS.reef}
        x={1400}
        y={400}
        width={300}
        height={200}
        delay={15}
      />

      {/* FlowArrow: Lab → Reef (at 1s) */}
      <FlowArrow
        fromX={400}
        fromY={400}
        toX={1250}
        toY={350}
        color={COLORS.outplanting}
        label="0TX direct"
        delay={labArrowDelay}
        particleCount={4}
      />

      {/* FlowArrow: Orchard → Reef (at 3s) */}
      <FlowArrow
        fromX={700}
        fromY={540}
        toX={1250}
        toY={450}
        color={COLORS.transplanting}
        label="1TX transplant"
        delay={orchardArrowDelay}
        particleCount={4}
      />

      {/* Size class bars inside reef at 5s */}
      {SIZE_CLASSES.map((sc, i) => {
        // Each bar starts growing sequentially from frame 150
        const barDelay = 150 + i * 15;
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

        const barX = reefBarsStartX + i * (barWidth + barGap);

        // Use reef blue tinted versions of the size class colors
        const barColor = COLORS.reef;

        return (
          <React.Fragment key={sc.id}>
            <div
              style={{
                position: 'absolute',
                left: barX,
                top: reefBarsBottomY - barHeight,
                width: barWidth,
                height: barHeight,
                opacity: barOpacity,
                background: `linear-gradient(to top, rgba(${hexToRgb(barColor)}, 0.25), rgba(${hexToRgb(barColor)}, 0.65))`,
                border: `1.5px solid rgba(${hexToRgb(barColor)}, 0.7)`,
                borderRadius: 5,
                zIndex: 3,
              }}
            />

            {/* Size class label */}
            <div
              style={{
                position: 'absolute',
                left: barX,
                top: reefBarsBottomY + 4,
                width: barWidth,
                textAlign: 'center',
                opacity: barOpacity,
                fontFamily: FONTS.mono,
                fontSize: 10,
                fontWeight: 700,
                color: COLORS.reef,
                zIndex: 3,
              }}
            >
              {sc.id}
            </div>
          </React.Fragment>
        );
      })}

      {/* "Outplanted corals join the reef population" at 7s */}
      <div
        style={{
          position: 'absolute',
          bottom: 100,
          width: '100%',
          textAlign: 'center',
          opacity: textOpacity,
          transform: `translateY(${textTranslateY}px)`,
          fontFamily: FONTS.body,
          fontSize: 24,
          color: COLORS.textMuted,
          zIndex: 2,
        }}
      >
        Outplanted corals join the reef population
      </div>
    </AbsoluteFill>
  );
};

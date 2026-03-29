import React from 'react';
import { AbsoluteFill, useCurrentFrame, useVideoConfig, interpolate, Easing } from 'remotion';

interface Props {
  children: React.ReactNode;
  fadeInFrames?: number;
  fadeOutFrames?: number;
}

/**
 * Wraps a scene with fade-in at start and fade-out at end.
 * Uses the scene's local frame (0-based within its Series.Sequence).
 */
export const SceneFade: React.FC<Props> = ({
  children,
  fadeInFrames = 15,
  fadeOutFrames = 15,
}) => {
  const frame = useCurrentFrame();
  const { durationInFrames } = useVideoConfig();

  const fadeIn = fadeInFrames > 0
    ? interpolate(frame, [0, fadeInFrames], [0, 1], {
        extrapolateRight: 'clamp',
        extrapolateLeft: 'clamp',
        easing: Easing.inOut(Easing.quad),
      })
    : 1;

  const fadeOut = fadeOutFrames > 0
    ? interpolate(
        frame,
        [durationInFrames - fadeOutFrames, durationInFrames],
        [1, 0],
        {
          extrapolateRight: 'clamp',
          extrapolateLeft: 'clamp',
          easing: Easing.inOut(Easing.quad),
        },
      )
    : 1;

  return (
    <AbsoluteFill style={{ opacity: Math.min(fadeIn, fadeOut) }}>
      {children}
    </AbsoluteFill>
  );
};

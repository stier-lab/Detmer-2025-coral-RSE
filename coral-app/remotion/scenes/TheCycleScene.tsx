import React from 'react';
import {
  AbsoluteFill,
  useCurrentFrame,
  useVideoConfig,
  interpolate,
  spring,
} from 'remotion';
import { COLORS, FONTS } from '../styles';
import { CompartmentBox } from '../components/CompartmentBox';
import { DecisionDiamond } from '../components/DecisionDiamond';
import { FlowArrow } from '../components/FlowArrow';

export const TheCycleScene: React.FC = () => {
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

  // Node positions
  const nodes = {
    external: { x: 200, y: 250 },
    wildRecruit: { x: 200, y: 700 },
    lab: { x: 700, y: 400 },
    decision: { x: 960, y: 400 },
    orchard: { x: 1200, y: 600 },
    reef: { x: 1500, y: 400 },
  };

  // Staggered node delays: 0.3s apart = 9 frames apart at 30fps
  const nodeDelayBase = 15;
  const nodeStagger = 9;

  // Arrow delays: start after all nodes are visible (~frame 70), stagger 12 frames apart
  const arrowDelayBase = 75;
  const arrowStagger = 12;

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
        The Full Cycle
      </div>

      {/* === NODES === */}

      {/* External Reefs */}
      <CompartmentBox
        label="External Reefs"
        subtitle="Source populations"
        color={COLORS.external}
        x={nodes.external.x}
        y={nodes.external.y}
        width={200}
        height={80}
        delay={nodeDelayBase}
      />

      {/* Wild Recruitment */}
      <CompartmentBox
        label="Wild Recruitment"
        subtitle="Natural settlement"
        color={COLORS.external}
        x={nodes.wildRecruit.x}
        y={nodes.wildRecruit.y}
        width={200}
        height={80}
        delay={nodeDelayBase + nodeStagger}
      />

      {/* Lab */}
      <CompartmentBox
        label="Lab"
        subtitle="Coral production"
        color={COLORS.lab}
        x={nodes.lab.x}
        y={nodes.lab.y}
        width={200}
        height={90}
        delay={nodeDelayBase + nodeStagger * 2}
      />

      {/* Decision Diamond */}
      <DecisionDiamond
        x={nodes.decision.x}
        y={nodes.decision.y}
        label="reef_prop"
        value="0.5"
        delay={nodeDelayBase + nodeStagger * 3}
      />

      {/* Orchard */}
      <CompartmentBox
        label="Orchard"
        subtitle="Grow-out"
        color={COLORS.orchard}
        x={nodes.orchard.x}
        y={nodes.orchard.y}
        width={200}
        height={90}
        delay={nodeDelayBase + nodeStagger * 4}
      />

      {/* Reef */}
      <CompartmentBox
        label="Reef"
        subtitle="Wild population"
        color={COLORS.reef}
        x={nodes.reef.x}
        y={nodes.reef.y}
        width={240}
        height={120}
        delay={nodeDelayBase + nodeStagger * 5}
      />

      {/* === FLOW ARROWS (staggered after nodes) === */}

      {/* 1. External → Lab (collection, cyan) */}
      <FlowArrow
        fromX={nodes.external.x + 100}
        fromY={nodes.external.y + 40}
        toX={nodes.lab.x - 100}
        toY={nodes.lab.y - 30}
        color={COLORS.collection}
        label="Collection"
        delay={arrowDelayBase}
        particleCount={3}
      />

      {/* 2. Lab → Decision (outplanting, yellow) */}
      <FlowArrow
        fromX={nodes.lab.x + 100}
        fromY={nodes.lab.y}
        toX={nodes.decision.x - 60}
        toY={nodes.decision.y}
        color={COLORS.outplanting}
        label="Production"
        delay={arrowDelayBase + arrowStagger}
        particleCount={2}
      />

      {/* 3. Decision → Orchard (transplanting, teal) */}
      <FlowArrow
        fromX={nodes.decision.x + 20}
        fromY={nodes.decision.y + 55}
        toX={nodes.orchard.x - 80}
        toY={nodes.orchard.y - 30}
        color={COLORS.transplanting}
        label="To Orchard"
        delay={arrowDelayBase + arrowStagger * 2}
        particleCount={3}
      />

      {/* 4. Decision → Reef (outplanting, yellow) */}
      <FlowArrow
        fromX={nodes.decision.x + 55}
        fromY={nodes.decision.y - 10}
        toX={nodes.reef.x - 120}
        toY={nodes.reef.y - 20}
        color={COLORS.outplanting}
        label="Direct to Reef"
        delay={arrowDelayBase + arrowStagger * 3}
        particleCount={3}
      />

      {/* 5. Orchard → Reef (transplanting, teal) */}
      <FlowArrow
        fromX={nodes.orchard.x + 100}
        fromY={nodes.orchard.y - 30}
        toX={nodes.reef.x - 100}
        toY={nodes.reef.y + 50}
        color={COLORS.transplanting}
        label="Transplant"
        delay={arrowDelayBase + arrowStagger * 4}
        particleCount={3}
      />

      {/* 6. Wild Recruitment → Reef (external, gray, dashed) */}
      <FlowArrow
        fromX={nodes.wildRecruit.x + 100}
        fromY={nodes.wildRecruit.y}
        toX={nodes.reef.x - 100}
        toY={nodes.reef.y + 60}
        color={COLORS.external}
        label="Wild Recruits"
        delay={arrowDelayBase + arrowStagger * 5}
        dashed
        particleCount={2}
      />

      {/* 7. Orchard → Lab feedback (collection, cyan, dashed) */}
      <FlowArrow
        fromX={nodes.orchard.x - 100}
        fromY={nodes.orchard.y - 35}
        toX={nodes.lab.x + 50}
        toY={nodes.lab.y + 45}
        color={COLORS.collection}
        label="Feedback"
        delay={arrowDelayBase + arrowStagger * 6}
        dashed
        particleCount={2}
      />
    </AbsoluteFill>
  );
};

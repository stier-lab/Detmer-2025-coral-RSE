import * as d3 from 'd3';
import { sizeClasses, locations, flows, decisions, externalInputs, coreEquation, annualCycle, disturbanceLayer, stochasticityLayer, costsLayer } from './data.js';
import { computeLayout, scNodePos, getLocHeight, curvedPath, diamondPoints } from './layout.js';

let layout;
let svg, mainGroup;
let expandedState = { lab: false, orchard: false, reef: false };

// ── Dynamic positioning ──────────────────────
// When Lab expands, push Orchard/Reef down to maintain spacing
const MIN_GAP = 120; // minimum px between Lab bottom and bottom row top

function getBottomRowShift() {
  const labH = getLocHeight('lab', expandedState, layout);
  const labBottom = layout.locationPositions.lab.y + labH;
  return Math.max(0, labBottom + MIN_GAP - layout.locationPositions.orchard.y);
}

function getEffectivePositions() {
  const base = layout.locationPositions;
  const shift = getBottomRowShift();
  return {
    lab: base.lab,
    orchard: { ...base.orchard, y: base.orchard.y + shift },
    reef: { ...base.reef, y: base.reef.y + shift },
  };
}

function getEffectiveViewHeight() {
  const pos = getEffectivePositions();
  const orchH = getLocHeight('orchard', expandedState, layout);
  const reefH = getLocHeight('reef', expandedState, layout);
  const maxBottom = Math.max(pos.orchard.y + orchH, pos.reef.y + reefH);
  return maxBottom + 160; // space for legend + badge
}

// ── Init ─────────────────────────────────────
export function initDiagram(svgEl) {
  svg = d3.select(svgEl);
  layout = computeLayout();

  svg
    .attr('viewBox', `0 0 ${layout.totalWidth} ${layout.collapsedHeight}`)
    .attr('preserveAspectRatio', 'xMidYMin meet');

  // Defs: arrowheads and glow filters
  const defs = svg.append('defs');
  addArrowhead(defs, 'arrowhead-grey', '#64748B');
  addArrowhead(defs, 'arrowhead-green', '#22c55e');
  addArrowhead(defs, 'arrowhead-red', '#ef4444');
  addArrowhead(defs, 'arrowhead-purple', '#c084fc');
  addArrowhead(defs, 'arrowhead-amber', '#FBBF24');
  addArrowhead(defs, 'arrowhead-flow-cyan', '#67E8F9');
  addArrowhead(defs, 'arrowhead-flow-amber', '#FBBF24');
  addArrowhead(defs, 'arrowhead-flow-teal', '#2DD4BF');
  addArrowhead(defs, 'arrowhead-fecundity', '#FB923C');
  addArrowhead(defs, 'arrowhead-external', '#64748B');

  // Glow filters
  addGlowFilter(defs, 'glow-soft', 3, 0.3);
  addGlowFilter(defs, 'glow-decision', 6, 0.4);
  addGlowFilter(defs, 'glow-disturbance', 8, 0.5);

  mainGroup = svg.append('g').attr('class', 'main-diagram');

  // Draw order: flows behind, then locations, then external+decisions on top
  drawInterLocationFlows();
  Object.keys(locations).forEach(locId => drawLocation(locId));
  drawExternalInputs();
  drawDecisionDiamonds();
  drawLegend();
  drawEquationBadge();
}

function addArrowhead(defs, id, color) {
  defs.append('marker')
    .attr('id', id)
    .attr('viewBox', '0 0 10 7')
    .attr('refX', 9)
    .attr('refY', 3.5)
    .attr('markerWidth', 8)
    .attr('markerHeight', 6)
    .attr('orient', 'auto')
    .append('polygon')
    .attr('points', '0 0, 10 3.5, 0 7')
    .attr('fill', color);
}

function addGlowFilter(defs, id, stdDev, opacity) {
  const filter = defs.append('filter')
    .attr('id', id)
    .attr('x', '-50%').attr('y', '-50%')
    .attr('width', '200%').attr('height', '200%');
  filter.append('feGaussianBlur')
    .attr('in', 'SourceGraphic')
    .attr('stdDeviation', stdDev)
    .attr('result', 'blur');
  filter.append('feComponentTransfer')
    .attr('in', 'blur')
    .attr('result', 'glow')
    .append('feFuncA')
    .attr('type', 'linear')
    .attr('slope', opacity);
  const merge = filter.append('feMerge');
  merge.append('feMergeNode').attr('in', 'glow');
  merge.append('feMergeNode').attr('in', 'SourceGraphic');
}

// ── Flow path calculation ──────────────────
// Uses effective positions so arrows follow shifted bottom row
function calcFlowGeometry(flow) {
  const pos = getEffectivePositions();
  const fromPos = pos[flow.from];
  const toPos = pos[flow.to];
  const fromH = getLocHeight(flow.from, expandedState, layout);
  const toH = getLocHeight(flow.to, expandedState, layout);

  let pathD, labelPos;
  const colorMap = { collection: '#67E8F9', outplant: '#FBBF24', transplant: '#2DD4BF' };

  if (flow.type === 'collection') {
    // Collection flows go UP from Orchard/Reef to Lab (diagonal)
    // Label near SOURCE end (near Orchard/Reef) to avoid center congestion
    if (flow.from === 'orchard') {
      const start = { x: fromPos.x + fromPos.w * 0.7, y: fromPos.y };
      const end = { x: toPos.x + toPos.w * 0.3, y: toPos.y + toH };
      const midX = (start.x + end.x) / 2 - 40;
      const midY = (start.y + end.y) / 2;
      pathD = `M ${start.x} ${start.y} Q ${midX} ${midY} ${end.x} ${end.y}`;
      // Label at t=0.18 from source (near Orchard)
      const t = 0.18;
      labelPos = {
        x: start.x + (end.x - start.x) * t - 80,
        y: start.y + (end.y - start.y) * t,
      };
    } else {
      const start = { x: fromPos.x + fromPos.w * 0.3, y: fromPos.y };
      const end = { x: toPos.x + toPos.w * 0.7, y: toPos.y + toH };
      const midX = (start.x + end.x) / 2 + 40;
      const midY = (start.y + end.y) / 2;
      pathD = `M ${start.x} ${start.y} Q ${midX} ${midY} ${end.x} ${end.y}`;
      const t = 0.18;
      labelPos = {
        x: start.x + (end.x - start.x) * t + 80,
        y: start.y + (end.y - start.y) * t,
      };
    }
  } else if (flow.type === 'outplant') {
    // Outplant flows go DOWN from Lab to Orchard/Reef (diagonal)
    // Label near SOURCE end (near Lab) to avoid center congestion
    if (flow.to === 'reef') {
      const start = { x: fromPos.x + fromPos.w * 0.8, y: fromPos.y + fromH };
      const end = { x: toPos.x + toPos.w * 0.2, y: toPos.y };
      const midX = (start.x + end.x) / 2 + 35;
      const midY = (start.y + end.y) / 2;
      pathD = `M ${start.x} ${start.y} Q ${midX} ${midY} ${end.x} ${end.y}`;
      const t = 0.18;
      labelPos = {
        x: start.x + (end.x - start.x) * t + 70,
        y: start.y + (end.y - start.y) * t,
      };
    } else {
      const start = { x: fromPos.x + fromPos.w * 0.2, y: fromPos.y + fromH };
      const end = { x: toPos.x + toPos.w * 0.8, y: toPos.y };
      const midX = (start.x + end.x) / 2 - 35;
      const midY = (start.y + end.y) / 2;
      pathD = `M ${start.x} ${start.y} Q ${midX} ${midY} ${end.x} ${end.y}`;
      const t = 0.18;
      labelPos = {
        x: start.x + (end.x - start.x) * t - 70,
        y: start.y + (end.y - start.y) * t,
      };
    }
  } else {
    // Transplant: Orchard → Reef, horizontal at bottom
    const fromMidY = fromPos.y + fromH / 2;
    const toMidY = toPos.y + toH / 2;
    pathD = `M ${fromPos.x + fromPos.w} ${fromMidY} L ${toPos.x} ${toMidY}`;
    labelPos = { x: (fromPos.x + fromPos.w + toPos.x) / 2, y: Math.min(fromMidY, toMidY) - 14 };
  }

  return { pathD, labelPos, color: colorMap[flow.type] };
}

// ── Location boxes ──────────────────────────
function drawLocation(locId) {
  const loc = locations[locId];
  const pos = layout.locationPositions[locId];
  const g = mainGroup.append('g')
    .attr('class', `location-box location-${locId}`)
    .attr('data-location', locId)
    .attr('transform', 'translate(0, 0)'); // animated when Lab expands

  // Background rect
  g.append('rect')
    .attr('class', 'location-bg')
    .attr('x', pos.x)
    .attr('y', pos.y)
    .attr('width', pos.w)
    .attr('height', layout.LOC_COLLAPSED_H)
    .attr('fill', loc.colorLight)
    .attr('stroke', loc.color);

  // Title
  g.append('text')
    .attr('class', 'location-title')
    .attr('x', pos.x + pos.w / 2)
    .attr('y', pos.y + 36)
    .attr('text-anchor', 'middle')
    .text(loc.name);

  // Subtitle
  g.append('text')
    .attr('class', 'location-subtitle')
    .attr('x', pos.x + pos.w / 2)
    .attr('y', pos.y + 55)
    .attr('text-anchor', 'middle')
    .text(loc.fullName);

  // Click hint with chevron
  g.append('text')
    .attr('class', 'click-hint')
    .attr('x', pos.x + pos.w / 2)
    .attr('y', pos.y + 74)
    .attr('text-anchor', 'middle')
    .attr('font-size', '10px')
    .attr('fill', loc.color)
    .attr('opacity', 0.7)
    .attr('letter-spacing', '0.08em')
    .text('\u25B6 expand');

  // Expanded detail group (hidden initially)
  const detail = g.append('g')
    .attr('class', 'location-detail')
    .attr('data-location', locId);

  if (loc.hasSizeClasses) {
    drawSizeClasses(detail, locId);
  } else {
    drawLabDetail(detail, locId);
  }

  // Layer overlays on the location
  drawLocationLayers(g, locId);
}

function drawSizeClasses(detailGroup, locId) {
  const loc = locations[locId];
  const pos = layout.locationPositions[locId];

  sizeClasses.forEach((sc, i) => {
    const nodePos = scNodePos(pos, i, layout);
    const scG = detailGroup.append('g')
      .attr('class', `sc-node sc-${sc.id}`)
      .attr('data-sc', sc.id)
      .attr('data-location', locId);

    // Node rectangle
    scG.append('rect')
      .attr('x', nodePos.x)
      .attr('y', nodePos.y)
      .attr('width', nodePos.w)
      .attr('height', nodePos.h)
      .attr('fill', 'rgba(15, 23, 42, 0.65)')
      .attr('stroke', loc.color)
      .attr('stroke-opacity', 0.55);

    // SC label
    scG.append('text')
      .attr('class', 'sc-label')
      .attr('x', nodePos.x + 12)
      .attr('y', nodePos.y + 20)
      .text(sc.label);

    // Range text
    scG.append('text')
      .attr('class', 'sc-range')
      .attr('x', nodePos.x + 50)
      .attr('y', nodePos.y + 20)
      .text(sc.range);

    // Role text
    scG.append('text')
      .attr('class', 'sc-range')
      .attr('x', nodePos.x + 12)
      .attr('y', nodePos.y + 36)
      .text(sc.role);

    // Reproduction indicator (interactive)
    if (sc.reproduces) {
      scG.append('text')
        .attr('class', 'sc-icon sc-icon-repro')
        .attr('x', nodePos.x + nodePos.w - 12)
        .attr('y', nodePos.y + 20)
        .attr('text-anchor', 'end')
        .attr('font-size', '12px')
        .attr('fill', '#FBBF24')
        .attr('cursor', 'help')
        .style('pointer-events', 'all')
        .text('\u2640');
    }
    // Fragmentation indicator (reef only, interactive)
    if (sc.fragments && !loc.noFragmentation) {
      scG.append('text')
        .attr('class', 'sc-icon sc-icon-frag')
        .attr('x', nodePos.x + nodePos.w - 28)
        .attr('y', nodePos.y + 20)
        .attr('text-anchor', 'end')
        .attr('font-size', '12px')
        .attr('fill', '#C084FC')
        .attr('cursor', 'help')
        .style('pointer-events', 'all')
        .text('\u26A1');
    }
  });

  // Draw internal arrows (growth, shrinkage, fragmentation)
  drawInternalArrows(detailGroup, locId);
}

function drawInternalArrows(detailGroup, locId) {
  const loc = locations[locId];
  const pos = layout.locationPositions[locId];

  for (let i = 0; i < 4; i++) {
    const fromPos = scNodePos(pos, i, layout);
    const toPos = scNodePos(pos, i + 1, layout);

    // Growth arrow (up) on left side
    const gx = fromPos.x + 6;
    detailGroup.append('line')
      .attr('class', 'internal-arrow growth-arrow')
      .attr('x1', gx).attr('y1', fromPos.y)
      .attr('x2', gx).attr('y2', toPos.y + toPos.h)
      .attr('marker-end', 'url(#arrowhead-green)');

    // Shrinkage arrow (down) on right side
    const sx = fromPos.x + fromPos.w - 6;
    detailGroup.append('line')
      .attr('class', 'internal-arrow shrinkage-arrow')
      .attr('x1', sx).attr('y1', toPos.y + toPos.h)
      .attr('x2', sx).attr('y2', fromPos.y)
      .attr('marker-end', 'url(#arrowhead-red)');
  }

  // Fragmentation arrows (reef only): SC4/SC5 -> smaller classes
  if (!loc.noFragmentation) {
    [3, 4].forEach(fromIdx => {
      const fromSc = scNodePos(pos, fromIdx, layout);
      for (let toIdx = 0; toIdx <= 2; toIdx++) {
        const toSc = scNodePos(pos, toIdx, layout);
        const fx = fromSc.x - 8;
        const ty = toSc.y + toSc.h / 2;
        const fy = fromSc.y + fromSc.h / 2;
        const cpx = fx - 18 - (fromIdx - toIdx) * 5;
        detailGroup.append('path')
          .attr('class', 'internal-arrow frag-arrow')
          .attr('d', `M ${fx + 8} ${fy} C ${cpx} ${fy}, ${cpx} ${ty}, ${fromSc.x} ${ty}`)
          .attr('data-pathways', 'wild,0tx,1tx,transplant');
      }
    });
  }

  // Fecundity arrows: SC3-SC5 exit right side
  [2, 3, 4].forEach(scIdx => {
    const scPos = scNodePos(pos, scIdx, layout);
    const exitX = scPos.x + scPos.w;
    const exitY = scPos.y + scPos.h / 2;
    detailGroup.append('line')
      .attr('class', 'internal-arrow fecundity-arrow')
      .attr('x1', exitX).attr('y1', exitY)
      .attr('x2', exitX + 20).attr('y2', exitY)
      .attr('marker-end', 'url(#arrowhead-fecundity)');
  });

  // Fecundity label
  const sc3Pos = scNodePos(pos, 2, layout);
  detailGroup.append('text')
    .attr('class', 'arrow-label')
    .attr('x', sc3Pos.x + sc3Pos.w + 4)
    .attr('y', sc3Pos.y - 6)
    .attr('font-size', '10px')
    .attr('fill', '#FB923C')
    .attr('font-family', "'DM Sans', sans-serif")
    .text('larvae \u2192');
}

function drawLabDetail(detailGroup, locId) {
  const pos = layout.locationPositions[locId];
  const cx = pos.x + pos.w / 2;
  let y = pos.y + 85;

  const steps = [
    { label: 'Larvae collected', sublabel: 'from orchard + ref. reef' },
    { label: 'Settlement on tiles', sublabel: '~15% success rate' },
    { label: '0_TX: Immediate outplant', sublabel: 'OR' },
    { label: '1_TX: Retain 1 year', sublabel: 'density-dep. survival' },
    { label: 'Outplant to reef/orchard', sublabel: 'via reef_prop allocation' },
  ];

  const stepSpacing = 62;
  const boxH = 50;

  steps.forEach((step, i) => {
    const boxY = y + i * stepSpacing;
    const boxW = 240;

    detailGroup.append('rect')
      .attr('x', cx - boxW / 2)
      .attr('y', boxY)
      .attr('width', boxW)
      .attr('height', boxH)
      .attr('rx', 8).attr('ry', 8)
      .attr('fill', 'rgba(15, 23, 42, 0.6)')
      .attr('stroke', '#F59E0B')
      .attr('stroke-opacity', 0.3)
      .attr('stroke-width', 1);

    detailGroup.append('text')
      .attr('x', cx)
      .attr('y', boxY + 22)
      .attr('text-anchor', 'middle')
      .attr('font-size', '12px')
      .attr('font-weight', '600')
      .attr('fill', '#E2E8F0')
      .attr('font-family', "'DM Sans', sans-serif")
      .text(step.label);

    detailGroup.append('text')
      .attr('x', cx)
      .attr('y', boxY + 38)
      .attr('text-anchor', 'middle')
      .attr('font-size', '10px')
      .attr('fill', '#7A8BA8')
      .attr('font-family', "'DM Sans', sans-serif")
      .text(step.sublabel);

    // Arrow to next step
    if (i < steps.length - 1) {
      detailGroup.append('line')
        .attr('class', 'internal-arrow')
        .attr('x1', cx).attr('y1', boxY + boxH)
        .attr('x2', cx).attr('y2', boxY + stepSpacing)
        .attr('marker-end', 'url(#arrowhead-grey)');
    }

    // Branch split label between step 2 (0_TX) and step 3 (1_TX)
    if (i === 2) {
      detailGroup.append('text')
        .attr('x', cx + boxW / 2 + 8)
        .attr('y', boxY + boxH + 8)
        .attr('font-size', '9px')
        .attr('font-family', "'JetBrains Mono', monospace")
        .attr('fill', '#FDE047')
        .attr('text-anchor', 'start')
        .text('\u2195 split');
    }
  });
}

// ── Inter-location flow arrows ──────────────
function drawInterLocationFlows() {
  const flowGroup = mainGroup.append('g').attr('class', 'inter-flows');
  const markerMap = { collection: 'arrowhead-flow-cyan', outplant: 'arrowhead-flow-amber', transplant: 'arrowhead-flow-teal' };

  flows.forEach(flow => {
    const { pathD, labelPos, color } = calcFlowGeometry(flow);

    const flowG = flowGroup.append('g')
      .attr('class', `flow-group flow-${flow.id}`)
      .attr('data-pathways', flow.pathways.join(','))
      .attr('data-flow', flow.id);

    // Glow layer behind the arrow
    flowG.append('path')
      .attr('class', 'flow-glow')
      .attr('d', pathD)
      .attr('fill', 'none')
      .attr('stroke', color)
      .attr('stroke-width', 10)
      .attr('stroke-linecap', 'round')
      .attr('opacity', 0.15);

    flowG.append('path')
      .attr('class', `flow-arrow ${flow.type}`)
      .attr('d', pathD)
      .attr('marker-end', `url(#${markerMap[flow.type]})`);

    // Label
    flowG.append('text')
      .attr('class', 'flow-label')
      .attr('x', labelPos.x)
      .attr('y', labelPos.y)
      .attr('text-anchor', 'middle')
      .attr('font-size', '13px')
      .attr('fill', color)
      .attr('font-weight', '600')
      .attr('font-family', "'DM Sans', sans-serif")
      .attr('style', 'filter: drop-shadow(0 1px 3px rgba(0,0,0,0.7))')
      .text(flow.label);

    // Cost layer badge
    if (flow.costLayer) {
      flowG.append('text')
        .attr('class', 'cost-badge layer-costs')
        .attr('x', labelPos.x)
        .attr('y', labelPos.y + 16)
        .attr('text-anchor', 'middle')
        .text(flow.costLayer);
    }
  });
}

// Update flow positions on expand/collapse
function updateFlowPositions(animate) {
  const dur = animate ? 400 : 0;

  flows.forEach(flow => {
    const { pathD, labelPos } = calcFlowGeometry(flow);
    const flowG = mainGroup.select(`.flow-${flow.id}`);

    flowG.selectAll('path').transition().duration(dur).attr('d', pathD);
    flowG.select('.flow-label').transition().duration(dur)
      .attr('x', labelPos.x).attr('y', labelPos.y);
    const costBadge = flowG.select('.cost-badge');
    if (!costBadge.empty()) {
      costBadge.transition().duration(dur)
        .attr('x', labelPos.x).attr('y', labelPos.y + 16);
    }
  });
}

// ── Decision diamonds ───────────────────────
function calcDecisionPositions() {
  const pos = getEffectivePositions();
  const labH = getLocHeight('lab', expandedState, layout);
  const orchH = getLocHeight('orchard', expandedState, layout);
  const reefH = getLocHeight('reef', expandedState, layout);

  const positions = {};

  // reef_prop: centered in the gap between Lab bottom and bottom row top
  const labBottom = pos.lab.y + labH;
  const bottomRowTop = pos.orchard.y;
  const gapMidY = (labBottom + bottomRowTop) / 2;
  positions['reef-prop'] = {
    cx: pos.lab.x + pos.lab.w / 2,
    cy: gapMidY,
  };

  // lab_retain_max: above Lab
  positions['lab-retain'] = { cx: pos.lab.x + pos.lab.w / 2, cy: pos.lab.y - 30 };

  // transplant[yr]: below the transplant line between Orchard and Reef
  const transplantMidY = (pos.orchard.y + orchH / 2 + pos.reef.y + reefH / 2) / 2;
  positions['transplant-timing'] = {
    cx: (pos.orchard.x + pos.orchard.w + pos.reef.x) / 2,
    cy: transplantMidY + 30,
  };

  return positions;
}

function drawDecisionDiamonds() {
  const decGroup = mainGroup.append('g').attr('class', 'decisions-group');
  const ds = layout.DIAMOND_SIZE;
  const positions = calcDecisionPositions();

  decisions.forEach(dec => {
    const { cx, cy } = positions[dec.id];

    const decG = decGroup.append('g')
      .attr('class', 'decision-diamond')
      .attr('data-decision', dec.id)
      .attr('data-pathways', dec.pathways.join(','));

    decG.append('polygon')
      .attr('points', diamondPoints(cx, cy, ds));

    // Position lab-retain label to the right to avoid overlapping the Lab box
    const labelX = dec.id === 'lab-retain' ? cx + ds + 8 : cx;
    const labelY = dec.id === 'lab-retain' ? cy + 5 : cy + ds + 16;
    const anchor = dec.id === 'lab-retain' ? 'start' : 'middle';

    decG.append('text')
      .attr('class', 'decision-label')
      .attr('x', labelX)
      .attr('y', labelY)
      .attr('text-anchor', anchor)
      .text(dec.label);
  });
}

function updateDecisionPositions(animate) {
  const dur = animate ? 400 : 0;
  const ds = layout.DIAMOND_SIZE;
  const positions = calcDecisionPositions();

  decisions.forEach(dec => {
    const { cx, cy } = positions[dec.id];
    const decG = mainGroup.select(`[data-decision="${dec.id}"]`);
    decG.select('polygon').transition().duration(dur)
      .attr('points', diamondPoints(cx, cy, ds));
    const labelX = dec.id === 'lab-retain' ? cx + ds + 8 : cx;
    const labelY = dec.id === 'lab-retain' ? cy + 5 : cy + ds + 16;
    decG.select('.decision-label').transition().duration(dur)
      .attr('x', labelX).attr('y', labelY);
  });
}

// ── External inputs ─────────────────────────
function drawExternalInputs() {
  const extGroup = mainGroup.append('g').attr('class', 'external-inputs-group');

  externalInputs.forEach(ext => {
    const pos = getEffectivePositions();
    const targetPos = pos[ext.target];
    const targetH = getLocHeight(ext.target, expandedState, layout);
    const extG = extGroup.append('g')
      .attr('class', 'external-input')
      .attr('data-pathways', ext.pathways.join(','))
      .attr('data-external', ext.id);

    if (ext.target === 'reef') {
      const entryX = targetPos.x + targetPos.w + 70;
      const entryY = targetPos.y + targetH * 0.75;
      extG.append('line')
        .attr('x1', entryX).attr('y1', entryY)
        .attr('x2', targetPos.x + targetPos.w).attr('y2', entryY)
        .attr('marker-end', 'url(#arrowhead-external)');

      extG.append('text')
        .attr('class', 'external-label')
        .attr('x', entryX + 8)
        .attr('y', entryY - 6)
        .attr('text-anchor', 'start')
        .text('Wild recruitment');
      extG.append('text')
        .attr('class', 'external-label')
        .attr('x', entryX + 8)
        .attr('y', entryY + 14)
        .attr('text-anchor', 'start')
        .attr('font-size', '11px')
        .text('(\u03BB) \u2192 SC1');
    } else {
      const entryX = targetPos.x - 70;
      const entryY = targetPos.y + targetH / 2;
      extG.append('line')
        .attr('x1', entryX).attr('y1', entryY)
        .attr('x2', targetPos.x).attr('y2', entryY)
        .attr('marker-end', 'url(#arrowhead-external)');

      extG.append('text')
        .attr('class', 'external-label')
        .attr('x', entryX - 8)
        .attr('y', entryY - 6)
        .attr('text-anchor', 'end')
        .text('Ref. reef larvae');
      extG.append('text')
        .attr('class', 'external-label')
        .attr('x', entryX - 8)
        .attr('y', entryY + 14)
        .attr('text-anchor', 'end')
        .attr('font-size', '11px')
        .text('(\u03BB_R)');
    }
  });
}

function updateExternalPositions(animate) {
  const dur = animate ? 400 : 0;
  const pos = getEffectivePositions();

  externalInputs.forEach(ext => {
    const targetPos = pos[ext.target];
    const targetH = getLocHeight(ext.target, expandedState, layout);
    const extG = mainGroup.select(`[data-external="${ext.id}"]`);

    if (ext.target === 'reef') {
      const entryX = targetPos.x + targetPos.w + 70;
      const entryY = targetPos.y + targetH * 0.75;
      extG.select('line').transition().duration(dur)
        .attr('x1', entryX).attr('y1', entryY)
        .attr('x2', targetPos.x + targetPos.w).attr('y2', entryY);
      const texts = extG.selectAll('text');
      texts.filter(function(d, i) { return i === 0; }).transition().duration(dur).attr('y', entryY - 6);
      texts.filter(function(d, i) { return i === 1; }).transition().duration(dur).attr('y', entryY + 14);
    } else {
      const entryX = targetPos.x - 70;
      const entryY = targetPos.y + targetH / 2;
      extG.select('line').transition().duration(dur)
        .attr('x1', entryX).attr('y1', entryY)
        .attr('x2', targetPos.x).attr('y2', entryY);
      const texts = extG.selectAll('text');
      texts.filter(function(d, i) { return i === 0; }).transition().duration(dur).attr('y', entryY - 6);
      texts.filter(function(d, i) { return i === 1; }).transition().duration(dur).attr('y', entryY + 14);
    }
  });
}

// ── Dynamic viewBox sizing ──────────────────
function updateViewBox() {
  const targetH = getEffectiveViewHeight();
  svg.transition().duration(400)
    .attr('viewBox', `0 0 ${layout.totalWidth} ${targetH}`);
}

// ── Legend + badge repositioning ─────────────
function getLegendY() {
  const pos = getEffectivePositions();
  const orchH = getLocHeight('orchard', expandedState, layout);
  const reefH = getLocHeight('reef', expandedState, layout);
  const maxBottom = Math.max(pos.orchard.y + orchH, pos.reef.y + reefH);
  return maxBottom + 20;
}

function updateLegendPosition(animate) {
  const dur = animate ? 400 : 0;
  const legendY = getLegendY();
  mainGroup.select('.legend').transition().duration(dur)
    .attr('transform', `translate(${layout.locationPositions.orchard.x}, ${legendY})`);

  // Update annual cycle badge
  const badgeY = legendY + 10;
  const eqG = mainGroup.select('.equation-group');
  if (!eqG.empty()) {
    eqG.select('.annual-cycle-badge').transition().duration(dur)
      .attr('y', badgeY - 18);
    const texts = eqG.selectAll('text');
    texts.filter(function(d, i) { return i === 0; }).transition().duration(dur).attr('y', badgeY + 2);
    texts.filter(function(d, i) { return i === 1; }).transition().duration(dur).attr('y', badgeY + 2);
    texts.filter(function(d, i) { return i === 2; }).transition().duration(dur).attr('y', badgeY + 16);
  }
}

// ── Location layer overlays ─────────────────
function drawLocationLayers(locGroup, locId) {
  const loc = locations[locId];
  const pos = layout.locationPositions[locId];

  // Disturbance indicator (red dashed border)
  if (disturbanceLayer.affectsLocations.includes(locId)) {
    locGroup.append('rect')
      .attr('class', 'disturbance-indicator layer-disturbance')
      .attr('x', pos.x - 4)
      .attr('y', pos.y - 4)
      .attr('width', pos.w + 8)
      .attr('height', layout.LOC_COLLAPSED_H + 8)
      .attr('rx', 12).attr('ry', 12);
  }

  // Stochasticity badges
  const stochSources = stochasticityLayer.sources.filter(s => s.affects.includes(locId));
  if (stochSources.length > 0) {
    const badgeY = pos.y - 12;
    stochSources.forEach((s, i) => {
      locGroup.append('text')
        .attr('class', 'stochasticity-badge layer-stochasticity')
        .attr('x', pos.x + 8 + i * 68)
        .attr('y', badgeY)
        .text(`\u00B1${s.param}`);
    });
  }

  // Density dependence badge (lab only)
  if (locId === 'lab') {
    locGroup.append('text')
      .attr('class', 'density-badge layer-density')
      .attr('x', pos.x + pos.w / 2)
      .attr('y', pos.y + layout.LOC_COLLAPSED_H + 18)
      .attr('text-anchor', 'middle')
      .text('Density dep: S = s_base \u00D7 exp(-m \u00D7 density)');
  }
}

// ── Legend ───────────────────────────────────
function drawLegend() {
  const legendG = mainGroup.append('g')
    .attr('class', 'legend')
    .attr('transform', `translate(${layout.locationPositions.orchard.x}, ${getLegendY()})`);

  legendG.append('text').attr('class', 'legend-title').attr('y', 0).text('Legend');

  const arrowItems = [
    { color: '#22c55e', label: 'Growth (\u2192 larger class)', dash: '' },
    { color: '#ef4444', label: 'Shrinkage (\u2192 smaller class)', dash: '' },
    { color: '#C084FC', label: 'Fragmentation (asexual)', dash: '4,3' },
    { color: '#FB923C', label: 'Fecundity (larvae)', dash: '6,3' },
    { color: '#67E8F9', label: 'Larvae Collection', dash: '' },
    { color: '#FBBF24', label: 'Outplanting', dash: '' },
    { color: '#2DD4BF', label: 'Transplanting', dash: '' },
    { color: '#64748B', label: 'External input', dash: '6,4' },
  ];

  arrowItems.forEach((item, i) => {
    const col = Math.floor(i / 4);
    const row = i % 4;
    const x = col * 280;
    const y = 22 + row * 22;

    legendG.append('line')
      .attr('x1', x).attr('y1', y)
      .attr('x2', x + 36).attr('y2', y)
      .attr('stroke', item.color)
      .attr('stroke-width', 2.5)
      .attr('stroke-dasharray', item.dash);

    legendG.append('text')
      .attr('x', x + 44)
      .attr('y', y + 4)
      .text(item.label);
  });

  // Symbol items (diamond, icons)
  const symbolY = 22 + 4 * 22 + 8;
  const symbols = [
    { symbol: '\u25C7', color: '#FDE047', label: 'Decision parameter', size: '14px' },
    { symbol: '\u2640', color: '#FBBF24', label: 'Sexual reproduction', size: '13px' },
    { symbol: '\u26A1', color: '#C084FC', label: 'Fragmentation capability', size: '13px' },
  ];

  symbols.forEach((item, i) => {
    const x = i * 280;
    legendG.append('text')
      .attr('x', x + 10)
      .attr('y', symbolY + 4)
      .attr('text-anchor', 'middle')
      .attr('font-size', item.size)
      .attr('fill', item.color)
      .text(item.symbol);

    legendG.append('text')
      .attr('x', x + 28)
      .attr('y', symbolY + 4)
      .text(item.label);
  });
}

// ── Annual cycle info badge (equation is in the header) ─────
function drawEquationBadge() {
  const eqG = mainGroup.append('g')
    .attr('class', 'equation-group')
    .attr('data-tooltip-title', 'Core Equation')
    .attr('data-tooltip-body', annualCycle.map(s => `Step ${s.step}: ${s.name} \u2014 ${s.desc}`).join('\n'));

  const x = layout.locationPositions.reef.x;
  const y = getLegendY() + 10;

  eqG.append('rect')
    .attr('class', 'annual-cycle-badge')
    .attr('x', x - 12)
    .attr('y', y - 18)
    .attr('width', 240)
    .attr('height', 36)
    .attr('rx', 8).attr('ry', 8)
    .attr('fill', 'rgba(15, 23, 42, 0.65)')
    .attr('stroke', 'rgba(56, 189, 248, 0.25)')
    .attr('cursor', 'pointer');

  eqG.append('text')
    .attr('x', x)
    .attr('y', y + 2)
    .attr('font-size', '14px')
    .attr('fill', '#38BDF8')
    .text('\u24D8');

  eqG.append('text')
    .attr('x', x + 18)
    .attr('y', y + 2)
    .attr('font-size', '12px')
    .attr('fill', '#E2E8F0')
    .attr('font-family', "'DM Sans', sans-serif")
    .attr('font-weight', '500')
    .attr('cursor', 'pointer')
    .text('Annual Cycle \u2014 8 steps');

  eqG.append('text')
    .attr('x', x + 18)
    .attr('y', y + 16)
    .attr('font-size', '10px')
    .attr('fill', '#7A8BA8')
    .attr('font-family', "'DM Sans', sans-serif")
    .attr('cursor', 'pointer')
    .text('hover for details');
}

// ── Expand/collapse ─────────────────────────
export function toggleLocation(locId) {
  expandedState[locId] = !expandedState[locId];
  const isExpanded = expandedState[locId];

  const locGroup = mainGroup.select(`.location-${locId}`);
  const bg = locGroup.select('.location-bg');
  const detail = locGroup.select('.location-detail');
  const hint = locGroup.select('.click-hint');

  bg.transition().duration(400)
    .attr('height', isExpanded ? layout.LOC_EXPANDED_H : layout.LOC_COLLAPSED_H);

  if (isExpanded) {
    detail.classed('expanded', true);
    hint.text('\u25BC collapse');
  } else {
    detail.classed('expanded', false);
    hint.text('\u25B6 expand');
  }

  // Update disturbance indicator height
  const distRect = locGroup.select('.disturbance-indicator');
  if (!distRect.empty()) {
    distRect.transition().duration(400)
      .attr('height', (isExpanded ? layout.LOC_EXPANDED_H : layout.LOC_COLLAPSED_H) + 8);
  }

  // Update density badge position
  const densityBadge = locGroup.select('.density-badge');
  if (!densityBadge.empty()) {
    const pos = layout.locationPositions[locId];
    const targetH = isExpanded ? layout.LOC_EXPANDED_H : layout.LOC_COLLAPSED_H;
    densityBadge.transition().duration(400)
      .attr('y', pos.y + targetH + 18);
  }

  // Animate bottom row shift (Orchard/Reef slide down when Lab expands)
  const shift = getBottomRowShift();
  ['orchard', 'reef'].forEach(id => {
    mainGroup.select(`.location-${id}`)
      .transition().duration(400)
      .attr('transform', `translate(0, ${shift})`);
  });

  // Reposition all dynamic elements using effective positions
  updateFlowPositions(true);
  updateDecisionPositions(true);
  updateExternalPositions(true);
  updateLegendPosition(true);

  // Resize viewBox to fit content
  updateViewBox();
}

export function expandAll() {
  Object.keys(locations).forEach(id => {
    if (!expandedState[id]) toggleLocation(id);
  });
}

export function collapseAll() {
  Object.keys(locations).forEach(id => {
    if (expandedState[id]) toggleLocation(id);
  });
}

export function getExpandedState() {
  return expandedState;
}

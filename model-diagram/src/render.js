import * as d3 from 'd3';
import { sizeClasses, locations, flows, decisions, externalInputs, coreEquation, annualCycle, disturbanceLayer, stochasticityLayer, costsLayer } from './data.js';
import { computeLayout, scNodePos, locEdges, curvedPath, diamondPoints } from './layout.js';

let layout;
let svg, mainGroup;
let expandedState = { lab: false, orchard: false, reef: false };

export function initDiagram(svgEl) {
  svg = d3.select(svgEl);
  const containerWidth = Math.max(1100, svgEl.parentElement.clientWidth - 32);
  layout = computeLayout(containerWidth);

  svg
    .attr('viewBox', `0 0 ${layout.totalWidth} ${layout.totalHeight}`)
    .attr('preserveAspectRatio', 'xMidYMin meet');

  // Defs: arrowheads and glow filters
  const defs = svg.append('defs');
  addArrowhead(defs, 'arrowhead-grey', '#64748B');
  addArrowhead(defs, 'arrowhead-green', '#22c55e');
  addArrowhead(defs, 'arrowhead-red', '#ef4444');
  addArrowhead(defs, 'arrowhead-purple', '#c084fc');
  addArrowhead(defs, 'arrowhead-amber', '#FBBF24');
  addArrowhead(defs, 'arrowhead-flow-purple', '#A78BFA');
  addArrowhead(defs, 'arrowhead-flow-amber', '#FBBF24');
  addArrowhead(defs, 'arrowhead-flow-green', '#34D399');
  addArrowhead(defs, 'arrowhead-external', '#64748B');

  // Glow filters
  addGlowFilter(defs, 'glow-soft', 4, 0.3);
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

// ── Location boxes ──────────────────────────
function drawLocation(locId) {
  const loc = locations[locId];
  const pos = layout.locationPositions[locId];
  const g = mainGroup.append('g')
    .attr('class', `location-box location-${locId}`)
    .attr('data-location', locId);

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
    .attr('y', pos.y + 30)
    .attr('text-anchor', 'middle')
    .text(loc.name);

  // Subtitle
  g.append('text')
    .attr('class', 'location-subtitle')
    .attr('x', pos.x + pos.w / 2)
    .attr('y', pos.y + 48)
    .attr('text-anchor', 'middle')
    .text(loc.fullName);

  // Click hint
  g.append('text')
    .attr('class', 'click-hint')
    .attr('x', pos.x + pos.w / 2)
    .attr('y', pos.y + 66)
    .attr('text-anchor', 'middle')
    .attr('font-size', '9px')
    .attr('fill', loc.color)
    .attr('opacity', 0.5)
    .attr('letter-spacing', '0.1em')
    .text('click to expand');

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
      .attr('fill', 'rgba(15, 23, 42, 0.6)')
      .attr('stroke', loc.color)
      .attr('stroke-opacity', 0.4);

    // SC label
    scG.append('text')
      .attr('class', 'sc-label')
      .attr('x', nodePos.x + 12)
      .attr('y', nodePos.y + 22)
      .text(sc.label);

    // Range text
    scG.append('text')
      .attr('class', 'sc-range')
      .attr('x', nodePos.x + 50)
      .attr('y', nodePos.y + 22)
      .text(sc.range);

    // Role text
    scG.append('text')
      .attr('class', 'sc-range')
      .attr('x', nodePos.x + 12)
      .attr('y', nodePos.y + 40)
      .text(sc.role);

    // Reproduction indicator
    if (sc.reproduces) {
      scG.append('text')
        .attr('x', nodePos.x + nodePos.w - 12)
        .attr('y', nodePos.y + 22)
        .attr('text-anchor', 'end')
        .attr('font-size', '10px')
        .attr('fill', '#FBBF24')
        .text('♀');
    }
    // Fragmentation indicator (reef only)
    if (sc.fragments && !loc.noFragmentation) {
      scG.append('text')
        .attr('x', nodePos.x + nodePos.w - 28)
        .attr('y', nodePos.y + 22)
        .attr('text-anchor', 'end')
        .attr('font-size', '10px')
        .attr('fill', '#C084FC')
        .text('⚡');
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

    // Growth arrow (up — from SC_i to SC_i+1) on left side
    const gx = fromPos.x + 6;
    detailGroup.append('line')
      .attr('class', 'internal-arrow growth-arrow')
      .attr('x1', gx).attr('y1', fromPos.y)
      .attr('x2', gx).attr('y2', toPos.y + toPos.h)
      .attr('marker-end', 'url(#arrowhead-green)');

    // Shrinkage arrow (down — from SC_i+1 to SC_i) on right side
    const sx = fromPos.x + fromPos.w - 6;
    detailGroup.append('line')
      .attr('class', 'internal-arrow shrinkage-arrow')
      .attr('x1', sx).attr('y1', toPos.y + toPos.h)
      .attr('x2', sx).attr('y2', fromPos.y)
      .attr('marker-end', 'url(#arrowhead-red)');
  }

  // Fragmentation arrows (reef only): SC4/SC5 → smaller classes
  if (!loc.noFragmentation) {
    [3, 4].forEach(fromIdx => {
      const fromSc = scNodePos(pos, fromIdx, layout);
      // Arrow curving left from parent back down to SC1-SC3
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

  // Fecundity arrows: SC3-SC5 exit right side → label
  [2, 3, 4].forEach(scIdx => {
    const scPos = scNodePos(pos, scIdx, layout);
    const exitX = scPos.x + scPos.w;
    const exitY = scPos.y + scPos.h / 2;
    detailGroup.append('line')
      .attr('class', 'internal-arrow fecundity-arrow')
      .attr('x1', exitX).attr('y1', exitY)
      .attr('x2', exitX + 20).attr('y2', exitY)
      .attr('marker-end', 'url(#arrowhead-amber)');
  });

  // Fecundity label
  const sc3Pos = scNodePos(pos, 2, layout);
  detailGroup.append('text')
    .attr('class', 'arrow-label')
    .attr('x', sc3Pos.x + sc3Pos.w + 4)
    .attr('y', sc3Pos.y - 6)
    .attr('font-size', '9px')
    .attr('fill', '#FBBF24')
    .attr('font-family', "'DM Sans', sans-serif")
    .text('larvae →');
}

function drawLabDetail(detailGroup, locId) {
  const pos = layout.locationPositions[locId];
  const cx = pos.x + pos.w / 2;
  let y = pos.y + 80;

  // Lab flow diagram: simpler representation
  const steps = [
    { label: 'Larvae collected', sublabel: 'from orchard + ref. reef' },
    { label: 'Settlement on tiles', sublabel: '~15% success rate' },
    { label: '0_TX: Immediate outplant', sublabel: 'OR' },
    { label: '1_TX: Retain 1 year', sublabel: 'density-dep. survival' },
    { label: 'Outplant to reef/orchard', sublabel: 'via reef_prop allocation' },
  ];

  steps.forEach((step, i) => {
    const boxY = y + i * 85;
    const boxW = 240;
    const boxH = 60;

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
      .attr('y', boxY + 24)
      .attr('text-anchor', 'middle')
      .attr('font-size', '12px')
      .attr('font-weight', '600')
      .attr('fill', '#E2E8F0')
      .attr('font-family', "'DM Sans', sans-serif")
      .text(step.label);

    detailGroup.append('text')
      .attr('x', cx)
      .attr('y', boxY + 42)
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
        .attr('x2', cx).attr('y2', boxY + 85)
        .attr('marker-end', 'url(#arrowhead-grey)');
    }

    // Branch indicator for 0_TX / 1_TX split
    if (i === 2) {
      detailGroup.append('text')
        .attr('x', cx + boxW / 2 + 8)
        .attr('y', boxY + 35)
        .attr('font-size', '9px')
        .attr('font-family', "'JetBrains Mono', monospace")
        .attr('fill', '#FDE047')
        .text('lab_retain_max ↕');
    }
  });
}

// ── Inter-location flow arrows ──────────────
function drawInterLocationFlows() {
  const flowGroup = mainGroup.append('g').attr('class', 'inter-flows');

  flows.forEach(flow => {
    const fromPos = layout.locationPositions[flow.from];
    const toPos = layout.locationPositions[flow.to];
    const fromEdges = locEdges(fromPos, true);
    const toEdges = locEdges(toPos, true);

    let pathD, labelPos, markerEnd;
    const colorMap = { collection: '#A78BFA', outplant: '#FBBF24', transplant: '#34D399' };
    const markerMap = { collection: 'arrowhead-flow-purple', outplant: 'arrowhead-flow-amber', transplant: 'arrowhead-flow-green' };

    const collapsedH = layout.LOC_COLLAPSED_H;

    if (flow.type === 'collection') {
      // Collection flows arc above the boxes (right-to-left)
      if (flow.from === 'orchard') {
        // Orchard → Lab: shorter arc
        pathD = curvedPath(
          { x: fromPos.x + 60, y: fromPos.y },
          { x: toPos.x + toPos.w - 60, y: toPos.y },
          'above', 40
        );
        labelPos = { x: (fromPos.x + toPos.x + toPos.w) / 2, y: fromPos.y - 48 };
      } else {
        // Reef → Lab: taller arc spanning full width
        pathD = curvedPath(
          { x: fromPos.x + 60, y: fromPos.y },
          { x: toPos.x + toPos.w - 60, y: toPos.y },
          'above', 70
        );
        labelPos = { x: (fromPos.x + toPos.x + toPos.w) / 2, y: fromPos.y - 78 };
      }
    } else if (flow.type === 'outplant') {
      // Outplant flows arc below the boxes
      if (flow.to === 'reef') {
        // Lab → Reef: long arc below
        pathD = curvedPath(
          { x: fromPos.x + fromPos.w - 40, y: fromPos.y + collapsedH },
          { x: toPos.x + 40, y: toPos.y + collapsedH },
          'below', 50
        );
        labelPos = { x: (fromPos.x + fromPos.w + toPos.x) / 2, y: fromPos.y + collapsedH + 62 };
      } else {
        // Lab → Orchard: shorter arc below
        pathD = curvedPath(
          { x: fromPos.x + fromPos.w - 40, y: fromPos.y + collapsedH },
          { x: toPos.x + 40, y: toPos.y + collapsedH },
          'below', 30
        );
        labelPos = { x: (fromPos.x + fromPos.w + toPos.x) / 2, y: fromPos.y + collapsedH + 40 };
      }
    } else {
      // Transplant: orchard → reef, straight line through middle
      const midY = fromPos.y + collapsedH / 2;
      pathD = `M ${fromPos.x + fromPos.w} ${midY} L ${toPos.x} ${midY}`;
      labelPos = { x: (fromPos.x + fromPos.w + toPos.x) / 2, y: midY - 10 };
    }

    const flowG = flowGroup.append('g')
      .attr('class', `flow-group flow-${flow.id}`)
      .attr('data-pathways', flow.pathways.join(','))
      .attr('data-flow', flow.id);

    // Glow layer behind the arrow
    flowG.append('path')
      .attr('d', pathD)
      .attr('fill', 'none')
      .attr('stroke', colorMap[flow.type])
      .attr('stroke-width', 8)
      .attr('stroke-linecap', 'round')
      .attr('opacity', 0.1);

    flowG.append('path')
      .attr('class', `flow-arrow ${flow.type}`)
      .attr('d', pathD)
      .attr('marker-end', `url(#${markerMap[flow.type]})`);

    // Label with from→to context (shortened for transplant to avoid overlap with diamond)
    const fromName = locations[flow.from].name;
    const toName = locations[flow.to].name;
    const labelText = flow.type === 'transplant' ? flow.label : `${flow.label} (${fromName} → ${toName})`;
    flowG.append('text')
      .attr('class', 'arrow-label')
      .attr('x', labelPos.x)
      .attr('y', labelPos.y)
      .attr('text-anchor', 'middle')
      .attr('font-size', '11px')
      .attr('fill', colorMap[flow.type])
      .attr('font-weight', '600')
      .text(labelText);

    // Cost layer badge
    if (flow.costLayer) {
      flowG.append('text')
        .attr('class', 'cost-badge layer-costs')
        .attr('x', labelPos.x)
        .attr('y', labelPos.y + 14)
        .attr('text-anchor', 'middle')
        .text(`💰 ${flow.costLayer}`);
    }
  });
}

// ── Decision diamonds ───────────────────────
function drawDecisionDiamonds() {
  const decGroup = mainGroup.append('g').attr('class', 'decisions-group');
  const labPos = layout.locationPositions.lab;
  const orchPos = layout.locationPositions.orchard;
  const reefPos = layout.locationPositions.reef;
  const collapsedH = layout.LOC_COLLAPSED_H;
  const ds = layout.DIAMOND_SIZE;

  decisions.forEach(dec => {
    let cx, cy;
    const gap = orchPos.x - labPos.x - labPos.w;
    const gap2 = reefPos.x - orchPos.x - orchPos.w;

    if (dec.id === 'reef-prop') {
      // Between lab and orchard, below the outplanting flows
      cx = labPos.x + labPos.w + gap / 2;
      cy = labPos.y + collapsedH + 50;
    } else if (dec.id === 'lab-retain') {
      // Above lab box, centered horizontally
      cx = labPos.x + labPos.w / 2;
      cy = labPos.y - 34;
    } else {
      // Between orchard and reef, below transplant line
      cx = orchPos.x + orchPos.w + gap2 / 2;
      cy = orchPos.y + collapsedH + 20;
    }

    const decG = decGroup.append('g')
      .attr('class', 'decision-diamond')
      .attr('data-decision', dec.id)
      .attr('data-pathways', dec.pathways.join(','));

    decG.append('polygon')
      .attr('points', diamondPoints(cx, cy, ds));

    // Label below the diamond
    decG.append('text')
      .attr('class', 'decision-label')
      .attr('x', cx)
      .attr('y', cy + ds + 14)
      .text(dec.label);
  });
}

// ── External inputs ─────────────────────────
function drawExternalInputs() {
  const extGroup = mainGroup.append('g').attr('class', 'external-inputs-group');

  externalInputs.forEach(ext => {
    const targetPos = layout.locationPositions[ext.target];
    const extG = extGroup.append('g')
      .attr('class', 'external-input')
      .attr('data-pathways', ext.pathways.join(','))
      .attr('data-external', ext.id);

    if (ext.target === 'reef') {
      // Arrow entering reef from the right
      const entryX = targetPos.x + targetPos.w + 60;
      const entryY = targetPos.y + layout.LOC_COLLAPSED_H / 2 + 15;
      extG.append('line')
        .attr('x1', entryX).attr('y1', entryY)
        .attr('x2', targetPos.x + targetPos.w).attr('y2', entryY)
        .attr('marker-end', 'url(#arrowhead-external)');

      // Label above the arrow
      extG.append('text')
        .attr('class', 'external-label')
        .attr('x', targetPos.x + targetPos.w + 30)
        .attr('y', entryY - 8)
        .attr('text-anchor', 'middle')
        .text('Wild recruitment');
      extG.append('text')
        .attr('class', 'external-label')
        .attr('x', targetPos.x + targetPos.w + 30)
        .attr('y', entryY + 16)
        .attr('text-anchor', 'middle')
        .attr('font-size', '10px')
        .text('(λ) → SC1');
    } else {
      // Arrow entering lab from the left
      const entryX = targetPos.x - 60;
      const entryY = targetPos.y + layout.LOC_COLLAPSED_H / 2 + 15;
      extG.append('line')
        .attr('x1', entryX).attr('y1', entryY)
        .attr('x2', targetPos.x).attr('y2', entryY)
        .attr('marker-end', 'url(#arrowhead-external)');

      // Label above the arrow
      extG.append('text')
        .attr('class', 'external-label')
        .attr('x', targetPos.x - 30)
        .attr('y', entryY - 8)
        .attr('text-anchor', 'middle')
        .text('Ref. reef larvae');
      extG.append('text')
        .attr('class', 'external-label')
        .attr('x', targetPos.x - 30)
        .attr('y', entryY + 16)
        .attr('text-anchor', 'middle')
        .attr('font-size', '10px')
        .text('(λ_R)');
    }
  });
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
    const badgeY = pos.y - 10;
    stochSources.forEach((s, i) => {
      locGroup.append('text')
        .attr('class', 'stochasticity-badge layer-stochasticity')
        .attr('x', pos.x + 8 + i * 65)
        .attr('y', badgeY)
        .text(`±${s.param}`);
    });
  }

  // Density dependence badge (lab only)
  if (locId === 'lab') {
    locGroup.append('text')
      .attr('class', 'density-badge layer-density')
      .attr('x', pos.x + pos.w / 2)
      .attr('y', pos.y + layout.LOC_COLLAPSED_H + 16)
      .attr('text-anchor', 'middle')
      .text('Density dep: S = s_base × exp(-m × density)');
  }
}

// ── Legend ───────────────────────────────────
function drawLegend() {
  const legendG = mainGroup.append('g')
    .attr('class', 'legend')
    .attr('transform', `translate(${layout.locationPositions.lab.x}, ${layout.totalHeight - 80})`);

  legendG.append('text').attr('class', 'legend-title').attr('y', 0).text('Arrow Legend');

  const items = [
    { color: '#22c55e', label: 'Growth (→ larger class)', dash: '' },
    { color: '#ef4444', label: 'Shrinkage (→ smaller class)', dash: '' },
    { color: '#C084FC', label: 'Fragmentation (asexual)', dash: '4,3' },
    { color: '#FBBF24', label: 'Fecundity (larvae)', dash: '6,3' },
    { color: '#A78BFA', label: 'Larvae collection', dash: '' },
    { color: '#FBBF24', label: 'Outplanting', dash: '' },
    { color: '#34D399', label: 'Transplanting', dash: '' },
    { color: '#64748B', label: 'External input', dash: '6,4' },
  ];

  items.forEach((item, i) => {
    const col = Math.floor(i / 4);
    const row = i % 4;
    const x = col * 280;
    const y = 18 + row * 18;

    legendG.append('line')
      .attr('x1', x).attr('y1', y)
      .attr('x2', x + 30).attr('y2', y)
      .attr('stroke', item.color)
      .attr('stroke-width', 2)
      .attr('stroke-dasharray', item.dash);

    legendG.append('text')
      .attr('x', x + 36)
      .attr('y', y + 4)
      .text(item.label);
  });
}

// ── Core equation badge ─────────────────────
function drawEquationBadge() {
  const eqG = mainGroup.append('g')
    .attr('class', 'equation-group')
    .attr('data-tooltip-title', 'Core Equation')
    .attr('data-tooltip-body', annualCycle.map(s => `Step ${s.step}: ${s.name} — ${s.desc}`).join('\n'));

  const x = layout.locationPositions.orchard.x;
  const y = layout.totalHeight - 30;

  eqG.append('rect')
    .attr('x', x - 8)
    .attr('y', y - 16)
    .attr('width', 310)
    .attr('height', 28)
    .attr('rx', 6).attr('ry', 6)
    .attr('fill', 'rgba(15, 23, 42, 0.5)')
    .attr('stroke', 'rgba(255, 255, 255, 0.06)');

  eqG.append('text')
    .attr('class', 'equation-badge')
    .attr('x', x)
    .attr('y', y)
    .text(coreEquation);

  eqG.append('text')
    .attr('x', x)
    .attr('y', y + 18)
    .attr('font-size', '9px')
    .attr('fill', '#64748B')
    .attr('font-family', "'DM Sans', sans-serif")
    .text('hover for annual cycle details');
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
    hint.text('click to collapse');
  } else {
    detail.classed('expanded', false);
    hint.text('click to expand');
  }

  // Update disturbance indicator height too
  const distRect = locGroup.select('.disturbance-indicator');
  if (!distRect.empty()) {
    distRect.transition().duration(400)
      .attr('height', (isExpanded ? layout.LOC_EXPANDED_H : layout.LOC_COLLAPSED_H) + 8);
  }
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

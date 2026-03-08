// Layout calculations — TRIANGULAR LAYOUT
// Lab at top-center, Orchard bottom-left, Reef bottom-right

const LOC_WIDTH = 300;
const LOC_COLLAPSED_H = 90;
const LOC_EXPANDED_H = 440;
const SC_NODE_H = 46;
const SC_NODE_W = 240;
const SC_GAP = 10;
const SC_PAD_TOP = 85;
const SC_PAD_LEFT = 30;
const DIAMOND_SIZE = 24;

export function computeLayout(width) {
  // Bottom row positioning — tightened for 1080p viewport
  const orchardX = 60;
  const reefX = 600;
  const bottomRowY = 470;

  // Lab centered above the midpoint of Orchard and Reef
  const bottomCenterX = (orchardX + LOC_WIDTH / 2 + reefX + LOC_WIDTH / 2) / 2;
  const labX = bottomCenterX - LOC_WIDTH / 2;
  const labY = 40;

  const locationPositions = {
    lab:     { x: labX,     y: labY,       w: LOC_WIDTH },
    orchard: { x: orchardX, y: bottomRowY, w: LOC_WIDTH },
    reef:    { x: reefX,    y: bottomRowY, w: LOC_WIDTH },
  };

  const totalWidth = reefX + LOC_WIDTH + 180;
  const totalHeight = bottomRowY + LOC_EXPANDED_H + 100;
  const collapsedHeight = bottomRowY + LOC_COLLAPSED_H + 120; // compact viewBox when collapsed

  return {
    locationPositions,
    LOC_WIDTH,
    LOC_COLLAPSED_H,
    LOC_EXPANDED_H,
    SC_NODE_H,
    SC_NODE_W,
    SC_GAP,
    SC_PAD_TOP,
    SC_PAD_LEFT,
    DIAMOND_SIZE,
    totalWidth,
    totalHeight,
    collapsedHeight,
  };
}

// Get position of a size class node within an expanded location
export function scNodePos(locPos, scIndex, layout) {
  // SC1 at bottom, SC5 at top -> reverse index
  const reversedIdx = 4 - scIndex;
  return {
    x: locPos.x + layout.SC_PAD_LEFT,
    y: locPos.y + layout.SC_PAD_TOP + reversedIdx * (layout.SC_NODE_H + layout.SC_GAP),
    w: layout.SC_NODE_W,
    h: layout.SC_NODE_H,
  };
}

// Get the current height of a location box
export function getLocHeight(locId, expandedState, layout) {
  return expandedState[locId] ? layout.LOC_EXPANDED_H : layout.LOC_COLLAPSED_H;
}

// Get center point of a location box
export function locCenter(locPos, height) {
  return {
    x: locPos.x + locPos.w / 2,
    y: locPos.y + height / 2,
  };
}

// Get edge midpoints of a location box
export function locEdges(locPos, height) {
  return {
    left:   { x: locPos.x,              y: locPos.y + height / 2 },
    right:  { x: locPos.x + locPos.w,   y: locPos.y + height / 2 },
    top:    { x: locPos.x + locPos.w / 2, y: locPos.y },
    bottom: { x: locPos.x + locPos.w / 2, y: locPos.y + height },
  };
}

// Generate curved path between two points
export function curvedPath(from, to, curveDir = 'above', offset = 50) {
  const midX = (from.x + to.x) / 2;
  const midY = (from.y + to.y) / 2;
  // For diagonal paths, offset perpendicular to the line
  const cpX = midX + (curveDir === 'left' ? -offset : curveDir === 'right' ? offset : 0);
  const cpY = curveDir === 'above' ? Math.min(from.y, to.y) - offset
            : curveDir === 'below' ? Math.max(from.y, to.y) + offset
            : midY;
  return `M ${from.x} ${from.y} Q ${cpX} ${cpY} ${to.x} ${to.y}`;
}

// Diamond points for a decision node centered at (cx, cy)
export function diamondPoints(cx, cy, size) {
  return [
    [cx, cy - size],      // top
    [cx + size, cy],      // right
    [cx, cy + size],      // bottom
    [cx - size, cy],      // left
  ].map(p => p.join(',')).join(' ');
}

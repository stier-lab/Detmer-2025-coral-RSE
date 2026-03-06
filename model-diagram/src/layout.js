// Layout calculations — positions for all diagram elements

const PADDING = 24;
const LOC_WIDTH = 300;
const LOC_GAP = 160;
const LOC_COLLAPSED_H = 80;
const LOC_EXPANDED_H = 540;
const SC_NODE_H = 52;
const SC_NODE_W = 240;
const SC_GAP = 14;
const SC_PAD_TOP = 70;
const SC_PAD_LEFT = 30;
const DIAMOND_SIZE = 22;

export function computeLayout(width) {
  const totalLocWidth = 3 * LOC_WIDTH + 2 * LOC_GAP;
  // Extra left margin for external label, extra right for wild recruitment label + equation
  const marginLeft = 160;
  const marginRight = 220;
  const startX = marginLeft;
  const startY = 80; // room above for collection arc labels

  const locationPositions = {
    lab:     { x: startX,                          y: startY, w: LOC_WIDTH },
    orchard: { x: startX + LOC_WIDTH + LOC_GAP,    y: startY, w: LOC_WIDTH },
    reef:    { x: startX + 2 * (LOC_WIDTH + LOC_GAP), y: startY, w: LOC_WIDTH },
  };

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
    totalWidth: marginLeft + totalLocWidth + marginRight,
    totalHeight: LOC_EXPANDED_H + startY + 120,
  };
}

// Get position of a size class node within an expanded location
export function scNodePos(locPos, scIndex, layout) {
  // SC1 at bottom, SC5 at top → reverse index
  const reversedIdx = 4 - scIndex;
  return {
    x: locPos.x + layout.SC_PAD_LEFT,
    y: locPos.y + layout.SC_PAD_TOP + reversedIdx * (layout.SC_NODE_H + layout.SC_GAP),
    w: layout.SC_NODE_W,
    h: layout.SC_NODE_H,
  };
}

// Get center point of a location box (collapsed)
export function locCenter(locPos, collapsed) {
  const h = collapsed ? LOC_COLLAPSED_H : LOC_EXPANDED_H;
  return {
    x: locPos.x + locPos.w / 2,
    y: locPos.y + h / 2,
  };
}

// Get edge midpoints of a location box for arrow connections
export function locEdges(locPos, collapsed) {
  const h = collapsed ? LOC_COLLAPSED_H : LOC_EXPANDED_H;
  return {
    left:   { x: locPos.x,              y: locPos.y + h / 2 },
    right:  { x: locPos.x + locPos.w,   y: locPos.y + h / 2 },
    top:    { x: locPos.x + locPos.w / 2, y: locPos.y },
    bottom: { x: locPos.x + locPos.w / 2, y: locPos.y + h },
  };
}

// Generate curved path between two points (for inter-location flows)
export function curvedPath(from, to, curveDir = 'above', offset = 50) {
  const midX = (from.x + to.x) / 2;
  const cpY = curveDir === 'above' ? Math.min(from.y, to.y) - offset : Math.max(from.y, to.y) + offset;
  return `M ${from.x} ${from.y} Q ${midX} ${cpY} ${to.x} ${to.y}`;
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

# React Flow Diagram Improvements (Gemini Critique)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Apply the top improvements from the Gemini multi-model critique: click-to-expand detail panels, path highlighting on click, larger text, node icons, and improved layout spacing.

**Architecture:** Five independent improvements to the existing React Flow diagram. Each task modifies specific files without breaking others. The diagram keeps its three detail levels but the "Full Model" level becomes click-to-expand panels rather than inline size classes. A new selectedNodeId state drives path highlighting. Layout positions are widened for better left-to-right narrative flow.

**Tech Stack:** @xyflow/react v12, React 19, TypeScript, Tailwind CSS

---

## Task 1: Widen layout positions for clearer left-to-right narrative flow

**Files:**
- Modify: `coral-app/src/components/diagram/hooks/useDiagramLayout.ts`
- Test: `coral-app/src/components/diagram/hooks/useDiagramLayout.test.ts`

The current POSITIONS constant has nodes cramped in a narrow range (x: 30-760). Widen the spread to use more horizontal space and establish a clear left→right narrative: Wild Sources → Lab → Decision → Orchard/Reef.

- [ ] **Step 1: Update POSITIONS constant**

In `coral-app/src/components/diagram/hooks/useDiagramLayout.ts`, replace the POSITIONS constant:

```ts
const POSITIONS = {
  extReefs:        { x: 0,   y: 200 },
  lab:             { x: 300, y: 250 },
  decision:        { x: 620, y: 260 },
  reef:            { x: 950, y: 150 },
  orchard:         { x: 620, y: 500 },
  wildRecruitment: { x: 950, y: 0 },
};
```

- [ ] **Step 2: Run existing tests**

Run: `cd coral-app && npx vitest run src/components/diagram/hooks/useDiagramLayout.test.ts`
Expected: All tests pass (tests check node/edge counts, not exact positions).

- [ ] **Step 3: Verify build**

Run: `cd coral-app && npm run build`
Expected: Build succeeds.

- [ ] **Step 4: Commit**

```bash
git add coral-app/src/components/diagram/hooks/useDiagramLayout.ts
git commit -m "style: widen diagram layout for clearer left-to-right flow"
```

---

## Task 2: Increase text sizes for edge labels, node subtitles, and parameters

**Files:**
- Modify: `coral-app/src/components/diagram/diagram-theme.css`
- Modify: `coral-app/src/components/diagram/nodes/CompartmentNode.tsx`
- Modify: `coral-app/src/components/diagram/nodes/ExternalNode.tsx`
- Modify: `coral-app/src/components/diagram/nodes/DecisionNode.tsx`

Gemini critique: "Make all text labels at least 25% larger, especially on the edges."

- [ ] **Step 1: Increase edge label pill font size in CSS**

In `coral-app/src/components/diagram/diagram-theme.css`, find the `.edge-label-pill` rule and change:

```css
.edge-label-pill {
  /* ... existing styles ... */
  font-size: 12px;  /* was 11px */
  padding: 4px 10px;  /* was 3px 8px */
}
```

- [ ] **Step 2: Increase cost badge font size**

In the same CSS file, find `.cost-badge` and change:

```css
.cost-badge {
  /* ... existing styles ... */
  font-size: 10px;  /* was 9px */
}
```

- [ ] **Step 3: Increase CompartmentNode text sizes**

In `coral-app/src/components/diagram/nodes/CompartmentNode.tsx`:

Change the label fontSize from 15 to 17:
```tsx
<div style={{ color: nodeData.color, fontWeight: 700, fontSize: 17, fontFamily: 'Crimson Pro, serif' }}>
```

Change the subtitle fontSize from 11 to 13:
```tsx
<div style={{ color: 'rgba(255,255,255,0.5)', fontSize: 13, marginTop: 2 }}>
```

Change parameter name/value fontSize from 10 to 11 (both spans):
```tsx
<span style={{ color: '#FDE047', fontFamily: 'JetBrains Mono, monospace', fontSize: 11 }}>
```
```tsx
<span style={{ color: 'rgba(255,255,255,0.6)', fontFamily: 'JetBrains Mono, monospace', fontSize: 11 }}>
```

- [ ] **Step 4: Increase ExternalNode text sizes**

In `coral-app/src/components/diagram/nodes/ExternalNode.tsx`:

Change label fontSize from 12 to 14:
```tsx
<div style={{ fontWeight: 600, fontSize: 14, fontFamily: 'Crimson Pro, serif' }}>
```

Change subtitle fontSize from 10 to 12:
```tsx
<div style={{ fontSize: 12, opacity: 0.6, marginTop: 1 }}>
```

- [ ] **Step 5: Increase DecisionNode text sizes**

In `coral-app/src/components/diagram/nodes/DecisionNode.tsx`:

Change label fontSize from 10 to 12:
```tsx
<div style={{ fontSize: 12, opacity: 0.7 }}>{nodeData.label}</div>
```

Change parameter fontSize from 11 to 12:
```tsx
<div style={{ fontFamily: 'JetBrains Mono, monospace', fontSize: 12, marginTop: 2 }}>
```

Change value fontSize from 13 to 15:
```tsx
<div style={{ fontSize: 15, fontWeight: 700, marginTop: 1 }}>
```

- [ ] **Step 6: Verify build and run tests**

Run: `cd coral-app && npx vitest run && npm run build`
Expected: All tests pass, build succeeds.

- [ ] **Step 7: Commit**

```bash
git add coral-app/src/components/diagram/
git commit -m "style: increase text sizes across diagram nodes and edges"
```

---

## Task 3: Add SVG icons to compartment and external nodes

**Files:**
- Create: `coral-app/src/components/diagram/nodes/NodeIcons.tsx`
- Modify: `coral-app/src/components/diagram/nodes/CompartmentNode.tsx`
- Modify: `coral-app/src/components/diagram/nodes/ExternalNode.tsx`

Gemini critique: "Replace colored squares with simple, meaningful icons for Lab, Orchard, Reef."

- [ ] **Step 1: Create NodeIcons component with SVG icons**

Create `coral-app/src/components/diagram/nodes/NodeIcons.tsx`:

```tsx
import React from 'react';

interface IconProps {
  size?: number;
  color?: string;
}

/** Microscope / flask for Lab */
export const LabIcon: React.FC<IconProps> = ({ size = 20, color = '#F59E0B' }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth={2} strokeLinecap="round" strokeLinejoin="round">
    <path d="M9 3h6v8l4 7H5l4-7V3z" />
    <path d="M9 3h6" />
    <circle cx="12" cy="15" r="1" fill={color} />
  </svg>
);

/** Branching coral / tree for Orchard */
export const OrchardIcon: React.FC<IconProps> = ({ size = 20, color = '#10B981' }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth={2} strokeLinecap="round" strokeLinejoin="round">
    <path d="M12 22V8" />
    <path d="M8 12l4-4 4 4" />
    <path d="M6 8l6-6 6 6" />
    <path d="M9 22h6" />
  </svg>
);

/** Coral colony / reef for Reef */
export const ReefIcon: React.FC<IconProps> = ({ size = 20, color = '#38BDF8' }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth={2} strokeLinecap="round" strokeLinejoin="round">
    <path d="M6 20c0-4 2-6 2-10a4 4 0 1 1 8 0c0 4 2 6 2 10" />
    <path d="M12 10c0 4 2 6 2 10" />
    <path d="M12 10c0 4-2 6-2 10" />
    <line x1="4" y1="20" x2="20" y2="20" />
  </svg>
);

/** Waves for External Reefs */
export const WavesIcon: React.FC<IconProps> = ({ size = 18, color = '#64748B' }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth={2} strokeLinecap="round" strokeLinejoin="round">
    <path d="M2 6c.6.5 1.2 1 2.5 1C7 7 7 5 9.5 5c2.6 0 2.4 2 5 2 2.5 0 2.5-2 5-2 1.3 0 1.9.5 2.5 1" />
    <path d="M2 12c.6.5 1.2 1 2.5 1 2.5 0 2.5-2 5-2 2.6 0 2.4 2 5 2 2.5 0 2.5-2 5-2 1.3 0 1.9.5 2.5 1" />
    <path d="M2 18c.6.5 1.2 1 2.5 1 2.5 0 2.5-2 5-2 2.6 0 2.4 2 5 2 2.5 0 2.5-2 5-2 1.3 0 1.9.5 2.5 1" />
  </svg>
);
```

- [ ] **Step 2: Add icon to CompartmentNode**

In `coral-app/src/components/diagram/nodes/CompartmentNode.tsx`, add import at top:

```tsx
import { LabIcon, OrchardIcon, ReefIcon } from './NodeIcons';
```

Add an ICON_MAP constant after COMPARTMENT_STYLES:

```tsx
const ICON_MAP: Record<string, React.FC<{ size?: number; color?: string }>> = {
  lab: LabIcon,
  orchard: OrchardIcon,
  reef: ReefIcon,
};
```

Inside the component, before the label div, add the icon:

```tsx
const Icon = ICON_MAP[nodeData.compartmentId];
```

Replace the label div with a row containing icon + label:

```tsx
<div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
  {Icon && <Icon size={20} color={nodeData.color} />}
  <div style={{ color: nodeData.color, fontWeight: 700, fontSize: 17, fontFamily: 'Crimson Pro, serif' }}>
    {nodeData.label}
  </div>
</div>
```

- [ ] **Step 3: Add icon to ExternalNode**

In `coral-app/src/components/diagram/nodes/ExternalNode.tsx`, add import:

```tsx
import { WavesIcon } from './NodeIcons';
```

Replace the label div with a row containing icon + label:

```tsx
<div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
  <WavesIcon size={16} color="#64748B" />
  <div style={{ fontWeight: 600, fontSize: 14, fontFamily: 'Crimson Pro, serif' }}>
    {nodeData.label}
  </div>
</div>
```

- [ ] **Step 4: Verify build and tests**

Run: `cd coral-app && npx vitest run && npm run build`
Expected: All pass.

- [ ] **Step 5: Commit**

```bash
git add coral-app/src/components/diagram/nodes/
git commit -m "feat: add SVG icons to diagram nodes (lab flask, orchard coral, reef, waves)"
```

---

## Task 4: Add click-to-select with path highlighting

**Files:**
- Modify: `coral-app/src/components/diagram/types.ts`
- Modify: `coral-app/src/components/diagram/ModelDiagram.tsx`
- Modify: `coral-app/src/components/diagram/hooks/useDiagramLayout.ts`
- Modify: `coral-app/src/components/diagram/nodes/CompartmentNode.tsx`
- Modify: `coral-app/src/components/diagram/nodes/ExternalNode.tsx`
- Modify: `coral-app/src/components/diagram/nodes/DecisionNode.tsx`
- Modify: `coral-app/src/components/diagram/edges/FlowEdge.tsx`
- Modify: `coral-app/src/components/diagram/diagram-theme.css`

When a user clicks any node, highlight it and all edges connected to it (upstream and downstream). Dim everything else. Click again or click background to deselect.

- [ ] **Step 1: Add selectedNodeId to CompartmentNodeData and other node data types**

In `coral-app/src/components/diagram/types.ts`, add `selectedNodeId` to all node data interfaces:

```ts
export interface CompartmentNodeData {
  [key: string]: unknown;
  compartmentId: 'lab' | 'orchard' | 'reef';
  label: string;
  subtitle: string;
  color: string;
  detailLevel: DetailLevel;
  layers: LayerState;
  selectedNodeId: string | null;
  parameters?: { name: string; value: string; description: string }[];
  sizeClasses?: { id: string; range: string; survival: number; fecundity: number; color: string }[];
}

export interface ExternalNodeData {
  [key: string]: unknown;
  label: string;
  subtitle: string;
  type: 'external-reefs' | 'wild-recruitment';
  selectedNodeId: string | null;
}

export interface DecisionNodeData {
  [key: string]: unknown;
  label: string;
  parameter: string;
  value: string;
  detailLevel: DetailLevel;
  selectedNodeId: string | null;
}

export interface FlowEdgeData {
  [key: string]: unknown;
  label: string;
  flowType: 'collection' | 'outplanting' | 'transplanting' | 'external' | 'feedback';
  color: string;
  animated: boolean;
  cost?: string;
  showCost: boolean;
  dimmed: boolean;
}
```

- [ ] **Step 2: Update buildDiagramLayout to accept and propagate selectedNodeId**

In `coral-app/src/components/diagram/hooks/useDiagramLayout.ts`, update the function signature:

```ts
export function buildDiagramLayout(
  detailLevel: DetailLevel,
  layers: LayerState,
  selectedNodeId: string | null = null
): { nodes: DiagramNode[]; edges: DiagramEdge[] } {
```

Add `selectedNodeId` to every node's data object. For each node definition, add:
```ts
selectedNodeId,
```

For edges, compute which edges connect to the selected node. After building the edges array, add dimming logic:

```ts
  // Compute connected edge IDs for the selected node
  const connectedEdgeIds = selectedNodeId
    ? new Set(edges.filter(e => e.source === selectedNodeId || e.target === selectedNodeId).map(e => e.id))
    : null;

  // Apply dimming to edges not connected to selected node
  const finalEdges = edges.map(e => ({
    ...e,
    data: {
      ...e.data,
      dimmed: connectedEdgeIds ? !connectedEdgeIds.has(e.id) : false,
    },
  })) as DiagramEdge[];

  return { nodes, edges: finalEdges };
```

Update the hook to accept selectedNodeId:

```ts
export function useDiagramLayout(detailLevel: DetailLevel, layers: LayerState, selectedNodeId: string | null = null) {
  return useMemo(
    () => buildDiagramLayout(detailLevel, layers, selectedNodeId),
    [detailLevel, layers, selectedNodeId]
  );
}
```

- [ ] **Step 3: Add selectedNodeId state and click handlers to ModelDiagram**

In `coral-app/src/components/diagram/ModelDiagram.tsx`, add state:

```tsx
const [selectedNodeId, setSelectedNodeId] = useState<string | null>(null);
```

Pass it to the layout hook:
```tsx
const layout = useDiagramLayout(detailLevel, layers, selectedNodeId);
```

Enable element selection and add click handler to ReactFlow:
```tsx
<ReactFlow
  ...
  elementsSelectable={true}
  onNodeClick={(_event, node) => {
    setSelectedNodeId(prev => prev === node.id ? null : node.id);
  }}
  onPaneClick={() => setSelectedNodeId(null)}
>
```

- [ ] **Step 4: Dim non-selected nodes in CompartmentNode**

In `coral-app/src/components/diagram/nodes/CompartmentNode.tsx`, add opacity logic after extracting nodeData:

```tsx
const isSelected = nodeData.selectedNodeId === null || nodeData.selectedNodeId === undefined;
const isThisNode = (data as any).compartmentId; // we need the node ID, but we don't have it directly
```

Actually, simpler approach — use CSS. Add a dimming style to the outer div when `selectedNodeId` is set and this node is not the selected one. Since nodes don't know their own ID directly from props in this pattern, we pass the info through data:

Add to every node's data in `useDiagramLayout.ts`:
```ts
isHighlighted: selectedNodeId === null || selectedNodeId === '<nodeId>',
```

where `<nodeId>` is the actual node ID (e.g., 'lab', 'reef', etc.). Also mark nodes as highlighted if they are connected to the selected node via any edge.

Better approach — compute connected node IDs:

```ts
const connectedNodeIds = selectedNodeId
  ? new Set([
      selectedNodeId,
      ...edges.filter(e => e.source === selectedNodeId || e.target === selectedNodeId)
        .flatMap(e => [e.source, e.target]),
    ])
  : null;
```

Then for each node, add `isHighlighted`:
```ts
isHighlighted: connectedNodeIds === null || connectedNodeIds.has('<nodeId>'),
```

In `CompartmentNode.tsx`, read `isHighlighted` from data and apply opacity:

```tsx
const isHighlighted = (nodeData as any).isHighlighted !== false;
```

Add to outer div style:
```tsx
style={{
  ...existingStyles,
  opacity: isHighlighted ? 1 : 0.25,
  transition: 'opacity 0.3s ease',
}}
```

Do the same for ExternalNode and DecisionNode.

- [ ] **Step 5: Dim non-connected edges in FlowEdge**

In `coral-app/src/components/diagram/edges/FlowEdge.tsx`, read dimmed from data:

```tsx
const dimmed = edgeData?.dimmed ?? false;
```

Apply to the main edge stroke and glow:
```tsx
<path d={edgePath} fill="none" stroke={color} strokeWidth={8} strokeOpacity={dimmed ? 0.02 : 0.1} />
```

And on the BaseEdge style:
```tsx
style={{
  stroke: color,
  strokeWidth: 2,
  strokeDasharray: isDashed ? '6 4' : undefined,
  opacity: dimmed ? 0.15 : 1,
  transition: 'opacity 0.3s ease',
}}
```

Hide animated particles when dimmed:
```tsx
{edgeData?.animated && !dimmed && (
```

- [ ] **Step 6: Add cursor pointer to nodes via CSS**

In `coral-app/src/components/diagram/diagram-theme.css`:

```css
.compartment-node,
.external-node,
.decision-node {
  cursor: pointer;
}
```

- [ ] **Step 7: Update tests for new selectedNodeId parameter**

In `coral-app/src/components/diagram/hooks/useDiagramLayout.test.ts`, the existing `buildDiagramLayout(level, layers)` calls will still work since `selectedNodeId` defaults to `null`. But add one test:

```ts
it('dims edges when a node is selected', () => {
  const { edges } = buildDiagramLayout('story', { costs: false, disturbance: false, stochasticity: false }, 'lab');
  const connectedToLab = edges.filter((e: any) => e.source === 'lab' || e.target === 'lab');
  const notConnected = edges.filter((e: any) => e.source !== 'lab' && e.target !== 'lab');
  connectedToLab.forEach((e: any) => expect(e.data.dimmed).toBe(false));
  notConnected.forEach((e: any) => expect(e.data.dimmed).toBe(true));
});
```

- [ ] **Step 8: Run all tests and verify build**

Run: `cd coral-app && npx vitest run && npm run build`
Expected: All tests pass, build succeeds.

- [ ] **Step 9: Commit**

```bash
git add coral-app/src/components/diagram/
git commit -m "feat: add click-to-select with path highlighting on diagram nodes"
```

---

## Task 5: Replace inline Full Model details with click-to-expand detail panel

**Files:**
- Create: `coral-app/src/components/diagram/DetailPanel.tsx`
- Modify: `coral-app/src/components/diagram/ModelDiagram.tsx`
- Modify: `coral-app/src/components/diagram/nodes/CompartmentNode.tsx`
- Modify: `coral-app/src/components/diagram/diagram-theme.css`

Gemini critique: "Remove the Full Model view entirely. Move detailed demographic information into a modal or side panel that appears when a user clicks on a node."

We keep the Full Model tab but instead of cramming size classes into nodes, clicking a node in Decision or Full Model mode opens a detail panel on the right.

- [ ] **Step 1: Create DetailPanel component**

Create `coral-app/src/components/diagram/DetailPanel.tsx`:

```tsx
import React from 'react';
import type { CompartmentNodeData } from './types';

interface Props {
  nodeData: CompartmentNodeData | null;
  onClose: () => void;
}

export default function DetailPanel({ nodeData, onClose }: Props) {
  if (!nodeData) return null;

  return (
    <div className="detail-panel">
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
        <div style={{ color: nodeData.color, fontWeight: 700, fontSize: 18, fontFamily: 'Crimson Pro, serif' }}>
          {nodeData.label}
        </div>
        <button
          onClick={onClose}
          style={{
            background: 'rgba(255,255,255,0.1)',
            border: 'none',
            color: 'rgba(255,255,255,0.6)',
            borderRadius: 6,
            padding: '4px 8px',
            cursor: 'pointer',
            fontSize: 12,
          }}
        >
          Close
        </button>
      </div>
      <div style={{ color: 'rgba(255,255,255,0.5)', fontSize: 13, marginBottom: 16 }}>
        {nodeData.subtitle}
      </div>

      {nodeData.parameters && (
        <div style={{ marginBottom: 16 }}>
          <div style={{ color: 'rgba(255,255,255,0.4)', fontSize: 10, textTransform: 'uppercase', letterSpacing: 1, marginBottom: 8 }}>
            Parameters
          </div>
          {nodeData.parameters.map((p) => (
            <div key={p.name} style={{ display: 'flex', justifyContent: 'space-between', padding: '6px 0', borderBottom: '1px solid rgba(255,255,255,0.06)' }}>
              <div>
                <span style={{ color: '#FDE047', fontFamily: 'JetBrains Mono, monospace', fontSize: 12 }}>
                  {p.name}
                </span>
                <span style={{ color: 'rgba(255,255,255,0.35)', fontSize: 11, marginLeft: 8 }}>
                  {p.description}
                </span>
              </div>
              <span style={{ color: 'rgba(255,255,255,0.7)', fontFamily: 'JetBrains Mono, monospace', fontSize: 12 }}>
                {p.value}
              </span>
            </div>
          ))}
        </div>
      )}

      {nodeData.sizeClasses && (
        <div>
          <div style={{ color: 'rgba(255,255,255,0.4)', fontSize: 10, textTransform: 'uppercase', letterSpacing: 1, marginBottom: 8 }}>
            Size Classes
          </div>
          {nodeData.sizeClasses.map((sc) => (
            <div key={sc.id} style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '6px 0', borderBottom: '1px solid rgba(255,255,255,0.06)' }}>
              <div style={{ width: 4, height: 24, borderRadius: 2, background: sc.color }} />
              <div style={{ flex: 1 }}>
                <div style={{ fontWeight: 600, fontSize: 12 }}>{sc.id}</div>
                <div style={{ color: 'rgba(255,255,255,0.4)', fontSize: 11 }}>{sc.range}</div>
              </div>
              <div style={{ textAlign: 'right', fontSize: 11, fontFamily: 'JetBrains Mono, monospace' }}>
                <div style={{ color: 'rgba(255,255,255,0.6)' }}>surv: {sc.survival}</div>
                {sc.fecundity > 0 && (
                  <div style={{ color: '#FB923C' }}>fec: {sc.fecundity.toLocaleString()}</div>
                )}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
```

- [ ] **Step 2: Add detail-panel CSS**

In `coral-app/src/components/diagram/diagram-theme.css`, add:

```css
.detail-panel {
  position: absolute;
  top: 12px;
  right: 12px;
  width: 300px;
  max-height: calc(100% - 24px);
  overflow-y: auto;
  background: rgba(15, 23, 42, 0.95);
  backdrop-filter: blur(16px);
  border: 1px solid rgba(148, 163, 184, 0.2);
  border-radius: 12px;
  padding: 20px;
  z-index: 20;
  font-size: 12px;
  color: rgba(255, 255, 255, 0.8);
}
```

- [ ] **Step 3: Remove inline size classes from CompartmentNode**

In `coral-app/src/components/diagram/nodes/CompartmentNode.tsx`, remove the entire size classes rendering block (the `{nodeData.detailLevel === 'full' && nodeData.sizeClasses && (` ... `)}` section). Parameters stay inline (they're compact enough). Only size classes move to the panel.

- [ ] **Step 4: Wire DetailPanel into ModelDiagram**

In `coral-app/src/components/diagram/ModelDiagram.tsx`:

Import:
```tsx
import DetailPanel from './DetailPanel';
import type { CompartmentNodeData } from './types';
```

Add state for the selected node's data:
```tsx
const [panelData, setPanelData] = useState<CompartmentNodeData | null>(null);
```

Update the `onNodeClick` handler to also set panel data:
```tsx
onNodeClick={(_event, node) => {
  setSelectedNodeId(prev => prev === node.id ? null : node.id);
  if (node.type === 'compartment') {
    setPanelData(prev => prev && selectedNodeId === node.id ? null : node.data as unknown as CompartmentNodeData);
  } else {
    setPanelData(null);
  }
}}
onPaneClick={() => {
  setSelectedNodeId(null);
  setPanelData(null);
}}
```

Add DetailPanel to the JSX, replacing the Legend position (move Legend left when panel is open):
```tsx
{panelData ? (
  <DetailPanel nodeData={panelData} onClose={() => { setPanelData(null); setSelectedNodeId(null); }} />
) : (
  <div style={{ position: 'absolute', top: 12, right: 12, zIndex: 10 }}>
    <Legend detailLevel={detailLevel} />
  </div>
)}
```

- [ ] **Step 5: Run all tests and verify build**

Run: `cd coral-app && npx vitest run && npm run build`
Expected: All tests pass, build succeeds.

- [ ] **Step 6: Commit**

```bash
git add coral-app/src/components/diagram/
git commit -m "feat: add click-to-expand detail panel, remove inline size classes from nodes"
```

---

## Self-Review Checklist

1. **Spec coverage:**
   - [x] Click-to-expand detail panels (Task 5)
   - [x] Path highlighting on click (Task 4)
   - [x] Larger text (Task 2)
   - [x] Node icons (Task 3)
   - [x] Better layout spacing (Task 1)

2. **Placeholder scan:** No TBD/TODO items. All steps have code.

3. **Type consistency:**
   - `selectedNodeId: string | null` -- used consistently in types, layout hook, and ModelDiagram
   - `isHighlighted: boolean` -- added to node data, read by node components
   - `dimmed: boolean` -- added to FlowEdgeData, read by FlowEdge
   - `CompartmentNodeData` has new `selectedNodeId` field -- passed from layout hook
   - `DetailPanel` receives `CompartmentNodeData | null` -- matches ModelDiagram state

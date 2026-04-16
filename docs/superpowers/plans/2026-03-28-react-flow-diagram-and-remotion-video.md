# Interactive Model Diagram (React Flow) + Animation Video (Remotion)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build an interactive React Flow diagram of the coral RSE model inside coral-app/ (replacing the standalone D3 model-diagram/), then create a Remotion animation video reusing the same visual language.

**Architecture:** The diagram is a new "Diagram" tab in the existing coral-app. It uses React Flow (@xyflow/react v12) with custom nodes for compartments (Lab, Orchard, Reef), external sources, and a decision diamond. Three detail levels (Story, Decision, Full Model) progressively reveal complexity. The Remotion video (Phase B) is a separate `remotion/` directory that renders the same layout as animated sequences.

**Tech Stack:** @xyflow/react (React Flow 12), Remotion 4, React 19, TypeScript, Tailwind CSS, Vitest

---

## File Structure

### New files

```
coral-app/src/components/diagram/
├── ModelDiagram.tsx              # Main React Flow wrapper with controls
├── ModelDiagram.test.tsx         # Integration tests for the diagram
├── diagram-theme.css             # Dark ocean theme CSS for diagram container
├── types.ts                      # DetailLevel, LayerState, custom node/edge types
├── nodes/
│   ├── CompartmentNode.tsx       # Lab/Orchard/Reef compartment (collapsed + expanded)
│   ├── ExternalNode.tsx          # External Reefs, Wild Recruitment (small)
│   └── DecisionNode.tsx          # Diamond shape for reef_prop decision
├── edges/
│   └── FlowEdge.tsx              # Animated particle edge between compartments
├── hooks/
│   ├── useDiagramLayout.ts       # Generates nodes + edges for current detail level
│   └── useDiagramLayout.test.ts  # Unit tests for layout generation
├── DetailToggle.tsx              # Story | Decision | Full Model toggle
├── LayerToggles.tsx              # Disturbance, Costs, Stochasticity checkboxes
└── Legend.tsx                    # Dynamic legend keyed to detail level
```

### Modified files

```
coral-app/package.json            # Add @xyflow/react dependency
coral-app/src/App.tsx             # Add "Diagram" tab, import ModelDiagram
```

---

## Phase A: React Flow Interactive Diagram

### Task 1: Install React Flow and scaffold diagram shell

**Files:**
- Modify: `coral-app/package.json`
- Create: `coral-app/src/components/diagram/types.ts`
- Create: `coral-app/src/components/diagram/diagram-theme.css`
- Create: `coral-app/src/components/diagram/ModelDiagram.tsx`
- Modify: `coral-app/src/App.tsx`

- [ ] **Step 1: Install @xyflow/react**

Run: `cd coral-app && npm install @xyflow/react`

- [ ] **Step 2: Create diagram types**

Create `coral-app/src/components/diagram/types.ts`:

```typescript
import type { Node, Edge, BuiltInNode, BuiltInEdge } from '@xyflow/react';

// --- Detail Levels ---
export type DetailLevel = 'story' | 'decision' | 'full';

// --- Layer toggles ---
export interface LayerState {
  costs: boolean;
  disturbance: boolean;
  stochasticity: boolean;
}

// --- Custom node data ---
export interface CompartmentNodeData {
  compartmentId: 'lab' | 'orchard' | 'reef';
  label: string;
  subtitle: string;
  color: string;         // hex color
  detailLevel: DetailLevel;
  layers: LayerState;
  // Decision mode extras
  parameters?: { name: string; value: string; description: string }[];
  // Full mode: size class populations
  sizeClasses?: { id: string; range: string; survival: number; fecundity: number; color: string }[];
}

export interface ExternalNodeData {
  label: string;
  subtitle: string;
  type: 'external-reefs' | 'wild-recruitment';
}

export interface DecisionNodeData {
  label: string;
  parameter: string;      // "reef_prop"
  value: string;           // "0.75"
  detailLevel: DetailLevel;
}

// --- Custom edge data ---
export interface FlowEdgeData {
  label: string;
  flowType: 'collection' | 'outplanting' | 'transplanting' | 'external' | 'feedback';
  color: string;
  animated: boolean;
  cost?: string;           // e.g. "$6,500/event"
  showCost: boolean;
}

// --- Type unions ---
export type CompartmentNodeType = Node<CompartmentNodeData, 'compartment'>;
export type ExternalNodeType = Node<ExternalNodeData, 'external'>;
export type DecisionNodeType = Node<DecisionNodeData, 'decision'>;

export type DiagramNode = BuiltInNode | CompartmentNodeType | ExternalNodeType | DecisionNodeType;
export type DiagramEdge = BuiltInEdge | Edge<FlowEdgeData, 'flow'>;
```

- [ ] **Step 3: Create diagram theme CSS**

Create `coral-app/src/components/diagram/diagram-theme.css`:

```css
.diagram-container {
  background: linear-gradient(135deg, #070E1A 0%, #0C1929 50%, #0A1628 100%);
  border-radius: 1rem;
  position: relative;
  overflow: hidden;
}

/* Override React Flow dark mode variables */
.diagram-container .react-flow {
  --xy-background-color: transparent;
  --xy-minimap-background-color: rgba(7, 14, 26, 0.8);
  --xy-minimap-mask-background-color: rgba(7, 14, 26, 0.6);
  --xy-controls-button-background-color: rgba(255, 255, 255, 0.08);
  --xy-controls-button-background-color-hover: rgba(255, 255, 255, 0.15);
  --xy-controls-button-color: rgba(255, 255, 255, 0.7);
  --xy-controls-button-border-color: rgba(255, 255, 255, 0.1);
}

/* Compartment node base */
.compartment-node {
  backdrop-filter: blur(12px);
  border-radius: 12px;
  padding: 16px 20px;
  min-width: 200px;
  transition: all 0.3s ease;
}

.compartment-node:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
}

/* External source node */
.external-node {
  backdrop-filter: blur(8px);
  background: rgba(100, 116, 139, 0.15);
  border: 1.5px dashed rgba(100, 116, 139, 0.5);
  border-radius: 10px;
  padding: 10px 16px;
  color: rgba(255, 255, 255, 0.7);
}

/* Decision diamond */
.decision-node {
  width: 100px;
  height: 100px;
  transform: rotate(45deg);
  background: rgba(253, 224, 71, 0.12);
  border: 2px solid rgba(253, 224, 71, 0.6);
  display: flex;
  align-items: center;
  justify-content: center;
}

.decision-node-content {
  transform: rotate(-45deg);
  text-align: center;
  color: #FDE047;
  font-size: 11px;
  font-weight: 600;
}

/* Edge label pills */
.edge-label-pill {
  background: rgba(7, 14, 26, 0.85);
  backdrop-filter: blur(8px);
  border: 1px solid rgba(255, 255, 255, 0.15);
  border-radius: 6px;
  padding: 3px 8px;
  font-size: 10px;
  font-family: 'JetBrains Mono', monospace;
  color: rgba(255, 255, 255, 0.8);
  white-space: nowrap;
}

.cost-badge {
  background: rgba(74, 222, 128, 0.15);
  border: 1px solid rgba(74, 222, 128, 0.4);
  color: #4ADE80;
  border-radius: 4px;
  padding: 1px 6px;
  font-size: 9px;
  font-family: 'JetBrains Mono', monospace;
  margin-top: 2px;
}

/* Size class nodes (full mode) */
.size-class-row {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 4px 8px;
  border-radius: 6px;
  background: rgba(12, 20, 38, 0.7);
  font-size: 11px;
  color: rgba(255, 255, 255, 0.8);
}

.size-class-accent {
  width: 3px;
  height: 24px;
  border-radius: 2px;
}

/* Layer overlays */
.disturbance-overlay {
  border: 2px dashed rgba(248, 113, 113, 0.6) !important;
}

.stochasticity-badge {
  background: rgba(192, 132, 252, 0.15);
  border: 1px solid rgba(192, 132, 252, 0.4);
  color: #C084FC;
  border-radius: 4px;
  padding: 1px 6px;
  font-size: 9px;
  font-family: 'JetBrains Mono', monospace;
}

/* Glow filter for node hover */
.glow-amber { filter: drop-shadow(0 0 8px rgba(245, 158, 11, 0.4)); }
.glow-emerald { filter: drop-shadow(0 0 8px rgba(16, 185, 129, 0.4)); }
.glow-sky { filter: drop-shadow(0 0 8px rgba(56, 189, 248, 0.4)); }

/* Legend panel */
.legend-panel {
  background: rgba(7, 14, 26, 0.85);
  backdrop-filter: blur(12px);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 10px;
  padding: 12px 16px;
  color: rgba(255, 255, 255, 0.8);
  font-size: 11px;
}
```

- [ ] **Step 4: Create ModelDiagram shell**

Create `coral-app/src/components/diagram/ModelDiagram.tsx`:

```tsx
import { useCallback, useState } from 'react';
import {
  ReactFlow,
  MiniMap,
  Controls,
  Background,
  BackgroundVariant,
  useNodesState,
  useEdgesState,
  type ColorMode,
} from '@xyflow/react';
import '@xyflow/react/dist/style.css';
import './diagram-theme.css';
import type { DetailLevel, LayerState } from './types';

const colorMode: ColorMode = 'dark';

export default function ModelDiagram() {
  const [detailLevel, setDetailLevel] = useState<DetailLevel>('story');
  const [layers, setLayers] = useState<LayerState>({
    costs: false,
    disturbance: false,
    stochasticity: false,
  });

  const [nodes, setNodes, onNodesChange] = useNodesState([]);
  const [edges, setEdges, onEdgesChange] = useEdgesState([]);

  return (
    <div className="diagram-container w-full" style={{ height: '70vh', minHeight: 500 }}>
      <ReactFlow
        nodes={nodes}
        edges={edges}
        onNodesChange={onNodesChange}
        onEdgesChange={onEdgesChange}
        colorMode={colorMode}
        fitView
        fitViewOptions={{ padding: 0.15 }}
        proOptions={{ hideAttribution: true }}
      >
        <MiniMap
          position="bottom-right"
          pannable
          zoomable
          nodeColor={() => 'rgba(255,255,255,0.2)'}
          maskColor="rgba(7,14,26,0.6)"
        />
        <Controls position="bottom-left" />
        <Background variant={BackgroundVariant.Dots} color="rgba(255,255,255,0.05)" gap={20} />
      </ReactFlow>
    </div>
  );
}
```

- [ ] **Step 5: Add Diagram tab to App.tsx**

In `coral-app/src/App.tsx`, add the import at the top:

```typescript
import ModelDiagram from './components/diagram/ModelDiagram';
```

Add 'diagram' to the tabs array (insert as first item):

```typescript
{ id: 'diagram', label: 'Model Diagram', icon: '' },
```

Change the default tab:

```typescript
const [activeTab, setActiveTab] = useState('diagram');
```

Add the diagram tab content before the overview tab content block:

```tsx
{activeTab === 'diagram' && (
  <div className="fade-in">
    <ModelDiagram />
  </div>
)}
```

- [ ] **Step 6: Verify the shell renders**

Run: `cd coral-app && npm run build`
Expected: Build succeeds with no type errors.

Run: `cd coral-app && npm run dev`
Verify: Open in browser, "Model Diagram" tab shows a dark container with React Flow controls and minimap.

- [ ] **Step 7: Commit**

```bash
git add coral-app/package.json coral-app/package-lock.json \
  coral-app/src/components/diagram/ \
  coral-app/src/App.tsx
git commit -m "feat: scaffold React Flow diagram shell with dark ocean theme"
```

---

### Task 2: Build CompartmentNode custom node

**Files:**
- Create: `coral-app/src/components/diagram/nodes/CompartmentNode.tsx`

- [ ] **Step 1: Create CompartmentNode component**

Create `coral-app/src/components/diagram/nodes/CompartmentNode.tsx`:

```tsx
import { memo } from 'react';
import { Handle, Position, type NodeProps } from '@xyflow/react';
import type { CompartmentNodeData } from '../types';

const COMPARTMENT_STYLES: Record<string, { border: string; bg: string; glow: string }> = {
  lab: {
    border: 'rgba(245, 158, 11, 0.6)',
    bg: 'rgba(245, 158, 11, 0.08)',
    glow: 'glow-amber',
  },
  orchard: {
    border: 'rgba(16, 185, 129, 0.6)',
    bg: 'rgba(16, 185, 129, 0.08)',
    glow: 'glow-emerald',
  },
  reef: {
    border: 'rgba(56, 189, 248, 0.6)',
    bg: 'rgba(56, 189, 248, 0.08)',
    glow: 'glow-sky',
  },
};

function CompartmentNode({ data }: NodeProps) {
  const nodeData = data as unknown as CompartmentNodeData;
  const style = COMPARTMENT_STYLES[nodeData.compartmentId] ?? COMPARTMENT_STYLES.lab;

  return (
    <div
      className={`compartment-node ${style.glow} ${nodeData.layers.disturbance && nodeData.compartmentId !== 'lab' ? 'disturbance-overlay' : ''}`}
      style={{
        background: style.bg,
        border: `1.5px solid ${style.border}`,
      }}
    >
      {/* Target handles */}
      <Handle type="target" position={Position.Left} id="left" style={{ background: style.border }} />
      <Handle type="target" position={Position.Top} id="top" style={{ background: style.border }} />

      {/* Header */}
      <div style={{ color: nodeData.color, fontWeight: 700, fontSize: 15, fontFamily: 'Crimson Pro, serif' }}>
        {nodeData.label}
      </div>
      <div style={{ color: 'rgba(255,255,255,0.5)', fontSize: 11, marginTop: 2 }}>
        {nodeData.subtitle}
      </div>

      {/* Decision mode: show parameters */}
      {nodeData.detailLevel !== 'story' && nodeData.parameters && (
        <div style={{ marginTop: 10, display: 'flex', flexDirection: 'column', gap: 4 }}>
          {nodeData.parameters.map((p) => (
            <div key={p.name} style={{ display: 'flex', justifyContent: 'space-between', gap: 12 }}>
              <span style={{ color: '#FDE047', fontFamily: 'JetBrains Mono, monospace', fontSize: 10 }}>
                {p.name}
              </span>
              <span style={{ color: 'rgba(255,255,255,0.6)', fontFamily: 'JetBrains Mono, monospace', fontSize: 10 }}>
                {p.value}
              </span>
            </div>
          ))}
        </div>
      )}

      {/* Full mode: show size classes */}
      {nodeData.detailLevel === 'full' && nodeData.sizeClasses && (
        <div style={{ marginTop: 10, display: 'flex', flexDirection: 'column', gap: 3 }}>
          {nodeData.sizeClasses.map((sc) => (
            <div key={sc.id} className="size-class-row">
              <div className="size-class-accent" style={{ background: sc.color }} />
              <span style={{ fontWeight: 600, width: 28 }}>{sc.id}</span>
              <span style={{ color: 'rgba(255,255,255,0.5)', flex: 1 }}>{sc.range}</span>
              {sc.fecundity > 0 && (
                <span style={{ color: '#FB923C', fontSize: 9 }} title="Reproduces">F</span>
              )}
            </div>
          ))}
        </div>
      )}

      {/* Stochasticity badge */}
      {nodeData.layers.stochasticity && nodeData.compartmentId !== 'lab' && (
        <div style={{ marginTop: 6 }}>
          <span className="stochasticity-badge">sigma_s, sigma_f</span>
        </div>
      )}

      {/* Source handles */}
      <Handle type="source" position={Position.Right} id="right" style={{ background: style.border }} />
      <Handle type="source" position={Position.Bottom} id="bottom" style={{ background: style.border }} />
    </div>
  );
}

export default memo(CompartmentNode);
```

- [ ] **Step 2: Verify build**

Run: `cd coral-app && npm run build`
Expected: No type errors.

- [ ] **Step 3: Commit**

```bash
git add coral-app/src/components/diagram/nodes/CompartmentNode.tsx
git commit -m "feat: add CompartmentNode custom React Flow node"
```

---

### Task 3: Build ExternalNode and DecisionNode

**Files:**
- Create: `coral-app/src/components/diagram/nodes/ExternalNode.tsx`
- Create: `coral-app/src/components/diagram/nodes/DecisionNode.tsx`

- [ ] **Step 1: Create ExternalNode**

Create `coral-app/src/components/diagram/nodes/ExternalNode.tsx`:

```tsx
import { memo } from 'react';
import { Handle, Position, type NodeProps } from '@xyflow/react';
import type { ExternalNodeData } from '../types';

function ExternalNode({ data }: NodeProps) {
  const nodeData = data as unknown as ExternalNodeData;

  return (
    <div className="external-node">
      <Handle type="source" position={Position.Right} id="right" style={{ background: '#64748B' }} />
      <Handle type="source" position={Position.Bottom} id="bottom" style={{ background: '#64748B' }} />
      <div style={{ fontWeight: 600, fontSize: 12, fontFamily: 'Crimson Pro, serif' }}>
        {nodeData.label}
      </div>
      <div style={{ fontSize: 10, opacity: 0.6, marginTop: 1 }}>
        {nodeData.subtitle}
      </div>
    </div>
  );
}

export default memo(ExternalNode);
```

- [ ] **Step 2: Create DecisionNode**

Create `coral-app/src/components/diagram/nodes/DecisionNode.tsx`:

```tsx
import { memo } from 'react';
import { Handle, Position, type NodeProps } from '@xyflow/react';
import type { DecisionNodeData } from '../types';

function DecisionNode({ data }: NodeProps) {
  const nodeData = data as unknown as DecisionNodeData;

  return (
    <div className="decision-node">
      {/* Handles positioned on the diamond corners */}
      <Handle type="target" position={Position.Left} id="left" style={{ background: '#FDE047' }} />
      <Handle type="source" position={Position.Top} id="top" style={{ background: '#FDE047' }} />
      <Handle type="source" position={Position.Right} id="right" style={{ background: '#FDE047' }} />
      <Handle type="source" position={Position.Bottom} id="bottom" style={{ background: '#FDE047' }} />

      <div className="decision-node-content">
        <div style={{ fontSize: 10, opacity: 0.7 }}>{nodeData.label}</div>
        {nodeData.detailLevel !== 'story' && (
          <>
            <div style={{ fontFamily: 'JetBrains Mono, monospace', fontSize: 11, marginTop: 2 }}>
              {nodeData.parameter}
            </div>
            <div style={{ fontSize: 13, fontWeight: 700, marginTop: 1 }}>
              {nodeData.value}
            </div>
          </>
        )}
      </div>
    </div>
  );
}

export default memo(DecisionNode);
```

- [ ] **Step 3: Verify build**

Run: `cd coral-app && npm run build`
Expected: No type errors.

- [ ] **Step 4: Commit**

```bash
git add coral-app/src/components/diagram/nodes/ExternalNode.tsx \
  coral-app/src/components/diagram/nodes/DecisionNode.tsx
git commit -m "feat: add ExternalNode and DecisionNode custom nodes"
```

---

### Task 4: Build FlowEdge with animated particles

**Files:**
- Create: `coral-app/src/components/diagram/edges/FlowEdge.tsx`

- [ ] **Step 1: Create FlowEdge**

Create `coral-app/src/components/diagram/edges/FlowEdge.tsx`:

```tsx
import { BaseEdge, getBezierPath, type EdgeProps } from '@xyflow/react';
import type { FlowEdgeData } from '../types';

const FLOW_COLORS: Record<string, string> = {
  collection: '#67E8F9',   // cyan
  outplanting: '#FBBF24',  // amber/gold
  transplanting: '#2DD4BF', // teal
  external: '#64748B',      // slate gray
  feedback: '#67E8F9',      // cyan (same as collection)
};

export default function FlowEdge({
  id,
  sourceX,
  sourceY,
  targetX,
  targetY,
  sourcePosition,
  targetPosition,
  data,
  markerEnd,
}: EdgeProps) {
  const edgeData = data as unknown as FlowEdgeData;
  const color = edgeData?.color ?? FLOW_COLORS[edgeData?.flowType ?? 'external'] ?? '#64748B';
  const isDashed = edgeData?.flowType === 'external';

  const [edgePath, labelX, labelY] = getBezierPath({
    sourceX,
    sourceY,
    sourcePosition,
    targetX,
    targetY,
    targetPosition,
  });

  return (
    <>
      {/* Glow underlayer */}
      <path
        d={edgePath}
        fill="none"
        stroke={color}
        strokeWidth={8}
        strokeOpacity={0.1}
      />

      {/* Main edge */}
      <BaseEdge
        id={id}
        path={edgePath}
        markerEnd={markerEnd}
        style={{
          stroke: color,
          strokeWidth: 2,
          strokeDasharray: isDashed ? '6 4' : undefined,
        }}
      />

      {/* Animated particles */}
      {edgeData?.animated && (
        <>
          <circle r="3" fill={color}>
            <animateMotion dur="3s" repeatCount="indefinite" path={edgePath} />
          </circle>
          <circle r="3" fill={color}>
            <animateMotion dur="3s" repeatCount="indefinite" path={edgePath} begin="1s" />
          </circle>
          <circle r="3" fill={color}>
            <animateMotion dur="3s" repeatCount="indefinite" path={edgePath} begin="2s" />
          </circle>
        </>
      )}

      {/* Label */}
      {edgeData?.label && (
        <foreignObject
          x={labelX - 50}
          y={labelY - 12}
          width={100}
          height={32}
          style={{ overflow: 'visible', pointerEvents: 'none' }}
        >
          <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
            <span className="edge-label-pill">{edgeData.label}</span>
            {edgeData.showCost && edgeData.cost && (
              <span className="cost-badge">{edgeData.cost}</span>
            )}
          </div>
        </foreignObject>
      )}
    </>
  );
}
```

- [ ] **Step 2: Verify build**

Run: `cd coral-app && npm run build`
Expected: No type errors.

- [ ] **Step 3: Commit**

```bash
git add coral-app/src/components/diagram/edges/FlowEdge.tsx
git commit -m "feat: add FlowEdge with animated particle dots"
```

---

### Task 5: Build useDiagramLayout hook with Story mode

**Files:**
- Create: `coral-app/src/components/diagram/hooks/useDiagramLayout.ts`
- Create: `coral-app/src/components/diagram/hooks/useDiagramLayout.test.ts`

- [ ] **Step 1: Write failing test for useDiagramLayout**

Create `coral-app/src/components/diagram/hooks/useDiagramLayout.test.ts`:

```typescript
import { describe, it, expect } from 'vitest';
import { buildDiagramLayout } from './useDiagramLayout';

describe('buildDiagramLayout', () => {
  const defaultLayers = { costs: false, disturbance: false, stochasticity: false };

  describe('story mode', () => {
    it('returns 6 nodes: 3 compartments + 2 external + 1 decision', () => {
      const { nodes } = buildDiagramLayout('story', defaultLayers);
      expect(nodes).toHaveLength(6);

      const types = nodes.map((n) => n.type);
      expect(types.filter((t) => t === 'compartment')).toHaveLength(3);
      expect(types.filter((t) => t === 'external')).toHaveLength(2);
      expect(types.filter((t) => t === 'decision')).toHaveLength(1);
    });

    it('returns 7 edges connecting all compartments', () => {
      const { edges } = buildDiagramLayout('story', defaultLayers);
      expect(edges).toHaveLength(7);
    });

    it('all edges are type flow', () => {
      const { edges } = buildDiagramLayout('story', defaultLayers);
      edges.forEach((e) => expect(e.type).toBe('flow'));
    });
  });

  describe('decision mode', () => {
    it('compartment nodes include parameters', () => {
      const { nodes } = buildDiagramLayout('decision', defaultLayers);
      const compartments = nodes.filter((n) => n.type === 'compartment');
      compartments.forEach((n) => {
        const data = n.data as Record<string, unknown>;
        expect(data.parameters).toBeDefined();
        expect(Array.isArray(data.parameters)).toBe(true);
      });
    });

    it('decision node shows parameter name and value', () => {
      const { nodes } = buildDiagramLayout('decision', defaultLayers);
      const decision = nodes.find((n) => n.type === 'decision');
      const data = decision!.data as Record<string, unknown>;
      expect(data.parameter).toBe('reef_prop');
      expect(data.value).toBe('0.75');
    });
  });

  describe('full mode', () => {
    it('compartment nodes include size class data', () => {
      const { nodes } = buildDiagramLayout('full', defaultLayers);
      const compartments = nodes.filter((n) => n.type === 'compartment');
      // Orchard and Reef have size classes; Lab does not
      const withSC = compartments.filter((n) => {
        const data = n.data as Record<string, unknown>;
        return Array.isArray(data.sizeClasses) && (data.sizeClasses as unknown[]).length > 0;
      });
      expect(withSC).toHaveLength(2); // orchard + reef
    });
  });

  describe('layer toggles', () => {
    it('cost layer enables showCost on edges', () => {
      const { edges } = buildDiagramLayout('decision', { ...defaultLayers, costs: true });
      const flowEdges = edges.filter((e) => e.data && 'showCost' in (e.data as Record<string, unknown>));
      flowEdges.forEach((e) => {
        const data = e.data as Record<string, unknown>;
        expect(data.showCost).toBe(true);
      });
    });
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd coral-app && npx vitest run src/components/diagram/hooks/useDiagramLayout.test.ts`
Expected: FAIL -- module not found.

- [ ] **Step 3: Implement useDiagramLayout**

Create `coral-app/src/components/diagram/hooks/useDiagramLayout.ts`:

```typescript
import { useMemo } from 'react';
import { MarkerType } from '@xyflow/react';
import type { DetailLevel, LayerState, DiagramNode, DiagramEdge } from '../types';

// --- Node positions (optimized for pipeline + feedback layout) ---
const POSITIONS = {
  extReefs:        { x: 30,  y: 180 },
  lab:             { x: 260, y: 250 },
  decision:        { x: 530, y: 255 },
  reef:            { x: 760, y: 140 },
  orchard:         { x: 530, y: 460 },
  wildRecruitment: { x: 760, y: 20 },
};

// --- Compartment parameters by detail level ---
const LAB_PARAMS = [
  { name: 'lab_max', value: '~3,100 tiles', description: 'Tile capacity' },
  { name: 'sett_props', value: '~0.15', description: 'Settlement rate' },
  { name: 'lab_retain_max', value: '0-3,100', description: '1-yr grow-out tiles' },
];

const ORCHARD_PARAMS = [
  { name: 'orchard_size', value: '~15,000', description: 'Colony capacity' },
  { name: 'orchard_yield', value: '0.5', description: 'Larvae collection fraction' },
  { name: 'survival', value: '0.70-0.95', description: 'Enhanced survival' },
];

const REEF_PARAMS = [
  { name: 'reef_areas', value: '~7,837 m\u00B2', description: 'Carrying capacity' },
  { name: 'lambda', value: 'varies', description: 'Wild recruitment' },
  { name: 'survival', value: '0.40-0.85', description: 'Baseline survival' },
];

const SIZE_CLASS_DATA = [
  { id: 'SC1', range: '0-10 cm\u00B2', survival: 0.4, fecundity: 0, color: '#10b981' },
  { id: 'SC2', range: '10-100 cm\u00B2', survival: 0.6, fecundity: 0, color: '#3b82f6' },
  { id: 'SC3', range: '100-900 cm\u00B2', survival: 0.7, fecundity: 5000, color: '#8b5cf6' },
  { id: 'SC4', range: '900-4k cm\u00B2', survival: 0.8, fecundity: 50000, color: '#f59e0b' },
  { id: 'SC5', range: '>4000 cm\u00B2', survival: 0.85, fecundity: 100000, color: '#ef4444' },
];

// --- Edge costs ---
const COSTS: Record<string, string> = {
  'ext-to-lab': '$6,500/event + $400 permits',
  'lab-to-decision': '',
  'decision-to-reef': '$300/day boat + $200/day divers',
  'decision-to-orchard': '$300/day boat + $200/day divers',
  'orchard-to-lab': '$6,500/event',
  'orchard-to-reef': '$300/day boat',
  'wild-to-reef': '',
};

/**
 * Pure function that builds nodes and edges for a given detail level and layer state.
 * Extracted from the hook for testability.
 */
export function buildDiagramLayout(
  detailLevel: DetailLevel,
  layers: LayerState
): { nodes: DiagramNode[]; edges: DiagramEdge[] } {
  const showParams = detailLevel !== 'story';
  const showSizeClasses = detailLevel === 'full';

  // --- Build nodes ---
  const nodes: DiagramNode[] = [
    // External sources
    {
      id: 'ext-reefs',
      type: 'external',
      position: POSITIONS.extReefs,
      data: {
        label: 'External Reefs',
        subtitle: 'Reference reef larvae',
        type: 'external-reefs',
      },
    },
    {
      id: 'wild-recruitment',
      type: 'external',
      position: POSITIONS.wildRecruitment,
      data: {
        label: 'Wild Recruitment',
        subtitle: 'External larval input',
        type: 'wild-recruitment',
      },
    },
    // Lab
    {
      id: 'lab',
      type: 'compartment',
      position: POSITIONS.lab,
      data: {
        compartmentId: 'lab',
        label: 'Lab Facility',
        subtitle: 'Larval rearing & settlement',
        color: '#F59E0B',
        detailLevel,
        layers,
        parameters: showParams ? LAB_PARAMS : undefined,
      },
    },
    // Decision
    {
      id: 'decision',
      type: 'decision',
      position: POSITIONS.decision,
      data: {
        label: 'Allocation',
        parameter: 'reef_prop',
        value: '0.75',
        detailLevel,
      },
    },
    // Reef
    {
      id: 'reef',
      type: 'compartment',
      position: POSITIONS.reef,
      data: {
        compartmentId: 'reef',
        label: 'Restoration Reef',
        subtitle: 'Target outplanting site',
        color: '#38BDF8',
        detailLevel,
        layers,
        parameters: showParams ? REEF_PARAMS : undefined,
        sizeClasses: showSizeClasses ? SIZE_CLASS_DATA : undefined,
      },
    },
    // Orchard
    {
      id: 'orchard',
      type: 'compartment',
      position: POSITIONS.orchard,
      data: {
        compartmentId: 'orchard',
        label: 'Orchard Nursery',
        subtitle: 'Protected coral grow-out',
        color: '#10B981',
        detailLevel,
        layers,
        parameters: showParams ? ORCHARD_PARAMS : undefined,
        sizeClasses: showSizeClasses ? SIZE_CLASS_DATA : undefined,
      },
    },
  ];

  // --- Build edges ---
  const markerEnd = { type: MarkerType.ArrowClosed, width: 14, height: 14 };
  const showCost = layers.costs;

  const edges: DiagramEdge[] = [
    // External Reefs -> Lab (collection)
    {
      id: 'ext-to-lab',
      source: 'ext-reefs',
      target: 'lab',
      sourceHandle: 'right',
      targetHandle: 'left',
      type: 'flow',
      markerEnd,
      data: {
        label: 'Larvae collection',
        flowType: 'collection',
        color: '#67E8F9',
        animated: true,
        cost: COSTS['ext-to-lab'],
        showCost,
      },
    },
    // Lab -> Decision (pipeline)
    {
      id: 'lab-to-decision',
      source: 'lab',
      target: 'decision',
      sourceHandle: 'right',
      targetHandle: 'left',
      type: 'flow',
      markerEnd,
      data: {
        label: 'Settlers',
        flowType: 'outplanting',
        color: '#FBBF24',
        animated: true,
        cost: '',
        showCost: false,
      },
    },
    // Decision -> Reef (reef_prop)
    {
      id: 'decision-to-reef',
      source: 'decision',
      target: 'reef',
      sourceHandle: 'right',
      targetHandle: 'left',
      type: 'flow',
      markerEnd,
      data: {
        label: detailLevel === 'story' ? 'To reef' : 'reef_prop = 0.75',
        flowType: 'outplanting',
        color: '#FBBF24',
        animated: true,
        cost: COSTS['decision-to-reef'],
        showCost,
      },
    },
    // Decision -> Orchard (1 - reef_prop)
    {
      id: 'decision-to-orchard',
      source: 'decision',
      target: 'orchard',
      sourceHandle: 'bottom',
      targetHandle: 'top',
      type: 'flow',
      markerEnd,
      data: {
        label: detailLevel === 'story' ? 'To orchard' : '1 - reef_prop = 0.25',
        flowType: 'outplanting',
        color: '#FBBF24',
        animated: true,
        cost: COSTS['decision-to-orchard'],
        showCost,
      },
    },
    // Orchard -> Lab (larvae feedback)
    {
      id: 'orchard-to-lab',
      source: 'orchard',
      target: 'lab',
      sourceHandle: 'left' as string,
      targetHandle: 'bottom',
      type: 'flow',
      markerEnd,
      data: {
        label: 'Larvae collection',
        flowType: 'feedback',
        color: '#67E8F9',
        animated: true,
        cost: COSTS['orchard-to-lab'],
        showCost,
      },
    },
    // Orchard -> Reef (transplanting)
    {
      id: 'orchard-to-reef',
      source: 'orchard',
      target: 'reef',
      sourceHandle: 'right',
      targetHandle: 'bottom',
      type: 'flow',
      markerEnd,
      data: {
        label: 'Transplanting',
        flowType: 'transplanting',
        color: '#2DD4BF',
        animated: false,
        cost: COSTS['orchard-to-reef'],
        showCost,
      },
    },
    // Wild Recruitment -> Reef (external)
    {
      id: 'wild-to-reef',
      source: 'wild-recruitment',
      target: 'reef',
      sourceHandle: 'bottom',
      targetHandle: 'top',
      type: 'flow',
      markerEnd,
      data: {
        label: 'Wild larvae',
        flowType: 'external',
        color: '#64748B',
        animated: false,
        cost: '',
        showCost: false,
      },
    },
  ];

  return { nodes, edges };
}

/**
 * React hook wrapper around buildDiagramLayout.
 * Memoizes output based on detail level and layer state.
 */
export function useDiagramLayout(detailLevel: DetailLevel, layers: LayerState) {
  return useMemo(
    () => buildDiagramLayout(detailLevel, layers),
    [detailLevel, layers]
  );
}
```

- [ ] **Step 4: Run tests**

Run: `cd coral-app && npx vitest run src/components/diagram/hooks/useDiagramLayout.test.ts`
Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
git add coral-app/src/components/diagram/hooks/
git commit -m "feat: add useDiagramLayout hook with story/decision/full modes"
```

---

### Task 6: Wire up nodes, edges, and register custom types in ModelDiagram

**Files:**
- Modify: `coral-app/src/components/diagram/ModelDiagram.tsx`

- [ ] **Step 1: Update ModelDiagram to use layout hook and register node/edge types**

Replace the contents of `coral-app/src/components/diagram/ModelDiagram.tsx`:

```tsx
import { useEffect, useState } from 'react';
import {
  ReactFlow,
  MiniMap,
  Controls,
  Background,
  BackgroundVariant,
  useNodesState,
  useEdgesState,
  useReactFlow,
  ReactFlowProvider,
  type ColorMode,
} from '@xyflow/react';
import '@xyflow/react/dist/style.css';
import './diagram-theme.css';
import type { DetailLevel, LayerState } from './types';
import { useDiagramLayout } from './hooks/useDiagramLayout';
import CompartmentNode from './nodes/CompartmentNode';
import ExternalNode from './nodes/ExternalNode';
import DecisionNode from './nodes/DecisionNode';
import FlowEdge from './edges/FlowEdge';
import DetailToggle from './DetailToggle';
import LayerToggles from './LayerToggles';
import Legend from './Legend';

// IMPORTANT: Define nodeTypes and edgeTypes OUTSIDE component to prevent re-renders
const nodeTypes = {
  compartment: CompartmentNode,
  external: ExternalNode,
  decision: DecisionNode,
};

const edgeTypes = {
  flow: FlowEdge,
};

const colorMode: ColorMode = 'dark';

function DiagramInner() {
  const [detailLevel, setDetailLevel] = useState<DetailLevel>('story');
  const [layers, setLayers] = useState<LayerState>({
    costs: false,
    disturbance: false,
    stochasticity: false,
  });

  const layout = useDiagramLayout(detailLevel, layers);
  const [nodes, setNodes, onNodesChange] = useNodesState(layout.nodes);
  const [edges, setEdges, onEdgesChange] = useEdgesState(layout.edges);
  const { fitView } = useReactFlow();

  // Sync layout changes to state
  useEffect(() => {
    setNodes(layout.nodes);
    setEdges(layout.edges);
    // Fit view after a brief delay to let nodes render
    const timer = setTimeout(() => fitView({ padding: 0.15, duration: 400 }), 50);
    return () => clearTimeout(timer);
  }, [layout, setNodes, setEdges, fitView]);

  return (
    <div className="diagram-container w-full" style={{ height: '70vh', minHeight: 500 }}>
      <ReactFlow
        nodes={nodes}
        edges={edges}
        onNodesChange={onNodesChange}
        onEdgesChange={onEdgesChange}
        nodeTypes={nodeTypes}
        edgeTypes={edgeTypes}
        colorMode={colorMode}
        fitView
        fitViewOptions={{ padding: 0.15 }}
        proOptions={{ hideAttribution: true }}
        nodesDraggable={false}
        nodesConnectable={false}
        elementsSelectable={false}
      >
        <MiniMap
          position="bottom-right"
          pannable
          zoomable
          nodeColor={() => 'rgba(255,255,255,0.2)'}
          maskColor="rgba(7,14,26,0.6)"
        />
        <Controls position="bottom-left" />
        <Background variant={BackgroundVariant.Dots} color="rgba(255,255,255,0.05)" gap={20} />
      </ReactFlow>

      {/* Controls overlay (top-left) */}
      <div style={{ position: 'absolute', top: 12, left: 12, zIndex: 10, display: 'flex', flexDirection: 'column', gap: 8 }}>
        <DetailToggle value={detailLevel} onChange={setDetailLevel} />
        <LayerToggles layers={layers} onChange={setLayers} />
      </div>

      {/* Legend (top-right) */}
      <div style={{ position: 'absolute', top: 12, right: 12, zIndex: 10 }}>
        <Legend detailLevel={detailLevel} />
      </div>
    </div>
  );
}

export default function ModelDiagram() {
  return (
    <ReactFlowProvider>
      <DiagramInner />
    </ReactFlowProvider>
  );
}
```

Note: This references `DetailToggle`, `LayerToggles`, and `Legend` which we build in the next tasks. To avoid build errors, create stubs first (next step).

- [ ] **Step 2: Create stub components for DetailToggle, LayerToggles, Legend**

Create `coral-app/src/components/diagram/DetailToggle.tsx`:

```tsx
import type { DetailLevel } from './types';

interface Props {
  value: DetailLevel;
  onChange: (level: DetailLevel) => void;
}

const LEVELS: { id: DetailLevel; label: string }[] = [
  { id: 'story', label: 'Story' },
  { id: 'decision', label: 'Decision' },
  { id: 'full', label: 'Full Model' },
];

export default function DetailToggle({ value, onChange }: Props) {
  return (
    <div className="legend-panel" style={{ display: 'flex', gap: 4 }}>
      {LEVELS.map((level) => (
        <button
          key={level.id}
          onClick={() => onChange(level.id)}
          style={{
            padding: '4px 10px',
            borderRadius: 6,
            border: 'none',
            fontSize: 11,
            fontWeight: value === level.id ? 700 : 400,
            background: value === level.id ? 'rgba(255,255,255,0.15)' : 'transparent',
            color: value === level.id ? '#fff' : 'rgba(255,255,255,0.5)',
            cursor: 'pointer',
            transition: 'all 0.2s',
          }}
        >
          {level.label}
        </button>
      ))}
    </div>
  );
}
```

Create `coral-app/src/components/diagram/LayerToggles.tsx`:

```tsx
import type { LayerState } from './types';

interface Props {
  layers: LayerState;
  onChange: (layers: LayerState) => void;
}

const LAYER_CONFIG: { key: keyof LayerState; label: string; color: string }[] = [
  { key: 'costs', label: 'Costs', color: '#4ADE80' },
  { key: 'disturbance', label: 'Disturbance', color: '#F87171' },
  { key: 'stochasticity', label: 'Stochasticity', color: '#C084FC' },
];

export default function LayerToggles({ layers, onChange }: Props) {
  const toggle = (key: keyof LayerState) => {
    onChange({ ...layers, [key]: !layers[key] });
  };

  return (
    <div className="legend-panel" style={{ display: 'flex', gap: 4 }}>
      {LAYER_CONFIG.map(({ key, label, color }) => (
        <button
          key={key}
          onClick={() => toggle(key)}
          style={{
            padding: '3px 8px',
            borderRadius: 4,
            border: `1px solid ${layers[key] ? color : 'rgba(255,255,255,0.15)'}`,
            fontSize: 10,
            background: layers[key] ? `${color}22` : 'transparent',
            color: layers[key] ? color : 'rgba(255,255,255,0.4)',
            cursor: 'pointer',
            transition: 'all 0.2s',
          }}
        >
          {label}
        </button>
      ))}
    </div>
  );
}
```

Create `coral-app/src/components/diagram/Legend.tsx`:

```tsx
import type { DetailLevel } from './types';

interface Props {
  detailLevel: DetailLevel;
}

const EDGE_LEGEND = [
  { color: '#67E8F9', label: 'Larvae collection', style: 'solid' },
  { color: '#FBBF24', label: 'Outplanting', style: 'solid' },
  { color: '#2DD4BF', label: 'Transplanting', style: 'solid' },
  { color: '#64748B', label: 'External input', style: 'dashed' },
];

const NODE_LEGEND = [
  { color: '#F59E0B', label: 'Lab' },
  { color: '#10B981', label: 'Orchard' },
  { color: '#38BDF8', label: 'Reef' },
];

export default function Legend({ detailLevel }: Props) {
  return (
    <div className="legend-panel" style={{ minWidth: 140 }}>
      <div style={{ fontWeight: 700, marginBottom: 6, fontSize: 12, fontFamily: 'Crimson Pro, serif' }}>
        Legend
      </div>

      {/* Node colors */}
      <div style={{ marginBottom: 8 }}>
        {NODE_LEGEND.map(({ color, label }) => (
          <div key={label} style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 3 }}>
            <div style={{ width: 10, height: 10, borderRadius: 3, background: color, opacity: 0.8 }} />
            <span>{label}</span>
          </div>
        ))}
      </div>

      {/* Edge types */}
      <div>
        {EDGE_LEGEND.map(({ color, label, style }) => (
          <div key={label} style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 3 }}>
            <svg width="16" height="4">
              <line
                x1="0" y1="2" x2="16" y2="2"
                stroke={color}
                strokeWidth={2}
                strokeDasharray={style === 'dashed' ? '4 2' : undefined}
              />
            </svg>
            <span>{label}</span>
          </div>
        ))}
      </div>

      {/* Detail level indicator */}
      {detailLevel !== 'story' && (
        <div style={{ marginTop: 8, paddingTop: 6, borderTop: '1px solid rgba(255,255,255,0.1)', fontSize: 10, opacity: 0.6 }}>
          {detailLevel === 'decision' ? 'Showing parameters & costs' : 'Showing full demographic model'}
        </div>
      )}
    </div>
  );
}
```

- [ ] **Step 3: Verify build**

Run: `cd coral-app && npm run build`
Expected: Build succeeds with no errors.

- [ ] **Step 4: Run all tests**

Run: `cd coral-app && npx vitest run`
Expected: All tests pass, including the new useDiagramLayout tests.

- [ ] **Step 5: Commit**

```bash
git add coral-app/src/components/diagram/
git commit -m "feat: wire up React Flow diagram with all nodes, edges, controls, and legend"
```

---

### Task 7: Add left handle to CompartmentNode for orchard feedback loop

**Files:**
- Modify: `coral-app/src/components/diagram/nodes/CompartmentNode.tsx`

The orchard needs a left-side source handle for the feedback edge to Lab. The current CompartmentNode has left as target only. We need to add a source handle on the left as well.

- [ ] **Step 1: Add left source handle to CompartmentNode**

In `coral-app/src/components/diagram/nodes/CompartmentNode.tsx`, add an additional source handle:

After the existing `<Handle type="source" position={Position.Bottom} id="bottom" .../>`, add:

```tsx
<Handle type="source" position={Position.Left} id="left" style={{ background: style.border }} />
```

- [ ] **Step 2: Verify build**

Run: `cd coral-app && npm run build`
Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add coral-app/src/components/diagram/nodes/CompartmentNode.tsx
git commit -m "fix: add left source handle for orchard feedback edge"
```

---

### Task 8: Integration test for ModelDiagram rendering

**Files:**
- Create: `coral-app/src/components/diagram/ModelDiagram.test.tsx`

- [ ] **Step 1: Write integration test**

Create `coral-app/src/components/diagram/ModelDiagram.test.tsx`:

```tsx
import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
import ModelDiagram from './ModelDiagram';

describe('ModelDiagram', () => {
  it('renders without crashing', () => {
    render(<ModelDiagram />);
    // React Flow renders a container with the react-flow class
    const container = document.querySelector('.react-flow');
    expect(container).not.toBeNull();
  });

  it('renders detail toggle buttons', () => {
    render(<ModelDiagram />);
    expect(screen.getByText('Story')).toBeInTheDocument();
    expect(screen.getByText('Decision')).toBeInTheDocument();
    expect(screen.getByText('Full Model')).toBeInTheDocument();
  });

  it('renders layer toggle buttons', () => {
    render(<ModelDiagram />);
    expect(screen.getByText('Costs')).toBeInTheDocument();
    expect(screen.getByText('Disturbance')).toBeInTheDocument();
    expect(screen.getByText('Stochasticity')).toBeInTheDocument();
  });

  it('renders the legend', () => {
    render(<ModelDiagram />);
    expect(screen.getByText('Legend')).toBeInTheDocument();
  });
});
```

- [ ] **Step 2: Run test**

Run: `cd coral-app && npx vitest run src/components/diagram/ModelDiagram.test.tsx`
Expected: All tests PASS.

- [ ] **Step 3: Run full test suite**

Run: `cd coral-app && npx vitest run`
Expected: All tests pass.

- [ ] **Step 4: Commit**

```bash
git add coral-app/src/components/diagram/ModelDiagram.test.tsx
git commit -m "test: add integration tests for ModelDiagram"
```

---

### Task 9: Update App.tsx tab text and verify existing tests

**Files:**
- Modify: `coral-app/src/App.tsx`
- Modify: `coral-app/src/App.test.tsx`

- [ ] **Step 1: Update App.test.tsx to account for new tab**

The existing test checks for "Overview" tab text. Add a check for the new Diagram tab:

In `coral-app/src/App.test.tsx`, update the nav test:

```typescript
it('renders navigation tabs', () => {
  render(<App />);
  expect(screen.getByText(/Diagram/i)).toBeInTheDocument();
  expect(screen.getByText(/Overview/i)).toBeInTheDocument();
  expect(screen.getByText(/Parameters/i)).toBeInTheDocument();
  expect(screen.getByText(/Results/i)).toBeInTheDocument();
});
```

The "size class information" test may fail if the default tab is now 'diagram'. Update:

```typescript
it('renders size class information when overview tab is active', () => {
  render(<App />);
  // Click overview tab first since default is now diagram
  const overviewButton = screen.getByText(/Overview/i);
  overviewButton.click();
  expect(screen.getByText(/Size Classes/i)).toBeInTheDocument();
});
```

- [ ] **Step 2: Run tests**

Run: `cd coral-app && npx vitest run`
Expected: All tests pass.

- [ ] **Step 3: Verify full build**

Run: `cd coral-app && npm run build`
Expected: Build succeeds.

- [ ] **Step 4: Commit**

```bash
git add coral-app/src/App.tsx coral-app/src/App.test.tsx
git commit -m "feat: add Diagram tab as default view, update tests"
```

---

### Task 10: Visual polish -- tooltips, node sizing, responsive container

**Files:**
- Modify: `coral-app/src/components/diagram/nodes/CompartmentNode.tsx`
- Modify: `coral-app/src/components/diagram/diagram-theme.css`
- Modify: `coral-app/src/components/diagram/ModelDiagram.tsx`

- [ ] **Step 1: Add title attributes for tooltip-on-hover to CompartmentNode**

In `CompartmentNode.tsx`, add a `title` attribute to the outer div:

```tsx
<div
  className={...}
  style={...}
  title={`${nodeData.label}: ${nodeData.subtitle}`}
>
```

Also add titles to size class rows:

```tsx
<div key={sc.id} className="size-class-row" title={`${sc.id}: ${sc.range}, survival=${sc.survival}`}>
```

- [ ] **Step 2: Make diagram container responsive**

In `ModelDiagram.tsx`, update the container style to use calc for better responsiveness:

```tsx
<div className="diagram-container w-full" style={{ height: 'calc(100vh - 280px)', minHeight: 500, maxHeight: 800 }}>
```

- [ ] **Step 3: Add subtle animated gradient overlay to diagram background**

In `diagram-theme.css`, add:

```css
.diagram-container::before {
  content: '';
  position: absolute;
  inset: 0;
  background:
    radial-gradient(ellipse at 20% 50%, rgba(245, 158, 11, 0.04) 0%, transparent 50%),
    radial-gradient(ellipse at 80% 30%, rgba(56, 189, 248, 0.04) 0%, transparent 50%),
    radial-gradient(ellipse at 50% 80%, rgba(16, 185, 129, 0.04) 0%, transparent 50%);
  pointer-events: none;
  z-index: 0;
}
```

- [ ] **Step 4: Verify build**

Run: `cd coral-app && npm run build`
Expected: Build succeeds.

- [ ] **Step 5: Commit**

```bash
git add coral-app/src/components/diagram/
git commit -m "style: add tooltips, responsive sizing, ambient gradient to diagram"
```

---

### Task 11: Final build verification and cleanup

**Files:**
- All diagram files

- [ ] **Step 1: Run full test suite**

Run: `cd coral-app && npx vitest run`
Expected: All tests pass.

- [ ] **Step 2: Run production build**

Run: `cd coral-app && npm run build`
Expected: Build succeeds with no errors or warnings.

- [ ] **Step 3: Visual check list**

Start dev server: `cd coral-app && npm run dev`

Verify in browser:
1. Diagram tab loads as default
2. Dark ocean background with ambient gradient
3. All 6 nodes visible (Ext Reefs, Wild Recruitment, Lab, Decision, Orchard, Reef)
4. All 7 edges visible with correct colors
5. Animated particle dots on collection and outplanting edges
6. Detail toggle switches between Story/Decision/Full
7. Decision mode shows parameters on nodes and reef_prop on diamond
8. Full mode shows size class rows in Orchard and Reef
9. Layer toggles show/hide cost badges, disturbance borders, stochasticity badges
10. Legend updates with detail level
11. MiniMap and Controls work (zoom, pan)
12. Other tabs (Overview, Parameters, Results, About) still work

- [ ] **Step 4: Commit all remaining changes**

```bash
git add -A
git commit -m "feat: complete React Flow interactive model diagram (Phase A)"
```

---

## Phase B: Remotion Animation Video (Outline)

Phase B is a separate plan. High-level architecture:

### Setup
- Install: `npm install --save-exact remotion @remotion/cli @remotion/player`
- Create `coral-app/remotion/` directory with `Root.tsx`, `index.ts`
- Composition: 1920x1080, 30fps, ~90 seconds

### Scenes (as Remotion Sequences)

| Scene | Duration | Content |
|-------|----------|---------|
| 1. Title | 3s | "Coral Restoration Strategy Evaluation" + Acropora palmata |
| 2. The Problem | 5s | Reef decline stat, fade to empty reef |
| 3. External Reefs | 5s | Zoom to External Reefs node, show larvae |
| 4. Lab Pipeline | 10s | Animate larvae → settlement → tiles → 0TX/1TX split |
| 5. Decision Point | 5s | Decision diamond zooms in, reef_prop slider animates |
| 6. Orchard Growth | 10s | Orchard node expands, size classes grow SC1→SC5 |
| 7. Reef Outplanting | 10s | Animated flow from Lab/Orchard to Reef |
| 8. The Cycle | 10s | Full diagram with all flows animated simultaneously |
| 9. Stochasticity | 8s | Random perturbation overlay, multiple trajectories |
| 10. Disturbance | 8s | Hurricane event, survival drops, recovery |
| 11. Strategy Comparison | 10s | Side-by-side: high vs low reef_prop outcomes |
| 12. Summary | 6s | Key findings, lab logo, credits |

### Shared Components
- Reuse `CompartmentNode`, `FlowEdge`, `Legend` visual styling (CSS classes)
- Extract color palette and node positions to shared constants
- Each scene is a React component using `useCurrentFrame()` + `interpolate()` + `spring()`

### Render Pipeline
- Dev: `npx remotion studio coral-app/remotion/index.ts`
- Export: `npx remotion render coral-app/remotion/index.ts CoralRSE out/coral-rse-model.mp4`

**Phase B should be planned in detail after Phase A is complete and visually verified.**

---

## Self-Review Checklist

1. **Spec coverage:**
   - [x] React Flow interactive diagram replacing D3 model-diagram
   - [x] Three detail levels (Story, Decision, Full Model)
   - [x] Layer toggles (costs, disturbance, stochasticity)
   - [x] Pipeline layout with feedback loop
   - [x] Animated particle edges
   - [x] Deep ocean dark theme
   - [x] Legend, MiniMap, Controls
   - [x] Remotion Phase B outlined
   - [x] All three audiences served (stakeholders, practitioners, academics)

2. **Placeholder scan:** No TBD/TODO items. All code steps have actual code.

3. **Type consistency:**
   - `DetailLevel` = `'story' | 'decision' | 'full'` -- used consistently
   - `LayerState` = `{ costs, disturbance, stochasticity }` -- used consistently
   - `buildDiagramLayout()` returns `{ nodes: DiagramNode[]; edges: DiagramEdge[] }` -- matches hook and tests
   - Node types registered as `compartment`, `external`, `decision` -- matches nodeTypes object and node data
   - Edge type `flow` -- matches edgeTypes and edge data

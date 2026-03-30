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
  type Node,
  type Edge,
} from '@xyflow/react';
import '@xyflow/react/dist/style.css';
import './diagram-theme.css';
import type { DetailLevel, LayerState, CompartmentNodeData } from './types';
import { useDiagramLayout } from './hooks/useDiagramLayout';
import CompartmentNode from './nodes/CompartmentNode';
import ExternalNode from './nodes/ExternalNode';
import DecisionNode from './nodes/DecisionNode';
import FlowEdge from './edges/FlowEdge';
import DetailToggle from './DetailToggle';
import LayerToggles from './LayerToggles';
import Legend from './Legend';
import DetailPanel from './DetailPanel';

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
  const [selectedNodeId, setSelectedNodeId] = useState<string | null>(null);
  const [panelData, setPanelData] = useState<CompartmentNodeData | null>(null);

  const layout = useDiagramLayout(detailLevel, layers, selectedNodeId);
  const [nodes, setNodes, onNodesChange] = useNodesState(layout.nodes as Node[]);
  const [edges, setEdges, onEdgesChange] = useEdgesState(layout.edges as Edge[]);
  const { fitView } = useReactFlow();

  useEffect(() => {
    setNodes(layout.nodes as Node[]);
    setEdges(layout.edges as Edge[]);
    const timer = setTimeout(() => fitView({ padding: 0.15, duration: 400 }), 50);
    return () => clearTimeout(timer);
  }, [layout, setNodes, setEdges, fitView]);

  return (
    <div className="diagram-container w-full" style={{ height: 'calc(100vh - 280px)', minHeight: 500, maxHeight: 800 }}>
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
        elementsSelectable={true}
        onNodeClick={(_event, node) => {
          const isCompartment = node.type === 'compartment';
          setSelectedNodeId(prev => prev === node.id ? null : node.id);
          if (isCompartment) {
            const nodeData = node.data as unknown as CompartmentNodeData;
            setPanelData(prev => prev?.compartmentId === nodeData.compartmentId ? null : nodeData);
          } else {
            setPanelData(null);
          }
        }}
        onPaneClick={() => {
          setSelectedNodeId(null);
          setPanelData(null);
        }}
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

      <div style={{ position: 'absolute', top: 12, left: 12, zIndex: 10, display: 'flex', flexDirection: 'column', gap: 8 }}>
        <DetailToggle value={detailLevel} onChange={setDetailLevel} />
        <LayerToggles layers={layers} onChange={setLayers} />
      </div>

      <div style={{ position: 'absolute', top: 12, right: 12, zIndex: 10 }}>
        {panelData ? (
          <DetailPanel nodeData={panelData} onClose={() => { setPanelData(null); setSelectedNodeId(null); }} />
        ) : (
          <Legend detailLevel={detailLevel} />
        )}
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

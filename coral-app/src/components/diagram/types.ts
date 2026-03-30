import type { Node, Edge, BuiltInNode, BuiltInEdge } from '@xyflow/react';

export type DetailLevel = 'story' | 'decision' | 'full';

export interface LayerState {
  costs: boolean;
  disturbance: boolean;
  stochasticity: boolean;
}

export interface CompartmentNodeData {
  [key: string]: unknown;
  compartmentId: 'lab' | 'orchard' | 'reef';
  label: string;
  subtitle: string;
  color: string;
  detailLevel: DetailLevel;
  layers: LayerState;
  parameters?: { name: string; value: string; description: string }[];
  sizeClasses?: { id: string; range: string; survival: number; fecundity: number; color: string }[];
  selectedNodeId: string | null;
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

export type CompartmentNodeType = Node<CompartmentNodeData, 'compartment'>;
export type ExternalNodeType = Node<ExternalNodeData, 'external'>;
export type DecisionNodeType = Node<DecisionNodeData, 'decision'>;

export type DiagramNode = BuiltInNode | CompartmentNodeType | ExternalNodeType | DecisionNodeType;
export type DiagramEdge = BuiltInEdge | Edge<FlowEdgeData, 'flow'>;

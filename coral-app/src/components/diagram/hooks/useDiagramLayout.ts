import { useMemo } from 'react';
import { MarkerType } from '@xyflow/react';
import type { DetailLevel, LayerState, DiagramNode, DiagramEdge } from '../types';

const POSITIONS = {
  extReefs:        { x: 30,  y: 180 },
  lab:             { x: 260, y: 250 },
  decision:        { x: 530, y: 255 },
  reef:            { x: 760, y: 140 },
  orchard:         { x: 530, y: 460 },
  wildRecruitment: { x: 760, y: 20 },
};

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

const COSTS: Record<string, string> = {
  'ext-to-lab': '$6,500/event + $400 permits',
  'lab-to-decision': '',
  'decision-to-reef': '$300/day boat + $200/day divers',
  'decision-to-orchard': '$300/day boat + $200/day divers',
  'orchard-to-lab': '$6,500/event',
  'orchard-to-reef': '$300/day boat',
  'wild-to-reef': '',
};

export function buildDiagramLayout(
  detailLevel: DetailLevel,
  layers: LayerState
): { nodes: DiagramNode[]; edges: DiagramEdge[] } {
  const showParams = detailLevel !== 'story';
  const showSizeClasses = detailLevel === 'full';

  const nodes: DiagramNode[] = [
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

  const markerEnd = { type: MarkerType.ArrowClosed, width: 14, height: 14 };
  const showCost = layers.costs;

  const edges: DiagramEdge[] = [
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
    {
      id: 'orchard-to-lab',
      source: 'orchard',
      target: 'lab',
      sourceHandle: 'left-source',
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

export function useDiagramLayout(detailLevel: DetailLevel, layers: LayerState) {
  return useMemo(
    () => buildDiagramLayout(detailLevel, layers),
    [detailLevel, layers]
  );
}

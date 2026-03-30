import React from 'react';

interface IconProps {
  size?: number;
  color?: string;
}

/** Flask icon for Lab */
export const LabIcon: React.FC<IconProps> = ({ size = 20, color = '#F59E0B' }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth={2} strokeLinecap="round" strokeLinejoin="round">
    <path d="M9 3h6v8l4 7H5l4-7V3z" />
    <path d="M9 3h6" />
    <circle cx="12" cy="15" r="1" fill={color} />
  </svg>
);

/** Branching coral for Orchard */
export const OrchardIcon: React.FC<IconProps> = ({ size = 20, color = '#10B981' }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth={2} strokeLinecap="round" strokeLinejoin="round">
    <path d="M12 22V8" />
    <path d="M8 12l4-4 4 4" />
    <path d="M6 8l6-6 6 6" />
    <path d="M9 22h6" />
  </svg>
);

/** Coral colony for Reef */
export const ReefIcon: React.FC<IconProps> = ({ size = 20, color = '#38BDF8' }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth={2} strokeLinecap="round" strokeLinejoin="round">
    <path d="M6 20c0-4 2-6 2-10a4 4 0 1 1 8 0c0 4 2 6 2 10" />
    <path d="M12 10c0 4 2 6 2 10" />
    <path d="M12 10c0 4-2 6-2 10" />
    <line x1="4" y1="20" x2="20" y2="20" />
  </svg>
);

/** Waves for External nodes */
export const WavesIcon: React.FC<IconProps> = ({ size = 18, color = '#64748B' }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth={2} strokeLinecap="round" strokeLinejoin="round">
    <path d="M2 6c.6.5 1.2 1 2.5 1C7 7 7 5 9.5 5c2.6 0 2.4 2 5 2 2.5 0 2.5-2 5-2 1.3 0 1.9.5 2.5 1" />
    <path d="M2 12c.6.5 1.2 1 2.5 1 2.5 0 2.5-2 5-2 2.6 0 2.4 2 5 2 2.5 0 2.5-2 5-2 1.3 0 1.9.5 2.5 1" />
    <path d="M2 18c.6.5 1.2 1 2.5 1 2.5 0 2.5-2 5-2 2.6 0 2.4 2 5 2 2.5 0 2.5-2 5-2 1.3 0 1.9.5 2.5 1" />
  </svg>
);

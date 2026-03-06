// Model structure and parameters for the coral RSE diagram
// All values from docs/model_architecture.md and rse_funs.R

export const sizeClasses = [
  { id: 'SC1', label: 'SC1', range: '0–10 cm²', midpoint: 0.1, role: 'Recruits / settlers', reproduces: false, fragments: false },
  { id: 'SC2', label: 'SC2', range: '10–100 cm²', midpoint: 43, role: 'Small juveniles', reproduces: false, fragments: false },
  { id: 'SC3', label: 'SC3', range: '100–900 cm²', midpoint: 369, role: 'Large juveniles (begin reproducing)', reproduces: true, fragments: false },
  { id: 'SC4', label: 'SC4', range: '900–4,000 cm²', midpoint: 2158, role: 'Subadults (reproduce + fragment)', reproduces: true, fragments: true },
  { id: 'SC5', label: 'SC5', range: '> 4,000 cm²', midpoint: 11171, role: 'Reproductive adults (max fecundity + fragmentation)', reproduces: true, fragments: true },
];

export const locations = {
  lab: {
    id: 'lab',
    name: 'Lab',
    fullName: 'Larval Rearing Facility',
    color: '#F59E0B',
    colorLight: 'rgba(245, 158, 11, 0.08)',
    description: 'Collected larvae are settled onto tiles and grown out before outplanting.',
    parameters: [
      { name: 'lab_max', value: '~3,100 tiles', desc: 'Total tile capacity in lab' },
      { name: 'lab_retain_max', value: '0–3,100', desc: 'Tiles reserved for 1-year grow-out' },
      { name: 'sett_props', value: '~0.15', desc: 'Settlement success rate by tile type' },
      { name: 'tile_props', value: '50/50', desc: 'Fraction of lab space per tile type (cement/ceramic)' },
      { name: 'tank_max', value: '~14,600', desc: 'Max larvae per tank' },
      { name: 's_base', value: 'varies', desc: 'Baseline lab survival' },
      { name: 'm0 / m1', value: 'varies', desc: 'Density-dependent mortality coefficients' },
    ],
    processes: [
      'Settlement on tiles (~15% success)',
      'Density-dependent survival: S = s_base × exp(-m × density)',
      'Two timing pathways: 0_TX (immediate) and 1_TX (retained 1 yr)',
    ],
    hasSizeClasses: false, // Lab tracks settlers/tiles, not 5 size classes
  },
  orchard: {
    id: 'orchard',
    name: 'Orchard',
    fullName: 'Coral Nursery',
    color: '#10B981',
    colorLight: 'rgba(16, 185, 129, 0.08)',
    description: 'Managed grow-out facility (underwater coral trees/tables). Enhanced survival, faster growth, no fragmentation.',
    parameters: [
      { name: 'orchard_size', value: '~15,000', desc: 'Max colonies per orchard' },
      { name: 'surv_pars', value: 'enhanced', desc: 'Higher survival than reef (protected)' },
      { name: 'growth', value: 'faster', desc: 'Managed conditions accelerate growth' },
      { name: 'orchard_yield', value: '0–1', desc: 'Fraction of orchard larvae collected' },
    ],
    processes: [
      'Survival (enhanced vs. reef)',
      'Growth & shrinkage (transition matrix T)',
      'NO fragmentation (managed)',
      'Sexual reproduction (fecundity → larvae for collection)',
    ],
    hasSizeClasses: true,
    noFragmentation: true,
  },
  reef: {
    id: 'reef',
    name: 'Reef',
    fullName: 'Wild / Restoration Site',
    color: '#38BDF8',
    colorLight: 'rgba(56, 189, 248, 0.08)',
    description: 'Target ecosystem. Full demographic rates, space limitation, external recruitment, and disturbance.',
    parameters: [
      { name: 'reef_areas', value: '~7,837 m²', desc: 'Carrying capacity per reef site (cm²)' },
      { name: 'surv_pars', value: 'SC1~0.1–0.2 → SC5~0.8–0.95', desc: 'Baseline survival by size class' },
      { name: 'lambda', value: 'varies', desc: 'External wild recruitment (mean recruits/yr)' },
      { name: 'reef_yield', value: '0.001–0.01', desc: 'Fraction of reference reef larvae collected' },
    ],
    processes: [
      'Survival (S) with log-normal stochasticity',
      'Growth & shrinkage (transition matrix T)',
      'Fragmentation (F) from SC4/SC5',
      'Sexual reproduction (fecundity)',
      'External recruitment (wild larvae)',
      'Space limitation (area-based carrying capacity)',
    ],
    hasSizeClasses: true,
    noFragmentation: false,
  },
};

export const flows = [
  // Larvae collection (orchard/reef → lab)
  {
    id: 'orchard-to-lab',
    from: 'orchard', to: 'lab',
    label: 'Larvae collection',
    description: 'Fraction of orchard larvae collected (orchard_yield) and sent to lab for settlement.',
    param: 'orchard_yield',
    pathways: ['0tx', '1tx'],
    type: 'collection',
    costLayer: 'Larval collection: $6,500/event',
  },
  {
    id: 'reef-to-lab',
    from: 'reef', to: 'lab',
    label: 'Larvae collection',
    description: 'Fraction of reference reef larvae collected (reef_yield) and sent to lab.',
    param: 'reef_yield',
    pathways: ['0tx', '1tx'],
    type: 'collection',
    costLayer: 'Larval collection: $6,500/event + $400 permits',
  },
  // Outplanting (lab → reef/orchard)
  {
    id: 'lab-to-reef',
    from: 'lab', to: 'reef',
    label: 'Outplanting',
    description: 'Lab-reared recruits outplanted to reef. Fraction determined by reef_prop.',
    param: 'reef_prop × reef_out_props',
    pathways: ['0tx', '1tx'],
    type: 'outplant',
    costLayer: 'Outplanting: $300/day boat + $200/day × 4 divers',
  },
  {
    id: 'lab-to-orchard',
    from: 'lab', to: 'orchard',
    label: 'Outplanting',
    description: 'Lab-reared recruits outplanted to orchard. Fraction = 1 − reef_prop.',
    param: '(1 − reef_prop) × orchard_out_props',
    pathways: ['0tx', '1tx'],
    type: 'outplant',
    costLayer: 'Outplanting: $300/day boat + $200/day × 4 divers',
  },
  // Transplanting (orchard → reef)
  {
    id: 'orchard-to-reef',
    from: 'orchard', to: 'reef',
    label: 'Transplanting',
    description: 'Direct transfer of large colonies from orchard to reef. Bypasses lab. Scheduled in specific years.',
    param: 'trans_mats / transplant[year]',
    pathways: ['transplant'],
    type: 'transplant',
    costLayer: 'Included in orchard maintenance costs',
  },
];

export const decisions = [
  {
    id: 'reef-prop',
    label: 'reef_prop',
    description: 'Fraction of lab output sent to reef vs. orchard (0–1). Key trade-off: direct reef recovery vs. building orchard larval supply.',
    position: 'between-lab-split', // conceptually between lab outflow splitting to reef/orchard
    pathways: ['0tx', '1tx'],
  },
  {
    id: 'lab-retain',
    label: 'lab_retain_max',
    description: 'Tiles reserved for 1-year grow-out. Trade-off: larger outplants (higher survival) vs. fewer survivors (extra lab mortality year).',
    position: 'inside-lab', // inside the lab panel
    pathways: ['1tx'],
  },
  {
    id: 'transplant-timing',
    label: 'transplant[yr]',
    description: 'Binary — whether transplanting from orchard to reef occurs this year. When to move large orchard colonies directly to reef.',
    position: 'on-orchard-reef', // on the orchard→reef arrow
    pathways: ['transplant'],
  },
];

export const externalInputs = [
  {
    id: 'wild-recruitment',
    label: 'Wild recruitment (λ)',
    target: 'reef',
    targetClass: 'SC1',
    description: 'External wild larvae from outside the modeled system. Constant or Poisson-distributed (ext_rand). Distributed across reefs proportional to area.',
    param: 'lambda',
    pathways: ['wild'],
  },
  {
    id: 'ref-reef-larvae',
    label: 'Ref. reef larvae (λ_R)',
    target: 'lab',
    description: 'Larvae collected from a reference reef outside the system. Constant or Poisson-distributed.',
    param: 'lambda_R / ext_rand[2]',
    pathways: ['0tx', '1tx'],
  },
];

export const disturbanceLayer = {
  description: 'Periodic events (hurricanes, bleaching, disease) override demographic parameters in specified years.',
  params: [
    { name: 'dist_yrs', desc: 'Years when disturbances occur (e.g., every 3 years)' },
    { name: 'dist_surv', desc: 'Replacement survival (e.g., 25% of baseline for reef, 40% for orchard)' },
    { name: 'dist_Tmat', desc: 'Replacement transition matrices' },
    { name: 'dist_Fmat', desc: 'Replacement fragmentation matrices' },
    { name: 'dist_fec', desc: 'Replacement fecundity vectors' },
  ],
  affectsLocations: ['reef', 'orchard'], // lab is protected
};

export const stochasticityLayer = {
  sources: [
    { param: 'sigma_s', desc: 'Survival: log-normal annual variation', affects: ['reef', 'orchard'] },
    { param: 'sigma_f', desc: 'Fecundity: log-normal annual variation', affects: ['reef', 'orchard'] },
    { param: 'ext_rand[1]', desc: 'External recruitment: Poisson(λ)', affects: ['reef'] },
    { param: 'ext_rand[2]', desc: 'Reference reef larvae: Poisson(λ_R)', affects: ['lab'] },
    { param: 'rand_pars_fun()', desc: '100 parameter sets sampled from data', affects: ['reef', 'orchard', 'lab'] },
  ],
};

export const costsLayer = {
  items: [
    { item: 'Reef stars', cost: '$84.60 each' },
    { item: 'Lab tiles (cement)', cost: '$1 each' },
    { item: 'Lab tiles (ceramic)', cost: '$7 each' },
    { item: 'Lab operations', cost: '~$4,501/yr' },
    { item: 'Larval collection', cost: '$6,500/event + $400 permits' },
    { item: 'Outplanting', cost: '$300/day boat + $200/day × 4 divers' },
    { item: 'Orchard maintenance', cost: '$230/substrate × 2 visits/yr + $300 boat' },
    { item: 'Boat maintenance', cost: '$4,800/yr' },
    { item: 'Logistics', cost: '$6,000/yr' },
  ],
};

// Core equation displayed in the diagram
export const coreEquation = 'N(t+1) = (T + F) × (S ⊙ N(t)) + R(t)';

// Annual cycle steps (for tooltip on the overall diagram)
export const annualCycle = [
  { step: 1, name: 'Reef dynamics', desc: 'Apply survival, transition + fragmentation for each reef × source' },
  { step: 2, name: 'External recruitment', desc: 'Distribute wild recruits to reef SC1 proportional to area' },
  { step: 3, name: 'Orchard dynamics', desc: 'Apply survival, transition (no fragmentation) for each orchard × source' },
  { step: 4, name: 'Reproduction', desc: 'Calculate larvae from reef and orchard populations (fecundity × population)' },
  { step: 5, name: 'Larval collection', desc: 'Collect fraction of orchard/ref. reef larvae, cap at lab_max' },
  { step: 6, name: 'Lab processing', desc: 'Split 0_TX/1_TX, allocate to tiles, settlement, density-dependent survival' },
  { step: 7, name: 'Outplanting', desc: 'Distribute lab cohorts to reef/orchard per reef_prop, check space, spillover' },
  { step: 8, name: 'Transplanting', desc: 'Move scheduled orchard colonies directly to reef (if scheduled)' },
];

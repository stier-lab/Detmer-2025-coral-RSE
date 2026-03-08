import * as d3 from 'd3';
import { locations, flows, decisions, externalInputs, sizeClasses, annualCycle, disturbanceLayer, stochasticityLayer, costsLayer } from './data.js';
import { toggleLocation, expandAll, collapseAll } from './render.js';

const tooltip = {
  el: null,
  title: null,
  body: null,
};

export function initInteractions() {
  tooltip.el = d3.select('#tooltip');
  tooltip.title = tooltip.el.select('.tooltip-title');
  tooltip.body = tooltip.el.select('.tooltip-body');

  setupLocationClicks();
  setupTooltips();
  setupLayerToggles();
  setupPathwayHighlight();
  setupExpandCollapseButtons();
}

// ── Location click to expand/collapse ───────
function setupLocationClicks() {
  d3.selectAll('.location-box').on('click', function () {
    const locId = d3.select(this).attr('data-location');
    toggleLocation(locId);
    hideTooltip(); // Prevent tooltip persisting after click
  });
}

// ── Tooltips ────────────────────────────────
function setupTooltips() {
  // Location boxes
  d3.selectAll('.location-box').each(function () {
    const el = d3.select(this);
    const locId = el.attr('data-location');
    const loc = locations[locId];

    el.on('mouseenter', (event) => {
      const params = loc.parameters.map(p => `<span class="param-name">${p.name}</span>: ${p.value} — ${p.desc}`).join('<br>');
      const procs = loc.processes.map(p => `• ${p}`).join('<br>');
      showTooltip(event, loc.name + ' — ' + loc.fullName, `${loc.description}<br><br><strong>Parameters:</strong><br>${params}<br><br><strong>Processes:</strong><br>${procs}`);
    })
    .on('mousemove', moveTooltip)
    .on('mouseleave', hideTooltip);
  });

  // Size class nodes
  d3.selectAll('.sc-node').each(function () {
    const el = d3.select(this);
    const scId = el.attr('data-sc');
    const locId = el.attr('data-location');
    const loc = locations[locId];
    const scData = getSizeClassData(scId);

    el.on('mouseenter', (event) => {
      const features = [];
      if (scData.reproduces) features.push('Sexual reproduction (fecundity)');
      if (scData.fragments && !loc.noFragmentation) features.push('Fragmentation (asexual)');
      if (!scData.reproduces) features.push('No reproduction');
      showTooltip(event, `${scId} in ${loc.name}`, `<strong>Area:</strong> ${scData.range}<br><strong>Midpoint:</strong> ${scData.midpoint} cm²<br><strong>Role:</strong> ${scData.role}<br><br>${features.join('<br>')}`);
    })
    .on('mousemove', moveTooltip)
    .on('mouseleave', hideTooltip);

    // Stop click from propagating to location box
    el.on('click', (event) => event.stopPropagation());

    // Tooltips on ♀ and ⚡ icons within this SC node
    el.selectAll('.sc-icon-repro').on('mouseenter', (event) => {
      event.stopPropagation();
      showTooltip(event, `♀ Sexual Reproduction`, `<strong>${scId}</strong> produces larvae via fecundity.<br>Larvae enter the collection pipeline for lab settlement.`);
    }).on('mousemove', moveTooltip).on('mouseleave', (event) => { event.stopPropagation(); hideTooltip(); })
      .on('click', (event) => event.stopPropagation());

    el.selectAll('.sc-icon-frag').on('mouseenter', (event) => {
      event.stopPropagation();
      showTooltip(event, `⚡ Fragmentation`, `<strong>${scId}</strong> fragments into smaller size classes (SC1–SC3).<br>Asexual reproduction via colony breakage.`);
    }).on('mousemove', moveTooltip).on('mouseleave', (event) => { event.stopPropagation(); hideTooltip(); })
      .on('click', (event) => event.stopPropagation());
  });

  // Flow arrows
  d3.selectAll('.flow-group').each(function () {
    const el = d3.select(this);
    const flowId = el.attr('data-flow');
    const flow = flows.find(f => f.id === flowId);
    if (!flow) return;

    el.on('mouseenter', (event) => {
      showTooltip(event, flow.label + ` (${locations[flow.from].name} → ${locations[flow.to].name})`,
        `${flow.description}<br><br><span class="param-name">${flow.param}</span>${flow.costLayer ? '<br><br>💰 ' + flow.costLayer : ''}`);
    })
    .on('mousemove', moveTooltip)
    .on('mouseleave', hideTooltip);
  });

  // Decision diamonds
  d3.selectAll('.decision-diamond').each(function () {
    const el = d3.select(this);
    const decId = el.attr('data-decision');
    const dec = decisions.find(d => d.id === decId);
    if (!dec) return;

    el.on('mouseenter', (event) => {
      showTooltip(event, `Decision: ${dec.label}`, dec.description);
    })
    .on('mousemove', moveTooltip)
    .on('mouseleave', hideTooltip);
  });

  // External inputs
  d3.selectAll('.external-input').each(function () {
    const el = d3.select(this);
    const extId = el.attr('data-external');
    const ext = externalInputs.find(e => e.id === extId);
    if (!ext) return;

    el.on('mouseenter', (event) => {
      showTooltip(event, ext.label, `${ext.description}<br><br><span class="param-name">${ext.param}</span>`);
    })
    .on('mousemove', moveTooltip)
    .on('mouseleave', hideTooltip);
  });

  // Equation badge (annual cycle)
  d3.select('.equation-group').on('mouseenter', (event) => {
    const cycleHtml = annualCycle.map(s => `<strong>Step ${s.step}:</strong> ${s.name}<br><em>${s.desc}</em>`).join('<br><br>');
    showTooltip(event, 'Annual Cycle — Order of Operations', cycleHtml);
  })
  .on('mousemove', moveTooltip)
  .on('mouseleave', hideTooltip);
}

function getSizeClassData(scId) {
  return sizeClasses.find(sc => sc.id === scId);
}

function showTooltip(event, title, body) {
  tooltip.title.html(title);
  tooltip.body.html(body);
  tooltip.el.classed('hidden', false);
  moveTooltip(event);
}

function moveTooltip(event) {
  const pad = 12;
  let x = event.clientX + pad;
  let y = event.clientY + pad;

  // Keep tooltip on screen
  const ttEl = tooltip.el.node();
  const rect = ttEl.getBoundingClientRect();
  if (x + rect.width > window.innerWidth - pad) {
    x = event.clientX - rect.width - pad;
  }
  if (y + rect.height > window.innerHeight - pad) {
    y = event.clientY - rect.height - pad;
  }

  tooltip.el.style('left', x + 'px').style('top', y + 'px');
}

function hideTooltip() {
  tooltip.el.classed('hidden', true);
}

// ── Layer toggles ───────────────────────────
function setupLayerToggles() {
  const svg = d3.select('#diagram');

  d3.selectAll('.controls input[type="checkbox"]').on('change', function () {
    const layer = this.dataset.layer;
    const active = this.checked;
    svg.classed(`show-${layer}`, active);
  });
}

// ── Pathway highlighting ────────────────────
function setupPathwayHighlight() {
  d3.select('#pathway-select').on('change', function () {
    const pathway = this.value;

    if (!pathway) {
      // Show all
      d3.selectAll('[data-pathways]').classed('dimmed', false).classed('highlighted', false);
      d3.selectAll('.location-box').classed('dimmed', false);
      d3.selectAll('.external-input').classed('dimmed', false);
      return;
    }

    // Dim everything, then highlight matching
    d3.selectAll('.flow-group').each(function () {
      const el = d3.select(this);
      const pathways = (el.attr('data-pathways') || '').split(',');
      el.classed('dimmed', !pathways.includes(pathway));
      el.classed('highlighted', pathways.includes(pathway));
    });

    d3.selectAll('.decision-diamond').each(function () {
      const el = d3.select(this);
      const pathways = (el.attr('data-pathways') || '').split(',');
      el.classed('dimmed', !pathways.includes(pathway));
      el.classed('highlighted', pathways.includes(pathway));
    });

    d3.selectAll('.external-input').each(function () {
      const el = d3.select(this);
      const pathways = (el.attr('data-pathways') || '').split(',');
      el.classed('dimmed', !pathways.includes(pathway));
      el.classed('highlighted', pathways.includes(pathway));
    });

    // Dim/highlight locations based on pathway
    const locRelevance = {
      wild: ['reef'],
      '0tx': ['lab', 'orchard', 'reef'],
      '1tx': ['lab', 'orchard', 'reef'],
      transplant: ['orchard', 'reef'],
    };
    const relevant = locRelevance[pathway] || [];

    d3.selectAll('.location-box').each(function () {
      const locId = d3.select(this).attr('data-location');
      d3.select(this).classed('dimmed', !relevant.includes(locId));
    });
  });
}

// ── Expand/Collapse all buttons ─────────────
function setupExpandCollapseButtons() {
  d3.select('#expand-all').on('click', expandAll);
  d3.select('#collapse-all').on('click', collapseAll);
}
